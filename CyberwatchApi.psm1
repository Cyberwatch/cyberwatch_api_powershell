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
    [PARAMETER(Mandatory=$true)][string]$api_url,
    [PARAMETER(Mandatory=$true)][string]$api_key,
    [PARAMETER(Mandatory=$true)][string]$secret_key,
    [PARAMETER(Mandatory=$true)][string]$http_method,
    [PARAMETER(Mandatory=$true)][string]$request_URI,
    [PARAMETER(Mandatory=$false)][Hashtable]$content,
    [PARAMETER(Mandatory=$false)][Hashtable]$query_params
    )

    $uri = "${API_URL}${request_URI}"

    if ($content) {
        $content_type = 'application/json'
        $body_content = $content | ConvertTo-Json
    }
    elseif ($query_params) {
        $content_type = ''
        Add-Type -AssemblyName System.Web
        $query_strings = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        foreach ($key in $query_params.GetEnumerator()) {
            if($key.Value -is [system.array]){
                foreach ($value in $key.Value) {
                    $query_strings.Add($key.Key + "[]", "${value}")
                }
            } else {$query_strings.Add($key.Key, $key.Value)}
        }

        $uriRequest = [System.UriBuilder]"${API_URL}${request_URI}"
        $uriRequest.Query = $query_strings.ToString()
        $params = $uriRequest.Query
        $body_content = $content
        $uri = "${API_URL}${request_URI}${params}"
    }

    $content_MD5 = ''
    $timestamp = [System.DateTime]::UtcNow.ToString('R')
    $message = "$http_method,$content_type,$content_MD5,$request_URI$params,$timestamp"
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SECRET_KEY)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
    $signature = [Convert]::ToBase64String($signature)

    Invoke-WebRequest -Uri $uri -Method $http_method -Headers @{
        "accept"        = "application/json";
        "Date"          = $timestamp
        "Authorization" = "Cyberwatch APIAuth-HMAC-SHA256 ${API_KEY}:$signature"
    } -ContentType $content_type -Body $body_content -UseBasicParsing
}

