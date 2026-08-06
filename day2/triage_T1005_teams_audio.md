# Triage Summary — T-1005

## Summary (one line)
Teams audio is completely non-functional on three machines located in the same meeting room.

## Impact (who/how many/business urgency)
- Who: All users of the affected meeting room (number of regular occupants — to-verify)
- How many: 3 machines confirmed affected; any user attempting to use the room is impacted
- Business urgency: High — meeting room audio loss directly blocks collaborative and client-facing meetings

## Known facts
- Teams audio is not working on three separate machines.
- All three machines are in the same physical meeting room.
- The common location strongly suggests a shared environmental or infrastructure cause.

## Missing information to gather
- User identities or room name/number and contact details.
- Whether the three machines share a common audio peripheral (room speakerphone, USB audio device, audio dock — to-verify).
- Whether each machine has its own separate audio device or all route through a single shared device (to-verify).
- Whether audio functions outside of Teams (system sounds, other applications) on the affected machines (to-verify).
- Whether the issue affects audio input, output, or both (to-verify).
- Whether Teams audio was working previously in this room and when it stopped (to-verify).
- Teams client version on the affected machines (to-verify).
- Whether any recent changes occurred: Teams update, Windows update, audio device firmware update, or room reconfiguration (to-verify).
- Whether Teams audio device settings show the correct device selected on each machine (to-verify).
- Whether the audio device appears healthy in Windows Device Manager on each machine (to-verify).
- Whether the issue is isolated to this room or reported in other rooms or locations (to-verify).
- Whether a Microsoft Teams Rooms device is involved or these are standard Windows PCs (to-verify).

## Likely category
- Collaboration / Teams audio failure in a shared room environment (to-verify)
- Possible subcategory: Shared audio peripheral fault, Teams audio device selection issue, or driver/firmware problem (to-verify)

## First diagnostic step
Test whether audio functions outside of Teams on all three machines (play a system sound or use another app) to determine if the failure is Teams-specific or at the OS/hardware level; if audio works outside Teams, check the selected audio device in Teams settings on each machine and identify whether a shared room peripheral is the single point of failure common to all three devices.
