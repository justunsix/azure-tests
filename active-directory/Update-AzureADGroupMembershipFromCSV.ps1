# Update Azure Active Directory (AAD) groups membership based on 
# a CSV file specifying users and their groups
# Prerequisites: 
# - Install Microsoft Graph PowerShell SDK and its prerequisites
# - Connect to Graph with appropriate scope

# Script was converted from Azure AD PowerShell cmdlets to Microsoft Graph PowerShell
# while referencing https://learn.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
param(
    # Allow script to support:
    # - SupportsShouldProcess: 
    #   -WhatIf : what happens if script is run 
    #   -Confirm : prompt user to confirm changes
    # - ConfirmImpact:
    #   - High: automatically prompt user to confirm
    
    # Confirm path to CSV file containing a list
    # of users and their emails
    # set default path to users.csv file in current working directory for script
    [ValidateScript({Test-Path $_})]
    [string]$AuthorizationFilePath = ".\users.csv"
)

# CSV format is Name,EmailAddress,Group
# Get user entries from CSV file
$records = Get-Content $AuthorizationFilePath | ConvertFrom-Csv | ForEach {
	[PSCustomObject]@{
		Name=$_.Name.Trim();
		EmailAddress=$_.EmailAddress.Trim();
		Group=$_.Group.Trim()
	}
}

# Update AAD groups so groups match with users' groups
# assigned in the csv file
# - Group users by group name 
# - Check each group
# - Add or remove users by comparing the AAD users in group
#   with desired member list

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
    
    # See desired members from csv file
    $desiredMembers = @()
    foreach ($member in $g.Group) {
        $desiredGroupMemberEmail = $member.EmailAddress.ToLower()
        $desiredMembers += $desiredGroupMemberEmail
    }

    Write-Host "Desired members: $($desiredMembers -join ', ')"
    
    # Get current members from AAD and each person's email address in lower case
    # ** AAPD: $currentMembers = Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId -All $true | Select -ExpandProperty Mail | ForEach { $_.ToLower() }
    # ** GPS: Get-MgGroupMember
    $groupMembers = Get-MgGroupMember -GroupId $aadGroup.Id -All

    # List of member's email which may be blank
    $currentMembers = @()
    # List of members Other emails
    $currentMembersOtherEmails = @()

    foreach ($member in $groupMembers) {

        $currentGroupMemberEmail = $member.Mail
        $currentGroupMemberOtherEmails = $member.OtherMails[0]

        if (!$currentGroupMemberEmail -and !$currentGroupMemberOtherEmails) {
            Write-Host "Error: $member.DisplayName has no email address" -ForegroundColor Red
        }
        else {
            if ($currentGroupMemberEmail) {
                $currentMembers += $currentGroupMemberEmail.ToLower()
            }
            # Fix issue where the mail field might be blank for federated users
            # or users have multiple other email addresses
            # Add "Other Emails" entries to the current group members
            # If none, no emails will be added
            foreach ($otherEmail in $member.OtherMails) {
                $currentMembersOtherEmails += $otherEmail.ToLower()
            }
        }
    }

    Write-Host "Current members: $($currentMembers -join ', ')"

    # Add users to group if they are in the desired members list
    # but not in the AAD group
    foreach ($email in $desiredMembers) {

        $isInGroup = $currentMembers | Where-Object -FilterScript { $_ -eq $email }
        $isInGroupOtherEmails = $currentMembersOtherEmails | Where-Object -FilterScript { $_ -eq $email }

        if (!$isInGroup -and !$isInGroupOtherEmails) {
            # Desired member not in AAD, add them
            Write-Host "+ $email" -ForegroundColor Green
            $user = Get-AzureADUser -SearchString "$email"

            if (!$user) {
                # Fix issue where SearchString email is not finding guest users,
                # reformat the email to match the start of their user principal name
                # and search on that instead
                $upnFromEmail = $email.Replace("@", "_")
                $user = Get-AzureADUser -Filter "startswith(userPrincipalName,'$upnFromEmail')"
                if (!$user) {
                    # Otherwise the user is not in a known format or the email could be incorrect or using an older email
                    Write-Host "Error: $email not found by this script`nDetermine if the user exists in Azure Active Directory by searching on $email and if they do add them manually." -ForegroundColor Red
                }
            }
            if ($PSCmdlet.ShouldProcess($email , "Add to $($aadGroup.DisplayName)")) {
                Add-AzureADGroupMember -ObjectId $aadGroup.ObjectId -RefObjectId $user.ObjectId
            }
            
        } else {
            # Desired member is already in AAD group
            Write-Host "= $email" -ForegroundColor Gray
        }
    }
    
    # Remove users from group if they are in the AAD grou
    # but not in the desired members list
    foreach ($email in $currentMembers) {
        $removeUser = -not ($desiredMembers | Where-Object -FilterScript { $_ -eq $email })

        if ($removeUser) {
            # User is in AAD group but not in desired members list,
            # remove them
            Write-Host "- $email" -ForegroundColor Red
            $user = Get-AzureADUser -SearchString "$email"
            
            if ($PSCmdlet.ShouldProcess($user.Mail , "Remove from $($aadGroup.DisplayName)")) {
                Remove-AzureADGroupMember -ObjectId $aadGroup.ObjectId -MemberId $user.ObjectId
            }
        }
    }
}