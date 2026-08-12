# Copilot Support Ticket Triage
**Date:** 2026-08-12  
**Engineer:** DWP L2/L3  
**Default assumption:** Non-Copilot cause unless all alternatives are ruled out.

---

## Ticket 1 — Finance lead cannot summarise Q3 board pack in SharePoint

> "It's right there, I can see it myself."

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction (board packs are commonly labelled Confidential/Highly Confidential, which blocks Copilot processing) 2. Permissions/access boundary (user has direct access but Copilot's delegated scope may differ, e.g. site-collection-level block) 3. Data indexing lag (file recently uploaded or moved) |
| **Fastest check** | Open the file in SharePoint and check the sensitivity label in the toolbar — a label set to "Do Not Copy" or equivalent Copilot-blocking policy explains the error immediately. |
| **Is this actually a Copilot bug?** | **No.** The user can see the file, meaning permissions are not fully absent. A sensitivity label or site-level Copilot restriction is the most parsimonious explanation. |

---

## Ticket 2 — New hire: Copilot knows nothing about recent emails

> Started yesterday.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Data indexing lag (Microsoft 365 content indexing for new accounts typically takes 24–72 hours before Copilot can reason over it) 2. License/client prerequisite issue (Copilot licence may not yet be assigned to the new account) |
| **Fastest check** | Check Microsoft 365 admin center to confirm a Copilot licence is assigned to the account; if it is, advise the user to wait 24–72 hours for indexing to complete. |
| **Is this actually a Copilot bug?** | **No.** New-account indexing lag is the documented expected behaviour for recently provisioned accounts. |

---

## Ticket 3 — HR manager: "I don't have access to that content" on salary review spreadsheet

> Asked Copilot in Word to pull data from a sensitive salary review spreadsheet.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction (salary data is a prime candidate for a Highly Confidential or equivalent label that explicitly blocks Copilot processing) 2. Permissions/access boundary (the spreadsheet may be in a restricted library the HR manager can open directly but Copilot cannot traverse) |
| **Fastest check** | Check the sensitivity label on the spreadsheet — the error message "I don't have access to that content" is the exact response Copilot returns when a label policy blocks it. |
| **Is this actually a Copilot bug?** | **No.** The error message is the expected output of a label-enforced access block, not a fault. |

---

## Ticket 4 — Sales rep: Copilot cannot find client contract shared via guest link from another org

> File shared via a guest link from another organisation's tenant.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Guest/external sharing limitation (Copilot only indexes content in the user's home tenant; files residing in an external tenant accessed via a guest link are explicitly out of scope) |
| **Fastest check** | Confirm the file lives in the external org's SharePoint tenant, not copied into your own tenant — if it does, this is a hard platform boundary, not a fault. |
| **Is this actually a Copilot bug?** | **No.** Copilot does not index or process content from external tenants accessed via guest links. This is a documented limitation. |

---

## Ticket 5 — IT admin: Copilot stopped working for the whole Finance team this morning

> Was working fine yesterday; team-wide failure.

| Field | Detail |
|---|---|
| **Likely cause** | 1. License/client prerequisite issue (bulk licence reassignment, group-based licensing change, or a licence policy update applied overnight to the Finance group) 2. Permissions/access boundary (a conditional access or Entra ID policy change applied to the Finance security group) 3. Genuine Copilot fault (a tenant-wide or region-wide Copilot service degradation — only if service health confirms it) |
| **Fastest check** | Check Microsoft 365 admin center → Service Health for any active Copilot advisories, then immediately check that the Finance group still has Copilot licences assigned. |
| **Is this actually a Copilot bug?** | **Unclear.** A sudden team-wide failure is atypical of individual config issues but is consistent with both a licence change and a genuine service incident. Service Health must be checked before concluding either way. |

---

## Ticket 6 — Manager: Copilot surfaced a file from a folder the manager forgot they had access to

> "A file I don't remember ever opening, from a folder I forgot I had access to."

| Field | Detail |
|---|---|
| **Likely cause** | No fault — permissions/access boundary is working correctly. The manager has legitimate access to the folder; Copilot is authorised to index it and did so. |
| **Fastest check** | Verify in SharePoint that the manager's account has explicit or inherited read access to that folder — this is expected to confirm Copilot behaved correctly. |
| **Is this actually a Copilot bug?** | **No.** Copilot correctly surfaced content the user is authorised to see. This is expected behaviour, not a bug. The concern here is a data governance/awareness issue, not a Copilot fault. |

---

## Ticket 7 — Analyst: Copilot gives generic answers; never uses internal SharePoint content

> "Doesn't seem to use any of our internal SharePoint content at all."

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary (the analyst may lack read access to the SharePoint sites Copilot would need to index, or site-level Copilot access is disabled) 2. Data indexing lag (SharePoint content not yet indexed for this user — possible if account is new or sites were recently added) 3. License/client prerequisite issue (Microsoft 365 Copilot licence may not include the correct Graph connector or SharePoint indexing is disabled at tenant level) |
| **Fastest check** | Ask the analyst to open a known internal SharePoint site directly — if they cannot access it, permissions are the issue; if they can, check the Microsoft 365 Search & Intelligence admin settings to confirm SharePoint content is enabled for Copilot. |
| **Is this actually a Copilot bug?** | **No.** Generic answers in the absence of SharePoint context are consistent with Copilot operating with no indexed enterprise content available to it — a configuration or permissions issue. |

---

## Ticket 8 — Executive assistant: Copilot in Outlook cannot see shared mailbox calendar

> Manages the calendar on behalf of a director via a shared mailbox.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary (Copilot in Outlook operates on the signed-in user's primary mailbox by default; delegated/shared mailbox access requires specific configuration and the shared mailbox may also need its own Copilot licence) 2. License/client prerequisite issue (shared mailboxes require a Copilot licence assigned to them for Copilot to process their content) |
| **Fastest check** | Check whether the shared mailbox has a Microsoft 365 Copilot licence assigned in the admin center — this is the most common blocker for shared mailbox Copilot scenarios. |
| **Is this actually a Copilot bug?** | **No.** Shared mailbox and delegated calendar access has documented licence and configuration prerequisites for Copilot. This is a setup gap, not a fault. |

---

## Summary Table

| # | Top Cause | Copilot Bug? |
|---|---|---|
| 1 | Sensitivity label restriction | No |
| 2 | Data indexing lag | No |
| 3 | Sensitivity label restriction | No |
| 4 | Guest/external sharing limitation | No |
| 5 | License/client prerequisite issue | Unclear — check Service Health |
| 6 | No fault (working as designed) | No |
| 7 | Permissions/access boundary | No |
| 8 | License/client prerequisite issue | No |
