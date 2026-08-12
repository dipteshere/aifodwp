# Detailed Analysis: Autopilot Enrolment Failure (DESKTOP-FB099)

## Incident Summary
- Device: DESKTOP-FB099
- User: FINBRIDGE\\rthomas
- Date observed: 2024-03-15 09:22
- Autopilot enrolment state: Failed
- Primary error: 0x80180014
- Error description: The device is already enrolled in MDM.
- Existing MDM enrolment: Yes (legacy manual enrolment from 2023-11-04)
- Azure AD joined: Yes
- Licensing: Present (M365, Intune P1, Autopilot)
- Network: Healthy (required endpoints reachable, no proxy)

## Confirmed Root Cause
Autopilot enrolment failed because the device already had an existing legacy/manual MDM enrolment record (from 2023-11-04). The pre-existing enrolment conflicts with the new Autopilot-driven MDM enrolment flow.

## Objective
Remove stale legacy enrolment artifacts (service-side and device-side), then rerun Autopilot enrolment cleanly so the device can enrol and receive policy.

## Remediation Steps (Exact)

### A. Intune admin center cleanup [Admin Center only]
1. Sign in to Microsoft Intune admin center.
2. Go to Devices > All devices.
3. Search for DESKTOP-FB099 and also search by serial number if available.
4. Identify legacy/stale managed device record(s):
   - Enrolment type/source indicates legacy/manual path.
   - Last check-in is stale or inconsistent with current repro window.
5. For stale device record(s), select Retire (if device is still associated and reachable), then Delete the stale managed device entry once retirement is complete/appropriate.
6. Go to Devices > Windows > Windows enrollment > Devices (Autopilot devices).
7. Locate the Autopilot device object by serial number/hardware hash.
8. Confirm exactly one correct Autopilot registration exists. Remove duplicate/stale Autopilot entries if found.
9. Go to Tenant administration > Connectors and tokens > Microsoft Entra join and enrollment (or equivalent enrollment restrictions area in your tenant UI) and confirm no policy restriction is forcing an alternate legacy method for this user/device cohort.

### B. Microsoft Entra device object sanity check [Admin Center only]
1. Open Microsoft Entra admin center.
2. Go to Devices > All devices.
3. Search for DESKTOP-FB099 and serial-correlated records.
4. If duplicates exist, keep the intended active identity path and remove stale/disabled duplicates that map to the old manual enrolment history (per your identity governance process).
5. Confirm user FINBRIDGE\\rthomas remains in the correct groups for Autopilot and Intune assignment.

### C. Device-side unenrolment cleanup [Device access required]
1. Access the endpoint (physical console preferred during OOBE/autopilot testing, or approved remote method pre-reset).
2. In Windows, open Settings > Accounts > Access work or school.
3. Disconnect the old work/school connection that corresponds to the legacy manual MDM enrolment.
4. Open certlm.msc (Local Computer certificates) and verify old MDM enrolment certificate artifacts are removed if still present and clearly tied to the stale enrolment.
5. Open Task Scheduler > Microsoft > Windows > EnterpriseMgmt and confirm stale enrolment task folders associated with the removed enrolment are no longer active.

### D. Reset/reprovision for clean Autopilot run [Device access required]
1. Perform the approved reset path for your environment so the device returns to OOBE for Autopilot:
   - Typical path: Fresh Start/Wipe from Intune (if still manageable), or local Reset this PC per endpoint process.
2. Ensure device has internet access at OOBE.
3. Start Autopilot sign-in with intended user credentials.
4. Allow enrolment and ESP/policy stages to complete without interruption.

## Correct Order of Operations
1. Intune stale managed-device cleanup.
2. Autopilot device object deduplication/validation.
3. Entra device object deduplication sanity check.
4. Device-side legacy unenrolment cleanup.
5. Device reset to OOBE.
6. Rerun Autopilot enrolment.
7. Post-enrolment validation.

## Verification Checks After Remediation

### Success criteria [Admin Center only]
1. In Intune admin center > Devices > All devices:
   - DESKTOP-FB099 appears with current check-in.
   - Enrolment method aligns to Autopilot/MDM expected path.
2. In device configuration/profile status:
   - Previously failing profile (FinBridge-Win11-Security-Baseline) shows success or in-progress toward success.
   - Profiles are no longer 0 of 4 applied.
3. In Intune device timeline/troubleshooting pane:
   - No recurrence of 0x80180014 for the new enrolment attempt.

### Success criteria [Device access required]
1. On device, Settings > Accounts > Access work or school shows the current, valid organizational connection.
2. dsregcmd /status confirms AzureAdJoined is Yes and state is healthy for the newly provisioned session.
3. Company Portal (if used) and policy sync function normally.

## Preventive Action for Fleet Recurrence

### Recommended control: pre-Autopilot legacy-enrolment gate [Admin Center only + process]
1. Create an operational preflight checklist for rebuild/redeployment devices:
   - Confirm no active legacy/manual MDM enrolment record exists before assigning/initiating Autopilot.
2. Add helpdesk/L2 step to retire/delete stale managed-device records before reprovisioning old devices into Autopilot.
3. Use dynamic device reporting/query in Intune to flag devices with historical legacy enrolment markers and stale check-in patterns.
4. Add a change-control rule: devices previously manually enrolled must pass cleanup gate before Autopilot profile assignment.
5. Publish a short runbook for service desk with decision tree: Legacy enrolment found -> cleanup -> reset -> Autopilot retry.

## Final Resolution Statement
The failure was caused by an existing legacy MDM enrolment conflict. Removing stale enrolment records (service-side and device-side), then reprovisioning and rerunning Autopilot in the defined sequence resolves the issue and restores normal policy application.
