# Root Cause Analysis (RCA) - Autopilot Enrollment Failure

## Document Control
- RCA ID: RCA-2024-03-15-AUTOPILOT-FB099
- Incident: Autopilot enrollment failure
- Affected device: DESKTOP-FB099
- Affected user: FINBRIDGE\\rthomas
- Incident date: 2024-03-15
- Diagnostic capture time: 2024-03-15 09:22
- RCA prepared date: 2026-08-11
- Status: Finalized

## Executive Summary
Autopilot enrollment failed because the endpoint already had an active legacy manual MDM enrollment from 2023-11-04. The enrollment engine returned 0x80180014 with explicit diagnostic text indicating the device was already enrolled in MDM. As a result, enrollment did not complete, and policy application also failed (0 of 4 applied, with last error 0x80070005 Access denied). Azure AD join, licensing, and network health were all positive in evidence and are not causal for this incident.

## Scope and Impact
- Impacted endpoint count in evidence: 1 device (DESKTOP-FB099).
- Impacted user in evidence: 1 user (FINBRIDGE\\rthomas).
- Impacted service: Windows Autopilot MDM enrollment and downstream policy application.
- Business impact: Device could not complete managed onboarding state during affected window.

## Supporting Evidence

### 1) Enrollment status evidence
- Source: EnrollmentStatus section.
- EnrollmentType: Autopilot.
- EnrollmentState: Failed.
- ErrorCode: 0x80180014.
- ErrorDescription: The device is already enrolled in MDM.
- Timestamp: 2024-03-15 09:18:44.

### 2) Existing enrollment evidence
- Source: DeviceInfo and top-level summary lines.
- MDMEnrolled: Yes (previous enrollment).
- Enrollment source: Legacy manual MDM enrollment.
- Historical date in summary: 2023-11-04.

### 3) Policy application evidence
- Source: PolicyManager section.
- ProfilesAttempted: 4.
- ProfilesApplied: 0.
- LastError: 0x80070005 (Access denied).
- FailedProfile: FinBridge-Win11-Security-Baseline.
- Timestamp: 2024-03-15 09:19:01.

### 4) Compliance engine evidence
- Source: ComplianceEngine section.
- EvaluationResult: Could not evaluate.
- Reason: Enrollment not complete.
- Timestamp: 2024-03-15 09:19:45.

### 5) Platform state evidence (non-causal controls)
- Source: DeviceInfo, Licensing, NetworkCheck sections.
- AzureADJoined: Yes.
- IntuneP1License: Yes.
- AutopilotLicense: Yes.
- M365LicenseFound: Yes.
- Endpoint reachability: login.microsoftonline.com OK, enrollment.manage.microsoft.com OK, enterpriseregistration.windows.net OK.
- ProxyDetected: No.

## Timeline Reconstruction

### Pre-existing condition
1. 2023-11-04 (from diagnostic summary): Device had legacy manual MDM enrollment established.

### Incident timeline (2024-03-15)
1. 09:18:44: Autopilot enrollment attempt fails with 0x80180014 and description "device is already enrolled in MDM".
2. 09:19:01: PolicyManager reports 0 of 4 profiles applied and last error 0x80070005 (Access denied).
3. 09:19:45: Compliance engine cannot evaluate because enrollment is not complete.
4. 09:22:00: MDM diagnostic export captured for investigation context.

## Root Cause Statement
Primary root cause: A pre-existing legacy manual MDM enrollment on DESKTOP-FB099 conflicted with the Autopilot enrollment flow, causing enrollment failure (0x80180014) and preventing downstream policy/compliance completion.

## 5-Why Analysis

Problem statement:
- Why did Autopilot enrollment fail for DESKTOP-FB099?

Why 1:
- Autopilot enrollment failed because EnrollmentState is Failed with 0x80180014.
- Evidence: EnrollmentStatus at 09:18:44.

Why 2:
- 0x80180014 in this case is explicitly accompanied by "The device is already enrolled in MDM."
- Evidence: EnrollmentStatus ErrorDescription.

Why 3:
- The device already had an existing MDM enrollment prior to this attempt.
- Evidence: MDMEnrolled Yes, EnrollmentSource Legacy manual MDM enrollment, prior date 2023-11-04.

Why 4:
- Because the stale legacy enrollment was still present at Autopilot runtime, the new enrollment could not complete as a clean enrollment path.
- Evidence: Direct coexistence of legacy enrollment state and failed Autopilot enrollment in same export.

Why 5:
- There was no completed pre-enrollment cleanup gate for previously manually enrolled devices before Autopilot reprovisioning.
- Evidence: Legacy enrollment remained active at time of Autopilot attempt.

5-Why conclusion:
- Root process failure is missing or not executed legacy-enrollment cleanup prior to Autopilot enrollment for a previously manually enrolled device.

## Corrective Actions Implemented (Resolution Plan)
1. Remove stale managed-device enrollment records in Intune for the legacy manual enrollment path.
2. Validate and deduplicate Autopilot device registration and Entra device objects where applicable.
3. Perform device-side unenrollment cleanup of legacy work account/enrollment artifacts.
4. Reset device to OOBE and rerun Autopilot enrollment.
5. Validate successful enrollment and profile application post-remediation.

## Verification Criteria for Successful Recovery
1. Intune shows current, active enrollment for DESKTOP-FB099 with recent check-in.
2. Enrollment failure 0x80180014 does not recur on retry.
3. Profile deployment no longer shows 0 of 4; targeted profiles progress to success.
4. Compliance evaluation proceeds normally after enrollment completion.

## Preventive Actions

### Preventive control 1: Legacy enrollment preflight gate
- Require explicit check for existing MDM enrollment records before assigning or rerunning Autopilot.
- Block Autopilot reprovision tasks until stale legacy records are retired/deleted.

### Preventive control 2: Service desk runbook standardization
- Publish a mandatory cleanup-before-Autopilot runbook for L1/L2/L3 with fixed sequence:
  Intune cleanup -> Entra object sanity check -> device-side unenroll -> reset -> Autopilot retry.

### Preventive control 3: Reporting and proactive detection
- Add scheduled reporting to detect devices with legacy manual enrollment signatures plus pending Autopilot assignment.
- Trigger an operational alert for cleanup action prior to deployment window.

### Preventive control 4: Change quality gate
- Add a CAB/change checklist item for reprovisioning projects: "Previously enrolled device cleanup completed and evidenced".

## Residual Risk
If legacy enrollment artifacts are not removed consistently across both service-side and device-side paths, future Autopilot attempts on redeployed devices may fail with the same pattern.

## Final Conclusion
The incident was caused by a confirmed enrollment conflict: existing legacy manual MDM enrollment on DESKTOP-FB099 blocked Autopilot enrollment completion. Supporting evidence is internally consistent across EnrollmentStatus, DeviceInfo, PolicyManager, and ComplianceEngine sections. Azure AD join, licensing, and network checks were healthy and are not root causes in this case.
