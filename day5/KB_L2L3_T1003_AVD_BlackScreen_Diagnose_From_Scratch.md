# L2/L3 Knowledge Base - T-1003 AVD Black Screen and Disconnect (POOL-FIN-01)

## Background
Azure Virtual Desktop (AVD) host pools provide Finance users with virtual Windows sessions for line-of-business access. During sign-in, the graphics stack and Desktop Window Manager (DWM) must initialize correctly on the session host.

Why this matters:
- If DWM crashes during session initialization, users can get a black screen, repeated disconnects, or unstable reconnect loops.
- Pool-wide impact can be high because multiple users are scheduled to the same host pool.
- Fast isolation is critical to protect user productivity and prevent wider blast radius.

## Symptom
What the user reports:
- Black screen immediately after sign-in to Finance desktop.
- For some users, screen clears after ~30 seconds; for others, session disconnects and reconnects repeatedly.
- Users may say they are locked out of desktop access, even though credentials are valid.

What the engineer observes:
- In POOL-FIN-01, affected hosts show repeated session instability shortly after logon.
- In host logs, pattern appears as logon success followed by DWM/application crash and session disconnect.
- POOL-FIN-02 remains stable in the same time window.

## Root Cause
Specific technical cause:
- A graphics/display regression on updated POOL-FIN-01 hosts causes dwm.exe to crash in Intel graphics module igdumd64.dll (access violation), leading to black-screen and disconnect loops.

Evidence that confirms root cause:
- Windows Logs > Application, Event ID 1000 on affected hosts:
  - Field Faulting application name = dwm.exe
  - Field Faulting module name = igdumd64.dll
  - Field Exception code = 0xc0000005
- Windows Logs > Application, Event ID 9009 in same window:
  - DWM exit events align with crashes.
- Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational:
  - Event ID 21 (logon success) immediately followed by Event ID 40 (disconnect), repeating.
- Comparison check:
  - POOL-FIN-02 host in same window does not show Event ID 1000 with dwm.exe + igdumd64.dll.

## Detection
Goal: confirm this specific incident in under 3 minutes before remediation.

### Step D1 - Identify one affected and one control host fast
Azure portal path:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts

Pick:
- One suspected affected host from POOL-FIN-01.
- One known healthy control host from POOL-FIN-02.

### Step D2 - Run command-first checks on POOL-FIN-01 (affected candidate)
Exact log location required:
- Application log (Event Viewer path: Windows Logs > Application)

PowerShell (run on the affected host or via remote session):
```powershell
# Set the incident window (example)
$start = Get-Date '2024-03-15 07:00:00'
$end   = Get-Date '2024-03-15 07:30:00'

# Event 1000 from Application log with required fields
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' -and $_.Message -match 'Exception code:\s*0xc0000005' }

# Event 9009 from Application log in same window
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9009; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message
```

What confirms POOL-FIN-01 is affected:
- Event ID 1000 exists in Application log with:
  - Faulting application name = dwm.exe
  - Faulting module name = igdumd64.dll
  - Exception code = 0xc0000005
- Event ID 9009 exists in Application log in the same time window.

### Step D3 - Confirm 21 -> 40 session loop on the same affected host
Exact log location:
- Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational

PowerShell:
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$start; EndTime=$end } |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, ProviderName, Message
```

What confirms loop behavior:
- Repeating Event ID 21 (logon succeeded) followed quickly by Event ID 40 (session disconnected).

### Step D4 - Run healthy baseline comparison on POOL-FIN-02 (control)
Exact log location required:
- Application log (Event Viewer path: Windows Logs > Application)

PowerShell (run on control host):
```powershell
# Event 1000 crash signature should be absent on control
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' }

# Event 9011 healthy baseline expected on control
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=$start; EndTime=$end } |
  Select-Object TimeCreated, Id, ProviderName, Message
```

Healthy baseline definition (POOL-FIN-02):
- Event ID 9011 present (DWM started successfully baseline).
- No Event ID 1000 with dwm.exe + igdumd64.dll in same window.

### Step D5 - Optional Azure CLI host pull (faster host targeting)
Use this to quickly pick active session hosts before log checks.

Azure CLI:
```bash
# POOL-FIN-01 session hosts
az desktopvirtualization session-host list \
  --resource-group <RG_NAME> \
  --host-pool-name POOL-FIN-01 \
  --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:sessions}" -o table

# POOL-FIN-02 session hosts (control)
az desktopvirtualization session-host list \
  --resource-group <RG_NAME> \
  --host-pool-name POOL-FIN-02 \
  --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:sessions}" -o table
