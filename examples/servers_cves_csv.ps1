"""Servers CVEs from group to CSV"""

$client = Get-CyberwatchApi -conf_file api.conf

# Find the ID on [CYBERWATCH_URL]/cbw_assets/groups and edit the concerned stored credential (the ID will be in the URL)
# Example: "https://[CYBERWATCH_URL]/cbw_assets/groups/9/edit" the GROUP_ID is '9'
$GROUP_ID = ""

$servers = $client.servers(@{
        "group_id" = $GROUP_ID
    })

#Get all servers details + all CVE code
$all_servers = @()
foreach ($server in $servers) {
    $asset = $client.server($server.id)
    $all_servers += $asset
}

# Find corresponding technology of each server + build CSV list
foreach ($server in $all_servers) {
    $to_export = @()
    foreach ($update in $server.updates) {
        foreach ($update_cve in $update.cve_announcements) {
            # Find details of each cve from update
            foreach ($server_cve in $server.cve_announcements) {
                if ($server_cve.cve_code -eq $update_cve) {
                    $cve = $server_cve
                }
            }

            if ($null -eq $update.target.product) {
                $techno = $update.current.product
            }
            else {
                $techno = $update.target.product
            }

            $to_export += [pscustomobject]@{
                Hostname                  = $server.Hostname
                Technologie               = $techno
                Vulnerabilite             = $cve.cve_code
                Derniere_analyse          = $server.analyzed_at
                Score_CVSS                = $cve.score
                Vulnerabilite_prioritaire = $cve.prioritized
                Date_de_detection         = $cve.detected_at
                Ignoree                   = $cve.ignored
                Commentaire               = $cve.comment
            }
        }
    }
    # Export CSV
    $to_export | Sort-Object -Property 'Hostname' -Descending | Export-Csv -NoTypeInformation -Delimiter ';' -Path (join-path ((Get-Item .).FullName) "$(get-date -f dd-MM)_$($server.Hostname)_cyberwatch.csv")
}
