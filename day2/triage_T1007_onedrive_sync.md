# Triage Summary — T-1007

## Summary (one line)
OneDrive has been stuck on 'processing changes' since a migration and files expected locally are missing.

## Impact (who/how many/business urgency)
- Who: Single end user (whether others in the same migration cohort are affected — to-verify)
- How many: 1 user reported; could indicate a wider migration batch issue (to-verify)
- Business urgency: High — locally missing files may be inaccessible for offline work and carry a perceived risk of data loss

## Known facts
- OneDrive client has been in a "processing changes" state since a migration.
- Files expected to be available locally are missing.
- Migration type (tenant-to-tenant, account migration, SharePoint/OneDrive content migration — to-verify).

## Missing information to gather
- User identity, UPN (old and new if tenant migration), and contact details.
- Whether the user can access their files via OneDrive on the web using the new account credentials (to-verify).
- Whether the OneDrive client is signed into the correct post-migration account (to-verify).
- Any sync errors shown in the OneDrive client (to-verify).
- Whether Known Folder Move (Desktop, Documents, Pictures redirection) was configured and whether those folders are present post-migration (to-verify).
- How long the "processing changes" state has persisted (to-verify).
- OneDrive client version and whether it has been updated since the migration (to-verify).
- Whether a OneDrive client reset has been attempted (to-verify).
- Available free disk space on the local device (to-verify).
- Whether IT has confirmed the back-end migration completed successfully for this user (to-verify).
- Whether Files On-Demand is enabled and files are online-only rather than locally synced (to-verify).

## Likely category
- Cloud storage / OneDrive sync failure post-migration (to-verify)
- Possible subcategory: Account identity mismatch, incomplete back-end migration, client re-configuration required, or Files On-Demand status change (to-verify)

## First diagnostic step
Confirm whether the user's files are visible and intact via OneDrive on the web with the new account credentials — if files are present online but missing locally, the issue is a client sync or configuration problem rather than data loss, and the resolution path shifts to client reconfiguration or reset.
