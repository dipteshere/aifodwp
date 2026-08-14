# Resolution Document: Windows Login Issues (Floor 6)

## Issue
Floor 6 users reported login failure or very slow login.

## What Is Confirmed
- About a dozen users on Floor 6 reported login failure or severe slowness.
- Windows 11 update has occurred.
- New application deployment occurred Friday afternoon.

## Resolution Goal
Restore stable user login access while validating whether recent change activity caused regression.

## Immediate Containment
1. Prioritize access restoration for impacted users (to confirm exact IT operations method).
2. Capture affected user/device list and symptom type:
- cannot authenticate
- authenticates but delayed profile load
- profile loads but desktop/shell delayed
3. Freeze additional rollout of related Friday changes for Floor 6 cohort (to confirm change authority).

## Resolution Steps
1. Correlate timeline:
- Compare first-seen login issues with Windows 11 update/install timestamps.
- Compare first-seen login issues with Friday deployment start/end timestamps.
2. Validate technical signals on impacted devices:
- Security failed logons in incident window.
- User profile service events in incident window.
- Group policy processing errors/delays in incident window.
- Diagnostics-performance startup/logon degradation events.
3. Compare with unaffected devices:
- Same update/deployment state vs symptom/no-symptom split (to confirm sample size).
4. If correlation is strong and impact persists:
- Execute approved rollback/disable path for recent change set (to confirm exact rollback procedure).

## Validation Criteria
- Affected users can sign in successfully.
- Login duration returns to normal baseline (to confirm baseline threshold).
- New login failures decline to expected background levels.

## Residual Risk
- If root cause remains unconfirmed, recurrence risk remains to confirm.

## Communication Notes (Partner-Safe)
- We have active service impact on Floor 6 logins.
- We have confirmed recent Windows/app changes in the same period.
- We are restoring access first and validating root cause in parallel.
- Next status update time: to confirm.

## Status Fields To Complete
- Incident owner: to confirm
- Change ticket references: to confirm
- Resolution timestamp: to confirm
- Final root cause statement: to confirm
