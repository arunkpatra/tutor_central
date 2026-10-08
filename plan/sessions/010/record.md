# Session 10 (2026-10-08): the Phase 5 boards and the Phase 5 plan

Model: Claude Fable 5.1 (D17), from `resume/009-phase-5-boards-and-plan.md`. Outcome: Phase 0 step 0.6 done (27 boards
in row 8 of the canvas, approved), mirrored into `docs/design/`; `plan/phase-05-plan.md` written with
`superpowers:writing-plans` and approved; `resume/010-phase-5-build.md` for the Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, state, decisions, the Phase 5 scope, the Phase 0 plan, Phase 4's "As built", the design documents,
   the inventory's Phase 5 rows, the spec, the records of sessions 8 and 9, the seed and migration 0001, and the code
   the plan would touch (the Students, Attendance, Schedule and Today stores and their AppShell wiring, the Data
   repositories and fakes, the DesignSystem components and their signatures). Reality matched `STATE.md`; `bun check`
   green; the local stack up.
2. Drew the 27 boards with one Python generator (shared pieces: the shell, the title row, the month header, the money
   pair, the fee row, banners, the segmented control, sheets, fields, the toast, a drawn QR; light twins by token-block
   substitution; More and Settings by substitution from their approved sources) and looked at every one rendered by
   headless Chrome before publishing: Fees (empty, all dark and light, due, paid, overdue, payee), generate (two), mark
   paid, after mark paid with the undo toast, the receipt, remind, waive, Parent payments (three), the student detail's
   fees section, a student's fees, Reports (fees dark and light, attendance, export, empty), More (dark and light),
   Settings. Two fixes before showing (the reminder sheet's subhead wrapped; the export sheet's unselected ring drew
   small). Published as row 8 (y 10400, a title note at 10100).
3. The owner approved the set. Mirrored the sources and the index into `docs/design/`, extended `components.md`
   ("Phase 5 parts": the money pair, the fee row's lines, the overdue banner, the payee card, the generate, mark paid,
   waive and message sheets with the two texts, the undo toast, Parent payments, a student's fees, Reports, the CSV
   sheet), `information-architecture.md` (the 24 launch states, the board table, what the boards settle),
   `design-tokens.md` ("Numbers in code": undo as a second write, the waive reason's 200 characters, overdue, the payee
   confirmation), ticked 0.6, committed to `main` (D12).
4. Fetched the local stack's real answers for every Phase 5 read and write with curl as the seed's tutor (the month's
   invoices, due before, `generate_fees`, the centres row, a reminder insert and read, mark paid, undo, waive, a
   student's months, the confirmation update), then reset the seed, so the plan's decoding fixtures are real.
5. Wrote `plan/phase-05-plan.md`: 15 tasks, 6 pull requests, tests first against the fakes, every read decoded from
   the pasted answers and every write proven in Swift before its PR merges, four RLS tests, the DesignSystem parts, the
   stores with their tests, the screens as pieces, the hand runs as a table in Task 15 with what the simulator cannot
   do, a Review Focus of five, a decisions table, a self-review (one fix: the button size `.row` already existed; the
   paid-day rule moved into Domain from Task 1). The owner approved the plan.
6. Wrote `resume/010-phase-5-build.md`, indexed it, updated `STATE.md`, `README.md`, the phase file, this record and
   the owner's messages; committed to `main`.

## Why things are as they are

- **No migration.** The resume asked whether a reminder must point at its invoice and whether "how many will be
  created" needs a new read. Neither: `(student_id, period)` is unique on `fee_invoices`, so a `message_log` row with
  its student and `about_date` set to the month's first day names the invoice exactly (0005's column, reused); and the
  generate preview is counted on the device by the function's own rule (active students without a fee, the student's
  fee else the class's else 0). Everything else was in 0001 from Phase 1.
- **Overdue is a rule with a banner, not a mixed list.** A fee of a month before the current one that is still due is
  overdue; its own month's view marks it; the current month's view shows "₹1,000 overdue from September · 1 parent"
  and moves there on tap. One list per month, old debt still visible, the month's Outstanding honest.
- **The payee card on Fees, Parent payments as one pushed screen.** The inventory keeps "parents are told to pay <id>,
  not right?" as a quiet reminder on Fees until confirmed once; Settings' "Parent payments" row and Fees' Payments
  action open the same screen. A changed id asks again.
- **Generate from two places.** The empty month's primary button and the ledger's section action, so "generating twice
  says so" has a place to be seen (the sheet reads "Everyone has a fee for October", the button disabled).
- **Mark paid waits; Undo is a second write.** Money is the tutor's: nothing is held back from the server for the
  toast's sake (a killed app would lose a payment); Undo reverses with a write of its own. `design-tokens.md`'s line
  was reworded (it said a toast with undo "waits 8 s before committing").
- **Waive from the Mark paid sheet.** One entry point ("Waive this fee instead"), no hidden menu; a waived fee is
  settled, not collected, and can be marked paid later from the student's fees.
- **The QR is kept on the phone, not uploaded.** The reference app keeps the QR to show a parent; the inventory keeps
  "remove". No Storage bucket and no migration: Application Support, complete file protection, Remove deletes it.
  The camera is VisionKit's scanner behind a wrapper (D8); the simulator has none, so the plan proves the path from
  Photos with a generated QR and the camera on the owner's phone.
- **The student detail's Remind and Mark paid open on the Fees tab**, as Mark attendance opens on the Attendance tab
  (Phase 4's precedent): the sheets stay in one feature, rule 4 holds, and AppShell refreshes the register after a
  write so the detail's row agrees.
- **Reports under More with Share as a sheet first.** The sheet names the file and its columns before the system
  share sheet, so the tutor knows what they are sending; the CSV is a `ShareLink` over a temporary file.
- **The fixtures gain a past.** September's ten fees (Nikhil's still due) and Hemanth's August and July give the
  overdue banner, the overdue month and a student's months real rows; the boards' other figures are illustrative
  (the owner's rule).
- **Boards by generator, checked by headless Chrome, as session 8:** the built-in browser pane is not reliable for a
  gallery; contact sheets of six boards each were sent to the owner.

## Tried and dropped

- A migration adding `message_log.invoice_id` with a composite key (and a `(centre_id, id)` unique on
  `fee_invoices`): `about_date` already names the month and the pair is unique.
- An AppShell-presented fee sheet over the Students tab (so the detail's Mark paid stays on its screen): two
  presentation paths for the same sheets; the tab switch is simpler and has a precedent.
- The `invoice_id` on `MonthFee` (the register's embedded fee) for the detail's actions: `FeeAction` names the student
  and the month instead, so the students fixture need not be re-fetched.

## Machine

As sessions 8 and 9: Xcode 27, the iPhone 17 simulator, bun, Docker with the local stack, Google Chrome 155 headless
for the renders. The generator, the renders and the contact sheets live in the session's scratchpad and `.shots/`;
the canvas and `docs/design/mockups/` hold the real copies.

## Next

The build in a fresh Opus 5.5 session from `resume/010-phase-5-build.md`. Then Phase 0 step 0.7 (the Phase 6 boards)
on Fable.
