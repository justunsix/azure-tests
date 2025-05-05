# Microsoft Entra ID formerly Azure Active Directory (AAD)

Use Microsoft Graph API and PowerShell to manage Microsoft Entra, also known
formerly as Azure Active Directory (AAD), resources.

## Prerequisites

- [Install the Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)
  and its prerequisites and verify it:
  - PowerShell 7.5.0 and later is recommended.
  - If using Windows PowerShell, additional prerequisites are required.
- Learn more at
  [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/?view=graph-powershell-1.0)

## Description of Scripts in this Directory

- `Check-EnterpriseAppUsers` - Check users in an Enterprise Application
  - `Check-GroupOwners` - Check owners of groups
  - `Check-UsersFromEmailList.ps1` - See if users with certain emails are
    present in Entra and how many of them there are
- `Add-GroupOwners.ps1` - Add owners to groups
- `Update-EntraGroupMembershipFromCSV.ps1` - Given a csv file with group names
  and emails, update group membership to match the csv file.
  Example usage:

## Scripts by Example

```powershell

# Check Group owners
Check-GroupOwners.ps1 "group-name"

# Add Group owners
$owner_user_principal_names = @(
  'john.me@email.ca'
)
$groupFilter1 = "group1"
Add-GroupOwners.ps1 $owner_user_principal_names $groupFilter1

# Update Group Membership
Update-EntraGroupMembershipFromCSV.ps1 "My-Users.csv" -WhatIf
# -WhatIf - check what changes are made, no changes will be done
# remove -WhatIf to make changes
```

## PowerShell 7 Install Issues

There may be errors when trying to install the Microsoft Graph PowerShell SDK on
PowerShell 7. If you encounter errors like:

```powershell
Install-Package: No match was found for the specified search criteria and
module name 'Microsoft.Graph'. Try Get-PSRepository to see all available
registered module repositories.
```

Try the following as administrator in PowerShell 7:

```powershell
# Re-register the PowerShell Gallery
Register-PSRepository -Default
# Set the repository
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
# Install the module
Install-Module Microsoft.Graph -Scope CurrentUser
```

The error may be due to the PowerShell Gallery not being registered or the
repository not being set and the commands above will set the PowerShell Gallery
so the `Install-Module` command will work.

## Microsoft Graph PowerShell SDK Example Usage

### Module Management and Sign In

```powershell
# Verify the module is installed
Get-InstalledModule Microsoft.Graph
# Update the module
Update-Module Microsoft.Graph

# Check permission for cmdlet for example Get-MgUser:
Find-MgGraphCommand -command Get-MgUser | Select -First 1 -ExpandProperty Permissions

# Sign in with user read and group read write
# to prepare for group operations
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"

# Sign in with Read only
Connect-MgGraph -Scopes 'User.Read.All',"Group.Read.All"

# Do work

# Sign out
Disconnect-MgGraph
```

### Group Queries

```powershell
# Get information on a user
Get-MgUser -Filter "userPrincipalName eq 'Bob.Smith@mydomain.ca'" `
| Format-List ID, DisplayName, Mail, UserPrincipalName

# Search for users with a specific "domain.ca" in their email address
$users = Get-MgUser -ConsistencyLevel eventual -Count userCount `
-Filter "endsWith(Mail, 'domain.ca')" -OrderBy UserPrincipalName
```

### User Management

```powershell

# Use -WhatIf to test changes without making them

# Get a user by principal name
$user = Get-MgUser -Filter "userPrincipalName eq 'Janet.Smith@mydomain.ca'"

# Get a group by Group name
$group = Get-MgGroup -Filter "displayName eq 'reader-friendly-group-name'"
$group | Format-List Id, DisplayName, Description

# Remove user found previously from the group
Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id

# Add user found previously to the group
New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
```
