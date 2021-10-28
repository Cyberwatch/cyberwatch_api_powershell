# -------------------------------------
# CONFIGURATION
# Please check and complete these items
# -------------------------------------

#Cyberwatch API authentication
$API_URL = ""
$API_KEY = ""
$SECRET_KEY = ""
# Filter
$category = "server"

# -------------------------
# RUN
# -------------------------

$client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $true

$all_agents_filtered = @()

$agents = $client.agents()

foreach ($agent in $agents) {
    $asset = $client.server($agent.server_id)
    if ($asset.os.type -eq "Os::Windows" -and $asset.category -eq $category) {
        $all_agents_filtered += [pscustomobject]@{
            Hostname     = $asset.Hostname
            Addresse_IP  = $agent.remote_ip
            Type         = $asset.category
            OS           = $asset.os.name
            Date_De_Creation = $asset.created_at
            Date_Derniere_Communication = $asset.last_communication

        }
    }
}

$all_agents_filtered | Sort-Object -Property 'Date_De_Creation' -Descending | Export-Csv -NoTypeInformation -Delimiter ';' -Path (join-path ((Get-Item .).FullName) "$(get-date -f dd-MM)_export_cyberwatch.csv")

cmd /c pause
