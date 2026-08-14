# Version Header
- Document: Runbook - Potential Restricted File Access via Copilot
- Version: 1.0
- Date: 2026-08-14
- Source: copilot_restricted_files_access_analysis_report

# Purpose
Provide a repeatable response procedure for a reported case where Copilot may have surfaced a client matter to a user who believes they should not have access.

# Known Trigger Conditions
- A user reports Copilot surfaced a matter or file they believe is restricted.
- The report is not yet technically validated.
- Business context includes confidentiality or legal sensitivity.

# Prerequisites
1. Security or governance incident owner assigned.
2. Reporting user identified.
3. Access to audit, permission, and content ownership review paths.
4. Legal or compliance contact available per incident policy.

# Procedure
1. Treat the report as a potential security/privacy incident.
Expected result: Incident is handled with appropriate priority until disproven.
Action:
- Open or link to the appropriate security/governance workflow.

2. Preserve evidence immediately.
Expected result: Sufficient evidence exists to validate the reported event.
Action:
- Capture prompt text.
- Capture response snippet.
- Capture timestamp, user identity, device identity, and item identifier.

3. Validate direct access outside Copilot.
Expected result: It is known whether the user can open the same matter directly outside Copilot.
Action:
- Test access through the normal application or repository path.

4. Review effective permissions.
Expected result: Current expected access is documented and compared with observed behavior.
Action:
- Check current ACL or permission assignment.
- Check historical permission changes if available.

5. Review indexing and metadata path.
Expected result: It is known whether the issue is permission bypass, stale visibility, indexing scope issue, or metadata misunderstanding, to confirm.
Action:
- Review content indexing scope.
- Review connector or search scope settings if applicable.
- Review matter classification or metadata labeling.

6. Check for broader scope.
Expected result: It is known whether other users can reproduce similar behavior.
Action:
- Query for similar reports.
- Test with approved sample accounts if policy permits.

7. Contain if unauthorized access is confirmed.
Expected result: Exposure path is restricted and incident response continues.
Action:
- Remove inappropriate access.
- Apply approved governance or content connector correction.

8. Communicate carefully.
Expected result: Stakeholders are informed without overstating unverified conclusions.
Action:
- State that validation is in progress.
- Do not confirm exposure until evidence supports it.

# Verification
1. Effective access is confirmed for the reported item.
2. Reporting user cannot reproduce unauthorized visibility if no access should exist.
3. Any identified permission or indexing issue is corrected.

# Exit Criteria
- Report is validated as true or false.
- Required containment is complete.
- Security/governance owner approves closure or transfer to follow-up track.

# Rollback Of This Runbook Action
- If a temporary containment change blocks legitimate access, restore approved access only after permission review and owner approval.

# Open Items To Confirm
- Exact prompt and response.
- Whether direct access outside Copilot succeeds.
- Final classification: permission issue, indexing issue, metadata issue, or false alarm.
