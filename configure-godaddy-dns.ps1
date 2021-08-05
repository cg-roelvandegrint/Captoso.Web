$goDaddySsoKey = $Env:GO_DADDY_SSO_KEY
$goDaddySsoSecret = $Env:GO_DADDY_SSO_SECRET
$appServiceName = $Env:APPSERVICENAME
$domain = $Env:DOMAIN
$subDomain = $Env:SUBDOMAIN
$domainVerificationKey = $Env:DOMAINVERIFICATIONKEY

$authorizationHeader = @{ 
    'Authorization' = "sso-key $($goDaddySsoKey):$($goDaddySsoSecret)" 
}

Write-Host $authorizationHeader

Write-Host "Retrieving DNS records for domain: $($domain)"

$response = Invoke-WebRequest `
    -Uri "https://api.godaddy.com/v1/domains/$($domain)/records" `
    -Headers $authorizationHeader

Write-Host "DNS records retrieved"

$records = ConvertFrom-Json -InputObject $response.Content

Write-Host "Checking if CNAME record is configured correctly"

$cNameConfigured = @($records.Where( {
            # the 'anotherapp' part should come from a parameter in the expression below
            $_.type -eq "CNAME" -and 
            $_.name -eq $subDomain -and
            $_.data -contains "$($appServiceName).azurewebsites.net"
        })).Count -gt 0

if ($cNameConfigured) {
    Write-Host "CNAME record correct"
}
else {
    Write-Host "CNAME record not configured, configuring now"
    
    $body = @(
        @{
            type = "CNAME";
            name = $subDomain;
            data = "$($appServiceName).azurewebsites.net";
        }
    )

    Invoke-WebRequest `
        -Uri "https://api.godaddy.com/v1/domains/$($domain)/records" `
        -Method Patch `
        -ContentType 'application/json' `
        -Body ($body | ConvertTo-Json -AsArray) `
        -Headers $authorizationHeader

    Write-Host "CNAME record configured successfully"
}

Write-Host "Checking if TXT record is configured correctly"
$txtRecordConfigured = @($records.Where( { 
            $_.type -eq "TXT" -and 
            $_.name -eq "asuid.$($subDomain)" -and
            $_.data -eq $domainVerificationKey
        })).Count -gt 0

if ($txtRecordConfigured) { 
    Write-Host "TXT record correct"
}
else {
    Write-Host "TXT record not configured, configuring now..."

    $body = @(
        @{
            type = "TXT";
            name = "asuid.$($subDomain)";
            data = $domainVerificationKey;
        }
    )

    Invoke-WebRequest `
        -Uri "https://api.godaddy.com/v1/domains/$($domain)/records" `
        -Method Patch `
        -ContentType 'application/json' `
        -Body ($body | ConvertTo-Json -AsArray) `
        -Headers $authorizationHeader

    Write-Host "TXT record configured successfully"
}
