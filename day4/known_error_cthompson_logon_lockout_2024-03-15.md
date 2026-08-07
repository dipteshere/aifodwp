Symptom: User FINBRIDGE\cthompson cannot log in interactively on DESKTOP-FB022. During the incident window, login attempts fail with bad-password and locked-account outcomes.

Cause: Verified root cause is repeated wrong-password authentication attempts that led to account lockout for FINBRIDGE\cthompson. A contributing factor was continued wrong-password Kerberos pre-authentication attempts from source IP 10.10.8.112 after lockout.

Scope: One user was affected: FINBRIDGE\cthompson. The affected endpoint in the evidence is DESKTOP-FB022, with additional failed pre-authentication attempts recorded from 10.10.8.112.

Workaround: Re-enable the locked account and retry interactive sign-in on DESKTOP-FB022. In this incident, account enablement at 09:08:14 was followed by successful interactive logon at 09:09:01.

Permanent fix: Identify and stop the secondary authentication source at 10.10.8.112 that continued wrong-password submissions. Add lockout triage correlation for Event 4740 with preceding 4625/4776 and concurrent 4771 source telemetry, and ensure saved credentials are updated across active sign-in paths.

How to spot it: Look for Event 4776 with error 0xC000006A and Event 4625 entries showing bad-password failures from DESKTOP-FB022, followed by Event 4740 account lockout. Confirm continued Event 4771 failures with code 0x18 from 10.10.8.112, then verify recovery with Event 4722 (account enabled) and Event 4624 (interactive logon success).
