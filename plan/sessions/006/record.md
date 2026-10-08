# Session 6 (2026-10-08): Phase 3 built, on TestFlight

Model: Claude Opus 5.5 (D17), from `resume/005-phase-3-build.md`, executing `plan/phase-03-plan.md` inline with
`superpowers:executing-plans` (a ledger of rulings kept outside the repo; the rulings are below). Outcome: PRs #24 to
#31 merged, as the plan's eight; migration 0003 in production (deploy run 37724513096, then 37731454614 with
nothing pending and the API at `7a5596a`); build 0.1.0 (5) uploaded by `testflight.yml` (run 5). No new decision
number: no ruling changed a rule.

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

(Recorded below when the reviewer's pass is in.)
