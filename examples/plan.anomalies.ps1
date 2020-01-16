# Powershell script to retry every updates with an anomaly status on every computers at their deploying period

$servers = $client.servers()

foreach ($server in $servers) {
    $serverFull = $client.server($server.id)
    $serverUpdates = $serverFull.updates
    $updateIds = @()
    foreach ($update in $serverUpdates) {
        If ($update.status.comment -eq "anomaly") {
            $updateIds += $update.id
        }
    }
    $client.server_schedule_updates($server.id, @{updates_ids= @($updateIds)})
}