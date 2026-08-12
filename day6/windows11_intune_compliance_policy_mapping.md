# Windows 11 Intune Compliance Policy Mapping (DWP Engineer)

Date: 2026-08-11
Scope: Intune compliance policy for Windows 10 and later (applies to Windows 11)

## Reference UI path (latest known)
[UI PATH MAY VARY BY TENANT/ROLLOUT]
- Intune admin center > Devices > Compliance > Policies > Create policy
- Platform: Windows 10 and later
- Compliance settings: Device health, Device properties, System security
- Actions for noncompliance: Mark device noncompliant

## Requirement-to-setting translation

### Requirement 1: BitLocker must be enabled on the OS drive
- Settings name: Require BitLocker
- Value: Require
- Effect: Device is compliant only when BitLocker is enabled (measured using Windows attestation state).
- False-positive risk: BitLocker was just enabled but device has not rebooted; attestation can lag until next boot. Temporary BitLocker suspension during firmware/BIOS work can also report noncompliant.
- Recommendation: Keep this as Require. Add user guidance to reboot after encryption completes, and add helpdesk runbook checks for BitLocker suspension/resume before escalating.
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > Device health > Require BitLocker [UI PATH MAY VARY]

### Requirement 2: Secure Boot must be enabled
- Settings name: Require Secure Boot to be enabled on the device
- Value: Require
- Effect: Device is compliant only when UEFI Secure Boot is on.
- False-positive risk: Legacy BIOS/CSM mode devices and some TPM 1.2 scenarios can report noncompliant even if otherwise healthy for their age.
- Recommendation: Keep Require. Pre-inventory hardware/firmware support and place unsupported legacy devices into a short-lived remediation or replacement cohort (not permanent exclusion).
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > Device health > Require Secure Boot to be enabled on the device [UI PATH MAY VARY]

### Requirement 3: Minimum OS build N-1 (22621.2861)
- Settings name: Minimum OS version
- Value: 10.0.22621.2861
- Effect: Devices below build 22621.2861 are marked noncompliant.
- False-positive risk: Devices still within approved patch rollout windows (ring delay), and manual entry mistakes in version format can cause widespread noncompliance.
- Recommendation: Keep minimum floor at 10.0.22621.2861. For safer operations, use phased assignments by update ring, or use Valid operating system builds to allow approved ranges without lowering security.
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > Device properties > Minimum OS version [UI PATH MAY VARY]

### Requirement 4: Windows Defender real-time protection must be on
- Settings name: Real-time protection
- Value: Require
- Effect: Device is compliant only when Microsoft Defender real-time monitoring is enabled.
- False-positive risk: Third-party AV products can place Defender into passive/disabled state by design, causing healthy protected devices to appear noncompliant.
- Recommendation: If your security standard allows non-Defender AV, do not weaken protection; instead define an equivalent-control rule set (for example, keep Antivirus = Require and enforce MDE risk) and document approved AV scenarios. If Defender is the standard, keep Real-time protection = Require with no exception.
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > System security > Defender > Real-time protection [UI PATH MAY VARY]

### Requirement 5: Firewall must be enabled for all profiles
- Settings name: Firewall
- Value: Require
- Effect: Device is compliant only when Windows Firewall is enabled and users cannot turn it off.
- False-positive risk: Conflicting GPO or local policy can override Intune and cause noncompliance even when endpoint protection is otherwise healthy. Immediate post-boot sync can occasionally return transient error/noncompliant states.
- Recommendation: Keep Require. Remove conflicting firewall GPOs and manage firewall posture from Intune consistently. If transient errors are common, rely on the 7-day grace period before access impact.
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > System security > Device security > Firewall [UI PATH MAY VARY]

### Requirement 6: A PIN or password must be configured
- Settings name: Require a password to unlock mobile devices
- Value: Require
- Effect: Device requires user authentication (password/PIN) for local access.
- False-positive risk: Shared kiosk or specialized sign-in modes, hybrid policy conflicts, or delayed sync after credential policy changes can temporarily flag devices.
- Recommendation: Keep Require. Pair with clear Windows Hello for Business policy design (PIN complexity/length) to avoid policy collisions and ambiguous sign-in states.
- UI path: Devices > Compliance > Policies > Windows 10 and later > Compliance settings > System security > Password > Require a password to unlock mobile devices [UI PATH MAY VARY]

