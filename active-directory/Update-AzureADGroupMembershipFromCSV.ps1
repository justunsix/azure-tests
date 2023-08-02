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

$groups = $records | Group Group
foreach ($g in $groups) {
    $groupName = $g.Group[0].Group

    # Get group object from AAD
    Write-Host "*** $groupName ***" -ForegroundColor Yellow
    # AzureAD PowerShell (deprecated) - ** AAPD
    # ** AAPD: $aadGroup = Get-AzureADGroup -SearchString "$groupName"
    # Microsoft Graph PowerShell SDK - ** GPS
    # ** GPS: Get group by display name: 
    $aadGroup = Get-MgGroup -Filter "DisplayName eq '$groupName'"
    
    # See desired members from csv file
    $desiredMembers = $g | Select -ExpandProperty Group | Select -ExpandProperty EmailAddress | ForEach { $_.ToLower() }
    Write-Host "Desired members: $($desiredMembers -join ', ')"
    
    # ** AAPD: $currentMembers = Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId -All $true | Select -ExpandProperty Mail | ForEach { $_.ToLower() }
    # ** GPS: Get current members from AAD and
    # get each person's email address in lower case
    $currentMembers = Get-MgGroupMember -GroupId $aadGroup.Id -All | Select-Object @{ Name = 'mail'; Expression = { $_.additionalProperties['mail'] } } | Select-Object -ExpandProperty mail | ForEach-Object { $_.ToLower() }

    Write-Host "Current members: $($currentMembers -join ', ')"

    # Add users to group if they are in the desired members list
    # but not in the AAD group
    foreach ($email in $desiredMembers) {
        $existingUser = Get-AzureADUser -SearchString "$email"
        $isInGroup = $currentMembers | Where-Object -FilterScript { $_ -eq $email }

        if (-not $isInGroup) {
            # Desired member not in AAD, add them
            Write-Host "+ $email" -ForegroundColor Green
            $user = Get-AzureADUser -SearchString "$email"
            
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