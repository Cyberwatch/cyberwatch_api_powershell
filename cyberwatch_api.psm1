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
    [PARAMETER(Mandatory=$true)][string]$request_URI = '/api/v2/ping'
    )

    $content_type = ''
    # $content = ""
    # $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    # $Hasher = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    # $md5 = $Hasher.ComputeHash($bytes)
    # $content_MD5 = [System.Convert]::ToBase64String($md5)
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
    }
}

Class ApiClient {
    [string]$api_url
    [string]$api_key
    [string]$secret_key

    ApiClient ([string]$api_url, [string]$api_key, [string]$secret_key)
    {
        $this.api_url = $api_url
        $this.api_key = $api_key
        $this.secret_key = $secret_key
    }

    [object] request([string]$http_method, [string]$request_URI) {
        return SendApiRequest -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI
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
}
