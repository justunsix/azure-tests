# Description: Checks the owners of a group in Microsoft Entra that starts with the name passed to the script
param(
    [Parameter(Mandatory=$true)]
    [string]$groupName1
)

# Using Microsoft Graph SDK for PowerShell
# Sign in with user read and group read write
# to prepare for group operations
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

# Output owners for groups that contain that start with specified group name
Get-MgGroup -Filter "startswith(displayName,'$groupName1')" | ForEach-Object {
  $group = $_
  # Output owners and group information
  Write-Host "Group Display Name: $($group.DisplayName)" -ForegroundColor Green
  Write-Host "GroupID: $($group.Id)"

  $owners = Get-MgGroupOwner -GroupId $group.Id
  if ($owners.Count -eq 0) {
    Write-Host "No owners found" -ForegroundColor Yellow
  }
  else {
    # For each Id in owners, get the user information
    # loop can be used to check specific users
    # like if a user is an owner
    foreach ($owner in $owners) {
      $user = Get-MgUser -UserId $owner.Id
      Write-Host "Owner: $($user.DisplayName)"
    }
  }
}