# -------------------------------------
# CONFIGURATION
# Please check and complete these items
# -------------------------------------

#Cyberwatch API authentication
$API_KEY = ""
$SECRET_KEY = ""
$API_URL = ""

$os = Read-Host -Prompt "Input the OS for scripts (from $API_URL/cbw_assets/os), ex : 'windows_10_21h1_64'"
$repositories = Read-Host -Prompt "Repositories to fetch (comma-separated values), ex : 'CIS_Benchmark, Cyberwatch'"

$filters = @{
    "os" = $os
    "repositories" = @($repositories)
    }

# -------------------------
# RUN
# -------------------------

Function FetchImporterScripts
{
<#
.SYNOPSIS
        Example script to fetch Compliance Airgap scripts
#>

Write-Output "-------------------------------------------"
Write-Output "Cyberwatch - Fetch Compliance Airgap scripts"
Write-Output "-------------------------------------------"

# Create the client variable
$client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY

# Test the client connection
Write-Output "INFO: Checking API connection and credentials..."
try
{
    $client.ping().uuid
    Write-Output "INFO: OK."
}
catch
{
  Write-Output "ERROR: Connection failed. Please check the following error message : '$_'"
  Return
}

# Clean old files
Write-Output "INFO: Cleaning old files..."
Remove-Item -LiteralPath ".\compliance_scripts" -Force -Recurse -ErrorAction Ignore
Write-Output "INFO: Done."

# Create the base folders
New-Item -path ".\compliance_scripts" -Force -ItemType Directory | Out-Null
New-Item -path ".\uploads" -Force -ItemType Directory | Out-Null

# Fetch available scanning scripts from the API
Write-Output "INFO: Fetching filtered compliance scripts..."
$available_scripts = $client.fetch_compliance_airgapped_scripts($filters)

$SH_EXECUTE_SCRIPT = '#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
mkdir ${DIR}/../uploads
for script in ${DIR}/*.sh; do
  script_basename=$(basename $script)
  result_filename=$(hostname)_${script_basename%.*}
  bash "$script" > ${DIR}/../uploads/$result_filename 2>&1
done
'

$SH_EXECUTE_SCRIPT | New-Item -path ".\compliance_scripts\run.sh" -Force -ItemType File | Out-Null

$PS1_EXECUTE_SCRIPT = '$hostname = [System.Net.Dns]::GetHostName()
If ( !( Test-Path -Path .\\..\\uploads )) { New-Item -ItemType Directory -Force -Path .\\..\\uploads | Out-Null }
Get-ChildItem -Path "$PSScriptRoot" -Filter "*.ps1" | ForEach-Object {
  If ($_.FullName -NotLike ("*" + $MyInvocation.MyCommand.Name + "*")) {
  Write-Host ("Current script: " + $_.FullName)
  & $_.FullName 2>&1 > $("$PSScriptRoot\\..\\uploads\\" + $hostname + "_" + $_.BaseName + ".txt")
  }
}
'

$PS1_EXECUTE_SCRIPT | New-Item -path ".\compliance_scripts\run.ps1" -Force -ItemType File | Out-Null

# Fetch content of each scripts and attachments
$available_scripts | ForEach-Object{
    Write-Output "INFO: Fetching content for $($_.filename) ..."
    $scanning_script = ($_)
    $scanning_script_path = ".\compliance_scripts\"+$scanning_script.filename.ToLower().replace("::", "\")

    $scanning_script.script_content | New-Item -path $scanning_script_path -Force -ItemType File | Out-Null

    Write-Output "INFO: Script saved at $($(Resolve-Path -Path $scanning_script_path).Path)."
}

Write-Output "---------------------------------------------------------------------"
Write-Output "Script completed!"
Write-Output "To continue, please now:"
Write-Output "1) Run the fetched scripts with 'run.ps1' or 'run.sh' on the targeted systems"
Write-Output "2) Put the results of the scripts as TXT files in the 'upload' folder"
Write-Output "3) Run the 'send_results_compliance_airgap' script"
Write-Output "---------------------------------------------------------------------"

}

FetchImporterScripts
