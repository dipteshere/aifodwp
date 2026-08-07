# Root Cause Analysis — Finance Drive Mapping Failure
## Intune Script Execution Context Misconfiguration

| Field | Value |
|-------|-------|
| **RCA ID** | RCA-2024-03-15-FINANCE-DRIVEMAP |
| **Incident Date** | 2024-03-15 |
| **Resolution Date** | 2024-03-15 |
| **Status** | CLOSED — Resolved and Verified |
| **Severity** | High — All Finance users impacted |
| **Affected Scope** | All Finance users, DESKTOP-FB* devices (OU=Finance) |
| **Service Affected** | S: drive mapping to `\\finbridge-fs01\Finance` |
| **RCA Author** | Senior Microsoft Intune / Active Directory / Windows Endpoint Engineer |
| **Related Documents** | resolution_Finance_DriveMapping_IntuneScript_2024-03-15.md |

---

## 1. Executive Summary

On 2024-03-15, all Finance department users were unable to access their mapped S: drive (`\\finbridge-fs01\Finance`) following a change made the previous evening. A drive-mapping PowerShell script was migrated from a Group Policy Object (GPO) logon script — which runs as the logged-on user — to an Intune Management Extension (IME) platform script — which runs as `NT AUTHORITY\SYSTEM` by default. The script was not updated or tested for the new execution context, causing it to fail silently at every Finance device login.

The incident was incorrectly categorised initially as a Group Policy failure. Event ID 1500 in the System log confirmed GPO processed successfully; the fault was entirely within the Intune script layer. The root cause was a change process gap: no script context review was performed during migration.

Resolution was confirmed after changing the Intune script assignment to run under the logged-on user's credentials. All Finance users verified successful S: drive access following the fix.

---

## 2. Impact Assessment

| Dimension | Detail |
|-----------|--------|
| **Users affected** | All Finance department users |
| **Devices affected** | All DESKTOP-FB* devices in OU=Finance |
| **Service lost** | S: drive — `\\finbridge-fs01\Finance` (primary Finance file share) |
| **Duration of impact** | From first login on 2024-03-15 until fix applied and verified |
| **Business impact** | Finance users unable to access shared files, spreadsheets, and departmental documents stored on the Finance file server |
| **Workaround available** | Yes — manual drive mapping via File Explorer (user self-service) |
| **Data loss** | None |
| **Security breach** | None |

---

## 3. Timeline of Events

### Pre-Incident — Change Activity

| Date / Time | Event |
|-------------|-------|
| **2024-03-14 23:30** | Change executed: `Map-FinBridgeDrives.ps1` migrated from GPO logon script to Intune Platform Script assignment targeting OU=Finance devices. Script content not reviewed or updated for the new SYSTEM execution context. Source device: DESKTOP-FB022. |
| **2024-03-14 23:30** | Intune script assignment saved with default setting: **"Run this script using the logged-on credentials" = No** (runs as SYSTEM). |

### Incident Day — 2024-03-15

| Time | Source | Event |
|------|--------|-------|
| **08:00:01** | IME ScriptRunner | Intune Management Extension dispatches `Map-FinBridgeDrives.ps1` to Finance devices at boot. |
| **08:00:02** | IME ScriptRunner | IME logs: **"Script context: SYSTEM account"** — script executing as NT AUTHORITY\SYSTEM. |
| **08:00:03** | IME ScriptRunner | Script attempts to resolve UNC path `\\finbridge-fs01\Finance`. SYSTEM has no Kerberos ticket, no user credentials, and the Workstation service is not yet running. **Win32 error 67 — "Network name cannot be found"** returned. Script exits with code 1. |
| **08:00:04** | IME ScriptRunner | IME logs: **"No retry configured."** IME marks the script as failed. No re-execution will occur for this login cycle. |
| **08:00:05** | Service Control Manager | **Event ID 7036** — Workstation service (LanmanWorkstation / SMB client redirector) enters *Running* state. Two seconds too late — the script had already failed. |
| **08:00:06** | GroupPolicy | **Event ID 1500** — Group Policy settings processed successfully. GPO is **not** involved in the failure. |
| **08:00:07** | NTFS | **Event ID 98** — NTFS cannot assign drive letter S: — no mapping exists. Downstream symptom only. |
| **08:00:07+** | End users | Finance users log in to find S: drive missing or showing a red X. Helpdesk tickets raised. |

### Resolution — 2024-03-15

