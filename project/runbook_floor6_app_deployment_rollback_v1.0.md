# Version Header
- Document: Runbook - Floor 6 App Deployment Containment and Rollback
- Version: 1.0
- Date: 2026-08-14
- Owner: EUC Operations (to confirm)
- Source Scope: Section 4 fix path from incident triage and resolution set

# Purpose
Restore Floor 6 login and desktop stability by removing impacted devices from the rollout ring and applying an app rollback/uninstall assignment.

# Prerequisites
1. Incident approved for containment/rollback by change authority (to confirm approver).
2. Microsoft Graph PowerShell available on admin workstation.
3. RBAC permissions:
- DeviceManagementApps.ReadWrite.All
- Group.ReadWrite.All
- Directory.Read.All
4. Confirmed object names/IDs:
- Impacted device group (Floor 6)
- Pilot rollout ring group
- Target app display name and app ID
5. Communication owner assigned for Floor 6 status updates.

# Numbered Procedure
1. Connect to Microsoft Graph with required scopes.
Expected result: Session connects successfully and token scopes include app/device/group write rights.

2. Resolve the impacted group, pilot ring group, and app object.
Expected result: All three objects return exactly one match each; if multiple or none, stop and correct identifiers.

3. Export current pilot ring membership and impacted group membership to CSV.
Expected result: Two timestamped CSV snapshots exist for audit and rollback reference.

4. Remove impacted Floor 6 devices from the pilot ring group.
Expected result: Remove operations succeed per device; failures are logged with reason.

5. Remove or disable Required install assignment for the pilot ring (if still active).
Expected result: No active Required install intent remains for the pilot ring target.

6. Add Uninstall assignment for impacted group (or approved rollback deployment model).
Expected result: Uninstall/rollback assignment is visible and targeted to impacted devices.

7. Trigger policy/app sync on impacted endpoints.
Expected result: Devices begin check-in; assignment status starts transitioning from pending.

8. Send controlled status note to Floor 6 and leadership.
Expected result: Users receive reassurance and current actions without an unvalidated ETA.

# Reference Command Block (Microsoft Graph PowerShell)
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.ReadWrite.All","Directory.Read.All"

$floor6GroupName = "GRP-Floor6-Impacted-Devices"      # to confirm
$pilotRingGroupName = "GRP-App-Pilot-Floor6"          # to confirm
$appDisplayName = "Document Management App"            # to confirm

$floor6Group = Get-MgGroup -Filter "displayName eq '$floor6GroupName'"
$pilotRingGroup = Get-MgGroup -Filter "displayName eq '$pilotRingGroupName'"
$app = Get-MgDeviceAppManagementMobileApp -All | Where-Object { $_.DisplayName -eq $appDisplayName }

if (-not $floor6Group -or -not $pilotRingGroup -or -not $app) {
    throw "Required object lookup failed. Confirm names/IDs."
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$pilotMembers = Get-MgGroupMember -GroupId $pilotRingGroup.Id -All
$affectedMembers = Get-MgGroupMember -GroupId $floor6Group.Id -All |
    Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.device' }

$pilotMembers | ConvertTo-Json -Depth 6 | Out-File ".\pilot_ring_members_$ts.json"
$affectedMembers | ConvertTo-Json -Depth 6 | Out-File ".\floor6_affected_members_$ts.json"

foreach ($m in $affectedMembers) {
    try {
        Remove-MgGroupMemberByRef -GroupId $pilotRingGroup.Id -DirectoryObjectId $m.Id -ErrorAction Stop
        Write-Host "Removed from pilot ring: $($m.Id)"
    } catch {
        Write-Warning "Failed removing $($m.Id): $($_.Exception.Message)"
    }
}

# Assignment rollback actions are tenant/app-type specific.
# Implement approved pattern:
# 1) remove/disable Required install assignment for pilot ring
# 2) add Uninstall assignment for impacted group
# Then monitor assignment state in Intune admin center.
```

# Verification
1. Group verification:
- Impacted device IDs are no longer members of pilot ring group.
2. Assignment verification:
- Required assignment to pilot ring is removed/disabled.
- Uninstall/rollback assignment is present for impacted group.
3. Endpoint verification:
- Test sample users can sign in successfully.
- Login duration and desktop behavior improve against incident baseline.
4. Monitoring verification:
- No new surge of Floor 6 login failures in the active window (to confirm threshold).

# Rollback (of this fix)
1. Re-import pilot ring membership from pre-change snapshot.
Expected result: Devices are restored to prior pilot membership set.

2. Revert assignment changes:
- Remove uninstall assignment added during containment.
- Re-enable prior required assignment only after change review approval.
Expected result: Original deployment posture is restored.

3. Announce rollback completion and keep incident monitoring active.
Expected result: Stakeholders informed; service trend observed for recurrence.

# Notes
- This runbook does not close the Copilot data-access allegation; that remains a security/governance validation track.
- Record all actions with timestamps in the incident timeline.
