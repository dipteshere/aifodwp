# Triage Summary — T-8002

## Summary (one line)
New associate (started this week) reports that Copilot in Outlook cannot find or provide context on any of the case emails he needs.

## Impact (who / how many / business urgency)
- Who: Single new associate (name, UPN, and start date to-verify)
- How many: 1 user; all case emails reportedly unavailable to Copilot
- Business urgency: Medium — user cannot leverage Copilot for email context but can still read emails directly; productivity impact rather than full blockage

## Known facts
- User started this week (very recently provisioned account).
- Copilot in Outlook is accessible (the user can open it) but returns no useful results for case emails.
- The issue affects all case emails, not a specific thread or folder.

## Missing information to gather
- User UPN and full name.
- Exact start date and date the M365 account was provisioned.
- Whether a Copilot (Microsoft 365 Copilot) licence is assigned to the account (check M365 admin centre > Users > Licences).
- Whether the user can see the emails in Outlook normally (confirms mailbox is populated and mail flow is working).
- Whether Copilot in Outlook is returning an error message or simply returning empty/irrelevant results.
- Whether the emails the user is trying to reference were sent to him directly or to a shared/group mailbox he has been added to (to-verify — shared mailbox content may not be indexed for Copilot).
- Whether the user's mailbox was migrated or the account was created fresh (migration may delay indexing further — to-verify).
- Whether other newly provisioned users on the same cohort report the same behaviour (to-verify).

## Likely category
- Microsoft 365 content indexing lag (accounts provisioned this week typically require 24–72 hours before Copilot can reason over mailbox content — most likely)
- Copilot licence not yet assigned or not yet propagated to the account (second most likely)
- Shared/group mailbox content not indexed for delegated Copilot use (if the emails are in a shared mailbox — to-verify)

## Root-cause hypothesis
New accounts undergo a mandatory Microsoft Search indexing period before Copilot can surface content. A user who started this week is almost certainly within that window. This is documented expected behaviour, not a fault. A secondary check on licence assignment is worthwhile, as licences are sometimes assigned with a delay during onboarding batch runs.

## First diagnostic step
In the Microsoft 365 admin centre, confirm a Copilot licence is assigned to the user's account. If not, assign one and advise the user to allow up to 24 hours for activation. If the licence is already assigned, advise the user this is normal indexing lag for new accounts and to retry in 24–72 hours from account creation. Document the account creation date for reference.

## Is this a Copilot bug?
**No.** New-account content indexing lag is documented expected behaviour for Microsoft 365 Copilot.
