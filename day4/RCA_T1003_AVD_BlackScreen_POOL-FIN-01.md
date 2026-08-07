# Root Cause Analysis (RCA) - T-1003 AVD Black Screen Incident (POOL-FIN-01)

## Document Control
- Incident ID: T-1003
- Incident Type: AVD post-login black screen and session disconnect behavior
- Affected Pool: POOL-FIN-01
- Unaffected Pool: POOL-FIN-02
- RCA Prepared By: DWWP Engineer
- RCA Date: 2026-08-06
- Incident Date (from evidence): 2024-03-15

## Executive Summary
At approximately 07:00, users on POOL-FIN-01 began experiencing post-login black screen behavior. For some users, sessions recovered after about 30 seconds; for others, the issue persisted and/or sessions disconnected and reconnected. POOL-FIN-02 remained unaffected.

Evidence from affected host SHFIN-01-A shows repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll immediately after successful session logon, followed by DWM exits and session disconnects. This pattern began after the overnight POOL-FIN-01 image update and did not appear on comparison host SHFIN-02-A (pre-update image).

The agreed remediation path was applied, and the incident was confirmed resolved at 10:00 AM. Users were verified logging in to POOL-FIN-01 hosts with no further issues reported.

## Scope and Impact
- Symptom: Blank screen after login; self-clears for some users after ~30 seconds, persists for others.
- User impact: Approximately 40 percent of users on POOL-FIN-01.
- Pool scope: POOL-FIN-01 affected; POOL-FIN-02 unaffected.
- Business effect: Access disruption and productivity loss due to delayed or unstable session startup.

## Supporting Evidence

### Change and timing correlation
- Overnight image update was performed on POOL-FIN-01 at 02:00.
- POOL-FIN-02 was not updated.
- Incident symptoms began around 07:00.

### Affected host evidence (SHFIN-01-A, 07:00 to 07:30)
- 07:02:10 - LSM Event 21: Session logon succeeded (FINBRIDGE\\mlopez).
- 07:02:14 - Kernel-General Event 1: Host boot time 02:03:11, indicating post-update restart.
- 07:02:16 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - LSM Event 40: Session disconnected.
- 07:02:18 - DWM Event 9009: Desktop Window Manager exited.
- 07:02:44 - LSM Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Application Error Event 1000: repeat dwm.exe fault in igdumd64.dll.
- 07:02:47 - LSM Event 40: Session disconnected again.
- 07:03:01 - DWM Event 9009: DWM exited again.
- 07:03:10 - LSM Event 21: Session logon succeeded (second reconnect).
- 07:08:24 - Application Error Event 1000: same fault signature for another user.

### Unaffected comparison evidence (SHFIN-02-A, POOL-FIN-02, pre-update image)
- 07:01:44 - LSM Event 21: Session logon succeeded.
- 07:01:46 - DWM Event 9011: Desktop Window Manager started successfully.
- No Application Error Event 1000 in same window.

## Timeline
1. 02:00 - Overnight image update applied to POOL-FIN-01.
2. 02:03 - SHFIN-01-A post-update boot recorded (Kernel-General Event 1).
3. ~07:00 - User impact starts: post-login black screen on POOL-FIN-01.
4. 07:02 to 07:08 - Repeated crash chain observed on SHFIN-01-A:
   - Event 21 (logon success) -> Event 1000 (dwm.exe crash in igdumd64.dll) -> Event 9009 (DWM exit) -> Event 40 (disconnect).
5. Incident window - POOL-FIN-02 remains stable with successful DWM startup and no matching crash events.
6. Remediation window - Agreed corrective actions from incident analysis were applied to POOL-FIN-01.
7. 10:00 - Service verified restored: users logging into POOL-FIN-01 with no further issues reported.

## Hypothesis Review and Elimination

1. Image-level regression on POOL-FIN-01
- Status: Supported.
- Evidence: Post-update boot on affected host plus repeated crash signatures only in updated pool path.

2. Generic startup delay (shell or GPO or AppReadiness)
- Status: Contradicted.
- Evidence: Immediate crash-disconnect sequence after successful logon, rather than delay-only pattern.

