# Phase 5 Fees, UPI Settings, Reminders, Receipts and Reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Money is clear: the Fees tab shows who owes what this month and what is overdue from before, one tap reminds a parent on WhatsApp with the UPI id, one tap marks a fee paid (with Undo) and offers a receipt, a month's fees are generated in one tap that says what it will make, the tutor's UPI id is set by typing or from a QR, a student's fees read from their page, and a month's report of fees and attendance shares as CSV; every screen built to its approved Phase 5 board in both appearances, every write proven against the local stack by the runbook (D32), on TestFlight.

**Architecture:** `Domain` gains the fee types and rules (`FeeInvoice` and its state including overdue, the ledger's rows and totals, the generate preview, the reminder and receipt texts, the UPI id rule and the UPI QR payload, the two CSVs), all tested first. `Data` gains a fees repository (reads by month and by student, the due-before read, `generate_fees`, mark paid, mark due, waive), fee logs on the message log (`reminder` and `receipt` rows whose `about_date` is the month, so no migration), the centre's payment settings on the centre repository, a QR image store, and in-memory fakes seeded as `supabase/seed.sql` seeds plus the boards' past months; every read's answer is decoded in a test against the local stack's real text (pasted below), and every write path is run in Swift against the stack before its pull request merges. No migration: 0001 holds every column (the resume's two questions answered in the decisions table). `Features/Fees` holds the Fees tab (one store per centre on `ShellState`), the five sheets, a student's fees, Parent payments (with the QR from Photos and the camera) and Reports with the CSV export; the student detail (Students) gains its live fees row and hands Remind and Mark paid to the Fees tab through `StudentsActions`. `AppShell` adds the routes, the `fees?month=` link, Today's Due tile into the Due filter, the live rows on More and Settings, and the 24 Phase 5 launch states. U12 closes with Task 9.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, `supabase-swift` 2.55.3 (PostgREST reads, updates with `select().single()`, one RPC), Vision (`VNDetectBarcodesRequest`) for the QR from Photos, VisionKit (`DataScannerViewController` behind a `UIViewControllerRepresentable`, D8) for the camera, `PhotosPicker`, `ShareLink` for the CSV, Bun tests against local Supabase, XcodeGen, GitHub Actions on `xcode-27` (D22), the simulator runbook (D32).

**Spec:** `docs/spec.md` sections 2, 5 and 7; scope and acceptance in `plan/phase-05-fees-and-reports.md`; the boards `docs/design/mockups/P5-*.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 8; the list, the launch states and what the boards settle in `docs/design/information-architecture.md`, "Phase 5 boards"); `design-tokens.md` ("Numbers in code": undo reverses with a second write, a waive reason is 200 characters, overdue is a past month still due, the payee confirmation until confirmed once), `components.md` ("Phase 5 parts": every new row, card and sheet, and the two message texts), `guidelines.md`; the Fees, Attendance (export) and Settings (parent payments) rows of `docs/reference/functional-inventory.md`; decisions D1 to D33 in `plan/README.md`; Phase 4's "As built" and the rulings in `plan/sessions/009/record.md` (the lint's shapes); `docs/runbooks/simulator.md` for every hand run; `plan/ui-polish.md` (U12 closes here; U9 is offered to the owner, not taken).

## Global Constraints

- iOS 26.0 minimum, iPhone only (D1), bundle id `in.tutorcentral.app` (D27). Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation (D8). Features never import each other: Students reaches the Fees sheets through `StudentsActions.openFeeAction(FeeAction)` (a Domain value), AppShell fulfils it by switching to the Fees tab; Fees reaches a student through `FeesActions.openStudent`. UIKit only behind a wrapper with the reason in the file: the camera scanner (`QRScannerView`), because SwiftUI has no barcode camera.
- The lint's shapes (session 9's rulings, a dozen of them): no tuple of three or more members anywhere (a struct with named fields); at most six parameters to a function (an initialiser may take more: give a value its own struct with an `init`); files under 400 lines (a store over it splits into `+Extension.swift` files); no force-unwrap in a test (SwiftFormat removes them: use `try #require(...)`); `@MainActor` on the fakes and the stores; a pure `static func` on a view is `nonisolated`.
- Style only through `DesignSystem` tokens (D10, D25): no raw colour, size, radius, shadow or duration in a feature view. A board value the document does not name becomes a token in `design-tokens.md` and Swift in the same commit; an anatomy number lives as a named constant on its component. Every new component gets a SwiftUI preview. The Kit boards are unchanged by this phase: the fee row, the money pair and the undo toast were on the Kit from step 0.2.
- Both appearances built and photographed (D13, D23). Every board state is a `LaunchState` whose raw value is the name in `information-architecture.md`'s Phase 5 table; `bun shots <state>` photographs it; every pull request that changes what is seen carries the table `bun pr-shots` prints, for each changed state in both appearances (D7, `CLAUDE.md` rule 2). No board, no screen (rule 1): a state this plan did not foresee is drawn and approved first. Where a board settles a layout, a detent or an interaction, the build follows the board; where it shows a figure the seed cannot produce, the screen follows the data and the board is not redrawn (the owner, 2026-10-08).
- Copy: sentence case, no exclamation marks, no emoji, no jargon ("fee" never "invoice" on screen); buttons are verbs with an object; errors say what happened and what to do (`guidelines.md`). The copy of every screen is on its board and repeated in the task that builds it. The parent-facing texts are those of `components.md` ("Phase 5 parts"), word for word.
- Money `₹4,000` (`Money.formatted`); dates `4 Oct`, `Tue 6 Oct`, `Today, 7 Oct`; months `October 2026`; the file names `fees-2026-10.csv`, `attendance-2026-10.csv`. The centre's calendar is India (`DayHeading.india`); every rule takes a `Calendar` and the tests pass `DayHeading.india`.
- Database (`supabase/CLAUDE.md`): no migration in this phase. Every write goes through RLS (`fee_invoices_member`, `message_log_member`, `centres_owner_update`) or the existing `generate_fees` (`security invoker`). The column checks are the rules the app keeps: `status = 'paid'` if and only if `paid_at` is set; `upi_id` matches `^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$`; `period` is the first of a month. New RLS tests pin the writes (Task 4). Nothing to deploy with `deploy.yml` (no migration, no API change); the TestFlight lane needs nothing pending, which holds.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/AppShellTests`, `Tests/StudentsTests` and the new `Tests/FeesTests` (in `Package.swift` and the scheme in `project.yml`). Stores are tested against the fakes. No UI test suites (D15). Every repository read decodes a fixture copied from what the local stack answers (`curl` as the seed's tutor; the texts below were taken on 2026-10-08 and are pasted whole), and every write path is run in Swift against the local stack before its pull request merges (`ios/CLAUDE.md`: a throwaway test with an in-memory session, deleted before the commit).
- Hand runs (D32): before the TestFlight build, every write path this phase adds is driven through the screens against the local stack by `docs/runbooks/simulator.md` and confirmed in the database; Task 15 names each run, what the simulator cannot do (the camera: the owner's phone; the CSV: copied out of the simulator's container into Numbers), and the owner's step.
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). Bun only (D16). `supabase-swift` stays the only iOS dependency (D14): Vision, VisionKit and PhotosUI are Apple's frameworks, not dependencies. A new decision gets its number in `plan/README.md` in the pull request that acts on it.
- Nothing from the reference app is dropped (rule 10): the inventory's Fees rows (the ledger by month with all, due, paid and overdue; outstanding and collected; generate a month idempotently; mark paid with method and date; remind by WhatsApp link, logged; a receipt after mark paid; UPI id, payment link, QR from the camera or Photos, remove; "parents are told to pay <id>" until confirmed; the monthly report with attendance and CSV), the Attendance export row and the Settings "Parent payments" row are all placed below. The message quota stays deferred (D4).

## Review Focus

Inputs the spec implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **Overdue must be a rule, never a guess, and must not leak into the month's own numbers:** a due fee of a month before the current one is overdue; a due fee of the current month is not, even on the 31st; a due fee of a future month is due; a waived fee is never overdue; the current month's Outstanding counts only that month, the banner carries the earlier months' sum and parent count and names the latest such month. Tests in Task 1 (`FeeInvoiceTests`: `overdueIsAPastMonthStillDue`, `theBannerSumsEarlierMonthsAndNamesTheLatest`).
2. **Money writes must be true on the server before the screen says so, and Undo must undo exactly one thing:** Mark paid waits for the server and shows the button loading; a failed write leaves the row due with a toast and Retry; Undo reverses the one fee the toast names (status due, `paid_at` and `paid_method` null), not the last row touched; a second Mark paid within the 8 s replaces the toast and the first fee stays paid; a failed Undo says so and the fee stays paid. Tests in Task 8 (`FeesStoreTests`: `markingPaidWaitsForTheServerAndOffersUndo`, `undoReversesTheOneFeeNamed`, `aFailedMarkPaidKeepsTheRowDueWithRetry`, `aFailedUndoLeavesTheFeePaid`) and Task 4 (`rls.test.ts`: `an undo returns a paid fee to due`).
3. **Generate must count what the function will make, from the same rule:** active students without a fee for the month, archived students never, the amount the student's own fee else the class's else 0, grouped by class with "No class" last, the total; a month where everyone has one says so and the button is disabled; after the function answers, the count it returns is what the toast says, and the screen re-reads the month. Tests in Task 1 (`GeneratePreviewTests`: `countsOnlyActiveStudentsWithoutAFee`, `amountsFollowTheFeeRule`) and Task 8 (`FeesStoreTests`: `generatingReadsTheMonthAgainAndSaysHowMany`, `nothingToCreateDisablesTheButton`).
4. **A reminder must name the right amount, month and payee, and must still open with no UPI id:** the text names the child, the month, the amount and the UPI id; with a payment link too, both; with neither, the second sentence is left out; a student with no parent number shows the text with the button disabled and "Add the parent's number first"; opening logs one `reminder` row about the month and the row then reads "Reminded today"; a receipt names the method and day, and is not offered when receipts are off or the parent has no number. Tests in Task 2 (`FeeMessageTests`: `theReminderNamesEverything`, `withoutAPayeeTheReminderStillReads`) and Task 8 (`FeesStoreTests`: `remindingLogsOnceAndReadsReminded`, `aReceiptIsOfferedOnlyWhenOnAndThereIsANumber`).
5. **The UPI id must be valid before it is saved, from the field or from a QR, and a changed id must ask again:** typing is normalised (trimmed, lower-cased) and refused in words when it does not match the column's rule; a QR payload that is not `upi://pay?pa=…` is refused with "That QR is not a UPI QR"; a payload with a valid `pa` fills and saves the id; saving a changed id clears the confirmation so Fees asks "Parents are told to pay … not right?" again; the CSV escapes a name with a comma or a quote so Numbers opens it whole. Tests in Task 2 (`UPITests`: `typedIDsAreNormalisedAndRefusedInWords`, `aQRPayloadGivesItsPayeeOrNothing`), Task 11 (`PaymentsStoreTests`: `aChangedIDClearsTheConfirmation`, `aBadQRIsRefusedInWords`) and Task 3 (`CSVTests`: `namesWithCommasAndQuotesAreEscaped`).

---

## Decisions this plan settles

Small and medium things, decided here and written down. None needs a number in `plan/README.md`.

| Decision |
|---|
| **No migration.** The resume's two questions: a reminder does not need to point at its invoice, because `(student_id, period)` is unique on `fee_invoices`, so a `message_log` row with `kind = 'reminder'` (or `'receipt'`), `student_id` and `about_date = <the month's first day>` names the invoice exactly (0005 added `about_date`); and "how many will be created" is counted on the device from the register and the month's invoices, by the same rule as `generate_fees` (active students without a fee for the month; the student's own fee else the class's else 0), so no new read. 0001 holds the rest: `fee_invoices` with `waived_reason`, `generate_fees`, `centres.upi_id`, `upi_confirmed_at`, `payment_link`, `send_receipts`. |
| **Writes that wait, and Undo as a second write (money is the tutor's).** Mark paid, waive, generate and every Parent payments save wait for the server (the button loading, or the Saved mark after). After Mark paid the row moves and a toast offers Undo for 8 s (`toastStayUndo`); Undo writes status `due`, `paid_at` and `paid_method` null, and waits too. Nothing on this tab is optimistic; nothing is held back from the server for the toast's sake (a killed app would lose a payment). `design-tokens.md` "Numbers in code" says so. |
| **The fee row's line.** Due or overdue: the parent's name and number, or "Reminded Tue 6 Oct" in `ok` with a tick when a reminder about that month was opened (the latest log); paid: "Paid by UPI on 4 Oct" ("by cash", "on 4 Oct" alone for other); waived: "Waived · <reason>". In All: due and overdue rows first, then paid, then waived, each by name. The name is not a link on the Fees tab (the buttons are the row's actions); the student detail is reached through the Students tab. |
| **Overdue.** `FeeInvoice.state(current:)`: `.overdue` when due and `period < current`; the month view marks its own rows; the current month's view reads `dueBefore(centre:month:)` for the banner ("₹1,000 overdue from September · 1 parent", the latest month with one; "from September and before" when more than one month), which moves the month. The Due filter and Outstanding are the shown month's only. |
| **The payee card** shows on every month's view while `upi_confirmed_at` is null and `upi_id` is set; "That's right" writes `upi_confirmed_at = now()`; Change pushes Parent payments. With no `upi_id` the empty-row card "No UPI id yet · Add" shows instead. Saving a changed `upi_id` writes `upi_confirmed_at = null` in the same update. |
| **Generate** opens from the empty card's button and the ledger's Generate action, for the shown month (past months too: a tutor who starts in October can make September's). The sheet is the content's height (`.fraction(0.65)` with `.large`, as the alert). `generate(month:)` returns the count; the toast says "10 fees created for October."; the month is read again. |
| **Mark paid's day.** Today by default; any earlier day through the system date picker in a popover (`calendarPopover`), never a future day. `paid_at` is `now()` when the day is today, else that day at 12:00 in India, so the paid day reads back as chosen. |
| **The receipt** opens as a sheet right after a successful Mark paid when `send_receipts` is on and the parent has a number; Cancel skips it; the undo toast shows under the sheet (`SheetToasts`) and still works. |
| **Remind** logs first, then opens the link, as the absence alert does; the text is also copied to the pasteboard (`UIPasteboard.general.string`) when Open WhatsApp is tapped, for a phone without WhatsApp. |
| **Waive** sets `status = 'waived'` and `waived_reason` (1 to 200 characters, trimmed); `paid_at` and `paid_method` stay null. A waived fee marked paid later clears `waived_reason`. A waived row has no buttons on the Fees tab; the student's fees row offers Mark paid on it. |
| **Parent payments** is `Features/Fees` (`PaymentsView`), pushed on whichever tab asked (Settings' row on More, Fees' Payments action). Saves as you go with the Settings pattern (`SaveState`, the Saved mark beside "UPI"). The QR image is kept on this iPhone only (`QRImageStore`, Application Support `TutorCentral/upi-qr-<centre id>.png`), never uploaded; Remove deletes the file and keeps the id. The camera path is `DataScannerViewController` (QR only) behind `QRScannerView`; the simulator has no camera, so the button says "No camera on this device" there and the owner proves it on the phone. |
| **A student's fees** (`StudentFeesView`, Fees) is pushed on the Students tab from the detail's See all; its Remind and Mark paid, and the detail's, switch to the Fees tab at that month with the sheet open (`FeeAction`), as Mark attendance switches to the Attendance tab. After any fee write AppShell refreshes the register (`shell.register?.refresh()`), so the detail's row and the list's chips agree. |
| **Reports** (`ReportsView`, Fees) is pushed from More; its store is per screen with a load generation (month moves). Share opens the CSV sheet; its primary is a `ShareLink` over a file written to the temporary directory (`fees-2026-10.csv`), so the system share sheet follows. The attendance CSV counts marks by student from the month's sessions, as History does. |
| **One fees store per centre** (`ShellState.fees`), so a tab switch keeps the month and the filter; reset on sign-out with the rest. Today's Due tile sets the filter to Due and selects the tab. `tutorcentral://fees?month=YYYY-MM` opens the tab at that month (a month that does not parse opens the current one). |
| **Type names.** `FeeInvoice` (one row of `fee_invoices`), `FeeState` (due, overdue, paid, waived), `FeeFilter`, `FeeTotals`, `FeeLedger` (the rules), `GeneratePreview`, `FeeMessage` (reminder and receipt), `UPIID`, `UPIQR`, `FeesCSV`, `AttendanceCSV`, `CSVRow` helpers, `FeeAction`, `PaymentSettings` (on `Centre`), `FeeLog` (Data). |
| **Fixtures.** `FakeFeesRepository.seed`: October's ten (six paid 4 Oct by UPI, as the register fake), September's ten (nine paid 3 Sep by UPI, Nikhil due: the overdue banner and P5-Fees-Overdue), Hemanth's August (cash, 5 Aug) and July (waived, "Joined mid-month") for P5-StudentFees; ids `bbbbbbbb-0000-0000-0000-%012d`. `FakeMessageLogRepository.feeSeed`: Dev reminded Tue 6 Oct about October, Nikhil reminded Wed 30 Sep about September. `FakeCentreRepository.meeraWorkspace` gains payments (`meera@okhdfcbank`, no link, receipts on, confirmed 1 Oct); `Fixtures` gives `fees-payee` the unconfirmed variant and `fees-empty`, `payments-empty` no UPI id. |

## File structure

```
supabase/
  tests/rls.test.ts                                   # + mark paid and undo, waive, a reminder read back by its month, generate twice
ios/
  App/Info.plist                                      # + NSCameraUsageDescription
  project.yml                                         # + FeesTests in the scheme
  TutorCentralKit/Package.swift                       # + FeesTests (depends on Fees, Students for a real register)
  TutorCentralKit/Sources/Domain/
    FeeInvoice.swift (FeeInvoice, FeeState), FeeLedger.swift (FeeFilter, FeeTotals, the rows), GeneratePreview.swift
    FeeMessage.swift, UPI.swift (UPIID, UPIQR), CSV.swift (CSVRow, FeesCSV, AttendanceCSV), FeeAction.swift
    Centre.swift (+ PaymentSettings)
  TutorCentralKit/Sources/Data/
    Fees/FeesRepository.swift, SupabaseFeesRepository.swift, FakeFeesRepository.swift, InvoiceRow.swift
    Messages/MessageLogRepository.swift (+ FeeLog, feeLogs, logFee), SupabaseMessageLogRepository.swift, FakeMessageLogRepository.swift
    Centres/CentreRepository.swift (+ payments), SupabaseCentreRepository.swift (CentreRow + 4 columns), FakeCentreRepository.swift
    Cache/QRImageStore.swift (protocol, FileQRImageStore, MemoryQRImageStore)
  TutorCentralKit/Sources/DesignSystem/Components/
    FeeRows.swift (FeeRow, FeeRowLine, FeeButtons), MoneyPair.swift, PayeeCard.swift, OnSheetRows.swift (OnSheetRow, ChoiceCard)
    ReportRows.swift (ReportFeeRow, ReportAttendanceRow), QRRow.swift, Banner.swift (+ a tappable chevron variant)
  TutorCentralKit/Sources/Features/Fees/
    FeesStore.swift, FeesStore+Writes.swift, FeesStore+Messages.swift, FeesActions.swift
    FeesView.swift, FeesSections.swift, GenerateSheet.swift, MarkPaidSheet.swift, WaiveSheet.swift, FeeMessageSheet.swift
    StudentFeesStore.swift, StudentFeesView.swift
    PaymentsStore.swift, PaymentsView.swift, QRDecoder.swift, QRScannerView.swift
    ReportsStore.swift, ReportsView.swift, ExportSheet.swift, Fees.swift (delete the marker)
  TutorCentralKit/Sources/Features/Students/
    StudentDetailStore.swift (+ messages, the reminded line), StudentDetailSections.swift (MonthFeeCard with buttons), StudentsActions.swift (+ openFeeAction)
  TutorCentralKit/Sources/Features/Settings/SettingsView.swift (the Parent payments row live), SettingsStore.swift (unchanged)
  TutorCentralKit/Sources/Features/Today/TodayView.swift (the Due tile → openFeesDue), TodayStore.swift (TodayActions + openFeesDue)
  TutorCentralKit/Sources/AppShell/
    RootView+Fees.swift (new: the store, the roots, the actions), TabsView.swift (the Fees root, the routes), TabsState.swift (Route cases, open(.fees)),
    ShellState.swift (fees), MoreView.swift (Reports live), RootView+LaunchStates.swift, LaunchState.swift (+24), Fixtures.swift (+ fees, workspace variants),
    Dependencies.swift (fees, qrImages), LaterView.swift (feesTab and studentFees removed; U12), RootView+Students.swift (openStudentFees, openFeeAction)
  TutorCentralKit/Tests/DomainTests/FeeInvoiceTests.swift, FeeLedgerTests.swift, GeneratePreviewTests.swift, FeeMessageTests.swift, UPITests.swift, CSVTests.swift
  TutorCentralKit/Tests/DataTests/InvoiceRowTests.swift, FakeFeesRepositoryTests.swift, CentreRowTests.swift, FeeLogRowTests.swift
  TutorCentralKit/Tests/FeesTests/FeesStoreTests.swift, StudentFeesStoreTests.swift, PaymentsStoreTests.swift, QRDecoderTests.swift, ReportsStoreTests.swift
  TutorCentralKit/Tests/StudentsTests/StudentDetailStoreTests.swift (+ the reminded line)
  TutorCentralKit/Tests/AppShellTests/LaunchStateTests.swift (+ Phase 5), TabsStateTests.swift (+ the fees link)
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 to 3 | `phase-5/domain` | Domain: fees and their states, the ledger, the generate preview, the messages, UPI, CSV | none |
| 2 | 4 to 6 | `phase-5/data` | Data: the fees repository, fee logs, the centre's payments, the QR store, the fakes, every answer decoded; the RLS tests | none |
| 3 | 7 to 9 | `phase-5/fees` | The Fees tab: the month, due, paid, overdue, the payee, generate, mark paid with undo, the receipt, remind, waive | `fees-empty`, `fees`, `fees-due`, `fees-paid`, `fees-overdue`, `fees-payee`, `fees-generate`, `fees-generate-nothing`, `fees-mark-paid`, `fees-marked-paid`, `fees-receipt`, `fees-remind`, `fees-waive`, `today`, both appearances |
| 4 | 10 | `phase-5/student-fees` | A student's fees and the detail's fees section live | `student-fees-due`, `student-fees`, `student`, both |
| 5 | 11, 12 | `phase-5/payments` | Parent payments: the UPI id, the QR from Photos and the camera, the link, receipts; Settings' row | `payments-empty`, `payments`, `payments-qr`, `settings`, both |
| 6 | 13, 14 | `phase-5/reports` | Reports: the month's fees and attendance, share as CSV; More's row | `reports`, `reports-attendance`, `reports-export`, `reports-empty`, `more`, both |
| main | 15 | | The hand runs, TestFlight; as built, state, record, resume (documents only, D12) | |

---

### Task 1: Domain: the fee, its state, the ledger, the generate preview (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/FeeInvoice.swift`, `FeeLedger.swift`, `GeneratePreview.swift`, `FeeAction.swift`
- Modify: `ios/TutorCentralKit/Sources/Domain/Centre.swift` (`PaymentSettings`)
- Test: `ios/TutorCentralKit/Tests/DomainTests/FeeInvoiceTests.swift`, `FeeLedgerTests.swift`, `GeneratePreviewTests.swift`

**Interfaces:**
- Consumes: `Money`, `Period`, `Day`, `MonthFee.Status`, `MonthFee.PaidMethod`, `Student`, `Classroom`, `Student.fee(in:)`.
- Produces:

```swift
/// One row of `fee_invoices`: a student's fee for a month.
public struct FeeInvoice: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public let studentID: UUID
    public let period: Period
    public let amount: Money
    public let status: MonthFee.Status
    public let paidAt: Date?
    public let paidMethod: MonthFee.PaidMethod?
    public let waivedReason: String?
    public init(id: UUID, studentID: UUID, period: Period, amount: Money, status: MonthFee.Status, paidAt: Date?, paidMethod: MonthFee.PaidMethod?, waivedReason: String?)
    /// Due, overdue (due and before the current month), paid, waived.
    public func state(current: Period) -> FeeState
    public func paidOn(calendar: Calendar) -> Day?
    /// "Paid by UPI on 4 Oct", "Paid by cash on 5 Aug", "Paid on 4 Oct" (other); "Waived · Joined mid-month"; nil when due.
    public func settledLine(calendar: Calendar) -> String?
    /// Today's payment is now; an earlier day's is that day at 12:00 in the calendar, so it reads back as chosen.
    public static func paidAt(for day: Day, today: Day, now: Date, calendar: Calendar) -> Date
    public static let waiveReasonLimit = 200
}
public enum FeeState: Hashable, Sendable, CaseIterable { case due, overdue, paid, waived
    public var word: String   // "Due", "Overdue", "Paid", "Waived"
    public var isSettled: Bool   // paid or waived
}
public enum FeeFilter: Hashable, Sendable, CaseIterable { case all, due, paid
    public var title: String   // "All", "Due", "Paid"
}
public struct FeeTotals: Hashable, Sendable {
    public let outstanding: Money; public let outstandingCount: Int; public let collected: Money; public let paidCount: Int; public let total: Int
    public var outstandingLine: String   // "4 parents" / "1 parent" / "Nothing due"
    public var collectedLine: String     // "6 of 10 paid"
    public init(invoices: [FeeInvoice])  // outstanding = due or overdue; collected = paid only (waived is settled, not collected)
}
public enum FeeLedger {
    /// The rows of a filter: All is due and overdue first, then paid, then waived, each by `name`; Due is due and overdue; Paid is paid.
    public static func rows(_ invoices: [FeeInvoice], filter: FeeFilter, current: Period, name: (UUID) -> String) -> [FeeInvoice]
    /// "10 fees", "4 due", "6 paid", "1 fee".
    public static func title(count: Int, filter: FeeFilter) -> String
    /// The earlier months' due fees: their sum, how many parents, and the latest month; nil when none.
    public static func overdueBefore(_ invoices: [FeeInvoice], current: Period) -> OverdueSummary?
}
public struct OverdueSummary: Hashable, Sendable { public let amount: Money; public let parents: Int; public let latest: Period; public let months: Int
    public var text: String   // "₹1,000 overdue from September · 1 parent"; "₹2,200 overdue from September and before · 2 parents"
}
/// What Generate will make for a month: the students without a fee, by class.
public struct GeneratePreview: Hashable, Sendable {
    public struct Group: Hashable, Sendable, Identifiable { public let id: String; public let name: String; public let count: Int; public let total: Money
        public var line: String   // "Class 10 Maths · 6 students", "No class · 1 student"
    }
    public let month: Period; public let groups: [Group]; public let count: Int; public let total: Money
    public static func make(students: [Student], classes: [Classroom], invoices: [FeeInvoice], month: Period) -> GeneratePreview
    public var title: String      // "10 fees will be created" / "1 fee will be created" / "Everyone has a fee for October"
    public var line: String       // "One for each student without a fee for October, from the class fee or the student's own." / "Nothing to create. A student you add later gets one from here."
    public var buttonLabel: String   // "Create 10 fees" / "Nothing to create"
    public var canCreate: Bool
}
/// What the Students tab asks the Fees tab to do for a student's month.
public enum FeeAction: Hashable, Sendable { case remind(studentID: UUID, month: Period), markPaid(studentID: UUID, month: Period) }
/// The centre's payment settings (centres.upi_id, payment_link, send_receipts, upi_confirmed_at).
public struct PaymentSettings: Hashable, Sendable { public var upiID: String?; public var paymentLink: String?; public var sendReceipts: Bool; public var upiConfirmedAt: Date?
    public init(upiID: String? = nil, paymentLink: String? = nil, sendReceipts: Bool = true, upiConfirmedAt: Date? = nil)
    public var needsConfirmation: Bool   // upiID set and upiConfirmedAt nil
}
// Centre gains `public var payments: PaymentSettings` with a default of `PaymentSettings()` in its init.
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/FeeInvoiceTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct FeeInvoiceTests {
    static let october = Period(year: 2026, month: 10)
    static let september = Period(year: 2026, month: 9)
    static func invoice(_ n: Int, month: Period, status: MonthFee.Status = .due, amount: Int = 1000, paidAt: Date? = nil,
                        method: MonthFee.PaidMethod? = nil, reason: String? = nil) -> FeeInvoice {
        FeeInvoice(
            id: UUID(uuidString: String(format: "bbbbbbbb-0000-0000-0000-%012d", n)) ?? UUID(),
            studentID: UUID(uuidString: String(format: "aaaaaaaa-0000-0000-0000-%012d", n)) ?? UUID(),
            period: month, amount: Money(rupees: amount), status: status, paidAt: paidAt, paidMethod: method, waivedReason: reason
        )
    }
    static let paidOn4Oct = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 11)) ?? .distantPast
}

/// Wednesday 7 October 2026, 18:30 in India (the boards' moment; Domain cannot see Data's FakeCountsRepository).
enum FakeInvoiceClock {
    static let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18, minute: 30)) ?? .distantPast

    @Test func overdueIsAPastMonthStillDue() {
        #expect(Self.invoice(1, month: Self.september).state(current: Self.october) == .overdue)
        #expect(Self.invoice(1, month: Self.october).state(current: Self.october) == .due)
        #expect(Self.invoice(1, month: Self.october.next).state(current: Self.october) == .due, "a future month is due, not overdue")
        #expect(Self.invoice(1, month: Self.september, status: .waived, reason: "Joined mid-month").state(current: Self.october) == .waived)
        #expect(Self.invoice(1, month: Self.september, status: .paid, paidAt: Self.paidOn4Oct, method: .upi).state(current: Self.october) == .paid)
        #expect(FeeState.overdue.word == "Overdue" && FeeState.paid.isSettled && FeeState.waived.isSettled && !FeeState.overdue.isSettled)
    }

    @Test func theSettledLineNamesTheMethodAndDay() {
        let upi = Self.invoice(1, month: Self.october, status: .paid, paidAt: Self.paidOn4Oct, method: .upi)
        #expect(upi.settledLine(calendar: DayHeading.india) == "Paid by UPI on 4 Oct" && upi.paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 4))
        #expect(Self.invoice(1, month: Self.october, status: .paid, paidAt: Self.paidOn4Oct, method: .cash).settledLine(calendar: DayHeading.india) == "Paid by cash on 4 Oct")
        #expect(Self.invoice(1, month: Self.october, status: .paid, paidAt: Self.paidOn4Oct, method: .other).settledLine(calendar: DayHeading.india) == "Paid on 4 Oct")
        #expect(Self.invoice(1, month: Self.october, status: .waived, reason: "Joined mid-month").settledLine(calendar: DayHeading.india) == "Waived · Joined mid-month")
        #expect(Self.invoice(1, month: Self.october).settledLine(calendar: DayHeading.india) == nil)
    }

    @Test func theBannerSumsEarlierMonthsAndNamesTheLatest() {
        let august = Period(year: 2026, month: 8)
        let invoices = [
            Self.invoice(1, month: Self.october), Self.invoice(2, month: Self.september, amount: 1000),
            Self.invoice(3, month: august, amount: 1200), Self.invoice(3, month: Self.september, status: .paid, paidAt: Self.paidOn4Oct, method: .upi),
            Self.invoice(4, month: august, status: .waived, reason: "x"),
        ]
        let summary = FeeLedger.overdueBefore(invoices, current: Self.october)
        #expect(summary?.amount == Money(rupees: 2200) && summary?.parents == 2 && summary?.latest == Self.september && summary?.months == 2)
        #expect(summary?.text == "₹2,200 overdue from September and before · 2 parents")
        let one = FeeLedger.overdueBefore([Self.invoice(2, month: Self.september, amount: 1000)], current: Self.october)
        #expect(one?.text == "₹1,000 overdue from September · 1 parent")
        #expect(FeeLedger.overdueBefore([Self.invoice(1, month: Self.october)], current: Self.october) == nil)
    }

    @Test func aPaidDayBecomesNoonOrNow() throws {
        let today = Day(FakeInvoiceClock.now, calendar: DayHeading.india)
        #expect(FeeInvoice.paidAt(for: today, today: today, now: FakeInvoiceClock.now, calendar: DayHeading.india) == FakeInvoiceClock.now)
        let earlier = try #require(Day(year: 2026, month: 10, day: 4))
        let at = FeeInvoice.paidAt(for: earlier, today: today, now: FakeInvoiceClock.now, calendar: DayHeading.india)
        #expect(Day(at, calendar: DayHeading.india) == earlier && DayHeading.india.component(.hour, from: at) == 12)
    }

    @Test func totalsCountDueAndOverdueAsOutstandingAndOnlyPaidAsCollected() {
        let invoices = [
            Self.invoice(1, month: Self.october, amount: 1000), Self.invoice(2, month: Self.october, amount: 1200),
            Self.invoice(3, month: Self.october, status: .paid, amount: 1500, paidAt: Self.paidOn4Oct, method: .upi),
            Self.invoice(4, month: Self.october, status: .waived, amount: 800, reason: "x"),
        ]
        let totals = FeeTotals(invoices: invoices)
        #expect(totals.outstanding == Money(rupees: 2200) && totals.outstandingCount == 2 && totals.outstandingLine == "2 parents")
        #expect(totals.collected == Money(rupees: 1500) && totals.paidCount == 1 && totals.total == 4 && totals.collectedLine == "1 of 4 paid")
        #expect(FeeTotals(invoices: []).outstandingLine == "Nothing due" && FeeTotals(invoices: [invoices[0]]).outstandingLine == "1 parent")
    }
}
```

`Tests/DomainTests/FeeLedgerTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct FeeLedgerTests {
    static let october = FeeInvoiceTests.october
    static let names: [Int: String] = [1: "Dev Kumar", 2: "Akshita Rao", 3: "Sahil Verma", 4: "Nikhil Das", 5: "Hemanth Reddy"]
    static func name(_ id: UUID) -> String {
        let n = Int(id.uuidString.suffix(1)) ?? 0
        return names[n] ?? "?"
    }

    @Test func allListsDueThenPaidThenWaivedEachByName() {
        let invoices = [
            FeeInvoiceTests.invoice(2, month: Self.october, status: .paid, paidAt: FeeInvoiceTests.paidOn4Oct, method: .upi),
            FeeInvoiceTests.invoice(1, month: Self.october),
            FeeInvoiceTests.invoice(3, month: Self.october, status: .waived, reason: "x"),
            FeeInvoiceTests.invoice(5, month: Self.october),
            FeeInvoiceTests.invoice(4, month: FeeInvoiceTests.september),
        ]
        let all = FeeLedger.rows(invoices, filter: .all, current: Self.october, name: Self.name)
        #expect(all.map { Self.name($0.studentID) } == ["Dev Kumar", "Hemanth Reddy", "Nikhil Das", "Akshita Rao", "Sahil Verma"])
        #expect(FeeLedger.rows(invoices, filter: .due, current: Self.october, name: Self.name).map(\.studentID) == [invoices[1], invoices[3], invoices[4]].map(\.studentID))
        #expect(FeeLedger.rows(invoices, filter: .paid, current: Self.october, name: Self.name).map(\.studentID) == [invoices[0].studentID])
        #expect(FeeLedger.title(count: 10, filter: .all) == "10 fees" && FeeLedger.title(count: 1, filter: .all) == "1 fee")
        #expect(FeeLedger.title(count: 4, filter: .due) == "4 due" && FeeLedger.title(count: 6, filter: .paid) == "6 paid")
        #expect(FeeFilter.allCases.map(\.title) == ["All", "Due", "Paid"])
    }

    @Test func paymentSettingsKnowWhenToAsk() {
        #expect(PaymentSettings(upiID: "meera@okhdfcbank").needsConfirmation)
        #expect(!PaymentSettings(upiID: "meera@okhdfcbank", upiConfirmedAt: Date()).needsConfirmation)
        #expect(!PaymentSettings().needsConfirmation, "no id: nothing to confirm; the empty card shows instead")
        #expect(PaymentSettings().sendReceipts, "receipts are on by default, as the column is")
    }
}
```

`Tests/DomainTests/GeneratePreviewTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct GeneratePreviewTests {
    static let october = FeeInvoiceTests.october
    static let maths = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID(), name: "Class 10 Maths", subject: nil,
        monthlyFee: Money(rupees: 1200), meetingDays: [.monday], startTime: nil, endTime: nil, archivedAt: nil
    )
    static let science = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333332") ?? UUID(), name: "Class 8 Science", subject: nil,
        monthlyFee: Money(rupees: 1000), meetingDays: [.tuesday], startTime: nil, endTime: nil, archivedAt: nil
    )
    static func student(_ n: Int, _ name: String, classID: UUID?, fee: Int? = nil, archived: Bool = false) -> Student {
        Student(
            id: UUID(uuidString: String(format: "aaaaaaaa-0000-0000-0000-%012d", n)) ?? UUID(), name: name, classID: classID,
            monthlyFee: fee.map(Money.init(rupees:)), parentName: nil, parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil,
            archivedAt: archived ? Date() : nil, thisMonth: nil
        )
    }
    static let students = [
        student(1, "Akshita Rao", classID: maths.id), student(2, "Riya Sharma", classID: maths.id, fee: 1500),
        student(3, "Dev Kumar", classID: science.id, fee: 1000), student(4, "Sahil Verma", classID: nil, fee: 800),
        student(5, "Gone Student", classID: maths.id, archived: true), student(6, "No Fee Anywhere", classID: nil),
    ]

    @Test func countsOnlyActiveStudentsWithoutAFee() {
        let preview = GeneratePreview.make(students: Self.students, classes: [Self.maths, Self.science], invoices: [], month: Self.october)
        #expect(preview.count == 5 && preview.total == Money(rupees: 4500) && preview.canCreate)
        #expect(preview.groups.map(\.line) == ["Class 10 Maths · 2 students", "Class 8 Science · 1 student", "No class · 2 students"])
        #expect(preview.groups.map(\.total) == [Money(rupees: 2700), Money(rupees: 1000), Money(rupees: 800)])
        #expect(preview.title == "5 fees will be created" && preview.buttonLabel == "Create 5 fees")
        #expect(preview.line == "One for each student without a fee for October, from the class fee or the student's own.")
    }

    @Test func amountsFollowTheFeeRule() {
        // Akshita already has October's fee; Riya's own fee beats the class's; No Fee Anywhere is ₹0 (as generate_fees makes it).
        let existing = FeeInvoiceTests.invoice(1, month: Self.october, amount: 1200)
        let preview = GeneratePreview.make(students: Self.students, classes: [Self.maths, Self.science], invoices: [existing], month: Self.october)
        #expect(preview.count == 4 && preview.total == Money(rupees: 3300))
        #expect(preview.groups.first?.line == "Class 10 Maths · 1 student" && preview.groups.first?.total == Money(rupees: 1500))
        let one = GeneratePreview.make(students: [Self.students[3]], classes: [], invoices: [], month: Self.october)
        #expect(one.title == "1 fee will be created" && one.buttonLabel == "Create 1 fee")
    }

    @Test func nothingToCreateSaysSo() {
        let invoices = Self.students.filter { !$0.isArchived }.enumerated().map { i, s in
            FeeInvoice(id: UUID(), studentID: s.id, period: Self.october, amount: .zero, status: .due, paidAt: nil, paidMethod: nil, waivedReason: nil)
        }
        let preview = GeneratePreview.make(students: Self.students, classes: [Self.maths, Self.science], invoices: invoices, month: Self.october)
        #expect(preview.count == 0 && !preview.canCreate && preview.groups.isEmpty)
        #expect(preview.title == "Everyone has a fee for October" && preview.buttonLabel == "Nothing to create")
        #expect(preview.line == "Nothing to create. A student you add later gets one from here.")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `FeeInvoice`, `FeeLedger`, `GeneratePreview`, `PaymentSettings` not found.

- [ ] **Step 3: Implement**

`Domain/FeeInvoice.swift`:

```swift
import Foundation

/// One row of `fee_invoices`: a student's fee for a month, due until paid or waived.
public struct FeeInvoice: Hashable, Sendable, Identifiable, Codable {
    public static let waiveReasonLimit = 200
    public let id: UUID
    public let studentID: UUID
    public let period: Period
    public let amount: Money
    public let status: MonthFee.Status
    public let paidAt: Date?
    public let paidMethod: MonthFee.PaidMethod?
    public let waivedReason: String?

    public init(
        id: UUID, studentID: UUID, period: Period, amount: Money, status: MonthFee.Status, paidAt: Date?,
        paidMethod: MonthFee.PaidMethod?, waivedReason: String?
    ) {
        self.id = id
        self.studentID = studentID
        self.period = period
        self.amount = amount
        self.status = status
        self.paidAt = paidAt
        self.paidMethod = paidMethod
        self.waivedReason = waivedReason
    }

    /// A due fee of a month before the current one is overdue (design-tokens.md, Numbers in code).
    public func state(current: Period) -> FeeState {
        switch status {
        case .paid: .paid
        case .waived: .waived
        case .due: period < current ? .overdue : .due
        }
    }

    public func paidOn(calendar: Calendar) -> Day? {
        paidAt.map { Day($0, calendar: calendar) }
    }

    /// Today's payment is now; an earlier day's is that day at noon, so it reads back as chosen (P5-MarkPaid's day).
    public static func paidAt(for day: Day, today: Day, now: Date, calendar: Calendar) -> Date {
        guard day != today else { return now }
        return calendar.date(byAdding: .hour, value: 12, to: day.date(in: calendar)) ?? now
    }

    /// The fee row's second line once settled (components.md, Fee row).
    public func settledLine(calendar: Calendar) -> String? {
        switch status {
        case .due: return nil
        case .waived: return "Waived · \(waivedReason ?? "")"
        case .paid:
            let day = paidOn(calendar: calendar).map { " on \($0.shortText)" } ?? ""
            switch paidMethod {
            case .upi: return "Paid by UPI\(day)"
            case .cash: return "Paid by cash\(day)"
            case .other, nil: return "Paid\(day)"
            }
        }
    }
}

/// How a fee stands today: the chip's word and tone.
public enum FeeState: Hashable, Sendable, CaseIterable {
    case due
    case overdue
    case paid
    case waived

    public var word: String {
        switch self {
        case .due: "Due"
        case .overdue: "Overdue"
        case .paid: "Paid"
        case .waived: "Waived"
        }
    }

    /// Paid or waived: nothing left to collect.
    public var isSettled: Bool {
        self == .paid || self == .waived
    }
}
```

`Domain/FeeLedger.swift`:

```swift
import Foundation

/// The Fees tab's three filters (P5-Fees-All, -Due, -Paid).
public enum FeeFilter: Hashable, Sendable, CaseIterable {
    case all
    case due
    case paid

    public var title: String {
        switch self {
        case .all: "All"
        case .due: "Due"
        case .paid: "Paid"
        }
    }
}

/// The money pair over a month (components.md, Money pair hero): outstanding is due and overdue, collected is paid
/// only; a waived fee is settled, not collected.
public struct FeeTotals: Hashable, Sendable {
    public let outstanding: Money
    public let outstandingCount: Int
    public let collected: Money
    public let paidCount: Int
    public let total: Int

    public init(invoices: [FeeInvoice]) {
        let due = invoices.filter { $0.status == .due }
        let paid = invoices.filter { $0.status == .paid }
        outstanding = due.map(\.amount).total
        outstandingCount = due.count
        collected = paid.map(\.amount).total
        paidCount = paid.count
        total = invoices.count
    }

    public var outstandingLine: String {
        switch outstandingCount {
        case 0: "Nothing due"
        case 1: "1 parent"
        default: "\(outstandingCount) parents"
        }
    }

    public var collectedLine: String {
        "\(paidCount) of \(total) paid"
    }
}

/// The earlier months' due fees, for the current month's banner (components.md, Overdue banner).
public struct OverdueSummary: Hashable, Sendable {
    public let amount: Money
    public let parents: Int
    public let latest: Period
    public let months: Int

    public var text: String {
        let from = months > 1 ? "\(latest.monthName) and before" : latest.monthName
        return "\(amount.formatted) overdue from \(from) · \(parents == 1 ? "1 parent" : "\(parents) parents")"
    }
}

public enum FeeLedger {
    /// A filter's rows: All is due and overdue first, then paid, then waived, each group by name.
    public static func rows(
        _ invoices: [FeeInvoice], filter: FeeFilter, current: Period, name: (UUID) -> String
    ) -> [FeeInvoice] {
        let kept = invoices.filter { invoice in
            switch filter {
            case .all: true
            case .due: !invoice.state(current: current).isSettled
            case .paid: invoice.status == .paid
            }
        }
        func rank(_ invoice: FeeInvoice) -> Int {
            switch invoice.status {
            case .due: 0
            case .paid: 1
            case .waived: 2
            }
        }
        return kept.sorted { a, b in
            let (ra, rb) = (rank(a), rank(b))
            return ra != rb ? ra < rb : name(a.studentID).localizedCaseInsensitiveCompare(name(b.studentID)) == .orderedAscending
        }
    }

    public static func title(count: Int, filter: FeeFilter) -> String {
        switch filter {
        case .all: "\(count) \(count == 1 ? "fee" : "fees")"
        case .due: "\(count) due"
        case .paid: "\(count) paid"
        }
    }

    public static func overdueBefore(_ invoices: [FeeInvoice], current: Period) -> OverdueSummary? {
        let overdue = invoices.filter { $0.status == .due && $0.period < current }
        guard let latest = overdue.map(\.period).max() else { return nil }
        return OverdueSummary(
            amount: overdue.map(\.amount).total,
            parents: Set(overdue.map(\.studentID)).count,
            latest: latest,
            months: Set(overdue.map(\.period)).count
        )
    }
}
```

`Domain/GeneratePreview.swift`:

```swift
import Foundation

/// What `generate_fees` will make for a month, counted on the device by its rule: one fee per active student without
/// one, from the student's own fee, else the class's, else nothing (P5-Generate, -Generate-Nothing).
public struct GeneratePreview: Hashable, Sendable {
    public struct Group: Hashable, Sendable, Identifiable {
        public let id: String
        public let name: String
        public let count: Int
        public let total: Money

        public var line: String {
            "\(name) · \(count == 1 ? "1 student" : "\(count) students")"
        }
    }

    public let month: Period
    public let groups: [Group]
    public let count: Int
    public let total: Money

    public static func make(students: [Student], classes: [Classroom], invoices: [FeeInvoice], month: Period) -> GeneratePreview {
        let covered = Set(invoices.filter { $0.period == month }.map(\.studentID))
        let missing = students.filter { !$0.isArchived && !covered.contains($0.id) }
        var groups: [Group] = []
        for classroom in classes.filter({ !$0.isArchived }) {
            let members = missing.filter { $0.classID == classroom.id }
            guard !members.isEmpty else { continue }
            groups.append(Group(
                id: classroom.id.uuidString, name: classroom.name, count: members.count,
                total: members.map { $0.fee(in: classroom) ?? .zero }.total
            ))
        }
        let noClass = missing.filter { student in !classes.contains { $0.id == student.classID && !$0.isArchived } }
        if !noClass.isEmpty {
            groups.append(Group(id: "none", name: "No class", count: noClass.count, total: noClass.map { $0.monthlyFee ?? .zero }.total))
        }
        return GeneratePreview(month: month, groups: groups, count: missing.count, total: groups.map(\.total).total)
    }

    public var canCreate: Bool {
        count > 0
    }

    public var title: String {
        switch count {
        case 0: "Everyone has a fee for \(month.monthName)"
        case 1: "1 fee will be created"
        default: "\(count) fees will be created"
        }
    }

    public var line: String {
        canCreate
            ? "One for each student without a fee for \(month.monthName), from the class fee or the student's own."
            : "Nothing to create. A student you add later gets one from here."
    }

    public var buttonLabel: String {
        switch count {
        case 0: "Nothing to create"
        case 1: "Create 1 fee"
        default: "Create \(count) fees"
        }
    }
}
```

`Domain/FeeAction.swift`:

```swift
import Foundation

/// What the Students tab asks the Fees tab to do for a student's month (the detail's and the student's fees' Remind
/// and Mark paid open on the Fees tab, as Mark attendance opens on the Attendance tab).
public enum FeeAction: Hashable, Sendable {
    case remind(studentID: UUID, month: Period)
    case markPaid(studentID: UUID, month: Period)
}
```

`Domain/Centre.swift`, add:

```swift
/// The centre's payment settings (`centres.upi_id`, `payment_link`, `send_receipts`, `upi_confirmed_at`).
public struct PaymentSettings: Hashable, Sendable {
    public var upiID: String?
    public var paymentLink: String?
    public var sendReceipts: Bool
    public var upiConfirmedAt: Date?