| Time | Action |
|------|--------|
| Incident raised | Initial mis-categorisation as "Group Policy failure" based on the symptom description. |
| Investigation | IME logs reviewed; Event 1500 confirmed GPO success; Event 7036 timing identified the race condition; change log entry at DESKTOP-FB022 confirmed migration occurred the prior evening without context update. |
| Fix applied | Intune admin centre: `Map-FinBridgeDrives.ps1` assignment updated — **"Run this script using the logged-on credentials"** changed from **No → Yes**. Script content hardened with Workstation service check, `Test-Path` reachability check, stale drive cleanup, and structured error handling. |
| Devices synced | All Finance DESKTOP-FB* devices forced to sync via Intune admin centre. IME re-ran updated script within 5–10 minutes per device. |
| Verification | Finance users confirmed S: drive accessible. IME logs showed script context changed to user account, exit code 0, no errors. System Event ID 98 absent on verified devices. |
| **Incident closed** | Resolved and verified. |

---

## 4. Supporting Evidence

### 4.1 Intune Management Extension Log (DESKTOP-FB041 — representative sample)

```
[08:00:01]  ScriptRunner  Info     Executing: Map-FinBridgeDrives.ps1
[08:00:02]  ScriptRunner  Info     Script context: SYSTEM account
[08:00:03]  ScriptRunner  Warning  Network path \\finbridge-fs01\Finance not accessible
                                   from SYSTEM context at execution time
[08:00:03]  ScriptRunner  Error    Script Map-FinBridgeDrives.ps1 failed.
                                   Exit code: 1. Error: Network name cannot be found.
[08:00:04]  ScriptRunner  Info     No retry configured.
```

**Evidence supports:** Script ran as SYSTEM (not user), failed on UNC resolution, and had no recovery mechanism.

### 4.2 System Event Log — DESKTOP-FB041

```
08:00:05  Service Control Manager  Event 7036
          Workstation service entered running state.

08:00:06  GroupPolicy              Event 1500
          Group Policy settings processed successfully.

08:00:07  Ntfs                     Event 98  Warning
          File system could not map drive letter S:
          Drive letter has not been assigned.
```

**Evidence supports:**
- **Event 7036:** Workstation service started 2 seconds after script failure — confirms race condition.
- **Event 1500:** GPO processed successfully — eliminates GPO as a cause.
- **Event 98:** Downstream symptom of the failed script — confirms S: was never mapped.

### 4.3 Change Log Entry

```
Source: DESKTOP-FB022
2024-03-14 23:30 — Drive mapping script migrated from GPO logon script
(runs as USER) to Intune PowerShell script (runs as SYSTEM).
Script not updated to handle SYSTEM context — network paths via UNC
require the Workstation service and mapped credentials which are not
available to SYSTEM at login time.
```

**Evidence supports:** The change is the direct antecedent of the incident. The change log itself documents the gap — the migrator was aware of the context difference but did not act on it.

### 4.4 Post-Fix IME Log Confirmation (after resolution)

```
ScriptRunner  Info    Script context: [domain]\[username]
ScriptRunner  Info    Workstation service is running. Proceeding with drive mapping.
ScriptRunner  Info    Drive S: mapped successfully to \\finbridge-fs01\Finance
ScriptRunner  Info    Exit code: 0
```

**Evidence supports:** Resolution confirmed — script now runs as user, UNC path resolves, drive mapped successfully.

### 4.5 Evidence Summary Table

| Evidence Item | Type | Supports |
|---------------|------|----------|
| IME log — "Script context: SYSTEM account" | Log | Root cause — wrong execution context |
| IME log — "Network name cannot be found" | Log | Direct failure mode |
| IME log — "No retry configured" | Log | Contributing factor — no recovery |
| Event 7036 at 08:00:05 (after script fail at 08:00:03) | Event log | Contributing factor — race condition |
| Event 1500 at 08:00:06 | Event log | Eliminates GPO as cause |
| Event 98 at 08:00:07 | Event log | Downstream symptom — drive never mapped |
| Change log entry 2024-03-14 23:30 | Change record | Root cause confirmed — untested migration |
| Post-fix IME log exit code 0 | Log | Resolution verified |
| User confirmation — S: accessible | User verification | Resolution verified end-to-end |

---

## 5. Five-Why Analysis

### Problem Statement
All Finance users were unable to access the S: drive (`\\finbridge-fs01\Finance`) on 2024-03-15.

---

**Why 1 — Why were Finance users unable to access the S: drive?**

> The drive mapping script `Map-FinBridgeDrives.ps1` failed at execution, so drive letter S: was never assigned.

*Evidence: IME log — Exit code 1, Error: "Network name cannot be found." System Event ID 98 — drive letter not assigned.*

---

**Why 2 — Why did the drive mapping script fail?**

