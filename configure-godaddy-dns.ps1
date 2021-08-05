$goDaddySsoKey = $Env:GO_DADDY_SSO_KEY
$goDaddySsoSecret = $Env:GO_DADDY_SSO_SECRET
$appServiceName = $Env:APPSERVICENAME
$domain = $Env:DOMAIN
$subDomain = $Env:SUB_DOMAIN
$customDomainVerificationId = $Env:CUSTOM_DOMAIN_VERIFICATION_ID

$authorizationHeader = @{ 
    'Authorization' = "sso-key $($goDaddySsoKey):$($goDaddySsoSecret)" 
}

Write-Output "Retrieving DNS records for domain: $($domain)"

$response = Invoke-WebRequest `
    -Uri "https://api.godaddy.com/v1/domains/$($domain)/records" `
    -Headers $authorizationHeader

Write-Output "DNS records retrieved"

$records = ConvertFrom-Json -InputObject $response.Content

Write-Output "Checking if CNAME record is configured correctly"

$cNameConfigured = @($records.Where( {
            # the 'anotherapp' part should come from a parameter in the expression below
            $_.type -eq "CNAME" -and 
            $_.name -eq $subDomain -and
            $_.data -contains "$($appServiceName).azurewebsites.net"
        })).Count -gt 0

if ($cNameConfigured) {
    Write-Output "CNAME record correct"
}
else {
    Write-Output "CNAME record not configured, configuring now"
    
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

    Write-Output "CNAME record configured successfully"
}

Write-Output "Checking if TXT record is configured correctly"
$txtRecordConfigured = @($records.Where( { 
            $_.type -eq "TXT" -and 
            $_.name -eq "asuid.$($subDomain)" -and
            $_.data -eq $customDomainVerificationId
        })).Count -gt 0

if ($txtRecordConfigured) { 
    Write-Output "TXT record correct"
}
else {
    Write-Output "TXT record not configured, configuring now..."

    $body = @(
        @{
            type = "TXT";
            name = "asuid.$($subDomain)";
            data = $customDomainVerificationId;
        }
    )

    Invoke-WebRequest `
        -Uri "https://api.godaddy.com/v1/domains/$($domain)/records" `
        -Method Patch `
        -ContentType 'application/json' `
        -Body ($body | ConvertTo-Json -AsArray) `
        -Headers $authorizationHeader

    Write-Output "TXT record configured successfully"
}
