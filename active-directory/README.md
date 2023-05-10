# Azure Active Directory

Use Microsoft Graph API and PowerShell to manage Azure Active Directory (AAD) resources.

## Update-AzureADGroupMembershipFromCSV.ps1

PowerShell script to update Azure Active Directory group membership from a CSV file.

### Prerequisites

- [Install the Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0) and its prerequisites.
- The PowerShell script execution policy must be set to remote signed or less restrictive.

To set policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
