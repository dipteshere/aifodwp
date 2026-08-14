[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [DateTime]$IncidentStart = (Get-Date).AddDays(-3),

    [Parameter(Mandatory = $false)]
    [DateTime]$IncidentEnd = (Get-Date),

    [Parameter(Mandatory = $false)]
    [string]$OutputRoot = "$env:ProgramData\Floor6Evidence",

    [Parameter(Mandatory = $false)]
    [string]$DeploymentAppName = "document management",

    [Parameter(Mandatory = $false)]
    [string]$UserDesktopPath = "$env:USERPROFILE\Desktop",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Safely {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Script
    )

    try {
        [PSCustomObject]@{
            Name = $Name
            Success = $true
            Data = (& $Script)
            Error = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Name = $Name
            Success = $false
            Data = $null
            Error = $_.Exception.Message
        }
    }
}

function Get-RegistryInstalledApps {
    param([string[]]$Paths)

    $apps = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $apps += Get-ChildItem -LiteralPath $path -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
                }
                catch {
                    $null
                }
            } |
            Where-Object { $_ -and $_.DisplayName }
    }

    $apps |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, PSPath |
        Sort-Object DisplayName -Unique
}

function Get-EventSlice {
    param(
        [Parameter(Mandatory = $true)][string]$LogName,
        [int[]]$Ids,
        [DateTime]$Start,
        [DateTime]$End,
        [int]$Max = 300
    )

    $filter = @{
        LogName = $LogName
        StartTime = $Start
        EndTime = $End
    }

    if ($Ids -and $Ids.Count -gt 0) {
        $filter.Id = $Ids
    }

    Get-WinEvent -FilterHashtable $filter -MaxEvents $Max -ErrorAction Stop |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$caseFolder = Join-Path -Path $OutputRoot -ChildPath ("Floor6_PostChange_{0}_{1}" -f $env:COMPUTERNAME, $timestamp)
if (-not $DryRun) {
    New-Item -Path $caseFolder -ItemType Directory -Force | Out-Null
}

$results = @()

$results += Invoke-Safely -Name "collection_context" -Script {
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        CollectedBy = "$env:USERDOMAIN\$env:USERNAME"
        CollectedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        IncidentStartUtc = $IncidentStart.ToUniversalTime().ToString("o")
        IncidentEndUtc = $IncidentEnd.ToUniversalTime().ToString("o")
        Hypothesis = "Post-change regression after Windows 11 update and Friday app deployment, potentially affecting logon/profile behavior and access controls."
    }
}

$results += Invoke-Safely -Name "device_identity" -Script {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $bios = Get-CimInstance -ClassName Win32_BIOS

    [PSCustomObject]@{
        DeviceName = $env:COMPUTERNAME
        Domain = $cs.Domain
        PartOfDomain = $cs.PartOfDomain
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        UserName = $cs.UserName
        OSName = $os.Caption
        OSVersion = $os.Version
        BuildNumber = $os.BuildNumber
        LastBootUpTime = $os.LastBootUpTime
        BIOSVersion = ($bios.SMBIOSBIOSVersion -join ";")
        SerialNumber = $bios.SerialNumber
    }
}

$results += Invoke-Safely -Name "aad_join_status" -Script {
    $dsreg = & dsregcmd /status 2>&1
    $dsreg
}

$results += Invoke-Safely -Name "hotfixes" -Script {
    Get-HotFix |
        Select-Object HotFixID, Description, InstalledBy, InstalledOn |
        Sort-Object InstalledOn -Descending
}

$results += Invoke-Safely -Name "windows_update_events" -Script {
    Get-EventSlice -LogName "Microsoft-Windows-WindowsUpdateClient/Operational" -Ids @(19,20,21,43,44) -Start $IncidentStart -End $IncidentEnd -Max 500
}

$results += Invoke-Safely -Name "deployment_related_apps" -Script {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $allApps = Get-RegistryInstalledApps -Paths $regPaths
    $allApps | Where-Object {
        $_.DisplayName -match [Regex]::Escape($DeploymentAppName) -or
        $_.Publisher -match [Regex]::Escape($DeploymentAppName)
    }
}

