# Analysis: Ranked Likely Causes of Finance-Win11 Startup Performance Drop

## Scope Basis Used for Ranking
- Change was deployed only to Finance-Win11 at 2026-08-04 02:00.
- Startup score dropped immediately on 2026-08-04 (84 to 61) and remained degraded.
- IT-Win11 (not targeted by the change) stayed stable.

## Ranked Top 3 Most Likely Causes

### 1) Added startup compliance logging script is extending logon path
Why it fits:
- Timing alignment is exact: degradation starts the same day as deployment.
- Scope alignment is exact: only the changed group (Finance-Win11) degraded; unchanged group did not.
- Mechanism fit: startup scripts run in the startup/logon path and can directly increase time to usable desktop.
Fastest check:
- On 3 to 5 affected Finance devices, temporarily disable only the new startup script assignment for one policy refresh cycle and compare next startup median against unchanged peers.

### 2) Additional Defender scan policy is triggering early-session scan load
Why it fits:
- Timing and scope match the same deployment event to Finance-Win11 only.
- Unaffected comparison group stability is consistent with a policy-specific effect rather than platform-wide regression.
- Mechanism fit: aggressive or newly scheduled scan activity can increase CPU/disk contention during startup.
Fastest check:
- Compare Defender operational logs and CPU/disk utilization during first 5 to 10 minutes after login on affected Finance devices; then A/B one pilot subset with scan policy setting rolled back and check startup delta next boot.

### 3) Combined policy interaction from the new security baseline (script + Defender) causing cumulative delay
Why it fits:
- Both changes were introduced together at one timestamp, and the impact was immediate and sustained.
- Clean control group with no change argues for a deployment-bound effect, potentially additive rather than single-setting.
- Magnitude jump suggests more than minor overhead, which can occur when multiple startup-time controls stack.
Fastest check:
- Perform a two-step isolation in a small pilot ring: first remove script only, then restore script and remove Defender addition, measuring startup each step; if partial improvement appears in both steps, cumulative interaction is confirmed.
