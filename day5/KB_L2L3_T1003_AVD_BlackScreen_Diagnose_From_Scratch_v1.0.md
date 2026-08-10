# L2/L3 Knowledge Base Article: T1003 AVD Black Screen and Disconnect (POOL-FIN-01)
v 1.0, 07/08/2026, status : Draft

## Background: what the system does and why it matter
Azure Virtual Desktop (AVD) host pools provide Finance users with remote Windows sessions for business applications. During sign-in, each session host must initialize the Desktop Window Manager (DWM) and graphics stack correctly.

Why it matters:
- If DWM fails during session startup, users can receive a black screen, then disconnect/reconnect loops.
- In a pooled environment, one bad image/host cohort can affect many users quickly.
- Fast pool isolation and host comparison prevents broad service disruption.

## Symptom: what the engineer observers and what the user report
What users report:
- Black screen immediately after sign-in to Finance AVD desktop.
- Some users say black screen clears after around 30 seconds, others get disconnected.
- Reconnect loops can repeat several times before users give up.

What engineer observes:
- In POOL-FIN-01, specific hosts show unstable sessions immediately after user logon.
- In POOL-FIN-02 (comparison pool), same time window remains stable.
- Affected hosts show DWM crash and session disconnect patterns in Windows event logs.

## Root cause: the specific technical cause with the evidence that confirms it
Root cause:
- POOL-FIN-01 session hosts on the affected image baseline experience DWM crash signature where dwm.exe faults in igdumd64.dll, causing session instability and disconnect loops.

Evidence that confirms this cause:
- Event ID 1000 in Application log with all fields:
  - Faulting application name: dwm.exe
  - Faulting module name: igdumd64.dll
  - Exception code: 0xc0000005
- Event ID 9009 in Application log in the same incident window.
- Event ID 21 followed by Event ID 40 repeating in TerminalServices-LocalSessionManager Operational log.
- Comparison evidence:
  - POOL-FIN-01 affected host shows the Event ID 1000 signature and 21->40 loop.
  - POOL-FIN-02 control host in same window does not show Event ID 1000 with dwm.exe + igdumd64.dll.

## Detection: exactly how to confirm this is the issue before acting- include specific event ids, log locations and what to look for
Target outcome: confirm or rule out this incident in under 3 minutes.

Use one suspected host from POOL-FIN-01 (affected candidate) and one host from POOL-FIN-02 (unaffected control) in the same time window.

1. Identify candidate hosts quickly from Azure.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts
- Fast command (Azure CLI):
```bash
az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-01 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:sessions}" -o table
az desktopvirtualization session-host list --resource-group <RG_NAME> --host-pool-name POOL-FIN-02 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:sessions}" -o table
```
- What to capture: one busy/problem candidate in POOL-FIN-01 and one healthy control in POOL-FIN-02.

2. On the POOL-FIN-01 candidate, query Application log Event 1000 and Event 9009 in one command run.
- Exact log location: Application log (Event Viewer path: Windows Logs > Application)
- Required Event IDs: 1000 and 9009
- Fast command (PowerShell, run on that host):
```powershell
$start = (Get-Date).AddMinutes(-30)
$end   = Get-Date

# Event 1000 signature check in Application log
$ev1000 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start; EndTime=$end } |
  Where-Object {
    $_.Message -match 'Faulting application name:\s*dwm\.exe' -and
    $_.Message -match 'Faulting module name:\s*igdumd64\.dll' -and
    $_.Message -match 'Exception code:\s*0xc0000005'
  } |
  Select-Object TimeCreated, Id, ProviderName, Message

# Event 9009 check in Application log
$ev9009 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9009; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message

[pscustomobject]@{
  Host              = $env:COMPUTERNAME
  Event1000Matched  = ($ev1000.Count -gt 0)
  Event9009Present  = ($ev9009.Count -gt 0)
}

$ev1000
$ev9009
```
- Field-level confirmation for Event 1000:
  - Faulting application name = dwm.exe
  - Faulting module name = igdumd64.dll
  - Exception code = 0xc0000005
- Field-level confirmation for Event 9009:
  - Id = 9009 in Application log within same time window.

3. On the same POOL-FIN-01 host, check TerminalServices loop pattern.
- Exact log location: Microsoft-Windows-TerminalServices-LocalSessionManager/Operational (Event Viewer path: Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational)
- Required Event IDs: 21 and 40
- Fast command (PowerShell):
```powershell
$start = (Get-Date).AddMinutes(-30)
$end   = Get-Date

Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$start; EndTime=$end } |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, ProviderName, Message
```
- What to look for: repeated Event 21 followed quickly by Event 40.

4. On POOL-FIN-02 control host, run healthy baseline comparison.
- Exact log location: Application log (Event Viewer path: Windows Logs > Application)
- Required control checks:
  - Event ID 9011 present (healthy DWM baseline)
  - Event ID 1000 with dwm.exe + igdumd64.dll absent
- Fast command (PowerShell, run on POOL-FIN-02 host):
```powershell
$start = (Get-Date).AddMinutes(-30)
$end   = Get-Date

$control1000 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start; EndTime=$end } |
  Where-Object {
    $_.Message -match 'Faulting application name:\s*dwm\.exe' -and
    $_.Message -match 'Faulting module name:\s*igdumd64\.dll'
  }

$control9011 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message

[pscustomobject]@{
  Host                        = $env:COMPUTERNAME
  Event9011Present            = ($control9011.Count -gt 0)
  Event1000CrashSignatureSeen = ($control1000.Count -gt 0)
}

$control9011
```

