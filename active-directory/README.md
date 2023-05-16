# Azure Active Directory

Use Microsoft Graph API and PowerShell to manage Azure Active Directory (AAD) resources.

## Update-AzureADGroupMembershipFromCSV.ps1

PowerShell script to update Azure Active Directory group membership from a CSV file.

### Prerequisites

- [Install the Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0) and its prerequisites and verify it:
  - PowerShell 7 and later is recommended.
  - If using Windows PowerShell, additional prerequisites are required.
- Learn more at [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/?view=graph-powershell-1.0)

#### PowerShell 7

There may be errors when trying to install the Microsoft Graph PowerShell SDK on PowerShell 7. If you encounter errors like 

```powershell
Install-Package: No match was found for the specified search criteria and module name
'Microsoft.Graph'. Try Get-PSRepository to see all available registered module
repositories.
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

## Check-AzureADUsersFromEmailList.ps1

PowerShell script to check Azure Active Directory users from a list of email addresses to see if domains in the list of users match domains of existing users in the AAD.

## Microsoft Graph Example Usage

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
Get-MgUser -Filter "userPrincipalName eq 'Justin.Tung@mydomain.ca'" | Format-List ID, DisplayName, Mail, UserPrincipalName

# Search for users with a specific "domain.ca" in their email address
$users = Get-MgUser -ConsistencyLevel eventual -Count userCount -Filter "endsWith(Mail, 'domain.ca')" -OrderBy UserPrincipalName
```

### User Management

```powershell

# Use -WhatIf to test changes without making them

# Get a user by principal name
$user = Get-MgUser -Filter "userPrincipalName eq 'Justin.Tung@mydomain.ca'"

# Get a group by Group name
$group = Get-MgGroup -Filter "displayName eq 'reader-friendly-group-name'"
$group | Format-List Id, DisplayName, Description

# Remove user found previously from the group
Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id

# Add user found previously to the group
New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id

```