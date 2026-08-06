# Triage Summary — T-1004

## Summary (one line)
A company application is failing to install from the Intune Company Portal with error 0x87D1041C.

## Impact (who/how many/business urgency)
- Who: Single end user (whether others targeted by the same Intune app deployment are affected — to-verify)
- How many: 1 user reported; could affect all devices in the same Intune assignment group (to-verify)
- Business urgency: Medium — user is blocked from a required application; urgency depends on the app's role (to-verify)

## Known facts
- User attempted to install an app via the Intune Company Portal.
- Install failed with error code 0x87D1041C.
- Platform is assumed to be Windows (to-verify).
- Error 0x87D1041C indicates Intune reported the application was not detected after the installation completed — the installer may have run but the detection rule did not match (to-verify).

## Missing information to gather
- User identity, device name/asset tag, and contact details.
- Name and version of the application that failed (to-verify).
- Whether the app has ever installed successfully on this device or on other devices (to-verify).
- Whether the device is enrolled in Intune, compliant, and Azure AD / Entra joined (to-verify).
- Whether the Intune Management Extension service is running and up to date on the device (to-verify).
- Contents of the Intune Management Extension log on the device for the relevant app entry (to-verify).
- Whether the Intune app detection rule matches what the installer actually writes to disk or registry (to-verify).
- Whether a reboot is pending on the device that may be blocking the install (to-verify).
- Whether a previous or conflicting version of the app is already installed (to-verify).
- Whether other users or devices in the same assignment group have the same failure (to-verify).

## Likely category
- Endpoint management / Intune app deployment failure (to-verify)
- Possible subcategory: Intune detection rule mismatch, Intune Management Extension issue, or installer-side failure (to-verify)

## First diagnostic step
Review the Intune Management Extension log on the affected device for the specific app entry to determine whether the installer ran to completion but the detection rule did not match — error 0x87D1041C specifically points to a detection failure, so cross-check the configured detection method in the Intune portal against what the installer actually places on the device.
