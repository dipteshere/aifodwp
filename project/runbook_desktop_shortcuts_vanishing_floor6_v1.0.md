# Version Header
- Document: Runbook - Desktop Shortcuts Vanishing on Floor 6
- Version: 1.0
- Date: 2026-08-14
- Source: desktop_shortcut_vanishing_analysis_report

# Purpose
Provide a repeatable procedure to investigate and restore missing desktop shortcuts reported after recent Windows or application changes.

# Known Trigger Conditions
- One or more Floor 6 users report missing desktop shortcuts.
- Windows 11 update has occurred.
- New application deployment occurred Friday afternoon.

# Prerequisites
1. Incident or service request owner assigned.
2. User name, device name, and list of missing shortcuts.
3. Access to the affected device or remote management tooling.
4. Access to change records for recent deployment or policy changes.

# Procedure
1. Confirm whether issue is isolated or widespread.
Expected result: Scope is known for one user, several users, or Floor 6 more broadly.
Action:
- Ask for affected user/device list.
- Check whether the same shortcut set is missing for other users.

2. Provide temporary access workaround.
Expected result: User can still open critical applications while investigation continues.
Action:
- Use Start menu or Search.
- Use known app path if available, to confirm path list.

3. Verify desktop shortcut locations.
Expected result: Shortcut state is identified as deleted, hidden, or moved.
Action:
- Check current user desktop path.
- Check public desktop path.
- Confirm whether shortcuts still exist but are not visible.

4. Review profile and policy behavior.
Expected result: Any profile or policy change correlated to shortcut loss is identified, to confirm.
Action:
- Review profile-related events.
- Review Group Policy or scripts that modify desktop items.

5. Check redirection or sync state.
Expected result: Any desktop redirection or sync issue is identified, to confirm relevance.
Action:
- Review OneDrive or profile redirection state if used.

6. Restore shortcuts.
Expected result: Required shortcuts are visible and usable again.
Action:
- Recreate missing shortcuts from approved source.
- Reapply approved policy or correction script if a known deployment issue exists, to confirm artifact.

7. Communicate status.
Expected result: User and service owner know whether issue was isolated or linked to a broader change.

# Verification
1. Required shortcuts are visible on the desktop.
2. Shortcuts launch the expected application or file.
3. Shortcuts remain present after sign-out and sign-in.

# Exit Criteria
- User confirms required shortcuts are restored.
- No repeat disappearance observed in validation cycle.

# Rollback Of This Runbook Action
- If a corrective policy or script caused an unintended result, remove that correction and restore prior approved shortcut package.

# Open Items To Confirm
- Final affected user count.
- Whether issue was isolated or linked to broader profile behavior.
- Official restoration script or package name.
