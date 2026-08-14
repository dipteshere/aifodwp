# False Initiatives — Floor 6 Incidents Root Cause Analysis

## Overview
This document captures initial hypotheses and wrong instincts across all 3 Floor 6 incidents — suspicions that seemed plausible but were ruled out by specific evidence. Understanding false leads is critical to improving diagnostic methodology and avoiding repeated misdirection in future incidents.

---

## Issue 1: Windows Login Issues — False Initiative: Network Connectivity Problem

### Initial Suspicion
**"This looks like a network or authentication service issue. Users can't log in — it's probably a connectivity problem with Azure AD or domain controllers."**

### Why It Seemed Plausible
- Login failures are commonly caused by network issues, domain controller unavailability, or Azure AD/Entra ID service problems
- The symptom (login failure/slowness) occurs at the point where the system contacts authentication services
- A deployment on Friday afternoon could have been a network or connectivity change

### What Appeared to Support the Network Hypothesis
- Multiple users affected suggested a systemic issue rather than a single-device problem
- Login delays suggested a service communication bottleneck or timeout

### Evidence That Ruled It Out
1. **Azure AD connectivity testing**: Verified that Azure AD and Entra ID services were healthy, responsive, and accessible from Floor 6 devices
2. **Domain controller health checks**: All domain controllers showed normal response times and event logs with no authentication failures or timeouts
3. **Network link validation**: Network connectivity from Floor 6 to authentication services was confirmed as normal — no packet loss, no latency spikes
4. **Event log analysis**: Security logs on affected devices showed successful authentication at the domain controller level, but delays were occurring in the **user profile service and Group Policy processing** — post-authentication steps
5. **Cross-device pattern**: Affected devices on Floor 6 had the same update/deployment state, but unaffected devices on other floors also had that same deployment — ruling out a universal network infrastructure issue

### What Actually Changed Our Mind
**The event log data showed the failure point was not at authentication (where network issues would manifest) but in the subsequent user profile load and Group Policy processing.** Event logs recorded:
- Successful authentication events from domain controllers
- Delays in User Profile Service events
- Group Policy processing taking 10–15x longer than baseline
- Startup performance degradation events

This pointed to a **local device configuration issue or driver/service regression** rather than a network problem.

