# Triage Summary — T-8004

## Summary (one line)
All 40 members of the Legal team simultaneously lost access to Microsoft 365 Copilot this morning; it was working normally last week.

## Impact (who / how many / business urgency)
- Who: Entire Legal team — 40 users
- How many: 40 users affected; entire department
- Business urgency: **HIGH** — full team outage of a business-critical productivity tool; Legal is a high-sensitivity function with time-critical work

## Known facts
- All 40 Legal team users are affected — no partial outage within the team.
- Copilot was working correctly last week.
- The issue started this morning (2026-08-12).
- The simultaneous, team-wide loss of access strongly suggests an administrative/licence change rather than individual endpoint or account issues.

## Missing information to gather
- Exact time the outage began (first reported complaint and any admin change windows overnight — to-verify).
- Whether any licence changes, group membership changes, or admin centre changes were made to the Legal team's M365 group or licence assignments in the past 24–48 hours (check M365 admin centre licence assignment history and Azure AD group membership audit log).
- Whether the Copilot licences are assigned via a group (e.g. an Azure AD security group or M365 group) or individually — a group-based assignment means a single group change can remove all 40 licences simultaneously.
- Whether the Legal team's Azure AD / Entra ID group has changed membership or had its licence assignment removed (check Entra ID > Groups > the relevant group > Licences and Members).
- Whether any conditional access policy was updated overnight that could block Copilot access for the Legal group.
- Whether there is a service health incident on the Microsoft 365 Service Health Dashboard affecting Copilot for the tenant (check M365 admin centre > Health > Service health).
- Whether users from other departments are also affected (to rule out a tenant-wide Copilot outage — to-verify).
- Error message users receive when they attempt to access Copilot (e.g. "You don't have a licence", "Copilot is not available", or other).

## Likely category
- Group-based licence assignment removed or group membership cleared (most likely — explains simultaneous team-wide loss)
- Copilot licence reassigned/revoked in the M365 admin centre (individual or bulk action — to-verify)
- Conditional access policy change blocking Copilot for Legal group (less likely but possible)
- Tenant-wide or regional Microsoft 365 Copilot service incident (check Service Health Dashboard first as a quick exclusion)

## Root-cause hypothesis
A simultaneous, team-wide loss of access to a single service for a defined group almost always points to a licensing or group-membership change in the admin plane, not a user-side or endpoint fault. The most probable cause is that the Legal team's Azure AD / Entra ID group — through which Copilot licences are assigned — had its licence assignment removed, or the group itself was modified or deleted. This may have been an unintended consequence of a broader licence management task performed overnight.

## First diagnostic step
1. Check the **Microsoft 365 Service Health Dashboard** (admin centre > Health > Service health) to immediately rule out a Microsoft-side Copilot outage — this takes under 2 minutes.
2. If no service incident is listed, open **Entra ID > Groups**, locate the group used to assign Copilot licences to Legal, and verify: (a) the group still has the Copilot licence assignment and (b) all 40 users are still members.
3. Review the **Entra ID audit log** (Entra ID > Monitoring > Audit logs, filter last 24 hours) for any group membership or licence assignment changes affecting the Legal group.

## Is this a Copilot bug?
**Unlikely.** A simultaneous all-team outage is a strong indicator of an administrative change. Investigate the licence and group configuration before assuming a Copilot service fault.
