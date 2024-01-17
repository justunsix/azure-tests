# Description: Add owners passed to the script to groups starting with the group filter passed to the script
param(
    [Parameter(Mandatory=$true)]
    [string[]]$ownerUserPrincipalNames,
    [Parameter(Mandatory=$true)]
    [string]$groupFilter
)

# Using Microsoft Graph SDK for PowerShell
# Sign in with user read and group read write
# to prepare for group operations if needed
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

$appliedGroupFilter = "startswith(displayName,'$groupFilter')"

Get-MgGroup -Filter $appliedGroupFilter | ForEach-Object {
  $group = $_
  # Output owners and group information
  Write-Host "Group Display Name: $($group.DisplayName)" -ForegroundColor Green
  Write-Host "GroupID: $($group.Id)"

  $owners = Get-MgGroupOwner -GroupId $group.Id
  $ownersCurrentUserPrincipalNames = @()

  if ($owners.Count -eq 0) {
    Write-Host "No owners found" -ForegroundColor Yellow
  }
  else {
    # For each Id in owners, get the user information
    foreach ($owner in $owners) {
      $user = Get-MgUser -UserId $owner.Id
      # Write-Host "Owner: $($user.DisplayName)"
      $ownersCurrentUserPrincipalNames += $user.UserPrincipalName
    }
  }
  
  Write-Host "Adding owners to group $($group.DisplayName)"
  # Add owners to group using array of user principal names
  foreach ($newOwner in $owner_user_principal_names) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$($newOwner)'"
    # Check if user is already an owner
    if ($ownersCurrentUserPrincipalNames -contains $user.UserPrincipalName) {
      Write-Host "= $($user.DisplayName) is already an owner of group $($group.DisplayName)"
    }
    else {
      Write-Host "+ Adding $($user.DisplayName) as owner to group $($group.DisplayName)" -ForegroundColor Green
      $newGroupOwner =@{
        "@odata.id"= "https://graph.microsoft.com/v1.0/users/{" + $user.Id + "}"
        }
      New-MgGroupOwnerByRef -GroupId $group.Id -BodyParameter $newGroupOwner
    }
  }


}