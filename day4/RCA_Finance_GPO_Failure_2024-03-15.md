# Root Cause Analysis (RCA) - Finance OU Group Policy Failure

## Document Control
- Incident: Group Policy failure at startup
- Affected scope: 3 of 4 Finance OU machines
- Primary sample host: DESKTOP-FB031
- Comparison host: DESKTOP-FB029 (unaffected)
- Incident window: 2024-03-15 07:40 to 07:55
- RCA prepared by: DWP Analyst
- RCA date: 2026-08-07

## Executive Summary
Three Finance OU endpoints failed Group Policy processing during startup because they could not contact a domain controller. The failure chain starts with DNS resolution timeouts for the domain controller, followed by secure-channel failure and inability to read SYSVOL policy files. DHCP then confirms impacted hosts were given a decommissioned DNS server, while the one unaffected host had the correct DNS server. The most likely cause is stale DHCP scope DNS configuration for the affected subnet.

## Event ID Interpretation

### Event 7036 (Service Control Manager)
- What it recorded: A Windows service changed state to Running.
- In this case: Network Location Awareness (NLA) entered running state at 07:40:02.
- Why it matters: Baseline startup context; networking stack initialization had started.

### Event 5719 (Netlogon) - Error
- What it recorded: The machine could not establish a secure channel to the domain because no domain controller was reachable.
- In this case: Secure channel setup to FINBRIDGE failed; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- Why it matters: First direct indicator of domain reachability failure at startup.

### Event 1058 (GroupPolicy) - Error
- What it recorded: Group Policy engine failed to read a required policy file (gpt.ini) from SYSVOL.
- In this case: Access to \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini failed with 0x3 (path not found).
- Why it matters: GPO application failed because the DC/SYSVOL path was not reachable.

### Event 1030 (GroupPolicy) - Warning
- What it recorded: Group Policy engine could not query the list of applicable GPOs.
- In this case: Returned error 0x546.
- Why it matters: Confirms GPO discovery itself failed, not just one file read.

### Event 1129 (GroupPolicy) - Error
- What it recorded: Group Policy processing failed because there was no network connectivity to a domain controller.
- In this case: Logged at 07:40:12 and again at 07:44:01.
- Why it matters: Explicit statement from Group Policy that DC connectivity was unavailable.

### Event 1014 (DNS Client Events) - Warning
- What it recorded: Name resolution timeout because configured DNS servers did not respond.
- In this case: FINBRIDGE-DC01.finbridge.local lookup timed out; none of configured DNS servers responded.
- Why it matters: Strong network-DNS evidence explaining why DC could not be located.

### Event 50036 (DHCP Client) - Information
- What it recorded: DHCP lease details, including assigned IP and DNS server list.
- In this case: FB031 received DNS 10.10.3.250, identified in incident notes as an old/decommissioned DNS server.
- Why it matters: Provides configuration-level cause for DNS lookup failures.

### Event 1500 (GroupPolicy) - Information (comparison host)
- What it recorded: Group Policy processed successfully.
- In this case: FB029 processed policy successfully and had correct DNS 10.10.0.10.
- Why it matters: Control sample proving policy works when DNS configuration is correct.

## Reconstructed Sequence (Plain English)
1. The machine began normal startup and brought up core networking services.
2. Very early in startup, it attempted domain operations but could not find a domain controller.
3. Because the DC name could not be resolved, Netlogon failed to establish the computer secure channel.
4. Group Policy then failed repeatedly because it could not query GPOs or read gpt.ini from SYSVOL.
5. DNS client logs then showed timeouts for the domain controller name and no response from configured DNS servers.
6. DHCP logs showed the endpoint had been given an outdated DNS server that had already been decommissioned.
7. Group Policy retried later in the window and failed again for the same DC connectivity reason.
8. Comparison host FB029, which had correct DNS (10.10.0.10), processed Group Policy successfully in the same startup period.

## Most Likely Cause of Policy Failure
Stale DHCP DNS configuration on the Finance/Floor 3 subnet assigned decommissioned DNS servers to affected machines, preventing domain controller DNS resolution and therefore blocking SYSVOL access required for Group Policy processing.

## Evidence Supporting Cause
- Netlogon Event 5719 explicitly states no DC available and failed DC DNS lookup.
- DNS Client Event 1014 explicitly states DNS timeout and no DNS server response.
- GroupPolicy Events 1058, 1030, and 1129 all show failure modes consistent with no DC reachability.
- DHCP Event 50036 on affected machine shows old DNS assignment (10.10.3.250 in sample notes).
- DHCP comparison states affected FB055-FB057 got decommissioned DNS (172.16.5.5), while FB058 got correct DNS (10.10.0.10).
- Unaffected FB029 had correct DNS and successful Group Policy Event 1500.

## Note on DNS Values in Supplied Evidence
Two old DNS addresses are referenced in the provided data (10.10.3.250 and 172.16.5.5). Both are documented as old/decommissioned values in the incident context. This does not change the root cause: affected clients were assigned obsolete DNS settings from DHCP scope data that was not fully updated during migration.

## Corrective and Preventive Actions
1. Update DHCP scope option 006 (DNS Servers) for the affected subnet to only include active DNS servers.
2. Force DHCP renew on impacted endpoints and validate new DNS assignment.
3. Run DNS and DC reachability checks at startup validation points for OU=Finance endpoints.
4. Add migration checklist control: DHCP scope validation before decommissioning DNS infrastructure.
5. Add post-change monitoring for spikes in Event IDs 5719, 1014, 1058, and 1129.

## Immediate Verification Steps
- On affected hosts, confirm DHCP-assigned DNS is 10.10.0.10 (or current approved list).
- Confirm successful name resolution of FINBRIDGE-DC01.finbridge.local.
- Run gpupdate and verify no repeat of Event 1058/1030/1129.
- Confirm subsequent startup cycles process Group Policy successfully.
