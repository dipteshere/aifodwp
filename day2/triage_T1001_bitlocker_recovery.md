# Triage Summary — T-1001

## Summary (one line)
New Windows 11 laptop is prompting for a BitLocker recovery key on every boot, blocking normal user login.

## Impact (who/how many/business urgency)
- Who: Single end user with a new Win11 laptop (team and location to-verify)
- How many: 1 device reported (whether further devices in the same deployment batch are affected — to-verify)
- Business urgency: High — user may be fully blocked from logging in if the recovery key is not to hand

## Known facts
- Device is a new Windows 11 laptop.
- BitLocker recovery key prompt appears on every boot (not a one-off).
- Issue is present from initial use (to-verify whether it has ever booted without the prompt).

## Missing information to gather
- User identity, UPN, team, location, and contact details.
- Device asset tag, make, and model.
- Device join type: Azure AD / Entra joined, hybrid joined, on-prem domain joined, or workgroup (to-verify).
- Whether the recovery key has been entered successfully and if the issue returns on next boot (to-verify).
- Where the recovery key is escrowed: Azure AD / Entra ID, on-prem Active Directory, or printed/saved elsewhere (to-verify).
- TPM status: whether a TPM chip is present, enabled in BIOS/UEFI, and showing as healthy (to-verify).
- Whether Secure Boot is enabled and whether its state changed recently (to-verify).
- Whether any BIOS/UEFI firmware update was applied to the device recently (to-verify).
- Whether any hardware was changed or a dock/USB device is attached at boot (to-verify).
- Whether there is an Intune or SCCM/MECM policy governing BitLocker on this device (to-verify).
- Any relevant entries in Windows Event logs relating to BitLocker or TPM at boot time (to-verify).

## Likely category
- Endpoint security / BitLocker TPM sealing failure (to-verify)
- Possible subcategory: TPM PCR value mismatch caused by BIOS/firmware change, Secure Boot configuration, or device provisioning issue (to-verify)

## First diagnostic step
Confirm whether the device TPM is present, enabled, and healthy (check BIOS/UEFI and Windows TPM management), then verify that the BitLocker recovery key has been successfully escrowed to Azure AD / Entra ID or Active Directory — this establishes whether the device was provisioned correctly and separates a hardware/firmware cause from a policy or provisioning gap.
