# Microsoft 365 Copilot Readiness — Tier Ranking for Finance Rollout
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Date:** 2026-08-12  
**Prepared by:** DWP Engineer  
**Reference document:** `copilot_readiness_checklist_finance_2026-08-12.md`

---

## Why This Document Exists

The readiness checklist contains ~40 individual action items. Not all of them carry equal risk if incomplete at the point of licence assignment. This document ranks every item into three tiers so that the deployment team has a clear, defensible prioritisation — and so that any risk-acceptance decisions are made explicitly, not by omission.

---

## Tier Definitions

| Tier | Label | Meaning |
|---|---|---|
| **MUST** | Blocking | Copilot licences must not be assigned until this is done. Proceeding without it creates a concrete, near-certain risk of data exposure, compliance breach, or broken functionality. |
| **SHOULD** | High risk if skipped | Not technically blocking, but skipping creates meaningful risk that is likely to materialise within weeks of rollout. Should be completed or formally accepted in writing before go-live. |
| **CAN** | Lower risk | Can be completed in parallel with or after rollout. Omitting these will reduce value or increase noise but will not directly expose sensitive data or break core functionality. |

---

## MUST — Complete Before Rollout (Blocking)

These items are hard blockers. Assigning Copilot licences before these are complete is not a calculated risk — it is an uncontrolled one.

### Permissions & Oversharing (entire section)

- [ ] Run the SharePoint Advanced Management site access review report across all Finance-owned sites
- [ ] Generate a Data Access Governance report to identify overshared sites and "Everyone" / "Everyone except external users" grants
- [ ] Export and remediate all Finance SharePoint site permission reports inherited from the 2019 migration
- [ ] Remove stale groups, ex-employee accounts, and generic broad grants from sensitive libraries
- [ ] Confirm payroll, board pack, M&A, and client financial data libraries have explicit, role-appropriate permissions
- [ ] Set default sharing link type to "Specific people" for all Finance site collections
- [ ] Disable "Share with everyone" link creation for Finance sites
- [ ] Review M365 Groups and Teams membership for accuracy against current Finance roles
- [ ] Search Purview Content Explorer for payroll/salary/compensation data and confirm it is in restricted locations
- [ ] Confirm board pack and M&A libraries are restricted to named individuals or specific security groups only
- [ ] Confirm client financial data libraries comply with contractual and regulatory access obligations
- [ ] Document remediation actions and record a formal permissions baseline

### Identity & MFA

- [ ] Confirm MFA is enforced for all 200 Finance users via Conditional Access policy
- [ ] Confirm no Finance accounts use legacy authentication protocols (Basic Auth, SMTP Auth)
- [ ] Verify no Finance users are excluded from MFA-required Conditional Access policies

### Licensing

- [ ] Confirm all 200 users hold an active M365 E5 licence
- [ ] Confirm Microsoft Purview Information Protection is active under the E5 licence

### Sensitivity Labelling (minimum viable)

- [ ] Confirm sensitivity labels are published to Finance users via a label policy
- [ ] Confirm labels with encryption are applied to libraries holding payroll, board packs, M&A, and client financial data
- [ ] Confirm SharePoint site labels are applied to Finance site collections (controls maximum sharing level)

---

## SHOULD — Complete Before Rollout (High Risk if Skipped)

These items are not binary blockers but skipping any of them significantly increases the probability of a data incident, user confusion, or compliance finding within the first 30 days.

### Microsoft 365 Apps Client

- [ ] Verify M365 Apps is on Current Channel or Monthly Enterprise Channel (Semi-Annual Channel unsupported)
- [ ] Check installed build meets minimum version: 2302 (Build 16130.20306) or later
- [ ] Confirm Teams is on the new Teams client

### Sensitivity Labelling (extended)

- [ ] Enable auto-labelling policies in simulation mode for Finance SharePoint sites and review results
- [ ] Enforce mandatory labelling for M365 Apps so new Finance documents are labelled at creation
- [ ] Review and confirm DLP policy covers SharePoint, OneDrive, Teams, and Exchange for Finance users

### Oversharing — OneDrive

- [ ] Identify Finance data stored in personal OneDrive that has been shared broadly; enforce retention/move policies if necessary

### End-User Comms

- [ ] Send pre-launch communication to Finance users explaining what data Copilot can access and what responsible use looks like
- [ ] Publish Finance-specific Copilot use-case guide
- [ ] Publish acceptable use guidance specific to Finance, covering handling of Copilot outputs on payroll and M&A topics

---

## CAN — Complete During or After Rollout (Lower Risk)

These items improve adoption quality, operational visibility, and long-term governance but do not materially increase the risk of a data incident if deferred.

### Microsoft 365 Apps Client

