# Day 2 Ticket Triage Summaries

---

## T-1001 — New Win11 laptop, BitLocker prompting for recovery key every boot

### Summary
A new Windows 11 laptop is requesting a BitLocker recovery key on every boot, preventing normal login without the key present.

### Impact
- Affected user(s): 1 end user (to confirm)
- Scope: Single device; user may be fully blocked from logging in without the key
- Business urgency: High — repeated recovery key prompts can lock a user out entirely if key is unavailable

### Known facts
- Device is a new Windows 11 laptop.
- BitLocker recovery key prompt appears on every boot.

### Missing information to gather
- User identity, team, location, and contact details.
- Whether the device has ever booted successfully without the prompt.
- Whether the recovery key has been entered and if that resolves the boot (temporarily or permanently).
- Where the BitLocker recovery key is stored (Azure AD / Entra ID escrow, on-prem AD, local printout).
- Device join type (Azure AD joined, hybrid joined, domain joined, or workgroup).
- Whether TPM is present, enabled, and healthy (TPM management console / BIOS status).
- Whether Secure Boot status has changed or BIOS/UEFI settings were altered.
- Whether any firmware or BIOS updates were applied recently.
- Whether any hardware changes occurred (RAM swap, dock, USB devices at boot).
- Whether there is an active Intune/SCCM policy that could be triggering re-seal.
- Event log entries around BitLocker (Event ID 24620, 24621, or similar in System/BitLocker-Driver logs).

### Likely category
- Endpoint security / BitLocker TPM sealing failure (to confirm)
- Possible subcategory: TPM PCR mismatch, Secure Boot change, BIOS update, or Intune policy issue (to confirm)

### Suggest first diagnostic step
Check whether the TPM is healthy and whether BitLocker is correctly escrowing the recovery key to Azure AD / Entra ID, then review recent BIOS/firmware version against the device baseline to determine if a firmware update or BIOS configuration change broke the TPM seal.

---

## T-1002 — Finance user cannot open a shared mailbox after migration

### Summary
A Finance team user cannot open or access a shared mailbox following a migration, despite presumably having the necessary permissions beforehand.

### Impact
- Affected user(s): 1 Finance user (to confirm whether team-wide)
- Scope: Shared mailbox access blocked; potential impact on Finance team workflows relying on the mailbox
- Business urgency: Medium–High — Finance teams often have time-sensitive mailbox dependencies (to confirm)

### Known facts
- User is in the Finance team.
- Issue began after a migration (Exchange, tenant, or similar — to confirm).
- User cannot open the shared mailbox.

### Missing information to gather
- User identity, UPN, and contact details.
- Name/address of the shared mailbox affected.
- Type of migration (Exchange on-prem to Exchange Online, tenant-to-tenant, mailbox move).
- Error message when attempting to open the mailbox (e.g., "You do not have permission", AutoDiscover failure, HTTP error).
- Whether the user has Full Access or Send As permissions, and whether those permissions were re-applied post-migration.
- Whether the shared mailbox itself completed migration successfully (not stuck/failed).
- Whether the issue affects Outlook desktop, Outlook Web App, or both.
- Whether other Finance team members have the same issue with this mailbox.
- Whether automapping is expected and whether it is functioning.
- Current Outlook profile state (cached credentials, stale profile from old tenant).

### Likely category
- Email / shared mailbox access post-migration (to confirm)
- Possible subcategory: Missing or broken delegated permissions, automapping failure, or stale Outlook profile (to confirm)

### Suggest first diagnostic step
Verify in the Exchange admin centre (or Microsoft 365 admin centre) that the shared mailbox migration completed successfully and that the user's Full Access permission is correctly assigned post-migration, then test access via Outlook on the Web to isolate whether this is a client-side profile issue or a permissions/service issue.

---

## T-1003 — AVD session disconnects after ~10 min, then reconnects

### Summary
An Azure Virtual Desktop (AVD) session repeatedly disconnects after approximately 10 minutes of use before automatically reconnecting, disrupting user productivity.

### Impact
- Affected user(s): 1 end user (to confirm whether others on same host pool are affected)
- Scope: Single user or potentially a host pool / session host issue
- Business urgency: Medium — user can reconnect but productivity is interrupted on each cycle

### Known facts
- Session disconnects approximately every 10 minutes.
- Session reconnects after disconnect (not a full loss of access).

### Missing information to gather
- User identity, team, location, and contact details.
- AVD host pool name and session host the user lands on.
- Client used to connect (Windows Remote Desktop client, web client, AVD client version).
- Network path: home Wi-Fi, corporate network, VPN, or direct internet?
- Whether the 10-minute interval is consistent or approximate.
- Whether the disconnect is a clean session disconnect or a full client crash.
- Any error codes or messages shown at disconnect.
- Whether the issue is reproducible across multiple session hosts or a single host.
- AVD host pool session time-out / idle disconnect policies (check Azure portal — Host pool settings).
- Network Quality of Service metrics: packet loss, latency, jitter from client side.
- Whether other users on the same host pool report the same issue.
- Windows Event logs on the session host (RemoteDesktopServices, TerminalServices-LocalSessionManager).