> The script attempted to connect to a UNC path (`\\finbridge-fs01\Finance`) while running as `NT AUTHORITY\SYSTEM`, which has no domain user credentials and no Kerberos ticket for the file server. Additionally, the Workstation service (SMB client) was not yet running at the time the script executed.

*Evidence: IME log — "Script context: SYSTEM account." IME Warning — "Network path not accessible from SYSTEM context." Event 7036 — Workstation service started 2 seconds after script failure.*

---

**Why 3 — Why was the script running as SYSTEM instead of as the logged-on user?**

> The script was migrated from a GPO logon script (which runs as the logged-on user by default) to an Intune Platform Script assignment (which runs as SYSTEM by default). The Intune assignment setting **"Run this script using the logged-on credentials"** was left at its default value of **No**.

*Evidence: IME log — "Script context: SYSTEM account." Intune admin centre — setting confirmed as No prior to fix. Change log — migration executed 2024-03-14 23:30.*

---

**Why 4 — Why was the Intune assignment setting not changed to run as the logged-on user?**

> The script was migrated as-is from GPO without a review of how Intune's execution context differs from a GPO logon script context. The engineer performing the migration did not update the script or its assignment settings to reflect the new environment. No pre-deployment testing was performed on a Finance device.

*Evidence: Change log entry explicitly states "Script not updated to handle SYSTEM context." No test record exists for the change. The change log itself was the only documentation of the known gap.*

---

**Why 5 — Why was there no context review or test requirement in the migration process?**

> The GPO-to-Intune migration process did not include a mandatory checklist step requiring engineers to review and validate the execution context when moving scripts between platforms. There was no requirement to test on a representative device in the target OU before broad deployment, and no Change Advisory Board gate that would have caught the missing context update.

*Evidence: Absence of any test record. Change log shows the change went directly to all Finance devices. No migration checklist document exists that covers execution context.*

---

### Five-Why Summary

```
Users cannot access S: drive
    └─ Why 1: Drive mapping script failed at execution
        └─ Why 2: Script ran as SYSTEM with no credentials and SMB not ready
            └─ Why 3: Intune script assignment defaulted to SYSTEM context;
                       setting not changed during migration
                └─ Why 4: No context review performed; script migrated as-is;
                           no pre-deployment testing conducted
                    └─ Why 5 (ROOT): GPO-to-Intune migration process had no
                                     mandatory execution context review step
                                     and no test-before-deploy gate
```

---

## 6. Root Cause Statement

**The root cause of this incident is a process gap: the GPO-to-Intune script migration process did not require engineers to review or validate the execution context of scripts being moved between platforms. This allowed `Map-FinBridgeDrives.ps1` to be deployed to all Finance devices in an execution context (SYSTEM) that was incompatible with the script's logic, without any pre-deployment testing that would have caught the failure before it reached production.**

The immediate technical cause was the Intune script assignment running as SYSTEM rather than as the logged-on user, which prevented UNC path resolution and drive mapping.

---

## 7. Contributing Factors

| Factor | Description | Classification |
|--------|-------------|----------------|
| **No retry policy on IME script** | IME had no retry configured; a single failure at boot was unrecoverable for that session | Contributing |
| **Workstation service race condition** | LanmanWorkstation started 2 seconds after script execution; UNC path unreachable even if credentials were present | Contributing |
| **Incident mis-categorised as GPO failure** | Initial diagnosis focused on GPO, delaying root cause identification | Contributing |
| **Change log gap** | The change log noted the context issue but the migration was deployed anyway without remediation | Contributing |
| **No Intune-specific onboarding for migrated scripts** | Engineers migrating from GPO to Intune had no platform-specific guidance on context differences | Root cause enabler |

---

## 8. Resolution Applied

### Primary Fix
In the Microsoft Intune admin centre, the `Map-FinBridgeDrives.ps1` script assignment was updated:

| Setting | Before | After |
|---------|--------|-------|
| Run this script using the logged-on credentials | No (SYSTEM) | **Yes (logged-on user)** |

### Script Hardening
The script was updated with the following defensive additions before any mapping logic executes:

1. **Workstation service readiness poll** — waits up to 60 seconds for `LanmanWorkstation` to reach Running state before proceeding
2. **UNC path reachability check** — `Test-Path` validates `\\finbridge-fs01\Finance` is accessible before attempting to map
3. **Stale drive cleanup** — removes any broken existing S: mapping before re-creating
4. **Structured error handling** — explicit `Write-Error` and exit codes replace silent failures

