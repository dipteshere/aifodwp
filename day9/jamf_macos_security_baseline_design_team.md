# JAMF macOS Security Baseline Mapping (DWP Engineer)

Date: 2026-08-14
Scope: JAMF-managed compliance posture for a 25-device Design team macOS fleet

## Reference UI path (latest known)
[UI PATH MAY VARY BY JAMF VERSION/INSTANCE]
- Computers > Configuration Profiles > New
- Platform: macOS
- Payload areas used in this baseline: Security and Privacy, Restrictions, Login Window, Software Update, and smart group criteria for reporting/compliance views
- Scope and sequencing: pilot group first, then full Design device group assignment

## Important validation note (same discipline as Day 6 Intune labs)

JAMF Pro UI wording, payload names, and option labels can vary by JAMF Pro version and by whether your tenant uses classic profile payload views or newer settings catalog experiences.  
For every requirement below, verify the exact label and payload location in your own JAMF instance before implementation.

## Requirement-to-setting translation

### Requirement 1: FileVault disk encryption must be enabled
- Payload type: Security and Privacy > FileVault [UI PATH MAY VARY]
- Value: Enable FileVault; escrow personal recovery key to JAMF; enforce enablement at next login/logout if immediate activation is not possible
- Effect: Device storage is encrypted at rest, reducing data exposure from device loss or theft.
- False-positive risk: Encryption is in progress; user has not completed logout/reboot activation; inventory is stale; recovery key escrow completed after last recon.
- Recommendation: Keep enforced enablement. Pair enforcement with a user prompt window and helpdesk script to verify FileVault state and key escrow before escalation.
- UI path: Computers > Configuration Profiles > <macOS Baseline Profile> > Security and Privacy > FileVault [UI PATH MAY VARY]

### Requirement 2: Gatekeeper must be enabled (identified developers only)
- Payload type: Security and Privacy > Gatekeeper / Application Access [UI PATH MAY VARY]
- Value: Allow apps from App Store and identified developers only
- Effect: Blocks unsigned and unnotarized app execution by default to reduce malware risk.
- False-positive risk: Temporary exception workflows, local admin command-line overrides, and delayed inventory/report refresh can make healthy devices appear out of policy.
- Recommendation: Keep strict baseline and issue time-bound approved exceptions through formal change control for design tooling that cannot meet notarization requirements.
- UI path: Computers > Configuration Profiles > <macOS Baseline Profile> > Security and Privacy > Gatekeeper [UI PATH MAY VARY]

### Requirement 3: Minimum macOS version must be current stable minus one point release
- Payload type: Restrictions and/or compliance reporting smart group criteria (OS version checks are often reported rather than hard-blocked directly by one payload) [UI PATH MAY VARY]
- Value: Set minimum allowed macOS to N-1 point release relative to current stable (example operating rule: if stable is 15.6, minimum allowed is 15.5)
- Effect: Prevents long-tail exposure from outdated macOS point releases.
- False-positive risk: Patch-ring staging delay, Apple release timing across hardware models, and version/build parsing differences can produce transient noncompliance.
- Recommendation: Keep N-1 floor, but deploy phased rollout groups and use compliance smart groups for ring-aware enforcement messaging.
- UI path: Computers > Smart Computer Groups > Criteria (Operating System Version) and related compliance dashboards [UI PATH MAY VARY]

### Requirement 4: Firewall must be enabled
- Payload type: Security and Privacy > Firewall [UI PATH MAY VARY]
- Value: Firewall On for all endpoints; optional stealth mode if approved by security architecture
- Effect: Reduces unsolicited inbound connectivity and lowers endpoint attack surface.
- False-positive risk: Third-party security products may influence observed firewall state; stale inventory after profile deployment may briefly show incorrect status.
- Recommendation: Keep enabled baseline, remove competing controls where possible, and validate post-profile recon before incident escalation.
- UI path: Computers > Configuration Profiles > <macOS Baseline Profile> > Security and Privacy > Firewall [UI PATH MAY VARY]

