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

- Create an `ApiClient` :

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

- Use the client to retrieve servers:

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

- Use the client to retrieve remote accesses:

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

- Use the client to retrieve a remote access details (here the last created remote access) :

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

PS > $client.server_schedule_updates($server_id, @{update_ids= $update_Ids; start="2019-09-14T03:00:00.000+02:00"; end="2019-09-14T09:00:00.000+02:00"})
```

- Use the client to retrieve all groups:

```powershell
PS> $client.groups()

id          : 171
name        : groupe1
description : main group
color       : #12AFCB
created_at  : 2019-09-26T14:30:54.000+02:00
updated_at  : 2019-09-26T14:30:54.000+02:00
...

```

- Use the client to get details about a specific CVE:

```powershell
PS> $client.cve_announcement("CVE-2017-0146")

cve_code      : CVE-2017-0146
score         : 8.1
score_v2      : 9.3
score_v3      : 8.1
level         : level_high
published     : 2017-03-17T01:59:00.000+01:00
content       : The SMBv1 server in Microsoft Windows Vista SP2; Windows Server 2008 SP2 and R2 SP1; Windows 
                7 SP1; Windows 8.1; Windows Server 2012 Gold and R2; Windows RT 8.1; and Windows 10 Gold, 
                1511, and 1607; and Windows Server 2016 allows remote attackers to execute arbitrary code 
                via crafted packets, aka "Windows SMB Remote Code Execution Vulnerability." This 
                vulnerability is different from those described in CVE-2017-0143, CVE-2017-0144, 
                CVE-2017-0145, and CVE-2017-0148.
last_modified : 2018-06-21T03:29:00.000+02:00
created_at    : 2017-03-14T23:01:28.000+01:00
updated_at    : 2019-09-15T08:57:01.000+02:00
exploitable   : True
servers       : {@{id=9cabadffe05cbdaedd3cee7ef763956f; host=AC1SRV0004; os=; updates=System.Object[];
                active=False; ignored=False; comment=; fixed_at=2018-03-20T17:29:51.000+01:00}...}

```

- Use the client to get a filtered list of CVEs or all of them:

```powershell
PS > $params = @{
        level= "level_critical"
        exploitable= "true"
}

PS > $client.cve_announcements($params)

content       : Microsoft Internet Explorer 6 through 11 allows remote attackers to execute 
                arbitrary code or cause a denial of service (memory corruption) via a crafted 
                web site, aka "Internet Explorer Memory Corruption Vulnerability," a different 
                vulnerability than CVE-2014-0282, CVE-2014-1779, CVE-2014-1799, CVE-2014-1803, 
                and CVE-2014-2757.
cve_code      : CVE-2014-1775
last_modified : 2018-10-13T00:06:00.000+02:00
level         : level_critical
published     : 2014-06-11T06:56:00.000+02:00
score         : 9.0
score_v2      : 9.3
score_v3      : 
exploitable   : True
cvss          : @{access_vector=access_vector_network; 
                access_complexity=access_complexity_medium; 
                authentication=authentication_none; 
                confidentiality_impact=confidentiality_impact_complete; 
                integrity_impact=integrity_impact_complete; 
                availability_impact=availability_impact_complete}
cvss_v3       : 
cwe           : @{cwe_id=CWE-119}
...

```

- Use the client to retrieve all users:

```powershell
PS> $client.users()

id            : 1
login         : test@cyberwatch.fr
name          : Cyberwatch
firstname     : Test
email         : test@cyberwatch.fr
locale        : en
auth_provider : ldap
server_groups :  {@{id=79; name=Test; role=auditor}}
...

```

## Using the API with a self-signed certificate

- Set up your client using the -trust_all_certificates parameter to allow requests to all certificates:

```powershell
PS> $client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $true
```

## More examples

See more examples and use cases in the [examples directory](examples)
