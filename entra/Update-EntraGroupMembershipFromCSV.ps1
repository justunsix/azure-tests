# Update Entra formerly known as Azure Active Directory (AAD) groups membership based on 
# a CSV file specifying users and their groups
#
# Prerequisites: 
# - Install Microsoft Graph PowerShell SDK and its prerequisites
# Call script using: .\Update-EntraGroupMembershipFromCSV.ps1 -AuthorizationFilePath "path\to\users.csv"

# Script was converted from Azure AD PowerShell cmdlets to Microsoft Graph PowerShell using 
# https://learn.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    # Allow script to support:
    # - SupportsShouldProcess: 
    #   -WhatIf : what happens if script is run 
    #   -Confirm : prompt user to confirm changes
    # - ConfirmImpact:
    #   - High: automatically prompt user to confirm
    
    # Confirm path to CSV file containing a list of users and their emails
    # set default path to users.csv file in current working directory for script
    [ValidateScript({ Test-Path $_ })]
    [string]$AuthorizationFilePath = ".\users.csv",
    [bool]$DebugMode = $false
)

# Cache of user objects looked up to avoid multiple calls to the API
$userCache = @{}

function Write-DebugLog {
    param(
        [string]$Message
    )
    if ($DebugMode) {
        Write-Host $Message -ForegroundColor Blue
    }
}

# Find a user based on their email
function Find-UserByEmail() {

    param(
        [Parameter(Mandatory = $true)] 
        [string]$email
    )

    # Check cache first
    if ($userCache.ContainsKey($email)) {
        Write-DebugLog("Found $($email) in cache")
        return $userCache[$email]
    }
    
    # Handle emails with single quotes like lee.o'connor@example.com and escape them
    # for the OData filter query
    $emailToSearch = $email.Replace("'", "''")
    
    # ** AAPD: $user = Get-AzureADUser -SearchString "$email"
    # ** GPS: Get-MgUser
    $user = Get-MgUser -Filter "startswith(userPrincipalName,'$emailToSearch')"

    if (!$user) {
        # Fix issue where SearchString email is not finding users,
        # whose UPN does not begin with their email
        # Reformat the email to match the start of their user principal name
        # and search on that instead
        $upnFromEmail = $email.Replace("@", "_")
        # ** AAPD: $user = Get-AzureADUser -Filter "startswith(userPrincipalName,'$upnFromEmail')"
        # ** GPS: Get-MgUser
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$user = Get-MgUser -Filter "startswith(userPrincipalName,'$upnFromEmail')"
        if (!$user) {
            # Otherwise the user is not in a known format or the email could be incorrect or using an older email
            Write-Host "Error: $email not found by this script`nDetermine if the user exists in the directory `
                    by searching on $email and if they do add them manually." -ForegroundColor Red
        }
    }
    Write-DebugLog("Searched on $($email), found user with Display Name: $($user.DisplayName)")


    $userCache[$email] = $user
    return $user
}

function Find-UserById() {
    param(
        [Parameter(Mandatory = $true)] 
        [string]$id
    )
    [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]$user = Get-MgUser -UserId $id
    
    Write-DebugLog("Searched on $($id), found user with Display Name: $($user.DisplayName)")

    $userCache[$user.Mail] = $user
    return $user
}
# Connect using Microsoft Graph SDK for PowerShell
# Sign in with user read and group read write
# to prepare for group operations if needed
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

# CSV format is Name,EmailAddress,Group
# Get user entries from CSV file
$records = Get-Content $AuthorizationFilePath | ConvertFrom-Csv | ForEach-Object {
    [PSCustomObject]@{
        Name         = $_.Name.Trim();
        EmailAddress = $_.EmailAddress.Trim().ToLower();
        Group        = $_.Group.Trim()
    }
    # If csv row is invalid, give error, and exit script
    if ($_.Group -eq "" -or $_.Name -eq "" -or $_.EmailAddress -eq "") {
        Write-Host "Error: a line in csv file has no name, group, or email address assigned. Check the csv file and that rows are not empty." -ForegroundColor Red
        exit 1
    }
}

# Update Entra groups so groups match with users' groups assigned in the csv file
# - Group users by group name 
# - Check each group
# - Add or remove users by comparing the users in group with desired members from csv file

