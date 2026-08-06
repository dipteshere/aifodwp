# Triage Summary — T-1002

## Summary (one line)
Finance user is unable to open a shared mailbox following a migration.

## Impact (who/how many/business urgency)
- Who: Single Finance team user (whether the whole Finance team is affected — to-verify)
- How many: 1 user reported; wider mailbox delegation group may be affected (to-verify)
- Business urgency: Medium–High — Finance teams commonly rely on shared mailboxes for time-sensitive workflows (urgency to-verify)

## Known facts
- Affected user is in the Finance team.
- User cannot open a shared mailbox.
- Issue began following a migration (migration type — Exchange on-prem to Exchange Online, tenant-to-tenant, or other — to-verify).

## Missing information to gather
- User identity, UPN, and contact details.
- Name and email address of the shared mailbox that cannot be opened.
- Type of migration performed and whether it has been marked complete for this user (to-verify).
- Exact error or behaviour when attempting to open the mailbox (permission denied, mailbox not found, no error but mailbox absent — to-verify).
- Whether the user has Full Access permission assigned and whether it was re-applied post-migration (to-verify).
- Whether the issue occurs in Outlook desktop, Outlook on the Web, or both (to-verify).
- Whether other Finance users with access to the same mailbox are also affected (to-verify).
- Whether automapping is configured and expected to surface the mailbox automatically (to-verify).
- Whether the user's Outlook profile was rebuilt or recreated post-migration (to-verify).
- Whether the shared mailbox itself completed migration successfully and is not in a failed/partial state (to-verify).

## Likely category
- Email / shared mailbox access failure post-migration (to-verify)
- Possible subcategory: Missing delegated permissions post-migration, automapping failure, or stale Outlook profile (to-verify)

## First diagnostic step
Check in the Exchange or Microsoft 365 admin centre that the shared mailbox migration completed successfully and that the user's Full Access permission is present and correctly assigned post-migration; then test access via Outlook on the Web to isolate whether this is a client-side profile issue or a back-end permissions problem.
