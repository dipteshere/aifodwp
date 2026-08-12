Symptom: Device fails Windows Autopilot enrollment and does not become fully managed. Typical indicators are enrollment failure with code 0x80180014 and policy deployment showing 0 of 4 applied.

Cause: Verified root cause is an existing legacy manual MDM enrollment already present on the device (DESKTOP-FB099), which conflicts with the Autopilot enrollment transaction.

Scope: Affects Windows devices that are being enrolled via Autopilot while still carrying prior manual/legacy MDM enrollment state. In this incident, scope confirmed on DESKTOP-FB099 (user FINBRIDGE\rthomas).

Workaround: Remove stale legacy enrollment state before reattempting Autopilot. Perform service-side cleanup (Intune/Entra object hygiene), device-side unenrollment cleanup, then rerun Autopilot from OOBE.

Permanent fix: Enforce a pre-enrollment cleanup gate for reprovisioning workflows so Autopilot cannot start when prior MDM enrollment exists. Add proactive reporting to detect Autopilot-targeted devices with legacy enrollment.

How to spot it: In MDM diagnostic export, confirm EnrollmentState Failed with ErrorCode 0x80180014 and ErrorDescription "The device is already enrolled in MDM." Cross-check DeviceInfo for MDMEnrolled Yes with legacy/manual source and previous enrollment date. Supporting pattern includes PolicyManager ProfilesApplied 0 of 4 and ComplianceEngine reason "Enrollment not complete."