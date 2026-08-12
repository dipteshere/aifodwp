# RCA — Adobe Acrobat Pro v23.6 Intune Install Failure (1603)

Incident date: 2024-03-15  
RCA date: 2026-08-12  
Service: Endpoint Application Deployment (Intune Win32)  
Application: Adobe Acrobat Pro v23.6

## 1. Incident Summary

A required Intune Win32 deployment of Adobe Acrobat Pro v23.6 failed on targeted Win11 endpoints. The installer returned code 1603 on initial attempt and on retry 60 minutes later. Detection then reported Not detected, resulting in continued retry scheduling and no successful install state for affected devices.

## 2. Business Impact

- Users did not receive Adobe Acrobat Pro v23.6 as scheduled.
- Intune generated repeated retry attempts, increasing endpoint and support noise.
- Service desk demand increased due to failed required install posture.
- Risk of large-scale deployment disruption if unchanged configuration was expanded.

## 3. Technical Timeline (UTC-local as logged)

- 10:01:00: Agent starts install for Adobe Acrobat Pro v23.6.
- 10:01:03: Command runs: msiexec /i AcrobatPro.msi /quiet.
- 10:01:44: Return code 1603.
- 10:01:45: Detection runs against HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0.
- 10:01:46: Detection = Not detected.
- 10:01:47: Result marked Failed; retry in 60 minutes.
- 11:01:48: Retry uses same command.
- 11:02:31: Return code 1603 again; retry fails.

## 4. Root Cause

Primary root cause:
- Deployment configuration used an incomplete/incorrect installation method for the Acrobat Pro package (direct MSI invocation without verified vendor-required deployment method), causing deterministic MSI fatal error 1603.

Contributing cause:
- Detection rule targeted Acrobat Reader registry path (HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0) rather than a validated Acrobat Pro v23.6 marker, creating potential false-negative detection behavior and retry loops even when partial install artifacts exist.

## 5. Why It Happened

- Packaging and install command were promoted without sufficient vendor-method validation for this specific Acrobat Pro build.
- Detection rule design reused a product-family key pattern (Reader) that did not match the deployed Pro application identity.
- No mandatory pre-production gate requiring:
  - verbose MSI log validation,
  - detection proof on known-good reference machine,
  - conflict/pending reboot pre-check outcomes.

## 6. Corrective Actions Implemented

- Rebuilt app revision using vendor-aligned installation method with verbose logging.
- Updated install command to silent, non-restart, logged execution.
- Replaced detection rule with Pro-specific validated marker and version check.
- Added pre-check controls for pending reboot and known Adobe conflict conditions.
- Piloted revised deployment in a constrained cohort before broader reassignment.

## 7. Preventive Actions (Permanent Controls)

1. Packaging standard update:
- All Win32 MSI-based deployments must include verbose logging path during pilot phase.

2. Detection standard update:
- Detection rule must be validated on a known-good endpoint and tied to product-correct identity (no cross-family key reuse).

3. Change gate update:
- CAB readiness checklist now requires:
  - command-line validation evidence,
  - detection validation evidence,
  - rollback group mapping,
  - pilot success metrics.

4. Monitoring update:
- Automated alert when any required app shows >=5% failure in rolling 6-hour window or repeated same exit code pattern.

## 8. Recovery and Rollback Posture

- Immediate containment action for recurrence:
  - Remove failing app revision from Required assignment for impacted groups.
- Rollback route:
  - Assign previous known-stable Acrobat package revision as Required until corrected build is proven.
- Decision authority:
  - DWP Endpoint Lead + EUC Service Owner within defined incident response window.

## 9. Lessons Learned

- MSI 1603 without verbose logging materially delays diagnosis.
- Detection mismatches can mask real install state and create avoidable retry churn.
- Adobe product-line deployments must follow explicit vendor enterprise packaging guidance, not generic MSI assumptions.

## 10. Evidence Used

- Intune deployment log excerpt with repeated 1603 on initial and retry attempts.
- Detection output showing Reader key lookup and Not detected status.
- Repeated retry schedule behavior indicating unresolved deterministic failure.

## 11. Final RCA Statement

The incident was caused by deployment misconfiguration: an invalid/incomplete Acrobat Pro installation command path produced deterministic MSI 1603 failures, and a mismatched Reader-based detection rule increased failure persistence through repeated retries. The issue was resolved by repackaging with vendor-aligned installation logic, correcting detection to Pro-specific markers, and enforcing stricter pilot and change gates.
