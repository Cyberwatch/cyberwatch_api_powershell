<#
.SYNOPSIS
        Cyberwatch API script to generate an Excel report of Computers' information monitored by Cyberwatch.
.DESCRIPTION
        This script serves as an example, it can and should be adapted to your needs.
        This example:
            - defines a filter based on assets' criticalities;
            - retrieves all assets from Cyberwatch that match this filter;
            - generates an Excel report of these assets.
.EXAMPLE
        .\generate_computers_excel_report.ps1
#>

$API_KEY = "..."
$SECRET_KEY = "..."
$API_URL = "https://cyberwatch.local"

$client = Get-CyberwatchApi -api_url $API_URL -api_key $API_KEY -secret_key $SECRET_KEY -trust_all_certificates $true

$client.ping()

$Filters = @{
    "environment_id" = "4"
}

$servers = $client.servers($Filters)

# Create excel report
$excel = New-Object -ComObject excel.application
$excel.visible = $True
$workbook = $excel.Workbooks.Add()
$worksheet = $workbook.Worksheets.Item(1)
$worksheet.name = 'Cyberwatch computers API report'

# Define headers on the first row
$worksheet.Cells.Item(1,1)= 'Computer name'
$worksheet.Cells.Item(1,2)= 'Description'
$worksheet.Cells.Item(1,3)= 'Operating system'
$worksheet.Cells.Item(1,4)= 'Groups'
$worksheet.Cells.Item(1,5)= 'Criticality'
$worksheet.Cells.Item(1,6)= 'Status'
$worksheet.Cells.Item(1,7)= 'Number of vulnerabilities detected'
$worksheet.Cells.Item(1,8)= 'Number of available patches'
$worksheet.Cells.Item(1,9)= 'Last communication'

$row = 2

foreach($server in $servers) {
    # Make a list of groups comma separated
    $first_group, $rest = $server.groups
    $server_groups = $first_group.name
    foreach($group in $rest) { $server_groups += ', ' + $group.name }

    # Fill the sheet with servers' information
    $worksheet.Cells.Item($row,1)= $server.hostname
    $worksheet.Cells.Item($row,2)= $server.description
    $worksheet.Cells.Item($row,3)= $server.os.name
    $worksheet.Cells.Item($row,4)= $server_groups
    $worksheet.Cells.Item($row,5)= $server.environment.name
    $worksheet.Cells.Item($row,6)= $server.status
    $worksheet.Cells.Item($row,7)= $server.cve_announcements_count
    $worksheet.Cells.Item($row,8)= $server.updates_count
    $worksheet.Cells.Item($row,9)= $server.last_communication
    $row += 1
}

$workbook.SaveAs("$PWD/cyberwatch_computers_report")
$excel.Quit()
