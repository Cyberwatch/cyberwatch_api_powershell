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

Write-Output "-------------------------------------------"
Write-Output "Cyberwatch - Send Compliance Airgap results for analysis"
Write-Output "-------------------------------------------"

Function SendResultsImporter
{
<#
.SYNOPSIS
        Example script to send Compliance Airgap scripts results
#>

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

# Load results and send them to Cyberwatch
Write-Output "INFO: Searching for available results..."
$available_results = Get-ChildItem -Recurse -File -Path ".\uploads"
Write-Output "INFO: Done. Found $($available_results.count) results to be processed and sent for analysis."

$available_results | ForEach-Object {
    Write-Output "INFO: Reading $($_.FullName) content..."
    $content = [IO.File]::ReadAllText($_.FullName)
    Write-Output "INFO: Sending $($_.FullName) content to the API..."
    # You can specify groups separated by commas ","
    $client.upload_compliance_airgapped_results(@{ output = $content })
    Write-Output "INFO: Done."
}


Write-Output "---------------------------------------------------------------------"
Write-Output "Script completed!"
Write-Output "Your scans are now being processed by your Cyberwatch nodes."
Write-Output "Please log on $API_URL to see the results."
Write-Output "---------------------------------------------------------------------"

}

SendResultsImporter
