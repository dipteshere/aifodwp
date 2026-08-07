# Title: T-1003 AVD Black Screen and Disconnect Runbook (POOL-FIN-01)
# Version: 1.0
# Date: 07/08/2026
# Author: Diptesh
# Reviewed: self
# Status: draft
# Change: initial version from RCA

## 1) Prerequisites

### Access Checklist
- [ ] [ELEVATED] Azure portal RBAC permission to manage AVD host pools and session hosts.
- [ ] [ELEVATED] Permission to set session host drain mode and allow new session.
- [ ] [ELEVATED] Permission to view and change host pool assignment/placement settings.
- [ ] [ELEVATED] Permission to roll back image baseline and reimage/replace session hosts.
- [ ] [ELEVATED] Permission to sign in to SHFIN-01-A and SHFIN-02-A and read Windows event logs.

### Tools Checklist
- [ ] Azure portal access.
- [ ] Remote desktop/admin access to SHFIN-01-A and SHFIN-02-A.
- [ ] Windows Event Viewer on each host.
- [ ] Incident work log template for timestamped actions.

### Mandatory End-User Information Checklist
- [ ] Affected username.
- [ ] Exact first-failure time.
- [ ] Host pool name reported by user (confirm POOL-FIN-01).
- [ ] Session host name shown to user at sign-in if available.
- [ ] Black-screen behavior type: self-clears after ~30 seconds or persists.
- [ ] Whether user observed disconnect/reconnect loop.

### Reference Values From RCA
- Affected pool: POOL-FIN-01.
- Unaffected comparison pool: POOL-FIN-02.
- Signature host example: SHFIN-01-A (affected), SHFIN-02-A (unaffected).
- Signature events: Event 1000 (dwm.exe faulting module igdumd64.dll, 0xc0000005), Event 9009, and Event 21 followed by Event 40.

## 2) Procedure
1. Open Azure portal and go to Azure Virtual Desktop > Host pools > POOL-FIN-01.
Expected result: POOL-FIN-01 overview page is open.

2. Record current UTC and local time in the incident work log.
Expected result: A timestamped start entry exists in the work log.

3. [ELEVATED] In POOL-FIN-01, open Session hosts and set each suspected host to Drain mode = On.
Expected result: Drained hosts show Drain mode enabled and stop taking new sessions.

4. [ELEVATED] In Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, confirm at least one healthy host has Allow new session = On.
Expected result: Unaffected capacity is available for new user logons.

5. [ELEVATED] Sign in to SHFIN-01-A and open Event Viewer.
Expected result: Event Viewer opens on SHFIN-01-A.

6. [ELEVATED] In Event Viewer on SHFIN-01-A, go to Windows Logs > Application and run Filter Current Log for Event ID 1000.
Expected result: Event 1000 list is shown for SHFIN-01-A.

7. [ELEVATED] Open each Event 1000 in the incident window and confirm Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.
Expected result: At least one matching crash signature is confirmed on affected host.

8. [ELEVATED] In Event Viewer on SHFIN-01-A, filter Windows Logs > Application for Event ID 9009.
Expected result: DWM exit events are visible in the same window.

9. [ELEVATED] In Event Viewer on SHFIN-01-A, open Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational and filter for Event IDs 21 and 40.
Expected result: A repeated Event 21 then Event 40 pattern is visible.

10. [ELEVATED] Sign in to SHFIN-02-A and repeat the Application log Event ID 1000 filter in the same time window.
Expected result: No Event 1000 entries with dwm.exe + igdumd64.dll are found on SHFIN-02-A.

11. Mark each POOL-FIN-01 host as AFFECTED only if all three signals are present: Event 1000 signature, Event 9009, and Event 21->40 loop.
Expected result: A written affected-host list is completed.

12. [ELEVATED] In Azure portal, start rollback of AFFECTED POOL-FIN-01 hosts to the last known good image baseline used by POOL-FIN-02.
Expected result: Image rollback task starts for all affected hosts.