3. FSLogix or profile attach problem
- Status: Neutral.
- Evidence: No FSLogix-specific telemetry included in provided event set.

4. Intra-pool host subset mismatch within POOL-FIN-01
- Status: Neutral.
- Evidence: Available comparison proves cross-pool difference; does not fully prove or disprove internal drift without broader host sample.

5. Graphics or display pipeline regression
- Status: Strongly supported.
- Evidence: Repeated Event 1000 for dwm.exe faulting igdumd64.dll, paired with DWM exit events and immediate session disconnects.

## Most Probable Root Cause
A graphics/display pipeline regression was introduced through the overnight POOL-FIN-01 image update, causing dwm.exe to crash in Intel graphics module igdumd64.dll during session initialization. This created black-screen and disconnect behavior immediately after successful logon.

## 5-Why Analysis

Problem Statement:
- Users on POOL-FIN-01 experienced post-login black screen and unstable session start.

Why 1:
- Why did users see black screens and disconnect loops?
- Because Desktop Window Manager crashed during session startup.
- Evidence: Event 1000 and Event 9009 on SHFIN-01-A after logon events.

Why 2:
- Why did Desktop Window Manager crash?
- Because dwm.exe faulted in igdumd64.dll with access violation 0xc0000005.
- Evidence: Application Error Event 1000 details at 07:02:16 and 07:02:46.

Why 3:
- Why was this fault path active in the affected environment?
- Because the affected pool had a new overnight image baseline and restarted hosts afterwards.
- Evidence: Kernel-General Event 1 post-update timing; unaffected pool remained on pre-update image and did not show the crash signature.

Why 4:
- Why did this reach production users?
- Because the updated image was promoted to a production pool without a sufficient graphics-path soak gate that would have caught DWM/driver instability.
- Evidence: Crash signature manifested in live user sessions shortly after business start.

Why 5:
- Why was there user impact before prevention controls blocked rollout?
- Because release governance lacked an automated hard stop tied to known critical display stability event signatures.
- Evidence: Production exposure occurred until remediation and verification completed.

Root Cause:
- Image-introduced graphics stack instability in POOL-FIN-01, expressed as dwm.exe crashes in igdumd64.dll during user logon initialization.

## Resolution Applied and Verification

### Resolution applied
- The agreed remediation plan from incident analysis was executed on POOL-FIN-01 hosts (containment, corrective host/image actions, and controlled validation).

### Recovery confirmation
- Time resolved: 10:00 AM.
- Verification outcome: Users successfully logged into POOL-FIN-01 hosts and no issues were reported after remediation.

### Post-fix verification checklist
- Confirmed absence of new critical symptom reports from affected user cohort.
- Confirmed successful logon behavior restored on POOL-FIN-01.
- Confirmed service stability after remediation window (as reported).

## Preventive Actions
1. Introduce image promotion gates for AVD with graphics stability soak tests before production rollout.
2. Add automated block conditions when these signatures appear in validation ring:
   - Application Error Event 1000 with dwm.exe and igdumd64.dll.
   - Desktop Window Manager Event 9009.
   - Repeated Event 21 to Event 40 loops during sign-in.
3. Maintain a tested rollback runbook for each host pool image release.
4. Roll out updates in rings (pilot subset -> broader deployment) with explicit hold points.
5. Capture and compare event telemetry between updated and control pools during first business-hour burn-in.
6. Document approved graphics driver baseline and enforce version pinning in image pipeline.
7. Add proactive alerting for black-screen precursor events to reduce time to detect.

## Residual Risks and Follow-Up
- Residual risk: Similar regressions can recur if future image updates bypass validation gates.
- Follow-up: Review image pipeline controls and implement policy enforcement before next production image cycle.
- Follow-up owner: DWWP Engineering and EUC Platform Operations.

## Evidence References
- Incident analysis addendum: day4/triage_T1003_avd_disconnect.md
- Affected host evidence source: SHFIN-01-A Application and System logs (07:00 to 07:30 window)
- Comparison host evidence source: SHFIN-02-A Application and System logs (same window)
