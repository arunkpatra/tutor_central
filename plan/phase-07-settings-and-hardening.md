# Phase 7: Settings, account, notifications, offline hardening, release candidate

**Status:** Planned: `phase-07-plan.md` approved 2026-10-09 (session 14); the build is next (resume 014). **Depends on:** Phases 2 to 6; Phase 0's Phase 7 boards (approved 2026-10-09, row 10).

## Goal

Everything around the product is finished: settings that save as you go, reminders on the device, account
deletion that really deletes, the app behaving well without a connection, and a release-candidate build on
TestFlight with the help and legal pages in place.

## Scope

1. **Settings.** Teaching profile; parent payments (from Phase 5); parent messages (WhatsApp only, D3);
   teacher reminders (notification permission state, class, event and unpaid fee switches, refresh); haptic
   feedback; about (version, build); privacy policy and terms (hosted pages); saved marks instead of a Save
   button.
2. **Account.** Email, sign-in methods, set or change password, sign out, delete account permanently with a
   typed confirmation that calls `delete_centre` and signs out.
3. **Local notifications.** Class reminders before each meeting, event reminders, an unpaid-fee reminder on a
   chosen day of the month; scheduled on the device, refreshed on foreground and after edits; each opens its
   deep link.
4. **Offline.** Cached reads for every list; honest offline states; a queued-write layer for attendance marks
   and mark-paid that replays on reconnect with conflict rules (last write wins per row, the user told when a
   replay fails).
5. **Hardening.** Dynamic Type at every size on every screen; VoiceOver labels on every control; reduced
   motion; the Kit reviewed in both appearances; launch time and list scrolling measured on the oldest iOS 26
   iPhone; error wording reviewed; a release checklist in `docs/release.md`.
6. **Release candidate.** Version 1.0, build from CI, TestFlight external group for the owner's testers,
   release notes.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Reminders fire at the right times in the simulator and on the owner's phone.
- Deleting an account removes every row of the centre; a second sign-in starts at onboarding.
- Attendance marked in airplane mode arrives when the connection returns.
- The release checklist is complete and the TestFlight build is on the owner's phone.

## As built

(Written when the phase ends.)
