# Session 7 (2026-10-08): the simulator runbook (issue #34)

Model: Claude Opus 5.5 (D17), from `resume/006-simulator-runbook.md`. Outcome: `docs/runbooks/simulator.md`, linked
from `CLAUDE.md` and `ios/CLAUDE.md`; D32; PR #35 (`bun check` tests run with `-collect-test-diagnostics never`); one
full hand run from a cold simulator against the local stack, every write confirmed on screen and in the database, the
screenshots on issue #34, which is closed.

## What was done, in order

1. Read the rules, state, decisions, issue #34 and session 6's record. Reality matched `STATE.md` (`main` clean at
   75571c4, no open PR, the stack up, the iPhone 17 booted). Neither `idb` nor AXe installed.
2. Built a Debug build against the local stack (`SUPABASE_URL` checked in the built Info.plist) and measured each
   avenue on the booted simulator, keeping every screenshot in the session's scratchpad.
3. Put the one owner decision (a debug sign-in launch option) to the owner with the evidence; the owner chose the
   screens.
4. PR #35: `iosTestCommand()` in `tools/check/steps.ts` carries the flag, test first; `bun check --fresh` green; CI
   green; merged.
5. Wrote the runbook, then followed it literally from a shutdown simulator and a reset seed: sign-in (first try),
   add, edit, archive, restore, delete a student, a deep link, add a class, move a student into it, archive it.
6. Folded the run's lessons back into the runbook; D32; the links; re-seeded the local database; the documents to
   `main`; the proof on issue #34; closed it.

## What was measured (why the runbook says what it says)

- **Taps always landed.** Session 6's "missed tap" was a screenshot taken straight after the tap, before the sheet
  arrived (the tool's screenshot and `simctl io screenshot` alike); a simctl shot 2 s later showed the sheet up.
- **`text` returns before delivery.** A burst of simctl screenshots every 0.4 s while typing 26 characters into
  search: one frame showed 23, the next all 26. A Sign in tap sent at once after `text` posted a cut-off password
  (`invalid_credentials` in `supabase_auth`'s log; curl with the same password answered 200; the field later showed
  all 13 dots). A second tap after a wait signed in. Session 6's "meera@e" was the same race.
- **The phone field drops digits under injected typing:** 10 digits sent at once, "98123 4" landed. `PhoneWell`
  rewrites its text when the sixth digit adds the group space, and keys injected during the rewrite are lost. Six
  digits, a wait, then four: all ten, every time it was tried (twice). A person typing does not race the rewrite;
  no app change was made.
- **The pasteboard works** (`simctl pbcopy`, a second tap on the focused field, Paste): no permission prompt, the
  value whole, tried on the name field (not on the phone field); three taps per value, so it is the fallback.
- **The hardware-keyboard setting is not a factor here:** it belongs to the Simulator app, which this setup does not
  run (the device is booted headless and streamed to the tool's panel); the software keyboard is up throughout.
  Not toggled.
- **The session survives a relaunch and a reboot:** after `simctl shutdown all`, boot and reinstall the app opened on
  Today signed in; after terminate and launch too. `ios/CLAUDE.md` said the opposite ("no session survives a
  relaunch"); corrected.
- **Cold start costs:** shutdown 3 s, boot to ready 5 s, install 4 s, Debug build 30 s cold and 8 s warm. The first
  keyboard after a boot showed iOS's one-time "slide to type" tip in place of the keys; Continue dismisses it.
- **Password sign-in brings iOS's "Save Password?" sheet;** "Not Now" dismisses it.

## Decisions

- **D32** (the runbook, the hand run before a TestFlight build that changes a write path, no launch option, no other
  driver).
- **No debug sign-in launch option:** the owner's choice, after the evidence that the screens sign in every time with
  the waits. It would have been Debug-only, refused any non-local `SUPABASE_URL`, and taken the credentials from the
  launch command so none sat in the app's code.
- **AXe and idb not installed:** third-party tools on the owner's Mac, adding element lookup by label and reading a
  field's value; not needed once the waits are kept.
- **XCUITest not used:** the most deterministic driver (`typeText` waits, `waitForExistence`), but a UI test suite
  (D15), a target to keep, and no watched run for the owner.
- `-collect-test-diagnostics never` applies in CI too (CI runs the same `bun check`); a ten-minute stall costs more
  there than the diagnostics are worth.

## Tried and dropped

- Building into `.build/` at the repo root: not ignored. The runbook uses the default DerivedData, where `bun shots`
  looks too.
- A first deep-link check without a screenshot between the back tap and the link: it could not say which action had
  shown the screen. Redone to a different student with a shot between; the runbook now says a shot after every
  action.

## Seen in passing (not changed)

- Today still shows Phase 2's fixed content beside a full register: "Start here: Add your first students" with 10
  students, and "No classes yet" beside "1 Classes today". By the Phase 2 plan (phase-02-plan.md:3345), so not a
  regression; for the owner's UI polish pass or the phase that makes Today live.
- A student moved into a class keeps their own fee (Dev's ₹1,000 in a ₹900 class), as information-architecture.md
  says; the class form's line "Students you add to this class start at this fee" holds only for students without one.

## Not done, and why

- Nothing the issue asked was left. The owner reported nothing from build 6 this session.