13. [ELEVATED] Reimage or replace each AFFECTED host from the known-good baseline.
Expected result: Replacement/reimaged hosts appear healthy in Session hosts.

14. [ELEVATED] Reboot each remediated host once from the Azure portal session-host action menu.
Expected result: Host status returns to Available after reboot.

15. Execute one test sign-in to each remediated host.
Expected result: Desktop loads without persistent black screen and without immediate disconnect.

16. [ELEVATED] Set Allow new session = On for one remediated host at a time in POOL-FIN-01.
Expected result: Controlled re-entry starts with one host accepting new sessions.

17. Monitor that host for new incidents before enabling the next host.
Expected result: No new black-screen/disconnect reports are observed for that host.

## 3) Verification
1. [ELEVATED] On each remediated host, open Event Viewer > Windows Logs > Application, click Filter Current Log, set Logged to the post-fix time window, set Event IDs to 1000, and click OK.
Expected result: Filtered list shows no new Event 1000 entries in the post-fix window.

2. [ELEVATED] In the filtered Event 1000 results, open each entry and verify General tab does not contain both Faulting application name: dwm.exe and Faulting module name: igdumd64.dll.
Expected result: No post-fix Event 1000 entry contains the RCA crash signature pair.

3. [ELEVATED] On each remediated host, stay in Event Viewer > Windows Logs > Application, click Filter Current Log, keep the same Logged window, change Event IDs to 9009, and click OK.
Expected result: No DWM Event 9009 appears in the post-fix window.

4. [ELEVATED] On each remediated host, open Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, click Filter Current Log, set Event IDs to 21,40, and click OK.
Expected result: You do not see repeated immediate Event 21 followed by Event 40 loops after fix time.

5. [ELEVATED] In Azure portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions and watch the session list for 10 minutes.
Expected result: Sessions remain Connected and do not repeatedly flip through disconnect/reconnect behavior.

6. In Azure portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and confirm remediated hosts remain Available with Allow new session = On only for hosts already validated.
Expected result: Only validated hosts are open for placement and host health remains stable.

7. Record user confirmation from affected users that sign-in works and no black screen recurs.
Expected result: Incident notes include user confirmation and timestamp.

8. Close the incident after steps 1-7 pass on all remediated hosts.
Expected result: Closure is supported by portal state, host logs, and user confirmation.

## 4) Rollback (Execute in Under 3 Minutes)
1. [ELEVATED] Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, multi-select all remediated hosts in the latest batch, click More actions, and set Allow new session = Off.
Expected result: New user sessions are blocked from the rollback batch immediately.

2. [ELEVATED] In the same Session hosts grid, verify each selected host now shows Allow new session = No.
Expected result: Rollback containment is active on all selected hosts.

3. [ELEVATED] Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts and confirm at least one healthy host shows Allow new session = Yes.
Expected result: New user sign-ins are automatically directed to unaffected capacity.

4. [ELEVATED] Open Event Viewer on one rolled-back host: Windows Logs > Application > Filter Current Log > Event IDs 1000,9009 for the last 5 minutes.
Expected result: If signature events are still appearing, keep all remediated hosts drained and do not re-open placement.

5. Record rollback start time, host names, and operator name in the incident log.
Expected result: Immediate rollback actions are auditable and complete.

## 5) Notes
- Edge case: some users may report black screen that self-clears after about 30 seconds; treat this as in-scope if signature events are present.
- Warning: do not re-enable session placement on a host until Event Viewer checks for Event 1000 and 9009 are clean in the post-fix window.
- Warning: if Event 1000 shows dwm.exe with igdumd64.dll again, return that host to drain mode immediately.
- Related incidents/documents: day4/RCA_T1003_AVD_BlackScreen_POOL-FIN-01.md and day4/triage_T1003_avd_disconnect.md.
