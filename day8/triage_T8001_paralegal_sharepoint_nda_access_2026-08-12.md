# Triage Summary — T-8001

## Summary (one line)
Paralegal asked Copilot to summarise a client NDA stored in SharePoint and received "I don't have access to that content" — the file is in a folder she has never directly opened.

## Impact (who / how many / business urgency)
- Who: Single paralegal user (name and team to-verify)
- How many: 1 user, 1 file reported (whether other files in the same folder are affected — to-verify)
- Business urgency: Medium — user is blocked from using Copilot to process a specific document; workaround (open and read the file manually) is available

## Known facts
- File is a client NDA stored in SharePoint.
- File is in a folder the user has **never directly opened** — she learned of it in a meeting.
- Copilot returned "I don't have access to that content."
- The user has not confirmed whether she holds permissions on the folder/file at all.

## Missing information to gather
- User UPN and display name.
- SharePoint site URL, library name, and folder path where the NDA resides.
- Whether the user can navigate to and open the file directly in SharePoint (confirms whether she actually has read permission).
- Sensitivity label applied to the file (visible in the SharePoint document properties or the label bar when the file is open).
- Whether the SharePoint site or library has Copilot disabled at the site-collection or library level (check site settings > Copilot / Search settings — to-verify with SharePoint admin).
- Whether the file was recently uploaded or moved (indexing lag if < 24–72 hours — to-verify).
- Whether there is a DLP or information-barrier policy restricting this folder (to-verify with compliance team).

## Likely category
- Permissions gap: user has no direct permission to the folder/file and Copilot correctly enforces her access boundary (most likely)
- Sensitivity label or Copilot-blocking policy on the document or library (second most likely)
- Microsoft Search / Copilot indexing lag (less likely unless file was very recently added)

## Root-cause hypothesis
The paralegal **heard about** the folder in a meeting but has never opened it — she most likely has no SharePoint permission on that folder or its parent library. Copilot respects the same access controls as SharePoint, so the error is expected behaviour rather than a Copilot fault. The secondary possibility is a sensitivity label (e.g. "Highly Confidential – Legal") that blocks Copilot processing even where read access is present.

## First diagnostic step
Ask the user to navigate directly to the SharePoint folder and attempt to open the NDA file. If SharePoint returns an "Access Denied" error, raise a permissions request with the site owner — Copilot cannot grant access that SharePoint has not granted. If the file opens successfully, check its sensitivity label; a Copilot-blocking label is the next most likely cause and should be escalated to the Information Protection team.

## Is this a Copilot bug?
**No.** Copilot enforces the same permission boundary as the underlying Microsoft 365 service. The behaviour is by design.
