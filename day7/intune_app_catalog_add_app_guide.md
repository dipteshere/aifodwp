# Adding a Windows Application to the Intune App Catalog
**Guide type:** Step-by-step operational guide
**Audience:** DWP engineers with no prior Intune app-deployment experience
**Worked example throughout:** FinBridge Connect v3.1 (.intunewin LOB app)
**Prerequisite:** You have Intune Administrator or a delegated app-management role in your tenant.

> **Tenant version note (read before you start):** Microsoft updates the Intune portal continuously. UI labels, menu positions, and field names shown in this guide reflect the current admin center layout at time of writing. Before executing each step, verify the label you see in your own tenant. Where labels commonly drift between tenant versions, this guide flags the step with a **[VERIFY LABEL]** callout.

---

## Section 1 — Where to Add an App in Intune

### 1.1 Navigate to the Apps blade

1. Open a browser and go to [https://intune.microsoft.com](https://intune.microsoft.com).
2. Sign in with your Intune-admin-capable account.
3. In the left-hand navigation pane, select **Apps**. **[VERIFY LABEL]** — on some tenant versions this pane item is labelled **Client apps** or appears under a collapsible **Apps** group.
4. Under **Apps**, select **All apps** (or **Windows** if you want to scope the view immediately). **[VERIFY LABEL]**
5. Select **+ Add** (top-left of the app list). A **Select app type** flyout panel opens.

### 1.2 Choose the correct app type

Use the table below to pick the right type before proceeding.

| Scenario | App type to select |
|---|---|
| Packaged `.intunewin` file (Windows LOB app) | **Line-of-business app** (under the *App type* > *Other* section) **[VERIFY LABEL]** |
| App available in the Microsoft Store | **Microsoft Store app (new)** — for the modern Store integration; or **Windows app (Win32)** if you have a wrapped Store package **[VERIFY LABEL]** |
| Shortcut to an internal or external website | **Web link** |

**For FinBridge Connect v3.1:** Select **Line-of-business app**, then click **Select**.

---

## Section 2 — Required Fields When Creating a LOB Windows App

After selecting **Line-of-business app** and clicking **Select**, a creation wizard opens. Work through each tab in order.

### 2.1 App information

| Field | What to enter | FinBridge Connect example |
|---|---|---|
| **App package file** | Upload your `.intunewin` file using the file picker | `FinBridgeConnect_v3.1.intunewin` |
| **Name** | Display name shown to users and in reports. Keep it consistent across all catalog entries. | `FinBridge Connect` |
| **Description** | Plain-language description. Include the purpose, supported OS, and who to contact for support. | `FinBridge Connect enables secure connectivity to the Finance Bridge platform. Deployed to Finance BU devices. Support: servicedesk@dwp.gov.uk` |
| **Publisher** | The software vendor or internal team who owns the package. | `FinBridge Ltd` |
| **App version** | Version string. Used in reporting; does not control detection — detection rules do that (Section 2.4). | `3.1` |
| **Category** *(optional)* | Assign a category to make the app findable in the Company Portal. | `Finance Tools` |
| **Show this as a featured app in the Company Portal** | Set to **Yes** only if you want it highlighted. Leave **No** for most LOB deployments. | `No` |
| **Information URL** / **Privacy URL** *(optional)* | Link to internal documentation or vendor privacy page. | *(leave blank or add intranet KB link)* |
| **Logo** *(optional)* | Upload a 48×48 PNG icon. | *(upload FinBridge icon if available)* |

Click **Next** when all required fields are complete.

### 2.2 Program (install and uninstall commands)

This tab tells Intune exactly how to install and remove the app silently.

| Field | Guidance | FinBridge Connect example |
|---|---|---|
| **Install command** | The full command line Intune will run. Must be silent/unattended — no interactive prompts. | `FinBridgeConnect_Setup.exe /silent` |
| **Uninstall command** | The command Intune runs when the app is uninstalled via assignment. | `FinBridgeConnect_Setup.exe /uninstall /silent` |
| **Install behavior** | **System** runs the installer as SYSTEM (no user context required — recommended for most LOB apps). **User** runs in the context of the logged-in user. | `System` |
| **Device restart behavior** **[VERIFY LABEL]** | Typically set to **Determine behavior based on return codes** unless you know the installer forces a restart. | `Determine behavior based on return codes` |

> **Install behavior — system vs user:**
> - **System context** — Intune Management Extension runs the installer as LocalSystem. The device does not need a user logged in. Best for apps that install to `C:\Program Files` and write to `HKLM`.
> - **User context** — Installer runs as the signed-in user. Required only if the app installs per-user (writes to `HKCU`, installs to `%AppData%`). Avoid unless necessary — it requires a user to be present during deployment.

Click **Next**.

### 2.3 Requirements

Intune evaluates these rules before attempting the install. If the device does not meet them, the app shows as **Not applicable** rather than **Failed**.

| Field | Guidance | FinBridge Connect example |
|---|---|---|
| **Operating system architecture** | Select **32-bit**, **64-bit**, or both. Match what your `.intunewin` package supports. | `64-bit` |
| **Minimum operating system** **[VERIFY LABEL]** | Select the lowest Windows 10/11 build your app supports. Drop-down values vary by tenant version — verify the options available to you. | `Windows 10 21H2` |
| **Disk space required (MB)** *(optional)* | Prevents install on devices with insufficient storage. | *(leave blank unless known)* |
| **Physical memory (MB)** *(optional)* | Minimum RAM. | *(leave blank unless known)* |
| **Minimum number of logical processors** *(optional)* | Rarely needed. | *(leave blank)* |
| **Minimum CPU speed (MHz)** *(optional)* | Rarely needed. | *(leave blank)* |

Click **Next**.

### 2.4 Detection rules

Detection rules are how Intune determines whether the app is already installed after the install command runs. Getting this wrong causes repeated re-installs or false **Not installed** statuses.

**Available detection rule types:**

| Type | When to use |
|---|---|
| **Registry** | App writes a version key to the registry on install (most reliable for versioned apps). |
| **MSI product code** | App is an MSI and you know the GUID from the MSI package. |
| **File** | App installs a specific file or folder to a known path (use as a fallback). |

**For FinBridge Connect v3.1 — registry detection:**

1. Select **Manually configure detection rules**, then click **+ Add**.
2. Set **Rule type** to **Registry**. **[VERIFY LABEL]**
3. Fill in the fields as follows:

| Field | Value |
|---|---|
| **Key path** | `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect` |
| **Value name** | `Version` |
| **Detection method** | `String comparison` |
| **Operator** | `Equals` |
| **Value** | `3.1` |
| **Associated with a 32-bit app on 64-bit clients** | `No` (FinBridge is a 64-bit app) |

> If the registry key is present and the value equals `3.1`, Intune marks the app as **Installed**. If the key is absent or the value differs, the app is **Not installed** and Intune will attempt (re-)installation.

Click **OK** to save the rule, then click **Next**.

### 2.5 Return codes

Return codes tell Intune how to interpret the exit code returned by the installer. Misconfigured return codes can cause Intune to retry an install that already succeeded.

**Default codes (pre-populated by Intune — verify these exist in your tenant):**

| Exit code | Type | Meaning |
|---|---|---|
| `0` | Success | Install completed successfully. |
| `1707` | Success | Install completed successfully (MSI). |
| `3010` | Soft reboot | Installed successfully; reboot required but not forced. |
| `1641` | Hard reboot | Installed successfully; reboot initiated by installer. |
| `1618` | Retry | Another install is in progress; Intune will retry. |

**For FinBridge Connect v3.1:** The default return code set is sufficient. If your vendor documentation specifies additional success or error codes, click **+ Add** to include them.

> Check vendor release notes or run the installer manually on a test machine (`FinBridgeConnect_Setup.exe /silent ; echo Exit: $LASTEXITCODE`) to confirm the exit code on success before finalising.

Click **Next**, review the **Review + create** summary, then click **Create**.

---

## Section 3 — Assignment Basics

Creating the app does not deploy it. You must assign it to groups. Navigate to the newly created app entry → **Properties** → **Assignments** → **Edit**, or use the **Assignments** tab immediately after creation.

### 3.1 Assignment types explained

| Assignment type | What it does | When to use |
|---|---|---|
| **Required** | Intune installs the app automatically on all devices in the assigned group, whether or not a user initiates it. | Mandatory corporate tooling that must be present on every device in scope. |
| **Available for enrolled devices** | The app appears in the Company Portal. Users can choose to install it. Nothing installs without user action. | Optional tools, departmental apps, self-service installs. |
| **Uninstall** | Intune removes the app from devices in the assigned group. | Decommissioning an app, removing from a group that no longer needs it. |

> **Conflict rule:** If the same device is in both a **Required** group and an **Uninstall** group, **Required** wins. Avoid assigning both to the same device.

### 3.2 Why you must test with a pilot group first

Deploying directly to the full 10,000-device fleet on first release carries significant risk:

- A silent install with an incorrect install command causes 10,000 simultaneous failures and potential support surge.
- A missing requirement rule deploys to incompatible hardware and generates noise in reports.
- An incorrect detection rule causes continuous re-install loops across the fleet.
- A forced reboot return code interpreted incorrectly reboots devices mid-session fleet-wide.

**Recommended rollout sequence for FinBridge Connect v3.1:**

```
Stage 1 — IT Pilot (5–10 devices, engineer-owned)
  Assignment type: Required
  Group: SG-Intune-AppPilot-IT

Stage 2 — Business Pilot (20–50 devices, nominated users from Finance BU)
  Assignment type: Required
  Group: SG-Intune-AppPilot-Finance

Stage 3 — Broad rollout (all target devices)
  Assignment type: Required
  Group: SG-Finance-AllDevices   ← only after Stage 1 and 2 pass
```

To add assignments:
1. Click **+ Add group** under the **Required** section.
2. Search for and select `SG-Intune-AppPilot-IT`.
3. Leave **Schedule** as **As soon as possible** for Stage 1.
4. Click **Review + save**.

---

## Section 4 — Verification Steps

### 4.1 Confirm the app appears correctly in the catalog

1. In the Intune portal, navigate to **Apps** → **All apps**.
2. Search for `FinBridge Connect`.
3. Verify:
   - Name, publisher, and version match what was entered in Section 2.1.
   - **Platform** shows `Windows`.
   - **App type** shows `Line-of-business app`.
   - **Assigned** shows **Yes** (if you completed Section 3).
4. Open the app entry and review **Properties** to confirm install/uninstall commands, detection rules, and assignments are saved as expected.

### 4.2 Check install status on an assigned test device

1. In the Intune portal, navigate to **Apps** → **All apps** → select **FinBridge Connect**.
2. Select **Device install status** (or **Monitor** → **Device install status**). **[VERIFY LABEL]**
3. Locate your Stage 1 pilot device by name or device ID.
4. Allow up to 8 hours for initial policy sync after assignment. To force a faster check-in:
   - On the test device, open **Settings** → **Accounts** → **Access work or school** → click your account → **Info** → **Sync**. **[VERIFY LABEL — path varies between Windows 10 and Windows 11]**
   - Or run in an elevated PowerShell session: `Start-Process "intunemanagementextension://syncapp"`

### 4.3 Understanding install status values

| Status shown | What it means | Action |
|---|---|---|
| **Installed** | Detection rule evaluated successfully — the registry key and value were found matching the configured criteria. App is present. | No action required. Proceed to Stage 2 when all pilot devices show this. |
| **Failed** | The install command ran but returned an unexpected exit code, or the detection rule evaluated as not met after install. | Review the Intune Management Extension log at `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` on the device. Check the install command and detection rule. |
| **Not applicable** | The device did not meet one or more requirement rules (Section 2.3) — e.g., wrong OS version or architecture. | Check the device's Windows build and architecture against your requirement settings. This is not an error — it means Intune correctly excluded the device. |
| **Pending** | The device has received the policy but the install has not yet been attempted or completed. | Wait for the next Intune sync cycle (up to 8 hours) or trigger a manual sync. |
| **Not installed** | The device is in scope and meets requirements, but the detection rule found the app absent. Intune will retry. | If this persists after 3 cycles, check the detection rule values match what the installer actually writes to the registry. |

### 4.4 Escalation if install fails on pilot devices

If **Failed** status persists on all pilot devices after reviewing the IME log:

1. Re-test the install command manually on a local machine to confirm the silent flag works.
2. Confirm the `.intunewin` package was created correctly using the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool).
3. Check that the package file did not exceed the Intune upload size limit (currently 30 GB, but verify in your tenant).
4. Raise with your Intune/SCCM escalation team before widening assignment beyond Stage 1.

---

## Summary Checklist

Use this before widening rollout to each new stage.

- [ ] App uploaded with correct `.intunewin` file
- [ ] Name, publisher, version fields completed
- [ ] Install command tested manually and confirmed silent
- [ ] Uninstall command confirmed
- [ ] Install behavior set to **System** (or **User** with documented justification)
- [ ] OS architecture and minimum OS version set
- [ ] Detection rule configured and validated against actual install output
- [ ] Return codes reviewed; vendor-specific codes added if required
- [ ] Stage 1 pilot group assigned (**Required**)
- [ ] All Stage 1 devices show **Installed** status before Stage 2 begins
- [ ] All Stage 2 devices show **Installed** status before broad rollout

---

*Guide owner: DWP Engineering — Digital Workplace Platform*
*Review this guide against your live tenant before each deployment — Intune UI labels and portal layout change with Microsoft releases.*
