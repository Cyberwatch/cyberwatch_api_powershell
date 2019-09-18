# Cyberwatch Api Powershell Client

## Prerequisites

- [ ] Powershell v5

## Usage

- Download and run `CyberwatchApi.psm1` with Powershell

```powershell
wget 'https://raw.githubusercontent.com/Cyberwatch/cyberwatch_api_powershell/master/CyberwatchApi.psm1' | iex
```

Or import it from Powershell Gallery:

```powershell
Install-Module -Scope CurrentUser -Name CyberwatchApi
```

- Use your personal credentials :

```powershell
PS> $API_KEY = "ezB15A1...."
PS> $SECRET_KEY = "TmKvmH..."
PS> $API_URL = "https://cyberwatch.local"
```

- Create a `ApiClient` :

```powershell
PS> $client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY
```

- Use the client to ping the API:

```powershell
PS> $client.ping()

uuid
----
3445a974-6a21-4ec7-a504-31ccf5caf2e5
```

- Use the client to retrive servers:

```powershell
PS> $client.servers()

id                      : 0000000084e8f76111d34c31a4572938
hostname                : DESKTOP-8000000
last_communication      : 2019-05-07T16:49:27.000+02:00
reboot_required         : False
agent_version           : 3.1
remote_ip               : 172.25.0.1
boot_at                 : 2019-05-06T09:01:32.000+02:00
criticality             : criticality_medium
updates_count           : 2
cve_announcements_count : 64
category                : desktop
status                  : @{comment=Vulnerable}
os                      : @{key=windows_10; name=Windows 10; arch=; eol=2025-10-14T02:00:00.000+02:00; short_name=Win 10; type=Os::Windows;
                          created_at=2017-10-18T17:44:41.000+02:00; updated_at=2017-10-18T17:44:41.000+02:00}
...


```

- Use the client to retreive remote accesses:

```powershell
PS> $client.remote_accesses()

id         : 123
type       : CbwRam::RemoteAccess::WinRm::WithNegotiate
address    : example.com
port       : 5985
is_valid   : True
created_at : 2019-03-15T09:03:06.000+01:00
updated_at : 2019-05-10T22:57:10.000+02:00
server     : @{id=0000000067e0ae7117b5ecb6c091cdf; hostname=example.com; last_communication=2019-03-15T10:44:24.000+01:00; reboot_required=True; 
             agent_version=; remote_ip=172.25.0.1; boot_at=2019-03-15T08:46:34.000+01:00; 
             criticality=criticality_medium; updates_count=0; cve_announcements_count=0; category=server}
node       : @{id=1; name=mynode; created_at=2018-09-12T17:16:02.000+02:00; updated_at=2019-05-20T12:01:07.000+02:00}
...


```

- Use the client to create a remote access:

```powershell
PS > $ram_params = @{
        type= "CbwRam::RemoteAccess::WinRm::WithNegotiate"
        address= "test.com"
        port= "5985"
        login= "myLogin"
        password= "myPassword"
        node= "myNodeName"
}

PS > $client.create_remote_access($ram_params)


id         : 157
type       : CbwRam::RemoteAccess::WinRm::WithNegotiate
address    : test.com
port       : 5985
is_valid   : 
created_at : 2019-05-21T13:44:29.000+02:00
updated_at : 2019-05-21T13:44:29.000+02:00
server     : @{id=18d2fc32acf9572830685df73b8fcf62; hostname=test.com; last_communication=; reboot_required=; agent_version=; remote_ip=test.com; 
             boot_at=; criticality=criticality_medium; updates_count=0; cve_announcements_count=0; category=server}

```

- Use the client to retreive a remote access details (here the last created remote access) :

```
PS > $ram = $client.remote_accesses() | Select-Object -Last 1
PS > $client.remote_access($ram.id)

id         : 157
type       : CbwRam::RemoteAccess::WinRm::WithNegotiate
address    : test.com
port       : 5985
is_valid   : False
created_at : 2019-05-21T13:44:29.000+02:00
updated_at : 2019-05-21T13:44:29.000+02:00
server     : @{id=18d2fc32acf9572830685df73b8fcf62; hostname=test.com; last_communication=; reboot_required=; agent_version=; remote_ip=test.com; 
             boot_at=; criticality=criticality_medium; updates_count=0; cve_announcements_count=0; category=server}

```

- Use the client to update a remote access (here the last created one):

```powershell
PS > $ram_params = @{
        type= "CbwRam::RemoteAccess::WinRm::WithNegotiate"
        address= "example.com"
        port= "5985"
        login= "myLogin"
        password= "myPassword"
        node= "myNodeName"
}

PS > $ram = $client.remote_accesses() | Select-Object -Last 1
PS > $client.update_remote_access($ram.id, $ram_params)
```

- Use the client to delete a remote access (here the last created one):

```powershell
PS > $ram = $client.remote_accesses() | Select-Object -Last 1
PS > $client.delete_remote_access($ram.id)
```

- Use the client to schedule updates on a specific server (here 2 updates identified by its IDs):

```powershell
PS > $update_ids = @{91482, 94515)
PS > $server_id = "c23673c6793f9fe5003a3e078cc5b1cc"

# If start and end parameters are not specified, the server's deployment policy is used

PS > $client.plan_updates($server_id, @{update_ids= $update_Ids; start="2019-09-14T03:00:00.000+02:00"; end="2019-09-14T09:00:00.000+02:00"})
```

## Using the API with a self-signed certificate

- Set up your client using the -trust_all_certificates parameter to allow requests to all certificates:

```powershell
PS> $client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $true
```

## More examples

See more examples and use cases in the [examples directory](examples)