```

### Detection confirmation criteria
Confirm this KB issue only when all conditions are true:
- Application log Event ID 1000 on POOL-FIN-01 host contains dwm.exe + igdumd64.dll + 0xc0000005.
- Application log Event ID 9009 appears in same window on that POOL-FIN-01 host.
- LSM Operational log shows repeated 21 -> 40 loop on that POOL-FIN-01 host.
- POOL-FIN-02 control host shows Event ID 9011 baseline and does not show Event ID 1000 with dwm.exe + igdumd64.dll.

Event IDs explicitly required in detection:
- 1000, 9009, 9011, 21, 40

## Resolution
Target completion: 5 to 10 minutes for containment + first-host recovery.

### Step R1 - Fast containment on affected pool
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select affected host(s) > More actions > Allow new session = Off

Fast command option (PowerShell - Az.DesktopVirtualization):
```powershell
# Prereq: Connect-AzAccount
$rg = '<RG_NAME>'
$pool = 'POOL-FIN-01'
$affectedHosts = @('SHFIN-01-A.contoso.local')

foreach ($h in $affectedHosts) {
  Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name $h -AllowNewSession:$false
}
```

Expected result:
- Affected hosts show Allow new session = No and stop receiving new logons.

### Step R2 - Keep service live on unaffected control pool
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > verify at least one host shows Allow new session = Yes and Status = Available

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$controlPool = 'POOL-FIN-02'
Get-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $controlPool |
  Select-Object Name, AllowNewSession, Status
```

Expected result:
- At least one healthy control host can accept users immediately.

### Step R3 - Confirm affected-host evidence threshold before image action
Required evidence on each POOL-FIN-01 host:
- Application log Event ID 1000 contains dwm.exe + igdumd64.dll + 0xc0000005
- Application log Event ID 9009 present in same time window
- LSM Operational log shows 21 -> 40 loop

Fast command option (run on each candidate host):
```powershell
$start = Get-Date '2024-03-15 07:00:00'
$end   = Get-Date '2024-03-15 07:30:00'

$sig1000 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start; EndTime=$end } |
  Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' -and $_.Message -match 'Exception code:\s*0xc0000005' }

$sig9009 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9009; StartTime=$start; EndTime=$end }

$sig2140 = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$start; EndTime=$end }

[pscustomobject]@{
  Has1000Signature = ($sig1000.Count -gt 0)
  Has9009          = ($sig9009.Count -gt 0)
  Has2140          = ($sig2140.Count -gt 0)
}
```

Expected result:
- Only hosts meeting all three signals are marked AFFECTED.

### Step R4 - Reimage affected session host VM(s) to known-good baseline
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > click host name (for example SHFIN-01-A) > Virtual machine
- Then: Azure portal > Virtual machines > SHFIN-01-A > Operations > Reimage
- In Reimage pane: Reimage type = OS disk only, Confirm = Yes, click Reimage

Fast command option (Azure CLI):
```bash
az vm reimage --resource-group <RG_NAME> --name SHFIN-01-A
```

Expected result:
- Reimage job completes and VM returns to running state on known-good image lineage.

### Step R5 - Restart host and keep pool controlled
Exact Azure portal path and option:
- Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart
- Keep Allow new session = Off until verification passes.

Fast command option (Azure CLI):
```bash
az vm restart --resource-group <RG_NAME> --name SHFIN-01-A
```

Expected result:
- Host is healthy but still drained from new placements.

### Step R6 - Controlled re-entry (one host at a time)
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select remediated host > More actions > Allow new session = On

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$pool = 'POOL-FIN-01'
$host = 'SHFIN-01-A.contoso.local'
Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name $host -AllowNewSession:$true
```

Expected result:
- One remediated host takes sessions without immediate black-screen/disconnect recurrence.

## Verification
Confirm all checks on the same remediated host before opening additional hosts.

### Step V1 - Verify no recurring crash signature in Application log
Exact log location:
- Event Viewer > Windows Logs > Application

Fast command option (PowerShell):
```powershell
$fixTime = (Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$fixTime } |
  Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' }
```

Pass criteria:
- No output returned for Event 1000 signature.

### Step V2 - Verify no new Event 9009 after fix
Exact log location:
- Event Viewer > Windows Logs > Application

Fast command option (PowerShell):
```powershell
$fixTime = (Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9009; StartTime=$fixTime } |
  Select-Object TimeCreated, Id, ProviderName
