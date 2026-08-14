# Version Header
- Document: L2 Technical Article - Floor 6 App Ring Containment and Rollback
- Version: 1.0
- Date: 2026-08-14
- Source Runbook: runbook_floor6_app_deployment_rollback_v1.0

# Scope
Technical execution guide for next occurrence of Floor 6 login and desktop instability linked to rollout ring assignment.

# Trigger Conditions
1. Multiple Floor 6 users report login failure/slow login.
2. Desktop shortcut anomalies appear in same change window.
3. Recent app rollout to Floor 6 pilot ring is confirmed.

# Prerequisites
1. Change approval for containment/rollback.
2. Graph scopes: DeviceManagementApps.ReadWrite.All, Group.ReadWrite.All, Directory.Read.All.
3. Confirmed group and app identifiers.
4. Incident channel and comms owner active.

# Execution Procedure
1. Connect Graph and resolve objects.
Expected result: impacted group, pilot ring group, and app each resolve uniquely.

2. Snapshot memberships before change.
Expected result: JSON/CSV snapshot files created with timestamp.

3. Remove impacted devices from pilot ring.
Expected result: impacted devices are no longer ring members.

4. Remove/disable Required install assignment to pilot ring.
Expected result: rollout pressure removed from affected cohort.

5. Assign Uninstall intent to impacted group.
Expected result: rollback deployment enters pending/in-progress state.

6. Trigger device sync and observe assignment state transitions.
Expected result: status moves toward success on targeted devices.

7. Validate user outcome on sample set.
Expected result: sign-in success and desktop behavior normalization trend.

# Command Set
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.ReadWrite.All","Directory.Read.All"

$floor6GroupName = "GRP-Floor6-Impacted-Devices"      # to confirm
$pilotRingGroupName = "GRP-App-Pilot-Floor6"          # to confirm
$appDisplayName = "Document Management App"            # to confirm

$floor6Group = Get-MgGroup -Filter "displayName eq '$floor6GroupName'"
$pilotRingGroup = Get-MgGroup -Filter "displayName eq '$pilotRingGroupName'"
$app = Get-MgDeviceAppManagementMobileApp -All | Where-Object { $_.DisplayName -eq $appDisplayName }

if ((@($floor6Group).Count -ne 1) -or (@($pilotRingGroup).Count -ne 1) -or (@($app).Count -ne 1)) {
    throw "Object resolution failed or ambiguous."
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$affectedMembers = Get-MgGroupMember -GroupId $floor6Group.Id -All |
    Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.device' }

$affectedMembers | ConvertTo-Json -Depth 6 | Out-File ".\floor6_affected_members_$ts.json"

foreach ($m in $affectedMembers) {
    try {
        Remove-MgGroupMemberByRef -GroupId $pilotRingGroup.Id -DirectoryObjectId $m.Id -ErrorAction Stop
        Write-Host "Removed from pilot ring: $($m.Id)"
    } catch {
        Write-Warning "Failed removing $($m.Id): $($_.Exception.Message)"
    }
}
```

# Verification Checklist
1. Membership diff confirms affected devices removed from pilot ring.
2. Assignment view confirms uninstall/rollback targeting active.
3. Endpoint checks show improved login success and reduced delay.
4. Incident metrics show no new accelerated failure trend (threshold to confirm).

# Rollback of This Change
1. Restore prior pilot ring membership from pre-change snapshot.
2. Remove uninstall assignment added during incident.
3. Re-enable prior required assignment only after CAB/owner approval.
4. Continue monitoring for recurrence for agreed observation period (to confirm duration).

# Escalation Boundary
If Copilot restricted-file allegation is present, treat as parallel security/governance track and do not close until that validation is complete.
