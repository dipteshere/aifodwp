# Triage Summary — T-1003

## Summary (one line)
AVD session disconnects after approximately 10 minutes of use before automatically reconnecting.

## Impact (who/how many/business urgency)
- Who: Single end user on AVD (whether other users on the same host pool are affected — to-verify)
- How many: 1 user reported; could be host pool-wide if policy or session host is the cause (to-verify)
- Business urgency: Medium — user can reconnect but work is interrupted on each cycle; unsaved work may be lost (to-verify)

## Known facts
- AVD session disconnects at approximately the 10-minute mark.
- Session reconnects automatically after the disconnect (not a complete loss of access).
- Whether the interval is consistently 10 minutes or approximate — to-verify.

## Missing information to gather
- User identity, team, location, and contact details.
- AVD host pool name and session host the user is assigned to (to-verify).
- Remote Desktop client in use and its version (Windows client, web browser, AVD client — to-verify).
- Network path at point of use: corporate network, home Wi-Fi, VPN, or direct internet (to-verify).
- Whether any error code or message is shown at the point of disconnect (to-verify).
- Whether the disconnect is a clean session disconnect or a full client application crash (to-verify).
- Whether the 10-minute pattern is reproducible on every session or intermittent (to-verify).
- AVD host pool idle disconnect and session time-limit policy settings in the Azure portal (to-verify).
- Whether other users on the same host pool report the same behaviour (to-verify).
- Network quality at the client side: packet loss, latency, jitter (to-verify).
- Session host resource utilisation (CPU, RAM, disk) around the time of disconnect (to-verify).

## Likely category
- Remote access / AVD session stability issue (to-verify)
- Possible subcategory: Host pool session timeout policy, network instability, or session host resource pressure (to-verify)

## First diagnostic step
Check the AVD host pool session time-limit and idle disconnect policy settings in the Azure portal — a 10-minute disconnect is a strong indicator of a policy-set timeout; if no policy matches that interval, review session host event logs to determine whether the disconnect is triggered by a network drop or a resource condition.
