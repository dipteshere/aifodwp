# Triage Summary — T-1008

## Summary (one line)
VPN connects successfully after a Win11 upgrade but no internal company resources are reachable.

## Impact (who/how many/business urgency)
- Who: Single end user working remotely post-Win11 upgrade (to-verify)
- How many: 1 user reported; whether other users on the same VPN client and Win11 build are affected — to-verify
- Business urgency: High — user is completely blocked from accessing internal services while off-site

## Known facts
- User upgraded to Windows 11.
- VPN client connects without reporting an error.
- No internal resources are reachable after the VPN connection is established.

## Missing information to gather
- User identity, team, location, and contact details.
- VPN client name and version (to-verify).
- Whether the VPN client was reinstalled or updated as part of the Win11 upgrade (to-verify).
- Whether the issue occurs on Wi-Fi, wired connection, or both (to-verify).
- Whether the VPN adapter receives an IP address correctly after connecting (to-verify via ipconfig output).
- Whether internal hostnames resolve after VPN connects (to-verify via nslookup).
- Whether the issue is DNS-only (internal IPs reachable but not hostnames) or full connectivity loss (to-verify).
- Whether split tunnelling is configured and whether the routing table is correct after VPN connects (to-verify).
- Whether Windows Firewall rules changed during the upgrade and are now blocking VPN traffic (to-verify).
- Whether the VPN adapter driver is correctly installed and healthy in Device Manager (to-verify).
- Whether any network adapter settings changed during the upgrade (to-verify).
- Whether other users on the same VPN client version and Win11 build have the same issue (to-verify).

## Likely category
- Remote access / VPN routing or DNS failure post-Win11 upgrade (to-verify)
- Possible subcategory: Split-tunnel routing issue, DNS client misconfiguration, Windows Firewall rule change, or VPN driver incompatibility with Win11 (to-verify)

## First diagnostic step
After VPN connects, capture the output of ipconfig to confirm the VPN adapter has received an IP address and DNS server assignment, then test name resolution for an internal hostname to determine whether the failure is at the DNS layer or a broader routing/firewall layer — this distinction drives the correct remediation path.
