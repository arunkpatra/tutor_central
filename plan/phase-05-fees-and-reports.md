# Phase 5: Fees, UPI settings, reminders, receipts, reports

**Status:** Done (session 11, 2026-10-08): PRs #45 to #49, #51 and #52; the hand run on issue #50; build 0.1.0 (8) on
TestFlight. **Depends on:** Phase 3 (Phase 4 for the attendance part of reports); Phase 0's
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

Session 11 (2026-10-08, Claude Opus 5.5, from `resume/010-phase-5-build.md`), by `phase-05-plan.md` with
`superpowers:executing-plans`: tests first against the fakes, every read decoded from the local stack's answers,
every write run in Swift against the stack before its pull request, every screen photographed in both appearances
beside its board, the D32 hand run (issue #50).

| PR | What |
|---|---|
| #45 | Domain: `FeeInvoice` and `FeeState` (overdue), `FeeLedger` and `FeeTotals`, the overdue summary, `GeneratePreview`, `PaymentSettings`, `FeeMessage` (reminder, receipt), `UPIID`, `UPIQR`, the two CSVs |
| #46 | Data: the fees repository and its fake, fee logs on `message_log` by month, the centre's payment columns, `QRImageStore`; four RLS tests |
| #47 | The Fees tab: the month, the filters, the overdue banner, the payee card, generate, mark paid with Undo, the receipt, remind, waive; the DesignSystem parts; the fees link; Today's Due tile (U12 closed) |
| #48 | A student's fees and the detail's fee row with Remind and Mark paid |
| #49 | Parent payments: the UPI id, the QR from Photos and the camera, the link, receipts; Settings' row |
| #51 | Reports: the month's fees and attendance, Share as CSV; More's row |
| #52 | The hand run's two fixes and the final review's: Undo closes the receipt; the Due tile opens this month; Undo after paying a waived fee waives it again; a screen's workspace change keeps the other screens' fields; the camera asked for and the scanner closable |

**Acceptance, line by line**

- Every screen matches its board; pictures in #47, #48, #49, #51 (both appearances). The figures follow the fixtures.
- Generating twice creates nothing the second time and says so: RLS test, `FeesStoreTests`, and the hand run (10, then
  "Everyone has a fee for November", ₹11,300 once in the database).
- Remind opens WhatsApp with the right number and text and the log records it: `FeeMessageTests`, `FeesStoreTests`,
  the hand run (the wa.me link opened, a `reminder` row about the month, the row reads "Reminded today", the text on
  the pasteboard).
- A QR from a real UPI app fills the id correctly: the decoder reads a Core Image UPI QR in tests and from Photos in
  the simulator; the camera on the owner's iPhone with build 0.1.0 (8): "installed the build and tested on iphone. test ok."
- The CSV opens in Numbers with the expected columns: the hand run (Save to Files, copied out, Numbers read 11 rows,
  7 columns, names whole, amounts as numbers; the BOM on disk, pinned by `ReportsStoreTests`).
- Domain tests cover every rule in item 9: `FeeInvoiceTests`, `FeeLedgerTests`, `GeneratePreviewTests`,
  `FeeMessageTests`, `UPITests`, `CSVTests`.

**Deviations, and why** (every one is in `plan/sessions/011/record.md`)

- A waived month on a student's fees shows Mark paid only (D34, the owner's answer): P5-StudentFees drew it bare,
  and the Waive sheet promises "You can still mark it paid later". Undo after that Mark paid waives it again (#52).
- The fee row's name is not a link, as the boards draw it; `information-architecture.md` said it opened the detail
  and is corrected.
- The P5-Fees boards render the money pair's numbers white because of a CSS typo in their source
  (`tabular-nums color: var(--due)`); the source, the Kit and `components.md` name `due` and `ok`, so they are built
  coloured.
- A past month's Outstanding reads "1 parent, overdue" (P5-Fees-Overdue).
- On the fee sheets the toast sits above the footer button, so the 8 s Undo toast never hides the receipt's Open
  WhatsApp.
- The camera scanner is a sheet (a swipe closes it), not a full-screen cover; Scan a QR asks for the camera the first
  time and says where to allow a refused one (#52).
- Vision's current barcode revision cannot run in the simulator ("Could not create inference context") and answers
  empty on CI's runner: `QRDecoder` falls back to revision 1 whenever the current one reads nothing.
- A screen's workspace change is merged onto the session's current workspace with only its own fields
  (`Workspace.takingSettings(from:)`, `takingPayments(from:)`, `RootView.applyWorkspace`): Settings' older copy had
  put back a replaced UPI id (#52).
- Shared parts moved into DesignSystem: `BackRow` (from Attendance) and `SaveMark` (from Settings); the step 0.2 Kit
  `FeeRow` was replaced by the settled one.

**What remains:** the review's deferred minors (`plan/sessions/011/record.md`); the polish rows U13 and U14
(`plan/ui-polish.md`).