### Requirement 5: Login password required after sleep or screen saver
- Payload type: Security and Privacy (password timing control) and/or Login Window controls, depending on JAMF version and payload model [UI PATH MAY VARY]
- Value: Require password immediately after sleep or screen saver begins
- Effect: Prevents unauthorized access to unlocked sessions when users step away.
- False-positive risk: Pending session state changes, user-level preference lag, or policy precedence conflicts from overlapping profiles.
- Recommendation: Keep immediate re-authentication requirement and avoid duplicate password-timing controls in multiple profiles.
- UI path: Computers > Configuration Profiles > <macOS Baseline Profile> > Security and Privacy or Login Window [UI PATH MAY VARY]

### Requirement 6: Automatic security updates must be enabled
- Payload type: Software Update [UI PATH MAY VARY]
- Value: Enable automatic check, download, and install for security updates and available critical system response content
- Effect: Keeps endpoints patched against known vulnerabilities with reduced manual effort.
- False-positive risk: Devices offline at maintenance window time, low disk space, power constraints, or delayed telemetry after successful install.
- Recommendation: Keep automatic updates on; define maintenance windows around design production peaks and monitor update failure trends weekly.
- UI path: Computers > Configuration Profiles > <macOS Baseline Profile> > Software Update [UI PATH MAY VARY]

## Assignment and remediation timing (25-device fleet)

- Pilot assignment: 3 to 5 Design devices for 24 to 48 hours.
- Full assignment: Remaining devices only after pilot shows no material toolchain impact.
- Remediation expectation: For drift findings, target same-day user action for low-friction fixes (reboot, logout, update trigger) and 48-hour closure for configuration conflicts.
- Compliance communications: Send notice at detection and follow-up at 24 hours if unresolved.

## Post-assignment validation steps (test device just synced)

### 1) Where to validate this device against this baseline
- Profile scope confirmation: Computers > Configuration Profiles > <macOS Baseline Profile> > Scope > verify target smart/static group membership.
- Device profile receipt: Computers > Inventory > <Device> > Profiles > confirm profile is installed.
- Setting-level cross-check: Computers > Inventory > <Device> > Security and system tabs for FileVault/firewall/update posture.
- Fleet posture check: Smart groups for each requirement (FileVault Off, Firewall Off, OS Below Minimum, Updates Pending) to detect drift quickly.

### 2) Compliance states and access impact
- Compliant: Device has profile applied and reports baseline-aligned state.
- Drift detected: Device has profile but one or more controls are not currently effective.
- Unknown/stale: Device has not checked in recently, so reported state may be outdated.
- Access impact note: If JAMF compliance is linked to conditional access workflows, only baseline-compliant state should satisfy access requirements; stale state can create temporary access friction.

### 3) FileVault false-positive triage (top 3 causes and fastest check)
- Cause 1: FileVault enablement pending user logout/reboot.
- Fastest check: On device, confirm FileVault is On in System Settings and ask user to complete logout/reboot cycle; run inventory update.

- Cause 2: Encryption active but not complete yet.
- Fastest check: Verify encryption progress locally, then re-check after completion and a fresh inventory recon.

- Cause 3: Recovery key escrow not yet reflected.
- Fastest check: Confirm escrow policy assignment and last check-in time; force recon and revalidate key presence in JAMF inventory.

## First-24-hour monitoring checklist (detect false positives early)
- Track smart group counts for each baseline requirement every 2 to 4 hours after rollout.
- Separate stale check-in devices from true control failures before declaring incident volume.
- Review pilot-device helpdesk tickets for design tool breakage linked to Gatekeeper or update settings.
- Validate that remediation actions (logout/reboot/update run) reduce drift counts as expected.
- Escalate only repeated, reproducible failures after at least one fresh inventory cycle.

## Notes
- JAMF UI labels, payload wording, and path layout can change by release and tenant features.
- This mapping provides implementation intent; exact control names should be confirmed live in your JAMF instance before production change.
- Record your final verified UI paths and profile names in this document after deployment for audit repeatability.
