# Version Header
- Document: L2 KB - Windows Login Issues on Floor 6
- Version: 1.0
- Date: 2026-08-14
- Source Runbook: runbook_windows_login_issues_floor6_v1.0

# Scope
Use this article when multiple Floor 6 users report login failure or severe login delay after recent change activity.

# Known Context
- Windows 11 update has occurred.
- New application deployment occurred Friday afternoon.
- Symptom may be authentication failure, delayed profile load, or delayed shell load.

# Procedure
1. Confirm scope.
Expected result: You have an affected user/device list with symptom classification.

2. Provide temporary access restoration for priority users.
Expected result: Critical users can continue working while investigation proceeds.

3. Correlate timeline.
Expected result: Incident start is compared with Windows update and Friday deployment times.

4. Collect evidence from impacted devices.
Expected result: Evidence exists for:
- Security failed logons
- User Profiles Service events
- Group Policy operational events
- Diagnostics-Performance logon/startup events

5. Compare with unaffected devices.
Expected result: Shared changed state or differentiator is identified.

6. Contain the suspected change if correlation is strong.
Expected result: Rollout is paused or rolled back for the affected cohort.

# Verification
1. Affected users can sign in.
2. Login duration returns to normal baseline, to confirm threshold.
3. New login failures drop toward normal background volume.

# Escalation
Escalate if users outside Floor 6 are affected or if rollback does not improve symptoms.
