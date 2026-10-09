# Phase 7: Settings, account, notifications, offline hardening, release candidate

**Status:** Done (session 15, 2026-10-09, PRs #63 to #75). **Depends on:** Phases 2 to 6; Phase 0's Phase 7 boards (approved 2026-10-09, row 10).

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

Session 15 (2026-10-09, Opus 5.5, from `resume/014-phase-7-build.md`), the plan's 23 tasks in eleven pull requests:

| PR | What |
|---|---|
| #63 | `public.delete_account()` (migration 0008, D37), the second and last `security definer`; two RLS tests |
| #64 | The API's `POST /account/revoke-apple` (D38): a client secret signed with the Sign in with Apple key (ES256, Node `crypto`), `APPLE_FAKE=1` locally |
| #65 | Domain: the reminder planner, pending changes, the cache age, the account rules |
| #66 | Data: account, connectivity, cached reads with file protection, the change queue and its runner, the notification centre, the wipe (D39, D40) |
| #67 | Settings in full, Account, a password, sign out that wipes, Delete account, Help, More's rows |
| #68 | Offline: every list from its copy on the iPhone, three writes queued and sent in order, Pending changes; no technical words on screen (D41) |
| #69 | Teacher reminders: the screen, the planner on sign-in, foreground and every saved write, a tapped reminder opens its link |
| #70 | Hardening: Dynamic Type, VoiceOver, reduced motion, the Kit's Phase 7 parts, no backend words, the launch screen, 1.0.0 |
| #71 | The whole-phase review's fixes (one Critical, four Important, three minors regraded), fresh data on foreground |
| #72 | The owner's build-10 findings: Start here's labels, every calendar, sheet headers, the keyboard, the task field; New class… from the student form |
| #73 | Today's account picture at the top right; the launch screen fading into the app |
| #74 | Sign-in: Google's official G and button (Google's guidelines), the three buttons as pills (P7-SignIn-Google) |
| #75 | The TestFlight lane revokes the Apple Development certificate each run makes (eleven had filled Apple's cap and stopped run 12) |

**Production:** migration 0008 and the API at `2448295` with `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` (deploy run
37897295893; Apple accepted the signed secret, answering a made-up code with `invalid_grant`). TestFlight: 1.0.0 (10) (run
37899341603) on the owner's phone; 1.0.0 (11) with #72 and #73 (run 37906652352); 1.0.0 (13) with #74 (run 37913258080,
which revoked its own certificate); run 12 failed at signing and left no build.

**Where it moved from the plan, and why** (the rulings are in `plan/sessions/015/record.md`):
- D41, from the owner mid-build: no technical words on screen; the approved texts with "server" were reworded and a test
  (`ErrorWordsTests`) reads every on-screen sentence in the sources. It replaced the plan's `ErrorWords` table.
- The Dynamic Type layer (`AdaptiveRow` and its kin) stacks rows only at the accessibility sizes; at every other size the
  boards' layout is unchanged, proven by a pixel diff. Text now follows a size changed while the app runs.
- The reviewer found the queue could drop a correction made during a send and send a change undone during a run; the
  runner now reads the queue before each send and removes only what it sent, and runs at once for a change queued online.
- Every list reads again on coming back to the app (the owner saw stale data on build 9).
- Run 6's tap-to-open could not be driven in the simulator (its lock screen takes no injected taps); the reminder's link
  was opened directly and the tap is the tester's D2.
- Google's official mark: taken at the end (#74), with Google's button colours and all three buttons as pills.
- Cloud signing on a fresh runner makes an Apple Development certificate per run; eleven filled the account's cap. The
  owner revoked them; the lane now revokes its own by serial (#75).

**Not done here:** the external group and Beta App Review (they need Phase 8's privacy page; Phase 9 runs them, D43);
the tester's D1 to D7; seven review minors (`plan/sessions/015/record.md`); U7, U16, U24 and U25 to U30 on the polish list.
