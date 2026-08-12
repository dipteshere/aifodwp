# FinBridge Connect v3.1 — Phased Intune Deployment Plan (10,000 Win11 Endpoints)

Date created: 2026-08-12  
Rollout deadline (3 weeks): 2026-09-02

## 1. RING STRUCTURE

### Ring design summary
- Total target endpoints: 10,000 Win11
- At-risk segment: ~500 devices (5%) with 4GB RAM
- Finance priority users: 500 users by end of week 1

### Ring 1 (Pilot)
- Size: 500 endpoints total
- Composition:
  - 250 IT + Digital Workplace support users (high diagnostic value)
  - 150 cross-business standard productivity users
  - 100 known 4GB RAM devices (intentionally over-sampled from at-risk segment)
- Duration: 3 calendar days minimum active monitoring after assignment
- Who to include:
  - Mix of laptop/desktop, remote/in-office, VPN/non-VPN, and device age spread
  - Exclude Finance users in this baseline path (Finance handled under section 4 recommendation)
- Purpose:
  - Validate packaging, install command, registry detection rule, and basic app launch stability
  - Validate behavior on low-memory devices before larger exposure
- Intune assignment group type:
  - Microsoft Entra ID Security Group (Assigned membership)
  - Group name pattern: SG-APP-FINBRIDGE-V31-R1-PILOT-REQ

### Ring 2 (Early)
- Size: 2,500 endpoints total (cumulative target = 3,000 including Ring 1)
- Composition:
  - 500 Finance users (mandatory completion by end of week 1)
  - 2,000 non-Finance users across major departments
  - Additional 150 4GB RAM devices (for cumulative 250/500 at-risk devices covered by end of Ring 2)
- Duration: 5 calendar days minimum active monitoring after assignment
- Who to include:
  - Departmental champions, frequent app users, and service desk-heavy business units
- Purpose:
  - Confirm performance at operational scale and peak-hour distribution behavior
  - Confirm finance workflows (data pull, authentication, export, print) in production conditions
- Intune assignment group type:
  - Microsoft Entra ID Security Group (Assigned membership)
  - Group name pattern: SG-APP-FINBRIDGE-V31-R2-EARLY-REQ

### Ring 3 (Broad)
- Size: remaining 7,000 endpoints
- Duration: up to 10 calendar days (can complete earlier if metrics remain green)
- Who to include:
  - All remaining in-scope Win11 managed endpoints not in Rings 1-2
  - Split into two waves inside Ring 3 for control:
    - Wave 3A: 3,500 endpoints
    - Wave 3B: 3,500 endpoints
- Purpose:
  - Complete enterprise-wide rollout by deadline with controlled final exposure
- Intune assignment group type:
  - Microsoft Entra ID Security Group (Dynamic membership for broad targeting with explicit exclusions)
  - Include dynamic group for all eligible Win11 corporate endpoints
  - Exclude SG-APP-FINBRIDGE-V31-HOLD and SG-APP-FINBRIDGE-V31-ROLLBACK

## 2. ADVANCE CRITERIA

All criteria are evaluated from Intune app reporting (Device install status, User install status, and failure detail exports), service desk ticket tagging (keyword: FinBridge v3.1), and endpoint health telemetry for the defined ring only.

### Ring 1 -> Ring 2 advance criteria
- Install success rate: >= 97.0% within 24 hours of assignment for Ring 1 population
- Error rate threshold: <= 2.5% failed status in Intune during the same 24-hour window
- User-reported issues: <= 1.5 tickets per 100 users per 24 hours (1.5%) tagged to FinBridge v3.1
- Monitoring period: minimum 72 continuous hours after first 90% of Ring 1 devices receive install intent
- Time-bound decision point: CAB-style go/no-go at Hour 72 to Hour 84

### Ring 2 -> Ring 3 advance criteria
- Install success rate: >= 98.0% within 48 hours of assignment for Ring 2 population
- Error rate threshold: <= 1.8% failed status in Intune during the same 48-hour window
- User-reported issues: <= 1.0 ticket per 100 users per 24 hours sustained for 2 consecutive days
- Monitoring period: minimum 120 continuous hours after Ring 2 assignment
- Time-bound decision point: go/no-go at Day 5 to Day 6 of Ring 2

### Hold condition (pause without full rollback)
- Trigger: any ring has 4GB RAM subgroup failure rate between 8.0% and 11.9% in a rolling 24-hour window, while fleet-wide failure remains below rollback threshold.
- Action on hold:
  - Pause progression to the next ring
  - Move impacted low-RAM devices to SG-APP-FINBRIDGE-V31-HOLD (exclude from required assignment)
  - Continue rollout for unaffected standard-hardware cohorts only after approval
- Specific example:
  - If Ring 2 has 2,500 devices and 150 are 4GB RAM, and 14 of those 150 fail in 24 hours (9.3%), hold is triggered for low-RAM cohort isolation even if overall ring failure is < 3%.

