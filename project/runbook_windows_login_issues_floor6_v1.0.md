# Version Header
- Document: Runbook - Windows Login Issues on Floor 6
- Version: 1.0
- Date: 2026-08-14
- Source: windows_login_issues_analysis_report

# Purpose
Provide a repeatable operational procedure to investigate and contain widespread Floor 6 login failures or severe login slowness following recent change activity.

# Known Trigger Conditions
- Multiple Floor 6 users report login failure or severe login delay.
- Windows 11 update has occurred.
- New application deployment occurred Friday afternoon.

# Prerequisites
1. Incident owner assigned.
2. Access to affected user and device list.
3. Access to endpoint logs or evidence collection tooling.
4. Change records for Windows 11 update and Friday app deployment.

# Procedure
1. Confirm scope.
Expected result: Affected user/device list exists with symptom type for each case.
Action:
- Record user name, device name, location, first seen time.
- Classify symptom as authentication failure, delayed profile load, or delayed shell/desktop load.

2. Stabilize access for highest-impact users.
Expected result: Priority users have a temporary path to continue work, to confirm local IT process.
Action:
- Follow approved temporary access restoration process.

3. Correlate timeline to recent changes.
Expected result: Change window and symptom onset are compared side by side.
Action:
- Compare incident start times with Windows 11 update times.
- Compare incident start times with Friday deployment start and end times.

4. Collect technical evidence from impacted devices.
Expected result: Evidence exists for login failures, profile events, policy events, and startup/logon performance.
Action:
- Review Security failed logons.
- Review User Profiles Service events.
- Review Group Policy operational events.
- Review Diagnostics-Performance events.

5. Compare with unaffected devices.
Expected result: Common factor or difference is identified, to confirm sample size.
Action:
- Check update level, deployment state, and event pattern on unaffected devices.

6. Decide containment.
Expected result: If correlation is strong, recent change is paused or rolled back under change authority.
Action:
- Freeze additional rollout for the affected cohort.
- Execute approved rollback or disable path for the suspected change if impact persists.

7. Communicate status.
Expected result: Stakeholders receive plain-language update with verified facts only.
Action:
- State impact, actions in progress, and next update time.

# Verification
1. Affected users can sign in successfully.
2. Login duration returns to normal baseline, to confirm threshold.
3. New login failure volume returns toward expected background levels.

# Exit Criteria
- Login access restored for affected users.
- Containment/rollback completed if required.
- Root cause path narrowed to confirmed or primary suspected change.

# Rollback Of This Runbook Action
- If a change rollback was executed, restore prior deployment posture only after approval and additional validation.

# Open Items To Confirm
- Exact impacted user count.
- Baseline login duration threshold.
- Final root cause statement.
