# Root Cause Analysis (RCA) - FinBridge VDI Pool-02 Session Launch Failure

## Document Control
- Incident: VDI session launch failures (Citrix)
- Affected pool: FinBridge-VDI-Pool-02
- Unaffected pool: FinBridge-VDI-Pool-01
- RCA prepared by: DWP Analyst
- RCA date: 2026-08-14
- Incident evidence date: 2024-03-15

## Executive Summary
Users in FinBridge-VDI-Pool-02 experienced major launch impact (22 of 30 users). Broker logs captured registration-response timeout followed by launch failure: error 1030 with message "No machines available in the desktop group." Pool-02 catalog showed only 3 of 25 machines registered (22 unregistered), while Pool-01 remained healthy (19 of 20 registered). Sample Pool-02 machine telemetry showed registration failures due to connection refused to dc-vdi-02.finbridge.local:80. Controller health confirmed Citrix Broker Service STOPPED on dc-vdi-02, while dc-vdi-01 remained RUNNING.

Based on the evidence set, the most probable root cause is broker-plane service unavailability on dc-vdi-02 (with pending reboot/update state as likely contributing context), leading to broad Pool-02 machine unregistration and launch failures.

## Incident Scope and Impact
- User impact: 22 of 30 users affected in Pool-02.
- Service impact: Session launch failures for Pool-02.
- Unaffected scope: Pool-01 within same site remained largely healthy.
- Business impact: Users unable to start VDI sessions in affected pool.

## Supporting Evidence

### Broker log evidence
- 08:58:34 - "Timeout waiting for machine registration response (30000ms exceeded)"
- 08:58:34 - "Session launch FAILED: error 1030 'No machines available in the desktop group'"

### Catalog health evidence
- Pool-02:
  - Provisioned: 25
  - Registered: 3
  - Unregistered: 22
  - Maintenance mode: 0
- Pool-01:
  - Provisioned: 20
  - Registered: 19
  - Unregistered: 1

### Unregistered machine samples (Pool-02)
- VDI-P02-014 and VDI-P02-017:
  - Last registration attempts failed.
  - Error: Unable to contact Delivery Controller.
  - Endpoint: dc-vdi-02.finbridge.local:80 - connection refused.

### Delivery Controller health
- dc-vdi-02:
  - Citrix Broker Service: STOPPED
  - Last known running: yesterday 23:40
  - Windows Update installed: today 00:15
  - Reboot required flag: set
  - Host reboot status: not rebooted
- dc-vdi-01:
  - Citrix Broker Service: RUNNING
  - Uptime: 14 days

## Timeline (from provided data)
1. 00:15 - Windows Update installed on dc-vdi-02; reboot required flag set.
2. 23:40 (previous day) - Last known running time of Citrix Broker Service on dc-vdi-02.
3. 06:15 to 06:16 - Pool-02 VDI samples fail registration attempts; connection refused to dc-vdi-02:80.
4. 08:58:03 - User session launch requested in Pool-02.
5. 08:58:04 - Broker queries available machines in Pool-02.
6. 08:58:34 - Broker timeout waiting for machine registration response (30000ms).
7. 08:58:34 - Launch failure recorded: error 1030, "No machines available in the desktop group."

## Hypothesis Evaluation (Ranked)

### Hypothesis 1 (Selected): dc-vdi-02 broker service outage caused Pool-02 unregistration and launch failure
- Confidence: High.
- Why it fits:
  - Direct service health evidence shows STOPPED broker service on impacted controller.
  - Registration errors explicitly target dc-vdi-02 with connection refused.
  - Pool-02 has severe registration collapse while Pool-01 remains healthy.

### Hypothesis 2: Pending reboot/update state on dc-vdi-02 contributed to broker unavailability
- Confidence: Medium.
- Why it fits:
  - Update installed with reboot required and no reboot completed.
  - Coexists with observed stopped broker service.

### Hypothesis 3: Pool-specific controller path/affinity prevented effective failover to dc-vdi-01
- Confidence: Medium-Low.
- Why it fits:
  - Pool-specific impact despite another healthy controller implies possible path/affinity asymmetry.
  - Not fully proven from supplied data alone.