### Likely category
- Remote access / AVD session stability (to confirm)
- Possible subcategory: Session timeout policy, network instability, session host resource exhaustion, or client idle setting (to confirm)

### Suggest first diagnostic step
Check the AVD host pool session timeout and idle disconnect policies in the Azure portal to confirm they are not set to disconnect at 10 minutes, then compare with the session host event logs to determine whether the disconnect is policy-driven, resource-driven, or network-driven.

---

## T-1004 — Company app fails to install from Company Portal, error 0x87D1041C

### Summary
A company application is failing to install via the Intune Company Portal with error code 0x87D1041C, blocking the user from accessing the required application.

### Impact
- Affected user(s): 1 end user (to confirm whether others in the same group/device target are affected)
- Scope: Single application install failure; may affect all users targeted by the same Intune app deployment
- Business urgency: Medium — user blocked from a required app (urgency depends on app criticality, to confirm)

### Known facts
- App install initiated from Company Portal.
- Error code returned: 0x87D1041C (Intune — "The application was not detected after installation completed successfully").
- Platform assumed to be Windows (to confirm).

### Missing information to gather
- User identity, device name, and contact details.
- Name and version of the application that failed to install.
- Whether the app has ever installed successfully on this device or others.
- Device compliance state and Entra ID / Azure AD join status.
- Whether the Intune Management Extension (IME) is running and up to date on the device.
- IME log file contents: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Whether the app detection rule in Intune matches the actual install path/registry key post-install.
- Whether the app installer itself completes (i.e., the install runs but detection fails, or the install itself fails).
- Whether a reboot is required and pending (pending reboot can block installs).
- Whether the user has a previous version or conflicting version of the app installed.

### Likely category
- Endpoint management / Intune app deployment failure (to confirm)
- Possible subcategory: Incorrect Intune detection rule, IME issue, or installer-side failure (to confirm)

### Suggest first diagnostic step
Review the IntuneManagementExtension.log on the device for the specific app entry to confirm whether the installer completed successfully but the detection rule did not match, or whether the installer itself failed — error 0x87D1041C specifically indicates a detection rule mismatch, so cross-check the configured detection method against what the installer actually writes to disk or registry.

---

## T-1005 — Teams audio dead on three machines in the same meeting room

### Summary
Microsoft Teams audio is not functioning on three separate machines located in the same physical meeting room, suggesting a shared environmental or infrastructure cause rather than an isolated per-device fault.

### Impact
- Affected user(s): Multiple users (at least 3 devices in one meeting room)
- Scope: Entire meeting room affected; meetings in this room cannot use Teams audio
- Business urgency: High — meeting room audio loss directly blocks collaborative meetings

### Known facts
- Teams audio is not working ("dead").
- Three machines in the same meeting room are all affected.
- All three machines are in the same location.

### Missing information to gather
- Whether the three machines share a common audio device (e.g., a room speakerphone, USB hub, or audio dock).
- Whether the audio device is a shared peripheral (USB or Bluetooth) connected to all machines or separate per-device.
- Whether audio works outside of Teams (system sounds, other apps) on the affected machines.
- Whether audio was previously working in this room and when it stopped.
- Any recent changes: Teams updates, Windows updates, firmware updates on audio devices, room reconfiguration.
- Teams version on the affected machines.
- Whether the issue is input (microphone), output (speakers), or both.
- Whether Teams audio device settings (Settings > Devices) show the correct audio device selected.
- Whether the audio device appears healthy in Windows Device Manager (no yellow flags).
- Whether the issue affects only this room or is reported elsewhere.
- Whether a Teams Rooms device (MTR) is involved or these are standard Windows PCs.

### Likely category
- Collaboration / Teams audio failure — shared room environment (to confirm)
- Possible subcategory: Shared audio peripheral fault, Teams audio device selection issue, or driver/firmware issue (to confirm)

### Suggest first diagnostic step
Test whether audio functions outside of Teams on all three machines (play a system sound) to determine if this is Teams-specific or an OS/hardware-level audio failure; if audio works outside Teams, verify the selected audio device in Teams Settings > Devices on each machine and check whether a shared room peripheral is the common point of failure.

---

## T-1006 — 'Everything is slow' — user upgraded to Win11 two days ago

### Summary
A user reports general system slowness across all activity since upgrading to Windows 11 two days ago.

### Impact
- Affected user(s): 1 end user (to confirm)
- Scope: Whole-device performance degradation post-upgrade
- Business urgency: Medium — user can still work but productivity is impaired

### Known facts
- User upgraded to Windows 11 two days ago.
- User reports "everything is slow" — no single app or function isolated.
- Issue has been present since the upgrade.

