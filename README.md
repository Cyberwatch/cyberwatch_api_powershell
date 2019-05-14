# Cyberwatch Api Powershell Client

## Prerequisites

- [ ] Powershell v5

## Usage

- Download and run `cyberwatch_api.ps1` with Powershell

```powershell
wget 'https://raw.githubusercontent.com/Cyberwatch/cyberwatch_api_powershell/master/cyberwatch_api.psm1' | iex
```

- Use your personal credentials :

```powershell
PS> $API_KEY = "ezB15A1...."
PS> $SECRET_KEY = "TmKvmH..."
PS> $API_URL = "https://cyberwatch.local"
```

- Create a `ApiClient` :

```powershell
PS> $client = [ApiClient]::new($API_URL, $API_KEY, $SECRET_KEY)
```

- Use the client to ping the API :

```powershell
PS> $client.ping()

uuid
----
3445a974-6a21-4ec7-a504-31ccf5caf2e5
```

- Use the client to retrive servers :

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
