# Given an Enterprise Application name, this script will return a list of users that have been assigned to the application
param(
    [Parameter(Mandatory=$true)]
    [string]$appName
)

# Import the required module
Import-Module Microsoft.Graph.Applications

# Using Microsoft Graph SDK for PowerShell
# Connect to Microsoft Graph
Connect-MgGraph

# Get the Enterprise Application for the app name passed to the script
$app = Get-MgApplication -Filter "displayName eq '$appName'"

# Get the service principal for the application
$servicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"

if ($servicePrincipal) {
    # Get the app role assignments for the service principal
    $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $servicePrincipal.Id

    # For each app role assignment, get the user
    foreach ($appRoleAssignment in $appRoleAssignments) {
        $user = Get-MgUser -UserId $appRoleAssignment.PrincipalId
        # Output display name in quotes and email address
        Write-Output ("{0},{1}" -f "`"$($user.DisplayName)`"", $user.Mail)
    }
} else {
    Write-Output "No service principal found for the specified application"
}