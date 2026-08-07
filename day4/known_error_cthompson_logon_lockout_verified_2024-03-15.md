Symptom     : FINBRIDGE\cthompson could not log in interactively on DESKTOP-FB022 starting around 08:40. During the incident window, sign-in attempts failed with bad-password and account-locked outcomes.

Cause       : Repeated invalid credential submissions for FINBRIDGE\cthompson triggered account lockout, which directly caused the interactive sign-in failure. Continued wrong-password submissions from secondary source 10.10.8.112 contributed to the ongoing failure pattern.

Scope       : One user was affected: FINBRIDGE\cthompson. The systems in evidence were DESKTOP-FB022 and source IP 10.10.8.112.

Workaround  : Re-enable the FINBRIDGE\cthompson account and retry interactive sign-in on DESKTOP-FB022. In this incident, account enablement at 09:08:14 was followed by successful sign-in at 09:09:01.

Permanent fix: Identify and remediate the process, endpoint, or stored credential source at 10.10.8.112 that continued invalid submissions. Keep lockout triage correlation in place using related failure events before closure.

How to spot it: Look for Event 4776 with error 0xC000006A and repeated Event 4625 bad-password failures from DESKTOP-FB022, followed by Event 4740 account lockout and Event 4625 showing account locked out. Confirm continued Event 4771 failures with code 0x18 from 10.10.8.112, then verify recovery with Event 4722 and successful Event 4624 at 09:09:01.