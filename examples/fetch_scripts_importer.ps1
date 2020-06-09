# -------------------------------------
# CONFIGURATION
# Please check and complete these items
# -------------------------------------

#Cyberwatch API authentication
$API_KEY = ""
$SECRET_KEY = ""
$API_URL = ""

# -------------------------
# RUN
# -------------------------

Function FetchImporterScripts
{
<#
.SYNOPSIS
        Example script to fetch Importer scanning scripts
#>

Write-Output "-------------------------------------------"
Write-Output "Cyberwatch - Fetch scanning scripts for Importer"
Write-Output "-------------------------------------------"

Write-Output "Would you like to download scripts attachments like .cab file? (Default is Yes)"
    $Readhost = Read-Host " ( y / n ) "
    Switch ($ReadHost)
     {
       Y {Write-Output "Yes, download attachments"; $DownloadAttachments=$true}
       N {Write-Output "No, skip attachments"; $DownloadAttachments=$false}
       Default {Write-Output "Default, download attachments"; $DownloadAttachments=$true}
     }

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
    Write-Output "ERROR: Connection failed. Please check the credentials. If needed, please reach the Cyberwatch support for further assistance."
    Return
}

# Clean old files
Write-Output "INFO: Cleaning old files..."
Remove-Item -LiteralPath ".\scripts" -Force -Recurse -ErrorAction Ignore
Write-Output "INFO: Done."

# Create the base folders
New-Item -path ".\scripts" -Force -ItemType Directory | Out-Null
New-Item -path ".\upload" -Force -ItemType Directory | Out-Null

# Fetch available scanning scripts from the API
Write-Output "INFO: Fetching available scanning scripts..."
$available_scripts = $client.fetch_importer_scripts()

# Fetch content of each scripts and attachments
$available_scripts | ForEach-Object{
    Write-Output "INFO: Fetching content for $($_.Type) ..."
    $scanning_script = $client.fetch_importer_script($_.id)
    $scanning_script_path = ".\"+$scanning_script.type.ToLower().replace("::", "\")

    if ($scanning_script.type -like '*Linux*') {
        $scanning_script_path = $scanning_script_path + '.sh'
    
    } elseif ($scanning_script.type -like '*Windows*') {
        $scanning_script_path = $scanning_script_path + '.ps1'
    }

    $scanning_script.contents | New-Item -path $scanning_script_path -Force -ItemType File | Out-Null

    if($scanning_script.attachment -And $DownloadAttachments) {
        $attachment_name  = ($scanning_script.attachment -split '/')[-1]
        $path = $scanning_script_path.SubString(0, $scanning_script_path.LastIndexOf('\')) + '\' + $attachment_name
        Invoke-WebRequest -Uri $scanning_script.attachment -OutFile $path
    }

    Write-Output "INFO: Script saved at $($(Resolve-Path -Path $scanning_script_path).Path)."
}

Write-Output "---------------------------------------------------------------------"
Write-Output "Script completed!"
Write-Output "To continue, please now:"
Write-Output "1) Run the fetched scripts on the targeted systems"
Write-Output "2) Put the results of the scripts as TXT files in the 'upload' folder"
Write-Output "3) Run the 'send_results' script"
Write-Output "---------------------------------------------------------------------"

}

FetchImporterScripts
