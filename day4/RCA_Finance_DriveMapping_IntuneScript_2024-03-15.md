# Root Cause Analysis — Finance Drive Mapping Failure (Intune Script Context)

**Incident Date:** 2024-03-15  
**Affected Scope:** All Finance users — DESKTOP-FB* devices (OU=Finance)  
**Reported By:** Intune Management Extension Log + System Event Log  
**Analyst Role:** Senior Microsoft Intune / Active Directory / Windows Endpoint Engineer  

---

## 1. Event Log Entries — Explained

### Intune Management Extension Log

| Timestamp | Source | Level | Event | Explanation |
|-----------|--------|-------|-------|-------------|
| 08:00:01 | ScriptRunner | Info | Executing: Map-FinBridgeDrives.ps1 | Intune Management Extension (IME) invoked the PowerShell script assigned to the Finance device group. This is the normal IME script dispatch event. |
| 08:00:02 | ScriptRunner | Info | Script context: SYSTEM account | IME confirms it is running the script under the **NT AUTHORITY\SYSTEM** security context. This is the default behaviour for Intune PowerShell scripts unless "Run this script using the logged-on credentials" is explicitly enabled. |
| 08:00:03 | ScriptRunner | Warning | Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context | SYSTEM attempted to resolve a UNC path. SYSTEM has no user credentials, no Kerberos ticket for the file server, and critically — the Workstation service had not yet fully initialised at the point of script execution (see Event 7036 at 08:00:05, two seconds later). The UNC path was unreachable. |
| 08:00:03 | ScriptRunner | Error | Script failed. Exit code: 1. Error: Network name cannot be found. | The `net use` or `New-PSDrive` call inside the script returned Win32 error 67 ("The network name cannot be found"). The script exited with a non-zero code, signalling failure to IME. |
| 08:00:04 | ScriptRunner | Info | No retry configured. | IME's retry policy for this script assignment is not set. IME will not attempt re-execution; the failure is terminal for this login cycle. |

### System Event Log — DESKTOP-FB041

| Timestamp | Source | Event ID | Level | Explanation |
|-----------|--------|----------|-------|-------------|
| 08:00:05 | Service Control Manager | **7036** | Info | The **Workstation service (LanmanWorkstation)** transitioned to the *Running* state. This service provides the SMB client redirector that resolves UNC paths (`\\server\share`). Its late start (two seconds **after** the script already failed) is a direct contributing factor to the failure. |
| 08:00:06 | GroupPolicy | **1500** | Info | Group Policy processing completed successfully. **This is NOT a Group Policy failure.** GPO settings were applied normally. The incident title "policy failure" is a misnomer — the failure originates in the Intune script layer, not in GPO. |
| 08:00:07 | Ntfs | **98** | Warning | NTFS could not assign drive letter **S:** because no mapping exists. The drive letter was never established (the script that should have created the mapping had already failed at 08:00:03). This is a downstream symptom, not an independent cause. |

---

## 2. Sequence of Events — Plain English Reconstruction

1. **08:00:01 — IME dispatches the drive-mapping script.**  
   At machine startup, the Intune Management Extension picks up the `Map-FinBridgeDrives.ps1` assignment targeting Finance devices and begins execution.

2. **08:00:02 — Script runs as SYSTEM.**  
   IME launches the script under `NT AUTHORITY\SYSTEM`. This account has no domain user credentials, no cached Kerberos tickets for `finbridge-fs01`, and relies on the Workstation service being up to resolve SMB paths.

3. **08:00:03 — Script attempts to connect to `\\finbridge-fs01\Finance` — and fails immediately.**  
   The Workstation service is not yet running (it starts two seconds later). SYSTEM has no user token with which to authenticate to the file server. Win32 error 67 is returned. The script exits with code 1.

4. **08:00:04 — IME records no-retry and moves on.**  
   Because no retry policy was configured in the Intune script assignment, IME marks the script as failed and does not attempt re-execution. Drive S: is never mapped for this session.

5. **08:00:05 — Workstation service starts — too late.**  
   LanmanWorkstation comes online, but the script execution window has already closed.

6. **08:00:06 — Group Policy processes successfully.**  
   GPO has no involvement in the drive mapping (the script was migrated away from GPO). GPO completes without error. This event is present in the log but is **not related to the failure**.

7. **08:00:07 — NTFS reports drive letter S: unassigned.**  
   Because no mapping was ever created, NTFS cannot honour any reference to S:. Users logging in see a missing or red-X mapped drive.

