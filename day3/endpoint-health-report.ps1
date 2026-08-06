#requires -Version 5.1

<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers.

.DESCRIPTION
Collects a set of endpoint health signals without making any system changes.
The script only reads local system information, registry values, event logs,
service state, and performs an in-memory download test for approximate
internet speed.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-BytesToReadable {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    if ($Bytes -ge 1TB) {
        return ('{0:N2} TB' -f ($Bytes / 1TB))
    }

    if ($Bytes -ge 1GB) {
        return ('{0:N2} GB' -f ($Bytes / 1GB))
    }

    if ($Bytes -ge 1MB) {
        return ('{0:N2} MB' -f ($Bytes / 1MB))
    }

    if ($Bytes -ge 1KB) {
        return ('{0:N2} KB' -f ($Bytes / 1KB))
    }

    return ('{0:N0} B' -f $Bytes)
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Output ''
    Write-Output ('=' * 80)
    Write-Output $Title
    Write-Output ('=' * 80)
}

function Get-PendingRebootStatus {
    $indicators = New-Object System.Collections.Generic.List[string]

    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        $null = $indicators.Add('Component Based Servicing reports RebootPending.')
    }

    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
        $null = $indicators.Add('Windows Update reports RebootRequired.')
    }

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $sessionManager = Get-ItemProperty -Path $sessionManagerPath -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
    if ($null -ne $sessionManager -and $sessionManager.PSObject.Properties.Match('PendingFileRenameOperations').Count -gt 0 -and $null -ne $sessionManager.PendingFileRenameOperations) {
        $null = $indicators.Add('Session Manager has PendingFileRenameOperations entries.')
    }

    $updateExeVolatile = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -Name 'UpdateExeVolatile' -ErrorAction SilentlyContinue
    if ($null -ne $updateExeVolatile -and $updateExeVolatile.PSObject.Properties.Match('UpdateExeVolatile').Count -gt 0 -and $null -ne $updateExeVolatile.UpdateExeVolatile -and $updateExeVolatile.UpdateExeVolatile -ne 0) {
        $null = $indicators.Add('UpdateExeVolatile is non-zero.')
    }

    [pscustomobject]@{
        IsPending  = ($indicators.Count -gt 0)
        Indicators = if ($indicators.Count -gt 0) { $indicators -join ' ' } else { 'No common reboot-pending registry indicators found.' }
    }
}

function Get-LoggedInUserSummary {
    try {
        $quserOutput = & quser 2>$null
        if ($LASTEXITCODE -eq 0 -and $quserOutput.Count -gt 1) {
            $users = $quserOutput |
                Select-Object -Skip 1 |
                Where-Object { $_.Trim() } |
                ForEach-Object {
                    if ($_ -match '^\s*>?(?<User>\S+)') {
                        $matches['User']
                    }
                } |
                Sort-Object -Unique

            return [pscustomobject]@{
                Count  = @($users).Count
                Users  = if ($users) { $users -join ', ' } else { 'None detected.' }
                Source = 'quser'
            }
        }
    }
    catch {
    }

    $fallbackUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName

    [pscustomobject]@{
        Count  = if ($fallbackUser) { 1 } else { 0 }
        Users  = if ($fallbackUser) { $fallbackUser } else { 'None detected.' }
        Source = 'Win32_ComputerSystem fallback'
    }
}

function Get-LatestWindowsUpdate {
    $latestHotFix = Get-HotFix |
        Where-Object { $_.InstalledOn } |
        Sort-Object -Property InstalledOn -Descending |
        Select-Object -First 1

    if ($null -eq $latestHotFix) {
        return [pscustomobject]@{
            InstalledOn = 'No installed update with a populated InstalledOn value was found.'
            HotFixId    = 'N/A'
            Description = 'N/A'
        }
    }

    [pscustomobject]@{
        InstalledOn = $latestHotFix.InstalledOn
        HotFixId    = $latestHotFix.HotFixID
        Description = $latestHotFix.Description
    }
}

function Test-InternetSpeed {
    param(
        [string]$Uri = 'https://speed.cloudflare.com/__down?bytes=5000000'
    )

    $webClient = New-Object System.Net.WebClient

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $data = $webClient.DownloadData($Uri)
        $stopwatch.Stop()

        if ($stopwatch.Elapsed.TotalSeconds -le 0) {
            throw 'Measured time was too small to calculate download speed.'
        }

        $bytesPerSecond = $data.Length / $stopwatch.Elapsed.TotalSeconds
        $megabytesPerSecond = $bytesPerSecond / 1MB
        $megabitsPerSecond = ($data.Length * 8 / 1000000) / $stopwatch.Elapsed.TotalSeconds

        return [pscustomobject]@{
            TestUri    = $Uri
            SampleSize = Convert-BytesToReadable -Bytes $data.Length
            Duration   = ('{0:N2} seconds' -f $stopwatch.Elapsed.TotalSeconds)
            SpeedMBs   = ('{0:N2} MB/s' -f $megabytesPerSecond)
            SpeedMbps  = ('{0:N2} Mbps' -f $megabitsPerSecond)
            Notes      = 'Approximate read-only download test performed fully in memory.'
        }
    }
    finally {
        $webClient.Dispose()
    }
}

function Get-ProcessCpuSecondsSafe {
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    try {
        return [double]$Process.TotalProcessorTime.TotalSeconds
    }
    catch {
        return $null
    }
}

Write-Section -Title 'Pre-Run Verification'

