# Version Header
- Document: L2 KB - Potential Restricted File Access via Copilot
- Version: 1.0
- Date: 2026-08-14
- Source Runbook: runbook_copilot_restricted_files_access_floor6_v1.0

# Scope
Use this article when a user reports that Copilot surfaced a file or matter they believe is restricted.

# Handling Principle
Treat the report as a potential security or privacy incident until disproven.

# Procedure
1. Open or link the security/governance workflow.
Expected result: Incident is tracked with appropriate priority.

2. Preserve evidence immediately.
Expected result: Prompt, response, timestamp, user, device, and item details are captured.

3. Validate direct access outside Copilot.
Expected result: You know whether the user can access the same matter through the normal repository path.

4. Review effective permissions.
Expected result: Current expected access is documented and compared with observed behavior.

5. Review indexing and metadata path.
Expected result: You determine whether the issue is permission-related, indexing-related, metadata-related, or still to confirm.

6. Check broader scope.
Expected result: You know whether similar reports or reproducible behavior exist.

7. Contain if unauthorized access is confirmed.
Expected result: Incorrect access or visibility path is restricted.

# Verification
1. Effective access is confirmed for the reported item.
2. Reporting user cannot reproduce unauthorized visibility if access should not exist.
3. Any identified permission or indexing issue is corrected.

# Escalation
Do not close the incident without security or governance approval if confidentiality risk remains.