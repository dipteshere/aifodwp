# Resolution Document — Adobe Acrobat Pro v23.6 Intune Failure (1603)

Date: 2026-08-12  
Incident reference: Adobe Acrobat Pro v23.6 Win32 deployment failure  
Platform: Microsoft Intune (Win32 app)  
Affected command (old): msiexec /i AcrobatPro.msi /quiet  
Observed behavior: Repeated return code 1603 + detection Not detected + hourly retries

## 1. Resolution Objective

Restore reliable deployment of Adobe Acrobat Pro v23.6 to managed Win11 endpoints by removing deterministic installer failure causes and correcting Intune detection logic to prevent false negatives and retry loops.

## 2. Confirmed Resolution Path (Based on Hypothesis Ranking)

Primary remediation used:
- Replace incomplete MSI invocation with vendor-aligned silent install command including verbose logging.
- Correct detection from Acrobat Reader registry path to Acrobat Pro-specific marker.
- Pilot revised app revision on controlled endpoint cohort before broad assignment.

Secondary safeguards added:
- Pre-install checks for pending reboot and conflicting Adobe remnants.
- Assignment scoping and rollback-ready v3.0 equivalent package posture.

## 3. Detailed Resolution Steps Executed

### Step 1: Freeze failing assignment
- Action:
  - Removed affected device group from Required assignment on failing app revision.
  - Kept app available in catalog for forensics only.
- Reason:
  - Prevent repetitive 60-minute retries while remediation is prepared.

### Step 2: Build revised app revision (v23.6-R1)
- Action:
  - Repackaged Intune Win32 payload using verified Adobe enterprise install structure.
  - Set install command to include quiet mode, no forced restart, and verbose MSI logging.
- Command pattern used:
  - msiexec /i "AcrobatPro.msi" /qn /norestart /L*v "C:\Windows\Temp\AcrobatPro_v236_install.log"
- Note:
  - If Adobe package requires bootstrap/setup.exe or MST, that command supersedes direct MSI invocation.

### Step 3: Correct detection rule (critical)
- Previous detection (incorrect for Pro target):
  - HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- Implemented detection approach:
  - Pro-specific registry/file/MSI product marker validated from a known-good Acrobat Pro v23.6 device.
- Enforcement:
  - Detection method set to exact version check for v23.6 marker.

### Step 4: Add requirement and pre-check controls
- Added requirements:
  - Win11 supported build
  - Correct architecture match
- Added pre-check script logic:
  - Detect pending reboot state
  - Detect conflicting Adobe remnants
  - Exit with controlled code and log reason when blocked

### Step 5: Pilot rollout and validation
- Pilot scope:
  - 20 devices (mix of hardware, locations, VPN/non-VPN)
- Observation window:
  - 24 hours post-assignment
- Validation checkpoints:
  - Intune Device install status
  - IntuneManagementExtension log snippets
  - MSI verbose log review on any non-success outcome

### Step 6: Controlled expansion
- Gate to expand from pilot:
  - >=95% success within 24 hours
  - <=2% failed installs
  - No repeated identical fatal 1603 pattern
  - Detection reports Installed on successful machines
- Post-gate action:
  - Reassign revised app to broader target groups in phases.

## 4. What Was Fixed (Specific Configuration Corrections)

- Install command changed from minimal silent MSI call to logged enterprise-safe silent command.
- Detection rule corrected from Reader family key to Pro-specific marker.
- Retry churn mitigated by temporarily removing Required assignment from failing revision.
- Added pre-check controls to prevent known endpoint-state blockers from causing repeat 1603.

## 5. Verification Evidence Checklist

Required evidence for closure:
- Intune reporting export showing pilot success/failure percentages.
- At least 3 successful endpoint logs proving detection marker present after install.
- At least 3 previously failing endpoint re-tests showing no recurring 1603 under revised package.
- Sample verbose MSI log excerpt showing normal completion path.

## 6. Backout / Contingency During Resolution

If revised package had failed pilot gates:
- Keep revised app unassigned.
- Reassign legacy stable Adobe package version to impacted users.
- Continue forensic review from MSI logs and Adobe enterprise deployment documentation.

## 7. Operational Ownership

- Technical owner: DWP Endpoint Engineering
- Change authority: EUC Change Manager / CAB
- Service desk coordination: L1/L2 EUC Support
- Monitoring owner: Intune Operations Analyst

## 8. Closure Criteria

Resolution is complete when:
- Revised app passes pilot gates and one expanded cohort without threshold breach.
- No hourly retry loop remains on revised targets.
- Detection accuracy confirmed for Pro v23.6 marker.
- Change record updated with final command line, detection rule, and known-good deployment evidence.
