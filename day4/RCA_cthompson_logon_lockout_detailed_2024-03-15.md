# Detailed Root Cause Analysis (RCA) - cthompson Logon Lockout Incident

## 1. Document Control
- Incident title: User logon failure and account lockout
- Incident date: 2024-03-15
- Affected user: FINBRIDGE\cthompson
- Affected endpoint: DESKTOP-FB022
- Resolution status: Resolved
- Resolution confirmation time: 09:09 AM
- RCA prepared by: DWP Analyst
- RCA prepared date: 2026-08-07

## 2. Incident Summary
At approximately 08:40, FINBRIDGE\cthompson reported inability to log in interactively. Security events show a sequence of wrong-password authentication failures, account lockout, and continued Kerberos pre-authentication failures from a secondary source. The suggested resolution was applied, and service was restored. Recovery was verified by successful interactive logon at 09:09 AM, with no additional user issues reported.

## 3. Scope and Impact
- User impact: One user only (FINBRIDGE\cthompson).
- Service impact: Interactive sign-in blocked during incident window.
- System scope: Evidence confirms primary endpoint DESKTOP-FB022 and additional authentication source IP 10.10.8.112.
- Business impact: Temporary inability for the affected user to access workstation session.

## 4. Supporting Evidence (Event-by-Event)

### Primary failure and lockout sequence
1. 08:44:01 - Security Event 4776 (Audit Failure)
- Meaning: NTLM/domain credential validation failed.
- Evidence detail: Error 0xC000006A (wrong password), user FINBRIDGE\cthompson, source workstation DESKTOP-FB022.

2. 08:44:03 - Security Event 4625 (Audit Failure)
- Meaning: Logon attempt failed.
- Evidence detail: Logon Type 2 (Interactive), failure reason bad username or password, source DESKTOP-FB022.

3. 08:44:28 - Security Event 4625 (Audit Failure)
- Meaning: Repeated interactive logon failure.
- Evidence detail: Bad-password outcome persisted from same workstation.

4. 08:44:55 - Security Event 4625 (Audit Failure)
- Meaning: Additional failed interactive sign-in.
- Evidence detail: Same account and workstation pattern continued.

5. 08:44:56 - Security Event 4740 (Audit Failure)
- Meaning: Account lockout occurred.
- Evidence detail: Account FINBRIDGE\cthompson locked out; caller computer DESKTOP-FB022.

6. 08:45:10 - Security Event 4625 (Audit Failure)
- Meaning: Logon/unlock failed due to lockout state.
- Evidence detail: Logon Type 7 (Unlock), failure reason account locked out.

### Concurrent secondary source failures
7. 08:45:44 - Security Event 4771 (Audit Failure)
- Meaning: Kerberos pre-authentication failed.
- Evidence detail: Failure code 0x18 (wrong password), source IP 10.10.8.112.

8. 08:46:01 - Security Event 4771 (Audit Failure)
- Meaning: Repeat Kerberos pre-auth failure.
- Evidence detail: Same wrong-password code and same source IP.

9. 08:46:33 - Security Event 4771 (Audit Failure)
- Meaning: Continued Kerberos pre-auth failure activity.
- Evidence detail: Same signature confirms persistent bad credential submissions.

### Recovery confirmation sequence
10. 09:08:14 - Security Event 4722 (Audit Success)
- Meaning: User account was enabled.
- Evidence detail: Action performed by FINBRIDGE\helpdesk-admin.

11. 09:09:01 - Security Event 4624 (Audit Success)
- Meaning: Successful logon.
- Evidence detail: Logon Type 2 (Interactive), user FINBRIDGE\cthompson, source DESKTOP-FB022.

12. 09:09 AM - Operational confirmation
- Meaning: Incident marked resolved.
- Evidence detail: User verified logging in to host; no issues reported.

## 5. Timeline Reconstruction
1. ~08:40: User reports inability to log in.
2. 08:44:01 to 08:44:55: Multiple wrong-password failures from DESKTOP-FB022 (Events 4776 and 4625).
3. 08:44:56: Account lockout triggered (Event 4740).
4. 08:45:10: Unlock/logon attempt blocked because account remained locked (Event 4625, Type 7).
5. 08:45:44 to 08:46:33: Wrong-password Kerberos attempts continue from secondary source 10.10.8.112 (Event 4771 x3).
6. 09:08:14: Helpdesk admin re-enabled the user account (Event 4722).
7. 09:09:01: User successfully performed interactive logon on DESKTOP-FB022 (Event 4624).
8. 09:09 AM: Case confirmed resolved with successful user verification and no further issues.

## 6. Root Cause and Contributing Factors
### Root Cause
Repeated invalid credential submissions for FINBRIDGE\cthompson triggered account lockout, directly causing interactive sign-in failure.

### Contributing Factors
- Continued wrong-password submissions from secondary source IP 10.10.8.112 prolonged incident conditions after initial lockout.
- Account lockout state blocked immediate user recovery until administrative account enablement occurred.

## 7. 5-Why Analysis
Problem statement:
- FINBRIDGE\cthompson could not log in to DESKTOP-FB022.

Why 1:
- Why could the user not log in?
- Because authentication failed repeatedly and the account became locked.
- Evidence: Events 4625 and 4740.

Why 2:
- Why did authentication fail repeatedly?
- Because incorrect credentials were submitted.
- Evidence: Event 4776 (0xC000006A wrong password), Event 4771 (0x18 wrong password).

Why 3:
- Why did the issue continue after lockout occurred?
- Because additional failed authentication attempts continued while the account was locked.
- Evidence: Event 4625 at 08:45:10 (account locked out) and repeated 4771 events thereafter.

Why 4:
- Why were additional failures still generated?
- Because a secondary source (10.10.8.112) kept submitting invalid credentials.
- Evidence: Event 4771 at 08:45:44, 08:46:01, 08:46:33 from the same source IP.

Why 5:
- Why was service restored at 09:09?
- Because suggested remediation was applied: account re-enabled, then user re-authenticated successfully.
- Evidence: Event 4722 at 09:08:14 followed by Event 4624 at 09:09:01 and user verification.

## 8. Resolution Actions Taken
1. Applied suggested resolution path through service desk process.
2. Re-enabled account FINBRIDGE\cthompson (Event 4722).
3. Retried interactive logon from DESKTOP-FB022 and confirmed success (Event 4624).
4. Confirmed user could log in and operate normally; no further issues reported.

## 9. Preventive Actions
1. Identify and remediate the process, endpoint, or stored credential source at 10.10.8.112 that continued invalid submissions.
2. Enforce immediate credential cache refresh guidance after password updates (workstation, mobile mail profile, mapped services, scheduled tasks).
3. Add lockout triage standard to correlate Event 4740 with prior 4625/4776 and concurrent 4771 source data before closure.
4. Implement alerting for repeated wrong-password patterns across multiple sources for the same account within short intervals.
5. Add closure checklist item requiring validation that no secondary failed-auth source remains active.

## 10. Verification of Recovery
- Technical verification: Successful interactive sign-in event present (4624 at 09:09:01).
- Operational verification: User confirmed access restored and stable.
- Incident status: Resolved at 09:09 AM.

## 11. Residual Risk
If secondary authentication sources with stale credentials are not fully identified and corrected, similar user lockouts can recur.
