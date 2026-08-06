#requires -Version 5.1

<#
.SYNOPSIS
Safely cleans temporary files on Windows endpoints with dry-run, logging, summary, and rollback support.

.DESCRIPTION
- Cleanup mode: Finds temp files older than a configured age and moves them into a rollback store.
- Dry run mode: Shows what would be moved/deleted without making changes.
- Rollback mode: Restores files from a prior cleanup manifest.

This script is designed to be idempotent:
- Re-running cleanup does not re-process files already moved out of temp locations.
- Re-running rollback safely skips files already restored or missing backup artifacts.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Cleanup')]
param(
    # This section defines the operational mode and file-aging behavior.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$TargetPaths = @($env:TEMP, "$env:WINDIR\Temp"),

    # This section defines rollback execution inputs.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ManifestPath,

    # This section defines where logs and rollback artifacts are stored.
    [string]$StateRoot = "$env:ProgramData\DWPTempCleanup"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This section initializes folder structure and timestamped run metadata.
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

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFilePath -Value $line
    Write-Output $line
}

function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

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

    $safe = $FullPath -replace ':', ''
    $safe = $safe.TrimStart('\\')
    return ($safe -replace '[\\/]+', '\\')
}

function Invoke-CleanupMode {
    # This section discovers candidate temp files and processes each file with per-file try/catch.
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
        Scanned          = 0
        Eligible         = 0
        Moved            = 0
        Deleted          = 0
        LockedSkipped    = 0
        MissingSkipped   = 0
        ErrorCount       = 0
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

            # This section supports dry-run output by listing exactly what would be removed.
            if ($DryRun) {
                Write-Log -Message ("[DRY-RUN] Would delete: {0}" -f $file.FullName)
                return
            }

            # This section catches locked files and logs them without failing the whole run.
            if (Test-FileLocked -File $file) {
                $summary.LockedSkipped++
                Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
                return
            }

            # This section performs per-file rollback-safe removal with dedicated try/catch handling.
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

                if ($PSCmdlet.ShouldProcess($file.FullName, 'Move to rollback store')) {
                    Move-Item -LiteralPath $file.FullName -Destination $backupPath -Force
                    $summary.Moved++
                    $summary.Deleted++

                    $manifestRows.Add([pscustomobject]@{
                        OriginalPath = $file.FullName
                        BackupPath   = $backupPath
                        Length       = $file.Length
                        LastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
                        RunId        = $runId
                        MovedAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
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
        $manifestRows | Export-Csv -Path $manifestPath -NoTypeInformation
        Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
    }

    # This section reports run totals so operators can verify what happened quickly.
    Write-Output ''
    Write-Output '=== Cleanup Summary ==='
    Write-Output ("Mode                 : {0}" -f $modeLabel)
    Write-Output ("Log File             : {0}" -f $logFilePath)
    if (-not $DryRun) {
        Write-Output ("Rollback Manifest    : {0}" -f $manifestPath)
        Write-Output ("Rollback Backup Root : {0}" -f $runBackupDirectory)
    }
    Write-Output ("Scanned Files        : {0}" -f $summary.Scanned)
    Write-Output ("Eligible Files       : {0}" -f $summary.Eligible)
    Write-Output ("Deleted Files        : {0}" -f $summary.Deleted)
    Write-Output ("Locked Skipped       : {0}" -f $summary.LockedSkipped)
    Write-Output ("Missing Skipped      : {0}" -f $summary.MissingSkipped)
    Write-Output ("Errors               : {0}" -f $summary.ErrorCount)

    Write-Log -Message ("Cleanup complete. Deleted={0}, LockedSkipped={1}, MissingSkipped={2}, Errors={3}" -f $summary.Deleted, $summary.LockedSkipped, $summary.MissingSkipped, $summary.ErrorCount)
}

function Invoke-RollbackMode {
    # This section restores files from a selected manifest and safely skips already-restored items.
    Write-Log -Message ("Starting rollback from manifest: {0}" -f $ManifestPath)

    $rows = Import-Csv -Path $ManifestPath
    $summary = [ordered]@{
        ManifestRows       = 0
        Restored           = 0
        AlreadyRestored    = 0
        DestinationExists  = 0
        MissingBackupFile  = 0
        ErrorCount         = 0
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

    # This section reports rollback totals for operator verification.
    Write-Output ''
    Write-Output '=== Rollback Summary ==='
    Write-Output ("Log File             : {0}" -f $logFilePath)
    Write-Output ("Manifest Rows        : {0}" -f $summary.ManifestRows)
    Write-Output ("Restored             : {0}" -f $summary.Restored)
    Write-Output ("Already Present      : {0}" -f $summary.AlreadyRestored)
    Write-Output ("Missing Backup File  : {0}" -f $summary.MissingBackupFile)
    Write-Output ("Errors               : {0}" -f $summary.ErrorCount)

    Write-Log -Message ("Rollback complete. Restored={0}, AlreadyPresent={1}, MissingBackup={2}, Errors={3}" -f $summary.Restored, $summary.AlreadyRestored, $summary.MissingBackupFile, $summary.ErrorCount)
}

# This section routes execution to cleanup or rollback mode.
if ($Rollback) {
    Invoke-RollbackMode
}
else {
    Invoke-CleanupMode
}
