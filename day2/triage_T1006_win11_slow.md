# Triage Summary — T-1006

## Summary (one line)
User reports the whole device has been slow since upgrading to Windows 11 two days ago.

## Impact (who/how many/business urgency)
- Who: Single end user (to-verify)
- How many: 1 device reported; whether other users from the same upgrade batch are affected — to-verify
- Business urgency: Medium — user can still work but productivity is significantly impaired

## Known facts
- User upgraded to Windows 11 two days ago.
- User reports "everything is slow" — not isolated to a single app or function.
- Slowness has been present since the upgrade.
- Whether it was an in-place upgrade or a clean install — to-verify.

## Missing information to gather
- User identity, device make, model, hardware specification (CPU, RAM, storage type), and contact details.
- Current resource utilisation at idle and under load: CPU, RAM, disk, GPU (to-verify).
- Whether Windows Update has finished all post-upgrade updates and whether any are still pending (to-verify).
- Whether the device has been rebooted multiple times since upgrade (first-boot background tasks can run for hours — to-verify).
- Whether antivirus or EDR is running a post-upgrade full scan (to-verify).
- Whether OneDrive or other sync clients are re-syncing data following the upgrade (to-verify).
- Whether device drivers (GPU, chipset, storage controller, network) are up to date for Windows 11 (to-verify).
- Whether the device fully meets Windows 11 hardware requirements (to-verify).
- Available free disk space on the system drive (to-verify).
- Whether there are any errors or warnings in Windows Event Viewer since the upgrade (to-verify).

## Likely category
- Endpoint performance / post-Win11 upgrade degradation (to-verify)
- Possible subcategory: Post-upgrade background processing, driver incompatibility, or hardware below recommended specification (to-verify)

## First diagnostic step
Open Task Manager on the device and capture CPU, RAM, disk, and network utilisation at idle to identify which resource is saturated — post-upgrade background tasks such as Windows Update, indexing, OneDrive re-sync, and antivirus scanning are the most common cause; the resource consuming the most will determine the next remediation step.
