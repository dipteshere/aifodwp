# Triage Summary — T-8003

## Summary (one line)
A partner reports that Copilot surfaced and summarised a draft settlement document from a matter she is not assigned to — raising a potential data oversharing / permissions security concern.

## Impact (who / how many / business urgency)
- Who: Single partner user (name and UPN to-verify); the matter owner and Information Security team must also be notified
- How many: At minimum 1 user saw 1 document they should not have; the full extent of oversharing is unknown
- Business urgency: **HIGH** — this is a potential data breach / information barrier violation involving privileged legal documents; must be escalated immediately to Information Security and the Data Protection Officer (DPO) per the firm's security incident response process

## Known facts
- The partner was able to view a Copilot-generated summary of a draft settlement document.
- The document belongs to a matter the partner is not assigned to.
- The partner states she "didn't know she could even see that folder" — suggesting the underlying SharePoint/matter site permissions may be overly broad.
- Copilot only surfaces content the user has permission to access via Microsoft Search; if Copilot returned this document, the user likely holds (possibly inadvertently) read permission on the underlying file or site.

## Missing information to gather
- Partner's UPN and display name.
- The matter number / SharePoint site / library path of the draft settlement.
- Whether the partner can navigate directly to the document in SharePoint (confirms actual permission).
- How the partner is permissioned on the site — direct user permission, broad group membership (e.g. "All Staff" or "All Partners"), or inherited permission from a parent site.
- Whether information barriers or ethical walls are configured in Microsoft Purview for this matter (to-verify with compliance/IG team).
- Whether other users not assigned to this matter can also access or have had Copilot surface documents from it (to-verify — may indicate a systemic permissions issue).
- Date and time of the Copilot interaction (for audit log review).
- Whether this is a newly created site or whether permissions were recently changed (to-verify).

## Likely category
- **Security incident — data oversharing**: Overly broad SharePoint site permissions allowing unintended access to privileged matter documents (most likely)
- Missing or misconfigured information barrier / ethical wall policy in Microsoft Purview (second most likely)
- Incorrect group-based permission assignment giving the partner read access to the site (third possibility)

## Root-cause hypothesis
Copilot does not grant access beyond what Microsoft 365 permissions already allow. If Copilot returned this document, the partner has (likely unintentionally) been granted read access to the matter site — either through a broad group, inherited site permissions, or a misconfigured information barrier. The issue is a permissions/governance failure, not a Copilot fault. However, regardless of root cause, this must be treated as a security incident.

## Immediate actions required
1. **Escalate now**: Raise a P1 security incident with the Information Security team and notify the DPO — do not wait for full root-cause analysis.
2. **Preserve audit evidence**: Pull the Microsoft Purview / Microsoft 365 Unified Audit Log for the partner's account and the matter site immediately (before logs age out).
3. **Restrict access**: Work with the SharePoint site owner and IT admin to review and tighten permissions on the matter site as an emergency action.
4. **Notify matter owner**: Inform the partner assigned to the matter that an unintended disclosure may have occurred.
5. **Assess scope**: Determine whether other non-assigned users hold similar permissions and may have seen the same or other sensitive documents.

## First diagnostic step
Pull the SharePoint site permissions for the matter site and identify every user and group with read or higher access. Cross-reference against the matter team list to identify any unintended members. Run the Unified Audit Log query for the site to see all access events in the past 30 days.

## Is this a Copilot bug?
**No** — but this is a **high-priority security incident**. Copilot surfaced the document because the user had underlying permission. The root cause is a permissions / information governance failure that must be addressed urgently.
