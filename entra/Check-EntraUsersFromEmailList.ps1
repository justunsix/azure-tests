# Check AAD for Existing Users with Domains from an Email List
# - Parses a file with emails 
# - Checks if domains in the emails  match to any emails in
# an Azure Active Directory

# Reads the contents of a file named emails.txt
$emails = Get-Content -Path "./emails.txt"
# Get all domains from emails and make them lowercase
# Catch parse error
try {
    $domains = $emails | ForEach-Object {($_ -split "@")[1].ToLower()}
} catch {
    Write-Host "Error parsing emails.txt, an email may not be in a correct format of name@domain.ending"
    exit
}

# Remove duplicate domain names
$domains = $domains | Select-Object -Unique

# Loop through each domain and count the number of users in AAD with that domain
Write-Host "Domain, AAD User Count, Email Count"
foreach ($domain in $domains) {
    # Get users with emails that end with the domain
    $users = Get-MgUser -ConsistencyLevel eventual -Count userCount -Filter "endsWith(Mail, '$domain')" -OrderBy UserPrincipalName 
    # Get number of users in the emails.txt with that domain, make sure emails are compared in lowercase
    $emailCount = $emails | Where-Object {($_ -split "@")[1].ToLower() -eq $domain} | Measure-Object | Select-Object -ExpandProperty Count

    Write-Host "$domain, $($users.Count), $emailCount"
}

