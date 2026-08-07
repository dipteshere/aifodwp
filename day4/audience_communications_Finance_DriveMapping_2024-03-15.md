# Audience Communications — Finance S: Drive Mapping Incident
## 2024-03-15 | Three-Audience Version

**Incident:** S: drive unavailable for all Finance users at login  
**Resolution:** Confirmed resolved and verified  
**Source RCA:** RCA_Finance_DriveMapping_FINAL_2024-03-15.md  

---

## Audience 1 — Non-Technical Executive

**Subject:** Finance shared drive restored — no action required

Your team's access to the Finance shared drive has been fully restored. No data was lost or compromised at any point. The issue was caused by a routine system update made overnight that required a quick configuration correction this morning. All Finance staff can now access their files normally. No action is needed from you or your team.

---

## Audience 2 — Affected Finance Team

**Subject:** S: drive issue fixed — here's what happened and what to do

This morning your S: drive was unavailable after login because a software update made overnight ran under the wrong settings — it has now been corrected and your drive should appear normally at your next login. If you are still missing the S: drive, right-click **This PC** in File Explorer, choose **Map network drive**, enter `\\finbridge-fs01\Finance` as the path, and click **Finish** to restore it for your current session. If the problem persists after your next login, please contact the IT Service Desk.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Subject:** P1 resolved — Finance drive map failure, Intune script context misconfiguration

**Root Cause**  
`Map-FinBridgeDrives.ps1` was migrated from GPO logon script (user context) to Intune Platform Script on 2024-03-14 23:30 (source: DESKTOP-FB022). The Intune script assignment was left at its default — **"Run this script using the logged-on credentials = No"** — causing IME to execute under `NT AUTHORITY\SYSTEM`. SYSTEM has no Kerberos ticket for `finbridge-fs01` and the Workstation service (LanmanWorkstation) was not yet running at IME execution time (Event 7036 fired at 08:00:05, two seconds after IME ScriptRunner had already logged exit code 1 at 08:00:03). Win32 error 67 ("Network name cannot be found"). No retry was configured on the assignment, so the failure was terminal for every login cycle.

**Confirming evidence**  
- `AgentExecutor.log` / `IntuneManagementExtension.log`: `Script context: SYSTEM account` → `Error: Network name cannot be found` → `Exit code: 1` → `No retry configured`  
- System log Event 7036 (SCM): Workstation service Running — timestamp after script failure  
- System log Event 1500 (GroupPolicy): GP processed successfully — eliminates GPO as cause  
- System log Event 98 (NTFS): Drive letter S: not assigned — downstream symptom only  
- Change log entry confirmed migration date/time and noted context gap but was deployed without remediation  

**Action Taken**  
1. Intune admin centre → **Devices → Scripts and remediations → Platform scripts** → `Map-FinBridgeDrives.ps1` → Properties → Edit  
   - Changed: **"Run this script using the logged-on credentials"** → **Yes**  
2. Script content updated (hash change forces IME re-execution on all targeted devices):  
   - Added Workstation service readiness poll (max 60 s, 5 s intervals) before any UNC access  
   - Added `Test-Path \\finbridge-fs01\Finance` reachability check before mapping  
   - Added stale S: drive removal (`Remove-PSDrive -Force`) before `New-PSDrive`  
   - Added structured `try/catch` with `Write-Error` and explicit exit codes  
   - Confirmed **"Run script in 64-bit PowerShell host = Yes"** (required for `New-PSDrive -Persist`)  
3. All DESKTOP-FB* Finance devices forced to sync via Intune admin centre bulk sync  

**Verification**  
- Post-fix `AgentExecutor.log`: `Script context: [domain\user]` → exit code 0 → no errors  
- System log: Event 98 absent on verified devices  
- End-user confirmation: S: accessible and resolves correctly to `\\finbridge-fs01\Finance`  
- Verified on minimum three Finance devices before incident closure  

**Preventive Action Required — still open**  
- **PA-01 (due 2024-03-22):** Publish GPO-to-Intune script migration checklist; mandatory step: review and set execution context before deployment  
- **PA-02 (due 2024-03-22):** CAB gate — test on one device per target OU before broad rollout for any Intune script targeting >10 devices  
- **PA-03 (due 2024-03-22):** Audit all existing SYSTEM-context Intune Platform Scripts; identify any that depend on user credentials or network paths  
- **PA-05 (due 2024-04-15):** Convert Finance drive-mapping (and equivalent scripts in other OUs) to Intune Remediations pairs — detection checks S: root path, remediation re-maps; schedule hourly for self-healing  

**Log path on managed devices**  
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log`  
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`

---

*Communications prepared by: Senior Microsoft Intune / AD / Windows Endpoint Engineer — 2024-03-15*  
*Source: RCA_Finance_DriveMapping_FINAL_2024-03-15.md*