```

Pass criteria:
- No new Event 9009 entries after remediation timestamp.

### Step V3 - Verify no repeat 21 -> 40 disconnect loop
Exact log location:
- Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational

Fast command option (PowerShell):
```powershell
$fixTime = (Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$fixTime } |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, Message
```

Pass criteria:
- No repeating immediate 21 then 40 pattern.

### Step V4 - Verify AVD host and session state in POOL-FIN-01
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
  - Option: Allow new session = Yes only on validated host
  - Option: Status = Available
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions
  - Option: SessionState = Connected

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$pool = 'POOL-FIN-01'
Get-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool |
  Select-Object Name, Status, AllowNewSession
Get-AzWvdUserSession -ResourceGroupName $rg -HostPoolName $pool |
  Select-Object Name, SessionState, UserPrincipalName
```

Pass criteria:
- Validated hosts are Available, AllowNewSession is controlled, and sessions remain Connected.

### Step V5 - Control host baseline check remains healthy (POOL-FIN-02)
Exact log location:
- Event Viewer > Windows Logs > Application on one POOL-FIN-02 host

Fast command option (PowerShell):
```powershell
$fixTime = (Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=$fixTime } |
  Select-Object TimeCreated, Id, ProviderName, Message
```

Pass criteria:
- Event 9011 continues to appear on control host and no instability is observed.

## Rollback
If any remediated host shows Event 1000 signature or Event 9009 again, execute rollback immediately.

### Step RB1 - Immediate re-containment of remediated batch
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select rollback host set > More actions > Allow new session = Off

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$pool = 'POOL-FIN-01'
$rollbackHosts = @('SHFIN-01-A.contoso.local')
foreach ($h in $rollbackHosts) {
  Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name $h -AllowNewSession:$false
}
```

Expected result:
- New user placement stops on rollback hosts within minutes.

### Step RB2 - Confirm rollback containment state
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
  - Option: Allow new session must show No for each rollback host

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$pool = 'POOL-FIN-01'
Get-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool |
  Select-Object Name, AllowNewSession, Status
```

Expected result:
- All rollback hosts are drained.

### Step RB3 - Keep service active on control pool
Exact Azure portal path and option:
- Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts
  - Option: At least one host Allow new session = Yes

Fast command option (PowerShell):
```powershell
$rg = '<RG_NAME>'
$controlPool = 'POOL-FIN-02'
Get-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $controlPool |
  Select-Object Name, AllowNewSession, Status
```

Expected result:
- Users continue signing in via unaffected capacity.

### Step RB4 - Decide next rollback depth (host reimage repeat vs host replacement)
Exact Azure portal path and options:
- Azure portal > Virtual machines > <rollback host VM> > Operations > Reimage
- If repeated reimage fails: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > Remove session host, then provision replacement host from known-good baseline

Fast command options (Azure CLI):
```bash
# Repeat reimage for failed remediated host
az vm reimage --resource-group <RG_NAME> --name <VM_NAME>

# Optional hard rollback action if needed
az vm delete --resource-group <RG_NAME> --name <VM_NAME> --yes
```

Expected result:
- Faulty host is removed from active service path; clean host path restored.

### Step RB5 - Validate rollback trigger evidence and document
Exact log location:
- Event Viewer > Windows Logs > Application (Event IDs 1000 and 9009, last 5 to 10 minutes)

Fast command option (PowerShell):
```powershell
$start = (Get-Date).AddMinutes(-10)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000,9009; StartTime=$start } |
  Select-Object TimeCreated, Id, ProviderName, Message
```

Expected result:
- If signature persists, keep hosts drained and continue rollback path.
- Incident notes capture timestamp, operator, host list, and rollback reason.

## Preventive
Specific process and tooling changes to prevent recurrence:
1. Add image promotion gate for AVD host pools requiring automated checks for:
- Event ID 1000 with fields Faulting application name=dwm.exe and Faulting module name=igdumd64.dll
- Event ID 9009
- Repeated Event ID 21 -> 40 loops
2. Enforce ringed rollout:
- Pilot subset in POOL-FIN-01 equivalent
- Comparison validation against control pool (POOL-FIN-02)
- Promotion blocked if any signature appears during first business-hour soak.
3. Add alert rules in monitoring pipeline:
- Burst alert when >=2 Event ID 1000 signature matches on same host in 10 minutes.
- Correlation alert when Event ID 9009 and 21->40 loop occur on same host within 5 minutes.
4. Update change checklist to require explicit rollback target baseline and host drain plan before image deployment.
5. Require post-change evidence capture template with exact log paths and fields listed in Detection section.

## Related
- Runbook: day5/runbook_T1003_AVD_BlackScreen_POOL-FIN-01.md
- RCA: day4/RCA_T1003_AVD_BlackScreen_POOL-FIN-01.md
- Triage analysis: day4/triage_T1003_avd_disconnect.md
- Communications pack: day4/audience_communications_T1003.md
