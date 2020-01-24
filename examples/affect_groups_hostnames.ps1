# Pass a list of groups to retrieve their ID
Function match_group_ids {
    Param(
        [PARAMETER(Mandatory=$true)][Collections.Generic.List[string]]$groups,
        [PARAMETER(Mandatory=$false)][bool]$create_missing = $true
    )

    $groups_ids = New-Object Collections.Generic.List[Int]
    $cyberwatch_groups = $client.groups()

    foreach($cyberwatch_group in $cyberwatch_groups) {
        foreach($group in $groups) {
            If($group -eq $cyberwatch_group.name) {
                # Add the ID to the list
                $groups_ids.Add($cyberwatch_group.id)

                # Remove the group from the list of groups
                $groups = foreach ($_ in $groups) { if ($_ -ne $group){ $_} }
            }
        }
    }

    # If allowed to, create the groups that were not found and add their IDs to the list
    If($create_missing) {
        foreach($group in $groups) {
            $new_group = $client.create_group(@{"name" = $group})
            $groups_ids.Add($new_group.id)
        }
    }

    return $groups_ids
}

# Function used to affect groups to the servers
Function affect_groups_to_servers {
    Param(
        [PARAMETER(Mandatory=$true)][Collections.Generic.List[string]]$hostnames,
        [PARAMETER(Mandatory=$true)][Collections.Generic.List[Int]]$groups_ids,
        [PARAMETER(Mandatory=$true)][System.Array]$servers
    )

    foreach($server in $servers) {
        If ($server.hostname -in $hostnames) {
            # Create the list of group IDs that will be affected to each computer (new groups and existing groups)
            $all_groups_ids = New-Object Collections.Generic.List[Int]
            foreach ($group_id in $groups_ids) { $all_groups_ids.Add($group_id)}

            $server_full = $client.server($server.id)
            foreach($group in $server_full.groups) {
                $all_groups_ids.Add($group.id)
            }

            $client.update_server($server.id, @{"groups" = $all_groups_ids})
        }
    }
}

$API_KEY = ""
$SECRET_KEY = ""
$API_URL = ""

# Specify the list of hostnames to which the script will affect the groups
$hostnames = @("first_hostname", "second_hostname", "third_hostname")

# List of groups to be affected.
$groups = @("first_group", "second_group", "third_group")

$client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $true

# Optional filters to retrieve the list of servers
$FILTERS = @{
    "per_page" = "200"
    "page" = "5"
}

# Retrieve the list of servers
$servers = $client.servers($FILTERS)

# For each group specified, find its ID or create it if it is missing (optional)
$groups_ids = match_group_ids -groups $groups -create_missing $true

# Affect a list of groups to a list of specific hostnames taken from a list of servers
affect_groups_to_servers -hostnames $hostnames -groups_ids $groups_ids -servers $servers
