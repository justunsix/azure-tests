<#
.SYNOPSIS
    Find the uptime of a Windows 11 Desktop for each day and display it and output results to a csv file.
.DESCRIPTION
    Use case is to checking system usage to help with machine usage and sizing.
.EXAMPLE
    Get-Win-System-Uptime-Report.ps1
    This command will find the uptime of the local system for each day in the last 7 days and display it. 
    Modify the $daysAgo variable to change the number of days in the past to search, for example $daysAgo = 30 to search the last 30 days.
#>

# Search range dates beginning at 12:00:00 AM of each day
$daysAgo = 7
$Begin = (Get-Date).AddDays(-$daysAgo).Date
# End date is today at 12:00:00 AM
$End = (Get-Date).Date

# Get information from system event log using EventID:
# - Event ID 6005 indicates the event log service was started (system startup)
# - Event ID 6006 indicates it was stopped (system shutdown).
$events = Get-EventLog -LogName System -After $Begin -Before $End | Where-Object { $_.EventID -eq 6005 -or $_.EventID -eq 6006 }

# Hash table to store uptime for each day
$uptime = @{}

# Iterate through each event in the retrieved events to get the uptime per day
for ($i = 0; $i -lt $events.Count; $i++) {
    $event = $events[$i]
    $date = $event.TimeGenerated.Date
    $eventID = $event.EventID

    # If the event is a system shutdown event, calculate the uptime using the start event
    if ($eventID -eq 6006) {
        $systemStartEvent = $events[$i + 1]
        $uptimeStart = $systemStartEvent.TimeGenerated
        $uptimeEnd = $event.TimeGenerated      
        $uptimeDuration = $uptimeEnd - $uptimeStart
        
        $uptime[$date] = "${uptimeDuration}"
    }
}

# Display uptime for each day in a table
# $uptime

# Export the results of the $uptime hash table to a CSV file
# so the headers are date, uptime
# each row will have a new date and the uptime for that day
# Format the date object in the format YYYY-MM-DD
$uptime.GetEnumerator() | Select-Object @{Name="Date"; Expression={ $_.Key.ToString("yyyy-MM-dd") }}, @{Name="Uptime"; Expression={ $_.Value }} | Export-Csv -Path "SystemUptimeReport.csv" -NoTypeInformation

Get-Content "SystemUptimeReport.csv"