    public init(upiID: String? = nil, paymentLink: String? = nil, sendReceipts: Bool = true, upiConfirmedAt: Date? = nil) {
        self.upiID = upiID
        self.paymentLink = paymentLink
        self.sendReceipts = sendReceipts
        self.upiConfirmedAt = upiConfirmedAt
    }

    /// The payee card on Fees: an id that was never confirmed (P5-Fees-Payee).
    public var needsConfirmation: Bool {
        upiID != nil && upiConfirmedAt == nil
    }
}
```

and `Centre` gains `public var payments: PaymentSettings` with `init(id:name:whatsappNumber:payments: PaymentSettings = PaymentSettings())`.

- [ ] **Step 4: Run, format, commit**

Run: `cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios`
Expected: green.

```bash
git checkout -b phase-5/domain
git add ios
git commit -m "Domain: a fee and its state (overdue is a past month still due), the ledger's rows and totals, the generate preview, the payment settings"
```

### Task 2: Domain: the reminder and receipt texts, the UPI id and QR (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/FeeMessage.swift`, `UPI.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/FeeMessageTests.swift`, `UPITests.swift`

**Interfaces:**
- Consumes: `AbsenceMessage.whatsAppURL(phone:text:)` (reused as is), `Period.monthName`, `Day.shortText`, `Money.formatted`.
- Produces:

```swift
/// The parent-facing texts of components.md ("Phase 5 parts"): the reminder and the receipt.
public struct FeeMessage: Hashable, Sendable {
    public enum Kind: Hashable, Sendable { case reminder, receipt(method: MonthFee.PaidMethod, day: Day) }
    public let kind: Kind; public let parentName: String?; public let studentName: String; public let month: Period; public let amount: Money
    public let upiID: String?; public let paymentLink: String?; public let tutorName: String?; public let centreName: String
    public init(kind: Kind, parentName: String?, studentName: String, month: Period, amount: Money, upiID: String?, paymentLink: String?, tutorName: String?, centreName: String)
    public var text: String
}
public enum UPIID {
    public static let invalidMessage = "A UPI id looks like name@bank."
    /// Trimmed and lower-cased; nil when it does not match the column's rule (^[a-z0-9._-]{2,}@[a-z]{2,}$, case-insensitive).
    public static func normalised(_ typed: String) -> String?
}
public enum UPIQR {
    public static let notUPIMessage = "That QR is not a UPI QR."
    /// The payee of a `upi://pay?pa=…` payload (the `pa` query item, normalised); nil for any other text.
    public static func upiID(in payload: String) -> String?
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/FeeMessageTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct FeeMessageTests {
    static let october = Period(year: 2026, month: 10)
    static func reminder(upi: String? = "meera@okhdfcbank", link: String? = nil, parent: String? = "Lakshmi Reddy") -> FeeMessage {
        FeeMessage(
            kind: .reminder, parentName: parent, studentName: "Hemanth Reddy", month: october, amount: Money(rupees: 1200),
            upiID: upi, paymentLink: link, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
    }

    @Test func theReminderNamesEverything() {
        #expect(Self.reminder().text == """
        Hello Lakshmi, Hemanth's fee of ₹1,200 for October is due. You can pay by UPI to meera@okhdfcbank. Thank you.

        Meera Nair
        Bright Minds Tuition
        """)
        #expect(Self.reminder(link: "https://pay.example/meera").text.contains(
            "You can pay by UPI to meera@okhdfcbank or through this link: https://pay.example/meera. Thank you."
        ))
        #expect(Self.reminder(upi: nil, link: "https://pay.example/meera").text.contains("You can pay through this link: https://pay.example/meera. Thank you."))
    }

    @Test func withoutAPayeeTheReminderStillReads() {
        let text = Self.reminder(upi: nil, link: nil, parent: nil).text
        #expect(text.hasPrefix("Hello, Hemanth's fee of ₹1,200 for October is due. Thank you.\n\nMeera Nair"))
    }

    @Test func theReceiptNamesTheMethodAndDay() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let upi = FeeMessage(
            kind: .receipt(method: .upi, day: day), parentName: "Ramesh Kumar", studentName: "Dev Kumar", month: Self.october,
            amount: Money(rupees: 1000), upiID: nil, paymentLink: nil, tutorName: nil, centreName: "Bright Minds Tuition"
        )
        #expect(upi.text == "Hello Ramesh, received ₹1,000 by UPI on 7 Oct for Dev's October fee. Thank you.\n\nBright Minds Tuition")
        let cash = FeeMessage(
            kind: .receipt(method: .cash, day: day), parentName: "Ramesh Kumar", studentName: "Dev Kumar", month: Self.october,
            amount: Money(rupees: 1000), upiID: nil, paymentLink: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
        #expect(cash.text.hasPrefix("Hello Ramesh, received ₹1,000 by cash on 7 Oct for Dev's October fee."))
        let other = FeeMessage(
            kind: .receipt(method: .other, day: day), parentName: nil, studentName: "Dev Kumar", month: Self.october,
            amount: Money(rupees: 1000), upiID: nil, paymentLink: nil, tutorName: nil, centreName: "Bright Minds Tuition"
        )
        #expect(other.text.hasPrefix("Hello, received ₹1,000 on 7 Oct for Dev's October fee."))
    }
}
```

`Tests/DomainTests/UPITests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct UPITests {
    @Test func typedIDsAreNormalisedAndRefusedInWords() {
        #expect(UPIID.normalised("  Meera@OkHdfcBank ") == "meera@okhdfcbank")
        #expect(UPIID.normalised("9611299988@ybl") == "9611299988@ybl" && UPIID.normalised("a.b-c_d@upi") == "a.b-c_d@upi")
        #expect(UPIID.normalised("meera") == nil && UPIID.normalised("m@bank") == nil && UPIID.normalised("meera@1bank") == nil)
        #expect(UPIID.normalised("meera okhdfc@bank") == nil && UPIID.normalised("") == nil)
        #expect(UPIID.invalidMessage == "A UPI id looks like name@bank.")
    }

    @Test func aQRPayloadGivesItsPayeeOrNothing() {
        #expect(UPIQR.upiID(in: "upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair&cu=INR") == "meera@okhdfcbank")
        #expect(UPIQR.upiID(in: "UPI://PAY?pn=Meera&pa=Meera@OkHdfcBank") == "meera@okhdfcbank", "scheme and host any case; the id normalised")
        #expect(UPIQR.upiID(in: "https://example.com/pay?pa=meera@okhdfcbank") == nil, "not a UPI scheme")
        #expect(UPIQR.upiID(in: "upi://pay?pn=Meera") == nil && UPIQR.upiID(in: "upi://pay?pa=not-an-id") == nil)
        #expect(UPIQR.upiID(in: "hello") == nil && UPIQR.notUPIMessage == "That QR is not a UPI QR.")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `FeeMessage`, `UPIID`, `UPIQR` not found.

- [ ] **Step 3: Implement**

`Domain/FeeMessage.swift`:

```swift
import Foundation

/// The parent-facing texts behind Remind and the receipt (P5-Remind, P5-Receipt; components.md, Phase 5 parts): plain
/// and polite, the child, the month, the amount, the UPI id or link at the end, the tutor and the centre as the
/// signature (as the absence alert). `AbsenceMessage.whatsAppURL` carries it.
public struct FeeMessage: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case reminder
        case receipt(method: MonthFee.PaidMethod, day: Day)
    }

    public let kind: Kind
    public let parentName: String?
    public let studentName: String
    public let month: Period
    public let amount: Money
    public let upiID: String?
    public let paymentLink: String?
    public let tutorName: String?
    public let centreName: String

    public init(
        kind: Kind, parentName: String?, studentName: String, month: Period, amount: Money, upiID: String?,
        paymentLink: String?, tutorName: String?, centreName: String
    ) {
        self.kind = kind
        self.parentName = parentName
        self.studentName = studentName
        self.month = month
        self.amount = amount
        self.upiID = upiID
        self.paymentLink = paymentLink
        self.tutorName = tutorName
        self.centreName = centreName
    }

    public var text: String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        let body: String
        switch kind {
        case .reminder:
            let pay: String? = switch (upiID, paymentLink) {
            case let (id?, link?): "You can pay by UPI to \(id) or through this link: \(link)."
            case let (id?, nil): "You can pay by UPI to \(id)."
            case let (nil, link?): "You can pay through this link: \(link)."
            case (nil, nil): nil
            }
            body = ["\(greeting) \(child)'s fee of \(amount.formatted) for \(month.monthName) is due.", pay, "Thank you."]
                .compactMap(\.self).joined(separator: " ")
        case let .receipt(method, day):
            let by = switch method {
            case .upi: " by UPI"
            case .cash: " by cash"
            case .other: ""
            }
            body = "\(greeting) received \(amount.formatted)\(by) on \(day.shortText) for \(child)'s \(month.monthName) fee. Thank you."
        }
        return "\(body)\n\n\(signature)"
    }
}
```

`Domain/UPI.swift`:

```swift
import Foundation

/// The UPI id as the tutor types it, held to the column's rule (migration 0001: `^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$`).
public enum UPIID {
    public static let invalidMessage = "A UPI id looks like name@bank."

    public static func normalised(_ typed: String) -> String? {
        let id = typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = id.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count >= 2, parts[1].count >= 2,
              parts[0].allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "._-".contains($0)) }),
              parts[1].allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        return id
    }
}

/// A UPI QR's payload: `upi://pay?pa=<payee>&pn=…` (NPCI's deep link). Only the payee is read.
public enum UPIQR {
    public static let notUPIMessage = "That QR is not a UPI QR."

    public static func upiID(in payload: String) -> String? {
        guard let components = URLComponents(string: payload.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "upi", components.host?.lowercased() == "pay",
              let payee = components.queryItems?.first(where: { $0.name.lowercased() == "pa" })?.value else { return nil }
        return UPIID.normalised(payee)
    }
}
```

- [ ] **Step 4: Run, format, commit**

Run: `cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios
git commit -m "Domain: the reminder and receipt texts, the UPI id rule, the payee of a UPI QR"
```

### Task 3: Domain: the two CSVs (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/CSV.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/CSVTests.swift`

**Interfaces:**
- Produces:

```swift
public enum CSV {
    /// A field with a comma, a quote or a newline is quoted, quotes doubled (RFC 4180); CRLF line ends; a UTF-8 BOM so Numbers and Excel read the rupee sign.
    public static func make(header: [String], rows: [[String]]) -> String
}
public struct FeesCSVRow: Hashable, Sendable { public let student: String; public let className: String; public let amount: Money; public let state: FeeState; public let paidOn: Day?; public let paidBy: MonthFee.PaidMethod?; public let remindedOn: Day?
    public init(student:className:amount:state:paidOn:paidBy:remindedOn:) }
public enum FeesCSV {
    public static let header = ["Student", "Class", "Amount", "Status", "Paid on", "Paid by", "Reminded on"]
    public static func fileName(_ month: Period) -> String   // "fees-2026-10.csv"
    public static func make(_ rows: [FeesCSVRow]) -> String    // amount as digits ("1200"), status word, days "2026-10-04", method "UPI"/"Cash"/"Other"
}
public struct AttendanceCSVRow: Hashable, Sendable { public let student: String; public let className: String; public let present: Int; public let absent: Int
    public init(student:className:present:absent:); public var percentage: Int?   // nil when nothing marked }
public enum AttendanceCSV {
    public static let header = ["Student", "Class", "Present", "Absent", "Percentage"]
    public static func fileName(_ month: Period) -> String   // "attendance-2026-10.csv"
    public static func make(_ rows: [AttendanceCSVRow]) -> String   // percentage "75" or "" when nothing marked
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
@testable import Domain

struct CSVTests {
    @Test func namesWithCommasAndQuotesAreEscaped() {
        let text = CSV.make(header: ["A", "B"], rows: [["Singh, Bir", "He said \"hi\""], ["plain", "two\nlines"]])
        #expect(text == "\u{FEFF}A,B\r\n\"Singh, Bir\",\"He said \"\"hi\"\"\"\r\nplain,\"two\nlines\"\r\n")
    }

    @Test func theFeesFileHasTheColumnsOfTheBoard() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 4))
        let rows = [
            FeesCSVRow(student: "Akshita Rao", className: "Class 10 Maths", amount: Money(rupees: 1200), state: .paid, paidOn: day, paidBy: .upi, remindedOn: nil),
            FeesCSVRow(student: "Dev Kumar", className: "Class 8 Science", amount: Money(rupees: 1000), state: .due, paidOn: nil, paidBy: nil, remindedOn: Day(year: 2026, month: 10, day: 6)),
            FeesCSVRow(student: "Sahil Verma", className: "", amount: Money(rupees: 800), state: .waived, paidOn: nil, paidBy: nil, remindedOn: nil),
        ]
        #expect(FeesCSV.make(rows) == "\u{FEFF}Student,Class,Amount,Status,Paid on,Paid by,Reminded on\r\n"
            + "Akshita Rao,Class 10 Maths,1200,Paid,2026-10-04,UPI,\r\n"
            + "Dev Kumar,Class 8 Science,1000,Due,,,2026-10-06\r\n"
            + "Sahil Verma,,800,Waived,,,\r\n")
        #expect(FeesCSV.fileName(Period(year: 2026, month: 10)) == "fees-2026-10.csv")
    }

    @Test func theAttendanceFileCountsAndPercents() {
        let rows = [
            AttendanceCSVRow(student: "Hemanth Reddy", className: "Class 10 Maths", present: 1, absent: 2),
            AttendanceCSVRow(student: "Sahil Verma", className: "", present: 0, absent: 0),
        ]
        #expect(rows[0].percentage == 33 && rows[1].percentage == nil)
        #expect(AttendanceCSV.make(rows) == "\u{FEFF}Student,Class,Present,Absent,Percentage\r\nHemanth Reddy,Class 10 Maths,1,2,33\r\nSahil Verma,,0,0,\r\n")
        #expect(AttendanceCSV.fileName(Period(year: 2026, month: 10)) == "attendance-2026-10.csv")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `CSV`, `FeesCSV`, `AttendanceCSV` not found.

- [ ] **Step 3: Implement**

`Domain/CSV.swift`:

```swift
import Foundation

/// A spreadsheet file (RFC 4180): quoted where a field needs it, CRLF line ends, a UTF-8 BOM so Numbers and Excel
/// read ₹ and names right (P5-Reports-Export).
public enum CSV {
    public static func make(header: [String], rows: [[String]]) -> String {
        let lines = ([header] + rows).map { $0.map(field).joined(separator: ",") }
        return "\u{FEFF}" + lines.map { $0 + "\r\n" }.joined()
    }

    static func field(_ text: String) -> String {
        guard text.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return text }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// One line of the fees file: student, class, amount, status, paid on, paid by, reminded on.
public struct FeesCSVRow: Hashable, Sendable {
    public let student: String
    public let className: String
    public let amount: Money
    public let state: FeeState
    public let paidOn: Day?
    public let paidBy: MonthFee.PaidMethod?
    public let remindedOn: Day?

    public init(student: String, className: String, amount: Money, state: FeeState, paidOn: Day?, paidBy: MonthFee.PaidMethod?, remindedOn: Day?) {
        self.student = student
        self.className = className
        self.amount = amount
        self.state = state
        self.paidOn = paidOn
        self.paidBy = paidBy
        self.remindedOn = remindedOn
    }
}

public enum FeesCSV {
    public static let header = ["Student", "Class", "Amount", "Status", "Paid on", "Paid by", "Reminded on"]

    public static func fileName(_ month: Period) -> String {
        "fees-\(month.isoDay.prefix(7)).csv"
    }

    public static func make(_ rows: [FeesCSVRow]) -> String {
        CSV.make(header: header, rows: rows.map { row in
            [row.student, row.className, "\(row.amount.rupees)", row.state.word, row.paidOn?.iso ?? "",
             row.paidBy.map(method) ?? "", row.remindedOn?.iso ?? ""]
        })
    }

    private static func method(_ method: MonthFee.PaidMethod) -> String {
        switch method {
        case .upi: "UPI"
        case .cash: "Cash"
        case .other: "Other"
        }
    }
}

/// One line of the attendance file: student, class, present, absent, percentage.
public struct AttendanceCSVRow: Hashable, Sendable {
    public let student: String
    public let className: String
    public let present: Int
    public let absent: Int

    public init(student: String, className: String, present: Int, absent: Int) {
        self.student = student
        self.className = className
        self.present = present
        self.absent = absent
    }

    /// Nil when nothing was marked: never 0% for an unmarked month.
    public var percentage: Int? {
        let total = present + absent
        return total == 0 ? nil : Int((Double(present) * 100 / Double(total)).rounded())
    }
}

public enum AttendanceCSV {
    public static let header = ["Student", "Class", "Present", "Absent", "Percentage"]

    public static func fileName(_ month: Period) -> String {
        "attendance-\(month.isoDay.prefix(7)).csv"
    }

    public static func make(_ rows: [AttendanceCSVRow]) -> String {
        CSV.make(header: header, rows: rows.map { row in
            [row.student, row.className, "\(row.present)", "\(row.absent)", row.percentage.map { "\($0)" } ?? ""]
        })
    }
}
```

- [ ] **Step 4: Run, format, commit; open PR 1**

Run: `cd ios && swiftformat . && cd .. && bun check`
Expected: green.

```bash
git add ios
git commit -m "Domain: the fees and attendance CSVs"
git push -u origin phase-5/domain
gh pr create --title "Domain: fees and their states, the ledger, the generate preview, the messages, UPI, CSV" --body "Phase 5 Tasks 1 to 3: FeeInvoice and FeeState (overdue is a past month still due), FeeLedger rows and totals, the overdue summary, GeneratePreview by generate_fees' rule, the reminder and receipt texts of components.md, UPIID and UPIQR, the two CSVs. Tests first against the rules; no screen changes."
```

Merge when green.

### Task 4: The database tests: mark paid and undo, waive, a reminder read back by its month, generate twice (PR 2)

**Files:**
- Modify: `supabase/tests/rls.test.ts` (four tests, before the `delete_centre` test)

**Interfaces:**
- Consumes: the existing `a` and `b` clients, `centreA`, the students the earlier tests made ("Only A" has October's fee from the `generate_fees` test).
- Produces: nothing new in the schema; the tests pin the writes the app makes.

- [ ] **Step 1: Write the tests**

```ts
test("mark paid, undo and waive are plain updates the checks allow", async () => {
  const inv = await a.from("fee_invoices").select("id").eq("centre_id", centreA).eq("period", "2026-10-01").order("amount").limit(1).single();
  const paid = await a.from("fee_invoices").update({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00", paid_method: "cash", waived_reason: null })
    .eq("id", inv.data!.id).select("status, paid_at, paid_method, waived_reason").single();
  expect(paid.error).toBeNull();
  expect(paid.data).toEqual({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00", paid_method: "cash", waived_reason: null });
  // Undo: back to due, nothing paid.
  const undone = await a.from("fee_invoices").update({ status: "due", paid_at: null, paid_method: null }).eq("id", inv.data!.id).select("status, paid_at, paid_method").single();
  expect(undone.data).toEqual({ status: "due", paid_at: null, paid_method: null });
  // Waive keeps paid_at null; a waived fee marked paid later clears the reason.
  const waived = await a.from("fee_invoices").update({ status: "waived", waived_reason: "Joined mid-month" }).eq("id", inv.data!.id).select("status, paid_at, waived_reason").single();
  expect(waived.data).toEqual({ status: "waived", paid_at: null, waived_reason: "Joined mid-month" });
  expect((await a.from("fee_invoices").update({ status: "due", paid_at: "2026-10-07T07:30:00+00:00" }).eq("id", inv.data!.id)).error).not.toBeNull(); // due with paid_at is refused
  const back = await a.from("fee_invoices").update({ status: "due", waived_reason: null }).eq("id", inv.data!.id).select("status, waived_reason").single();
  expect(back.data).toEqual({ status: "due", waived_reason: null });
  expect((await b.from("fee_invoices").update({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00" }).eq("id", inv.data!.id).select("id")).data).toEqual([]);
});

test("a reminder and a receipt are logged about a month and read back by it", async () => {
  const s = await a.from("students").select("id").eq("name", "Only A").single();
  const reminder = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "reminder", about_date: "2026-10-01" }).select("kind, about_date, channel").single();
  expect(reminder.data).toEqual({ kind: "reminder", about_date: "2026-10-01", channel: "whatsapp_link" });
  expect((await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "receipt", about_date: "2026-10-01" })).error).toBeNull();
  const october = await a.from("message_log").select("kind").eq("centre_id", centreA).in("kind", ["reminder", "receipt"]).eq("about_date", "2026-10-01").order("kind");
  expect(october.data).toEqual([{ kind: "receipt" }, { kind: "reminder" }]);
  const september = await a.from("message_log").select("kind").eq("centre_id", centreA).in("kind", ["reminder", "receipt"]).eq("about_date", "2026-09-01");
  expect(september.data).toEqual([]);
});

test("the centre's payment settings are the owner's to change", async () => {
  const set = await a.from("centres").update({ upi_id: "meera@okhdfcbank", payment_link: "https://pay.example/meera", send_receipts: false, upi_confirmed_at: null })
    .eq("id", centreA).select("upi_id, payment_link, send_receipts, upi_confirmed_at").single();
  expect(set.data).toEqual({ upi_id: "meera@okhdfcbank", payment_link: "https://pay.example/meera", send_receipts: false, upi_confirmed_at: null });
  expect((await a.from("centres").update({ upi_id: "not an id" }).eq("id", centreA)).error).not.toBeNull();
  const confirmed = await a.from("centres").update({ upi_confirmed_at: "2026-10-07T07:35:00+00:00" }).eq("id", centreA).select("upi_confirmed_at").single();
  expect(confirmed.data!.upi_confirmed_at).toBe("2026-10-07T07:35:00+00:00");
  expect((await b.from("centres").update({ upi_id: "thief@bank" }).eq("id", centreA).select("id")).data).toEqual([]);
});

test("generate_fees for a second month skips nothing and counts what it made", async () => {
  const active = await a.from("students").select("id").eq("centre_id", centreA).is("archived_at", null);
  const made = await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-11-01" });
  expect(made.error).toBeNull();
  expect(made.data).toBe(active.data!.length);
  expect((await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-11-01" })).data).toBe(0);
});
```

- [ ] **Step 2: Run the tests**

Run: `cd supabase && bun test tests`
Expected: PASS (nothing new in the schema; the tests pin what the app will do). If `the centre's payment settings` fails on the `upi_id` check, the rule the app keeps (`UPIID.normalised`) is wrong, not the test.

- [ ] **Step 3: Commit**

```bash
git checkout main && git pull && git checkout -b phase-5/data
git add supabase/tests/rls.test.ts
git commit -m "Database tests: mark paid, undo and waive under the checks; a reminder and a receipt logged about a month; the payment settings the owner's; generate_fees twice"
```

### Task 5: Data: the fees repository, its row, the fake; every answer decoded; the writes proven (PR 2)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Fees/FeesRepository.swift`, `SupabaseFeesRepository.swift`, `FakeFeesRepository.swift`, `InvoiceRow.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/InvoiceRowTests.swift`, `FakeFeesRepositoryTests.swift`

**Interfaces:**
- Consumes: `FeeInvoice`, `Period`, `Day`, `PostgRESTDecoder`, `FakeStudentsRepository.seed` (ids `aaaaaaaa-…-%012d`, 1 to 10 in the seed's name order), `FakeCountsRepository.fixedNow`.
- Produces:

```swift
/// The fee ledger. RLS keeps every call inside the member's centre.
public protocol FeesRepository: Sendable {
    /// The month's fees, by student id (the caller orders by name).
    func invoices(centre: UUID, month: Period) async throws -> [FeeInvoice]
    /// One student's months, newest first.
    func invoices(centre: UUID, student: UUID) async throws -> [FeeInvoice]
    /// Fees still due from months before `month` (the overdue banner).
    func dueBefore(centre: UUID, month: Period) async throws -> [FeeInvoice]
    /// `generate_fees`; how many it made.
    func generate(centre: UUID, month: Period) async throws -> Int
    /// Paid at `at` (now, or the chosen day at noon); clears a waive reason.
    func markPaid(id: UUID, method: MonthFee.PaidMethod, at: Date) async throws -> FeeInvoice
    /// Undo: due, nothing paid.
    func markDue(id: UUID) async throws -> FeeInvoice
    func waive(id: UUID, reason: String) async throws -> FeeInvoice
}
@MainActor public final class FakeFeesRepository: FeesRepository {
    public nonisolated static let seed: [FeeInvoice]        // October's ten, September's ten, Hemanth's August and July (the decisions table)
    public nonisolated static let octoberOnly: [FeeInvoice] // the first ten, for states without a past
    public nonisolated static func id(_ n: Int) -> UUID      // bbbbbbbb-0000-0000-0000-%012d
    public nonisolated static let devOctober: UUID          // id(4)
    public nonisolated static let hemanthOctober: UUID      // id(5)
    public nonisolated static let sahilOctober: UUID        // id(10)
    public nonisolated static let nikhilSeptember: UUID     // id(18)
    public var invoices: [FeeInvoice]; public var nextError: (any Error)?; public var delay: Duration?
    public private(set) var generated: [Period]; public private(set) var paid: [UUID]; public private(set) var undone: [UUID]; public private(set) var waived: [UUID]
    /// What `generate` answers and appends: by default one due fee per active seed student without one, at the seed's amounts.
    public var generateCount: Int?
    public init(invoices: [FeeInvoice] = [], now: @escaping @Sendable () -> Date = { FakeCountsRepository.fixedNow })
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/InvoiceRowTests.swift`. The fixtures are the local stack's answers on 2026-10-08 (pasted whole, as the seed's tutor; the ids are the seed's random ones): `GET /rest/v1/fee_invoices?select=id,student_id,period,amount,status,paid_at,paid_method,waived_reason&centre_id=eq.<id>&period=eq.2026-10-01&order=student_id&limit=3`; `POST /rest/v1/rpc/generate_fees` → `0`; `PATCH …fee_invoices?id=eq.<id>&select=…` (mark paid, undo, waive). Do not change them.

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct InvoiceRowTests {
    static let month = Data("""
    [{"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","period":"2026-10-01","amount":1000,"status":"due","paid_at":null,"paid_method":null,"waived_reason":null}, 
     {"id":"98ae7ca8-94dc-47db-aa65-d46ffc6e61a8","student_id":"2bf34b2d-af1c-4510-a784-452c8415ec89","period":"2026-10-01","amount":1200,"status":"paid","paid_at":"2026-10-05T11:28:56.803636+00:00","paid_method":"upi","waived_reason":null}, 
     {"id":"fc5083f6-ce30-46af-9851-25159e5d745f","student_id":"3611371e-6814-446a-ba55-affd7aa460ec","period":"2026-10-01","amount":1200,"status":"paid","paid_at":"2026-10-05T11:28:56.803636+00:00","paid_method":"upi","waived_reason":null}]
    """.utf8)
    static let paid = Data("""
    [{"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","centre_id":"22222222-2222-2222-2222-222222222222","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","period":"2026-10-01","amount":1000,"status":"paid","paid_at":"2026-10-07T07:30:00+00:00","paid_method":"upi","waived_reason":null,"created_at":"2026-10-08T11:28:56.803636+00:00","updated_at":"2026-10-08T13:11:45.819826+00:00"}]
    """.utf8)
    static let waived = Data("""
    {"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","period":"2026-10-01","amount":1000,"status":"waived","paid_at":null,"paid_method":null,"waived_reason":"Joined mid-month"}
    """.utf8)

    @Test func decodesAMonthWithPaidAndDueRows() throws {
        let rows = try SupabaseFeesRepository.decoder.decode([InvoiceRow].self, from: Self.month).compactMap(\.invoice)
        #expect(rows.count == 3 && rows[0].status == .due && rows[0].paidAt == nil && rows[0].amount == Money(rupees: 1000))
        #expect(rows[0].period == Period(year: 2026, month: 10) && rows[0].id.uuidString.lowercased() == "0ac1dcb5-b76b-4bd9-b43b-4b3639589b14")
        #expect(rows[1].status == .paid && rows[1].paidMethod == .upi && rows[1].paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 5))
    }

    @Test func decodesAWriteAnswerWithEveryColumnOrAFew() throws {
        let paid = try #require(try SupabaseFeesRepository.decoder.decode([InvoiceRow].self, from: Self.paid).first?.invoice)
        #expect(paid.status == .paid && paid.paidMethod == .upi && paid.waivedReason == nil)
        #expect(paid.paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 7), "07:30Z is 13:00 in India, the 7th")
        let waived = try #require(try SupabaseFeesRepository.decoder.decode(InvoiceRow.self, from: Self.waived).invoice)
        #expect(waived.status == .waived && waived.waivedReason == "Joined mid-month" && waived.paidAt == nil)
    }

    @Test func theRpcAnswersACount() throws {
        #expect(try SupabaseFeesRepository.decoder.decode(Int.self, from: Data("0".utf8)) == 0)
        #expect(try SupabaseFeesRepository.decoder.decode(Int.self, from: Data("10".utf8)) == 10)
    }

}
```

`Tests/DataTests/FakeFeesRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeFeesRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id
    let october = Period(year: 2026, month: 10)

    @Test func theSeedIsTheBoards() async throws {
        let repo = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        let month = try await repo.invoices(centre: centre, month: october)
        #expect(month.count == 10 && FeeTotals(invoices: month).outstanding == Money(rupees: 4000) && FeeTotals(invoices: month).collected == Money(rupees: 7300))
        #expect(month.filter { $0.status == .paid }.allSatisfy { $0.paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 4) && $0.paidMethod == .upi })
        let september = try await repo.invoices(centre: centre, month: Period(year: 2026, month: 9))
        #expect(FeeTotals(invoices: september).collected == Money(rupees: 10300) && september.filter { $0.status == .due }.map(\.id) == [FakeFeesRepository.nikhilSeptember])
        let before = try await repo.dueBefore(centre: centre, month: october)
        #expect(before.map(\.id) == [FakeFeesRepository.nikhilSeptember])
        let hemanth = try await repo.invoices(centre: centre, student: FakeAttendanceRepository.hemanth)
        #expect(hemanth.map(\.period.month) == [10, 9, 8, 7] && hemanth[2].paidMethod == .cash && hemanth[3].status == .waived)
        #expect(try await FakeFeesRepository(invoices: FakeFeesRepository.octoberOnly).dueBefore(centre: centre, month: october).isEmpty)
    }

    @Test func writesChangeTheRowAndAreRecorded() async throws {
        let repo = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        let at = FakeCountsRepository.fixedNow
        let paid = try await repo.markPaid(id: FakeFeesRepository.devOctober, method: .upi, at: at)
        #expect(paid.status == .paid && paid.paidAt == at && paid.paidMethod == .upi && repo.paid == [FakeFeesRepository.devOctober])
        let undone = try await repo.markDue(id: FakeFeesRepository.devOctober)
        #expect(undone.status == .due && undone.paidAt == nil && undone.paidMethod == nil && repo.undone == [FakeFeesRepository.devOctober])
        let waived = try await repo.waive(id: FakeFeesRepository.sahilOctober, reason: "Joined mid-month")
        #expect(waived.status == .waived && waived.waivedReason == "Joined mid-month" && repo.waived == [FakeFeesRepository.sahilOctober])
        let paidAfterWaive = try await repo.markPaid(id: FakeFeesRepository.sahilOctober, method: .cash, at: at)
        #expect(paidAfterWaive.waivedReason == nil)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.markPaid(id: FakeFeesRepository.devOctober, method: .upi, at: at) }
        await #expect(throws: URLError.self) { try await repo.markDue(id: UUID()) }
    }

    @Test func generateMakesOneDueFeePerSeedStudentWithoutOne() async throws {
        let repo = FakeFeesRepository(invoices: [])
        let made = try await repo.generate(centre: centre, month: october)
        #expect(made == 10 && repo.generated == [october])
        let month = try await repo.invoices(centre: centre, month: october)
        #expect(month.count == 10 && month.allSatisfy { $0.status == .due } && month.map(\.amount).total == Money(rupees: 11300))
        #expect(try await repo.generate(centre: centre, month: october) == 0, "idempotent, as the function")
        repo.generateCount = 3
        #expect(try await repo.generate(centre: centre, month: Period(year: 2026, month: 11)) == 3, "a scripted answer for the stores' tests")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `InvoiceRow`, `SupabaseFeesRepository`, `FakeFeesRepository` not found.

- [ ] **Step 3: Implement**

`Data/Fees/FeesRepository.swift`: the protocol above, with the doc lines.

`Data/Fees/InvoiceRow.swift`:

```swift
import Domain
import Foundation

/// A `fee_invoices` row as PostgREST answers it; a write's answer carries the centre and timestamps too, which are
/// ignored.
struct InvoiceRow: Decodable {
    let id: UUID
    let studentId: UUID
    let period: String
    let amount: Int
    let status: String
    let paidAt: Date?
    let paidMethod: String?
    let waivedReason: String?

    /// Nil for a status this build does not know (never, by the enum; kept so a bad row cannot crash the ledger).
    var invoice: FeeInvoice? {
        guard let period = Period(isoDay: period), let status = MonthFee.Status(rawValue: status) else { return nil }
        return FeeInvoice(
            id: id, studentID: studentId, period: period, amount: Money(rupees: amount), status: status, paidAt: paidAt,
            paidMethod: paidMethod.flatMap(MonthFee.PaidMethod.init(rawValue:)), waivedReason: waivedReason
        )
    }
}
```

`Data/Fees/SupabaseFeesRepository.swift`:

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseFeesRepository: FeesRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, student_id, period, amount, status, paid_at, paid_method, waived_reason"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func invoices(centre: UUID, month: Period) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("period", value: month.isoDay).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func invoices(centre: UUID, student: UUID) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("student_id", value: student).order("period", ascending: false).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func dueBefore(centre: UUID, month: Period) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("status", value: "due").lt("period", value: month.isoDay).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func generate(centre: UUID, month: Period) async throws -> Int {
        let response = try await client.rpc("generate_fees", params: [
            "p_centre": AnyJSON.string(centre.uuidString), "p_period": .string(month.isoDay),
        ]).execute()
        return try Self.decoder.decode(Int.self, from: response.data)
    }

    public func markPaid(id: UUID, method: MonthFee.PaidMethod, at: Date) async throws -> FeeInvoice {
        try await update(id, [
            "status": .string("paid"), "paid_at": .string(ISO8601DateFormatter().string(from: at)),
            "paid_method": .string(method.rawValue), "waived_reason": .null,
        ])
    }

    public func markDue(id: UUID) async throws -> FeeInvoice {
        try await update(id, ["status": .string("due"), "paid_at": .null, "paid_method": .null])
    }

    public func waive(id: UUID, reason: String) async throws -> FeeInvoice {
        try await update(id, ["status": .string("waived"), "paid_at": .null, "paid_method": .null, "waived_reason": .string(reason)])
    }

    private func update(_ id: UUID, _ values: [String: AnyJSON]) async throws -> FeeInvoice {
        let response = try await client.from("fee_invoices").update(values).eq("id", value: id)
            .select(Self.columns).single().execute()
        guard let invoice = try Self.decoder.decode(InvoiceRow.self, from: response.data).invoice else {
            throw URLError(.cannotParseResponse)
        }
        return invoice
    }
}
```

`Data/Fees/FakeFeesRepository.swift`: `seed` built from `FakeStudentsRepository.seed`'s ids and amounts (the seed's rule: the student's own fee else the class's: Akshita 1200, Ananya 1200, Bir 1200, Dev 1000, Hemanth 1200, Lakshmi 1200, Meher 1000, Nikhil 1000, Riya 1500, Sahil 800) with ids `id(1...10)` for October (paid 4 Oct 11:00 India by UPI for Akshita, Ananya, Bir, Lakshmi, Meher, Riya), `id(11...20)` for September (paid 3 Sep by UPI for everyone but Nikhil, `id(18)` due), `id(21)` Hemanth's August (cash, 5 Aug 2026 11:00), `id(22)` Hemanth's July (waived, "Joined mid-month"); `octoberOnly = Array(seed.prefix(10))`. `generate` appends due fees for every seed student id without one for the month (amounts as above, ids `UUID()`) and returns the count, or `generateCount` when set (then appends nothing). `markPaid`, `markDue` and `waive` find the row (throw `URLError(.fileDoesNotExist)` when absent), rewrite it, record the id, return it; `begin()` honours `delay` and `nextError` as `FakeStudentsRepository` does.

- [ ] **Step 4: Prove the write path in Swift against the local stack**

With `supabase start` up and the seed fresh, add a throwaway test in `DataTests` that makes a `SupabaseClient` for `http://127.0.0.1:54321` with the anon key from `supabase status -o env` (`SupabaseClientFactory.make` with an in-memory session, as session 6 and 9 did), signs in as `meera@example.com` / `tutor-local-1`, reads October, marks Dev's fee paid by UPI at now, reads it back (`status == .paid`, `paidMethod == .upi`, the day today), marks it due again, waives Sahil's with "Joined mid-month", reads Sahil's months, calls `generate` for November (10) and again (0), and `dueBefore` for October (empty). Run it (`bun check --only=ios`), confirm with psql, delete the test, then `cd supabase && supabase db reset`.

- [ ] **Step 5: Run, format, commit**

Run: `cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios
git commit -m "Data: the fees repository (the month, a student, due before, generate, mark paid, mark due, waive), its row decoded from the stack's answers, the fake with the boards' months"
```

### Task 6: Data: fee logs on the message log, the centre's payments, the QR image store, `Dependencies` (PR 2)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Data/Messages/MessageLogRepository.swift`, `SupabaseMessageLogRepository.swift`, `FakeMessageLogRepository.swift`; `Data/Centres/CentreRepository.swift`, `SupabaseCentreRepository.swift`, `FakeCentreRepository.swift`; `AppShell/Dependencies.swift`, `AppShell/Fixtures.swift` (the fees fake, the workspace variants); `Tests/AppShellTests/LaunchStateTests.swift` (`everyBoardStateHasAFixture` already covers every case)
- Create: `ios/TutorCentralKit/Sources/Data/Cache/QRImageStore.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/FeeLogRowTests.swift`, `CentreRowTests.swift`, `FakeCentreRepositoryTests.swift` (+ payments), `FakeAttendanceRepositoryTests.swift` (+ `theMessageLogRemembersFeeMessages`)

**Interfaces:**
- Produces:

```swift
/// One opened reminder or receipt (`message_log`, kinds `reminder` and `receipt`, `about_date` = the month's first day).
public struct FeeLog: Hashable, Sendable, Codable {
    public enum Kind: String, Hashable, Sendable, Codable { case reminder, receipt }
    public let studentID: UUID; public let kind: Kind; public let openedAt: Date; public let month: Period
    public init(studentID: UUID, kind: Kind, openedAt: Date, month: Period)
}
// MessageLogRepository gains:
    /// The month's reminders and receipts, newest first.
    func feeLogs(centre: UUID, month: Period) async throws -> [FeeLog]
    /// One student's reminders and receipts across months, newest first.
    func feeLogs(centre: UUID, student: UUID) async throws -> [FeeLog]
    /// Logged when the tutor taps Open WhatsApp, before the link opens.
    func logFee(centre: UUID, studentID: UUID, kind: FeeLog.Kind, month: Period) async throws -> FeeLog
// FakeMessageLogRepository gains: `public nonisolated static let feeSeed: [FeeLog]` (Dev reminded Tue 6 Oct 2026 10:15 India about October; Nikhil reminded Wed 30 Sep 2026 18:00 about September), `public var feeLogs: [FeeLog]`, `public private(set) var feeLogged: [FeeLog]`, `init(logs:feeLogs:now:)`.
// CentreRepository gains:
    /// The UPI id; a changed id is unconfirmed again (upi_confirmed_at null in the same update).
    func updateUPI(id: UUID, upiID: String?) async throws
    func updatePaymentLink(id: UUID, link: String?) async throws
    func updateSendReceipts(id: UUID, on: Bool) async throws
    func confirmUPI(id: UUID, at: Date) async throws
// CentreRow gains upi_id, upi_confirmed_at, payment_link, send_receipts; `workspace(for:)` selects them; FakeCentreRepository records `upiUpdates: [String?]`, `linkUpdates: [String?]`, `receiptUpdates: [Bool]`, `confirmations: [Date]` and applies each to `workspace?.centre.payments`. `meeraWorkspace` gains `payments: PaymentSettings(upiID: "meera@okhdfcbank", sendReceipts: true, upiConfirmedAt: 1 Oct 2026 09:00 India)`; `meeraWorkspaceUnconfirmed` (upiConfirmedAt nil) and `meeraWorkspaceWithoutUPI` (PaymentSettings()) beside it.
/// The UPI QR image kept on this iPhone (Parent payments): never uploaded.
public protocol QRImageStore: Sendable {
    func image(for centre: UUID) -> Data?
    func save(_ data: Data, for centre: UUID) throws
    func remove(for centre: UUID)
}
public struct FileQRImageStore: QRImageStore { public init() }   // Application Support/TutorCentral/upi-qr-<centre>.png, complete file protection
@MainActor public final class MemoryQRImageStore: QRImageStore { public init(); public var images: [UUID: Data] }
// Dependencies gains `fees: any FeesRepository` and `qrImages: any QRImageStore`; `live()` passes SupabaseFeesRepository and FileQRImageStore; Fixtures passes FakeFeesRepository and MemoryQRImageStore.
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/FeeLogRowTests.swift`. The fixtures are the stack's answers on 2026-10-08: the insert (`POST /rest/v1/message_log` with `Prefer: return=representation`) and the read (`GET …message_log?select=student_id,kind,opened_at,about_date&centre_id=eq.…&kind=in.(reminder,receipt)&about_date=eq.2026-10-01&order=opened_at.desc`):

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct FeeLogRowTests {
    static let inserted = Data("""
    [{"id":"69ce3185-4fca-4d3b-becd-f47e0c1a43b7","centre_id":"22222222-2222-2222-2222-222222222222","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder","channel":"whatsapp_link","opened_at":"2026-10-08T13:11:45.759711+00:00","created_at":"2026-10-08T13:11:45.759711+00:00","updated_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]
    """.utf8)
    static let read = Data("""
    [{"student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder","opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]
    """.utf8)

    @Test func decodesAFeeLogFromTheInsertAndTheRead() throws {
        let made = try #require(try SupabaseMessageLogRepository.decoder.decode([FeeLogRow].self, from: Self.inserted).first?.log)
        #expect(made.kind == .reminder && made.month == Period(year: 2026, month: 10) && made.studentID.uuidString.lowercased() == "11f29474-3413-4c2c-a045-4fa4fd181b19")
        let read = try SupabaseMessageLogRepository.decoder.decode([FeeLogRow].self, from: Self.read).compactMap(\.log)
        #expect(read.count == 1 && Day(read[0].openedAt, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 8))
    }

    @Test func aLogWithoutAStudentOrAMonthTellsNoOne() throws {
        let orphan = Data(#"[{"student_id":null,"kind":"receipt","opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]"#.utf8)
        #expect(try SupabaseMessageLogRepository.decoder.decode([FeeLogRow].self, from: orphan).compactMap(\.log).isEmpty)
        let old = Data(#"[{"student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder","opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":null}]"#.utf8)
        #expect(try SupabaseMessageLogRepository.decoder.decode([FeeLogRow].self, from: old).compactMap(\.log).isEmpty, "a reminder before this build named no month")
    }
}
```

`Tests/DataTests/CentreRowTests.swift`, the stack's answer to `GET /rest/v1/centres?select=id,name,whatsapp_number,upi_id,upi_confirmed_at,payment_link,send_receipts` and to the confirmation update:

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct CentreRowTests {
    static let centres = Data("""
    [{"id":"22222222-2222-2222-2222-222222222222","name":"Bright Minds Tuition","whatsapp_number":"+919611299988","upi_id":"meera@okhdfcbank","upi_confirmed_at":null,"payment_link":null,"send_receipts":true}]
    """.utf8)
    static let confirmed = Data("""
    [{"upi_id":"meera@okhdfcbank","upi_confirmed_at":"2026-10-07T07:35:00+00:00","payment_link":null,"send_receipts":true}]
    """.utf8)

    @Test func decodesTheCentreWithItsPayments() throws {
        let row = try #require(try SupabaseCentreRepository.decoder.decode([CentreRow].self, from: Self.centres).first)
        let centre = row.centre
        #expect(centre.name == "Bright Minds Tuition" && centre.payments.upiID == "meera@okhdfcbank" && centre.payments.needsConfirmation)
        #expect(centre.payments.paymentLink == nil && centre.payments.sendReceipts)
        let settings = try #require(try SupabaseCentreRepository.decoder.decode([PaymentsRow].self, from: Self.confirmed).first).settings
        #expect(!settings.needsConfirmation && settings.upiConfirmedAt != nil)
    }
}
```

Add to `FakeCentreRepositoryTests`:

```swift
    @Test func paymentsAreWrittenOneColumnAtATime() async throws {
        let repo = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
        try await repo.updateUPI(id: repo.workspace?.centre.id ?? UUID(), upiID: "meera@ybl")
        #expect(repo.upiUpdates == ["meera@ybl"] && repo.workspace?.centre.payments.upiID == "meera@ybl")
        #expect(repo.workspace?.centre.payments.upiConfirmedAt == nil, "a changed id is unconfirmed again")
        try await repo.confirmUPI(id: UUID(), at: FakeCountsRepository.fixedNow)
        #expect(repo.workspace?.centre.payments.upiConfirmedAt == FakeCountsRepository.fixedNow)
        try await repo.updatePaymentLink(id: UUID(), link: "https://pay.example/meera")
        try await repo.updateSendReceipts(id: UUID(), on: false)
        #expect(repo.workspace?.centre.payments.paymentLink == "https://pay.example/meera" && repo.workspace?.centre.payments.sendReceipts == false)
        #expect(FakeCentreRepository.meeraWorkspace.centre.payments.upiConfirmedAt != nil && FakeCentreRepository.meeraWorkspaceUnconfirmed.centre.payments.needsConfirmation)
        #expect(FakeCentreRepository.meeraWorkspaceWithoutUPI.centre.payments.upiID == nil)
    }
```

Add to `FakeAttendanceRepositoryTests`:

```swift
    @Test func theMessageLogRemembersFeeMessages() async throws {
        let log = FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed)
        let october = try await log.feeLogs(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.map(\.studentID) == [FakeStudentsRepository.id(4)] && october[0].kind == .reminder)
        #expect(Day(october[0].openedAt, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 6))
        let made = try await log.logFee(centre: centre, studentID: FakeAttendanceRepository.hemanth, kind: .receipt, month: Period(year: 2026, month: 10))
        #expect(made.kind == .receipt && log.feeLogged == [made])
        #expect(try await log.feeLogs(centre: centre, student: FakeAttendanceRepository.hemanth).map(\.kind) == [.receipt])
        #expect(try await log.feeLogs(centre: centre, month: Period(year: 2026, month: 9)).map(\.studentID) == [FakeStudentsRepository.id(8)])
    }
```

(`FakeStudentsRepository.id(_:)` becomes `public nonisolated static`.) And a `MemoryQRImageStore` test in `JSONCacheTests.swift`'s file or a new `QRImageStoreTests.swift`: save, read back, remove, read nil; `FileQRImageStore` round-trips a 3-byte `Data` under a throwaway centre id and removes it.

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `FeeLogRow`, `PaymentsRow`, `updateUPI`, `QRImageStore` not found.

- [ ] **Step 3: Implement**

`Data/Messages`: `FeeLog` and the three methods on the protocol; `SupabaseMessageLogRepository.feeLogs(centre:month:)` selects `student_id, kind, opened_at, about_date` with `.eq("centre_id")`, `.in("kind", values: ["reminder", "receipt"])`, `.eq("about_date", value: month.isoDay)`, `.order("opened_at", ascending: false)`; `feeLogs(centre:student:)` the same by `student_id` (kinds in, ordered); `logFee` inserts `centre_id`, `student_id`, `kind`, `about_date = month.isoDay` with `.select(columns).single()`; `FeeLogRow` (`studentId: UUID?`, `kind: String`, `openedAt: Date`, `aboutDate: String?`) whose `log` is nil without a student, a known kind or a month (`Period(isoDay:)`). The fake filters `feeLogs` by month or student, sorted newest first, and appends on `logFee` at `now()`.

`Data/Centres`: `CentreRow` gains the four columns (`upiId: String?`, `upiConfirmedAt: Date?`, `paymentLink: String?`, `sendReceipts: Bool`) and a `centre` computed value; `PaymentsRow` decodes a settings update's answer; `workspace(for:)` selects `id, name, whatsapp_number, upi_id, upi_confirmed_at, payment_link, send_receipts`; `updateUPI` updates `["upi_id": id ?? .null, "upi_confirmed_at": .null]`; `updatePaymentLink` `["payment_link": …]`; `updateSendReceipts` `["send_receipts": .bool(on)]`; `confirmUPI` `["upi_confirmed_at": .string(ISO8601DateFormatter().string(from: at))]`; `static let decoder = PostgRESTDecoder.make()` (the row decodes with it; `createCentre` keeps `PaymentSettings()`).

`Data/Cache/QRImageStore.swift`: the protocol; `FileQRImageStore` writes under `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]/TutorCentral/upi-qr-<centre>.png` with `.completeFileProtection` (the register cache's folder; make the directory), reads with `Data(contentsOf:)`, removes with `removeItem` (ignoring a missing file); `MemoryQRImageStore` a dictionary.

`AppShell/Dependencies.swift`: `fees`, `qrImages` (the init gains two parameters: an `init` may take more than six). `Fixtures.dependencies(for:)`: `fees: FakeFeesRepository(invoices: fees(for: state))` where `fees(for:)` is `[]` for `.feesEmpty`, `.feesGenerate`, `.todayEmpty`, `.studentsEmpty`, `.attendanceEmpty`, `.classesEmpty`; `.octoberOnly` for `.reportsEmpty`'s November (nothing in November either way; `octoberOnly` keeps Reports' October numbers) and `.seed` otherwise; `messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed, feeLogs: FakeMessageLogRepository.feeSeed, now:)`; `qrImages: MemoryQRImageStore()` (Task 12 seeds `payments-qr`'s image); `centres.workspace = workspace(for: state)`: `meeraWorkspaceWithoutUPI` for `.feesEmpty`, `.feesGenerate`, `.paymentsEmpty`; `meeraWorkspaceUnconfirmed` for `.feesPayee`; `meeraWorkspace` otherwise (and `initialState(for:)` returns `.ready(workspace(for: state))`; `LaunchStateTests` compares against `Fixtures.workspace(for:)` where it compared `meeraWorkspace`). The Phase 5 `LaunchState` cases are added in Task 9, 10, 12 and 14 with their screens; `Fixtures` grows then.

- [ ] **Step 4: Prove the write paths in Swift against the local stack**

As Task 5's step 4, a throwaway test: `logFee` reminder for Dev about October, `feeLogs(centre:month:)` reads it back, `feeLogs(centre:student:)` too; `updateUPI("meera@ybl")` then `workspace(for:)` shows it unconfirmed; `confirmUPI(at: now)`; `updatePaymentLink`, `updateSendReceipts(false)`; each confirmed in psql (`select upi_id, upi_confirmed_at, payment_link, send_receipts from centres`). Delete the test; `supabase db reset`.

- [ ] **Step 5: Run, format, commit; open PR 2**

Run: `cd ios && swiftformat . && cd .. && bun check`
Expected: green (the db step runs Task 4's tests again).

```bash
git add ios supabase
git commit -m "Data: reminders and receipts on the message log by month, the centre's payment settings, the QR image kept on the phone, the fees in Dependencies and the fixtures"
git push -u origin phase-5/data
gh pr create --title "Data: the fees repository, fee logs, the centre's payments, the QR store, the fakes, every answer decoded; the RLS tests" --body "Phase 5 Tasks 4 to 6. No migration: a reminder names its invoice by student and about_date = the month (student_id, period is unique), and Generate's count is made on the device. Every read decoded from the local stack's real answer; every write run in Swift against it (mark paid, undo, waive, generate, the logs, the four payment columns), confirmed in psql."
```

Merge when green.

### Task 7: DesignSystem: the Phase 5 parts (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Components/FeeRows.swift`, `MoneyPair.swift`, `PayeeCard.swift`, `OnSheetRows.swift`, `ReportRows.swift`, `QRRow.swift`
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/Banner.swift` (`BannerLink`)
- Test: none beyond the previews (DesignSystem has no logic here); `DesignSystemTests/TokenDocumentTests` still passes because no token changes.

**Interfaces (components.md, "Phase 5 parts"):**

```swift
/// The money pair hero: Outstanding in due over its line, Collected in ok over its line, a line rule between (P5-Fees-*, P5-Reports-Fees, P5-StudentFees).
public struct MoneyPair: View { public init(outstanding: String, outstandingLine: String, collected: String, collectedLine: String) }
/// The second line of a fee row: its words, an optional tone (ok for "Reminded Tue 6 Oct") and symbol (checkmark).
public struct FeeRowLine: Hashable, Sendable { public let text: String; public let tone: StatusTone?; public let symbol: String?
    public init(_ text: String, tone: StatusTone? = nil, symbol: String? = nil) }
/// Remind (secondary, bell) and Mark paid (primary, checkmark), 44 high, radius 14, side by side (the Kit's fee row).
public struct FeeButtons: View { public init(remind: @escaping () -> Void, markPaid: @escaping () -> Void) }
/// The fee row: title rowTitle over its line; the amount numberRow over a compact chip; `buttons` under them on a due row. Padding 12 16; no press of its own.
public struct FeeRow: View { public init(title: String, line: FeeRowLine, amount: String, chip: Chip.Kind, buttons: FeeButtons? = nil) }
/// A Banner that opens something: the chevron on the right, the whole line presses (the overdue banner).
public struct BannerLink: View { public init(symbol: String, text: String, tone: StatusTone?, action: @escaping () -> Void) }
/// "Parents are told to pay <id>" with Change (secondary) and That's right (primary, checkmark) (P5-Fees-Payee).
public struct PayeeCard: View { public init(title: String, line: String, change: @escaping () -> Void, confirm: @escaping () -> Void, confirming: Bool) }
/// A row of a list on a sheet (P5-Generate): label subhead (700 when strong) left, a numberRow value right; divided by line.
public struct OnSheetRow: View { public init(label: String, value: String, strong: Bool = false) }
/// A selectable card on a sheet (P5-Reports-Export): surface2, accent border and haloFocus with a tick when selected, else a 24 ring.
public struct ChoiceCard: View { public init(title: String, line: String, selected: Bool, action: @escaping () -> Void) }
/// Reports: name over the class, the amount, the compact chip (P5-Reports-Fees).
public struct ReportFeeRow: View { public init(name: String, className: String, amount: String, chip: Chip.Kind) }
/// Reports: name over "3 present · 1 absent" (present ok 600; absent overdue 600 when more than none), the percentage numberRow (an en dash in text3 when nothing was marked) (P5-Reports-Attendance).
public struct ReportAttendanceRow: View { public init(name: String, present: Int?, absent: Int?, percent: String?) }
/// Parent payments: the QR thumbnail 56 (radius 10, on white), "QR from your UPI app" over its line, a quiet Remove in overdue (P5-Payments-QR).
public struct QRRow: View { public init(image: UIImage, title: String, line: String, remove: @escaping () -> Void) }
```

- [ ] **Step 1: Build each part to its board with a preview**

`FeeRows.swift` (under 400 lines; `FeeRow`, `FeeRowLine`, `FeeButtons`): the head is an `HStack(alignment: .top, spacing: Tokens.rowPaddingDense)` of the two-line title block (`rowTitle`; the line `footnote` in `line.tone?.color ?? Tokens.text2`, with `Image(systemName:)` at `Tokens.iconInline - 2`… no: the board draws the tick at 14, the Banner's `symbolSize`; name a constant `lineSymbolSize = 14` on `FeeRowLine`) and the trailing `VStack(alignment: .trailing, spacing: Tokens.rowGapInner * 2)` of the amount (`numberRow`, `monospacedDigit`) and `Chip(chip, compact: true)`; then `buttons` when given; `.padding(.vertical, Tokens.rowPaddingDense).padding(.horizontal, Tokens.rowPaddingHorizontal)`; the row is one accessibility element with the buttons as children (`accessibilityElement(children: .contain)`). `FeeButtons`: `HStack(spacing: Tokens.tileGap)` of `Button { } label: { Label("Remind", systemImage: "bell").frame(maxWidth: .infinity) }.buttonStyle(.secondary(.row))` and `Label("Mark paid", systemImage: "checkmark")` `.buttonStyle(.primary(.row))` (`ButtonSize.row`, 44 high with radius `radiusChip`, exists since Phase 4 for exactly this row). Icons at `Tokens.iconSmall` through `.environment(\.buttonIconSize, Tokens.iconSmall)`.

`MoneyPair.swift`: `HStack(spacing: 0)` of two `VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2)` (an `Eyebrow`, the number in `displayCompact` `monospacedDigit` in `Tokens.due.color` / `Tokens.ok.color`, the line `footnote` `text2`), the first with `.padding(.trailing, Tokens.rowPaddingHorizontal)` and a trailing `Rectangle` divider `Tokens.line` 1 wide, the second with `.padding(.leading, Tokens.rowPaddingHorizontal)`; each `.frame(maxWidth: .infinity, alignment: .leading)`; wrapped in `Card(.hero)`.

`BannerLink` in `Banner.swift`: `Button(action:)` whose label is the Banner's `HStack` plus `Image(systemName: "chevron.right")` at `Tokens.iconInline` in `text3`; `.pressable()`; the tone colours the text and symbol (the overdue banner is `overdue`).

`PayeeCard.swift`: `Card(.compact)` is padding 14 all round; the board draws 14 16 16: a plain `VStack(alignment: .leading, spacing: Tokens.tileGap)` with the title `rowTitle`, the line `footnote` `text2`, `HStack(spacing: Tokens.tileGap)` of `Button("Change").buttonStyle(.secondary(.row))` and `Button { } label: { Label("That's right", systemImage: "checkmark") }.buttonStyle(.primary(.row, loading: confirming))`, `.padding(.top, Tokens.cardPaddingCompact).padding([.horizontal, .bottom], Tokens.rowPaddingHorizontal).surface(radius: Tokens.radiusTile)`.

`OnSheetRows.swift`: `OnSheetRow` is an `HStack` of the label (`subhead`, 700 when strong: `typeStyle(strong ? Tokens.buttonStrong : Tokens.subhead)`) and the value (`numberRow`), padding `rowPaddingDense` × `rowPaddingHorizontal`; the caller wraps rows in `Card(.onSheet) { VStack(spacing: 0) { … .rowDivider() } }`. `ChoiceCard`: a `Button` whose label is an `HStack` of the two-line block (`rowTitle`, `footnote` `text2`) and either `Image(systemName: "checkmark")` in `accentText` at `Tokens.iconSmall` bold or a `Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: 1.5)` 24 (the checkbox's ring: reuse `Checkbox`'s constants if exposed, else name `ringSize = 24`, `ringStroke = 1.5` here); `.padding(.vertical, Tokens.rowPaddingDense).padding(.horizontal, Tokens.rowPaddingHorizontal)`; background `Tokens.surface2.color` in `radiusCard`, the border `accent` + `haloFocus` when selected else `line`; `.pressable()`; `accessibilityAddTraits(selected ? .isSelected : [])`.

`ReportRows.swift`: `ReportFeeRow` an `HStack(spacing: Tokens.rowPaddingDense)` of `RowTitles(title:subtitle:)` (internal, reuse), the amount `numberRow`, `Chip(chip, compact: true)`, in `ListRow(action: nil)`. `ReportAttendanceRow`: the name over a line built as `Text` concatenation: `Text("\(present) present").foregroundStyle(ok)` + ` · ` + `Text("\(absent) absent")` in `overdue` when `absent > 0` else `text2`, all `footnote` with 600 on the coloured parts; "No class, nothing marked" in `text2` when `present == nil`; the percent on the right in `numberRow`, or "–" in `text3`.

`QRRow.swift`: `HStack(spacing: Tokens.rowPaddingDense)` of `Image(uiImage:).resizable().interpolation(.none).scaledToFit().padding(4).frame(width: 56, height: 56).background(Color.white, in: .rect(cornerRadius: 10))` (the white ground and 4 pt inset are what a QR needs to scan: name `thumbnail = 56`, `inset = 4`, `radius = 10` as constants; white is the QR's own quiet zone, not a theme colour, and the doc comment says so), the two-line block, `Button("Remove").buttonStyle(.quiet).foregroundStyle(Tokens.overdue.color)` (a quiet destructive: add `QuietButtonStyle(tone: .overdue)` or apply `.tint`; simplest: `Button("Remove").buttonStyle(.destructiveQuiet)` as a new style in `Buttons.swift`: no fill, `overdue` text 15 600).

- [ ] **Step 2: Run, format, commit**

Run: `cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios`
Expected: green.

```bash
git checkout main && git pull && git checkout -b phase-5/fees
git add ios
git commit -m "DesignSystem: the fee row and its buttons, the money pair, the banner link, the payee card, on-sheet rows and choice cards, the report rows, the QR row"
```

### Task 8: `FeesStore`: the month, the filter, the rows, generate, mark paid with undo, waive, remind, the receipt, the payee (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/FeesStore.swift`, `FeesStore+Writes.swift`, `FeesStore+Messages.swift`, `FeesActions.swift`
- Delete: `ios/TutorCentralKit/Sources/Features/Fees/Fees.swift` (the Phase 2 marker)
- Modify: `ios/TutorCentralKit/Package.swift`, `ios/project.yml` (`FeesTests`, depending on `Fees` and `Students`)
- Test: `ios/TutorCentralKit/Tests/FeesTests/FeesStoreTests.swift`

**Interfaces:**
- Consumes: `FeesRepository`, `MessageLogRepository` (fee logs), `CentreRepository` (confirmUPI), `Register` (D33), `FeeLedger`, `FeeTotals`, `GeneratePreview`, `FeeMessage`, `AbsenceMessage.whatsAppURL`, `FeeInvoice.paidAt(for:today:now:calendar:)`.
- Produces:

```swift
@MainActor @Observable public final class FeesStore {
    /// The sheets over the Fees tab (P5-Generate, -MarkPaid, -Remind, -Receipt, -Waive).
    public enum Sheet: Hashable, Sendable, Identifiable { case generate, markPaid(UUID), remind(UUID), receipt(UUID), waive(UUID)
        public var id: String }
    /// A fee row as the tab draws it.
    public struct Row: Hashable, Sendable, Identifiable { public let invoice: FeeInvoice; public let name: String; public let line: String; public let lineTone: StatusTone?; public let lineSymbol: String?; public let state: FeeState; public let showsButtons: Bool
        public var id: UUID { invoice.id } }
    /// The undo toast after Mark paid: its words and the fee to reverse.
    public struct UndoToast: Hashable, Sendable { public let text: String; public let invoiceID: UUID }
    /// The payee card: "Parents are told to pay <id>" (confirm), or "No UPI id yet" (add).
    public enum Payee: Hashable, Sendable { case confirm(upiID: String), add }
    public private(set) var month: Period
    public var filter: FeeFilter
    public private(set) var invoices: [FeeInvoice]; public private(set) var dueBefore: [FeeInvoice]; public private(set) var logs: [FeeLog]
    public private(set) var loading: Bool; public private(set) var loaded: Bool; public private(set) var error: String?
    public var message: String?; public private(set) var canRetry: Bool; public private(set) var lastSavedAt: Date?
    public var sheet: Sheet?
    public var undo: UndoToast?             // set after a successful Mark paid; the view shows the toast and clears it
    public private(set) var writing: Bool   // a write in flight: the sheet's button loads
    public private(set) var confirming: Bool
    public private(set) var workspace: Workspace
    public var monthTitle: String; public var totals: FeeTotals; public var rows: [Row]; public var ledgerTitle: String
    public var overdue: OverdueSummary?; public var payee: Payee?; public var isEmptyMonth: Bool   // loaded, no invoices, no error
    public var generatePreview: GeneratePreview
    public var today: Day
    public func load() async                       // the first open: the current month (once)
    public func open(month: Period) async          // a month move or the link; a load generation drops a stale answer
    public func previous() async; public func next() async
    public func reload() async                     // after a write from elsewhere (the student detail's actions): the same month again
    public func openOverdue() async                // the banner: the latest month with an overdue fee
    public func workspaceChanged(_ workspace: Workspace)
    public func retryLast() async
    // + Writes
    public func generate() async -> Int?           // waits; toast "10 fees created for October."; reloads; nil on failure (message, Retry)
    public func markPaid(_ id: UUID, method: MonthFee.PaidMethod, on day: Day) async -> Bool   // waits; replaces the row; sets `undo`; opens .receipt when receipts are on and the parent has a number
    public func undoPaid(_ id: UUID) async -> Bool // waits; "Couldn't undo. <Dev>'s fee stays paid." with Retry on failure
    public func waive(_ id: UUID, reason: String) async -> Bool
    public func confirmPayee() async               // confirmUPI; workspace updated; onWorkspaceChanged
    public var onWorkspaceChanged: (Workspace) -> Void
    // + Messages
    public func reminder(for id: UUID) -> FeeMessageSheet?   // nil when the invoice is gone or settled
    public func receipt(for id: UUID) -> FeeMessageSheet?    // nil unless paid and receipts on
    public func send(_ sheet: FeeMessageSheet) async -> URL? // logs (reminder or receipt), then the link; nil with a toast on failure
    public init(workspace: Workspace, register: any Register, fees: any FeesRepository, messages: any MessageLogRepository, centres: any CentreRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
/// What the message sheets show (P5-Remind, P5-Receipt).
public struct FeeMessageSheet: Hashable, Sendable, Identifiable {
    public let invoiceID: UUID; public let kind: FeeLog.Kind; public let student: Student; public let title: String; public let headline: String; public let parentLine: String; public let label: String; public let text: String; public let note: String; public let url: URL?
    public var id: UUID { invoiceID } }
public struct FeesActions { let openPayments: () -> Void; let openStudent: (UUID) -> Void
    public init(openPayments: @escaping () -> Void, openStudent: @escaping (UUID) -> Void) }
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Fees

@MainActor struct FeesStoreTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let messages = FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed)
    let centres = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
    let october = Period(year: 2026, month: 10)
    let dev = FakeFeesRepository.devOctober
    let hemanth = FakeFeesRepository.hemanthOctober

    func make(workspace: Workspace = FakeCentreRepository.meeraWorkspace, invoices: [FeeInvoice]? = nil) async -> FeesStore {
        if let invoices { fees.invoices = invoices }
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(workspace: workspace, register: register, fees: fees, messages: messages, centres: centres, now: { FakeCountsRepository.fixedNow })
        await store.load()
        return store
    }

    @Test func theMonthOpensOnOctoberWithTheBoardsNumbers() async {
        let store = await make()
        #expect(store.month == october && store.monthTitle == "October 2026" && store.filter == .all && store.loaded)
        #expect(store.totals.outstanding == Money(rupees: 4000) && store.totals.outstandingLine == "4 parents")
        #expect(store.totals.collected == Money(rupees: 7300) && store.totals.collectedLine == "6 of 10 paid")
        #expect(store.rows.map(\.name) == ["Dev Kumar", "Hemanth Reddy", "Nikhil Das", "Sahil Verma", "Akshita Rao", "Ananya Iyer", "Bir Bikram Singh", "Lakshmi Menon", "Meher Shah", "Riya Sharma"])
        #expect(store.rows[0].line == "Reminded Tue 6 Oct" && store.rows[0].lineTone == .ok && store.rows[0].lineSymbol == "checkmark" && store.rows[0].showsButtons)
        #expect(store.rows[1].line == "Lakshmi Reddy · +91 93802 60871" && store.rows[1].lineTone == nil)
        #expect(store.rows[4].line == "Paid by UPI on 4 Oct" && store.rows[4].state == .paid && !store.rows[4].showsButtons)
        #expect(store.ledgerTitle == "10 fees" && store.overdue?.text == "₹1,000 overdue from September · 1 parent")
        #expect(store.payee == nil, "the fixture's id is confirmed")
        #expect(!store.isEmptyMonth && !store.generatePreview.canCreate && store.generatePreview.title == "Everyone has a fee for October")
    }

    @Test func theFiltersAndTheMonthMoves() async {
        let store = await make()
        store.filter = .due
        #expect(store.rows.count == 4 && store.ledgerTitle == "4 due" && store.rows.allSatisfy(\.showsButtons))
        store.filter = .paid
        #expect(store.rows.count == 6 && store.ledgerTitle == "6 paid")
        await store.previous()
        #expect(store.month == Period(year: 2026, month: 9) && store.totals.collected == Money(rupees: 10300) && store.overdue == nil)
        store.filter = .all
        #expect(store.rows.first?.name == "Nikhil Das" && store.rows.first?.state == .overdue && store.rows.first?.line == "Reminded Wed 30 Sep")
        await store.next()
        await store.next()
        #expect(store.month == Period(year: 2026, month: 11) && store.isEmptyMonth && store.generatePreview.count == 10)
        await store.openOverdue()
        #expect(store.month == Period(year: 2026, month: 9), "the banner opens the latest overdue month")
    }

    @Test func aQuickSecondMonthMoveWins() async {
        let store = await make()
        fees.delay = .milliseconds(80)
        async let first: () = store.open(month: Period(year: 2026, month: 9))
        fees.delay = nil
        await store.open(month: Period(year: 2026, month: 11))
        await first
        #expect(store.month == Period(year: 2026, month: 11) && store.invoices.isEmpty)
    }

    @Test func thePayeeCardShowsUntilConfirmed() async {
        let store = await make(workspace: FakeCentreRepository.meeraWorkspaceUnconfirmed)
        #expect(store.payee == .confirm(upiID: "meera@okhdfcbank"))
        var changed: Workspace?
        store.onWorkspaceChanged = { changed = $0 }
        await store.confirmPayee()
        #expect(store.payee == nil && centres.confirmations.count == 1 && changed?.centre.payments.upiConfirmedAt != nil)
        let noID = await make(workspace: FakeCentreRepository.meeraWorkspaceWithoutUPI)
        #expect(noID.payee == .add)
    }

    @Test func generatingReadsTheMonthAgainAndSaysHowMany() async {
        let store = await make(invoices: [])
        #expect(store.isEmptyMonth && store.generatePreview.canCreate && store.generatePreview.buttonLabel == "Create 10 fees")
        let made = await store.generate()
        #expect(made == 10 && store.invoices.count == 10 && store.message == "10 fees created for October." && !store.canRetry)
        #expect(store.sheet == nil && store.lastSavedAt != nil)
    }

    @Test func nothingToCreateDisablesTheButton() async {
        let store = await make()
        store.sheet = .generate
        #expect(!store.generatePreview.canCreate && store.generatePreview.buttonLabel == "Nothing to create")
        fees.nextError = URLError(.notConnectedToInternet)
        let empty = await make(invoices: [])
        #expect(await empty.generate() == nil && empty.message == "Couldn't create the fees. Check your connection and try again." && empty.canRetry)
    }

    @Test func markingPaidWaitsForTheServerAndOffersUndo() async throws {
        let store = await make()
        fees.delay = .milliseconds(50)
        let task = Task { await store.markPaid(dev, method: .upi, on: store.today) }
        try await Task.sleep(for: .milliseconds(10))
        #expect(store.writing && store.rows.first { $0.id == dev }?.state == .due, "nothing moves before the server answers")
        #expect(await task.value)
        #expect(!store.writing && store.totals.outstanding == Money(rupees: 3000) && store.totals.collectedLine == "7 of 10 paid")
        let row = try #require(store.rows.first { $0.id == dev })
        #expect(row.state == .paid && row.line == "Paid by UPI on 7 Oct" && !row.showsButtons)
        #expect(store.undo == UndoToast(text: "Dev's fee marked paid by UPI.", invoiceID: dev) && fees.paid == [dev])
        #expect(store.sheet == .receipt(dev), "receipts are on and Ramesh has a number")
    }

    @Test func undoReversesTheOneFeeNamed() async {
        let store = await make()
        _ = await store.markPaid(dev, method: .cash, on: store.today)
        _ = await store.markPaid(hemanth, method: .upi, on: store.today)
        #expect(store.undo?.invoiceID == hemanth, "the newer toast replaces the older; Dev stays paid")
        #expect(await store.undoPaid(dev))
        #expect(fees.undone == [dev] && store.rows.first { $0.id == dev }?.state == .due && store.rows.first { $0.id == hemanth }?.state == .paid)
        #expect(store.undo == nil && store.totals.outstanding == Money(rupees: 2800))
    }

    @Test func aFailedMarkPaidKeepsTheRowDueWithRetry() async {
        let store = await make()
        fees.nextError = URLError(.notConnectedToInternet)
        #expect(await store.markPaid(dev, method: .upi, on: store.today) == false)
        #expect(store.rows.first { $0.id == dev }?.state == .due && store.undo == nil && store.sheet == nil)
        #expect(store.message == "Couldn't mark the fee paid. Check your connection and try again." && store.canRetry)
        await store.retryLast()
        #expect(fees.paid == [dev] && store.rows.first { $0.id == dev }?.state == .paid)
    }

    @Test func aFailedUndoLeavesTheFeePaid() async {
        let store = await make()
        _ = await store.markPaid(dev, method: .upi, on: store.today)
        fees.nextError = URLError(.notConnectedToInternet)
        #expect(await store.undoPaid(dev) == false)
        #expect(store.rows.first { $0.id == dev }?.state == .paid && store.message == "Couldn't undo. Dev's fee stays paid." && store.canRetry)
    }

    @Test func aReceiptIsOfferedOnlyWhenOnAndThereIsANumber() async throws {
        var off = FakeCentreRepository.meeraWorkspace
        off.centre.payments.sendReceipts = false
        let store = await make(workspace: off)
        _ = await store.markPaid(dev, method: .upi, on: store.today)
        #expect(store.sheet == nil && store.undo != nil)
        let receipt = try #require(store.receipt(for: dev))
        #expect(receipt.title == "Send a receipt" && receipt.headline == "Dev's fee is paid" && receipt.parentLine == "Ramesh Kumar · +91 98848 43831" && receipt.label == "Receipt")
        #expect(receipt.text.hasPrefix("Hello Ramesh, received ₹1,000 by UPI on 7 Oct for Dev's October fee. Thank you."))
        #expect(receipt.note == "Opens WhatsApp with the receipt ready to send. We note it on the fee." && receipt.url?.host() == "wa.me")
        let url = await store.send(receipt)
        #expect(url == receipt.url && messages.feeLogged.map(\.kind) == [.receipt] && store.lastSavedAt != nil)
    }

    @Test func remindingLogsOnceAndReadsReminded() async throws {
        let store = await make()
        let sheet = try #require(store.reminder(for: hemanth))
        #expect(sheet.title == "Remind the parent" && sheet.headline == "Hemanth's October fee is due" && sheet.parentLine == "Lakshmi Reddy · +91 93802 60871")
        #expect(sheet.label == "Message" && sheet.text == """
        Hello Lakshmi, Hemanth's fee of ₹1,200 for October is due. You can pay by UPI to meera@okhdfcbank. Thank you.

        Meera Nair
        Bright Minds Tuition
        """)
        #expect(sheet.note == "Opens WhatsApp with the message ready to send. We note the date on the fee. The text is copied too, in case WhatsApp can't open.")
        let url = await store.send(sheet)
        #expect(url == sheet.url && messages.feeLogged.map(\.kind) == [.reminder] && messages.feeLogged[0].month == october)
        #expect(store.rows.first { $0.id == hemanth }?.line == "Reminded today" && store.rows.first { $0.id == hemanth }?.lineTone == .ok)
        #expect(store.reminder(for: FakeFeesRepository.id(1)) == nil, "a paid fee has no reminder")
        messages.nextError = URLError(.notConnectedToInternet)
        #expect(await store.send(sheet) == nil && store.message == "Couldn't open WhatsApp. Check your connection and try again.")
    }

    @Test func aStudentWithoutANumberShowsTheTextWithoutALink() async throws {
        var students = FakeStudentsRepository.seed
        students[9].parentPhone = nil
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees, messages: messages, centres: centres, now: { FakeCountsRepository.fixedNow })
        await store.load()
        let sheet = try #require(store.reminder(for: FakeFeesRepository.sahilOctober))
        #expect(sheet.url == nil && sheet.parentLine == "Add the parent's number first")
        _ = await store.markPaid(FakeFeesRepository.sahilOctober, method: .cash, on: store.today)
        #expect(store.sheet == nil, "no number, no receipt sheet")
    }

    @Test func waivingSettlesWithoutCollecting() async {
        let store = await make()
        #expect(await store.waive(FakeFeesRepository.sahilOctober, reason: "  Joined mid-month "))
        let row = store.rows.first { $0.id == FakeFeesRepository.sahilOctober }
        #expect(row?.state == .waived && row?.line == "Waived · Joined mid-month" && row?.showsButtons == false)
        #expect(store.totals.outstanding == Money(rupees: 3200) && store.totals.collected == Money(rupees: 7300) && store.sheet == nil)
        #expect(store.message == "Sahil's fee waived." && fees.waived == [FakeFeesRepository.sahilOctober])
    }

    @Test func aFailedReadSaysSoAndKeepsTheLastMonth() async {
        let store = await make()
        fees.nextError = URLError(.notConnectedToInternet)
        await store.next()
        #expect(store.error == "Couldn't load fees. Check your connection and try again." && store.month == Period(year: 2026, month: 11))
        #expect(!store.isEmptyMonth, "a failed read is not an empty month")
        await store.retryLast()
        #expect(store.error == nil && store.isEmptyMonth)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `FeesStore` not found (after `FeesTests` is in `Package.swift` — `.testTarget(name: "FeesTests", dependencies: ["Fees", "Students"])` — and `project.yml` — `- package: TutorCentralKit/FeesTests`).

- [ ] **Step 3: Implement**

`FeesStore.swift`: the state above; `load()` opens the current month once (`guard !loaded`); `open(month:)` bumps `loadGeneration`, reads `invoices(centre:month:)`, `dueBefore(centre:month: today.period)` (always the current month's earlier debt, whichever month is shown, so the banner's month can be opened from anywhere) and `feeLogs(centre:month:)` with `async let`, drops a stale answer, sets `error` on failure ("Couldn't load fees. Check your connection and try again.", `canRetry` with `lastFailed = { await self?.open(month:) }`); `reload()` is `open(month: month)`; `rows` maps `FeeLedger.rows(invoices, filter:, current: today.period, name: { register.student($0)?.name ?? "" })` to `Row`s: the line is the latest `reminder` log about the month for that student ("Reminded today" / "Reminded Tue 6 Oct", `.ok`, "checkmark") when the state is due or overdue, else the parent line (name · number, "No parent details yet" when none), else `invoice.settledLine(calendar:)`; `showsButtons` is `!state.isSettled`; `overdue = FeeLedger.overdueBefore(dueBefore, current: today.period)` only when `month == today.period`; `openOverdue()` opens `FeeLedger.overdueBefore(dueBefore, current: today.period)?.latest` from any month; `payee` is `.add` when `workspace.centre.payments.upiID == nil`, `.confirm` when `needsConfirmation`, else nil; `isEmptyMonth = loaded && invoices.isEmpty && error == nil && !loading`; `generatePreview = GeneratePreview.make(students: register.activeStudents, classes: register.activeClasses, invoices: invoices, month: month)`.

`FeesStore+Writes.swift`: `generate()` sets `writing`, calls `fees.generate`, on success `sheet = nil`, `message = "\(count) \(count == 1 ? "fee" : "fees") created for \(month.monthName)."`, `lastSavedAt = now()`, then `await reload()`; on failure the message and `lastFailed`. `markPaid(_:method:on:)`: `writing = true`, `fees.markPaid(id:method:at: FeeInvoice.paidAt(for: day, today: today, now: now(), calendar:))`, replace the invoice in `invoices`, `sheet = receipt(for:) != nil ? .receipt(id) : nil`, `undo = UndoToast(text: "\(firstName)'s fee marked paid\(by).", invoiceID: id)` (by: " by UPI" / " by cash" / ""), `lastSavedAt`; failure: the message, `canRetry`, `lastFailed`. `undoPaid` the same shape with `markDue`, clearing `undo` when it names that fee; its failure message names the student. `waive` trims the reason, calls `fees.waive`, replaces, `sheet = nil`, `message = "\(firstName)'s fee waived."`. `confirmPayee` sets `confirming`, calls `centres.confirmUPI(id:at: now())`, sets `workspace.centre.payments.upiConfirmedAt`, calls `onWorkspaceChanged`.

`FeesStore+Messages.swift`: `reminder(for:)` finds the invoice (state due or overdue) and its student, builds `FeeMessage(kind: .reminder, …, upiID: payments.upiID, paymentLink: payments.paymentLink, tutorName: profile.displayName, centreName:)`, the sheet with `title: "Remind the parent"`, `headline: "\(firstName)'s \(month.monthName) fee is due"`, `parentLine` (name · number, or "Add the parent's number first"), `label: "Message"`, the note, `url` through `AbsenceMessage.whatsAppURL` when there is a number. `receipt(for:)` needs `status == .paid`, `payments.sendReceipts` and a number: `title: "Send a receipt"`, `headline: "\(firstName)'s fee is paid"`, `label: "Receipt"`, kind `.receipt(method: paidMethod ?? .other, day: paidOn)`, the note "Opens WhatsApp with the receipt ready to send. We note it on the fee.". `send(_:)` logs through `messages.logFee(centre:studentID:kind:month:)`, inserts the log into `logs`, `lastSavedAt = now()`, returns the url; on failure `message = "Couldn't open WhatsApp. Check your connection and try again."`, `canRetry = false`, nil.

- [ ] **Step 4: Run, format, commit**

Run: `cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios
git commit -m "FeesStore: the month and its rows, the overdue banner, the payee, generate, mark paid with undo, waive, the reminder and receipt sheets"
```

### Task 9: The Fees tab on screen: the month, the filters, the empty month, the sheets, the toast; AppShell's wiring; the launch states (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/FeesView.swift`, `FeesSections.swift`, `GenerateSheet.swift`, `MarkPaidSheet.swift`, `WaiveSheet.swift`, `FeeMessageSheet.swift` (the view; the value type of Task 8 keeps its name: call the view `FeeMessageSheetView`); `ios/TutorCentralKit/Sources/AppShell/RootView+Fees.swift`
- Modify: `AppShell/ShellState.swift` (`fees: FeesStore?`, reset), `TabsView.swift` (the Fees root replaces `LaterView(place: .feesTab)`; routes), `TabsState.swift` (`open(.fees)` returns true), `RootView.swift` (`onOpenURL` sets the month; `todayView` passes `openFeesDue`), `RootView+LaunchStates.swift` (`tab(for:)`, `feesBoardState`), `LaunchState.swift` (13 cases: `feesEmpty = "fees-empty"`, `fees`, `feesDue = "fees-due"`, `feesPaid = "fees-paid"`, `feesOverdue = "fees-overdue"`, `feesPayee = "fees-payee"`, `feesGenerate = "fees-generate"`, `feesGenerateNothing = "fees-generate-nothing"`, `feesMarkPaid = "fees-mark-paid"`, `feesMarkedPaid = "fees-marked-paid"`, `feesReceipt = "fees-receipt"`, `feesRemind = "fees-remind"`, `feesWaive = "fees-waive"`), `Fixtures.swift`, `LaterView.swift` (`feesTab` removed, `laterFees` state removed with it: U12 closes), `Features/Today/TodayStore.swift` (`TodayActions.openFeesDue`), `Features/Today/TodayView.swift` (the Due tile calls it), `docs/design/information-architecture.md` only if a state name must change
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (`theFeesStatesOpenTheTab`), `TabsStateTests.swift` (`aFeesLinkOpensTheTab`), `Tests/TodayTests/TodayStoreTests.swift` unchanged (`TodayActions` gains a closure; its tests build it with `{}`).

**Interfaces:**

```swift
public enum FeesBoardState: Hashable, Sendable { case due, paid, september, generate, markPaid, markedPaid, receipt, remind, waive }
public struct FeesView: View { public init(store: FeesStore, actions: FeesActions, boardState: FeesBoardState? = nil) }
// TodayActions gains `openFeesDue: () -> Void`; RootView fulfils it with `feesStore(for:).filter = .due; shell.tabs.select(.fees)`.
// TabsState.open(.fees(month:)) → true: selects the tab, clears its stack; RootView then `Task { await store.open(month:) }` when the month parses ("YYYY-MM" → Period).
```

- [ ] **Step 1: Write the failing tests**

Add to `LaunchStateTests`:

```swift
    @MainActor @Test func theFeesStatesOpenTheTab() async throws {
        let states: [LaunchState] = [.feesEmpty, .fees, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate, .feesGenerateNothing,
                                     .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind, .feesWaive]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.workspace(for: state)) && RootView.tab(for: state) == .fees)
        }
        #expect(RootView.feesBoardState(.feesDue) == .due && RootView.feesBoardState(.feesMarkedPaid) == .markedPaid && RootView.feesBoardState(.fees) == nil)
        let centre = Fixtures.meeraWorkspace.centre.id
        #expect(try await Fixtures.dependencies(for: .feesEmpty).fees.invoices(centre: centre, month: Period(year: 2026, month: 10)).isEmpty)
        #expect(try await Fixtures.dependencies(for: .fees).fees.dueBefore(centre: centre, month: Period(year: 2026, month: 10)).count == 1)
        #expect(Fixtures.workspace(for: .feesPayee).centre.payments.needsConfirmation && Fixtures.workspace(for: .feesEmpty).centre.payments.upiID == nil)
        #expect(!Fixtures.workspace(for: .fees).centre.payments.needsConfirmation)
    }
```

Add to `TabsStateTests`:

```swift
    @Test func aFeesLinkOpensTheTab() {
        let tabs = TabsState(selected: .today)
        tabs.push(.settings)
        #expect(tabs.open(.fees(month: "2026-09")))
        #expect(tabs.selected == .fees && tabs.paths[.fees] == [])
        #expect(RootView.linkMonth("2026-09") == Period(year: 2026, month: 9) && RootView.linkMonth("2026-13") == nil && RootView.linkMonth(nil) == nil)
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, the cases, `feesBoardState`, `linkMonth`, `Fixtures.workspace(for:)` not found.

- [ ] **Step 3: Implement**

`FeesView` (to P5-Fees-Empty, -All, -Due, -Paid, -Overdue, -Payee, -MarkedPaid, in both appearances), its pieces in `FeesSections.swift`:

- The `ScrollView` with `.statusBarGlass()`, `.background(Tokens.ground.color)`, `.toolbar(.hidden, for: .navigationBar)`, `.padding(.top, max(0, Tokens.pageTop - topInset))`, `.padding(.bottom, Tokens.contentBottom)`; `.refreshable { await store.reload() }`.
- The title row: `Text("Fees").typeStyle(Tokens.display)` with `Button("Payments") { actions.openPayments() }.buttonStyle(.quiet)` on the right.
- `MonthHeader(title: store.monthTitle, previous: { Task { await store.previous() } }, next: { Task { await store.next() } })`, with the stale pattern while `store.loading` (`.opacity(Tokens.opacityStale)` on the sections below and a 16 pt `ProgressView` beside the title, as History does).
- The payee: `.add` → `Card { HStack { EmptyRow(symbol: "indianrupeesign", title: "No UPI id yet", line: "Reminders tell parents where to pay. Add your UPI id or scan its QR."); Button("Add", action: actions.openPayments).buttonStyle(.quiet).padding(.trailing, Tokens.rowPaddingHorizontal) } }`; `.confirm(id)` → `PayeeCard(title: "Parents are told to pay \(id)", line: "Reminders carry this UPI id. Not right? Change it.", change: actions.openPayments, confirm: { Task { await store.confirmPayee() } }, confirming: store.confirming)`.
- The empty month (`store.isEmptyMonth`): no hero, no segmented; one `Card { EmptyState(symbol: "indianrupeesign", title: "No fees for \(month.monthName) yet", line: "Generate them to see who owes what: one fee per student, from the class fee or their own.", action: .init("Generate \(month.monthName)'s fees", emphasis: .primary) { store.sheet = .generate }, size: .screen) }`.
- Otherwise: `MoneyPair(outstanding: totals.outstanding.formatted, outstandingLine: totals.outstandingLine, collected: totals.collected.formatted, collectedLine: totals.collectedLine)`; the overdue `BannerLink(symbol: "exclamationmark.circle", text: overdue.text, tone: .overdue) { Task { await store.openOverdue() } }` when `store.overdue` is set; `Segmented(options: FeeFilter.allCases.map { ($0, $0.title) }, selection: $store.filter)`; `SectionHeader(store.ledgerTitle, action: ("Generate", { store.sheet = .generate }))` and a `Card { VStack(spacing: 0) { ForEach(store.rows) { row in FeeRow(title: row.name, line: FeeRowLine(row.line, tone: row.lineTone, symbol: row.lineSymbol), amount: row.invoice.amount.formatted, chip: chip(row.state), buttons: row.showsButtons ? FeeButtons(remind: { store.sheet = .remind(row.id) }, markPaid: { store.sheet = .markPaid(row.id) }) : nil).rowDivider(row.id != store.rows.last?.id) } } }` where `chip(.due) = .status(.due, "Due", symbol: "clock")`, `.overdue → .status(.overdue, "Overdue", symbol: "exclamationmark.circle")`, `.paid → .status(.ok, "Paid", symbol: "checkmark")`, `.waived → .neutral("Waived")`; an empty filter (Due with nothing due) shows `EmptyRow(symbol: "checkmark.circle", title: "Nothing due", line: "Every fee for \(month.monthName) is settled.")` (unboarded, the Kit's empty row; the Paid filter with nothing paid: "Nothing paid yet", "Fees you mark paid appear here.").
- The error line under the month header when `store.error` is set: `Label(error, systemImage: "exclamationmark.triangle")` `footnote` `text2` with `Button("Retry") { Task { await store.retryLast() } }.buttonStyle(.quiet)` (Today's `refreshError` pattern).
- Sheets: `.sheet(item: $store.sheet) { sheet in switch sheet { … } }`, each a floating sheet (D28): `presentationDragIndicator(.hidden)`, `presentationCornerRadius(Tokens.radiusSheet)`, `presentationBackground(Tokens.surface1.color)`, `.modifier(SheetToasts())`.
  - `GenerateSheet(preview: store.generatePreview, creating: store.writing, create: { Task { await store.generate() } }, close:)` at `.fraction(0.65)` and `.large`: `SheetHeader(title: "Generate fees", cancel:)`; `Eyebrow(month.title)`; `Text(preview.title).typeStyle(Tokens.title2)`; `Text(preview.line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)`; `Card(.onSheet) { VStack(spacing: 0) { ForEach(preview.groups) { OnSheetRow(label: $0.line, value: $0.total.formatted).rowDivider() }; OnSheetRow(label: "\(preview.count) fees", value: preview.total.formatted, strong: true) } }` (only the total row when nothing to create: "10 fees" with the month's total of the existing invoices); the footnote "A student who already has a fee for \(month.monthName) is skipped. You can edit any fee after."; `Spacer`; `Button(preview.buttonLabel).buttonStyle(.primary(.sheet, loading: creating)).disabled(!preview.canCreate)`.
  - `MarkPaidSheet(row:, writing:, markPaid: (MonthFee.PaidMethod, Day) -> Void, waive: () -> Void, close:)` at `.fraction(0.6)` and `.large`: `SheetHeader(title: "Mark paid")`; the student line (`Avatar(name:)`, the name `rowTitle`, "₹1,000 for October" `footnote` `text2`); "Paid by" over `Segmented(options: [(.upi, "UPI"), (.cash, "Cash"), (.other, "Other")], selection:)`; "Paid on" over `PickerTile(label: "Day", value: dayText)` ("Today, 7 Oct" / "Mon 5 Oct") opening a `.popover` with the graphical `DatePicker` (`in: ...today`, `.calendarPopover(timeZone:)`); the footnote "\(parentName) is offered a receipt on WhatsApp after this. Turn receipts off under Payments." (or "A receipt is offered on WhatsApp after this." without a parent name; nothing when receipts are off); `Spacer`; `Button("Waive this fee instead") { waive() }.buttonStyle(.quiet)` centred; `Button { markPaid(method, day) } label: { Label("Mark \(amount) paid", systemImage: "checkmark") }.buttonStyle(.primary(.sheet, loading: writing))`. Tapping Waive sets `store.sheet = .waive(id)` (the sheet swaps).
  - `WaiveSheet(row:, writing:, waive: (String) -> Void, close:)` at `.fraction(0.56)` and `.large`: the header "Waive this fee"; the student line; `NotesWell(label: "Reason", text: $reason, placeholder: "Why the fee is waived", limit: FeeInvoice.waiveReasonLimit, autofocus)` (`NotesWell` gains `showsFocus`/`autofocus` as `TextWell` has, the board draws the focus ring); the footnote "A waived fee counts as settled, not collected. You can still mark it paid later."; the primary "Waive \(amount)" disabled while the trimmed reason is empty or over the limit.
  - `FeeMessageSheetView(sheet: FeeMessageSheet, send:, close:)` at `.fraction(0.65)` and `.large` for the reminder, `.fraction(0.66)` for the receipt (P5-Remind's top is 248, P5-Receipt's 290: both near two thirds; one fraction `0.66` for both is fine; the board decides the content, not the pixel): the absence alert's layout with `sheet.title`, `sheet.headline`, `sheet.parentLine`, `sheet.label`, `sheet.text` in the well, `sheet.note`, and `Label("Open WhatsApp", systemImage: "message")` primary; the reminder's Open WhatsApp also sets `UIPasteboard.general.string = sheet.text` (the view, not the store; a `#if canImport(UIKit)` is not needed, the package is iOS only). `.disabled(sheet.url == nil)`.
- The toast: `.onChange(of: store.undo) { _, undo in guard let undo else { return }; toasts.show(undo.text, action: ("Undo", { Task { await store.undoPaid(undo.invoiceID) } })); store.undo = nil }` in `RootView+Fees.swift` (the toast centre is AppShell's); `store.message` → `toasts.show(message, action: store.canRetry ? Self.retry(store) : nil)` with the success haptic on `lastSavedAt` and the error haptic on a message with Retry (a plain message such as "10 fees created for October." plays success).
- Board states: `.due`/`.paid` set the filter; `.september` opens September; `.generate` sets `sheet = .generate` after load; `.markPaid` `sheet = .markPaid(devOctober)`; `.markedPaid` calls `markPaid(devOctober, .upi, today)` after load (the toast shows; the receipt sheet is dismissed at once so the toast is seen: the board state sets `sheet = nil` after the call); `.receipt` the same without dismissing; `.remind` `sheet = .remind(hemanthOctober)`; `.waive` `sheet = .waive(sahilOctober)` with the reason "Joined mid-month" typed (`WaiveSheet(initialReason:)`).

`AppShell`: `ShellState.fees: FeesStore?` (`@ObservationIgnored`, reset); `RootView+Fees.swift`: `feesStore(for:)` as `attendanceStore(for:)` (with `onWorkspaceChanged` wired to `session.workspaceChanged` and `shell.today?.workspaceChanged`); `feesView` builds `FeesView(store:, actions: FeesActions(openPayments: { shell.tabs.push(.payments) }, openStudent: { shell.tabs.push(.student($0)) }), boardState:)` with the toast wiring above (`.payments` is a `Route` added here and its screen arrives in Task 12; until then it pushes `LaterView(place: .payments)`, a new `LaterPlace` removed in Task 12); `openFees(month:)` for the link (`static func linkMonth(_ text: String?) -> Period?` parses "YYYY-MM"); `TabsView` takes `fees: () -> Fees`; `TabsState.open(.fees)` returns true; Today's `openFeesDue`. `Fixtures.workspace(for:)` and `fees(for:)` as Task 6 said; `clock(for:)` stays 18:30 for every fees state. `LaterPlace.feesTab` and `LaunchState.laterFees` go (U12).

- [ ] **Step 4: Run, photograph, commit; open PR 3**

```bash
bun check
for s in fees-empty fees fees-due fees-paid fees-overdue fees-payee fees-generate fees-generate-nothing fees-mark-paid fees-marked-paid fees-receipt fees-remind fees-waive today; do bun shots $s; done
bun pr-shots phase-5-fees .shots/*/*.png
git add ios
git commit -m "The Fees tab: the month and its filters, the overdue banner, the payee, the empty month, generate, mark paid with undo, the receipt, remind, waive; the fees link; Today's Due tile"
git push -u origin phase-5/fees
gh pr create --title "The Fees tab: the month, due, paid, overdue, the payee, generate, mark paid with undo, the receipt, remind, waive" --body "<the pr-shots table>"
```

Compare each picture with its board before merging (the figures follow the fixture; the layout follows the board); merge when green. U12 moves to Done in `plan/ui-polish.md` with this PR's number in Task 15's documents commit.

### Task 10: A student's fees and the detail's fees section live (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/StudentFeesStore.swift`, `StudentFeesView.swift`
- Modify: `Features/Students/StudentDetailStore.swift` (`messages`, `remindedLine`), `StudentDetailSections.swift` (`MonthFeeCard` with buttons), `StudentDetailView.swift`, `StudentsActions.swift` (`openFeeAction`), `AppShell/RootView+Students.swift` (`openStudentFees` pushes `.studentFees(id)`; `openFeeAction` switches to Fees), `RootView+Fees.swift` (`studentFeesView(_:)`, `openFeeAction(_:)`), `TabsView.swift`, `TabsState.swift` (`Route.studentFees(UUID)`), `LaunchState.swift` (`studentFeesDue = "student-fees-due"`, `studentFees = "student-fees"`), `RootView+LaunchStates.swift` (`initialRoutes`: `[.student(hemanth)]` and `[.student(hemanth), .studentFees(hemanth)]`), `LaterView.swift` (`studentFees` removed), `Fixtures.swift`
- Test: `Tests/FeesTests/StudentFeesStoreTests.swift`, `Tests/StudentsTests/StudentDetailStoreTests.swift` (+ `theFeeRowReadsRemindedAndOffersActions`), `Tests/AppShellTests/LaunchStateTests.swift` (+ the two states)

**Interfaces:**

```swift
@MainActor @Observable public final class StudentFeesStore {
    public struct Row: Hashable, Sendable, Identifiable { public let invoice: FeeInvoice; public let title: String; public let line: String; public let lineTone: StatusTone?; public let lineSymbol: String?; public let state: FeeState; public let showsButtons: Bool
        public var id: UUID { invoice.id } }
    public private(set) var invoices: [FeeInvoice]; public private(set) var logs: [FeeLog]; public private(set) var loading: Bool; public private(set) var error: String?
    public var studentName: String; public var title: String   // "Hemanth's fees"
    public var totals: FeeTotals; public var outstandingLine: String   // "October" (the due months' names, newest first, at most two then "and before") / "Nothing due"
    public var collectedLine: String   // "2 of 4 months"
    public var rows: [Row]; public var sectionTitle: String   // "4 months" / "1 month"
    public var footnote: String   // "Months before Hemanth joined have no fee. A month's fee is made when you generate that month."
    public func load() async; public func reload() async
    public init(studentID: UUID, workspace: Workspace, register: any Register, fees: any FeesRepository, messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
public struct StudentFeesView: View { public init(store: StudentFeesStore, act: @escaping (FeeAction) -> Void) }
// StudentsActions gains `openFeeAction: (FeeAction) -> Void`; StudentDetailStore gains `messages: any MessageLogRepository` and `remindedLine: String?` ("Reminded Tue 6 Oct"), its `monthLine` reads "Due · Reminded Tue 6 Oct" when reminded; `MonthFeeCard` takes `act: (FeeAction) -> Void` and shows `FeeButtons` when `store.monthMark?.tone == .due`.
// RootView.openFeeAction(_:): `let store = feesStore(for:)`; `shell.tabs.select(.fees)`; `Task { await store.open(month:); store.sheet = .remind(invoice.id) / .markPaid(invoice.id) }` where the invoice is found in the opened month by student id (a month without one: the toast "No fee for <month> yet. Generate it first."). After any fee write (`store.lastSavedAt` changes) AppShell calls `shell.register?.refresh()`.
```

- [ ] **Step 1: Write the failing tests**

`Tests/FeesTests/StudentFeesStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Fees

@MainActor struct StudentFeesStoreTests {
    func make(_ id: UUID = FakeAttendanceRepository.hemanth) async -> StudentFeesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = StudentFeesStore(
            studentID: id, workspace: FakeCentreRepository.meeraWorkspace, register: register,
            fees: FakeFeesRepository(invoices: FakeFeesRepository.seed),
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed), now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func hemanthsMonthsReadAsTheBoard() async {
        let store = await make()
        #expect(store.title == "Hemanth's fees" && store.sectionTitle == "4 months")
        #expect(store.totals.outstanding == Money(rupees: 1200) && store.outstandingLine == "October" && store.totals.collected == Money(rupees: 2400) && store.collectedLine == "2 of 4 months")
        #expect(store.rows.map(\.title) == ["October 2026", "September 2026", "August 2026", "July 2026"])
        #expect(store.rows[0].state == .due && store.rows[0].line == "Lakshmi Reddy · +91 93802 60871" && store.rows[0].showsButtons)
        #expect(store.rows[1].line == "Paid by UPI on 3 Sep" && store.rows[2].line == "Paid by cash on 5 Aug" && store.rows[3].line == "Waived · Joined mid-month")
        #expect(store.rows[3].showsButtons, "a waived month can still be marked paid here")
        #expect(store.footnote == "Months before Hemanth joined have no fee. A month's fee is made when you generate that month.")
    }

    @Test func devReadsRemindedAndNikhilOverdue() async {
        let dev = await make(FakeStudentsRepository.id(4))
        #expect(dev.rows[0].line == "Reminded Tue 6 Oct" && dev.rows[0].lineTone == .ok && dev.rows[0].lineSymbol == "checkmark")
        let nikhil = await make(FakeStudentsRepository.id(8))
        #expect(nikhil.rows.map(\.state) == [.due, .overdue] && nikhil.outstandingLine == "October and September" && nikhil.collectedLine == "0 of 2 months")
    }
}
```

Add to `StudentDetailStoreTests` (its `make` gains `messages:`):

```swift
    @Test func theFeeRowReadsRemindedAndOffersActions() async throws {
        let register = await register()
        let hemanth = try #require(register.students.first { $0.name == "Hemanth Reddy" })
        let detail = StudentDetailStore(
            id: hemanth.id, register: register, attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed)
        )
        await detail.loadAttendance()
        #expect(detail.monthLine == "Due" && detail.monthMark?.tone == .due)
        let dev = try #require(register.students.first { $0.name == "Dev Kumar" })
        let devDetail = StudentDetailStore(id: dev.id, register: register, attendance: FakeAttendanceRepository(), messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed))
        await devDetail.loadAttendance()
        #expect(devDetail.monthLine == "Due · Reminded Tue 6 Oct" && devDetail.feeAction(.remind) == .remind(studentID: dev.id, month: Period(year: 2026, month: 10)))
    }
```

(`StudentDetailStore.feeAction(_ kind: FeeActionKind) -> FeeAction?` where `FeeActionKind` is `remind` or `markPaid`; nil when this month has no fee. `loadAttendance()` also reads the student's fee logs; rename it `load()` and update its callers.)

Add to `LaunchStateTests.theStudentDetailStatesOpenAkshitaOnTheStudentsTab`'s neighbour:

```swift
    @MainActor @Test func theStudentFeesStatesOpenHemanth() {
        #expect(RootView.tab(for: .studentFeesDue) == .students && RootView.initialRoutes(for: .studentFeesDue) == [.student(FakeAttendanceRepository.hemanth)])
        #expect(RootView.initialRoutes(for: .studentFees) == [.student(FakeAttendanceRepository.hemanth), .studentFees(FakeAttendanceRepository.hemanth)])
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `StudentFeesStore`, `messages:`, `feeAction`, the cases not found.

- [ ] **Step 3: Implement**

`StudentFeesStore`: reads `fees.invoices(centre:student:)` and `messages.feeLogs(centre:student:)` with `async let`; `rows` newest first with `title = invoice.period.title`, the line as `FeesStore.Row`'s rule (the parent line, Reminded, or the settled line), `showsButtons = state != .paid`; `outstandingLine` joins the due months' names (newest first; three or more: the first two then "and before"); `collectedLine = "\(paidCount) of \(count) months"` ("1 month"); `sectionTitle`; the footnote with the first name. `StudentFeesView` (to P5-StudentFees): the nav row (Back, `store.title`), `MoneyPair`, `SectionHeader(store.sectionTitle)` over a `Card` of `FeeRow`s (buttons → `act(.remind(studentID:month:))` / `act(.markPaid(…))`), the footnote; `.toolbar(.hidden, for: .tabBar)`; its store in `@State`; `.task { await store.load() }` and reload on `scenePhase == .active`.

`MonthFeeCard` (P5-StudentDetail-Fees): the existing row plus, when `store.monthMark?.tone == .due`, `FeeButtons(remind: { act(.remind…) }, markPaid: { act(.markPaid…) })` under it, inside the same card (`VStack(spacing: Tokens.tileGap)` with the row's padding); `monthLine` reads "Due · Reminded Tue 6 Oct" when `remindedLine` is set.

`AppShell`: `Route.studentFees(UUID)` → `studentFeesView(id)` (`StudentFeesView(store: StudentFeesStore(…), act: openFeeAction)`); `studentsActions.openStudentFees = { shell.tabs.push(.studentFees($0)) }`, `openFeeAction = openFeeAction`; `openFeeAction(_:)` as the interface says; the register refresh after a fee write: in `feesView`, `.onChange(of: store.lastSavedAt) { Task { await shell.register?.refresh() } }`. `Fixtures`: `studentFeesDue` and `studentFees` use `FakeFeesRepository.seed` and `feeSeed`; the register's Hemanth stays due.

- [ ] **Step 4: Run, photograph, commit; open PR 4**

```bash
bun check
for s in student-fees-due student-fees student; do bun shots $s; done
bun pr-shots phase-5-student-fees .shots/*/*.png
git checkout -b phase-5/student-fees   # from main after PR 3 merged
git add ios
git commit -m "A student's fees: every month with its state; the detail's fees row with Remind and Mark paid, which open on the Fees tab"
git push -u origin phase-5/student-fees
gh pr create --title "A student's fees and the detail's fees section live" --body "<the pr-shots table>"
```

Compare with P5-StudentFees and P5-StudentDetail-Fees; merge when green.

### Task 11: `PaymentsStore` and the QR decoder (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/PaymentsStore.swift`, `QRDecoder.swift`
- Test: `ios/TutorCentralKit/Tests/FeesTests/PaymentsStoreTests.swift`, `QRDecoderTests.swift`

**Interfaces:**
- Consumes: `CentreRepository` (the four payment writes), `QRImageStore`, `UPIID`, `UPIQR`, `SettingsStore.SaveState`'s shape (copied: `PaymentsStore.SaveState` with `idle`, `saving`, `saved`).
- Produces:

```swift
@MainActor @Observable public final class PaymentsStore {
    public enum SaveState: Equatable, Sendable { case idle, saving, saved }
    public var upiID: String { didSet }         // the field's text; clears upiError on change
    public private(set) var upiError: String?
    public var paymentLink: String { didSet }
    public private(set) var linkError: String?
    public private(set) var sendReceipts: Bool
    public private(set) var saveState: SaveState
    public var message: String?
    public private(set) var qrImage: Data?       // the kept QR, from the store
    public private(set) var fromQR: Bool         // "Read from the QR. Edit it if it is not right." while the id came from a QR this visit
    public var upiHelper: String                 // the helper line under the field
    public var onWorkspaceChanged: (Workspace) -> Void
    public func commitUPI() async                // normalises; refuses in words; writes when changed (confirmation cleared by the repository)
    public func commitLink() async               // trimmed; empty → nil; must start with https:// or http:// else "A link starts with https://."
    public func setReceipts(_ on: Bool) async
    /// A QR's payload (from Photos or the camera) and its image: the payee fills and saves the id; the image is kept on this iPhone.
    public func applyQR(payload: String, image: Data) async -> Bool
    public func removeQR()
    public init(workspace: Workspace, centres: any CentreRepository, qrImages: any QRImageStore)
}
/// A QR's payload read from an image on the device (Vision).
public enum QRDecoder { public static func payload(in image: CGImage) -> String? }
```

- [ ] **Step 1: Write the failing tests**

`Tests/FeesTests/PaymentsStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Fees

@MainActor struct PaymentsStoreTests {
    let centres = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
    let images = MemoryQRImageStore()

    func make(_ workspace: Workspace = FakeCentreRepository.meeraWorkspace) -> PaymentsStore {
        PaymentsStore(workspace: workspace, centres: centres, qrImages: images)
    }

    @Test func theFieldsStartFromTheCentre() {
        let store = make()
        #expect(store.upiID == "meera@okhdfcbank" && store.paymentLink == "" && store.sendReceipts && store.saveState == .idle)
        #expect(store.upiHelper == "Reminders tell parents to pay this id." && store.qrImage == nil)
        #expect(make(FakeCentreRepository.meeraWorkspaceWithoutUPI).upiID == "")
    }

    @Test func aChangedIDClearsTheConfirmation() async {
        let store = make()
        var changed: Workspace?
        store.onWorkspaceChanged = { changed = $0 }
        store.upiID = " Meera@YBL "
        await store.commitUPI()
        #expect(centres.upiUpdates == ["meera@ybl"] && store.upiID == "meera@ybl" && store.saveState == .saved)
        #expect(changed?.centre.payments.upiID == "meera@ybl" && changed?.centre.payments.upiConfirmedAt == nil)
        await store.commitUPI()
        #expect(centres.upiUpdates.count == 1, "unchanged: no write")
        store.upiID = ""
        await store.commitUPI()
        #expect(centres.upiUpdates == ["meera@ybl", nil] && changed?.centre.payments.upiID == nil)
    }

    @Test func aBadIDIsRefusedInWordsAndNotWritten() async {
        let store = make()
        store.upiID = "meera"
        await store.commitUPI()
        #expect(store.upiError == "A UPI id looks like name@bank." && centres.upiUpdates.isEmpty && store.saveState == .idle)
        store.upiID = "meera@ybl"
        #expect(store.upiError == nil, "typing clears the error")
    }

    @Test func theLinkAndReceiptsSave() async {
        let store = make()
        store.paymentLink = "pay.example/meera"
        await store.commitLink()
        #expect(store.linkError == "A link starts with https://." && centres.linkUpdates.isEmpty)
        store.paymentLink = " https://pay.example/meera "
        await store.commitLink()
        #expect(centres.linkUpdates == ["https://pay.example/meera"] && store.linkError == nil)
        await store.setReceipts(false)
        #expect(centres.receiptUpdates == [false] && !store.sendReceipts)
        centres.nextError = URLError(.notConnectedToInternet)
        await store.setReceipts(true)
        #expect(store.sendReceipts == false && store.message == "Couldn't save. Check your connection and try again.")
    }

    @Test func aQRFillsSavesAndKeepsItsImage() async {
        let store = make(FakeCentreRepository.meeraWorkspaceWithoutUPI)
        let image = Data([0x89, 0x50, 0x4E, 0x47])
        #expect(await store.applyQR(payload: "upi://pay?pa=Meera@OkHdfcBank&pn=Meera", image: image))
        #expect(store.upiID == "meera@okhdfcbank" && centres.upiUpdates == ["meera@okhdfcbank"] && store.fromQR)
        #expect(store.upiHelper == "Read from the QR. Edit it if it is not right." && store.qrImage == image)
        #expect(images.images[FakeCentreRepository.meeraWorkspace.centre.id] == image)
        store.removeQR()
        #expect(store.qrImage == nil && images.images.isEmpty && store.upiID == "meera@okhdfcbank", "Remove keeps the id")
    }

    @Test func aBadQRIsRefusedInWords() async {
        let store = make()
        #expect(await store.applyQR(payload: "https://example.com/pay", image: Data()) == false)
        #expect(store.message == "That QR is not a UPI QR." && centres.upiUpdates.isEmpty && store.qrImage == nil)
    }
}
```

`Tests/FeesTests/QRDecoderTests.swift` (a QR made with Core Image, read back with Vision; the simulator renders both):

```swift
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Testing
@testable import Fees

struct QRDecoderTests {
    static func qr(_ text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }

    @Test func readsAUPIQRAndRefusesAPlainPicture() throws {
        let payload = "upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair&cu=INR"
        let image = try #require(Self.qr(payload))
        #expect(QRDecoder.payload(in: image) == payload)
        let blank = try #require(CIContext().createCGImage(CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200)), from: CGRect(x: 0, y: 0, width: 200, height: 200)))
        #expect(QRDecoder.payload(in: blank) == nil)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `PaymentsStore`, `QRDecoder` not found.

- [ ] **Step 3: Implement**

`PaymentsStore`: the Settings pattern (`save(_:apply:)` with `saveState`); `commitUPI` normalises with `UPIID.normalised` (an empty field means nil: the id is cleared), sets `upiError` otherwise, writes through `centres.updateUPI(id:upiID:)` when the value differs from the workspace's, applies `payments.upiID` and `payments.upiConfirmedAt = nil`, calls `onWorkspaceChanged`; `commitLink` trims, requires the `https://` or `http://` prefix; `setReceipts` writes and applies, restoring the old value with the message on failure; `applyQR` runs `UPIQR.upiID(in:)` (nil → `message = UPIQR.notUPIMessage`, false), sets `upiID`, `fromQR = true`, awaits `commitUPI()` (a failed write leaves the field filled and says so), then `try? qrImages.save(image, for: centre)` and `qrImage = image`; `removeQR` removes the file and clears `qrImage` and `fromQR`; `qrImage` is read from the store in `init`.

`QRDecoder.swift` (imports Vision): a `VNDetectBarcodesRequest` with `symbologies = [.qr]` run by a `VNImageRequestHandler(cgImage:)`; the first result's `payloadStringValue`.

- [ ] **Step 4: Run, format, commit**

```bash
cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios
git checkout main && git pull && git checkout -b phase-5/payments
git add ios
git commit -m "PaymentsStore: the UPI id, the link and receipts saved as you go, a QR's payee filled and its image kept; the QR decoder"
```

### Task 12: Parent payments on screen: the fields, the QR from Photos and the camera; Settings' row; the launch states (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/PaymentsView.swift`, `QRScannerView.swift`
- Modify: `ios/App/Info.plist` (`NSCameraUsageDescription`: "To read the QR of your UPI app and fill in your UPI id."), `Features/Settings/SettingsView.swift` (the later card becomes "Payments and later builds": a live `SettingRow(symbol: "indianrupeesign", label: "Parent payments", trailing: { Text("UPI") … }, action: openPayments)` over the Phase 7 later row; `SettingsView` gains `openPayments: () -> Void`), `AppShell/RootView.swift` (`settingsView` passes `{ shell.tabs.push(.payments) }`), `RootView+Fees.swift` (`paymentsView`), `TabsView.swift` (`.payments` route), `LaterView.swift` (`payments` removed), `LaunchState.swift` (`paymentsEmpty = "payments-empty"`, `payments`, `paymentsQR = "payments-qr"`), `RootView+LaunchStates.swift` (the three push `.payments` on the More tab from Settings: `initialRoutes` `[.settings, .payments]`), `Fixtures.swift` (`payments-qr` seeds `MemoryQRImageStore` with a PNG of a QR made as the test makes it, `Fixtures.sampleQR()`; `payments-empty` uses `meeraWorkspaceWithoutUPI`)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (+ `thePaymentsStatesOpenFromSettings`)

**Interfaces:**

```swift
public enum PaymentsBoardState: Hashable, Sendable { case empty }   // the field shows focus without the keyboard
public struct PaymentsView: View { public init(store: PaymentsStore, boardState: PaymentsBoardState? = nil, onWorkspaceChanged: @escaping (Workspace) -> Void, onMessage: @escaping (String) -> Void) }
/// The camera for a UPI QR: VisionKit's DataScannerViewController behind a UIViewControllerRepresentable, because SwiftUI has no barcode camera (D8). `isAvailable` is false on the simulator.
public struct QRScannerView: UIViewControllerRepresentable { public init(onPayload: @escaping (String) -> Void); public static var isAvailable: Bool }
```

- [ ] **Step 1: Write the failing test**

```swift
    @MainActor @Test func thePaymentsStatesOpenFromSettings() {
        for state in [LaunchState.paymentsEmpty, .payments, .paymentsQR] {
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.settings, .payments])
        }
        #expect(Fixtures.workspace(for: .paymentsEmpty).centre.payments.upiID == nil && Fixtures.workspace(for: .payments).centre.payments.upiID == "meera@okhdfcbank")
        #expect(Fixtures.dependencies(for: .paymentsQR).qrImages.image(for: Fixtures.meeraWorkspace.centre.id) != nil)
        #expect(Fixtures.dependencies(for: .payments).qrImages.image(for: Fixtures.meeraWorkspace.centre.id) == nil)
    }
```

- [ ] **Step 2: Run to see it fail**

Run: `bun check --only=ios`
Expected: FAIL, the cases not found.

- [ ] **Step 3: Implement**

`PaymentsView` (to P5-Payments-Empty, -Filled, -QR): its store in `@State`; the nav row (Back, "Parent payments"); "UPI" with the Saved mark on the right (Settings' `saveMark`, moved to DesignSystem as `SaveMark(state:)` so both screens draw one); a `Card` (padding `rowPaddingHorizontal`, `VStack(spacing: Tokens.cardPaddingCompact)`): `TextWell(label: "UPI id", text: $store.upiID, placeholder: "yourname@bank", helper: store.upiHelper, error: store.upiError, numeric: true, keyboard: .emailAddress, capitalisation: .never, showsFocus: boardState == .empty) { Task { await store.commitUPI() } }` (`numeric` gives the 600 weight the board draws; the keyboard `.emailAddress` has the @), then `QRRow(image:, title: "QR from your UPI app", line: "Kept on this iPhone to show a parent.", remove: store.removeQR)` when `store.qrImage` decodes to a `UIImage`, then `HStack(spacing: Tokens.tileGap)` of `Button { scanning = true } label: { Label("Scan a QR", systemImage: "camera") }.buttonStyle(.secondary())` and `PhotosPicker(selection: $picked, matching: .images) { Label("From Photos", systemImage: "photo.on.rectangle") }.buttonStyle(.secondary())` with `.environment(\.buttonIconSize, Tokens.iconSmall)`; "Payment link" over a `Card` with `TextWell(label: "Payment link", text: $store.paymentLink, placeholder: "https://", optional: true, helper: "Added to reminders when set, for parents who pay by a link.", error: store.linkError, keyboard: .URL, capitalisation: .never) { Task { await store.commitLink() } }`; "Receipts" over a `Card` with a row: the two-line block ("Offer a receipt after Mark paid" `body`, "A WhatsApp message with the amount, the date and how it was paid." `footnote` `text2`) and `Toggle("", isOn: Binding(get: { store.sendReceipts }, set: { on in Task { await store.setReceipts(on) } })).labelsHidden().tint(Tokens.accent.color)`, padding `rowPaddingVertical` × `rowPaddingHorizontal`. `.toolbar(.hidden, for: .navigationBar)`, `.toolbar(.hidden, for: .tabBar)`, `.scrollDismissesKeyboard(.interactively)`, the success haptic on `.saved`, the error haptic and `onMessage` on `message`.
  - Photos: `.onChange(of: picked) { _, item in Task { guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data)?.cgImage else { onMessage("Couldn't read that picture."); return }; guard let payload = QRDecoder.payload(in: image) else { onMessage("No QR found in that picture."); return }; _ = await store.applyQR(payload: payload, image: data); picked = nil } }`.
  - Camera: `.fullScreenCover(isPresented: $scanning) { QRScannerView { payload in scanning = false; Task { _ = await store.applyQR(payload: payload, image: Data()) } } }` (a scanned QR keeps no image: the camera frame is not the QR; the QR row then does not show, and the helper says "Read from the QR"); when `!QRScannerView.isAvailable` the Scan button calls `onMessage("No camera on this device.")` instead (the simulator).
  - `QRScannerView`: `DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced, isHighlightingEnabled: true)`, started in `updateUIViewController`, its delegate's `didAdd` handing the first barcode's `payloadStringValue` to `onPayload`; `isAvailable = DataScannerViewController.isSupported && DataScannerViewController.isAvailable`; the file's header comment names D8 and the reason.

`SettingsView`: `later` becomes `payments`: `SectionHeader("Payments and later builds")` over a `Card` with `SettingRow(symbol: "indianrupeesign", label: "Parent payments", trailing: { Text("UPI").typeStyle(Tokens.body).foregroundStyle(Tokens.text2.color) }, action: openPayments).rowDivider()` and `LaterRow(symbol: "bell", label: "Reminders and haptics", phase: "Phase 7")` (the card no longer dims as a whole; the later row dims itself).

`Fixtures.sampleQR()`: the QR of `upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair` made with `CIFilter.qrCodeGenerator` scaled ×8, as PNG data (`UIImage(cgImage:).pngData()`), so `payments-qr` draws a real QR.

- [ ] **Step 4: Prove the QR from Photos in the simulator**

Build (`bun check`), then put the same QR into the simulator's Photos and pick it through the screen (the runbook's waits): `python3`-free: write `Fixtures.sampleQR()` to a file through a throwaway test, or make one with `qrencode` if installed, else screenshot `payments-qr`'s thumbnail at full size (`bun shots payments-qr`, crop the thumbnail with `sips`); then `xcrun simctl addmedia booted qr.png`; in the app (signed in as Meera against the local stack, Settings → Parent payments) tap From Photos, pick it, see the id fill and `select upi_id, upi_confirmed_at from centres` show it unconfirmed. This is also Task 15's hand run; do it here first so the PR's description can say the path works end to end.

- [ ] **Step 5: Run, photograph, commit; open PR 5**

```bash
bun check
for s in payments-empty payments payments-qr settings; do bun shots $s; done
bun pr-shots phase-5-payments .shots/*/*.png
git add ios
git commit -m "Parent payments: the UPI id, Scan a QR and From Photos, the payment link, receipts; Settings' row live"
git push -u origin phase-5/payments
gh pr create --title "Parent payments: the UPI id, the QR from Photos and the camera, the link, receipts; Settings' row" --body "<the pr-shots table> The camera path cannot run in the simulator: proven on the owner's iPhone after the TestFlight build (Task 15)."
```

Compare with P5-Payments-* and P5-Settings; merge when green.

### Task 13: `ReportsStore` and the CSV files (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/ReportsStore.swift`
- Test: `ios/TutorCentralKit/Tests/FeesTests/ReportsStoreTests.swift`

**Interfaces:**
- Consumes: `FeesRepository.invoices(centre:month:)`, `AttendanceRepository.sessions(centre:month:)`, `MessageLogRepository.feeLogs(centre:month:)`, `AttendanceStats.forStudent(_:in:)` (Phase 4), `FeesCSV`, `AttendanceCSV`, `FeeTotals`.
- Produces:

```swift
@MainActor @Observable public final class ReportsStore {
    public enum Segment: Hashable, Sendable, CaseIterable { case fees, attendance
        public var title: String }   // "Fees", "Attendance"
    public struct FeeLine: Hashable, Sendable, Identifiable { public let id: UUID; public let name: String; public let className: String; public let amount: String; public let state: FeeState }
    public struct AttendanceLine: Hashable, Sendable, Identifiable { public let id: UUID; public let name: String; public let present: Int?; public let absent: Int?; public let percent: String? }
    public struct AttendanceHero: Hashable, Sendable { public let percent: String; public let fraction: Double; public let line: String }   // "79%", "19 of 24 marks · 5 classes marked"
    public struct Export: Hashable, Sendable { public let fileName: String; public let text: String }
    public private(set) var month: Period; public var segment: Segment
    public private(set) var loading: Bool; public private(set) var error: String?
    public struct FeesLines: Hashable, Sendable { public let outstandingLine: String; public let collectedLine: String }   // "4 of 10 due", "6 of 10 paid"
    public var monthTitle: String; public var totals: FeeTotals; public var feesLines: FeesLines
    public var feeLines: [FeeLine]; public var attendanceHero: AttendanceHero?; public var attendanceLines: [AttendanceLine]
    public var isEmpty: Bool          // no invoices and no sessions, loaded, no error
    public var studentsTitle: String  // "10 students"
    public func load() async; public func previous() async; public func next() async; public func retryLast() async
    public func export(_ segment: Segment) -> Export
    /// The CSV written to the temporary directory for ShareLink; nil when it cannot be written (a toast).
    public func exportFile(_ segment: Segment) -> URL?
    public init(workspace: Workspace, register: any Register, fees: any FeesRepository, attendance: any AttendanceRepository, messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Fees

@MainActor struct ReportsStoreTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)

    func make() async -> ReportsStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = ReportsStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees, attendance: attendance,
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed), now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func octobersFeesReadAsTheBoard() async {
        let store = await make()
        #expect(store.month == Period(year: 2026, month: 10) && store.segment == .fees && !store.isEmpty && store.studentsTitle == "10 students")
        #expect(store.totals.outstanding == Money(rupees: 4000) && store.feesLines.outstandingLine == "4 of 10 due" && store.feesLines.collectedLine == "6 of 10 paid")
        #expect(store.feeLines.map(\.name) == FakeStudentsRepository.seed.map(\.name), "by name, every student with a fee")
        #expect(store.feeLines[3].className == "Class 8 Science" && store.feeLines[3].state == .due && store.feeLines[9].className == "")
    }

    @Test func octobersAttendanceCountsMarksByStudent() async throws {
        let store = await make()
        store.segment = .attendance
        let hemanth = try #require(store.attendanceLines.first { $0.name == "Hemanth Reddy" })
        #expect(hemanth.present == 1 && hemanth.absent == 2 && hemanth.percent == "33%")
        let sahil = try #require(store.attendanceLines.first { $0.name == "Sahil Verma" })
        #expect(sahil.present == nil && sahil.percent == nil, "no class, nothing marked")
        let hero = try #require(store.attendanceHero)
        let marks = FakeAttendanceRepository.seedWithToday.filter { $0.date.period == store.month }.flatMap { $0.marks.values }
        let present = marks.filter { $0 == .present }.count
        #expect(hero.line == "\(present) of \(marks.count) marks · \(FakeAttendanceRepository.seedWithToday.filter { $0.date.period == store.month }.count) classes marked")
        #expect(hero.percent == "\(Int((Double(present) * 100 / Double(marks.count)).rounded()))%")
    }

    @Test func theExportsHaveTheBoardsColumns() async throws {
        let store = await make()
        let fees = store.export(.fees)
        #expect(fees.fileName == "fees-2026-10.csv" && fees.text.hasPrefix("\u{FEFF}Student,Class,Amount,Status,Paid on,Paid by,Reminded on\r\n"))
        #expect(fees.text.contains("Dev Kumar,Class 8 Science,1000,Due,,,2026-10-06\r\n") && fees.text.contains("Akshita Rao,Class 10 Maths,1200,Paid,2026-10-04,UPI,\r\n"))
        let attendance = store.export(.attendance)
        #expect(attendance.fileName == "attendance-2026-10.csv" && attendance.text.contains("Hemanth Reddy,Class 10 Maths,1,2,33\r\n") && attendance.text.contains("Sahil Verma,,0,0,\r\n"))
        let url = try #require(store.exportFile(.fees))
        #expect(url.lastPathComponent == "fees-2026-10.csv" && (try String(contentsOf: url, encoding: .utf8)) == fees.text)
    }

    @Test func aMonthWithNothingIsEmptyAndAFailedReadIsNot() async {
        let store = await make()
        await store.next()
        #expect(store.month == Period(year: 2026, month: 11) && store.isEmpty && store.feeLines.isEmpty && store.attendanceHero == nil)
        fees.nextError = URLError(.notConnectedToInternet)
        await store.previous()
        #expect(store.error == "Couldn't load the report. Check your connection and try again." && !store.isEmpty)
        await store.retryLast()
        #expect(store.error == nil && store.feeLines.count == 10)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `ReportsStore` not found.

- [ ] **Step 3: Implement**

`ReportsStore`: a load generation over three reads (`async let`); `feeLines` from the month's invoices by name (`register.student`, the class through `register.classroom`); `attendanceLines` for every active student: `AttendanceStats.forStudent(id, in: sessions)` (`present`, `total`; nil when `total == 0`), the percent as History's; `attendanceHero` from every mark of the month (nil when there are no sessions); `FeesLines` struct (`outstandingLine = "\(outstandingCount) of \(total) due"`, `collectedLine = totals.collectedLine`); `export(_:)` builds `FeesCSVRow`s (the reminded day from the latest reminder log about the month per student) and `AttendanceCSVRow`s; `exportFile(_:)` writes to `FileManager.default.temporaryDirectory.appending(path: fileName)` with `.utf8` (nil on a throw).

- [ ] **Step 4: Run, format, commit**

```bash
cd ios && swiftformat . && cd .. && bun check --only=format,lint,ios
git checkout main && git pull && git checkout -b phase-5/reports
git add ios
git commit -m "ReportsStore: a month's fees and attendance by student, the two CSVs written for sharing"
```

### Task 14: Reports on screen: the month, Fees | Attendance, Share as CSV; More's row; the launch states (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Fees/ReportsView.swift`, `ExportSheet.swift`
- Modify: `AppShell/MoreView.swift` (`SettingRow(symbol: "chart.bar", label: "Reports", action: { open(.reports) })` replaces the later row), `TabsView.swift`, `TabsState.swift` (`Route.reports`), `RootView+Fees.swift` (`reportsView`), `LaunchState.swift` (`reports`, `reportsAttendance = "reports-attendance"`, `reportsExport = "reports-export"`, `reportsEmpty = "reports-empty"`), `RootView+LaunchStates.swift` (`.more`, `[.reports]`, `reportsBoardState`), `Fixtures.swift` (`reports-empty` opens November: `ReportsBoardState.november`)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (+ `theReportsStatesOpenFromMore`)

**Interfaces:**

```swift
public enum ReportsBoardState: Hashable, Sendable { case attendance, export, november }
public struct ReportsView: View { public init(store: ReportsStore, boardState: ReportsBoardState? = nil, onMessage: @escaping (String) -> Void) }
```

- [ ] **Step 1: Write the failing test**

```swift
    @MainActor @Test func theReportsStatesOpenFromMore() {
        for state in [LaunchState.reports, .reportsAttendance, .reportsExport, .reportsEmpty] {
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.reports])
        }
        #expect(RootView.reportsBoardState(.reportsExport) == .export && RootView.reportsBoardState(.reportsEmpty) == .november && RootView.reportsBoardState(.reports) == nil)
    }
```

- [ ] **Step 2: Run to see it fail**

Run: `bun check --only=ios`
Expected: FAIL, the cases not found.

- [ ] **Step 3: Implement**

`ReportsView` (to P5-Reports-Fees dark and light, -Attendance, -Empty): its store in `@State`; the nav row (Back, "Reports", a quiet Share on the right opening the export sheet); `MonthHeader`; `Segmented(options: ReportsStore.Segment.allCases.map { ($0, $0.title) }, selection: $store.segment)`; the empty month: `Card { EmptyRow(symbol: "chart.bar", title: "Nothing for \(month.monthName) yet", line: "The month's fees and attendance appear here once there are some.") }`; Fees: `MoneyPair(outstanding:, outstandingLine: store.feesLines.outstandingLine, collected:, collectedLine:)`, `SectionHeader(store.studentsTitle)` over a `Card` of `ReportFeeRow(name:className:amount:chip:)` (the same chip rule as the Fees tab; a `FeeState.chip` helper in Fees, `FeeChips.kind(for:)`, used by both views); Attendance: `PercentHero(eyebrow: month.title, percent: hero.percent, fraction: hero.fraction, line: hero.line)` and a `Card` of `ReportAttendanceRow(name:present:absent:percent:)`; the error line and Retry as the Fees tab; `.toolbar(.hidden, for: .tabBar)`.

`ExportSheet(store:, segment:, close:)` (P5-Reports-Export) at `.fraction(0.5)` and `.large`: `SheetHeader(title: "Share as CSV")`; the line "A spreadsheet of \(month.title), one row per student. Opens in Numbers, Files or anywhere a CSV goes." `subhead` `text2`; two `ChoiceCard`s ("Fees", "fees-2026-10.csv · Student, class, amount, status, paid on, paid by, reminded on"; "Attendance", "attendance-2026-10.csv · Student, class, present, absent, percentage") with the chosen one selected (the segment on open); `Spacer`; the primary: `ShareLink(item: url, preview: SharePreview(fileName)) { Label("Share \(fileName)", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }.buttonStyle(.primary(.sheet))` where `url = store.exportFile(chosen)` (nil → the button disabled and `onMessage("Couldn't write the file.")`). The system share sheet follows (not drawn).

`MoreView`: Reports live in Organise (P5-More). `Fixtures`: `reports-empty` keeps `FakeFeesRepository.octoberOnly` and the board state opens November.

- [ ] **Step 4: Run, photograph, commit; open PR 6**

```bash
bun check
for s in reports reports-attendance reports-export reports-empty more; do bun shots $s; done
bun pr-shots phase-5-reports .shots/*/*.png
git add ios
git commit -m "Reports: the month's fees and attendance by student, Share as CSV through the share sheet; More's row live"
git push -u origin phase-5/reports
gh pr create --title "Reports: the month's fees and attendance, share as CSV; More's row" --body "<the pr-shots table>"
```

Compare with P5-Reports-* and P5-More; merge when green.

### Task 15: The hand runs, TestFlight, the owner's camera check; the documents (main)

- [ ] **Step 1: Nothing to deploy.** No migration and no API change in this phase; `gh workflow run deploy` is not needed (the TestFlight lane checks for pending migrations itself and finds none). `git checkout main && git pull`.
- [ ] **Step 2: The hand runs (D32),** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed (the local seed is relative to the real day: "this month" is the real month), signed in as Meera, every write confirmed in the database, every screenshot kept in `.shots/run/` and attached to the phase's issue (open one: "Phase 5 hand run"):

| Run | Through the screens | Confirm |
|---|---|---|
| The month | Fees tab: the real month's ten fees, six paid; Due, Paid, All; the next month (empty, Generate) and back | reads only |
| Generate | Next month → Generate <month>'s fees → the sheet says 10 → Create 10 fees; the toast; the ten rows; Generate again → "Everyone has a fee", Nothing to create disabled | `select count(*), sum(amount) from fee_invoices where period = '<next month>-01'` → 10, 11300; twice stays 10 |
| Mark paid, the receipt | Back to this month, Due: Dev Kumar → Mark paid, UPI, today → the row paid, the hero rolls, the receipt sheet → Open WhatsApp (Safari or nothing in the simulator; the sheet closes) | `select status, paid_at, paid_method from fee_invoices f join students s on s.id = f.student_id where s.name = 'Dev Kumar' and period = date_trunc('month', current_date)` → paid, today, upi; `select kind, about_date from message_log order by opened_at desc limit 1` → receipt, the month |
| Undo | Hemanth Reddy → Mark paid, Cash → the toast → Undo within 8 s → the row due again | Hemanth's row: due, paid_at null, paid_method null |
| An earlier day | Nikhil Das → Mark paid, Other, the date picker → the 2nd of the month | Nikhil's `paid_at::date` = the 2nd, `paid_method` other |
| Waive | Sahil Verma → Mark paid → Waive this fee instead → "Joined mid-month" → Waive ₹800 | Sahil's row: waived, `waived_reason`; Outstanding ₹1,200 |
| Remind | Hemanth → Remind → the message → Open WhatsApp; the row reads "Reminded today" | `message_log`: reminder, student Hemanth, about_date the month's first |
| The payee | Fees shows "Parents are told to pay meera@okhdfcbank" (the seed is unconfirmed) → That's right → the card goes | `select upi_confirmed_at from centres` set |
| Parent payments | More → Settings → Parent payments: UPI id → "meera@ybl", leave the field (Saved); Fees shows the payee card again; back: payment link "https://pay.example/meera"; receipts off; receipts on | `select upi_id, upi_confirmed_at, payment_link, send_receipts from centres` after each |
| The QR from Photos | `xcrun simctl addmedia booted qr.png` (Task 12's QR: `upi://pay?pa=meera@okhdfcbank`); From Photos → pick it → the id fills and saves, the QR row shows; Remove | `upi_id` = meera@okhdfcbank, `upi_confirmed_at` null; the file under the app container's Application Support gone after Remove (`xcrun simctl get_app_container booted in.tutorcentral.app data`) |
| Scan a QR | Tap it: "No camera on this device." (the simulator) | the owner's step below |
| A student's fees | Students → Hemanth Reddy: the fees row reads Due · Reminded today with Remind and Mark paid → Mark paid → the Fees tab opens with the sheet → Cancel; See all → Hemanth's fees → Remind → the Fees tab with the reminder sheet | reads only (the writes are the runs above) |
| Reports | More → Reports: Fees, Attendance, the previous month; Share → Share fees-<month>.csv → Save to Files → On My iPhone → Save; then copy it out of the simulator: `find ~/Library/Developer/CoreSimulator/Devices -name 'fees-*.csv' -mmin -10` and `open -a Numbers <file>`: ten rows, seven columns, amounts as digits, names whole | the file opens in Numbers with the expected columns (the phase's acceptance) |
| Today | The Due tile → the Fees tab at Due | reads only |
| Links | `xcrun simctl openurl booted "tutorcentral://fees?month=2026-09"` → the Fees tab at September 2026 (empty: Generate) | reads only |

- [ ] **Step 3: TestFlight.** `gh workflow run testflight`; the build number from the run; the owner installs it.
- [ ] **Step 4: The owner's step (one message, one step):** on the iPhone, Settings → Parent payments → Scan a QR, pointed at the QR shown by a real UPI app (PhonePe, Google Pay or the bank's app, the "receive money" QR): the id fills; the owner says whether it is right. Record the answer in the phase file's "As built" (the acceptance "A QR from a real UPI app fills the id correctly").
- [ ] **Step 5: Documents (D12), one commit to `main`:** `plan/phase-05-fees-and-reports.md` "As built" (the PR table, acceptance line by line, deviations and why, what remains); `plan/README.md` (Phase 5 done; any decision the build numbered); `plan/STATE.md`; `plan/ui-polish.md` (U12 to Done with PR 3's number; anything seen in passing added to Open); `docs/design/components.md` and `information-architecture.md` where the build corrected a board's words; `ios/CLAUDE.md` rules learned; `plan/sessions/011/record.md` and `owner-messages.md`; then ask for a reviewer pass on the six merged pull requests with `superpowers:requesting-code-review` and record its outcome.

---

## Self-review

- **Spec coverage.** Phase file scope 1 (the month view: navigator, outstanding and collected, All, Due, Paid, overdue marked, each row's student, amount, status and paid-by, the empty state before generation): Tasks 1, 8, 9. Scope 2 (generate through `generate_fees`, idempotent; the sheet says how many before it runs; the fee rule): Tasks 1 (`GeneratePreview`), 4, 5, 8, 9. Scope 3 (mark paid with method and date, undo within the toast, waive with a reason; partial payments out): Tasks 4, 5, 8, 9. Scope 4 (remind: the WhatsApp link naming the student, month, amount and UPI id or link; copied to the clipboard; logged with the time): Tasks 2, 6, 8, 9. Scope 5 (the receipt after mark paid when receipts are on; logged): Tasks 2, 8, 9. Scope 6 (UPI id, payment link, receipts switch; the QR from the camera or Photos decoded on the device to fill the id; remove; the payee reminder on Fees until confirmed once): Tasks 2, 6, 8, 9, 11, 12. Scope 7 (the student's ledger with mark paid and remind in place): Task 10. Scope 8 (reports by month: fees collected and outstanding per student, attendance per student, CSV through the share sheet): Tasks 3, 13, 14. Scope 9 (the rules, tested): Tasks 1 to 3. Acceptance: pictures in PRs 3 to 6; generating twice creates nothing and says so (Tasks 4, 8, 15); remind opens WhatsApp with the right number and text and logs (Tasks 2, 8, 15); a QR from a real UPI app fills the id (Task 11's decoder, Task 12's Photos run, Task 15's owner step); the CSV opens in Numbers with the expected columns (Task 3, Task 15's Reports run); domain tests cover item 9. Inventory rows: all placed (Global Constraints, last line). U12: Task 9. D32: Task 15's table names every write path.
- **Placeholders.** The views (Tasks 9, 10, 12, 14) are given as their pieces with the exact components, tokens, copy and wiring, as Phase 4's plan gave its screens; every number is a token or a named anatomy constant and every word is on a board or in `components.md`. The decoding fixtures are pasted from the stack's answers. No "TBD", no "handle edge cases".
- **Type consistency.** `FeeInvoice` (Task 1) is what `InvoiceRow` (Task 5), `FeesStore.Row` (Task 8), `StudentFeesStore.Row` (Task 10) and `ReportsStore` (Task 13) carry. `FeeLedger.rows(_:filter:current:name:)` and `FeeTotals(invoices:)` (Task 1) serve Tasks 8, 10 and 13. `GeneratePreview.make(students:classes:invoices:month:)` (Task 1) is `FeesStore.generatePreview` (Task 8) and `GenerateSheet`'s input (Task 9). `FeeMessage(kind:parentName:studentName:month:amount:upiID:paymentLink:tutorName:centreName:)` (Task 2) is built in `FeesStore+Messages` (Task 8). `UPIID.normalised` and `UPIQR.upiID(in:)` (Task 2) are what `PaymentsStore` calls (Task 11); `QRDecoder.payload(in:)` (Task 11) is what `PaymentsView` calls (Task 12). `FeesRepository`'s seven methods (Task 5) are the ones `FeesStore`, `StudentFeesStore` and `ReportsStore` call. `MessageLogRepository.feeLogs(centre:month:)`, `feeLogs(centre:student:)`, `logFee(centre:studentID:kind:month:)` (Task 6) are used in Tasks 8, 10 and 13. `CentreRepository.updateUPI`, `updatePaymentLink`, `updateSendReceipts`, `confirmUPI` (Task 6) are used by Tasks 8 and 11. `FeeInvoice.paidAt(for:today:now:calendar:)` (Task 1) is what `FeesStore.markPaid` passes to the repository (Task 8). `FeeAction` (Task 1) is what `StudentsActions.openFeeAction` passes (Task 10). `Fixtures.workspace(for:)` (Task 6) is what Task 9's and Task 12's tests read. `LaunchState` raw values match `information-architecture.md`'s Phase 5 table (24 states; `more` and `settings` keep their names). `ButtonSize.row` (existing) is what `FeeButtons` and `PayeeCard` use (Task 7). `SaveMark(state:)` moves to DesignSystem in Task 12 and Settings uses it from then.
- **Review Focus.** 1 → Task 1 `overdueIsAPastMonthStillDue`, `theBannerSumsEarlierMonthsAndNamesTheLatest`. 2 → Task 8 `markingPaidWaitsForTheServerAndOffersUndo`, `undoReversesTheOneFeeNamed`, `aFailedMarkPaidKeepsTheRowDueWithRetry`, `aFailedUndoLeavesTheFeePaid`; Task 4 `mark paid, undo and waive are plain updates the checks allow`. 3 → Task 1 `countsOnlyActiveStudentsWithoutAFee`, `amountsFollowTheFeeRule`, `nothingToCreateSaysSo`; Task 8 `generatingReadsTheMonthAgainAndSaysHowMany`, `nothingToCreateDisablesTheButton`. 4 → Task 2 `theReminderNamesEverything`, `withoutAPayeeTheReminderStillReads`, `theReceiptNamesTheMethodAndDay`; Task 8 `remindingLogsOnceAndReadsReminded`, `aReceiptIsOfferedOnlyWhenOnAndThereIsANumber`, `aStudentWithoutANumberShowsTheTextWithoutALink`. 5 → Task 2 `typedIDsAreNormalisedAndRefusedInWords`, `aQRPayloadGivesItsPayeeOrNothing`; Task 11 `aChangedIDClearsTheConfirmation`, `aBadIDIsRefusedInWordsAndNotWritten`, `aBadQRIsRefusedInWords`; Task 3 `namesWithCommasAndQuotesAreEscaped`.
- **The polish list.** U9 (a failure toast behind the keyboard on sheets) touches the waive sheet and Parent payments: offered to the owner with this plan, not taken; the build session takes it only if the owner says so, as its own pull request after a board.
