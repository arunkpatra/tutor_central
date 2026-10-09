# Session 15 (2026-10-09): the Phase 7 build

Model: Claude Opus 5.5, from `resume/014-phase-7-build.md`, executing `plan/phase-07-plan.md` inline
(`superpowers:executing-plans`). Outcome: Phase 7 done in PRs #63 to #73; migration 0008 and the API with the Sign in with
Apple key in production; TestFlight 1.0.0 (10) on the owner's phone and 1.0.0 (11) with the owner's findings on it. The
owner added Phase 9 (user testing, D43) and chose Next.js on Vercel for the website (D42). The task-by-task ledger, with
every ruling and its cost if wrong, is `ledger.md` beside this record.

## What was done, in order

1. PRs 1 to 4 (#63 to #66): `delete_account()` with its RLS tests (D37); the API's Apple revocation with a signed client
   secret and `APPLE_FAKE` (D38); Domain's planner, pending changes, cache age and account rules; Data's account,
   connectivity, cached reads, the change queue and runner, the notification centre and the wipe (D39, D40). Each tests
   first; the API and the database proven against the local stack.
2. PR 5 (#67): Settings in full, Account, the password, sign out that wipes, Delete account, Help, More's rows. Hand runs 1
   to 5; run 5 found the deletion's follow-up lost when the screen went (fixed: the store's task runs it).
3. PR 6 (#68): offline reads on every list, the three queued writes, back online, Pending changes. Hand runs 7 to 10 found
   the queue missing in stores built before the shell followed the session, stale screens after a send or a discard,
   and the app stuck on loading offline at launch; each fixed with a test. The owner's rule mid-build: no technical
   words on screen (D41).
4. PR 7 (#69): Teacher reminders, the scheduler, the delegate. Run 6 fired a real local notification; it found a class
   moved while the app was away planned at its old time (fixed: the register is read again on foreground). The lock
   screen took no injected taps; the reminder's link was opened directly.
5. PR 8 (#70): Dynamic Type at the accessibility sizes (rows stack, buttons wrap, sheets scroll; the default size proven
   unchanged by a pixel diff of 23 states), VoiceOver, reduced motion, the Kit's Phase 7 parts, D41's test, keyboards
   away before a write, the launch screen, 1.0.0. Run 11 found text that did not follow a size changed while the app
   ran (fixed). The accessibility record and `docs/release.md` went to `main` as documents.
6. The owner's steps 1 to 3: the Sign in with Apple key (made in the session after a first confusion with the sign-in
   setup of Phase 2), the three variables in Vercel and `api/.env.local` (Apple accepted the signed secret: a made-up
   code answered `invalid_grant`), and the deploy (run 37897295893: migration 0008, the API at `2448295`).
7. The whole-phase review (an Opus reviewer over #63 to #70): one Critical (the queue could drop a correction made
   during a send, and send a change undone during a run), four Important (a change queued online waited; an outage
   failed changes; opening the app offline dropped event and fee reminders; Back during the deletion could strand a
   deleted tutor), eleven minors. Fixed the Critical, the Important and three minors regraded (raw API words on screen,
   shown reminders surviving sign-out, Account's "Not set") in #71, each with a test that failed first. The hand run
   after the fixes found a stale screen after a send; fixed. The owner reported stale data from build 9: every list now
   reads again on coming back to the app.
8. TestFlight 1.0.0 (10) (run 37899341603). The owner tested it on his phone and reported: Start here's icons, the date of
   birth calendar collapsed, the New class header cut off, the keyboard not going away, the task field under the
   keyboard, New class from the student form, the account picture's place, the launch screen too quick. Fixed in #72 and
   #73 (three new boards approved: the class menu, Today's header, the opening fade), each proven in the simulator.
9. Google's official G and button, by Google's guidelines, with the three buttons as pills (#74, board
   P7-SignIn-Google). Run 12 of the TestFlight lane failed at signing: eleven Apple Development certificates made by
   earlier runs had filled the account's cap. The owner revoked them; the lane now revokes its own by serial (#75); build
   1.0.0 (13) uploaded and its run revoked its certificate (204).
10. Closed the phase: "As built", `README.md` (Phase 7 done; Phases 8 and 9; D42, D43), `STATE.md`, the polish list (U6
   and U9 done; U25 to U30 added), `components.md` and `information-architecture.md`, the rules files, the device tests,
   this record and the owner's messages; `resume/015-phase-8-boards-and-plan.md`.

## Why things are as they are

- **No `ErrorWords` table.** The plan's mechanical move of every error literal into one table changed nothing on screen;
  a test that reads every on-screen sentence in the sources enforces D41 for every future string instead.
- **The Dynamic Type layer stacks only at the accessibility sizes.** The first version moved layouts at the default size;
  `AdaptiveRow` with `AdaptiveSpacer` keeps the boards' `HStack` exactly until the text is too large to sit beside.
- **The queue reads itself before every send.** A snapshot let a correction be dropped and an undone change be sent. One
  window remains: a Mark paid undone while its own request is in flight is still written (the next read shows it).
- **The opening fade is ease-in-out.** A recording showed the app's `easeOut` ending a 500 ms fade in a tenth of a
  second, which reads as a cut. Apple's guidance forbids holding the launch screen; the fade adds no wait.
- **New class… is the system's menu with toggles,** because a menu `Picker` drops each class's count line.

## Deferred minors (the review's, the owner's to take)

1. Sign-out does not stop a queue run in progress (row-level security keeps it in its centre).
2. A timed-out deletion says "Check your connection… Nothing was removed" though it may have run (Retry is safe).
3. The fee reminder, once its day has passed, names next month with this month's count and total.
4. A timed-out absence log can be noted twice on replay.
5. The "Sign in again" line has no way forward but Sign out (U30).
6. The API reads `APPLE_*` at boot (a deploy without them takes the AI routes down too); `APPLE_FAKE` is not refused in
   production; the revoked code is not bound to the caller.
7. Two tests the plan named are missing: `aWriteWhileChangesWaitJoinsTheQueueInOrder` (feature-level ones exist) and
   `aLocalSignOutFailureStillEndsSignedOut`.

## Next

Phase 8's boards and plan on Fable 5.1 (`resume/015-phase-8-boards-and-plan.md`), then its build; then Phase 9.
