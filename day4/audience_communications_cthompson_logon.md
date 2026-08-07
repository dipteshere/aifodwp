# End-User Communication Variants - cthompson Logon Incident

## Audience 1 - Non-technical executive
Your access and data are safe. One user, cthompson, could not sign in from about 08:40. Multiple wrong password attempts on DESKTOP-FB022 locked the account, and additional wrong attempts came from device 10.10.8.112. helpdesk-admin re-enabled the account at 09:08:14, and sign-in succeeded on DESKTOP-FB022 at 09:09:01. The issue was resolved at 09:09 with no further issues reported. No action is needed unless this recurs.

## Audience 2 - Affected end-user team (10 users)
Your access and data are safe. Around 08:40, one user (cthompson) could not sign in because repeated wrong password attempts from DESKTOP-FB022 locked the account, with additional wrong-password attempts also coming from device 10.10.8.112. helpdesk-admin re-enabled the account at 09:08:14, and sign-in succeeded on DESKTOP-FB022 at 09:09:01; the issue was resolved at 09:09 with no further issues reported. If you see the same issue, report it immediately with the time and device name. Contact FINBRIDGE helpdesk-admin.

## Audience 3 - Engineer-to-engineer internal note
Root cause: repeated invalid credential submissions for FINBRIDGE\cthompson caused AD lockout (4740 at 08:44:56), preceded by 4776 (0xC000006A) and 4625 bad-password failures from DESKTOP-FB022; contributing path was continued 4771 pre-auth failures (0x18) from source IP 10.10.8.112 at 08:45:44, 08:46:01, and 08:46:33.

Exact action taken: account was enabled by FINBRIDGE\helpdesk-admin (4722 at 09:08:14), followed by user retry and successful interactive logon (4624 type 2) on DESKTOP-FB022 at 09:09:01.

Config detail: affected principal FINBRIDGE\cthompson; local interactive source DESKTOP-FB022; secondary credential-submission source 10.10.8.112; incident start around 08:40; resolved 09:09 with no further issues reported.

Verification step: confirm Security 4624 success for FINBRIDGE\cthompson on DESKTOP-FB022 at 09:09:01 and no subsequent failure pattern matching 4625/4771 lockout chain in the immediate post-fix window.

Preventive action needed: identify and stop the secondary source at 10.10.8.112 continuing wrong-password submissions, run rapid lockout triage correlation (4740 with preceding 4625/4776 and concurrent 4771 source telemetry), and ensure saved credentials are updated across active sign-in paths.