Function SendApiRequestPagination
{
Param    (
    [PARAMETER(Mandatory=$true)][string]$api_url,
    [PARAMETER(Mandatory=$true)][string]$api_key,
    [PARAMETER(Mandatory=$true)][string]$secret_key,
    [PARAMETER(Mandatory=$true)][string]$http_method,
    [PARAMETER(Mandatory=$true)][string]$request_URI,
    [PARAMETER(Mandatory=$false)][Hashtable]$content,
    [PARAMETER(Mandatory=$false)][Hashtable]$query_params = @{}
    )

    if ($query_params.ContainsKey("per_page") -eq $false) {
        $query_params.Add("per_page", 100)
    }

    $response = SendApiRequest -api_url $api_url -api_key $api_key -secret_key $secret_key -http_method $http_method -request_URI $request_URI -content $content -query_params $query_params
    if ($response.headers["link"] -match "[?&]page=(\d*)" -and $query_params.ContainsKey("page") -eq $false) {
        $last_page_number = $matches[1]
        1..$last_page_number | ForEach-Object {
        $query_params["page"] = $_;
        SendApiRequest -api_url $api_url -api_key $api_key -secret_key $secret_key -http_method $http_method -request_URI $request_URI -content $content -query_params $query_params | ConvertFrom-Json | ForEach-Object { $_ }
        }
    }

    else { $response | ConvertFrom-JSON }

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
        return SendApiRequest -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI | ConvertFrom-JSON
    }

    [object] request([string]$http_method, [string]$request_URI, [Hashtable]$content) {
        return SendApiRequest  -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI -content $content | ConvertFrom-JSON
    }

    [object] request_pagination([string]$http_method, [string]$request_URI) {
        return SendApiRequestPagination -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI
    }

    [object] request_pagination([string]$http_method, [string]$request_URI, [Hashtable]$query_params) {
        return SendApiRequestPagination -api_url $this.api_url -api_key $this.api_key -secret_key $this.secret_key -http_method $http_method -request_URI $request_URI -query_params $query_params
    }

    [object] ping()
    {
        return $this.request('GET', '/api/v3/ping')
    }

    [object] servers()
    {
        return $this.request_pagination('GET', '/api/v3/servers')
    }

    [object] servers([Object]$filters)
    {
        return $this.request_pagination('GET', '/api/v3/servers', $filters)
    }

    [object] server([string]$id)
    {
        return $this.request('GET', "/api/v3/servers/${id}")
    }

    [object] update_server([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/servers/${id}", $content)
    }

    [object] refresh_server([string]$id)
    {
        return $this.request('PUT', "/api/v3/servers/${id}/refresh")
    }

    [object] delete_server([string]$id)
    {
        return $this.request('DELETE', "/api/v3/servers/${id}")
    }

    [object] update_server_cve([string]$id, [string]$cve_code, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/servers/${id}/cve_announcements/${cve_code}", $content)
    }

    [object] server_schedule_updates([string]$id, [Object]$content)
    {
        return $this.request('POST', "/api/v3/servers/${id}/updates", $content)
    }

    [object] remote_accesses()
    {
        return $this.request_pagination('GET', '/api/v3/remote_accesses')
    }

    [object] remote_accesses([Object]$filters)
    {
        return $this.request_pagination('GET', '/api/v3/remote_accesses', $filters)
    }

    [object] remote_access([string]$id)
    {
        return $this.request('GET', "/api/v3/remote_accesses/${id}")
    }

    [object] create_remote_access([Object]$content)
    {
        return $this.request('POST', '/api/v3/remote_accesses', $content)
    }

    [object] update_remote_access([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/remote_accesses/${id}", $content)
    }

    [object] delete_remote_access([string]$id)
    {
        return $this.request('DELETE', "/api/v3/remote_accesses/${id}")
    }

    [object] groups()
    {
        return $this.request_pagination('GET', "/api/v3/groups")
    }

    [object] groups([Object]$filters)
    {
        return $this.request_pagination('GET', '/api/v3/groups', $filters)
    }

    [object] group([string]$id)
    {
        return $this.request('GET', "/api/v3/groups/${id}")
    }

    [object] create_group([Object]$content)
    {
        return $this.request('POST', '/api/v3/groups', $content)
    }

    [object] update_group([string]$id, [Object]$content)
    {
        return $this.request('PATCH', "/api/v3/groups/${id}", $content)
    }

    [object] delete_group([string]$id)
    {
        return $this.request('DELETE', "/api/v3/groups/${id}")
    }

    [object] cve_announcement([string]$id)
    {
        return $this.request('GET', "/api/v3/cve_announcements/${id}")
    }

    [object] cve_announcements()
    {
        return $this.request_pagination('GET', "/api/v3/cve_announcements")
    }

    [object] cve_announcements([Hashtable]$query_params)
    {
        return $this.request_pagination('GET', "/api/v3/cve_announcements", $query_params)
    }

    [object] update_cve_announcement([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/cve_announcements/${id}", $content)
    }

    [object] delete_cve_announcement([string]$id)
    {
        return $this.request('DELETE', "/api/v3/cve_announcements/${id}")
    }

    [object] users()
    {
        return $this.request_pagination('GET', "/api/v3/users")
    }

    [object] users([Hashtable]$filter)
    {
        return $this.request_pagination('GET', "/api/v3/users", $filter)
    }

    [object] user([string]$id)
    {
        return $this.request('GET', "/api/v3/users/${id}")
    }

    [object] nodes()
    {
        return $this.request_pagination('GET', "/api/v3/nodes")
    }

    [object] nodes([Hashtable]$filter)
    {
        return $this.request_pagination('GET', "/api/v3/nodes", $filter)
    }

    [object] node([string]$id)
    {
        return $this.request('GET', "/api/v3/nodes/${id}")
    }

    [object] delete_node([string]$id, [Object]$content)
    {
        return $this.request('DELETE', "/api/v3/nodes/${id}", $content)
    }

    [object] hosts()
    {
        return $this.request_pagination('GET', "/api/v3/hosts")
    }

    [object] hosts([Object]$filters)
    {
        return $this.request_pagination('GET', '/api/v3/hosts', $filters)
    }

    [object] host([string]$id)
    {
        return $this.request('GET', "/api/v3/hosts/${id}")
    }

    [object] create_host([Object]$content)
    {
        return $this.request('POST', '/api/v3/hosts', $content)
    }

    [object] update_host([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/hosts/${id}", $content)
    }

    [object] delete_host([string]$id)
    {
        return $this.request('DELETE', "/api/v3/hosts/${id}")
    }

    [object] security_issues()
    {
        return $this.request('GET', "/api/v3/security_issues")
    }

    [object] security_issues([Object]$filters)
    {
        return $this.request_pagination('GET', '/api/v3/security_issues', $filters)
    }

    [object] security_issue([string]$id)
    {
        return $this.request('GET', "/api/v3/security_issues/${id}")
    }

    [object] create_security_issue([Object]$content)
    {
        return $this.request('POST', '/api/v3/security_issues', $content)
    }

    [object] update_security_issue([string]$id, [Object]$content)
    {
        return $this.request('PUT', "/api/v3/security_issues/${id}", $content)
    }

    [object] delete_security_issue([string]$id)
    {
        return $this.request('DELETE', "/api/v3/security_issues/${id}")
    }

    [object] agents()
    {
        return $this.request_pagination('GET', "/api/v3/agents")
    }

    [object] agents([Hashtable]$filter)
    {
        return $this.request_pagination('GET', "/api/v3/agents", $filter)
    }

    [object] agent([string]$id)
    {
        return $this.request('GET', "/api/v3/agents/${id}")
    }

    [object] delete_agent([string]$id)
    {
        return $this.request('DELETE', "/api/v3/agents/${id}")
    }

    [object] fetch_importer_scripts()
    {
        return $this.request('GET', "/api/v2/cbw_scans/scripts")
    }

    [object] fetch_importer_script([string]$id)
    {
        return $this.request('GET', "/api/v2/cbw_scans/scripts/${id}")
    }

    [object] send_result_importer([Object]$content)
    {
        return $this.request('POST', "/api/v2/cbw_scans/scripts", $content)
    }

    [object] compliance_servers()
    {
        return $this.request_pagination("GET", "/api/v3/compliance/servers")
    }

    [object] compliance_servers([Hashtable]$filter)
    {
        return $this.request_pagination("GET", "/api/v3/compliance/servers", $filter)
    }

    [object] compliance_server([string]$id)
    {
        return $this.request("GET", "/api/v3/compliance/servers/${id}")
    }

    [object] recheck_rules([string]$id)
    {
        return $this.request("PUT", "/api/v3/compliance/servers/${id}/recheck_rules")
    }

    [object] compliance_rules()
    {
        return $this.request("GET", "/api/v3/compliance/rules")
    }

    [object] compliance_rules([Hashtable]$filter)
    {
        return $this.request("GET", "/api/v3/compliance/rules", $filter)
    }

    [object] compliance_rule([string]$id)
    {
        return $this.request("GET", "/api/v3/compliance/rules/${id}")
    }

    [object] create_compliance_rule([Object]$content)
    {
        return $this.request("POST", "/api/v3/compliance/rules", $content)
    }

    [object] delete_compliance_rule([string]$id)
    {
        return $this.request("DELETE", "/api/v3/compliance/rules/${id}")
    }

    [object] recheck_servers([string]$id)
    {
        return $this.request("PUT", "/api/v3/compliance/rules/${id}/recheck_servers")
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
    [PARAMETER(Mandatory=$true)][string]$api_url,
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

