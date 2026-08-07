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

## Addendum - Incident Evidence Review (Black Screen, POOL-FIN-01)

### New event details reviewed
- Affected host: SHFIN-01-A (POOL-FIN-01)
- Time window: 2024-03-15 07:00 to 07:30
- Key sequence observed:
	- 07:02:10, Event 21: Session logon succeeded (mlopez)
	- 07:02:14, Kernel-General Event 1: Host booted at 02:03:11 after overnight image update
	- 07:02:16, Application Error Event 1000: dwm.exe faulting module igdumd64.dll, exception 0xc0000005
	- 07:02:17, Event 40: Session disconnected
	- 07:02:18, DWM Event 9009: Desktop Window Manager exited
	- 07:02:44, Event 21: Reconnect logon succeeded
	- 07:02:46, Application Error Event 1000: repeat dwm.exe fault in igdumd64.dll
	- 07:02:47, Event 40: Session disconnected again
	- 07:03:01, DWM Event 9009: DWM exited again
	- 07:03:10, Event 21: Second reconnect succeeded
	- 07:08:24, Application Error Event 1000: same dwm.exe and igdumd64.dll fault for another user
- Unaffected comparison host: SHFIN-02-A (POOL-FIN-02, pre-update image)
	- 07:01:44, Event 21: Session logon succeeded
	- 07:01:46, DWM Event 9011: Desktop Window Manager started successfully
	- No Application Error Event 1000 in the same window

### Reviewed hypotheses against evidence

1. Image-level regression introduced in POOL-FIN-01 overnight update
- Judgement: Supports
- Determining events: Kernel-General Event 1 at 07:02:14 on SHFIN-01-A (post-update boot), plus repeated Event 1000 and Event 9009 on updated host only.

2. Startup sequence delay from new image (shell or GPO or AppReadiness)
- Judgement: Contradicts
- Determining events: Event 21 at 07:02:10 followed by crash chain (Event 1000 at 07:02:16, Event 40 at 07:02:17). This indicates crash-disconnect, not only delayed shell readiness.

3. FSLogix or profile attach issue
- Judgement: Neutral
- Determining events: No FSLogix-specific events in provided extract; evidence shown is primarily DWM and graphics-module crash events.

4. Host subset mismatch inside POOL-FIN-01
- Judgement: Neutral
- Determining events: Evidence confirms one bad host in POOL-FIN-01 and one good host in POOL-FIN-02, but does not yet prove or disprove intra-pool subset drift within POOL-FIN-01.

5. Graphics or display pipeline issue introduced with update
- Judgement: Strongly supports
- Determining events: Event 1000 at 07:02:16 and 07:02:46 (dwm.exe faulting igdumd64.dll), Event 9009 at 07:02:18 and 07:03:01 (DWM exit), and Event 40 disconnects immediately after logon.

### Surviving hypothesis after elimination
Graphics and display pipeline regression introduced by the overnight POOL-FIN-01 image update, with DWM crashing in igdumd64.dll and triggering session disconnect or black-screen behavior.

### Detailed resolution steps

1. Immediate containment
- Drain affected POOL-FIN-01 hosts and temporarily route users to unaffected capacity.
- Pause new session placement on hosts showing the crash signature.

2. Scope and confirm
- On each POOL-FIN-01 host, check for crash signature in incident window:
	- Application Error Event 1000: dwm.exe with igdumd64.dll
	- DWM Event 9009
	- LSM Event 40 shortly after Event 21
- Group hosts into affected and clean cohorts.

3. Fast restoration
- Revert affected pool to the last known good image baseline used by unaffected hosts.
- Reimage or replace affected session hosts from the known-good image.

4. Tactical mitigation if rollback is delayed
- Roll back or pin Intel graphics driver to previously known stable version.
- Apply temporary graphics acceleration mitigation per platform standard.
- Reboot hosts and retest with both previously persistent and self-clearing users.

5. Validation gates before reopening host placement
- Run repeated login tests on remediated hosts.
- Confirm zero recurrence of Event 1000 (dwm.exe/igdumd64.dll) and Event 9009 during soak period.
- Confirm no repeated Event 21 to Event 40 loop pattern.

6. Controlled reintroduction
- Return remediated hosts to service in small batches.
- Monitor disconnect and black-screen indicators at short intervals during initial hours.

7. Preventive controls
- Add a pre-production validation ring for new images with graphics-path smoke tests.
- Block image promotion if DWM crash signature appears during soak.
- Maintain a tested rollback playbook for host pool image regression incidents.
