# Phase 5: Fees, UPI settings, reminders, receipts, reports

**Status:** Planned (session 10, 2026-10-08): the 27 boards approved (row 8 of the canvas), `phase-05-plan.md` approved; the
build next from `resume/010-phase-5-build.md`. **Depends on:** Phase 3 (Phase 4 for the attendance part of reports); Phase 0's
Phase 5 boards (approved 2026-10-08).

## Goal

Money is clear: who owes what this month, one tap to remind a parent on WhatsApp with the right UPI id, one
tap to mark paid and send a receipt, and a month's report the tutor can share.

## Scope

1. **Fees month view.** Month navigator; outstanding and collected; ledger with All, Due, Paid; overdue
   (a past month, still due) marked; each row: student, amount, status, paid-by; empty state before generation.
2. **Generate month.** One due invoice per active student without one for the month, through
   `generate_fees` (idempotent); the sheet says how many will be created before it runs; a student's fee is
   the class fee unless overridden.
3. **Mark paid.** Method (UPI, cash, other) and date (today by default); undo within the toast; waive with a
   reason. Partial payments out of scope.
4. **Remind.** WhatsApp deep link with the message naming the student, the month, the amount and the UPI id
   (or payment link); copied to the clipboard as a fallback; logged in `message_log` with the time.
5. **Receipt.** After mark paid, if receipts are on: a WhatsApp deep link with the receipt text; logged.
6. **UPI settings.** UPI id, payment link, receipts switch; UPI QR: scan with the camera or pick from Photos,
   decoded on device (`upi://pay?pa=`) to fill the id; remove; "parents are told to pay <id>, not right?" on
   Fees until confirmed once (`upi_confirmed_at`).
7. **Student detail, fees.** The student's ledger, with mark paid and remind in place.
8. **Reports.** Month navigator; fees collected and outstanding with per-student rows; attendance summary per
   student (present, absent, percentage); export fees and attendance as CSV through the share sheet.
9. **Domain rules, tested.** Invoice status including overdue; totals; message texts; UPI QR parsing; CSV
   shape; month maths.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Generating twice for the same month creates nothing the second time and says so.
- Remind opens WhatsApp with the right number and text; the log records it.
- A QR from a real UPI app fills the id correctly.
- The CSV opens in Numbers with the expected columns.
- Domain tests cover every rule in item 9.

## As built

(Written when the phase ends.)