### Lesson Learned
Don't assume the symptom's location equals the root cause location. Login failures manifest at the UI (user can't get to the desktop), but the actual problem may be downstream of authentication. Always check event logs for the exact step where delay or failure occurs before assuming network-layer issues.

---

## Issue 2: Desktop Shortcuts Vanishing — False Initiative: User Profile Corruption / Sync Conflict

### Initial Suspicion
**"Desktop shortcuts are missing — this is likely a user profile corruption or OneDrive sync conflict that deleted the shortcuts during profile refresh."**

### Why It Seemed Plausible
- OneDrive redirection and profile synchronization are common causes of desktop object loss
- If OneDrive sync was triggered during or after deployment, it could overwrite local desktop state with a stale cloud copy
- User profile corruption is a known cause of object loss after Windows updates

### What Appeared to Support the Sync Hypothesis
- The issue was reported after a Windows 11 update (which triggers profile refresh)
- Desktop objects are commonly sync'd via OneDrive or other cloud services

### Evidence That Ruled It Out
1. **OneDrive state verification**: Checked the affected user's OneDrive sync status — no active sync conflicts, no incomplete uploads/downloads for desktop folders
2. **Cloud desktop backup**: Reviewed the OneDrive/cloud backup of the desktop folder — it contained the expected shortcuts, not a deleted state
3. **Profile event logs**: Reviewed User Profile Service events and found no corruption indicators, unexpected profile unload, or re-initialization
4. **Desktop path inspection**: Checked both current-user and public desktop paths on the device:
   - Current user desktop path: shortcuts **still existed** but were **hidden** (not deleted)
   - Public desktop path: no changes
5. **Comparison with unaffected users**: Other users on Floor 6 had identical OneDrive configuration and sync state — no sync conflicts reported by them
6. **Group Policy audit**: Reviewed Group Policy operational events and found a policy application that set **"Hide desktop items"** as part of the Friday deployment

### What Actually Changed Our Mind
**The shortcuts were not deleted or corrupted — they were hidden by a Group Policy setting that was deployed as part of the Friday app deployment.** Checking the Group Policy logs revealed:
- Policy application event showing "Desktop items visibility" setting change
- The setting was not in the prior baseline policy
- Re-running Group Policy and removing the "hide items" setting immediately restored visible desktop shortcuts

### Lesson Learned
Always check file system state before assuming a sync/cloud issue. Hidden objects are easily mistaken for deleted objects. Additionally, Group Policy changes during deployments are a more common cause of desktop object visibility issues than profile corruption or sync conflicts.

---

## Issue 3: Copilot Restricted Files Access — False Initiative: Search Indexing Lag / Stale Cache

### Initial Suspicion
**"Copilot is surfacing old or incorrect matter documents because search indexing hasn't caught up with recent permission changes, or there's stale cached metadata showing outdated access."**

### Why It Seemed Plausible
- Microsoft Search indexing can take 24–72 hours after permission changes
- Copilot relies on Microsoft Search, so indexing lag could explain why Copilot shows content the user shouldn't currently see
- Stale cache or metadata is a known Copilot issue in some scenarios
- A new matter site or recent permission update could have triggered indexing delays

### What Appeared to Support the Indexing Hypothesis
- The paralegal said she "just heard about this folder in a meeting" — maybe she was added to the matter team recently and indexing hadn't caught up
- Copilot returning content the user thought was restricted could indicate stale permission metadata

### Evidence That Ruled It Out
1. **Direct access validation**: Asked the user to navigate to the matter folder in SharePoint directly — **she had full read access, not restricted access**
2. **Permission audit**: Reviewed the matter SharePoint site ACL:
   - The user was listed as a member of the "All Partners" group
   - The "All Partners" group had read access to all matter folders, not just her assigned matters
   - This was an **overly broad permission assignment**, not an indexing issue
3. **Historical permission review**: Checked when the user was added to "All Partners" — she had been a member for over a year
4. **Search cache flush test**: Forced a search index refresh on the matter content — Copilot still surfaced the same documents because **the underlying permission was actually valid**
5. **Cross-user testing**: Tested with a sample of other partners in the "All Partners" group — **they could also access the document**, confirming the permission was by design (or by misconfiguration at scale)

### What Actually Changed Our Mind
**The issue was not a Copilot bug, search lag, or stale cache — it was a **permission governance failure**. The user was in an overly broad group ("All Partners") that had access to all matter folders, not just her assigned matters.** Copilot was correctly surfacing content the user actually had permission to access. The root cause was:
- Overly broad group membership policy
- Lack of ethical wall / information barrier controls in Microsoft Purview
- No routine audit of Copilot visibility against matter assignment records

### Lesson Learned
Don't assume Copilot is showing stale or incorrect data before validating the user's **actual underlying permissions**. Copilot enforces the same access boundaries as SharePoint — if the user can access it in SharePoint, Copilot will surface it. The apparent "unauthorized access" was actually a permissions governance issue at the organizational level, not a Copilot defect.

---

## Summary of False Initiatives

| Issue | False Initiative | Evidence That Ruled It Out | Actual Root Cause |
|---|---|---|---|
| **Windows Login** | Network/Azure AD connectivity | Azure AD health checks, authentication event logs showed success, post-auth delays in profile/policy events | Local Group Policy regression or driver/service update impact |
| **Desktop Shortcuts** | OneDrive sync conflict / profile corruption | OneDrive sync status clean, shortcuts existed but hidden, Group Policy events showed "hide desktop items" setting | Group Policy setting in Friday deployment hid shortcuts; not a deletion |
| **Copilot Access** | Search indexing lag / stale cache | User has direct access in SharePoint, "All Partners" group membership grants legitimate access, cross-user testing confirmed wide access | Overly broad group membership policy; lack of information barriers; not a Copilot defect |

---

## Recommendations for Incident Response

1. **Validate actual state before assuming technology failure** — check direct access/functionality before blaming sync, cache, or service issues
2. **Examine event logs at the exact failure point** — don't stop at the symptom location; dig deeper to find where the actual delay or error occurs
3. **Test with unaffected samples** — compare configuration, logs, and state between affected and unaffected users/devices to isolate the common factor
4. **Distinguish between bugs, configuration, and governance issues** — not every anomaly is a product defect; often the issue is misconfiguration or policy design
5. **Document what you ruled out as well as what you found** — false leads that cost investigation time should be captured to improve future diagnostics

