# Check AAD for Existing Users with Domains from an Email List
# - Parses a file with emails 
# - Checks if domains in the emails  match to any emails in
# an Azure Active Directory

# Reads the contents of a file named emails.txt
$emails = Get-Content -Path "./emails.txt"
$domains = $emails | ForEach-Object {($_ -split '@')[1]}
# Removes duplicate domain names
$domains = $domains | Select-Object -Unique

# Loop through each domain and count the number of users in AAD with that domain
foreach ($domain in $domains) {
      $users = Get-MgUser -ConsistencyLevel eventual -Count userCount -Filter "endsWith(Mail, '$domain')" -OrderBy UserPrincipalName 
      Write-Host "$domain, $($users.Count)"
}

