# Analysis — Adobe Acrobat Pro v23.6 Intune Install Failure (Return Code 1603)

Date of analysis: 2026-08-12  
Incident log date: 2024-03-15  
Platform: Microsoft Intune (Win32 app deployment)  
App: Adobe Acrobat Pro v23.6  
Package: AdobeAcrobatPro.intunewin  
Install command: msiexec /i AcrobatPro.msi /quiet  
Install context: SYSTEM

## 1. Executive Summary

The deployment failed consistently with MSI return code 1603 during both initial install and first retry. Detection then reported Not detected because the expected registry key/value did not exist. The evidence strongly indicates the installer never completed successfully, and the detection rule appears misaligned with the product identity (Acrobat Pro install checked against an Acrobat Reader registry path). The likely outcome is a repeated retry loop in Intune until max retry behavior is reached or assignment changes.

## 2. Timeline Reconstruction (From Provided Logs)

- 10:01:00: Intune agent begins Adobe Acrobat Pro v23.6 install.
- 10:01:01: Installer runs in SYSTEM context.
- 10:01:03: Command executed: msiexec /i AcrobatPro.msi /quiet.
- 10:01:44: Installer exits with code 1603 (fatal error during installation).
- 10:01:45 to 10:01:46: Detection rule runs and checks HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0; value not found; detection fails.
- 10:01:47: App result marked Failed; retry scheduled in 60 minutes.
- 11:01:47: Retry attempt 1 starts.
- 11:01:48: Same install command executed.
- 11:02:31: Return code 1603 again; retry fails; next retry in 60 minutes.

Observed install attempt durations:
- Attempt 1 runtime: ~41 seconds (10:01:03 to 10:01:44)
- Attempt 2 runtime: ~43 seconds (11:01:48 to 11:02:31)

Interpretation:
- Failure occurs quickly and consistently, suggesting a deterministic blocker (packaging, prerequisite, product conflict, command-line requirement, or MSI runtime constraint), not transient network instability.

## 3. Technical Findings (Specific)

### Finding A: Install process fails before detection can ever pass
- Evidence: Return code 1603 appears before detection each time.
- Impact: Detection result Not detected is expected after a failed install and does not, by itself, indicate a detection-rule-only problem.

### Finding B: Detection rule likely targets wrong product family key
- Configured key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- Deployed app: Adobe Acrobat Pro v23.6
- Risk: Reader and Pro commonly use different product/feature markers. If Pro installs successfully but does not write this exact Reader key/value, Intune would still mark Not detected and keep retrying.

### Finding C: Command line lacks explicit logging and may miss required switches for enterprise package behavior
- Current command: msiexec /i AcrobatPro.msi /quiet
- Risks:
  - No verbose log path supplied (harder RCA)
  - Some Adobe enterprise packages require transforms (MST), setup bootstrap, or additional parameters not represented here

### Finding D: Repeated 1603 indicates non-remediated underlying state
- Same failure code on retry with same runtime pattern strongly suggests unchanged local condition between attempts (e.g., stale install remnants, pending reboot, conflicts, permission/context mismatch for package internals, or unsupported install path assumptions).

## 4. Hypothesis Section

### Hypothesis 1 (Highest Probability): Detection rule mismatch (Reader key used for Pro app)
- Why plausible:
  - Detection path explicitly references Acrobat Reader.
  - App being deployed is Acrobat Pro.
- What this explains:
  - Persistent Not detected state if Pro installs under different key/value.
- What this does not explain:
  - It does not directly cause MSI 1603; it explains post-install detection failures and possible reinstall loops.
- How to validate:
  - On a known-good Acrobat Pro v23.6 machine, enumerate product registry markers and version values.
  - Compare with Intune detection rule target.

### Hypothesis 2 (High Probability): MSI package invocation is incomplete for this Adobe build
- Why plausible:
  - Acrobat enterprise deployments often require bootstrap/setup.exe, transform (MST), or specific install properties.
  - Direct MSI install returns 1603 rapidly.