# This section flags assumptions to verify before running because the script
# reads protected areas like the registry and event logs and performs a network test.
$verificationItems = @(
    'Run in a PowerShell 5.1 session with rights to read HKLM and the System event log.',
    'Verify outbound HTTPS access to https://speed.cloudflare.com for the internet speed check.',
    'Verify quser is available if you want a session-based logged-in user count.',
    'Verify Microsoft Defender is present on the endpoint. Third-party AV can remove or disable the WinDefend service.',
    'Verify Get-HotFix is an acceptable source for the most recent Windows update in your environment.'
)

$verificationItems | ForEach-Object { Write-Output ('- {0}' -f $_) }

# This section reports current system uptime based on the last boot timestamp.
Write-Section -Title '1. System Uptime'
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $operatingSystem.LastBootUpTime
$uptime = (Get-Date) - $lastBoot
Write-Output ('Computer Name : {0}' -f $env:COMPUTERNAME)
Write-Output ('Last Boot     : {0}' -f $lastBoot)
Write-Output ('Uptime        : {0} days {1} hours {2} minutes' -f $uptime.Days, $uptime.Hours, $uptime.Minutes)

# This section reports free space for each local fixed disk.
Write-Section -Title '2. Free Disk Space'
$diskReport = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' |
    Select-Object DeviceID,
        VolumeName,
        @{ Name = 'Size'; Expression = { Convert-BytesToReadable -Bytes $_.Size } },
        @{ Name = 'FreeSpace'; Expression = { Convert-BytesToReadable -Bytes $_.FreeSpace } },
        @{ Name = 'FreePercent'; Expression = { '{0:N1}%' -f (($_.FreeSpace / $_.Size) * 100) } }
$diskReport | Format-Table -AutoSize | Out-String | Write-Output

# This section checks common registry indicators that Windows uses to signal a pending reboot.
Write-Section -Title '3. Pending Reboot Status'
$pendingReboot = Get-PendingRebootStatus
Write-Output ('Pending Reboot : {0}' -f $pendingReboot.IsPending)
Write-Output ('Evidence       : {0}' -f $pendingReboot.Indicators)

# This section lists the top five processes ranked by working set memory usage.
Write-Section -Title '4. Top 5 Processes By Memory (Working Set)'
$topMemoryProcesses = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 ProcessName, Id,
        @{ Name = 'WorkingSet'; Expression = { Convert-BytesToReadable -Bytes $_.WorkingSet64 } }
$topMemoryProcesses | Format-Table -AutoSize | Out-String | Write-Output

# This section lists the top five processes ranked by total CPU time consumed.
Write-Section -Title '5. Top 5 Processes By CPU'
$topCpuProcesses = Get-Process |
    ForEach-Object {
        [pscustomobject]@{
            ProcessName = $_.ProcessName
            Id          = $_.Id
            CPUSeconds  = Get-ProcessCpuSecondsSafe -Process $_
        }
    } |
    Where-Object { $null -ne $_.CPUSeconds } |
    Sort-Object -Property CPUSeconds -Descending |
    Select-Object -First 5 ProcessName, Id,
        @{ Name = 'CPUSeconds'; Expression = { '{0:N2}' -f $_.CPUSeconds } }
$topCpuProcesses | Format-Table -AutoSize | Out-String | Write-Output

# This section retrieves the five most recent error entries from the System event log.
Write-Section -Title '6. Last 5 System Log Errors'
$systemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
    Select-Object TimeCreated, ProviderName, Id,
        @{ Name = 'Message'; Expression = { ($_.Message -replace '\s+', ' ').Trim() } }
$systemErrors | Format-Table -Wrap -AutoSize | Out-String | Write-Output

# This section performs an in-memory download test to estimate internet speed without writing files.
Write-Section -Title '7. Internet Speed'
try {
    $internetSpeed = Test-InternetSpeed
    Write-Output ('Test URI    : {0}' -f $internetSpeed.TestUri)
    Write-Output ('Sample Size : {0}' -f $internetSpeed.SampleSize)
    Write-Output ('Duration    : {0}' -f $internetSpeed.Duration)
    Write-Output ('Speed       : {0} ({1})' -f $internetSpeed.SpeedMbps, $internetSpeed.SpeedMBs)
    Write-Output ('Notes       : {0}' -f $internetSpeed.Notes)
}
catch {
    Write-Output ('Internet speed test could not be completed: {0}' -f $_.Exception.Message)
}

# This section checks whether the Microsoft Defender service is present and running.
Write-Section -Title '8. Microsoft Defender Service State'
$defenderService = Get-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
if ($null -eq $defenderService) {
    Write-Output 'Microsoft Defender service (WinDefend) was not found on this endpoint.'
}
else {
    Write-Output ('Service Name : {0}' -f $defenderService.Name)
    Write-Output ('Display Name : {0}' -f $defenderService.DisplayName)
    Write-Output ('Status       : {0}' -f $defenderService.Status)
    Write-Output ('Is Running   : {0}' -f ($defenderService.Status -eq 'Running'))
}

# This section counts the currently logged-in users using session data where possible.
Write-Section -Title '9. Logged-In Users'
$loggedInUsers = Get-LoggedInUserSummary
Write-Output ('User Count : {0}' -f $loggedInUsers.Count)
Write-Output ('Users      : {0}' -f $loggedInUsers.Users)
Write-Output ('Source     : {0}' -f $loggedInUsers.Source)

# This section reports the most recent Windows update returned by Get-HotFix.
Write-Section -Title '10. Last Windows Update'
$lastUpdate = Get-LatestWindowsUpdate
Write-Output ('Installed On : {0}' -f $lastUpdate.InstalledOn)
Write-Output ('HotFix ID    : {0}' -f $lastUpdate.HotFixId)
Write-Output ('Description  : {0}' -f $lastUpdate.Description)