# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Date:** 2026-08-12  
**Prepared by:** DWP Engineer  
**Status:** Pre-deployment

---

## ⚠️ HIGHEST PRIORITY — Permissions & Oversharing (Complete Before Any Copilot Assignment)

> Copilot respects existing Microsoft 365 permissions. If a user can access a file, Copilot can surface it in responses — including to users who should not see it. Given that Finance SharePoint permissions were inherited from a 2019 migration and have never been fully audited, this is the single greatest data exposure risk. **Do not assign Copilot licences until all items in this section are resolved or formally risk-accepted.**

### SharePoint & OneDrive Permissions Audit

- [ ] Run the **SharePoint Advanced Management (SAM)** site access review report across all Finance-owned sites (`SharePoint Admin Centre > Policies > Access reviews`)
- [ ] Generate a **Data Access Governance (DAG)** report to identify overshared sites, files shared with "Everyone", "Everyone except external users", or with broad internal groups (`SharePoint Admin Centre > Reports > Data access governance`)
- [ ] Export all Finance SharePoint site permission reports; identify any inherited permissions originating from the 2019 migration that grant access beyond current role requirements
- [ ] Review and remediate all **site-level permissions** — remove stale groups, ex-employee accounts, and generic "All Company" or "All Staff" grants from sensitive libraries
- [ ] Identify SharePoint libraries containing payroll data, board packs, M&A documents, and client financial data; confirm each has **explicit, role-appropriate permissions** rather than broad inheritance
- [ ] Disable "**Share with everyone**" link creation at tenant level for Finance sites if not already restricted (`SharePoint Admin Centre > Policies > Sharing`)
- [ ] Set default sharing link type to **"Specific people"** (not "People in your organisation") for all Finance site collections
- [ ] Review and scope **Microsoft 365 Groups and Teams** that Finance users belong to — verify that membership accurately reflects current job roles and that files within those groups are appropriate
- [ ] Identify any Finance data stored in **personal OneDrive** accounts that has been shared broadly; enforce retention/move policies if necessary
- [ ] Document all remediation actions taken and record a formal **permissions baseline** for the Finance department post-audit

### Oversharing Risk — Sensitive Content Specific Checks

- [ ] Search for files containing payroll, salary, or compensation data using **Microsoft Purview Content Explorer** and confirm they are in appropriately restricted locations
- [ ] Confirm board pack and M&A document libraries are restricted to named individuals / specific security groups only — not department-wide access
- [ ] Confirm client financial data libraries comply with contractual and regulatory access obligations (check against data classification records)
- [ ] Enable **SharePoint site sensitivity labels** so that label inheritance controls link-sharing behaviour on the most sensitive libraries

---

## 1. Licensing Prerequisites

- [ ] Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence (verified — as per department context)
- [ ] Confirm each user licence includes one of the qualifying base plans for Copilot: Microsoft 365 E3/E5, or Office 365 E3/E5
- [ ] Procure and assign **Microsoft 365 Copilot add-on licences** for Finance users (not yet assigned — action required)
- [ ] Verify licences are assigned via **Entra ID group-based licensing** or directly in the M365 Admin Centre; avoid manual per-user assignment at this scale
- [ ] Confirm **Microsoft Purview Information Protection** is active under the E5 licence (required for sensitivity label enforcement at the Copilot layer)

---

## 2. Microsoft 365 Apps Client Version Requirements

- [ ] Confirm all Finance endpoints are running **Microsoft 365 Apps for Enterprise** (not perpetual/volume-licensed Office)
- [ ] Verify Microsoft 365 Apps is on **Current Channel** or **Monthly Enterprise Channel** — Semi-Annual Channel is not supported for Copilot
- [ ] Check installed build meets the minimum requirement: **Version 2302 (Build 16130.20306)** or later; verify via `winver` / Intune device compliance report
- [ ] Confirm endpoints are enrolled in **Intune** and receiving app update policies — validate with a compliance report filtered to Finance device group
- [ ] Check that **Microsoft Teams** is on the new Teams client (classic Teams will not surface Copilot in Teams fully)
- [ ] Validate **Outlook** is the new Outlook or classic Outlook on a supported build — web-only users should be identified separately

