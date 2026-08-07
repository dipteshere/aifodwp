# Root Cause Analysis (RCA) - cthompson Logon Failure Incident

## Document Control
- Incident: User logon failure and account lockout
- Affected user: FINBRIDGE\cthompson
- Affected endpoint: DESKTOP-FB022
- Incident date: 2024-03-15
- Resolution time: 09:09 AM
- RCA prepared date: 2026-08-07

## Executive Summary
FINBRIDGE\cthompson was unable to log in starting around 08:40. Security logs show multiple wrong-password failures, followed by account lockout, then post-lockout wrong-password Kerberos failures from a different source IP. Resolution was completed after the account was re-enabled, and successful interactive logon was verified at 09:09 with no further issues reported.

## Scope and Impact
- Impacted user: One user only (FINBRIDGE\cthompson).
- Impacted service: Interactive logon access for the affected account.
- Impact window in provided evidence: 08:44 to 09:12, with resolution confirmed at 09:09.

## Supporting Evidence
1. 08:44:01 - Security Event 4776 (Audit Failure)
- Domain credential validation failed for FINBRIDGE\cthompson.
- Error code 0xC000006A (wrong password).
- Source workstation: DESKTOP-FB022.

2. 08:44:03 - Security Event 4625 (Audit Failure)
- Logon failed for FINBRIDGE\cthompson.
- Failure reason: Unknown user name or bad password.
- Logon type 2 (Interactive), source DESKTOP-FB022.

3. 08:44:28 - Security Event 4625 (Audit Failure)
- Repeated interactive bad-password failure for FINBRIDGE\cthompson on DESKTOP-FB022.

4. 08:44:55 - Security Event 4625 (Audit Failure)
- Additional interactive bad-password failure for FINBRIDGE\cthompson on DESKTOP-FB022.

5. 08:44:56 - Security Event 4740 (Audit Failure)
- User account FINBRIDGE\cthompson locked out.
- Caller computer: DESKTOP-FB022.

6. 08:45:10 - Security Event 4625 (Audit Failure)
- Unlock/logon attempt failed for FINBRIDGE\cthompson.
- Failure reason: Account locked out.
- Logon type 7 (Unlock attempt), source DESKTOP-FB022.

7. 08:45:44 - Security Event 4771 (Audit Failure)
- Kerberos pre-authentication failed for FINBRIDGE\cthompson.
- Failure code 0x18 (wrong password).
- Source IP: 10.10.8.112.

8. 08:46:01 - Security Event 4771 (Audit Failure)
- Repeated Kerberos pre-authentication failure (0x18 wrong password).
- Source IP: 10.10.8.112.

9. 08:46:33 - Security Event 4771 (Audit Failure)
- Repeated Kerberos pre-authentication failure (0x18 wrong password).
- Source IP: 10.10.8.112.

10. 09:08:14 - Security Event 4722 (Audit Success)
- User account FINBRIDGE\cthompson was enabled.
- Action performed by FINBRIDGE\helpdesk-admin.

11. 09:09:01 - Security Event 4624 (Audit Success)
- Successful interactive logon for FINBRIDGE\cthompson.
- Logon type 2 (Interactive), source DESKTOP-FB022.

## Timeline Reconstruction
1. Around 08:40, user reports inability to log in.
2. 08:44:01 to 08:44:55, multiple wrong-password failures occur from DESKTOP-FB022 (Events 4776 and 4625).
3. 08:44:56, account lockout is recorded (Event 4740).
4. 08:45:10, unlock attempt fails due to locked account state (Event 4625, logon type 7).
5. 08:45:44 to 08:46:33, additional wrong-password Kerberos pre-authentication failures continue from source IP 10.10.8.112 (Event 4771).
6. 09:08:14, helpdesk-admin enables the account (Event 4722).
7. 09:09:01, successful interactive logon occurs on DESKTOP-FB022 (Event 4624).
8. 09:09 AM, issue marked resolved and user verified working with no issues reported.

## Root Cause Statement
Primary cause: repeated wrong-password authentication attempts led to account lockout for FINBRIDGE\cthompson.
Contributing factor: wrong-password attempts continued from an additional source (10.10.8.112) after lockout, indicating another active credential submission path during the incident window.

## 5-Why Analysis
Problem statement:
- FINBRIDGE\cthompson could not log in.

Why 1:
- Why could the user not log in?
- Because authentication attempts failed and then the account entered a locked state.
- Evidence: Event 4625 failures and Event 4740 lockout.

Why 2:
- Why did authentication fail before lockout?
- Because wrong credentials were submitted.
- Evidence: Event 4776 error 0xC000006A and Event 4625 bad-password failures.

Why 3:
- Why did access remain blocked after lockout?
- Because subsequent attempts were made while the account was locked.
- Evidence: Event 4625 at 08:45:10 with failure reason account locked out.

Why 4:
- Why did failed authentication continue during the incident?
- Because wrong-password Kerberos pre-authentication attempts continued from source IP 10.10.8.112.
- Evidence: Event 4771 at 08:45:44, 08:46:01, and 08:46:33 with failure code 0x18.

Why 5:
- Why was service restored?
- Because the account was enabled by helpdesk-admin and login was retried successfully.
- Evidence: Event 4722 at 09:08:14 followed by Event 4624 success at 09:09:01.

## Resolution Actions Taken
1. Helpdesk-admin enabled account FINBRIDGE\cthompson (Event 4722, 09:08:14).
2. User performed interactive logon on DESKTOP-FB022 successfully (Event 4624, 09:09:01).
3. Service status confirmed resolved at 09:09 AM with user verified working and no issues reported.

## Verification
- Verification event: Security Event 4624 at 09:09:01.
- Verification condition met: Successful interactive logon by FINBRIDGE\cthompson on DESKTOP-FB022.
- User outcome: User confirmed working, no further issues reported.

## Preventive Actions
1. Identify and stop the secondary authentication source at 10.10.8.112 that continued wrong-password submissions during the incident window.
2. Add rapid lockout triage checks to correlate Event 4740 with preceding 4625/4776 and concurrent 4771 source telemetry.
3. Provide user-facing guidance to update saved credentials on all active sign-in paths after password changes to reduce repeated lockout conditions.
4. Capture and review lockout incidents where multiple sources appear, to ensure all offending credential paths are remediated before case closure.