- [ ] Confirm Outlook is on new Outlook or a supported classic Outlook build; identify web-only users separately

### Licensing & Administration

- [ ] Migrate to Entra ID group-based licensing if currently using manual per-user assignment
- [ ] Identify and correctly categorise Finance service accounts and shared mailboxes to exclude from Copilot assignment

### End-User Enablement

- [ ] Identify 2–3 Finance champions for early access testing
- [ ] Schedule 30-minute enablement sessions or publish self-service video content
- [ ] Establish a feedback channel (Teams channel or service desk category) for unexpected Copilot behaviour

### Adoption & Governance

- [ ] Confirm adoption metrics are being captured (Viva Insights / Copilot Dashboard)
- [ ] Schedule 30-day post-launch review

---

## Why Permissions and Oversharing is MUST — Not Just Another Item

Licensing and client version checks are technically simpler to verify, and that is precisely why they feel more urgent — they are quick wins. But simplicity of verification does not equal importance. The reason the permissions and oversharing audit is a hard blocker, not a high-risk item to weigh up, is rooted in how Copilot works and what is actually at stake in this specific Finance environment.

### 1. Copilot does not add new permissions — it amplifies existing ones

Copilot for Microsoft 365 operates entirely within the Microsoft Graph. It can only surface content that the user already has permission to access. This sounds reassuring until you consider the inverse: if a Finance analyst has inherited read access to a board-level M&A folder from a 2019 migration group that was never cleaned up, Copilot will treat that access as legitimate and may surface that content in a response to a routine prompt — without the user even knowing the folder exists. The exposure is not theoretical; it is a direct function of unreviewed inherited permissions.

### 2. The 2019 migration debt is a known, unresolved risk — not a hypothetical

Most oversharing risk discussions are probabilistic. This one is not. The permissions inherited from the 2019 migration have never been audited. Seven years of staff changes, role changes, team restructures, and project completions mean there is near certainty of stale access grants across the Finance SharePoint estate. Assigning Copilot licences before auditing this is not accepting a small residual risk — it is activating a large known debt.

### 3. The data categories involved carry the highest consequence of exposure

The Finance department holds payroll data, board packs, M&A documents, and client financial data. These are not just "sensitive" in a general sense:
- **Payroll data** carries employment law, GDPR Article 9, and internal HR policy obligations.
- **M&A documents** carry legal privilege, market abuse regulation (MAR), and inside information obligations under UK MAR / FCA rules.
- **Client financial data** likely carries contractual confidentiality obligations and potentially FCA/PRA regulatory requirements.
- **Board packs** contain forward-looking statements and strategic decisions that, if surfaced to the wrong internal audience, could constitute a governance failure.

A misconfigured permissions state combined with a Copilot licence is a single user prompt away from surfacing any of this to an unintended recipient.

### 4. Licensing and client version failures are recoverable in minutes; a data incident is not

If a user's M365 Apps build is out of date, Copilot simply will not work for them. That is a helpdesk ticket. If an M&A document is surfaced to a Finance analyst who had a seven-year-old inherited access grant, that is a potential regulatory breach, an internal investigation, and a formal data incident report. The asymmetry in consequence is the entire justification for treating permissions as a blocking item rather than a parallel workstream.

### 5. Remediation cannot happen retrospectively without cost

Once Copilot is live and users begin prompting, any data that has been surfaced inappropriately cannot be unsurfaced. Audit logs will record what was returned. Remediating permissions after the fact closes the door but does not address what already occurred. Doing the permissions work before rollout eliminates this category of risk entirely.

---

## Summary Table

| Section | Tier | Rationale |
|---|---|---|
| Permissions & Oversharing audit (entire section) | **MUST** | Activates known 2019 migration debt; direct exposure path for payroll/M&A/client data via Copilot Graph access |
| MFA and Conditional Access enforcement | **MUST** | Identity is the control plane for all M365 access; weak MFA = account compromise = Copilot as a data exfiltration vector |
| Sensitivity labels on Finance sites and libraries | **MUST** (minimum) | Labels control sharing behaviour at the site layer; without them, link-based sharing bypasses access controls |
| M365 Apps on supported channel/build | **SHOULD** | Functional blocker for affected users but not a data risk; fixable post-assignment |
| DLP policy coverage | **SHOULD** | Reduces blast radius if oversharing occurs; important but compensating control rather than primary |
| Mandatory labelling enforcement | **SHOULD** | Prevents new unlabelled documents; does not address existing estate |
| End-user comms and acceptable use guidance | **SHOULD** | Reduces accidental misuse; cannot prevent permission-based exposure |
| Champions, enablement sessions, feedback channel | **CAN** | Adoption quality items; no data risk implication if deferred |
| Adoption metrics and 30-day review | **CAN** | Governance improvement; does not affect rollout safety |