## Final Root Cause Statement
The incident was caused by broker-plane availability loss on dc-vdi-02 (Citrix Broker Service STOPPED), which left most Pool-02 VDIs unregistered and resulted in broker launch timeout and "No machines available" failures for Pool-02 users.

Note on error code semantics:
- The dataset confirms error 1030 is emitted together with "No machines available in the desktop group."
- This RCA does not assert additional vendor-code interpretation beyond supplied evidence text.

## Corrective Remediation (Exact Steps and Order)

### Order of operations
1. Stabilize Delivery Controller dc-vdi-02.
2. Restore broker service availability.
3. Recover Pool-02 VDI registrations.
4. Validate session launches end-to-end.
5. Monitor and close.

### Exact remediation steps
1. Controller recovery
- On dc-vdi-02, check Citrix Broker Service status and startup configuration.
- Start Citrix Broker Service.
- If unstable or blocked and reboot-required remains set, execute controlled reboot.
- After boot, confirm Citrix Broker Service auto-started and is RUNNING.

2. Registration recovery
- Confirm Pool-02 VDI reachability to dc-vdi-02 on required broker endpoint.
- Trigger registration recovery for unregistered Pool-02 VDIs (service restart/reboot per platform runbook).
- Continue until registered count materially normalizes.

3. Service validation
- Run controlled test launches in Pool-02 with pilot users.
- Confirm no repeated registration timeout/no-machines broker failures.

## Verification Checks (Post-Remediation)
- Controller health:
  - dc-vdi-02 Citrix Broker Service RUNNING and stable.
  - dc-vdi-01 remains RUNNING.
- Registration health:
  - Pool-02 registered count significantly improved from 3 baseline.
  - Pool-02 unregistered count significantly reduced from 22 baseline.
- User experience:
  - Successful Pool-02 launches during validation window.
  - No recurrence of 30000ms registration timeout or error 1030 with "No machines available" during monitoring period.

## 5-Why Analysis

Problem statement:
- Pool-02 users could not launch VDI sessions at scale.

Why 1:
- Why did launches fail?
- Because broker processing timed out waiting for machine registration response and then reported no machines available.

Why 2:
- Why were no machines effectively available?
- Because most Pool-02 machines were unregistered (22 of 25).

Why 3:
- Why were Pool-02 machines unregistered?
- Because machines failed contacting Delivery Controller endpoint dc-vdi-02:80 (connection refused).

Why 4:
- Why was controller endpoint refusing connections?
- Because Citrix Broker Service on dc-vdi-02 was stopped.

Why 5:
- Why did service remain stopped into business impact window?
- Pending update/reboot state and lack of pre-business controller service assurance controls allowed degraded state to persist.

Root cause from 5-Why chain:
- Broker service outage state on dc-vdi-02, combined with insufficient operational guardrails to detect and recover before user demand.

## Preventive Actions
1. Add critical alerting for Citrix Broker Service state on all Delivery Controllers (stop/fail alerts with paging).
2. Enforce patch reboot completion policy for Delivery Controllers with mandatory post-reboot health validation before start of business.
3. Implement daily pre-shift synthetic health checks:
- Broker service status on all controllers.
- Controller endpoint connectivity from representative VDI hosts.
- Pool registration threshold compliance.
4. Validate pool-to-controller failover posture routinely so one controller loss cannot isolate a pool.
5. Maintain incident runbook for rapid controller recovery and VDI re-registration workflow.

## Residual Risk and Follow-Up
- Residual risk: Recurrence if updates leave controllers in non-healthy service state without automatic detection.
- Follow-up owner: EUC Platform / DWP Operations.
- Follow-up due: Before next controller patch cycle.

## Evidence Index
- Citrix Session Broker log excerpt (Pool-02 launch timeout and failure).
- Delivery Controller machine catalog status snapshot.
- Unregistered machine detail sample (Pool-02).
- Delivery Controller health snapshots for dc-vdi-02 and dc-vdi-01.
