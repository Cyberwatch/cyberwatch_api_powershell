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
Write-Output "Cyberwatch - Send results for analysis"
Write-Output "-------------------------------------------"

Function SendResultsImporter
{
<#
.SYNOPSIS
        Example script to send Importer scanning scripts results
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
    Write-Output "ERROR: Connection failed. Please check credentials. If needed, please reach the Cyberwatch support for further assistance."
    Return
}

# Load results and send them to Cyberwatch
Write-Output "INFO: Searching for available results..."
$available_results = Get-ChildItem -Recurse -File -Path ".\upload"
Write-Output "INFO: Done. Found $($available_results.count) results to be processed and sent for analysis."

$available_results | ForEach-Object {
    Write-Output "INFO: Reading $($_.FullName) content..."
    $content = [IO.File]::ReadAllText($_.FullName)
    Write-Output "INFO: Sending $($_.FullName) content to the API..."
    # You can specify groups separated by commas ","
    $client.send_result_importer(@{ output = $content ; groups = "" })
    Write-Output "INFO: Done."
}


Write-Output "---------------------------------------------------------------------"
Write-Output "Script completed!"
Write-Output "Your scans are now being processed by your Cyberwatch nodes."
Write-Output "Please log on $API_URL to see the results."
Write-Output "---------------------------------------------------------------------"

}

SendResultsImporter
