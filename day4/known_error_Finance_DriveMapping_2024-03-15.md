# Known-Error Record — Finance S: Drive Not Mapped at Login

**Knowledge Base ID:** KE-2024-03-15-FINANCE-DRIVEMAP  
**Status:** Active  
**Date Raised:** 2024-03-15  
**Source RCA:** RCA_Finance_DriveMapping_FINAL_2024-03-15.md  

---

**Symptom**  
Finance users log in to find drive letter S: missing or showing a red X in File Explorer; `\\finbridge-fs01\Finance` is not accessible for the session. System Event ID 98 is recorded by NTFS stating the drive letter has not been assigned.

**Cause**  
The drive-mapping script `Map-FinBridgeDrives.ps1` was migrated from a GPO logon script (runs as the logged-on user) to an Intune Platform Script with the default setting "Run this script using the logged-on credentials = No", causing it to execute as `NT AUTHORITY\SYSTEM`. SYSTEM has no domain credentials or Kerberos ticket for `finbridge-fs01`, and the Workstation service (LanmanWorkstation) is not yet running at the point IME executes the script, returning Win32 error 67 — "Network name cannot be found."

**Scope**  
All users on DESKTOP-FB* devices in OU=Finance. No other OUs, drive letters, or file servers are affected by this specific error.

**Workaround**  
In File Explorer, right-click **This PC → Map network drive**, select drive letter **S:**, enter path `\\finbridge-fs01\Finance`, tick **Reconnect at sign-in**, and click **Finish**. This restores access for the current session only and must be repeated until the permanent fix is applied.

**Permanent Fix**  
In the Intune admin centre, open the `Map-FinBridgeDrives.ps1` script assignment under **Devices → Scripts and remediations → Platform scripts**, edit the assignment, and set **"Run this script using the logged-on credentials"** to **Yes**. After saving, force a sync on all affected DESKTOP-FB* devices; IME will re-execute the script under the user's token and map S: successfully.

**How to Spot It**  
Look for all three signals appearing together within the same boot window: IME log entries `Script context: SYSTEM account` and `Error: Network name cannot be found` (exit code 1) in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log`, System **Event ID 7036** (Workstation service entering Running state) timestamped *after* the IME script failure, and System **Event ID 98** (NTFS — drive letter not assigned) for drive S:. The absence of any Group Policy error and a clean **Event ID 1500** confirm this is an Intune script context issue, not a GPO fault.

---

*Record raised by: Senior Microsoft Intune / AD / Windows Endpoint Engineer — 2024-03-15*
