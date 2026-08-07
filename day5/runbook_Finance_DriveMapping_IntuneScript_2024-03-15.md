# Runbook — Finance Drive Mapping Failure (Intune Script Context)

**Reference RCA:** RCA_Finance_DriveMapping_IntuneScript_2024-03-15.md  
**Incident Type:** Service degradation — Finance S: drive not mapped at login  
**Affected Scope:** All Finance users on DESKTOP-FB* devices (OU=Finance)  
**Last Updated:** 2024-03-15  

---

## 1. Prerequisites

Before starting, confirm you have the following:

### Access Rights
| Requirement | Detail |
|-------------|--------|
| **Intune RBAC role** | Policy and Profile Manager (or higher) — needed to edit script assignments |
| **Azure AD / Entra ID access** | Read access to device and group membership — to verify Finance device group |
| **Local admin or remote admin on a Finance device** | Required to inspect IME logs and verify drive mapping during Verification |
| **Read access to the Intune Management Extension log** | Path: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` |

### Tools
| Tool | Purpose |
|------|---------|
| Microsoft Intune portal (intune.microsoft.com) | Edit script assignment settings |
| Microsoft Endpoint Manager admin centre | Alternative portal access |
| Remote desktop / direct session to a Finance device | Run verification steps |
| PowerShell 5.1+ (run as the test user, not admin) | Verify drive mapping |
| Event Viewer | Confirm Event IDs 7036 and 98 post-fix |

### Information to Gather Before Starting
- Name of the Intune script assignment (`Map-FinBridgeDrives.ps1`)
- Name of the Finance device group targeted by the assignment
- UNC path being mapped: `\\finbridge-fs01\Finance` → drive letter `S:`
- A test Finance user account and a DESKTOP-FB* test device you can log in to
- The change record from 2024-03-14 23:30 (script migration) — for audit trail

---

## 2. Procedure

> **Read all steps before starting.**  
> Steps marked **[ELEVATED]** require Intune admin permissions. Steps marked **[LOCAL]** are performed directly on a Finance device.

---

### Part A — Fix the Intune Script Execution Context

**Step 1.** Open a browser and navigate to [https://intune.microsoft.com](https://intune.microsoft.com).  
*Expected result:* Intune portal loads and you are signed in with your admin account.

**Step 2.** In the left navigation, click **Devices** → **Scripts and remediations** → **Platform scripts**.  
*Expected result:* A list of PowerShell script assignments is displayed.

**Step 3.** Locate and click the script named **Map-FinBridgeDrives.ps1**.  
*Expected result:* The script assignment properties page opens.

**Step 4 [ELEVATED].** Click **Properties** → **Edit** (next to Script settings).  
*Expected result:* The script settings form becomes editable.

**Step 5 [ELEVATED].** Find the setting **"Run this script using the logged on credentials"** and change its value from **No** to **Yes**.  
*Expected result:* The toggle/radio button is set to Yes.

**Step 6 [ELEVATED].** Click **Review + save**, review the change summary, then click **Save**.  
*Expected result:* The portal confirms the assignment has been updated. The setting now shows "Run this script using the logged on credentials: Yes".

---

### Part B — Add a Retry Policy to the Script Assignment

**Step 7 [ELEVATED].** On the same script assignment properties page, click **Edit** next to **Assignment settings** (or equivalent retry configuration section).  
*Expected result:* Assignment settings become editable.

**Step 8 [ELEVATED].** Set **Retry count** to **3** and **Retry interval** to **5 minutes**.  
*Expected result:* Retry fields show values 3 and 5 respectively.

**Step 9 [ELEVATED].** Click **Review + save** → **Save**.  
*Expected result:* Retry policy is saved against the assignment.

---

### Part C — Update the Script to Include a Workstation Service Check

**Step 10 [ELEVATED].** Download the current `Map-FinBridgeDrives.ps1` from the Intune portal (Scripts → select script → **Download**).  
*Expected result:* The .ps1 file is saved locally.

**Step 11 [ELEVATED].** Open the file in a text editor. Insert the following block at the **very top of the script**, before any `net use` or `New-PSDrive` call:

```powershell
# Wait for Workstation service before attempting UNC mapping
$maxWait = 30  # seconds
$waited  = 0
while ((Get-Service -Name LanmanWorkstation).Status -ne 'Running' -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 2
    $waited += 2
}
if ((Get-Service -Name LanmanWorkstation).Status -ne 'Running') {
    Write-Error "LanmanWorkstation not running after $maxWait seconds. Aborting."
    exit 1
}
```

*Expected result:* The file is saved with the service-readiness check at the top.

**Step 12 [ELEVATED].** In the Intune portal, on the **Map-FinBridgeDrives.ps1** properties page, click **Edit** → **Script settings** → upload the updated .ps1 file using the **Script location** field.  
*Expected result:* The portal accepts the new file upload.

**Step 13 [ELEVATED].** Click **Review + save** → **Save**.  
*Expected result:* Updated script version is saved. Note the timestamp for your audit trail.

---

### Part D — Force a Re-evaluation on a Finance Test Device

**Step 14 [LOCAL].** Log in to a Finance test device (DESKTOP-FB* series) as a Finance test user.  
*Expected result:* Desktop loads.

**Step 15 [LOCAL].** Open PowerShell as the **test user** (not as Administrator). Run:
```powershell
Get-Service -Name LanmanWorkstation | Select-Object Status
```
*Expected result:* Output shows `Status: Running`.

**Step 16 [LOCAL].** Force Intune Management Extension to re-check policies. Open PowerShell **as Administrator** and run:
```powershell
Stop-Service -Name IntuneManagementExtension -Force
Start-Service -Name IntuneManagementExtension
```
*Expected result:* Service restarts without error.

**Step 17 [LOCAL].** Wait **5 minutes** to allow IME to pick up and execute the updated script assignment.  
*Expected result:* No action required during this wait.

---

## 3. Verification

> Perform all verification steps before closing the incident or contacting users.

**V1 [LOCAL].** Open PowerShell as the **test user** (not Administrator) and run:
```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue
```
*Expected result:* Output shows drive `S:` with `Root` set to `\\finbridge-fs01\Finance`. If no output, the fix has not taken effect — do not close; go to Rollback.

**V2 [LOCAL].** In File Explorer, navigate to **This PC**. Confirm drive **S: (Finance)** is present and shows no red X.  
*Expected result:* S: is accessible and browsable.

**V3 [LOCAL].** Open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. Search for the most recent execution of `Map-FinBridgeDrives.ps1`. Confirm the log contains:
- `Script context: <username>` (not `SYSTEM`)
- No `Error` line for this script execution
- `Exit code: 0`

*Expected result:* Script ran as the logged-on user and exited successfully.

**V4 [LOCAL].** Open **Event Viewer** → **Windows Logs** → **System**. Filter for Event ID **98** (NTFS drive letter not assigned). Confirm no new Event 98 entries appear after the IME restart in Step 16.  
*Expected result:* No new Event ID 98 entries for S:.

**V5.** In the Intune portal, navigate to **Devices** → **Scripts** → **Map-FinBridgeDrives.ps1** → **Device status**. Filter for the test device. Confirm the status column shows **Success**.  
*Expected result:* Status is `Success`, not `Failed` or `Pending`.

---

## 4. Rollback

> Use this section if any verification step fails or if the procedure makes drive mapping worse.

> **These steps restore the script assignment to its pre-fix state. Do not attempt to diagnose further before rolling back — stabilise first.**

**R1 [ELEVATED].** In the Intune portal, navigate to **Devices** → **Scripts** → **Map-FinBridgeDrives.ps1** → **Properties** → **Edit** (Script settings).  
*Expected result:* Script settings form opens.

**R2 [ELEVATED].** Set **"Run this script using the logged on credentials"** back to **No**.  
*Expected result:* Setting reverts to No (SYSTEM context).

**R3 [ELEVATED].** Re-upload the **original** `Map-FinBridgeDrives.ps1` (without the Workstation service check added in Step 11). Use the copy you downloaded in Step 10 before editing.  
*Expected result:* Original script file is restored in the portal.

**R4 [ELEVATED].** Set **Retry count** back to **0** (or the value it held before Step 8 — check your notes from Step 7).  
*Expected result:* Retry policy is cleared.

**R5 [ELEVATED].** Click **Review + save** → **Save**.  
*Expected result:* Assignment is restored to its pre-change state.

**R6 [LOCAL].** On the test Finance device, open PowerShell as Administrator and run:
```powershell
Stop-Service -Name IntuneManagementExtension -Force
Start-Service -Name IntuneManagementExtension
```
*Expected result:* IME restarts and will re-apply the rolled-back assignment.

**R7.** Raise a Priority 2 incident and escalate to the Senior Intune Engineer. Reference this runbook, the RCA (RCA_Finance_DriveMapping_IntuneScript_2024-03-15.md), and the change record from 2024-03-14 23:30. Do not attempt further changes without senior sign-off.

> **Note:** Rolling back to SYSTEM context does not restore drive mapping for users — it simply returns the environment to the known pre-fix broken state so no additional damage is caused. Users will still need a manual workaround (see Notes below) until a new fix is approved.

---

## 5. Notes

### Manual Workaround for Users During Outage
If users need access to `\\finbridge-fs01\Finance` before the fix is confirmed, they can map the drive manually:
1. Open File Explorer.
2. Click **This PC** → **Map network drive** (toolbar or right-click).
3. Drive letter: **S:**, Folder: `\\finbridge-fs01\Finance`, tick **Reconnect at sign-in**.
4. Enter domain credentials when prompted.

This is a temporary workaround only — it does not persist across all sign-in scenarios and will be replaced by the scripted mapping once the fix is confirmed.

### Edge Cases
| Scenario | What to do |
|----------|------------|
| IME does not re-execute the script after Step 16 | In the Intune portal, remove the Finance device from the target group, save, re-add it, and save again to force re-evaluation |
| Script runs as logged-on user but still fails with "Access Denied" | The user account may not have permission to `\\finbridge-fs01\Finance` — escalate to the File Server team; do not modify the script |
| Multiple Finance users report failure after the fix | Check if the Finance device group in Azure AD / Entra ID has drifted — re-confirm all DESKTOP-FB* devices are members |
| Device is in a location with high SMB latency (e.g. remote site, VPN) | Increase `$maxWait` in the script from 30 to 60 seconds and re-upload |
| Event ID 7036 (LanmanWorkstation start) still appears after script execution | Race condition may still be occurring; increase the wait loop and check network boot order |

### Warnings
- **Do not enable "Run as logged-on credentials" for scripts that require SYSTEM-level privileges** — this change is safe for drive-mapping scripts only. Audit any other IME script assignments before applying the same change.
- **Do not delete and re-create the script assignment** as a shortcut — this resets all device status history and complicates audit trails.
- **The change record from 2024-03-14 23:30 must be updated** to reflect this remediation. Failure to do so will leave the change open and may trigger CAB review.

### Related Incidents and Knowledge Articles
| Reference | Detail |
|-----------|--------|
| RCA_Finance_DriveMapping_IntuneScript_2024-03-15.md | Source RCA for this runbook |
| RCA_Finance_DriveMapping_FINAL_2024-03-15.md | Final incident report |
| Change record 2024-03-14 23:30 (DESKTOP-FB022) | Original script migration that introduced the fault |
| Event ID 7036 (Service Control Manager) | LanmanWorkstation start — use to time-correlate script execution in future incidents |
| Event ID 98 (NTFS) | Drive letter not assigned — use as a fast signal that drive mapping failed |

---

*Runbook prepared from RCA by: DWP Engineer*  
*Date: 2024-03-15*  
*Review before use if more than 90 days have passed since this date.*
