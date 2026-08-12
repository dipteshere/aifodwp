# L2/L3 Knowledge Base - Autopilot Enrollment Failure 0x80180014 (Legacy MDM Conflict)

## Background
Windows Autopilot enrollment requires a clean device enrollment state. If a device retains a prior manual/legacy MDM enrollment, Autopilot may fail before policy and compliance stages complete.

Why this matters:
- Enrollment failure blocks managed onboarding and security baseline deployment.
- Downstream compliance cannot evaluate until enrollment is complete.
- Repeated retries without cleanup can prolong outage and increase ticket volume.

## Symptom
What the user reports:
- Device setup fails during company enrollment.
- Repeated enrollment retries do not complete.

What the engineer observes:
- EnrollmentState = Failed.
- ErrorCode = 0x80180014.
- ErrorDescription = "The device is already enrolled in MDM."
- ProfilesApplied = 0 of 4, LastError = 0x80070005.
- ComplianceEngine reports enrollment not complete.

## Root Cause
Specific technical cause:
- Existing legacy manual MDM enrollment state conflicts with Autopilot enrollment transaction.

Evidence that confirms root cause:
- EnrollmentStatus: Failed, 0x80180014, explicit duplicate-enrollment message.
- DeviceInfo: MDMEnrolled Yes with legacy/manual source and prior enrollment date.
- PolicyManager: 0 profiles applied from 4 attempted.
- ComplianceEngine: could not evaluate because enrollment not complete.

Non-causal controls validated in this pattern:
- AzureADJoined = Yes.
- Intune and Autopilot licenses present.
- Required Microsoft endpoints reachable and no proxy issue.

## Detection
Goal: confirm this issue signature in under 5 minutes.

### Step D1 - Collect MDM diagnostic export
Required artifact:
- Export containing EnrollmentStatus, DeviceInfo, PolicyManager, ComplianceEngine, NetworkCheck, and Licensing sections.

### Step D2 - Confirm primary enrollment error signature
Required values:
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription contains: "already enrolled in MDM"

### Step D3 - Confirm existing enrollment conflict state
Required values:
- MDMEnrolled: Yes
- EnrollmentSource indicates legacy/manual enrollment (or prior enrollment timestamp)

### Step D4 - Confirm downstream failure chain
Required values:
- ProfilesAttempted > 0 and ProfilesApplied = 0
- ComplianceEngine reason indicates enrollment incomplete

### Step D5 - Exclude common prerequisites as root cause
Required values:
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Endpoint reachability to Microsoft enrollment URLs: OK
- ProxyDetected: No

Detection confirmation criteria:
- Confirm this KB issue only when D2, D3, and D4 are true.
- D5 strengthens confidence that conflict state, not licensing/network, is causal.

## Resolution
Target completion: 20 to 45 minutes depending on cleanup propagation.

### Step R1 - Service-side record hygiene
Actions:
- In Intune admin center, identify and retire/delete stale managed device record(s) tied to legacy enrollment.
- In Entra admin center, verify device object consistency and remove duplicate stale objects when governed by policy.

Expected result:
- No conflicting legacy enrollment record remains active for target device.

### Step R2 - Device-side unenrollment cleanup
Actions:
- Remove legacy work/school account enrollment bindings from the endpoint.
- Ensure no old MDM enrollment artifacts remain before reset/retry.

Expected result:
- Endpoint is ready for clean Autopilot enrollment path.

### Step R3 - Reset and rerun Autopilot
Actions:
- Reset device to OOBE per endpoint operations standard.
- Re-run Autopilot enrollment with assigned profile.

Expected result:
- Enrollment progresses beyond prior failure point.

### Step R4 - Validate policy and compliance progression
Actions:
- Confirm profile deployment progresses (not 0 of N).
- Confirm compliance evaluation completes.

Expected result:
- Device reaches managed, compliant state.

## Verification
Pass all checks before closure:
- EnrollmentState is Succeeded.
- 0x80180014 does not recur.
- Policy profile application shows success progression.
- Compliance evaluation completes successfully.
- Intune check-in and management state are healthy.

## Escalation and Evidence Pack
Escalate when any condition is true:
- 0x80180014 persists after full cleanup and OOBE retry.
- Enrollment state remains failed with no legacy records visible.
- New blocking error replaces 0x80180014.

Attach in escalation:
- Latest MDM diagnostic export.
- Timeline of cleanup actions and timestamps.
- Device object IDs and actions taken (Intune/Entra).
- Screenshots of enrollment error and post-retry state.

## Preventive Controls
1. Enforce preflight check to block Autopilot on already-enrolled devices.
2. Add runbook checkpoint requiring evidence of legacy-state cleanup.
3. Schedule proactive reporting for Autopilot-assigned devices with legacy enrollment indicators.
4. Add change/CAB checklist item for reprovisioning quality gate.