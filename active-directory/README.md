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

### Microsoft Graph Example Usage

#### Module Management

```powershell
# Verify the module is installed
Get-InstalledModule Microsoft.Graph
# Update the module
Update-Module Microsoft.Graph
```

#### Permissions

```powershell
# Check permission for cmdlet for example Get-MgUser:
Find-MgGraphCommand -command Get-MgUser | Select -First 1 -ExpandProperty Permissions

# Sign in with user read and group read write
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"

# Do work

# Sign out
Disconnect-MgGraph
```