$results += Invoke-Safely -Name "all_installed_apps_sample" -Script {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    Get-RegistryInstalledApps -Paths $regPaths | Select-Object -First 300
}

$results += Invoke-Safely -Name "logon_failures_security" -Script {
    Get-EventSlice -LogName "Security" -Ids @(4625) -Start $IncidentStart -End $IncidentEnd -Max 400
}

$results += Invoke-Safely -Name "logon_success_security" -Script {
    Get-EventSlice -LogName "Security" -Ids @(4624) -Start $IncidentStart -End $IncidentEnd -Max 400
}

$results += Invoke-Safely -Name "user_profile_service_events" -Script {
    Get-EventSlice -LogName "Application" -Start $IncidentStart -End $IncidentEnd -Max 500 |
        Where-Object { $_.ProviderName -eq "Microsoft-Windows-User Profiles Service" }
}

$results += Invoke-Safely -Name "group_policy_events" -Script {
    Get-EventSlice -LogName "Microsoft-Windows-GroupPolicy/Operational" -Ids @(4000,4001,4002,5312,5313,7016,7320,7326,8000,8001) -Start $IncidentStart -End $IncidentEnd -Max 600
}

$results += Invoke-Safely -Name "boot_logon_perf_events" -Script {
    Get-EventSlice -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -Ids @(100,101,102,103,200,201,202,203) -Start $IncidentStart -End $IncidentEnd -Max 600
}

$results += Invoke-Safely -Name "desktop_shortcuts_current_user" -Script {
    if (-not (Test-Path -LiteralPath $UserDesktopPath)) {
        return @()
    }

    Get-ChildItem -LiteralPath $UserDesktopPath -File -Force -ErrorAction SilentlyContinue |
        Select-Object Name, FullName, Extension, LastWriteTimeUtc, CreationTimeUtc, Attributes
}

$results += Invoke-Safely -Name "desktop_shortcuts_public" -Script {
    $publicDesktop = "$env:PUBLIC\Desktop"
    if (-not (Test-Path -LiteralPath $publicDesktop)) {
        return @()
    }

    Get-ChildItem -LiteralPath $publicDesktop -File -Force -ErrorAction SilentlyContinue |
        Select-Object Name, FullName, Extension, LastWriteTimeUtc, CreationTimeUtc, Attributes
}

$results += Invoke-Safely -Name "onedrive_client_state" -Script {
    $paths = @(
        "HKCU:\SOFTWARE\Microsoft\OneDrive",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    )

    $data = @()
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            $data += Get-ItemProperty -LiteralPath $path | Select-Object *
        }
    }
    $data
}

$results += Invoke-Safely -Name "network_identity" -Script {
    [PSCustomObject]@{
        IPConfiguration = (Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer)
        DNSClientCacheSample = (Get-DnsClientCache | Select-Object -First 80)
    }
}

$results += Invoke-Safely -Name "incident_note_template" -Script {
    [PSCustomObject]@{
        CopilotPromptUsed = "to_confirm"
        CopilotResponseSnippet = "to_confirm"
        ReportedMatterIdentifier = "to_confirm"
        ReportedByUser = "$env:USERDOMAIN\$env:USERNAME"
        ValidationOutsideCopilot = "to_confirm"
        EffectivePermissionOwnerReview = "to_confirm"
        Notes = "Capture from witness and security team. This script cannot validate cloud ACL truth on its own."
    }
}

foreach ($entry in $results) {
    if ($DryRun) {
        continue
    }

    $safeName = ($entry.Name -replace "[^a-zA-Z0-9_\-]", "_")
    $outFile = Join-Path -Path $caseFolder -ChildPath ("{0}.json" -f $safeName)
    $entry | ConvertTo-Json -Depth 8 | Out-File -FilePath $outFile -Encoding utf8
}

# Build an action-oriented rollup to guide next responders.
$findings = [ordered]@{
    TopRankedCause = "Post-change regression after Windows 11 update and Friday app deployment"
    EvidenceConfidence = "to_confirm"
    HighPriorityFlags = @()
    SuggestedActions = @()
}