5. Confirm this KB issue before acting.
- Confirm this is the incident only when all conditions are true:
  - POOL-FIN-01 host: Application log Event 1000 contains dwm.exe + igdumd64.dll + 0xc0000005.
  - POOL-FIN-01 host: Application log Event 9009 exists in same time window.
  - POOL-FIN-01 host: TerminalServices Operational log shows repeated Event 21->40 pattern.
  - POOL-FIN-02 host: Application log has Event 9011 baseline and no Event 1000 crash signature with igdumd64.dll.

Event IDs explicitly required in detection:
- 1000, 9009, 9011, 21, 40

## Resolution: step-by-step fix with expected result after each step - include specific portal/console paths
1. Contain affected hosts immediately.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select affected host(s) > More actions > Allow new session = Off
- Expected result: selected hosts show Allow new session = No and stop accepting new logons.

2. Confirm unaffected capacity is available.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts
- Expected result: at least one control host shows Status = Available and Allow new session = Yes.

3. Validate host evidence threshold before image action.
- Console path: Event Viewer on each candidate host
  - Windows Logs > Application (Event IDs 1000 and 9009)
  - Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational (Event IDs 21 and 40)
- Expected result: only hosts with all three signals are marked AFFECTED.

4. Reimage each affected VM to known-good baseline lineage.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select host > Virtual machine > Virtual machines > <host VM> > Operations > Reimage
- Reimage setting: OS disk only, confirm action.
- Expected result: reimage job completes and host returns running.

5. Restart reimaged VM and keep host drained.
- Azure portal path: Azure portal > Virtual machines > <host VM> > Overview > Restart
- Expected result: VM restart succeeds, host healthy, Allow new session remains Off.

6. Controlled return to service, one host at a time.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select validated host > More actions > Allow new session = On
- Expected result: single host accepts sessions without black-screen/disconnect recurrence.

7. Repeat step 4 to 6 for remaining affected hosts.
- Azure portal path: same as above for each host.
- Expected result: all remediated hosts pass verification before full pool re-open.

## Verification: how to confirm the fix worked
1. Verify no new Event ID 1000 signature after fix time.
- Log location: Event Viewer > Windows Logs > Application
- Field check: Message must not contain dwm.exe + igdumd64.dll + 0xc0000005.
- Pass result: zero new matching Event ID 1000 entries.

2. Verify no new Event ID 9009 in post-fix window.
- Log location: Event Viewer > Windows Logs > Application
- Field check: TimeCreated and Event ID.
- Pass result: no new 9009 events after remediation timestamp.

3. Verify no repeating Event 21->40 loop.
- Log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational
- Field check: ordered TimeCreated for Event IDs 21 and 40.
- Pass result: no repeated immediate 21 followed by 40 pattern.

4. Verify AVD placement and session stability.
- Azure portal path A: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
- Field check A: Status = Available, Allow new session = Yes only on validated hosts.
- Azure portal path B: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions
- Field check B: SessionState remains Connected for active users.
- Pass result: stable connected sessions, no recurrent user reports.

5. Verify control pool baseline still clean.
- Log location: Event Viewer on POOL-FIN-02 control host > Windows Logs > Application
- Event checks: Event ID 9011 present, no Event ID 1000 signature with dwm.exe + igdumd64.dll.
- Pass result: control pool remains healthy in same post-fix period.

## Rollback: what to do if the fix makes thing worse- be specific
Trigger rollback immediately if any remediated host shows Event ID 1000 signature or Event ID 9009 after fix.

1. Re-contain remediated host batch.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select rollback host set > More actions > Allow new session = Off
- Expected result: new placements stop on rollback hosts.

2. Confirm containment state.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
- Field check: Allow new session = No for each rollback host.
- Expected result: all rollback hosts drained.

3. Keep user access via control pool.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts
- Field check: at least one host with Allow new session = Yes and Status = Available.
- Expected result: users continue signing in while rollback proceeds.

4. Execute deeper rollback decision.
- Option A portal path: Azure portal > Virtual machines > <host VM> > Operations > Reimage
- Option B portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > Remove session host, then provision replacement host from known-good baseline
- Expected result: unstable host removed from active service path.

5. Document rollback evidence and freeze re-entry.
- Log location: Event Viewer > Windows Logs > Application (Event IDs 1000 and 9009, last 5-10 minutes)
- Field check: TimeCreated, Message signature fields.
- Expected result: if signature persists, keep host drained and escalate for image engineering review.

## Preventive: the specific change to process or tooling that stop this recurring
1. Implement automated image promotion gate in pre-production AVD test ring:
- Block promotion if Event ID 1000 contains dwm.exe + igdumd64.dll or if Event ID 9009 appears during soak window.

2. Enforce ring-based rollout policy for host images:
- Ring 0 pilot subset in POOL-FIN-01 equivalent.
- Ring 1 broader rollout only after clean evidence.
- Mandatory comparison check against control pool (POOL-FIN-02 equivalent) before promotion.

3. Add Azure Monitor alert rules on session hosts:
- Alert A: 2 or more matching Event ID 1000 signatures on same host in 10 minutes.
- Alert B: Event ID 9009 and Event ID 40 correlation on same host within 5 minutes.

4. Add change record guardrails:
- Change ticket must include pre-approved rollback baseline, host drain sequence, and responsible owner.

5. Add incident closure gate:
- Closure blocked until evidence pack includes log exports for Event IDs 1000, 9009, 21, 40 and control comparison against POOL-FIN-02.

## Related: other incidents or KB article this connects to
- Runbook: day5/runbook_T1003_AVD_BlackScreen_POOL-FIN-01.md
- Existing KB version: day5/KB_L2L3_T1003_AVD_BlackScreen_Diagnose_From_Scratch.md
- RCA: day4/RCA_T1003_AVD_BlackScreen_POOL-FIN-01.md
- Triage: day4/triage_T1003_avd_disconnect.md
- L1 article: day5/L1_self_service_login_black_screen_article.md