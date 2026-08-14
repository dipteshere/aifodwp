# Root Cause Analysis (RCA) - Legal Win11 DocManager Crash Wave

## Document Control
- Incident: Legal app crash wave after DocManager v2.1 deployment
- Affected group: Legal-Win11
- Devices in scope: 45
- RCA prepared by: DWP Analyst
- RCA date: 2026-08-14
- Incident evidence date: 2024-03-25

## Executive Summary
Legal users experienced a sharp increase in application crashes during the morning after a successful deployment of Legal Document Manager v2.1 to all 45 devices. Nexthink shows stable conditions at 08:00 and 09:00, followed by a steep DEX drop and high crash/high disk I/O state at 10:00 and 11:00. The dominant crashing process was DocManager.exe (74% of crashes from 10:00 to 11:00).

SCCM confirms complete and successful installation (45/45, 0 failures) at 09:44, while vendor notes for v2.1 document a known limitation: first-hours auto-save indexing can cause high disk I/O and intermittent crashes on devices under 8GB RAM. With 40% of the fleet at 4GB RAM, the evidence supports a post-deployment runtime regression in v2.1 indexing behavior, amplified on lower-memory devices.

## Incident Scope and Impact
- User/service impact: wave of app crashes across Legal-Win11 devices during business hours.
- Technical impact indicators:
  - DEX score dropped from 90 (09:00) to 58 (10:00), then 55 (11:00).
  - App crash rate rose from 0.2% (09:00) to 6.2% (10:00), then 6.8% (11:00).
  - Disk I/O moved from Normal to High at 10:00 and remained High at 11:00.
- Process concentration: DocManager.exe represented 74% of crash events in the peak window.

## Supporting Evidence

### Nexthink DEX telemetry
- 08:00: DEX 91, crash rate 0.1%, disk I/O Normal.
- 09:00: DEX 90, crash rate 0.2%, disk I/O Normal.
- 10:00: DEX 58, crash rate 6.2%, disk I/O High.
- 11:00: DEX 55, crash rate 6.8%, disk I/O High.

### SCCM deployment evidence
- 09:38:20: Deployment started for Legal Document Manager v2.1 to Legal-Win11.
- 09:44:07: Install completed 45 of 45 devices.
- Result: success, 0 failures.

### Change and platform context
- Prior version: v2.0 stable for 6 weeks.
- New version: v2.1 introduces auto-save feature.
- Vendor known limitation: under-8GB devices may see high disk I/O and intermittent crashes during initial indexing hours.
- Fleet hardware profile: 60% at 8GB, 40% at 4GB.

## Timeline (from provided evidence)
1. 08:00 to 09:00: baseline healthy state (high DEX, low crash rate, normal disk I/O).
2. 09:38:20: v2.1 deployment begins to Legal-Win11.
3. 09:44:07: deployment completes successfully on all 45 devices.
4. 10:00: first measured degradation window begins (DEX down, crash rate up, disk I/O high).
5. 10:00 to 11:00: DocManager.exe accounts for 74% of crashes.
6. 11:00: elevated crash and high I/O state persists.

## Hypothesis Evaluation (Ranked)

### Hypothesis 1 (Selected): v2.1 initial indexing behavior caused runtime instability, with stronger impact on lower-memory devices
- Confidence: High.
- Why it fits:
  - Tight temporal correlation between deployment completion and degradation onset.
  - Crash concentration in the newly updated app process.
  - Symptom match with vendor-known limitation (high disk I/O plus intermittent crashes).
  - Fleet includes a large at-risk segment (4GB devices).

### Hypothesis 2: Deployment quality passed install checks but introduced runtime regression not represented by SCCM success metrics
- Confidence: Medium-High.
- Why it fits:
  - SCCM validates installation completion, not sustained runtime stability.
  - DEX/runtime indicators deteriorated materially post-install despite zero failures.

### Hypothesis 3: Concurrent morning user load amplified crash frequency during background indexing
- Confidence: Medium.
- Why it fits:
  - Impact appears in active business window.
  - High I/O persisted across consecutive hourly snapshots, consistent with sustained contention.

## Final Root Cause Statement
The incident was caused by a post-deployment runtime regression in Legal Document Manager v2.1, where first-hours auto-save indexing generated high disk I/O and triggered intermittent app crashes, with disproportionate susceptibility on lower-memory (4GB) devices in the Legal-Win11 fleet.

## Corrective Remediation (Exact Steps and Order)

### Order of operations
1. Contain deployment exposure.
2. Stabilize affected user experience.
3. Validate improvement with telemetry.
4. Coordinate vendor-backed fix criteria.
5. Resume rollout only after controlled proof.

### Exact remediation steps
1. Containment:
- Pause further v2.1 rollout beyond current Legal scope.

2. Targeted mitigation:
- Prioritize rollback or feature-disable path for impacted subset, starting with 4GB devices.
- Keep 8GB subset under observation if not symptomatic.

3. Validation monitoring:
- Track DEX score, app crash rate, and disk I/O for at least 2 to 4 hours post-change.
- Confirm DocManager.exe crash share drops from incident peak.

4. Vendor engagement:
- Request definitive remediation guidance for low-memory endpoints (patch, config, or staged indexing control).
- Define safe re-rollout entry criteria with vendor confirmation.

## Verification Checks (Post-Remediation)
- Stability metrics:
  - App crash rate returns toward pre-incident baseline.
  - Disk I/O returns from High to Normal profile in business hours.
  - DEX score materially recovers from incident trough.
- App-specific metrics:
  - DocManager.exe no longer dominates crash telemetry.
- User outcome:
  - No new Legal-wide crash wave in the subsequent business cycle.

## 5-Why Analysis

Problem statement:
- Legal users experienced a broad morning wave of app crashes.

Why 1:
- Why did users see many crashes?
- Because DocManager.exe crashed at high frequency during 10:00 to 11:00.

Why 2:
- Why did DocManager.exe crash at high frequency?
- Because the app entered a high disk I/O state during first-hours post-install activity.

Why 3:
- Why was disk I/O high in that period?
- Because v2.1 introduced auto-save indexing behavior that runs during initial hours.

Why 4:
- Why did this behavior cause broad user impact?
- Because a large portion of the fleet has lower memory (4GB), a known risk condition for this version behavior.

Why 5:
- Why was this not prevented before wide deployment?
- Because deployment success criteria focused on install completion and did not gate release on post-install runtime performance validation across hardware tiers.

Root cause from 5-Why chain:
- v2.1 indexing behavior plus insufficient performance gating by hardware profile before full-scope rollout.

## Preventive Actions
1. Add release gate requiring post-install runtime soak validation (crash rate, DEX, disk I/O) before full deployment.
2. Segment rollout by hardware tier; pilot low-memory cohorts first with explicit hold points.
3. Define automatic halt thresholds (for example, crash-rate or DEX drop triggers) in first-hours monitoring.
4. Require vendor known-limitations review as a formal pre-deployment checklist control.
5. Add rollback readiness criteria and communications template before production rollout starts.

## Residual Risk and Follow-Up
- Residual risk: Recurrence remains possible on low-memory devices if v2.1 is reintroduced without controls.
- Follow-up owner: Endpoint Engineering and EUC Operations.
- Follow-up due: Before next Legal fleet application release.

## Evidence Index
- Nexthink DEX export for Legal-Win11 (08:00 to 11:00, 2024-03-25).
- SCCM deployment log for Legal Document Manager v2.1 (09:38 to 09:44, 2024-03-25).
- Vendor release note excerpt for v2.1 known limitation.
- Fleet RAM distribution summary for Legal-Win11.
