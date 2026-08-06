# Root Cause Analysis (RCA) - User Lockout Incident (jsmith)

## Document Control
- Incident Type: User account lockout
- User: jsmith
- Time Window Reviewed: 08:02:14 to 08:23:44
- Systems Referenced: DESKTOP-FB001, FINBRIDGE domain
- Prepared By: DWP Analyst
- Date: 2026-08-06

## Scope and Objective
This RCA analyzes Windows Security events captured during a 30-minute period in which user jsmith was unable to access their machine. The objective is to identify what happened, determine the most likely cause, and define corrective and preventive actions.

## Event ID Meaning (What Each Event Records)

1. Event ID 4625 (Audit Failure)
- What it records: A failed logon attempt.
- In this incident: The account jsmith attempted to log on interactively at DESKTOP-FB001 and authentication failed.
- Failure text seen: Unknown username or bad password, and later Account locked out.

2. Event ID 4740 (Audit Failure category in provided data)
- What it records: A user account was locked out by account lockout policy after repeated failed authentication attempts.
- In this incident: Account jsmith was locked out, and the caller/source machine was DESKTOP-FB001.

3. Event ID 4722 (Audit Success)
- What it records: A user account was enabled by an administrator.
- In this incident: jsmith was enabled by FINBRIDGE\helpdesk-admin.
- Note: In many environments, unlock actions are commonly tracked with Event ID 4767, while 4722 is account enabled. Verify exact admin action in AD Users and Computers audit trail.

4. Event ID 4624 (Audit Success)
- What it records: A successful logon.
- In this incident: jsmith successfully logged on interactively after admin intervention.

## Reconstructed Sequence of Events (Plain English)

1. At 08:02:14, jsmith tried to sign in at DESKTOP-FB001 using interactive logon (type 2), but credentials were rejected as unknown username or bad password.
2. At 08:04:22, a second interactive sign-in failure occurred from the same endpoint with the same bad-credentials reason.
3. At 08:06:01, domain/account lockout policy threshold was reached and jsmith was locked out (Event 4740), with DESKTOP-FB001 identified as the calling/source host.
4. At 08:07:45, another attempt occurred at unlock context (logon type 7) and failed because the account was already locked.
5. At 08:22:10, helpdesk-admin performed an administrative account action recorded as Event 4722 (account enabled).
6. At 08:23:44, jsmith logged on successfully (Event 4624, type 2), confirming access was restored.

## Most Likely Cause of Lockout
Primary Cause:
- Repeated interactive bad-password attempts for jsmith on DESKTOP-FB001 triggered account lockout policy.

Evidence:
- Two consecutive 4625 failures with bad password reason from DESKTOP-FB001 before lockout.
- Event 4740 explicitly states account locked out and identifies DESKTOP-FB001 as caller.
- Post-lockout 4625 with reason Account locked out confirms lockout state.
- Successful 4624 only after helpdesk intervention indicates credentials/state issue was resolved after administrative action.

Contributing Factors:
- User likely entered an incorrect password repeatedly, or a stale cached credential was used at interactive logon/unlock.
- Lack of immediate user self-service recovery path (for example SSPR/unlock) increased outage duration.

## 5-Why Analysis

Problem Statement:
- User jsmith was locked out and unable to access the machine for approximately 21 minutes.

Why 1:
- Why was jsmith locked out?
- Because lockout policy was triggered after repeated failed authentication attempts.
- Evidence: Event 4740 at 08:06:01 after prior 4625 failures.

Why 2:
- Why were there repeated failed authentication attempts?
- Because interactive logon attempts used invalid credentials.
- Evidence: Event 4625 at 08:02:14 and 08:04:22 with Unknown username or bad password.

Why 3:
- Why were invalid credentials entered/used on the endpoint?
- Most likely the user entered an incorrect password or used an outdated memorized password.
- Evidence: Failures are interactive (type 2) from the same endpoint before lockout.
- Verification needed: Confirm with user interview and password-change timeline.

Why 4:
- Why did the issue persist until helpdesk intervention?
- Because once locked, subsequent attempts cannot succeed without unlock/administrative action.
- Evidence: 4625 at 08:07:45 shows Account locked out; recovery event appears at 08:22:10.

Why 5:
- Why was user productivity impacted for this duration?
- Because there was no immediate self-service unlock flow and response relied on helpdesk action.
- Evidence: Time gap between lockout and administrative remediation event.

Root Cause (Most Probable):
- Repeated interactive authentication failures with incorrect credentials at DESKTOP-FB001 triggered domain lockout policy for jsmith.

## Corrective Actions (Immediate)
1. Confirm account is active/unlocked and user can authenticate on DESKTOP-FB001.
2. Require controlled password reset if there is any doubt about password correctness.
3. Validate no stuck credential prompts or cached credential loops on local machine.

## Preventive Actions (Recommended)
1. Implement or promote self-service password reset/unlock to reduce downtime.
2. Provide user guidance on lockout policy thresholds and safe retry behavior.
3. Monitor for repeated 4625 bursts by user+endpoint and alert before threshold is reached.
4. Review whether account enable/unlock procedures are audited with expected event IDs in this domain.
5. Consider conditional lockout notifications to both user and service desk for faster intervention.

## Validation and Follow-Up Checks
1. Confirm no further 4625 events for jsmith from DESKTOP-FB001 after 08:23:44.
2. Confirm a stable run period (for example 24-48 hours) without new 4740 events for jsmith.
3. Verify whether Event 4767 (account unlocked) exists around 08:22 to clarify whether action was enable, unlock, or both.

## Confidence and Assumptions
- Confidence in immediate cause: High.
- Confidence in deeper human-factor cause (mistyped vs stale credential): Medium.
- Assumption: Provided event snippet is complete for the incident window. If additional DC/security logs exist, correlate before final closure.
