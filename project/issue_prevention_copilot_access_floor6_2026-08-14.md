# Issue File: Copilot Restricted Files Access — Floor 6

## Issue Summary
A paralegal reported that Copilot surfaced and summarized a client matter document that she believes she should not have access to. Treated as potential security/confidentiality incident pending technical validation.

## Affected Users & Matters
- Reporting user: 1 paralegal (name and UPN to confirm)
- Matter involved: [matter number/reference to confirm]
- Document type: Draft settlement
- Sensitivity: Client-confidential / attorney-work-product (classification to confirm)

## Incident Details
- User was able to view Copilot-generated summary of matter document
- User states she was not assigned to this matter
- User did not know she could access this folder ("didn't even know I could see that folder")
- Report date: [to confirm]
- Copilot interaction timestamp: [to confirm]

## Potential Security Concerns
1. **Unauthorized access**: User without matter assignment can see document via Copilot
2. **Permission oversharing**: SharePoint site permissions may be overly broad
3. **Information barrier failure**: Expected ethical wall controls may not be functioning
4. **Indexing scope issue**: Copilot's search connector may be surfacing restricted content

## Evidence Preserved
- Copilot prompt text: [to capture]
- Copilot response snippet: [to capture]
- Timestamp: [to capture]
- User/device identity: [to capture]
- Matter identifier: [to capture]

## Validation Status (In Progress)
- Direct access test (can user open document outside Copilot): [to confirm]
- Effective permissions review: [to confirm]
- Indexing/metadata review: [to confirm]
- Scope check (other users affected): [to confirm]

## Technical Investigation Path
1. ✓ Preserve incident evidence
2. Test whether user has direct access to matter in SharePoint
3. Review SharePoint site ACL and user permission source (direct, group, inherited)
4. Check historical permission changes for the matter site
5. Review Copilot indexing scope and connector mappings
6. Check matter metadata/sensitivity classification
7. Query for similar reports from other users
8. Test with approved sample accounts if policy permits

## Validation Criteria
- Determine access type: **Authorized** (user should have access) or **Unauthorized** (access breach)
- If unauthorized: Identify root cause (permission overshare vs. indexing scope vs. metadata issue)
- Confirm no other users can reproduce similar unauthorized exposure

## Incident Response Status
- Security/governance incident opened: [reference to confirm]
- Legal/compliance owner assigned: [to confirm]
- Audit log pull requested: [status to confirm]

## Residual Risks
- **Until validation completes, confidentiality/compliance risk is active**
- Potential exposure to client information beyond intended matter team
- Possible regulatory/professional responsibility implications if unauthorized access confirmed

## Change References
- Windows 11 update occurred in same timeframe: [ticket/reference to confirm — relevance to verify]
- Friday app deployment occurred: [ticket/reference to confirm — relevance to verify]

## Stakeholders
- Reporting paralegal: [to confirm]
- Matter partner/owner: [to notify]
- Information Security team: [escalated]
- Data Protection Officer (DPO): [to notify]
- Legal/Compliance: [to notify]
- SharePoint site owner: [to contact for ACL review]

## Follow-Up Actions
1. **Immediate**: Pull Microsoft 365 Unified Audit Log for user and matter site (preserve evidence)
2. Complete technical validation (access, permissions, indexing, metadata)
3. Conduct scope assessment (check for similar unauthorized access cases)
4. If unauthorized access confirmed: Execute incident response containment plan
5. If confirmed: Apply permission corrections and governance controls
6. Conduct follow-up validation to confirm corrections are effective
7. Document lessons learned and update access control procedures