---

## 3. Identity & MFA Readiness

- [ ] Confirm all Finance users are **cloud-only or hybrid-synced** in Microsoft Entra ID (no on-premises-only accounts)
- [ ] Verify **Multi-Factor Authentication (MFA)** is enforced for all 200 users — check Entra ID Sign-in report for any MFA gaps
- [ ] Confirm MFA is enforced via **Conditional Access policy** (not legacy per-user MFA, which is deprecated)
- [ ] Review Conditional Access policies to ensure Finance users are not excluded from any MFA-required policies
- [ ] Confirm no Finance accounts are using **legacy authentication protocols** (Basic Auth, SMTP Auth without modern auth) — block via Conditional Access if found
- [ ] Check for any Finance service accounts or shared mailboxes that may be misconfigured as user accounts — exclude from Copilot assignment appropriately

---

## 4. Sensitivity Labelling

- [ ] Confirm **Microsoft Purview sensitivity labels** are published to Finance users via a label policy in the Compliance portal
- [ ] Verify Finance-relevant labels exist and are in use: at minimum `Confidential`, `Highly Confidential`, and `Internal` (or equivalent organisational taxonomy)
- [ ] Check that labels with **encryption** are applied to libraries holding payroll, board packs, M&A documents, and client financial data
- [ ] Enable **auto-labelling policies** in simulation mode for Finance SharePoint sites and review results before going live
- [ ] Confirm **mandatory labelling** is enforced for Microsoft 365 Apps (Word, Excel, PowerPoint) so new Finance documents are labelled at creation
- [ ] Verify **SharePoint site labels** are applied to Finance site collections — site label controls the maximum sharing level for items within the site
- [ ] Review the Purview **Data Loss Prevention (DLP)** policy covering financial data; confirm it covers SharePoint, OneDrive, Teams, and Exchange for Finance users

---

## 5. End-User Communications & Enablement

- [ ] Draft and send a **pre-launch communication** to Finance users explaining what Copilot is, what data it can access, and what responsible use looks like — emphasise that Copilot surfaces data they already have access to (reinforcing why users must not save sensitive files in broadly-shared locations)
- [ ] Publish a **Finance-specific Copilot use-case guide** covering high-value scenarios: summarising long email threads, drafting reports, querying financial documents, meeting notes in Teams
- [ ] Identify **2–3 Finance champions** (power users) to participate in early access testing before full rollout; use their feedback to refine the deployment
- [ ] Schedule **30-minute enablement sessions** (or self-service video) covering: how to prompt effectively, how to verify Copilot outputs, and data handling responsibilities
- [ ] Publish acceptable use guidance specific to Finance — reinforce that Copilot outputs on sensitive topics (payroll, M&A) must be treated as **confidential** and handled accordingly
- [ ] Establish a **feedback channel** (Teams channel or service desk category) for Finance users to report unexpected Copilot behaviour, including any cases where Copilot surfaces data that appears inappropriate
- [ ] Confirm **adoption metrics** are being captured post-launch (Viva Insights / Copilot Dashboard in M365 Admin Centre) and that a 30-day review is scheduled

---

## Sign-Off & Go / No-Go Criteria

| Criteria | Owner | Status |
|---|---|---|
| Permissions audit complete and remediated | SharePoint / DWP Engineer | ⬜ Not started |
| Oversharing report reviewed and actioned | SharePoint / DWP Engineer | ⬜ Not started |
| Sensitivity labels applied to Finance sites | Security / Compliance | ⬜ Not started |
| MFA enforced for all 200 users | Identity / DWP Engineer | ⬜ Not started |
| M365 Apps on supported channel/build | Endpoint / DWP Engineer | ⬜ Not started |
| Copilot licences procured | IT Procurement / Admin | ⬜ Not started |
| End-user comms sent | DWP Engineer / Comms | ⬜ Not started |

> **Go / No-Go decision:** All items in the Permissions & Oversharing section must be complete (or formally risk-accepted in writing by the Finance data owner) before Copilot licences are assigned. All other sections should be complete before general availability is announced to the department.
