# Azure Virtual Desktop Provisioning Runbook

Environment:
- Subscription: 56f6d861-2ab0-4b14-a0e8-9e6d6192b3ad
- Resource group: dwpai-lab-rg
- Region: East US
- Tenant: zippyops.in
- User: p40@zippyops.in

## What was built

- Host pool: POOL-FIN-01
- Host pool type: Pooled
- Load balancing: BreadthFirst
- Max session limit: 5
- Desktop application group: POOL-FIN-01-DAG
- Workspace: FinBridge-Workspace
- Session host VM: fin-avd-sh01
- VM size: Standard_B2ms
- Image: MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest
- Security: Trusted Launch with Secure Boot and vTPM enabled
- Identity: System-assigned managed identity enabled
- Join state: Microsoft Entra ID joined only

## Access granted

- Virtual Machine User Login on fin-avd-sh01 for direct RDP access
- Desktop Virtualization User on POOL-FIN-01-DAG for AVD client access

## Validation completed

- Host pool created successfully
- Application group linked to workspace successfully
- VM provisioned successfully
- VM security profile confirmed as Trusted Launch
- RdAgent and RDAgentBootLoader services running
- Session host status confirmed as Available

## Provisioning sequence followed

1. Verified active Azure identity and subscription context.
2. Checked subscription and resource group RBAC for the signed-in operator.
3. Registered required resource providers and installed the desktopvirtualization CLI extension.
4. Created the pooled host pool with breadth-first load balancing and a 5-session limit.
5. Created the desktop application group and workspace, then linked the app group to the workspace.
6. Generated a host pool registration token.
7. Provisioned the Windows 11 multi-session VM with Trusted Launch, Secure Boot, and vTPM enabled.
8. Enabled Microsoft Entra sign-in support on the VM.
9. Installed and registered the AVD agent components inside the VM.
10. Assigned the user the roles needed for VM RDP and AVD desktop access.
11. Confirmed the session host reached Available.

## Troubleshooting notes

- The first VM build was non-compliant because it came up as Standard security instead of Trusted Launch.
- The VM was rebuilt with the correct security profile and managed identity.
- A legacy AVD agent publisher path was not available in this environment, so the host was registered using the supported installer-based approach.
- Password reset for p40@zippyops.in could not be performed from the current identity because directory permissions were insufficient.

## Login details

Direct RDP:
- Username: AzureAD\p40@zippyops.in
- Public IP: 20.172.225.72

AVD client:
- Workspace: FinBridge-Workspace
- Web client: https://rdweb.wvd.microsoft.com/arm/webclient

## Companion script

See [provision-avd-finance.ps1](provision-avd-finance.ps1) for a PowerShell version of the working build and validation flow.