### Requirement 7: Device must not be jailbroken or rooted
- Settings name: Not available as a native Windows 10/11 compliance setting
- Value: N/A
- Effect: No direct jailbreak/root toggle exists for Windows compliance policies.
- False-positive risk: If implemented via custom compliance scripts, aggressive tamper heuristics can flag admin tools, debuggers, or approved engineering builds.
- Recommendation: Implement equivalent assurance using native Windows controls (Secure Boot, BitLocker, Defender, Firewall) plus Defender for Endpoint risk-based compliance and/or custom compliance script with tested allow-list logic.
- UI path: N/A in Windows compliance policy [UI PATH MAY VARY]

## Grace period configuration (applies to all settings in this policy)
- Setting area: Actions for noncompliance
- Action: Mark device noncompliant
- Schedule (days after noncompliance): 7
- Effect: Users get a 7-day remediation window before full noncompliant enforcement is applied (for Conditional Access impact).
- False-positive risk: During transient sensor/reporting delays, devices can remain in grace period and appear unresolved if check-ins are infrequent.
- Recommendation: Keep 7 days as requested; add user notifications at day 0 and day 5, and monitor per-setting compliance reports to catch systemic false positives early.
- UI path: Devices > Compliance > Policies > <Your Windows policy> > Properties > Actions for noncompliance > Mark device noncompliant [UI PATH MAY VARY]

## Post-assignment validation steps (test device just synced)

### 1) Where to see this device's status for this specific policy
- Policy view (single policy): Devices > Compliance > Policies > <Your Windows 10/11 compliance policy> > Monitor > View report
- Device drill-down for this policy: In View report, search Device name, then open the row to see per-policy result and failing setting category.
- Per-setting confirmation: Devices > Compliance > Policies > <Your Windows 10/11 compliance policy> > Monitor > Per-setting status > select the count under Not compliant for the relevant setting (for example, Require BitLocker).
- Cross-check from device blade: Devices > All devices > <Device> > Device compliance > select the Windows policy to confirm status/time.

### 2) Compliance states and Conditional Access impact
- Compliant: Device meets policy settings (or is otherwise currently treated as compliant for that policy). If CA requires compliant device, access is allowed.
- Not compliant: Device has failed one or more settings after grace window expires (or immediately if schedule is 0). If CA requires compliant device, access is blocked.
- In grace period: Device has a failure, but the Mark device noncompliant action is delayed (7 days in this baseline). User can remediate before enforcement; CA block is expected after grace expires if still failing.
- Important context: This behavior depends on CA grant controls requiring compliant device and on your configured noncompliance action schedule.

### 3) BitLocker false-positive triage (top 3 causes + fastest check)
- Cause 1: Device Health Attestation lag because status is measured at boot.
- Fastest check: Confirm BitLocker is On in Windows Security or with `manage-bde -status`, then reboot once and trigger Intune sync from Company Portal.

- Cause 2: BitLocker encryption is enabled but temporarily suspended (common after firmware/BIOS/TPM operations).
- Fastest check: Run `manage-bde -status C:` and verify Protection Status is On (not Suspended). Resume protectors if suspended, reboot, sync.

- Cause 3: UEFI/TPM attestation prerequisites are unhealthy (for example, Secure Boot off, TPM issue, legacy boot mode), causing DHA-based BitLocker evaluation to fail.
- Fastest check: Run `msinfo32` and verify BIOS Mode = UEFI and Secure Boot State = On; run `tpm.msc` to confirm TPM ready; then recheck policy status after sync.

### First-24-hour monitoring checklist (to detect false positives early)
- Monitor > View report: watch Not compliant and In grace period counts for sudden spikes right after assignment.
- Monitor > Per-setting status: isolate failures on Require BitLocker vs other settings.
- Filter failures by OS version/build: distinguish migration ring timing from true security drift.
- Validate Last check-in time: separate stale-reporting devices from newly evaluated devices.
- Track helpdesk incidents and CA sign-in blocks tied to this policy for correlated impact.

## Notes
- Intune UI labels and navigation can change by service release, role experience, and portal refresh cycles.
- Latest known naming and structure are based on current Microsoft Learn documentation for Windows compliance settings.