- How to validate:
  - Execute install manually in SYSTEM context with verbose MSI logging:
    - msiexec /i "AcrobatPro.msi" /qn /L*v "C:\Windows\Temp\AcrobatPro_v236_install.log"
  - Inspect log for terminal error context near "Return value 3".

### Hypothesis 3 (Medium Probability): Existing Adobe product conflict or upgrade code collision
- Why plausible:
  - 1603 frequently appears when product upgrade/uninstall prerequisites fail.
- How to validate:
  - Inventory installed Adobe products and versions on failed endpoint.
  - Check uninstall keys and Windows Installer product registration.
  - Test clean uninstall/repair path, then redeploy.

### Hypothesis 4 (Medium Probability): Pending reboot or locked file/state blocks MSI transaction
- Why plausible:
  - 1603 is common when reboot-required state exists.
- How to validate:
  - Check pending reboot indicators in registry and CBS/Windows Update state.
  - Reboot endpoint, force Intune sync, retry install.

### Hypothesis 5 (Lower Probability): Content extraction/path issue inside intunewin package
- Why plausible:
  - If MSI path is wrong relative to extracted working folder, installer can fail early.
- How to validate:
  - Confirm packaged content contains AcrobatPro.msi at expected relative path.
  - Verify install command references correct working directory/file name.

## 5. Root Cause Candidates (Ranked)

1. Primary candidate: Packaging/install-command design issue for Adobe Pro deployment (missing required enterprise switches/bootstrap/transform), producing deterministic 1603.
2. Secondary candidate: Detection rule points to Acrobat Reader key, not Acrobat Pro marker, creating false negatives even if install eventually succeeds.
3. Tertiary candidate: Endpoint state conflict (existing Adobe remnants or pending reboot) amplifying 1603 on retry.

## 6. Immediate Remediation Plan (Actionable)

### A. Correct install command for diagnostics first
- Replace with explicit quiet mode and verbose log:
  - msiexec /i "AcrobatPro.msi" /qn /norestart /L*v "C:\Windows\Temp\AcrobatPro_v236_install.log"
- Reason:
  - Captures installer decision path and exact failure reason.

### B. Validate Adobe-recommended enterprise deployment method
- Confirm whether package should use setup bootstrap and/or MST rather than raw MSI.
- If vendor method differs, repackage intunewin using vendor-prescribed command line.

### C. Fix detection logic for Acrobat Pro v23.6
- Change detection to a Pro-specific, stable marker (registry/file/MSI product code) verified on successful install reference device.
- Avoid Reader-specific key unless app is actually Reader.

### D. Add requirements and pre-checks
- Require supported Win11 build and architecture.
- Add pre-install script checks for pending reboot and known Adobe conflicts; exit gracefully with clear custom codes.

### E. Control blast radius before reattempt
- Deploy revised package to a pilot group (10-20 devices) first.
- Review Intune status + MSI verbose logs before broad assignment.

## 7. Validation Criteria After Fix

The fix is accepted only if all are met:
- >= 95% install success in pilot within 24 hours.
- <= 2% failed installs with no repeating identical fatal pattern.
- Detection shows Installed on successful devices using corrected Pro marker.
- No repeated hourly retry loop for corrected deployment.

## 8. Exact Data to Collect for Final RCA Closure

Collect from at least 3 failed and 3 successful endpoints:
- IntuneManagementExtension.log snippets around install execution and exit codes.
- Full MSI verbose log (AcrobatPro_v236_install.log).
- Installed Adobe product inventory before/after install.
- Pending reboot indicators at install time.
- Detection marker presence/absence and exact registry/file path values.

## 9. Risks If Left Unchanged

- Continuous retry attempts increase endpoint churn and helpdesk load.
- False Not detected states may trigger repeated reinstalls and user disruption.
- Production rollout could fail at scale with the same deterministic 1603 pattern.

## 10. Recommended Next Change (Operational)

Create a new Intune app revision for Adobe Acrobat Pro v23.6 with:
- Correct vendor-supported install command
- Verbose logging enabled during pilot
- Corrected Pro-specific detection rule
- Limited pilot assignment and monitored expansion gates
