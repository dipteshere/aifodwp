# Intune App Deployment — Quick Steps (No Explanations)

## STEP 1: Navigate to App Upload
1. Go to https://intune.microsoft.com
2. Click **Apps** in left pane
3. Click **All apps**
4. Click **+ Add**
5. Select **Line-of-business app**
6. Click **Select**

## STEP 2: Fill App Information
1. Upload `.intunewin` file
2. Enter app name
3. Enter description (optional but recommended)
4. Enter publisher name
5. Enter version number
6. Leave other fields blank unless needed
7. Click **Next**

## STEP 3: Set Install Commands
1. Enter install command (e.g., `FinBridgeConnect_Setup.exe /silent`)
2. Enter uninstall command (e.g., `FinBridgeConnect_Setup.exe /uninstall /silent`)
3. Set Install behavior to **System**
4. Leave Device restart behavior as default
5. Click **Next**

## STEP 4: Set Requirements
1. Select **64-bit** (or match your app architecture)
2. Select minimum Windows version your app supports
3. Leave other fields blank
4. Click **Next**

## STEP 5: Add Detection Rule
1. Select **Manually configure detection rules**
2. Click **+ Add**
3. Set Rule type to **Registry**
4. Enter registry key path (provided by vendor or app developer)
5. Enter value name
6. Set Detection method to **String comparison**
7. Set Operator to **Equals**
8. Enter expected value
9. Click **OK**
10. Click **Next**

## STEP 6: Review Return Codes
1. Check that exit code `0` is set to **Success**
2. Check that exit code `1707` is set to **Success**
3. Check that exit code `3010` is set to **Soft reboot**
4. Leave defaults unless vendor documentation says otherwise
5. Click **Next**

## STEP 7: Create the App
1. Review the summary on **Review + create** tab
2. Click **Create**
3. Wait for creation to complete

## STEP 8: Assign to Pilot Group
1. Open the app you just created
2. Click **Assignments** tab
3. Click **+ Add group** under **Required** section
4. Search and select pilot group (e.g., `SG-Intune-AppPilot-IT`)
5. Click **Review + save**
6. Wait for sync

## STEP 9: Check Install Status on Test Device
1. On test device: Open **Settings** > **Accounts** > **Access work or school**
2. Click your account name
3. Click **Info**
4. Click **Sync**
5. Wait 5–10 minutes
6. Back in Intune portal: Go to **Apps** > **All apps** > select your app
7. Click **Device install status**
8. Find your test device
9. Look for **Installed** status

## STEP 10: Expand Assignment (After Pilot Success)
1. Open the app
2. Click **Assignments** tab
3. Click **+ Add group** under **Required** section
4. Search and select next group (Stage 2 pilot, then broad rollout)
5. Click **Review + save**

## Status Meanings
- **Installed** = App is on the device. Good.
- **Pending** = Waiting for sync. Check back later.
- **Not installed** = Detection rule not met. Check registry key.
- **Failed** = Install command failed. Check logs.
- **Not applicable** = Device doesn't meet OS/architecture requirements.

## If Install Fails
1. Open test device
2. Go to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
3. Search for your app name and error message
4. Check install command syntax
5. Check detection rule matches actual install output
6. Test install command manually on device if possible
