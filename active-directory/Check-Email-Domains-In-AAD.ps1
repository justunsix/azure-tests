# Check AAD for Existing Users with Domains from an Email List
# - Parses a file with emails 
# - Checks if domains in the emails  match to any emails in
# an Azure Active Directory

# Reads the contents of a file named emails.txt
$emails = Get-Content -Path "./emails.txt"
$domains = $emails | ForEach-Object {($_ -split '@')[1]}
# Removes duplicate domain names
$domains = $domains | Select-Object -Unique

# Queries Azure Active Directory for users 
# whose email addresses match the domain name
foreach ($domain in $domains) {
    $users = Get-AzureADUser -Filter "UserPrincipalName -like '*@$domain'"
    if ($users) {
        Write-Host "Users found for domain $domain:"
        
        # Display UserPrincipalName for each user found
        # Write-Host $users.UserPrincipalName
    }
}