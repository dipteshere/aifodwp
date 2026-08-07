# Root Cause Analysis (RCA) - Outlook Crash Incident (2024-03-15)

## Document Control
- Incident ID: APP-OUTLOOK-2024-03-15
- Incident Type: Repeated Outlook application crash (App crash sequence)
- Affected Device: Windows 11 endpoint (single machine in provided evidence)
- RCA Prepared By: DWP Analyst
- RCA Date: 2026-08-07
- Incident Date (from evidence): 2024-03-15

## Executive Summary
Between 09:14 and 09:18, the endpoint recorded repeated Outlook crashes with the same failure signature: OUTLOOK.EXE faulting in KERNELBASE.dll with exception code 0xc0000005 (access violation). Windows Error Reporting then logged an APPCRASH bucket, and .NET Runtime logged an unhandled System.AccessViolationException.

Based on the provided events, this is an application crash and restart pattern, not a user account lockout pattern. No lockout-related Security log evidence (for example account lockout events) is present in the supplied data.

## Scope and Impact
- Symptom: Outlook terminated unexpectedly multiple times within minutes.
- User impact: Email client instability and interruption of productivity.
- System scope: Outlook process on the affected machine during the 30-minute observation window.

## Event ID Explanation

### Event ID 1000 (Source: Application Error)
Records when an application crashes and includes crash signature details: faulting process, module, exception code, offset, paths, and report ID.

In this incident, Event 1000 shows:
- Faulting app: OUTLOOK.EXE
- Faulting module: KERNELBASE.dll
- Exception code: 0xc0000005 (access violation memory fault)
- Repeated identical signature at 09:14:22 and 09:17:45, indicating recurring deterministic failure path.

### Event ID 1001 (Source: Windows Error Reporting)
Records that Windows Error Reporting captured and bucketed the crash for telemetry and possible Watson analysis.

In this incident, Event 1001 shows:
- Event Name: APPCRASH
- Fault bucket ID generated
- Confirms OS crash reporting pipeline captured the failure immediately after Event 1000.

### Event ID 1026 (Source: .NET Runtime)
Records .NET runtime unhandled exception termination details for a managed or mixed-mode process.

In this incident, Event 1026 shows:
- Process terminated due to unhandled exception
- Exception type: System.AccessViolationException
- Corroborates the same memory access violation failure sequence seen in Event 1000.

## Timeline Reconstruction (Plain English)
1. Outlook started at 09:13:44.
2. At 09:14:22, Outlook crashed in KERNELBASE.dll with access violation 0xc0000005 (Event 1000).
3. Outlook was likely reopened (manually or automatically) and crashed again at 09:17:45 with the same signature (Event 1000).
4. At 09:18:01, Windows Error Reporting logged APPCRASH and generated a crash bucket (Event 1001).
5. At 09:18:05, .NET Runtime recorded unhandled System.AccessViolationException and process termination (Event 1026).

## Most Likely Cause and Evidence
Most likely cause: A recurring memory access violation in the Outlook execution path (likely add-in, profile interaction, or Office binary/runtime interaction) causing repeated process termination in KERNELBASE.dll.

Evidence from events:
- Repeated Event 1000 with identical app/module/exception signature indicates the same code path fails repeatedly.
- Exception 0xc0000005 is an access violation, consistent with invalid memory access.
- Event 1026 confirms unhandled AccessViolationException in the same process window.
- Event 1001 confirms APPCRASH telemetry was generated for this same failure chain.

Lockout assessment:
- The provided dataset does not contain account lockout evidence.
- No Security events associated with lockout are present in the supplied logs.
- Conclusion: this incident is best evidenced as an Outlook crash incident, not an account lockout incident.

## 5-Why Analysis

Problem Statement:
- Outlook repeatedly crashed on the endpoint during the incident window.

Why 1:
- Why did the user lose Outlook access?
- Because OUTLOOK.EXE terminated unexpectedly.
- Evidence: Application Error Event 1000 entries.

Why 2:
- Why did OUTLOOK.EXE terminate?
- Because it hit exception 0xc0000005 (access violation) in KERNELBASE.dll.
- Evidence: Event 1000 crash signature.

Why 3:
- Why was access violation triggered repeatedly?
- Because the same failure path was re-entered after restart, indicating persistent triggering condition.
- Evidence: Two Event 1000 crashes with same signature within ~3 minutes.

Why 4:
- Why was the triggering condition still present after relaunch?
- Because the underlying state/component was unchanged between launches (for example problematic add-in state, corrupted profile data path, or unstable Office runtime interaction).
- Evidence: No variation in fault signature; immediate recurrence pattern.

Why 5:
- Why did this progress to user-facing disruption?
- Because there was no immediate containment (for example safe-mode launch, add-in isolation, or Office quick repair) before repeated normal launches retriggered the fault.
- Evidence: Repeated crash sequence followed by WER and .NET termination record.

Root Cause:
- Recurrent access-violation crash path in Outlook runtime context (OUTLOOK.EXE/KERNELBASE.dll), with high confidence in crash mechanism and medium confidence in exact underlying trigger component due to limited log scope.

## Corrective and Preventive Actions
1. Run Outlook in safe mode and test stability to isolate add-in influence.
2. Disable all COM add-ins, re-enable one-by-one, and identify offending extension.
3. Create a fresh Outlook profile and compare behavior.
4. Perform Office Online Repair to refresh binaries.
5. Validate Office and Windows patch levels are aligned to supported baseline.
6. Capture and review Windows Error Reporting crash dumps for module stack confirmation.
7. Add monitoring alert for repeated Event 1000 on OUTLOOK.EXE with 0xc0000005.

## Verification Plan
- Verify no new Event 1000 for OUTLOOK.EXE for at least one business day.
- Verify normal Outlook launch, send/receive, and mailbox switch operations.
- Verify no recurring Event 1026 AccessViolationException for OUTLOOK.EXE.

## Residual Risks
- If root trigger is third-party add-in dependent on specific user workflow, recurrence may occur when feature path is revisited.
- If no dump-level analysis is completed, exact trigger component remains inferential.

## Evidence References
- Source events provided in incident prompt (Application log window).
- Related workspace context: day2/triage_T1001_bitlocker_recovery.md (lockout-style analysis example) and day4 RCA structure examples.
