# Session 6 (2026-10-08): Phase 3 built, on TestFlight

Model: Claude Opus 5.5 (D17), from `resume/005-phase-3-build.md`, executing `plan/phase-03-plan.md` inline with
`superpowers:executing-plans` (a ledger of rulings kept outside the repo; the rulings are below). Outcome: PRs #24 to
#31 merged, as the plan's eight; migration 0003 in production (deploy run 37724513096, then 37731454614 with
nothing pending and the API at `7a5596a`); build 0.1.0 (5) uploaded by `testflight.yml` (run 5). The final review
found a Critical in build 5 (student saves); PR #33 fixed it and six Important findings; build 0.1.0 (6) replaces it.
D31 (the owner's ask): CI skips a commit of documents only, PR #32.

## What was done, in order

1. Read the rules, state, decisions, scope, plan and design documents. Reality matched `STATE.md`; `bun check`
   green; the local stack up. Rendered the 22 P3 boards to images with headless Chrome to set each screen beside
   its board.
2. PR #24 Domain (Tasks 1 to 3), tests first. The plan's search test could not pass as written (both fixture
   students had the same number); fixed, it then caught a real miss ("+91 98111" did not match).
3. PR #26 Data (Tasks 4, 5). The students read with the embedded invoice filter was run against the local stack
   (curl as the seed's tutor) before it merged; PostgREST writes microsecond timestamps, now tested.
4. PR #25 migration 0003 `archive_class` (Task 6), with the two RLS tests; deployed at once (D26).
5. PR #27 the Students root (Tasks 7 to 9): the components, `RegisterStore`, six states. PR #28 New student
   (Tasks 10, 11). PR #29 student detail and the deep link (Tasks 12, 13). PR #30 classes (Tasks 14 to 17). PR #31
   the Phase 2 minors in these files (Task 18).
6. Every board state photographed in both appearances and compared with its board before its PR; the pictures are
   in PRs #27 to #30.
7. Deploy (nothing pending, API at the merged head), TestFlight build 5. Documents: "As built", the design
   corrections (the popover, the context menu, `class-archive-confirm`, the `On sheet` card), the rules files.

## Why things are as they are

- **The boards win over the plan where they differ:** times and the date of birth are accent values opening the
  system pickers in a popover (the compact picker's capsule is not drawn); Edit class opens over the Classes list
  (as P3-EditClass draws it); a member's own fee is 13/600 (`footnoteStrong`, a new token with D25); no "Clear
  times" button (not drawn; Clear lives in the picker's popover).
- **Search finds four for "sh":** the rule is any part of the name (Review Focus 2); the board drew three and missed
  Lakshmi. Flagged for the owner in `STATE.md`.
- **One register per centre, shared by every Students screen:** `ShellState.register` is filled in the same pass by
  the first screen built (`@ObservationIgnored`), so a pushed detail and the list never hold two stores.
- **A missing student's screen is taken off the stack by AppShell:** a `dismiss()` during the push was lost and left
  an empty screen; found by opening a link with `simctl openurl`.
- **Pushed screens wait for the register** (`loadIfNeeded`) before deciding a student or class is missing.
- **Shadows parsed when the token is made**, not cached in a mutable global (D8).
- **`nonisolated` statics on views that tests call:** a filter closure in a view's static inherited the main actor and
  trapped the test host (two ten-minute hangs before the crash report said why).

## Rulings (from the ledger, in order)

- Task 3: the search test gave both students one number; the second student now has +91 98111 22233.
- Task 3: "+91 98111" missed (91 dropped only beyond ten digits); a typed +91 is now dropped first.
- Task 4: the classes fake orders by plain text, as Postgres does ("Class 10" before "Class 8").
- Task 4: SwiftLint refused plan code (an eight-parameter helper, long lines); the seed is a table.
- Task 7: `TileRow` takes a label type; `PickerValue` and `CheckMark` split out; new rows in `ClassRows.swift`.
- Task 8: four match "sh", not the board's three. The retry test expects one write (the failed attempt never reached
  the fake). Classes sorted as the database sorts. Writes in an extension (type length).
- Task 9: `Dependencies.cachesRegister` (fixtures never write); the student link waited for Task 13; `EmptyState`
  takes two actions; the popover does not dim the screen as the board does.
- Task 11: the date of birth is a button opening the graphical picker; the form is a `sheet(item:)`; no autofocus in
  board states.
- Task 13: `onMissing` and `TabsState.remove`; `loadIfNeeded`; the shared register; chip symbol, dialog loading.
- Task 15: Edit class over the Classes list; times as values with Clear in the popover; the class sheet at its
  content height; `classes-empty` with an empty register.
- Task 16: `footnoteStrong`; `Card(.onSheet)` and the okInk tick; the add sheet at the board's 59%.
- Task 18: the phone field drops a pasted country code itself (DesignSystem cannot see Domain); shadows parsed at
  init; haptics on `lastSavedAt` and "Saved", and with every failure toast.

## Not done, and why

- **The hand runs against the local stack in the simulator** (Tasks 11, 13, 16: add, edit, archive, delete, class
  members). Typing into the simulator through the session's tools did not land reliably (truncated, stale screens).
  Instead: every store path is tested against the fakes, every write the app sends was run with curl against the
  local stack as the seed's tutor, and both deep links were tried with `simctl openurl`. The owner's install of
  build 5 is the first hand run.

## Tried and dropped

- A compact `DatePicker` for the date of birth and the class times: its capsule is not on the boards.
- Setting `shell.register` from a deferred `Task` while building the view: the list and a pushed detail could each
  make a register in the same pass.
- `dismiss()` for a link to a missing student: lost during the push.

## Final review

A fresh reviewer (Fable) read the merged range 14a63cd..7a5596a (PRs #24 to #31), read-only. Verdict: one Critical,
six Important, with fixes. All seven fixed in PR #33, test-first where there is logic:

1. **Critical:** every student add and edit failed on the real backend (the insert's answer has no `fee_invoices`;
   `StudentRow` required it), and Retry wrote the student twice. The plan's own code; the tests decoded only rows
   with invoices and the curl checks never ran the Swift decoder. Fixed; a throwaway test then ran every Swift write
   against the local stack as the seed's tutor (and failed with the old code, passed with the fix). Build 5 carried
   the bug; the owner was told not to add or edit on it.
2. Overlapping writes undid each other (whole-list rollback): rollback per row.
3. A class edit could land on another class after the list re-sorted: looked up by id after the save.
4. A failed save's toast was hidden under the form sheet: `ToastCenter` and `ToastHost` moved to DesignSystem; the
   three sheets draw the toast over themselves.
5. An offline first launch showed "No students yet": the register is empty only after a read said so.
6. A detail whose student went while open was blank and trapped: the back row stays; the route leaves with the
   toast.
7. The pickers showed the phone's time zone: India's.

The reviewer weighed none of the 53 rulings wrong on its own; it named the deferred simulator run as where the
Critical slipped through. Lesson recorded in `ios/CLAUDE.md`: a repository's write path is proven against the local
stack in Swift before a build ships, not only by curl.

**Deferred minors** (for the polish slice or the phase that touches the file):
- `RegisterStore.fetch`: a cancelled first read (a push or tab switch mid-read) shows "Couldn't refresh…" until the
  next run (Today's store has the same pattern).
- `persist()` while an add is in flight caches the placeholder's random id; the next launch shows a phantom row
  until the refresh.
- A second failure replaces the first's Retry.
- `ClassFormSheet`: "Not set" on Ends sets 17:00 even when Starts is 17:00 (the end-before-start error at once).
- `StudentQuery`: "91 98111" (no plus, under eleven digits) does not match.
- `PhoneNumber` still accepts any `isNumber` (the field filters ASCII since #31; the Domain rule should too).
- `StudentDetailStore` uses `DayHeading.india` where the register carries an injected calendar.
- Feature-level anatomy numbers (`inlineTitleHeight` 44, `avatarSize` 56, `AddMenu.width` 260) sit in
  `Features/Students`; Phase 2 put such constants on DesignSystem components.
- `addStudent` could send the placeholder's id so a retry after a lost answer conflicts instead of duplicating.
- **The owner's call:** the register cache (children's names, parents' numbers, dates of birth, notes) stays on disk
  after sign-out, as the plan settled; the reviewer would remove it on sign-out and write it with complete file
  protection, for a shared phone.

**Declined to judge** (the reviewer's list; each stands as the plan or Phase 2 left it): a deep link before the
session is ready is dropped; the hidden navigation bar disables swipe-back (Settings' pattern); search ignores the
filter chip ("a search looks everywhere"); the popover does not dim; no pull to refresh on the detail and class
screens (no board draws it); class restore and archived classes unlisted (later); the form waits for the server
before closing (the plan's `save()`); removal by context menu only.
