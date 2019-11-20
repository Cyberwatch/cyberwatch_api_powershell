#requires -modules ActiveDirectory
#requires -modules CyberwatchApi

<#
.SYNOPSIS
        Cyberwatch API script to crawl and compare results from an Active Directory.
        This script requires the ActiveDirectory module. You can import it using the command:
        Install-WindowsFeature -Name RSAT-AD-PowerShell
.DESCRIPTION
        This script serves as an example, it can and should be adapted to your needs.
        For this particular example, you will need:
            - access to the Active Directory (most likely running the script on your DC)
            - Cyberwatch Powershell API installed (https://github.com/Cyberwatch/cyberwatch_api_powershell)
            - A login/password to connect to the computers if you wish to create missing agentless connections /!\ there are better (more secure) ways to handle credentials than the way it is done in this example /!\
        What this example does:
            - connects to the Active Directory (given it has access to it)
            - compare computers present in the AD to those present in Cyberwatch
            - Can (optional) create the missing agentless connections (default option does not create these connections)
            - Can (optional) delete WinRM agentless connections not found in the AD (default option does not delete these connections)
            - Will log the results in the file crawl_AD.log
.EXAMPLE
        .\crawl_AD.ps1 # running with default parameters (readonly)
.EXAMPLE
        .\crawl_AD.ps1 -remove_outside_AD $true -create_missing_rams $true -use_default_credentials $true  # Allows the script to create missing connections (using default credentials) and delete those not found in the AD
.PARAMETER trust_all_certificates
        Allows the script to connect to Cyberwatch instances with a self-signed certificate
.PARAMETER create_missing_rams
        Allows the script to create agentless connections for computers found in the AD and missing from Cyberwatch.
        This option requires you to provide a generic login/password (or allow the use of default credentials) to create the WinRM connections on your computers.
        You will also need to specify the name of the Cyberwatch node responsible for initiating the connection.
.PARAMETER remove_outside_AD
        Allows the script to remove agentless connections for computers not found in the AD
.PARAMETER use_default_credentials
        Allows the script to use Cyberwatch's default credentials to create agentless connections (won't require a login/password)
#>

Param (
    [PARAMETER(Mandatory=$false)][bool]$trust_all_certificates = $false,
    [PARAMETER(Mandatory=$false)][bool]$create_missing_rams = $false,
    [PARAMETER(Mandatory=$false)][bool]$remove_outside_AD = $false,
    [PARAMETER(Mandatory=$false)][bool]$use_default_credentials = $true
)

$LOGFILE = "crawl_AD.log"
# Cyberwatch API authentication
$API_KEY = ""
$SECRET_KEY = ""
$API_URL = ""

# These variables should be filled if you want to create agentless connections without using default credentials
$WINRM_login = ""
$WINRM_password = ""

# Specify the Cyberwatch node's ID that will be used to initiate agentless connections
$cyberwatch_node_id = ""

If(($API_KEY -eq "") -OR ($SECRET_KEY -eq "") -OR ($API_URL -eq "")) {
    Write-Error -Category AuthenticationError -RecommendedAction "Please provide Cyberwatch's API infos" -TargetObject $API_KEY "Missing API keys or URL"
    exit
}

If (($create_missing_rams -eq $true) -AND ($cyberwatch_node_id -eq "")) {
    Write-Error -Category InvalidData -RecommendedAction "Please provide the name of the Cyberwatch node to create agentless connections" -TargetObject $cyberwatch_node_id "Missing Cyberwatch node id"
    exit
}

If(($use_default_credentials -eq $false) -AND (($WINRM_login -eq "") -OR ($WINRM_password -eq ""))) {
    Write-Error -Category InvalidData  -RecommendedAction "Please provide the required credentials to create agentless connections" -TargetObject $WINRM_login "Missing WINRM credentials"
    exit
}

Write-Output "******************** $(Get-Date -Format "dd/MM/yyyy HH:mm") Script started with the following options : ********************
trust_all_certificates = $trust_all_certificates
create_missing_rams = $create_missing_rams
remove_outside_AD = $remove_outside_AD
use_default_credentials = $use_default_credentials
**************************************************************************************" >> $LOGFILE

$AD_account = Read-Host "Please enter an account login to request your Active Directory"

# Retrieves the list of Computers in your AD with an optional filter. The filter can be set as '*' to retrieve all computers
$Filter = '*'
$SearchBase = 'OU=test,DC=example,DC=com'
$ComputerList_AD = Get-ADComputer -Filter $Filter -SearchBase $SearchBase -Credential $AD_account -Properties IPv4Address | Select-Object -Property name, IPv4Address

if(!$ComputerList_AD) {
    Write-Output "No computer found from the AD request, exiting..."
    exit
}

$client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $trust_all_certificates

# Retrieves the list of Computers in Cyberwatch
$ComputerList_CBW = $client.remote_accesses() | Where-Object -Property type -Like ('CbwRam::RemoteAccess::WinRm::*') | Select-Object -Property id, address

if(!$ComputerList_CBW) {
    Write-Output "No computer found from the Cyberwatch API request, exiting..."
    exit
}

foreach ($server in $ComputerList_AD) {
    If (($ComputerList_CBW | Select-Object -ExpandProperty address) -contains ($server | Select-Object -ExpandProperty IPv4Address)) {
        Write-Output "`r`nThe server $server is already monitored by Cyberwatch" >> $LOGFILE
    }
    Else {
        Write-Output "`r`nThe server $server is present in your AD and not in Cyberwatch" >> $LOGFILE

        If ($create_missing_rams) {
            # Create the remote access in Cyberwatch if found in AD and not in Cyberwatch
            If ($use_default_credentials) {
                $ram_params = @{type = "CbwRam::RemoteAccess::WinRm::WithNegotiate"; address = ($server | Select-Object -ExpandProperty IPv4Address); port = "5985"; node_id = $cyberwatch_node_id}
            } else {
                $ram_params = @{type = "CbwRam::RemoteAccess::WinRm::WithNegotiate"; address = ($server | Select-Object -ExpandProperty IPv4Address); port = "5985"; auth_password = $WINRM_login; priv_password = $WINRM_password; node_id = $cyberwatch_node_id}
            }
            Write-Output "`r`nCreating a RAM object for address (using default credentials : $use_default_credentials) : " $ram_params.address >> $LOGFILE
            $client.create_remote_access($ram_params)
        }
    }
}

If ($remove_outside_AD) {
    foreach ($server in $ComputerList_CBW) {
        If(-Not (($server | Select-Object -ExpandProperty address) -in ($ComputerList_AD | Select-Object -ExpandProperty IPv4Address))) {
            # Delete the agentless connection if not found in AD
            Write-Output "`r`nDeleting RAM object : $server" >> $LOGFILE
            $client.delete_remote_access($server.id)
        }
    }
}