### Device Remediation
All DESKTOP-FB* Finance devices were forced to sync via the Intune admin centre. IME re-executed the updated script (triggered by script content hash change) within 5–10 minutes per device. Drive S: was restored in all verified sessions.

### Verification Confirmation
- IME logs post-fix: script context = logged-on user, exit code = 0, no errors
- System log: Event ID 98 absent on verified devices
- End-user confirmation: S: drive accessible and resolves to `\\finbridge-fs01\Finance`
- Tested on minimum three Finance devices before incident closure

---

## 9. Preventive Actions

### Immediate Actions (Complete by 2024-03-22)

| # | Action | Owner | Due | Status |
|---|--------|-------|-----|--------|
| PA-01 | Publish a GPO-to-Intune script migration checklist that mandates execution context review as a required step | Endpoint Engineering Lead | 2024-03-22 | Open |
| PA-02 | Add mandatory test-on-one-device gate to the change process for all Intune script deployments targeting more than 10 devices | Change Advisory Board | 2024-03-22 | Open |
| PA-03 | Audit all existing Intune platform scripts that run as SYSTEM and assess whether any should run as the logged-on user | Senior Endpoint Engineer | 2024-03-22 | Open |
| PA-04 | Update the L1/L2 troubleshooting runbook to include "Intune script execution context" as a standard diagnostic step when drive mapping failures are reported | Service Desk Lead | 2024-03-29 | Open |

### Medium-Term Actions (Complete by 2024-04-15)

| # | Action | Owner | Due | Status |
|---|--------|-------|-----|--------|
| PA-05 | Convert all remaining Finance and other OU drive-mapping scripts to Intune Remediations pairs (detection + remediation) with a 1-hour schedule, replacing one-shot platform scripts | Endpoint Engineering | 2024-04-15 | Open |
| PA-06 | Configure Intune Remediation retry schedules on all business-critical scripts — minimum 3 retries at 15-minute intervals | Endpoint Engineering | 2024-04-15 | Open |
| PA-07 | Create an internal knowledge base article: "Differences between GPO logon scripts and Intune PowerShell scripts — execution context, timing, and credential availability" | Senior Endpoint Engineer | 2024-04-15 | Open |

### GPO-to-Intune Migration Checklist (to be published as PA-01)

When migrating any script from a GPO logon/startup script to an Intune Platform Script:

- [ ] **Execution context:** Does the script use network paths, user credentials, or mapped drives? If yes, set "Run as logged-on credentials = Yes"
- [ ] **Service dependencies:** Does the script depend on services (Workstation, DNS Client, etc.) that may not be running at SYSTEM-context execution time? Add service readiness checks
- [ ] **Timing:** GPO logon scripts run after user session is fully established. Intune scripts run earlier. Verify the script's dependencies are available at IME execution time
- [ ] **Test deployment:** Deploy to one device in the target OU. Verify in IME logs before broad rollout
- [ ] **Retry policy:** Configure Intune Remediations pair or ensure the platform script assignment will re-execute on failure
- [ ] **Rollback plan:** Document how to revert to the GPO script if the Intune deployment fails
- [ ] **Change record:** Document the context change explicitly and confirm it was tested

---

## 10. Lessons Learned

| Lesson | Applicability |
|--------|--------------|
| Intune Platform Scripts and GPO logon scripts are **not equivalent** — execution context, timing, and available resources differ fundamentally. Scripts must be reviewed and tested when moving between platforms. | All future GPO-to-Intune migrations |
| Event ID 1500 (GPO success) and Event ID 7036 (Workstation service start) are valuable differential diagnostic events — their presence and timestamps can quickly confirm or rule out GPO and SMB-layer causes. | L1/L2 troubleshooting |
| "No retry configured" in IME is a silent risk multiplier — a single transient boot-time failure with no recovery mechanism will affect every user every session until the assignment is fixed. | All Intune script assignments |
| Change log entries that document a known gap ("script not updated to handle SYSTEM context") but proceed with deployment anyway indicate a process enforcement problem, not a knowledge problem. | Change governance |
| Intune Remediations (detection + remediation pairs with a schedule) are more resilient than one-shot Platform Scripts for business-critical configurations like drive mappings. | Architecture decisions |

---

## 11. Sign-Off

| Role | Name | Date |
|------|------|------|
| Incident Owner | | 2024-03-15 |
| Endpoint Engineering Lead | | |
| Change Advisory Board Representative | | |
| Service Desk Lead | | |

---

*Document prepared by: Senior Microsoft Intune / Active Directory / Windows Endpoint Engineer*  
*Incident Date: 2024-03-15 | RCA Completed: 2024-03-15*  
*Status: CLOSED — Resolved and Verified*
