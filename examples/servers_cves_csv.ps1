"""Servers CVEs from group to CSV"""

$client = Get-CyberwatchApi -conf_file api.conf

# Find the ID on [CYBERWATCH_URL]/cbw_assets/groups and edit the concerned stored credential (the ID will be in the URL)
# Example: "https://[CYBERWATCH_URL]/cbw_assets/groups/9/edit" the GROUP_ID is '9'
$GROUP_ID = ""

$servers = $client.servers(@{
    "group_id" = $GROUP_ID
})

# Get all servers details + all CVE code
$all_servers = @()
$all_cves = @()
foreach ($server in $servers) {
    if ($server.cve_announcements_count -gt 0) {
        $asset = $client.server($server.id)
        $all_servers += $asset
        foreach ($cve in $asset.cve_announcements) {
            $all_cves += $cve.cve_code
        }
    }
}

# Get all CVE details from all CVE codes
$all_cves_details = @{}
foreach($cve in $all_cves | Select-Object -Unique) {
    $all_cves_details[$cve] = $client.cve_announcement($cve)
}

# Find corresponding technology of each server + build CSV list
$to_export = @()
foreach ($server in $all_servers) {
    foreach ($cve in $server.cve_announcements) {
        foreach ($cve_server in $all_cves_details[$cve.cve_code].servers) {
            if ($cve_server.id -eq $server.id) {
                if ($null -eq $cve_server.updates[0].target.product) {
                    $technology = $cve_server.updates[0].current.product
                }
                else {
                    $technology = $cve_server.updates[0].target.product
                }
            }
        }

        $to_export += [pscustomobject]@{
            Hostname     = $server.Hostname
            Technologie  = $technology
            Vulnerabilite  = $cve.cve_code
            Derniere_analyse = $server.analyzed_at
            Score_CVSS = $cve.score
            Vulnerabilite_prioritaire = $cve.prioritized
            Date_de_detection = $cve.detected_at
            Ignoree = $cve.ignored
            Commentaire = $cve.comment
        }
    }
}

# Export CSV
$to_export | Sort-Object -Property 'Hostname' -Descending | Export-Csv -NoTypeInformation -Delimiter ';' -Path (join-path ((Get-Item .).FullName) "$(get-date -f dd-MM)_export_cyberwatch.csv")

cmd /c pause
