# Analysis - Legal Win11 App Crash Wave (DocManager v2.1)

## Document Control
- Incident: Legal app crash wave after morning deployment
- Affected device group: Legal-Win11
- Device count in scope: 45
- Analysis date: 2026-08-14
- Evidence date in telemetry/logs: 2024-03-25
- Analyst role: DWP Analyst

## Scope Facts (from provided evidence only)
- Nexthink DEX trend for Legal-Win11:
  - 08:00: DEX 91, app crash rate 0.1%, disk I/O Normal
  - 09:00: DEX 90, app crash rate 0.2%, disk I/O Normal
  - 10:00: DEX 58, app crash rate 6.2%, disk I/O High
  - 11:00: DEX 55, app crash rate 6.8%, disk I/O High
- Top crashing process from 10:00 to 11:00: DocManager.exe (74% of crashes in that window).
- SCCM deployment record:
  - 09:38:20 deployment started for Legal Document Manager v2.1 to Legal-Win11 (45 devices).
  - 09:44:07 install completed on 45 of 45 devices.
  - Result: success, 0 failures.
- Change context:
  - Previous version v2.0 had been stable for 6 weeks.
  - New version v2.1 introduces auto-save and includes a vendor-known limitation.
- Vendor known limitation for v2.1:
  - On devices with under 8GB RAM, initial auto-save indexing can drive high disk I/O and intermittent crashes during first few hours post-install.
- Fleet memory split in Legal-Win11:
  - 60% at 8GB RAM.
  - 40% at 4GB RAM.

## Why Both Data Sources Are Required
- Nexthink alone shows what changed operationally (sharp crash and disk I/O degradation), but not what changed in the environment.
- SCCM alone shows a successful, complete rollout, but not user experience regression after rollout.
- Combined, they establish a strong time-linked pattern: full deployment at 09:44 followed by steep crash and I/O deterioration from 10:00 onward.

## Hypotheses (Ranked)

### 1) Most likely: v2.1 post-install indexing behavior triggered instability on lower-memory devices
Why it fits:
1. Timing aligns: crash and I/O spike starts shortly after 09:44 completion.
2. Process concentration aligns: DocManager.exe is 74% of crashes in the impacted window.
3. Symptom profile aligns with vendor note: high disk I/O plus intermittent crashes in first hours.
4. Fleet composition increases risk exposure: 40% of devices are 4GB RAM.

Quick checks to confirm:
1. Segment crashes by RAM tier (4GB vs 8GB) from 10:00 onward.
2. Check whether crash rate declines after indexing window passes.
3. Review DocManager client logs for autosave/indexing exceptions on 4GB devices.

### 2) Plausible: rollout succeeded technically, but introduced a performance regression not captured by install success criteria
Why it fits:
1. SCCM success indicates package delivery/install success, not runtime quality.
2. DEX and crash metrics degraded significantly after deployment despite zero install failures.
3. Previous version (v2.0) baseline was stable for 6 weeks.

Quick checks to confirm:
1. Compare runtime stability between v2.1 and a controlled v2.0 cohort.
2. Validate whether any install-time custom actions changed system load behavior post-login.
3. Measure app launch and save-path performance before/after rollback on sample devices.

### 3) Alternative contributor: morning workload plus background indexing amplified disk contention and crash frequency
Why it fits:
1. Degradation appears in working hours (10:00 to 11:00) when user activity is rising.
2. Vendor note references first-hours indexing, which can overlap with active use.
3. High disk I/O and crash growth from 6.2% to 6.8% suggest sustained load, not a single transient event.

Quick checks to confirm:
1. Correlate crash bursts with user activity peaks and autosave/indexing timestamps.
2. Compare impact on lightly used devices vs heavily used devices during the same window.
3. Check for signs of disk queue saturation during DocManager indexing phases.

## Preliminary Conclusion
The evidence most strongly supports a post-deployment runtime regression tied to DocManager v2.1 indexing behavior, with disproportionate impact expected on 4GB devices. SCCM confirms deployment completeness, while Nexthink confirms immediate user-experience degradation and identifies the dominant crashing process.

## Recommended Next Actions
1. Contain: pause further v2.1 expansion beyond current Legal scope.
2. Mitigate: prioritize temporary rollback or feature-disable path for affected subset (starting with 4GB RAM devices).
3. Validate: monitor DEX, crash rate, and disk I/O for 2 to 4 hours after mitigation.
4. Confirm with vendor: request patch/config guidance for low-memory environments and safe re-rollout criteria.
5. Communicate: issue a plain-language user update confirming data/access safety and expected next steps.

## Evidence Used
- Nexthink DEX export for Legal-Win11 (08:00 to 11:00 on 2024-03-25).
- SCCM deployment log for Legal Document Manager v2.1 (09:38 to 09:44 on 2024-03-25).
- Vendor release note excerpt for v2.1 known limitation.
- Fleet hardware distribution summary for Legal-Win11.
