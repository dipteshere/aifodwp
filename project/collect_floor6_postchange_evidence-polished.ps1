#requires -Version 5.1

<#!
.SYNOPSIS
Safely cleans temporary files with dry-run, logging, summary, and rollback support.

.DESCRIPTION
- Cleanup mode finds files older than a configured age and moves them to a rollback store.
- Dry run mode prints exactly which files would be deleted (no changes made).
- Rollback mode restores files from a prior cleanup manifest.

This script is idempotent by design:
- Cleanup: files already moved are no longer in source paths and are skipped naturally.
- Rollback: files already restored or missing backup artifacts are safely skipped.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Cleanup')]
param(
    # Cleanup mode options
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$TargetPaths = @($env:TEMP, "$env:WINDIR\Temp"),

    # Rollback mode options
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ManifestPath,

    # State and logging root
    [string]$StateRoot = "$env:ProgramData\DWPTempCleanup"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Initialize run metadata, folder structure, and timestamped log path.
$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runId = "run_$runTimestamp"
$logDirectory = Join-Path -Path $StateRoot -ChildPath 'Logs'
$backupRoot = Join-Path -Path $StateRoot -ChildPath 'Backups'

New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

$logFilePath = Join-Path -Path $logDirectory -ChildPath ("temp_cleanup_{0}.log" -f $runTimestamp)

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    # Log every action with local date/time and severity.
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFilePath -Value $line
    Write-Output $line
}

function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    # Attempt exclusive open; if it fails, file is considered locked.
    try {
        $stream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch {
        return $true
    }
}

function Convert-ToSafeRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    # Convert absolute path into rollback-store-safe relative path.
    $safe = $FullPath -replace ':', ''
    $safe = $safe.TrimStart('\\')
    return ($safe -replace '[\\/]+', '\\')
}

function Invoke-CleanupMode {
    # Discover candidates based on age threshold, then process each file with per-file error handling.
    $cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
    $modeLabel = if ($DryRun) { 'DRY-RUN' } else { 'LIVE' }

    Write-Log -Message ("Starting cleanup mode ({0}). OlderThanDays={1}. Cutoff={2:o}" -f $modeLabel, $OlderThanDays, $cutoff)
    Write-Log -Message ("Target paths: {0}" -f ($TargetPaths -join '; '))

    $runBackupDirectory = Join-Path -Path $backupRoot -ChildPath $runId
    $manifestPath = Join-Path -Path $runBackupDirectory -ChildPath 'manifest.csv'

    if (-not $DryRun) {
        New-Item -Path $runBackupDirectory -ItemType Directory -Force | Out-Null
    }

    $summary = [ordered]@{
        Scanned = 0
        Eligible = 0
        Deleted = 0
        LockedSkipped = 0
        MissingSkipped = 0
        ErrorCount = 0
    }

    $manifestRows = New-Object System.Collections.Generic.List[object]

    foreach ($path in $TargetPaths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            Write-Log -Level 'WARN' -Message ("Path not found, skipping: {0}" -f $path)
            continue
        }

        Write-Log -Message ("Scanning path: {0}" -f $path)

        Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $summary.Scanned++
            $file = $_

            if ($file.LastWriteTime -gt $cutoff) {
                return
            }

            $summary.Eligible++

            # Dry-run prints all candidate files that would be deleted.
            if ($DryRun) {
                Write-Log -Message ("[DRY-RUN] Would delete: {0}" -f $file.FullName)
                return
            }

            # Skip locked files and continue processing.
            if (Test-FileLocked -File $file) {
                $summary.LockedSkipped++
                Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
                return
            }

            try {
                if (-not (Test-Path -LiteralPath $file.FullName -PathType Leaf)) {
                    $summary.MissingSkipped++
                    Write-Log -Level 'WARN' -Message ("File disappeared before processing, skipped: {0}" -f $file.FullName)
                    return
                }

                $relativePath = Convert-ToSafeRelativePath -FullPath $file.FullName
                $backupPath = Join-Path -Path $runBackupDirectory -ChildPath $relativePath
                $backupParent = Split-Path -Path $backupPath -Parent
                New-Item -Path $backupParent -ItemType Directory -Force | Out-Null

                if ($PSCmdlet.ShouldProcess($file.FullName, 'Move to rollback store and remove from temp location')) {
                    Move-Item -LiteralPath $file.FullName -Destination $backupPath -Force
                    $summary.Deleted++

                    $manifestRows.Add([pscustomobject]@{
                        OriginalPath = $file.FullName
                        BackupPath = $backupPath
                        Length = $file.Length
                        LastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
                        RunId = $runId
                        MovedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
                    }) | Out-Null

                    Write-Log -Message ("Deleted (moved to rollback store): {0}" -f $file.FullName)
                }
            }
            catch {
                $summary.ErrorCount++
                Write-Log -Level 'ERROR' -Message ("Failed processing file: {0}. Error: {1}" -f $file.FullName, $_.Exception.Message)
            }
        }
    }

    if (-not $DryRun) {
        $manifestRows | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8
        Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
    }

    # Build machine-readable and human-readable summary.
    $summaryObject = [pscustomobject]@{
        Mode = $modeLabel
        RunId = $runId
        Timestamp = (Get-Date).ToString('o')
        OlderThanDays = $OlderThanDays
        Cutoff = $cutoff.ToString('o')
        LogFile = $logFilePath
        ManifestPath = if ($DryRun) { $null } else { $manifestPath }
        BackupFolder = if ($DryRun) { $null } else { $runBackupDirectory }
        ScannedFiles = $summary.Scanned
        EligibleFiles = $summary.Eligible
        DeletedFiles = $summary.Deleted
        LockedSkipped = $summary.LockedSkipped
        MissingSkipped = $summary.MissingSkipped
        Errors = $summary.ErrorCount
    }

    $summaryPath = Join-Path -Path $StateRoot -ChildPath ("summary_{0}.json" -f $runTimestamp)
    $summaryObject | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Log -Message ("Summary file created: {0}" -f $summaryPath)

    Write-Output ''
    Write-Output '=== Cleanup Summary ==='
    Write-Output ("Mode                 : {0}" -f $summaryObject.Mode)
    Write-Output ("Log File             : {0}" -f $summaryObject.LogFile)
    Write-Output ("Summary JSON         : {0}" -f $summaryPath)
    if (-not $DryRun) {
        Write-Output ("Rollback Manifest    : {0}" -f $summaryObject.ManifestPath)
        Write-Output ("Rollback Backup Root : {0}" -f $summaryObject.BackupFolder)
    }
    Write-Output ("Scanned Files        : {0}" -f $summaryObject.ScannedFiles)
    Write-Output ("Eligible Files       : {0}" -f $summaryObject.EligibleFiles)
    Write-Output ("Deleted Files        : {0}" -f $summaryObject.DeletedFiles)
    Write-Output ("Locked Skipped       : {0}" -f $summaryObject.LockedSkipped)
    Write-Output ("Missing Skipped      : {0}" -f $summaryObject.MissingSkipped)
    Write-Output ("Errors               : {0}" -f $summaryObject.Errors)

    Write-Log -Message ("Cleanup complete. Deleted={0}, LockedSkipped={1}, MissingSkipped={2}, Errors={3}" -f $summaryObject.DeletedFiles, $summaryObject.LockedSkipped, $summaryObject.MissingSkipped, $summaryObject.Errors)
}