## 3. ROLLBACK TRIGGERS

### Trigger 1: Install failure rate (automatic halt)
- Condition:
  - >= 8.0% failed installs in any active ring within any rolling 12-hour window, measured from Intune Device install status
- Decision owner:
  - Incident Commander (DWP Lead Engineer) with Endpoint Product Owner concurrence
- Decision window:
  - 60 minutes from threshold breach alert
- Exact Intune rollback action:
  - Remove required assignment of FinBridge Connect v3.1 from active ring group(s)
  - Add affected ring group(s) to FinBridge Connect v3.0 Required assignment
  - Add affected ring devices to SG-APP-FINBRIDGE-V31-ROLLBACK exclusion group to prevent immediate re-targeting

### Trigger 2: Application crash rate (rollback consideration)
- Condition:
  - >= 3.0% of active devices in ring report 2 or more app crashes within rolling 24 hours
  - Corroborated by endpoint telemetry and service desk incident linkage
- Decision owner:
  - DWP Lead Engineer + EUC Service Owner + Major Incident Manager
- Decision window:
  - 4 hours from confirmation of crash pattern
- Exact Intune rollback action:
  - Halt new ring expansion immediately
  - For confirmed affected ring(s), swap Required assignment from v3.1 to v3.0
  - Keep unaffected prior-success rings unchanged only if crash rate is below threshold there

### Trigger 3: Business-critical failure (immediate rollback)
- Condition (specific scenario):
  - Finance users cannot submit regulatory day-end reconciliation files from FinBridge for two consecutive processing cycles due to v3.1 defect
- Decision owner:
  - Major Incident Manager can declare immediate rollback; Business Service Owner (Finance IT) informed in parallel
- Decision window:
  - Immediate (within 30 minutes of verified critical impact)
- Exact Intune rollback action:
  - Remove v3.1 Required assignment from Finance-targeted groups immediately
  - Assign v3.0 as Required to same Finance groups
  - Open emergency change record for wider rollback decision across other rings

### Trigger 4: 4GB RAM device failures (ring isolation)
- Condition:
  - >= 12.0% install failure rate on 4GB RAM devices in any ring over rolling 24 hours
- Decision owner:
  - Endpoint Engineering Manager
- Decision window:
  - 2 hours from threshold breach
- Exact Intune action:
  - Move all 4GB RAM devices into SG-APP-FINBRIDGE-V31-HOLD
  - Exclude SG-APP-FINBRIDGE-V31-HOLD from v3.1 assignments in all rings
  - Assign v3.0 Required to SG-APP-FINBRIDGE-V31-HOLD until vendor fix or packaging workaround is validated

## 4. FINANCE DEADLINE RESOLUTION

### Option A — Compress pilot to fit Finance into Ring 2 by end of week 1
- Minimum safe pilot duration:
  - 72 hours with at least one business-day peak and one off-hours sync cycle
- Risk introduced:
  - Reduced observation time may miss low-frequency stability defects or scheduled-task conflicts
- Compensating control:
  - Increase pilot telemetry depth (hourly failure dashboard review, dedicated Finance UAT checklist run in pilot subset, and pre-approved rollback change ready before Ring 2 assignment)

### Option B — Finance as separate Ring 0 before main pilot
- Ring 0 structure:
  - 500 Finance users split into two waves of 250 over 48 hours
  - Include 50 known 4GB RAM finance devices in Wave 0A for early hardware-risk signal
- Ring 0 advance conditions:
  - Wave 0A -> Wave 0B: >= 97% success in 24 hours, <= 2.5% failure, <= 2 tickets per 100 users
  - Ring 0 completion gate: >= 97.5% success in 48 hours, no business-critical workflow blocker
- Ring 0 rollback plan:
  - Same trigger framework as section 3, but with immediate ring-only rollback to v3.0 for Finance groups if any critical finance workflow failure occurs

### Recommendation
- Recommend Option B (Finance Ring 0).
- Justification:
  - Meets non-negotiable Finance end-of-week-1 requirement without weakening the main engineering pilot design.
  - Preserves Ring 1 as a true technical validation cohort, improving confidence before broad exposure.
  - Contains business risk: Finance can be rolled back independently to v3.0 without disrupting non-Finance ring progression.
  - Better aligns with change governance by separating business-priority deployment from platform-risk validation.

### Recommended 3-week execution calendar (with Option B)
- Week 1:
  - Day 1-2: Ring 0 Finance Wave 0A/0B
  - Day 3: Ring 0 decision gate and remediation if needed
  - Day 3-5: Ring 1 Pilot (500 endpoints)
- Week 2:
  - Ring 2 Early (2,500 endpoints including any deferred Finance exceptions)
  - Day 5/6 gate based on section 2 criteria
- Week 3:
  - Ring 3 Broad Wave 3A then 3B (remaining 7,000)
  - Final compliance sweep and closure report by 2026-09-02
