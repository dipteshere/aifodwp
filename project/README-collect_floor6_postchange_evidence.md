# Safe Temp Cleanup (Polished) - PowerShell 5.1

## Purpose
This script safely cleans temporary files while preserving rollback capability and detailed evidence logs.

Script path:
- `project/safe-temp-cleanup-polished.ps1`

## Features
- Dry run support (`-DryRun`) prints the exact list of files that would be deleted.
- Age-based targeting (`-OlderThanDays`) only processes files older than N days. Default is `0`.
- Locked file handling skips locked files and logs the error without stopping execution.
- Per-file `try/catch` processing.
- Date/time stamped log file for all actions.
- End-of-run summary in console and JSON summary file.
- Rollback support using manifest from prior cleanup run.
- Idempotent behavior for both cleanup and rollback operations.

## Parameters
- `-DryRun`
  - Cleanup mode only.
  - No changes are made.
  - Logs and prints `[DRY-RUN] Would delete: <path>` lines.

- `-OlderThanDays <int>`
  - Cleanup mode only.
  - Default: `0`.
  - Example: `-OlderThanDays 7` processes files with `LastWriteTime` older than 7 days.

- `-TargetPaths <string[]>`
  - Cleanup mode only.
  - Default: `%TEMP%` and `%WINDIR%\Temp`.
  - You can pass one or more folders.

- `-StateRoot <string>`
  - Optional state storage root.
  - Default: `%ProgramData%\DWPTempCleanup`.
  - Contains logs, backups, and summary files.

- `-Rollback`
  - Switch to rollback mode.

- `-ManifestPath <string>`
  - Required in rollback mode.
  - Must point to `manifest.csv` created by a prior live cleanup run.

## Usage Examples
### 1) Dry run only
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\project\safe-temp-cleanup-polished.ps1 -DryRun -OlderThanDays 3
```

### 2) Live cleanup with defaults
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\project\safe-temp-cleanup-polished.ps1
```

### 3) Live cleanup with custom target paths
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\project\safe-temp-cleanup-polished.ps1 -OlderThanDays 5 -TargetPaths "C:\Windows\Temp","C:\Temp"
```

### 4) Rollback from a manifest
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\project\safe-temp-cleanup-polished.ps1 -Rollback -ManifestPath "C:\ProgramData\DWPTempCleanup\Backups\run_20260814_103000\manifest.csv"
```

## Output Structure
Under `StateRoot`:
- `Logs\temp_cleanup_yyyyMMdd_HHmmss.log`
- `Backups\run_yyyyMMdd_HHmmss\manifest.csv` (live cleanup only)
- `summary_yyyyMMdd_HHmmss.json`

## Operational Notes
- Run as admin for best access to system temp paths.
- If locked files are encountered, they are skipped and logged; rerun later.
- Cleanup is non-destructive by design because files are moved to rollback storage before removal from source locations.