function Invoke-RollbackMode {
    # Restore files from manifest; skip already-restored or missing backup entries safely.
    Write-Log -Message ("Starting rollback from manifest: {0}" -f $ManifestPath)

    $rows = Import-Csv -Path $ManifestPath
    $summary = [ordered]@{
        ManifestRows = 0
        Restored = 0
        AlreadyRestored = 0
        MissingBackupFile = 0
        ErrorCount = 0
    }

    foreach ($row in $rows) {
        $summary.ManifestRows++
        $originalPath = $row.OriginalPath
        $backupPath = $row.BackupPath

        try {
            if (Test-Path -LiteralPath $originalPath -PathType Leaf) {
                $summary.AlreadyRestored++
                Write-Log -Level 'WARN' -Message ("Already present at destination, skipping: {0}" -f $originalPath)
                continue
            }

            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
                $summary.MissingBackupFile++
                Write-Log -Level 'WARN' -Message ("Backup file not found, cannot restore: {0}" -f $backupPath)
                continue
            }

            $destinationParent = Split-Path -Path $originalPath -Parent
            if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
                New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
            }

            if ($PSCmdlet.ShouldProcess($originalPath, 'Restore file from rollback store')) {
                Move-Item -LiteralPath $backupPath -Destination $originalPath -Force
                $summary.Restored++
                Write-Log -Message ("Restored: {0}" -f $originalPath)
            }
        }
        catch {
            $summary.ErrorCount++
            Write-Log -Level 'ERROR' -Message ("Failed restoring file: {0}. Error: {1}" -f $originalPath, $_.Exception.Message)
        }
    }

    $summaryObject = [pscustomobject]@{
        Mode = 'ROLLBACK'
        RunId = $runId
        Timestamp = (Get-Date).ToString('o')
        LogFile = $logFilePath
        ManifestPath = $ManifestPath
        ManifestRows = $summary.ManifestRows
        Restored = $summary.Restored
        AlreadyRestored = $summary.AlreadyRestored
        MissingBackupFile = $summary.MissingBackupFile
        Errors = $summary.ErrorCount
    }

    $summaryPath = Join-Path -Path $StateRoot -ChildPath ("summary_{0}.json" -f $runTimestamp)
    $summaryObject | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Log -Message ("Summary file created: {0}" -f $summaryPath)

    Write-Output ''
    Write-Output '=== Rollback Summary ==='
    Write-Output ("Log File             : {0}" -f $summaryObject.LogFile)
    Write-Output ("Summary JSON         : {0}" -f $summaryPath)
    Write-Output ("Manifest Rows        : {0}" -f $summaryObject.ManifestRows)
    Write-Output ("Restored             : {0}" -f $summaryObject.Restored)
    Write-Output ("Already Present      : {0}" -f $summaryObject.AlreadyRestored)
    Write-Output ("Missing Backup File  : {0}" -f $summaryObject.MissingBackupFile)
    Write-Output ("Errors               : {0}" -f $summaryObject.Errors)

    Write-Log -Message ("Rollback complete. Restored={0}, AlreadyPresent={1}, MissingBackup={2}, Errors={3}" -f $summaryObject.Restored, $summaryObject.AlreadyRestored, $summaryObject.MissingBackupFile, $summaryObject.Errors)
}

# Route execution based on parameter set.
if ($Rollback) {
    Invoke-RollbackMode
}
else {
    Invoke-CleanupMode
}
