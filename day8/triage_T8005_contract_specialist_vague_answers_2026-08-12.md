# Triage Summary — T-8005

## Summary (one line)
Contract specialist reports that Copilot gives vague, generic answers when asked about specific clauses in the firm's contract templates library — it does not appear to actually read or reference the documents.

## Impact (who / how many / business urgency)
- Who: Single contract specialist (name and UPN to-verify); likely affects others who use the same templates library
- How many: 1 user confirmed; scope across team to-verify
- Business urgency: Medium — Copilot is accessible but not functioning correctly for its intended purpose; workaround is to read documents manually

## Known facts
- The contract templates library is stored in SharePoint (location and site to-verify).
- Copilot responds to clause-related queries but with generic, non-document-specific answers.
- The user expects Copilot to cite or reflect actual content from specific template documents.
- It is not yet confirmed whether the user is referencing the library generally or a specific open document.

## Missing information to gather
- User UPN and display name.
- SharePoint site URL and library path for the contract templates library.
- Whether the user is using Copilot in the context of a specific open document (e.g. in Word with the document open) or asking Copilot generally (e.g. in Teams or the Copilot chat sidebar) to reference the library.
- Whether the user has direct read access to the templates library and can open the files manually (to-verify).
- Sensitivity labels applied to the template documents (a Copilot-blocking label would prevent Copilot from reading content even where access exists — to-verify).
- Whether the templates library has restricted search indexing — e.g. the SharePoint library or site has "Do not index" or "Exclude from search" configured (to-verify with SharePoint admin).
- How recently the templates were uploaded or last modified (indexing lag if < 24–72 hours — to-verify).
- Whether the library contains a large number of documents and whether Copilot is being asked to reason over the entire library vs. a specific file.
- Whether other users querying the same library via Copilot get the same generic results (to-verify — helps determine if this is user-specific or library-wide).

## Likely category
- SharePoint library or site excluded from Microsoft Search indexing (most likely — explains why Copilot cannot read actual document content)
- Sensitivity label on template documents blocking Copilot processing (second most likely)
- User querying via general Copilot chat rather than in-document Copilot (misuse of feature — Copilot chat works best when a document is open or explicitly referenced — to-verify)
- Content indexing lag (if library was recently created or documents recently added — to-verify)

## Root-cause hypothesis
Copilot's ability to answer questions about specific document content depends on Microsoft Search having indexed those documents. If the SharePoint library has search indexing disabled (a common setting in libraries containing sensitive templates), or if the documents carry a sensitivity label that prevents Copilot processing, Copilot will fall back to its general language model knowledge and produce generic answers. Alternatively, the user may be using Copilot in a context (e.g. general chat) where it does not automatically scope to a specific file — instructing them to open the template in Word and use "Copilot in Word" may resolve the issue immediately.

## First diagnostic step
Ask the user to open a specific contract template directly in Word (from SharePoint), then use the Copilot pane within Word to ask the same clause-related question. If Copilot now gives a specific, document-grounded answer, the issue is context/usage (the user was querying general Copilot chat rather than in-document Copilot) — resolve with user guidance. If the in-Word experience also returns generic answers, escalate to check the library's search indexing settings and the sensitivity labels on the documents.

## Is this a Copilot bug?
**Unlikely.** The most probable causes are search indexing configuration, sensitivity labels, or incorrect usage context — all of which are infrastructure or user-guidance issues rather than a Copilot product defect.
