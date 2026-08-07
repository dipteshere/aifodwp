# End-User Communication - Three Audiences (Same Facts)

## Audience 1 - Non-technical executive
Your access and data are safe. One user, cthompson, could not sign in from about 08:40 after repeated wrong password attempts on DESKTOP-FB022 locked the account; additional wrong attempts also came from device 10.10.8.112. helpdesk-admin re-enabled the account at 09:08:14, sign-in succeeded on DESKTOP-FB022 at 09:09:01, and the issue was resolved at 09:09 with no further issues reported. No action is needed unless this happens again.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access and data are safe. Around 08:40, one user (cthompson) could not sign in because repeated wrong password attempts on DESKTOP-FB022 locked the account, and additional wrong attempts also came from device 10.10.8.112; helpdesk-admin re-enabled the account at 09:08:14, sign-in succeeded on DESKTOP-FB022 at 09:09:01, and the issue was resolved at 09:09 with no further issues reported. If you see this, contact FINBRIDGE helpdesk-admin and share the time and device name.

## Audience 3 - Engineer-to-engineer internal note
Root cause: repeated wrong-password submissions for FINBRIDGE\cthompson from DESKTOP-FB022 caused lockout, with additional wrong-password submissions from source 10.10.8.112.

Exact action taken: FINBRIDGE\helpdesk-admin enabled the account at 09:08:14; user then completed successful interactive sign-in on DESKTOP-FB022 at 09:09:01.

Config detail: user FINBRIDGE\cthompson; primary host DESKTOP-FB022; secondary source 10.10.8.112; incident start about 08:40; issue resolved 09:09; no further issues reported.

Verification step: confirmed successful sign-in at 09:09:01 on DESKTOP-FB022 after account enablement at 09:08:14 and user reported no further issues.

Preventive action needed: identify and remediate the secondary source at 10.10.8.112 and continue lockout correlation across related authentication failures to stop repeated invalid submissions early.