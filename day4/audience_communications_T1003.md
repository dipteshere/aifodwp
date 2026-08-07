# Audience Communications - T-1003 AVD Black Screen Incident

## Audience 1 - Non-technical executive
Your access and data are safe. After an overnight update at 02:00, one finance desktop group (POOL-FIN-01) had black screens after sign-in from about 07:00, affecting about 40% of users; another group (POOL-FIN-02) was not affected. The issue was fixed on the affected systems by 10:00, and sign-ins are now stable with no further reports. No action is needed unless it happens again; then contact DWWP Engineering or EUC Platform Operations.

## Audience 2 - Affected end-user team
Your access and data are safe, and the issue is fixed. After an overnight update at 02:00, one finance desktop group (POOL-FIN-01) began showing black screens just after sign-in from about 07:00, affecting about 40% of users while another group (POOL-FIN-02) was unaffected. The fix was completed by 10:00, and sign-ins are stable with no further reports. If you see the same issue again, report it immediately with time and host details. Contact DWWP Engineering or EUC Platform Operations.

## Audience 3 - Engineer-to-engineer internal note
Root cause: image-introduced graphics/display regression on POOL-FIN-01 after 02:00 image update; DWM crash chain in logon init path. Config/signature detail: Event 1000 dwm.exe faulting igdumd64.dll (0xc0000005), Event 9009 DWM exit, Event 40 disconnects after Event 21 logon success; POOL-FIN-02 (pre-update) unaffected. Action taken: agreed remediation executed on POOL-FIN-01 hosts (containment and corrective host/image actions with controlled validation), incident resolved by 10:00. Verification: users successfully logging in, no further issues reported. Preventive action: enforce pre-prod graphics soak gate, block promotion on signature events, keep tested rollback runbook.
