# Version Header
- Document: Process Change - Friday Release Gate for Floor 6
- Version: 1.0
- Date: 2026-08-14
- Control ID: FRG-F6-01

# One Specific Process Change
Implement a mandatory control named: Floor 6 Monday Readiness Gate.

Definition:
Any app rollout to Floor 6 after 12:00 on Friday must remain in pilot state until the gate passes at 06:30 Monday. If the gate fails, automatic rollback is executed before 08:00.

# Why This Would Have Caught It
The incident pattern included login delay/failure, desktop inconsistency, and possible access-scope concern after a Friday deployment. This gate checks those exact failure signals before business users start work Monday morning.

# Control Design
## Trigger
- A change targets Floor 6 and is deployed on Friday after 12:00.

## Owner
- Change Manager owns gate decision.
- Endpoint Engineer runs technical checks.
- Service Desk Manager confirms user experience checks.

## Gate Inputs (must all pass)
1. Sentinel device logon check:
- Minimum 5 pre-selected Floor 6 sentinel devices.
- Each device must complete sign-in within baseline threshold (to confirm exact threshold).

2. Event signal check:
- No abnormal spike in failed logons since deployment window (to confirm threshold).
- No abnormal spike in profile or startup delay events since deployment window (to confirm threshold).

3. Desktop usability check:
- Required shortcut set present on all sentinel devices.

4. Access-scope sanity check:
- One scripted canary query against approved non-sensitive test matter only.
- No unexpected matter visibility result.

## Evidence Required
- Timestamped checklist signed by owner roles.
- Device-level output from evidence script.
- Event count summary and pass/fail decision record.

# Pass/Fail Rule
- Pass: All four gate inputs pass.
- Fail: Any single input fails.

# Automatic Outcome
- On fail, execute containment before 08:00 Monday:
1. Remove impacted devices from deployment ring.
2. Apply approved uninstall or rollback assignment.
3. Publish plain-language user update.

# Change Management Integration
- Add FRG-F6-01 as a required CAB checklist item for all Friday Floor 6 releases.
- Change ticket cannot move to Complete until gate evidence is attached.

# Success Metric
- Zero Monday-start high-severity Floor 6 incidents caused by Friday post-noon app rollouts for 90 days (to confirm review period).