---

## 3. Root Cause Analysis

### Primary Root Cause

**A drive-mapping script was migrated from a GPO logon script (user context) to an Intune PowerShell script (SYSTEM context) on 2024-03-14 at 23:30, but the script itself was not updated to handle the SYSTEM execution environment.**

The original GPO logon script ran:
- **As the logged-on user** — inheriting the user's Kerberos token and network credentials.
- **After the user session was established** — by which time the Workstation service was running and the user had a valid session with the file server.

The migrated Intune script runs:
- **As SYSTEM** — which holds no domain user credentials and cannot authenticate to `finbridge-fs01`.
- **At device startup / early IME processing** — before the Workstation service is guaranteed to be running.

Both conditions independently prevent the UNC path from being resolved.

### Contributing Factors

| Factor | Detail |
|--------|--------|
| **Race condition: Workstation service** | Event 7036 at 08:00:05 shows LanmanWorkstation started 2 seconds *after* the script had already failed. Even if SYSTEM had credentials, the SMB redirector was not ready. |
| **No retry policy configured** | IME was not given a retry count or retry interval. A single transient failure at boot is unrecoverable without user interaction or device re-enrolment. |
| **Script not validated post-migration** | The change log entry (DESKTOP-FB022, 2024-03-14) indicates the script was migrated without a context review or test on a Finance device. |
| **Event 1500 misread as "policy failure"** | GPO completed successfully; the incident was initially mis-categorised as a Group Policy issue, delaying correct diagnosis. |

### Evidence Summary

| Evidence | Supports |
|----------|----------|
| IME log 08:00:02 — "Script context: SYSTEM account" | Script runs as SYSTEM, not as the user |
| IME log 08:00:03 — "Network name cannot be found" | SYSTEM cannot resolve `\\finbridge-fs01\Finance` |
| Event 7036 at 08:00:05 — Workstation service starts **after** script fails | Race condition confirmed — SMB client not ready at script execution time |
| Event 1500 at 08:00:06 — GP processed successfully | GPO is not the cause; failure is in the Intune script layer |
| Event 98 at 08:00:07 — S: not assigned | Downstream symptom of script failure, not an independent fault |
| Change log 2024-03-14 23:30 — script migrated without context update | Root cause confirmed — DESKTOP-FB022 source entry |

---

## 4. Recommendations

### Immediate Fix — Change Script Execution Context
In the Intune script assignment, enable:  
> **"Run this script using the logged-on credentials" = Yes**

This causes IME to execute the script as the logged-on user, restoring the behaviour of the original GPO logon script. The user's Kerberos token and credentials will be available, and the Workstation service will already be running by the time the user is logged in.

### Short-Term — Add Retry Logic to the Script
Add a service-readiness check and retry loop at the top of `Map-FinBridgeDrives.ps1`:

```powershell
# Wait for Workstation service before attempting UNC mapping
$maxWait = 30  # seconds
$waited  = 0
while ((Get-Service -Name LanmanWorkstation).Status -ne 'Running' -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 2
    $waited += 2
}
```

### Short-Term — Configure IME Retry Policy
In the Intune script assignment properties, set a retry count (e.g. 3 retries, 5-minute interval) so transient startup timing failures self-recover without re-enrolment.

### Process Improvement — Script Migration Checklist
Any future migration of GPO logon scripts to Intune PowerShell scripts must include:

- [ ] Review execution context (user vs. SYSTEM) and update script accordingly  
- [ ] Confirm all UNC paths / network resources are accessible from the target context  
- [ ] Test on at least one representative device in the target OU before broad deployment  
- [ ] Validate post-migration on multiple devices before closing the change record  

---

## 5. Incident Classification

| Field | Value |
|-------|-------|
| **Incident Type** | Service degradation — drive mapping failure |
| **Root Cause Category** | Change-induced — script context not updated during migration |
| **GPO Involved?** | No — Event 1500 confirms GP processed successfully |
| **Impact** | All Finance users unable to access S: (\\finbridge-fs01\Finance) at login |
| **Change Record** | 2024-03-14 23:30 — IME script migration (source: DESKTOP-FB022) |
| **Resolution Path** | Change Intune script assignment to run as logged-on user |

---

*Analysis prepared by: Senior Microsoft Intune / AD / Windows Endpoint Engineer*  
*Date: 2024-03-15*