### Missing information to gather
- User identity, device model/make, hardware spec (CPU, RAM, storage type), and contact details.
- Whether the upgrade was an in-place upgrade or a clean install.
- Current resource utilisation (Task Manager — CPU, RAM, disk, GPU at idle and under load).
- Whether Windows Update has completed all post-upgrade updates and whether any are still pending.
- Whether the device has restarted multiple times since upgrade (first-boot tasks can cause prolonged background activity).
- Whether antivirus / EDR is performing a post-upgrade full scan.
- Whether OneDrive or other sync clients are re-syncing large amounts of data post-upgrade.
- Whether device drivers (GPU, chipset, storage controller) are up to date for Windows 11.
- Whether the device meets Windows 11 hardware requirements fully (TPM 2.0, CPU compatibility).
- Whether there are any reliability or critical errors in Event Viewer since the upgrade.
- Page file / virtual memory configuration and available disk space.

### Likely category
- Endpoint performance / post-Win11 upgrade degradation (to confirm)
- Possible subcategory: Post-upgrade background processing, driver incompatibility, or underpowered hardware (to confirm)

### Suggest first diagnostic step
Open Task Manager and capture CPU, RAM, disk, and network utilisation at idle to identify which resource is saturated; post-upgrade background tasks (Windows Update, OneDrive sync, antivirus scan, indexing) are the most common cause — if a specific process is consuming resources, that drives the next resolution step.

---

## T-1007 — OneDrive stuck 'processing changes' since migration; files missing locally

### Summary
Since a migration, a user's OneDrive client has been stuck in a "processing changes" state and files that should be available locally are missing, risking data loss or inaccessibility.

### Impact
- Affected user(s): 1 end user (to confirm whether broader migration cohort is affected)
- Scope: OneDrive sync broken post-migration; local file availability compromised
- Business urgency: High — files missing locally may indicate data is inaccessible or at risk

### Known facts
- Issue started since a migration (tenant-to-tenant, account migration, or SharePoint/OneDrive migration — to confirm).
- OneDrive client shows "processing changes" status persistently.
- Files expected to be synced locally are missing.

### Missing information to gather
- User identity, UPN (old and new if tenant migration), and contact details.
- Type of migration performed (tenant-to-tenant, OneDrive content migration, account rename).
- Whether the user can access their files via OneDrive on the web (browser).
- Whether the OneDrive client is signed into the correct account (new tenant UPN vs old).
- OneDrive sync error details (right-click system tray icon > View sync problems).
- Whether Known Folder Move (Desktop, Documents, Pictures) was configured and if those folders are present in the new location.
- Duration of "processing changes" state (hours, days).
- OneDrive client version and whether it has been updated post-migration.
- Whether a OneDrive reset has been attempted (`%localappdata%\Microsoft\OneDrive\onedrive.exe /reset`).
- Disk space available locally (insufficient space prevents sync).
- Whether IT has confirmed the migration completed successfully on the back end for this user.

### Likely category
- Cloud storage / OneDrive sync failure post-migration (to confirm)
- Possible subcategory: Account identity mismatch, migration incomplete on back end, or client re-configuration required (to confirm)

### Suggest first diagnostic step
Confirm whether the user's files are intact and accessible via OneDrive on the web with the new account credentials — this determines whether data is present on the service side; if files are visible online but missing locally, the issue is a client sync/configuration problem rather than data loss.

---

## T-1008 — VPN connects but no internal resources reachable after Win11 upgrade

### Summary
After upgrading to Windows 11, a user's VPN client connects successfully but internal company resources (servers, intranet, internal DNS) are unreachable, despite the connection appearing established.

### Impact
- Affected user(s): 1 end user (to confirm whether others on the same VPN client/version are affected)
- Scope: Full remote access to internal resources blocked post-upgrade; user cannot work remotely
- Business urgency: High — user is effectively unable to access any internal services while off-site

### Known facts
- Windows 11 upgrade was performed.
- VPN client connects without error.
- No internal resources are reachable after VPN connects.

### Missing information to gather
- User identity, team, location, and contact details.
- VPN client name and version (Cisco AnyConnect, GlobalProtect, Always On VPN, other).
- Whether the VPN client was reinstalled or updated as part of the Win11 upgrade.
- Whether the issue occurs on Wi-Fi, wired, or both.
- Whether the VPN assigns an IP address correctly post-connect (run `ipconfig /all` after VPN connects).
- Whether DNS resolution works for internal hostnames after VPN connects (`nslookup internal.host`).
- Whether the issue is DNS-only (can ping internal IPs but not hostnames) or full connectivity loss.
- Whether split tunnelling is configured and whether routing table is correct post-connect (`route print` after VPN connects).
- Whether Windows Firewall or a third-party firewall is blocking traffic after upgrade.
- Whether the VPN adapter/driver is correctly installed and healthy in Device Manager.
- Whether any network adapter settings changed during the upgrade (metric, binding order).
- Whether other users on the same VPN client and Windows 11 build have the same issue.

### Likely category
- Remote access / VPN routing or DNS failure post-Win11 upgrade (to confirm)
- Possible subcategory: VPN split-tunnel routing issue, DNS client misconfiguration, Windows Firewall rule change, or VPN driver incompatibility with Win11 (to confirm)

### Suggest first diagnostic step
After VPN connects, run `ipconfig /all` to confirm the VPN adapter has received an IP address and DNS server, then run `nslookup <internal-hostname>` to determine if the failure is DNS resolution — distinguishing between a DNS failure and a routing/firewall failure will define the correct remediation path.
