# Powershell Cyberwatch Api Client

Function SendApiRequest
{
<#
.SYNOPSIS
        Cyberwatch API Powershell Client.
.DESCRIPTION
        Send REST Query to Cyberwatch API
.EXAMPLE
        SendApiRequest -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -http_method $http_method -request_URI $request_URI
.PARAMETER api_url
        Your Cyberwatch instance base url
#>
Param    (
    [PARAMETER(Mandatory=$true)][string]$api_url = 'https://cyberwatch.local',
    [PARAMETER(Mandatory=$true)][string]$api_key,
    [PARAMETER(Mandatory=$true)][string]$secret_key,
    [PARAMETER(Mandatory=$true)][string]$http_method = 'GET',
    [PARAMETER(Mandatory=$true)][string]$request_URI = '/api/v2/ping',
    [PARAMETER(Mandatory=$false)][Hashtable]$content
    )

    if($content) {
        $content_type = 'application/json'
        $json_body = $content | ConvertTo-Json
    }
    else {
        $content_type = ''
    }

    $content_MD5 = ''
    $timestamp = [System.DateTime]::UtcNow.ToString('R')
    $message = "$http_method,$content_type,$content_MD5,$request_URI,$timestamp"
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SECRET_KEY)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
    $signature = [Convert]::ToBase64String($signature)

    Invoke-RestMethod -Uri "${API_URL}${request_URI}" -Method $http_method -Headers @{
        "accept"="application/json";
        "Date"=$timestamp
        "Authorization"="Cyberwatch APIAuth-HMAC-SHA256 ${API_KEY}:$signature"
    } -ContentType $content_type -Body $json_body
}

Class CbwApiClient {
    [string]$api_url
    [string]$api_key
    [string]$secret_key

    CbwApiClient ([string]$api_url, [string]$api_key, [string]$secret_key)
    {
        $this.api_url = $api_url
        $this.api_key = $api_key
        $this.secret_key = $secret_key
    }

    [object] request([string]$http_method, [string]$request_URI) {
        return SendApiRequest -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI
    }

    [object] request([string]$http_method, [string]$request_URI, [Hashtable]$content) {
        return SendApiRequest -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI -content $content
    }

    [object] ping()
    {
        return $this.request('GET', '/api/v2/ping')
    }

    [object] servers()
    {
        return $this.request('GET', '/api/v2/servers')
    }

    [object] server([string]$id)
    {
        return $this.request('GET', "/api/v2/servers/${id}")
    }

    [object] update_server([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v2/servers/${id}", $content)
    }

    [object] delete_server([string]$id)
    {
        return $this.request('DELETE', "/api/v2/servers/${id}")
    }

    [object] server_schedule_updates([string]$id, [Object]$content)
    {
        return $this.request('POST', "/api/v2/servers/${id}/updates", $content)
    }

    [object] remote_accesses()
    {
        return $this.request('GET', '/api/v2/remote_accesses')
    }

    [object] create_remote_access([Object]$content)
    {
        return $this.request('POST', '/api/v2/remote_accesses', $content)
    }

    [object] remote_access([string]$id)
    {
        return $this.request('GET', "/api/v2/remote_accesses/${id}")
    }

    [object] update_remote_access([string]$id, [Object]$content)
    {
        return $this.request('PATCH', "/api/v2/remote_accesses/${id}", $content)
    }

    [object] delete_remote_access([string]$id)
    {
        return $this.request('DELETE', "/api/v2/remote_accesses/${id}")
    }

    [object] groups([string]$id)
    {
        return $this.request('GET', "/api/v2/groups")
    }
}


function Get-CyberwatchApi
{
<#
.SYNOPSIS
        Cyberwatch API Powershell Client.
.DESCRIPTION
        Send REST Query to Cyberwatch API
.EXAMPLE
        Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY
        Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $ALLOW_SELFSIGNED
.PARAMETER api_url
        Your Cyberwatch instance base url
#>
Param    (
    [PARAMETER(Mandatory=$true)][string]$api_url = 'https://cyberwatch.local',
    [PARAMETER(Mandatory=$true)][string]$api_key,
    [PARAMETER(Mandatory=$true)][string]$secret_key,
    [PARAMETER(Mandatory=$false)][bool]$trust_all_certificates = $false
    )

    # Allow request to self-signed certificate
    if($trust_all_certificates) {
        add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
          }
        }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    return [CbwApiClient]::new($api_url, $api_key, $secret_key)
}