$failedCollectors = $results | Where-Object { -not $_.Success }
if ($failedCollectors.Count -gt 0) {
    $findings.HighPriorityFlags += "One or more evidence collectors failed; rerun script as local admin and verify event log permissions."
}

$logonFailureCollector = $results | Where-Object Name -eq "logon_failures_security"
$profileCollector = $results | Where-Object Name -eq "user_profile_service_events"
$gpoCollector = $results | Where-Object Name -eq "group_policy_events"
$deploymentCollector = $results | Where-Object Name -eq "deployment_related_apps"
$perfCollector = $results | Where-Object Name -eq "boot_logon_perf_events"

$logonFailureCount = 0
if ($logonFailureCollector -and $logonFailureCollector.Success -and $logonFailureCollector.Data) {
    $logonFailureCount = @($logonFailureCollector.Data).Count
}

$profileEventCount = 0
if ($profileCollector -and $profileCollector.Success -and $profileCollector.Data) {
    $profileEventCount = @($profileCollector.Data).Count
}

$gpoEventCount = 0
if ($gpoCollector -and $gpoCollector.Success -and $gpoCollector.Data) {
    $gpoEventCount = @($gpoCollector.Data).Count
}

$deploymentHitCount = 0
if ($deploymentCollector -and $deploymentCollector.Success -and $deploymentCollector.Data) {
    $deploymentHitCount = @($deploymentCollector.Data).Count
}

$perfEventCount = 0
if ($perfCollector -and $perfCollector.Success -and $perfCollector.Data) {
    $perfEventCount = @($perfCollector.Data).Count
}

if ($logonFailureCount -gt 0) {
    $findings.HighPriorityFlags += "Security log contains $logonFailureCount failed logons in the incident window."
}

if ($profileEventCount -gt 0) {
    $findings.HighPriorityFlags += "User Profiles Service emitted $profileEventCount profile-related events in the incident window."
}

if ($gpoEventCount -gt 0) {
    $findings.HighPriorityFlags += "Group Policy operational log has $gpoEventCount events in the incident window; check for new/failed policy application."
}

if ($deploymentHitCount -eq 0) {
    $findings.HighPriorityFlags += "No installed app match found for DeploymentAppName='$DeploymentAppName'; verify app name string or deployment method."
}

if ($perfEventCount -gt 0) {
    $findings.HighPriorityFlags += "Diagnostics-Performance log contains $perfEventCount relevant events; inspect for startup/logon degradation indicators."
}

$findings.SuggestedActions += "Compare this device evidence with at least two unaffected devices for differential analysis."
$findings.SuggestedActions += "If profile and GPO signals are elevated, prioritize rollback/disable of recent change set for Floor 6 pilot group."
$findings.SuggestedActions += "For Copilot restricted-file allegation, pair this output with cloud-side permission and audit logs (security/governance team)."
$findings.SuggestedActions += "Prepare partner-safe update: scope, verified facts, containment steps, and next update time."

$collectorStatus = $results |
    Select-Object Name, Success, Error |
    Sort-Object Name

if ($DryRun) {
    Write-Host "Dry run complete. No files were written."
    Write-Host "Planned output folder: $caseFolder"
    Write-Host "Collectors run: $($collectorStatus.Count)"
    Write-Host "High-priority flags:"
    $findings.HighPriorityFlags | ForEach-Object { Write-Host ("- {0}" -f $_) }
    Write-Host "Suggested actions:"
    $findings.SuggestedActions | ForEach-Object { Write-Host ("- {0}" -f $_) }
}
else {
    $findingsFile = Join-Path -Path $caseFolder -ChildPath "00_findings_and_next_actions.json"
    $findings | ConvertTo-Json -Depth 6 | Out-File -FilePath $findingsFile -Encoding utf8

    $collectorStatusFile = Join-Path -Path $caseFolder -ChildPath "00_collector_status.csv"
    $collectorStatus | Export-Csv -Path $collectorStatusFile -NoTypeInformation -Encoding UTF8

    Write-Host "Evidence collection complete."
    Write-Host "Output folder: $caseFolder"
    Write-Host "Primary action file: $findingsFile"
}
