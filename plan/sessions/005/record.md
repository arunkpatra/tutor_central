# Session 5 (2026-10-08): the Phase 3 boards and the Phase 3 plan

Model: Claude Fable 5.1 (D17), from `resume/004-phase-3-boards-and-plan.md`. Outcome: Phase 0 step 0.4 done (22
boards in row 6 of the canvas, approved with one tweak), mirrored into `docs/design/`; `plan/phase-03-plan.md`
written with `superpowers:writing-plans` and approved; `resume/005-phase-3-build.md` for the Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, state, decisions, the Phase 3 scope, the Phase 0 plan, Phase 2's "As built", the design
   documents and every Phase 2 and Kit board source, the inventory, the spec, the session 4 record, the schema and
   the RLS tests, the shell, the stores and the Kit components. Reality matched `STATE.md`; `bun check` green.
2. Drew the 22 boards in four groups, each published to the canvas as it landed (row 6, y 7600, a title note at
   y 7300): the Students list (empty, few, many dark and light, searching, filtered, the "+" menu), the student form
   (new empty, filled, invalid; edit), the student detail (dark, light, archived) with the archive and typed delete
   confirmations, classes (empty, list), the class form (new; edit with Archive class), the class detail and its
   add-students sheet. Every board from the token values and the Kit, with the seed's content on Wednesday
   7 October 2026 at 18:30. The light twins and the derived states (archived, confirmations, invalid, edit, the
   sheets over their screens) were generated from their dark source by text substitution so they cannot drift.
3. Looked at the set as a flow before asking: a local gallery page served over localhost into the built-in browser
   pane (file: URLs render as static snapshots there and iframes do not load). Two fixes before approval: a row's
   second line wrapped (the phone left the row; the class row's fee left its subtitle), and the chip row now bleeds
   to the screen edge; the class detail's bottom hint was dropped so nothing runs under the home indicator.
4. The owner approved with one tweak: plain labels on "Add a student" and "Scan register" (and, for consistency,
   on the empty classes board's "Create a class"). Mirrored the sources and the index into `docs/design/`, extended
   `components.md` (search field, filter chip, banner, picker tiles on a sheet, day picker, menu, the member,
   meeting and checklist rows, the row's second-line rule, the later row, the dialog's primary for a reversible
   action) and `information-architecture.md` (the 20 launch states, the board table, what the boards settle),
   ticked 0.4, committed to `main` (D12).
5. Wrote `plan/phase-03-plan.md`: 19 tasks, 8 pull requests, tests first against the fakes, one migration, a
   Review Focus of five, a decisions table, a self-review whose corrections were applied in the text (the paid
   method on `MonthFee`, `student-edit` photographed with the detail, the dialog owns the typed-name test). The owner
   approved it.
6. Wrote `resume/005-phase-3-build.md`, indexed it, updated `STATE.md`, `README.md`, the two phase files, this
   record and the owner's messages; committed to `main`.

## Why things are as they are

- **Search under the large title, chips to the edge, a Classes row on the root:** the Students root is the one place
  the tutor works from; the chips filter by class (the inventory's "filter by class"), the Classes row is the way to
  the classes list from the tab (the IA lists Classes among the tab's pushed screens), and the sort is a quiet
  menu so the count line stays one line.
- **The row's second line is the class, not the phone:** at 13 pt the class and the number together wrapped in
  every row; the detail has the number with Call and WhatsApp; the phone takes the line only when there is no class
  yet or when a search matched it.
- **The fee status is this month's invoice:** the inventory asks for "status chips (fee due)"; `fee_invoices` exists
  since 0001 and the seed pays six; Phase 5 owns the ledger, Phase 3 reads one month.
- **An empty fee means the class fee:** the phase file's "monthly fee (prefilled from the class)" with the column's
  nullable `monthly_fee`; the helper line says which fee applies so the tutor never guesses.
- **Archive confirms with a primary button, delete types the first name:** archive is reversible (components.md's
  rule gives primary to the action unless it is destructive); delete removes history (the Kit's typed dialog). The
  copy names the student: the seed has no gender, so no pronoun.
- **Class archive at the bottom of its edit sheet:** the class detail is full with the week and the members; the
  student's archive stays on its detail where the board has room.
- **Pushed screens hide the tab bar:** detail and form screens are one task each (Settings already does this).
- **No new table, one function:** 0001 holds every column; `archive_class` is two statements; assigning students is
  one `update … in (…)`; delete cascades by the existing foreign keys, which the plan proves with a test.
- **`Classroom`:** `Class` reads as the keyword; the word on screen stays "class".
- **The "+" menu is a popover, not a `Menu`:** a system `Menu` cannot be opened by a launch argument, so its board
  state could not be photographed (D7); a `.popover` with the board's rows can, and the system still draws the glass.
  `components.md` says "the system draws it"; Task 19 of the plan corrects the wording.
- **Removal from a class through the row's context menu:** the members sit in a card, not a `List`, so there is no
  swipe action; `information-architecture.md` says swipe and is corrected at Task 19.
- **A JSON cache per centre:** the spec's "repository → cache (memory, then disk) → view" for a list that must show at
  once on a weak connection; the stale pattern covers the refresh.
- **Optimistic writes except delete:** the spec's "optimistic in the store, confirmed by the repository, reverted with
  a toast on failure"; a delete cascades, so nothing can be shown before the server has done it.
- **The Kit unchanged:** the new components appear on the Phase 3 boards, not on a Kit board; adding them to the Kit
  screen would change an approved board's picture.

## Tried and dropped

- Opening the boards in the browser pane as `file:` URLs (static snapshots, no iframes): served them over localhost
  with a ten-line Bun server instead.
- The parent's phone on every row's second line (wrapped), the fee on the class row's subtitle (wrapped), a swipe
  hint under the class members (ran under the home indicator).
- A system `Menu` for "+" (no launchable state), a swipe to remove a member (no `List`), a `Class` type name.

## Machine

As session 4. The scratch gallery and the board sources also live in the session's scratchpad; the canvas and
`docs/design/mockups/` hold the real copies.

## Next

The build in a fresh Opus 5.5 session from `resume/005-phase-3-build.md`. Then Phase 0 step 0.5 (Phase 4 boards)
on Fable.
