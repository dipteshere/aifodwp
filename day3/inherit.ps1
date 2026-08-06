<#
.SYNOPSIS
Collects and prints a quick endpoint health snapshot.

.DESCRIPTION
Reads computer name and memory, free space on C:, top memory-consuming processes,
recent System log errors, and stale user profile count. This script is read-only
and reports findings to the console.

.AUTHOR
Original author: Unknown
Readability refactor: GitHub Copilot

.DATE
2026-08-06

.HOW TO RUN
1. Open PowerShell.
2. Navigate to this folder.
3. Run: .\inherit.ps1
#>

# Get core computer system details (for example, computer name and total RAM).
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get free space (in bytes) on the C: drive.
$freeSpaceBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the top 5 running processes by working set memory usage (highest first).
$topProcessesByWorkingSet = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the most recent 10 System log events, then keep only error-level entries (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get all user profiles and keep only non-special profiles not used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free bytes to GB, round to 2 decimals, and print the result.
Write-Host ([math]::Round($freeSpaceBytes / 1GB, 2)) 'GB free'

# Print each of the top processes with its name and working set value.
$topProcessesByWorkingSet | ForEach-Object { Write-Host $_.Name $_.WS }

# Print each recent system error with timestamp and message.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If stale profiles exist, print how many were found.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }