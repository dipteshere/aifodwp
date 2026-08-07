# Resolution Steps — Finance Drive Mapping Failure (Intune Script Context)

**Incident Date:** 2024-03-15  
**Affected Scope:** All Finance users — DESKTOP-FB* devices (OU=Finance)  
**Related RCA:** RCA_Finance_DriveMapping_IntuneScript_2024-03-15.md  
**Resolver Role:** Senior Microsoft Intune / Active Directory / Windows Endpoint Engineer  

---

## Overview

The failure was caused by a drive-mapping script being migrated from a GPO logon script (user context) to an Intune PowerShell script (SYSTEM context) without updating the script or the assignment settings to match the new execution environment. Resolution requires three coordinated actions:

1. Fix the Intune script assignment to run as the logged-on user  
2. Harden the script itself against startup race conditions  
3. Remediate affected devices that are currently missing the S: drive mapping  

---

## Phase 1 — Immediate Fix: Correct the Intune Script Assignment Context

This is the primary fix. It re-aligns the script's execution context with what the script was written to expect.

### Steps

1. Sign in to the **Microsoft Intune admin centre** at `https://intune.microsoft.com`.

2. Navigate to:  
   **Devices → Scripts and remediations → Platform scripts**

3. Locate the script assignment named **Map-FinBridgeDrives.ps1** (or the display name used in your tenant).

4. Click the script → **Properties → Edit**.

5. Under **Script settings**, change the following setting:

   | Setting | Current Value | Required Value |
   |---------|--------------|----------------|
   | Run this script using the logged-on credentials | **No** (SYSTEM) | **Yes** (logged-on user) |

6. Leave all other settings unchanged. Click **Review + save → Save**.

7. Under the **Assignments** tab, confirm the script is still targeted at the Finance device group or the OU=Finance dynamic group. Do not modify the assignment scope.

> **Why this works:** Setting "Run as logged-on credentials" causes IME to execute the script under the user's security token. The user has a valid Kerberos ticket for `finbridge-fs01`, network credentials, and — crucially — the Workstation service is already running by the time the user logs in and IME fires the script in user context.

---

## Phase 2 — Script Hardening: Add Workstation Service Check and Retry Logic

Even in user context, a race condition at boot could still delay the Workstation service. Add defensive logic to the script to prevent a future recurrence.

### Updated Script — Map-FinBridgeDrives.ps1

Replace the opening section of the script with the following block before any `net use` or `New-PSDrive` calls:

```powershell
#region --- Workstation service readiness check ---
$serviceName = 'LanmanWorkstation'
$maxWaitSec   = 60
$intervalSec  = 5
$elapsed      = 0

Write-Host "Checking Workstation service readiness..."
while ((Get-Service -Name $serviceName -ErrorAction SilentlyContinue).Status -ne 'Running') {
    if ($elapsed -ge $maxWaitSec) {
        Write-Error "Workstation service did not start within $maxWaitSec seconds. Aborting."
        exit 1
    }
    Start-Sleep -Seconds $intervalSec
    $elapsed += $intervalSec
}
Write-Host "Workstation service is running. Proceeding with drive mapping."
#endregion

#region --- Network path reachability check ---
$uncPath = '\\finbridge-fs01\Finance'
if (-not (Test-Path -Path $uncPath)) {
    Write-Error "UNC path '$uncPath' is not accessible. Check file server availability and user credentials."
    exit 1
}
#endregion

#region --- Drive mapping ---
$driveLetter = 'S'

# Remove any stale mapping before re-creating
if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
    Remove-PSDrive -Name $driveLetter -Force
}

try {
    New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $uncPath -Persist -Scope Global
    Write-Host "Drive $driveLetter`: mapped successfully to $uncPath"
}
catch {
    Write-Error "Failed to map drive $driveLetter`: $_"
    exit 1
}
#endregion
```

### Deploy the Updated Script

1. In Intune admin centre, open the **Map-FinBridgeDrives.ps1** script properties.
2. Under **Script settings → Script**, upload or paste the updated script content.
3. Ensure **Run script in 64-bit PowerShell host** is set to **Yes** (required for `New-PSDrive -Persist`).
4. Save and allow the policy to propagate (default Intune check-in cycle is 8 hours; force sync in Phase 3 below).

---

## Phase 3 — Configure IME Retry Policy

Intune script assignments do not expose a built-in retry interval in the UI, but you can control re-execution behaviour through the following:

### Option A — Force Re-execution via Script Hash Reset (Recommended)

Intune re-runs a script when it detects the script content has changed. After uploading the hardened script in Phase 2, IME will automatically treat it as a new version and re-execute it on all targeted devices at the next check-in. No additional action needed if Phase 2 is completed.

### Option B — Remediation Script Pair (for ongoing retry capability)

For long-term resilience, convert the drive-mapping logic into an **Intune Remediations** (formerly Proactive Remediations) pairing:

| Script | Purpose |
|--------|---------|
| **Detection script** | Checks whether S: exists and resolves to `\\finbridge-fs01\Finance`. Returns exit code 1 (non-compliant) if missing. |
| **Remediation script** | Runs the mapping logic (same as above) when detection reports non-compliant. |

Set the schedule to run **every 1 hour** so any session that missed the mapping at login is self-healed within an hour.

**Detection script example:**

```powershell
$drive = Get-PSDrive -Name 'S' -ErrorAction SilentlyContinue
if ($drive -and $drive.Root -eq '\\finbridge-fs01\Finance\') {
    Write-Host "Compliant: S: drive mapped correctly."
    exit 0
} else {
    Write-Host "Non-compliant: S: drive missing or mapped to wrong path."
    exit 1
}
```

---

## Phase 4 — Remediate Currently Affected Devices

Finance devices that failed at login still have no S: drive mapped for the current session. Use one of the following methods to restore mappings without requiring a full reboot.

### Option A — Force Intune Sync (Preferred, no user disruption)

1. In Intune admin centre, navigate to **Devices → All devices**.
2. Filter by **OU=Finance** or search for `DESKTOP-FB`.
3. Select all affected devices → **Sync**.
4. IME will check in within approximately 5–10 minutes and re-run the updated script (since script content changed in Phase 2).

### Option B — Remote PowerShell (for urgent individual devices)

For priority users who cannot wait for an Intune sync cycle:

```powershell
# Run remotely via PowerShell remoting or Intune Run Command
$uncPath     = '\\finbridge-fs01\Finance'
$driveLetter = 'S'

if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
    Remove-PSDrive -Name $driveLetter -Force
}

New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $uncPath -Persist -Scope Global
Write-Host "Drive S: mapped for current session."
```

Run this via **Devices → [Device name] → Run command** in the Intune admin centre, or use a Remote PowerShell session if the device is on a routable network.

### Option C — User Self-Service (last resort)

If remote options are unavailable, instruct the user to:

1. Open **File Explorer**.
2. Right-click **This PC → Map network drive**.
3. Select drive letter **S:**.
4. Enter path: `\\finbridge-fs01\Finance`.
5. Tick **Reconnect at sign-in** and click **Finish**.

This is a temporary workaround only. The permanent fix is Phases 1–2.

---

## Phase 5 — Validation

After applying the fix, confirm resolution on at least three Finance devices before closing the incident.

### Validation Checklist

- [ ] Confirm script assignment shows **"Run as logged-on credentials: Yes"** in Intune admin centre
- [ ] Confirm updated script has been uploaded (check script hash / last modified date)
- [ ] On a test device (e.g. DESKTOP-FB041), force an Intune sync and wait for IME check-in
- [ ] Verify `AgentExecutor.log` or `IntuneManagementExtension.log` shows:
  - Script context: **user account** (not SYSTEM)
  - Exit code: **0**
  - No "Network name cannot be found" error
- [ ] Open File Explorer on the test device — confirm **S:** is mapped and accessible
- [ ] Check `\\finbridge-fs01\Finance` is reachable from the mapped drive
- [ ] Review System Event Log — confirm Event ID 98 (NTFS drive letter not assigned) is **absent**
- [ ] Confirm with at least two Finance end users that S: is accessible after next login
- [ ] Document results and attach to the incident record

### Log Location for IME on Managed Devices

```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log
```

---

## Phase 6 — Process Improvement Actions

| Action | Owner | Target Date |
|--------|-------|-------------|
| Add script context review step to the GPO-to-Intune migration checklist | Endpoint Engineering | 2024-03-22 |
| Require test deployment on one device per target OU before broad rollout | Change Advisory Board | 2024-03-22 |
| Convert all remaining GPO logon drive-mapping scripts to Intune Remediations pairs | Endpoint Engineering | 2024-04-15 |
| Add "Intune script execution context" to the L1/L2 troubleshooting runbook | Service Desk Lead | 2024-03-29 |

---

## Summary of Changes Made

| Item | Before | After |
|------|--------|-------|
| Script execution context | SYSTEM | Logged-on user |
| Workstation service check | None | Polls up to 60 seconds before proceeding |
| UNC path reachability check | None | `Test-Path` before mapping |
| Stale drive cleanup | None | Removes existing S: mapping before re-creating |
| Error handling | Script exits silently | Explicit `Write-Error` and exit codes |
| Retry on failure | Not configured | IME re-runs on next check-in (Remediations pair runs hourly) |

---

*Resolution document prepared by: Senior Microsoft Intune / AD / Windows Endpoint Engineer*  
*Date: 2024-03-15*  
*Related RCA: RCA_Finance_DriveMapping_IntuneScript_2024-03-15.md*
