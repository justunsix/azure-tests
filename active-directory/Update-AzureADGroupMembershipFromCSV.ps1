# Update Azure Active Directory (AAD) groups membership based on 
# a CSV file specifying users and their groups
# Prerequisites: 
# - Install Microsoft Graph PowerShell SDK and its prerequisites

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
param(
    # Allow script to support:
    # - SupportsShouldProcess: 
    #   -WhatIf : what happens if script is run 
    #   -Confirm : prompt user to confirm execution
    #
    # Confirm path to CSV file containing a list 
    # of users and their emails
    # set default path to users csv file to current working directory
    [ValidateScript({Test-Path $_})]
    [string]$AuthorizationFilePath = ".\Users.csv"
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
    # AzureAD PowerShell (deprecated): 
    $aadGroup = Get-AzureADGroup -SearchString "$groupName"
    # Microsoft Graph PowerShell SDK, get group by display name: 
    # $aadGroup = GetMgGroup -Filter "DisplayName eq '$groupName'"
    
    # See desired members from csv file
    $desiredMembers = $g | Select -ExpandProperty Group | Select -ExpandProperty EmailAddress | ForEach { $_.ToLower() }
    Write-Host "Desired members: $($desiredMembers -join ', ')"
    
    # See current members from AAD
    $currentMembers = Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId -All $true | Select -ExpandProperty Mail | ForEach { $_.ToLower() }
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