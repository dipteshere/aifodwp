# Analysis - FinBridge VDI Session Launch Failure (Pool-02)

## Document Control
- Incident: FinBridge VDI session launch failure
- Affected pool: FinBridge-VDI-Pool-02
- Unaffected pool: FinBridge-VDI-Pool-01
- Analysis date: 2026-08-14
- Evidence date in logs: 2024-03-15
- Analyst role: DWP Analyst

## Scope Facts (from provided evidence only)
- Affected users: 22 of 30 users on FinBridge-VDI-Pool-02.
- Unaffected pool: FinBridge-VDI-Pool-01 (same site).
- Broker errors captured:
  - "Timeout waiting for machine registration response (30000ms exceeded)"
  - "Session launch FAILED: error 1030 'No machines available in the desktop group'"
- Catalog state:
  - Pool-02: 25 provisioned, 3 registered, 22 unregistered, maintenance mode 0.
  - Pool-01: 20 provisioned, 19 registered, 1 unregistered.
- Unregistered sample machines in Pool-02:
  - Registration attempts failed with "Unable to contact Delivery Controller"
  - Endpoint shown: dc-vdi-02.finbridge.local:80 - connection refused.
- Delivery Controller health:
  - dc-vdi-02: Citrix Broker Service STOPPED; last known running yesterday 23:40; Windows Update installed today 00:15; reboot required flag set; host not rebooted.
  - dc-vdi-01 (serves Pool-01): Citrix Broker Service RUNNING; uptime 14 days.

## Ranked Likely Causes (Most probable first)

### 1) Delivery Controller service outage on dc-vdi-02 (most likely)
Why it fits the evidence:
- Pool-02 has mass unregistration (22 unregistered of 25) while Pool-01 remains mostly healthy (19/20 registered).
- Sample registration failures explicitly show connection refused to dc-vdi-02:80.
- Broker log shows registration-response timeout then no machines available.
- Controller health explicitly shows Citrix Broker Service STOPPED on dc-vdi-02.

Fastest check to confirm or eliminate:
1. On dc-vdi-02, check Citrix Broker Service state and startup mode.
2. From one Pool-02 VDI, test TCP connectivity to dc-vdi-02 on port 80.
3. Check whether Pool-02 registration count rises immediately after service recovery.

Specific remediation if confirmed:
1. Start Citrix Broker Service on dc-vdi-02 and set startup type to Automatic.
2. If service start is blocked/unstable and reboot-required is set, perform controlled reboot of dc-vdi-02.
3. After controller recovery, force/retry registration cycle on unregistered Pool-02 VDIs as needed.
4. Monitor Pool-02 until registered count normalizes and launches succeed.

### 2) Pending Windows update on dc-vdi-02 left required reboot unperformed, leaving broker service unavailable
Why it fits the evidence:
- Logs show update installed at 00:15 with reboot required flag set and no reboot completed.
- Broker service currently STOPPED on the same controller.
- Timing aligns with later launch failures and widespread Pool-02 unregistration.

Fastest check to confirm or eliminate:
1. Review update history and reboot-pending markers on dc-vdi-02.
2. Reboot dc-vdi-02 in a controlled window and observe broker service post-boot status.
3. Confirm VDI registrations begin recovering after reboot.

Specific remediation if confirmed:
1. Execute controlled reboot of dc-vdi-02.
2. Validate Citrix Broker Service starts automatically and remains stable.
3. Re-check Pool-02 registration and launch success; remediate any stragglers.

### 3) Pool-02 controller affinity/dependency concentrated on dc-vdi-02, limiting failover to healthy dc-vdi-01
Why it fits the evidence:
- Pool-01 is healthy through dc-vdi-01 while Pool-02 appears tied to failures contacting dc-vdi-02.
- If Pool-02 registration/broker path is preferentially bound to dc-vdi-02, outage impact would be pool-specific.

Fastest check to confirm or eliminate:
1. Inspect controller assignment/registration settings for Pool-02 VDIs.
2. Verify whether Pool-02 machines are configured to use both controllers or primarily dc-vdi-02.
3. Test a forced registration path to dc-vdi-01 for a sample Pool-02 VDI.

Specific remediation if confirmed:
1. Correct controller list/affinity to include resilient multi-controller registration.
2. Apply policy/config consistency across all Pool-02 machines.
3. Re-register impacted machines and validate balanced broker operations.

## Error Code Handling Note
- Numeric code observed: 1030.
- Confirmed from provided log text only: this event is paired with "No machines available in the desktop group."
- No independent code-meaning expansion is asserted here beyond what the provided broker log already states.

## Finalized Single Hypothesis
Primary hypothesis selected:
- Service outage on dc-vdi-02 (Citrix Broker Service STOPPED), likely sustained by pending-reboot/update state, caused mass Pool-02 unregistration and broker launch failures.

## Exact Remediation Steps (for finalized hypothesis)
1. Contain impact:
- Announce degraded service for Pool-02 and pause non-essential launch retries.

2. Recover controller first (dc-vdi-02):
- Check service state and dependencies.
- Start Citrix Broker Service.
- If service does not remain healthy and reboot-pending is set, perform controlled reboot.
- Post-boot, verify service is RUNNING and startup type is Automatic.

3. Recover registrations:
- Trigger/allow VDA re-registration from Pool-02 machines.
- For persistent unregistered machines, restart Citrix Desktop Service (or machine reboot per runbook).

4. Restore service:
- Re-enable normal user launch flow.
- Closely monitor registration counts and launch success for at least one full business cycle.

## Correct Order of Operations
1. Validate and recover dc-vdi-02 broker service health.
2. Confirm controller endpoint reachability from Pool-02 VDIs.
3. Drive Pool-02 machine re-registration recovery.
4. Validate broker launch path end-to-end with user test sessions.
5. Return to BAU and monitor.

## Verification Checks After Remediation
- Controller checks:
  - dc-vdi-02 Citrix Broker Service is RUNNING and stable.
  - No ongoing connection-refused findings for dc-vdi-02:80 from Pool-02 VDIs.
- Catalog checks:
  - Pool-02 registered count rises from 3 toward expected operating baseline.
  - Unregistered count declines materially from 22.
- User outcome checks:
  - Session launches in Pool-02 succeed with no 30000ms registration timeout.
  - No new "No machines available in the desktop group" launch failures in validation window.

## Preventive Action (to stop recurrence)
1. Implement controller-service watchdog/alerting:
- Alert immediately if Citrix Broker Service stops on any Delivery Controller.

2. Enforce patch-and-reboot governance:
- After Windows Update on controllers, require controlled reboot completion and post-reboot service validation checklist before business hours.

3. Strengthen failover posture:
- Periodically test Pool-to-controller resiliency so a single controller outage does not create pool-specific launch failure.

4. Add operational guardrails:
- Daily pre-business synthetic health check: controller service state, controller port reachability, and pool registration thresholds.

## Evidence Used
- Citrix Session Broker log excerpt (timestamps around 08:58).
- Machine catalog registration snapshots for Pool-02 and Pool-01.
- Unregistered machine samples referencing dc-vdi-02 connection refused.
- Delivery Controller health snapshots for dc-vdi-02 and dc-vdi-01.