$groups = $records | Group-Object Group
foreach ($g in $groups) {
    $groupName = $g.Group[0].Group

    # Get group object from AAD
    Write-Host "`n----------------------------------`n*** $groupName ***" -ForegroundColor Yellow

    # Get group by display name
    # AzureAD PowerShell (deprecated) - ** AAPD
    # ** AAPD: $aadGroup = Get-AzureADGroup -SearchString "$groupName"
    # Microsoft Graph PowerShell SDK - ** GPS
    # ** GPS: Get-MgGroup
    $aadGroup = Get-MgGroup -Filter "DisplayName eq '$groupName'"
    
    if (!$aadGroup) {
        Write-Host "Error: $groupName not found in directory, Check the group name" -ForegroundColor Red
        continue
    }

    # See desired members from csv file
    $desiredMembers = @()
    foreach ($member in $g.Group) {
        $desiredGroupMemberEmail = $member.EmailAddress
        $desiredMembers += $desiredGroupMemberEmail
    }

    Write-Host "Desired members: $($desiredMembers -join ', ')"
    
    # Get current members from Entra and each person's email address in lower case
    # ** AAPD: $currentMembers = Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId -All $true | Select -ExpandProperty Mail | ForEach { $_.ToLower() }
    # ** GPS: Get-MgGroupMember
    $groupMembers = Get-MgGroupMember -GroupId $aadGroup.Id -All

    # List of member's email which may be blank
    $currentMembers = @()
    # List of members Other emails
    $currentMembersOtherEmails = @()

    foreach ($member in $groupMembers) {

        $memberUserObject = Find-UserById($member.Id)
        $currentGroupMemberEmail = $memberUserObject.Mail
        $otherEmailsExist = $memberUserObject.OtherMails.Count -gt 0

        Write-DebugLog("Current group member `
            Display Name: $($memberUserObject.DisplayName) `
            `nUPN: $($($memberUserObject.UserPrincipalName)) `
            `nEmail: $($memberUserObject.Mail) `
            `nOther Email: $($memberUserObject.OtherMails) `
            `nMail Nickname: $($memberUserObject.MailNickname)")
        

        if (!$currentGroupMemberEmail -and !$otherEmailsExist) {
            Write-Host "Error: $($memberUserObject.DisplayName) with User Principle Name: `n$($memberUserObject.UserPrincipalName) `nhas no email address" -ForegroundColor Red
        }
        else {
            if ($currentGroupMemberEmail) {
                $currentMembers += $currentGroupMemberEmail.ToLower()
            }

            if ($otherEmailsExist) {
                # Fix issue where the mail field might be blank for federated users
                # or users have multiple other email addresses
                # Add "Other Emails" entries to the current group members
                # If none, no emails will be added
                foreach ($otherEmail in $memberUserObject.OtherMails) {
                    $currentMembersOtherEmails += $otherEmail.ToLower()
                }
            }
        }
    }

    Write-Host "Current members: $($currentMembers -join ', ')"

    # Add users to group if they are desired members from csv file but not in the group
    foreach ($email in $desiredMembers) {

        if ($currentMembers -notcontains $email -and $currentMembersOtherEmails -notcontains $email) {
            # Desired member not in group, add them
            Write-Host "+ $email" -ForegroundColor Green

            $user = Find-UserByEmail($email)
            if ($PSCmdlet.ShouldProcess($email , "Add to $($aadGroup.DisplayName)")) {
                # ** AAPD: Add-AzureADGroupMember -ObjectId $aadGroup.ObjectId -RefObjectId $user.ObjectId
                # ** GPS: New-MgGroupMember
                New-MgGroupMember -GroupId $aadGroup.Id -DirectoryObjectId $user.Id
            }
            
        }
        else {
            # Desired member is already in AAD group
            Write-Host "= $email" -ForegroundColor Gray
        }
    }
    
    # Remove users from group if they are in the group but not in the desired members list
    foreach ($email in $currentMembers) {

        if ($desiredMembers -notcontains $email) {
            # User is in group but not in desired members list, remove them
            Write-Host "- $email" -ForegroundColor Red

            $user = Find-UserByEmail($email)
            
            if ($PSCmdlet.ShouldProcess($user.Mail , "Remove from $($aadGroup.DisplayName)")) {
                # ** AAPD: Remove-AzureADGroupMember -ObjectId $aadGroup.ObjectId -MemberId $user.ObjectId
                # ** GPS: Remove-MgGroupMemberByRef
                Remove-MgGroupMemberByRef -GroupId $aadGroup.Id -DirectoryObjectId $user.Id
            }
        }
    }
}