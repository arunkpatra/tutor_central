# Session 11 (2026-10-08): the Phase 5 build

Model: Claude Opus 5.5 (D17), from `resume/010-phase-5-build.md`, executing `plan/phase-05-plan.md` with
`superpowers:executing-plans` (inline, one ledger, one fresh reviewer at the end). Outcome: Phase 5 built in PRs #45
to #49, #51 and #52 (the hand run's and the review's fixes); the D32 hand run on issue #50; build 0.1.0 (8) on
TestFlight; the owner's camera check: "installed the build and tested on iphone. test ok." (the owner).

## What was done, in order

1. Read the rules, the state, the decisions, the phase file and plan, the design documents and the runbook. Reality
   matched `STATE.md`; `bun check` green; the local stack up. Rendered the 27 P5 boards with headless Chrome into the
   scratchpad and an outline script over their HTML, to read every value before building a part.
2. PR 1 (#45), Domain: the fee and its state, the ledger and totals, the overdue summary, the generate preview, the
   payment settings, the reminder and receipt texts, the UPI id rule and the QR payee, the two CSVs.
3. PR 2 (#46), Data and the database tests: the fees repository, fee logs on `message_log`, the centre's payment
   columns, the QR image store, the fakes; every read decoded from the plan's pasted answers; every write run in Swift
   against the local stack in a throwaway test (deleted), confirmed in psql.
4. PR 3 (#47), the Fees tab: the DesignSystem parts, `FeesStore` and the screens, the fees link, Today's Due tile, 13
   launch states, every state photographed in both appearances beside its board (side-by-side sheets made with PIL).
5. PR 4 (#48), a student's fees and the detail's fee row. The board drew a waived month bare; the owner chose "Mark
   paid only" (asked once).
6. PR 5 (#49), Parent payments and Settings' row; From Photos proven in the simulator with a Core Image UPI QR added by
   `simctl addmedia`.
7. PR 6 (#51), Reports and More's row.
8. The D32 hand run (issue #50) found two bugs, fixed with tests on their own branch.
9. The final review (a fresh reviewer on the whole range): no Critical, four Important, one re-graded up; fixed with
   tests in the same branch, and the changed write run again in the simulator.
10. TestFlight, the owner's camera check, the documents.

## Why things are as they are

Every ruling below was taken during the build and written in the build's ledger; each says what it costs if wrong.

- **The plan's tests, corrected where they could not run:** `FeeInvoiceTests` had its tests inside the clock enum while
  calling `Self.invoice` (moved into the struct); `order('kind')` sorts the enum by declaration, reminder before receipt
  (the RLS expectation corrected); the month-move race used `async let` that ran after the delay was cleared (a `Task`
  given 20 ms instead); `nothingToCreate` set the error before the store's first read consumed it (set after); the CSV
  file test read back with `String(contentsOf:)`, which drops the BOM (bytes compared, the BOM asserted). Cost if
  wrong: none.
- **The lint's shapes** (strict SwiftLint): no one-letter names, `!groups.isEmpty` for `count > 0`, a receipt line
  split under 120 columns, fixtures' long lines joined with `\` inside the literal, `RootView`'s Today and Settings
  wiring moved to `RootView+Today.swift` (type body), TabsView's destinations split by tab and `initialRoutes`' new
  cases in a helper (complexity), the Fees store tests split into a second file (type body). Cost if wrong: none.
- **Boards over the plan:** the on-sheet row's label is 15 600, not subhead 400 (P5-Generate); `ChoiceCard`'s line
  wraps (P5-Reports-Export); a past month's Outstanding reads "1 parent, overdue" (P5-Fees-Overdue); the sheet heights
  are the boards' tops, nudged for the floating sheet's inset; the fee row's name is not a link (the boards; the
  plan's decisions table agreed, `information-architecture.md` did not and is corrected).
- **The money pair's colours:** the P5-Fees boards render the numbers white because of a CSS typo in their source
  (`tabular-nums color: var(--due)`, no semicolon); the source, the Kit board and `components.md` name `due` and `ok`;
  built coloured. Cost if wrong: two colours.
- **One fee row, one money pair:** the step 0.2 Kit `FeeRow` was replaced by the settled one and the Kit's preview
  moved to it and to `MoneyPair`. Cost if wrong: the Kit's preview shows a plain tick.
- **The toast on fee sheets** sits above the footer button: the 8 s Undo toast after Mark paid covered the receipt's
  Open WhatsApp. Other sheets unchanged (U9 stays the owner's). Cost if wrong: a toast position.
- **Store shapes:** `receipt(for:)` needs only a paid fee and Mark paid decides whether to open it (receipts on and a
  number); a successful Undo clears its toast; `FeesActions` has Payments only; the stores' fields are `public
  internal(set)` for their extension files; `onFeesChanged` refreshes the register after any fee write; a failed month
  move clears the old month's rows. Cost if wrong: none.
- **Data:** `MemoryQRImageStore` is a class over a `Mutex` (the protocol is synchronous and `Sendable`); `CentreRow`
  decodes with `PostgRESTDecoder` (proven live). Cost if wrong: none.
- **A waived month on a student's fees offers Mark paid alone** (D34), the owner's answer when asked; the Fees tab's
  Mark paid sheet hides "Waive this fee instead" for a waived fee.
- **Shared parts to DesignSystem:** `BackRow` (Fees cannot import Attendance, rule 4) and `SaveMark`.
- **Parent payments before PR 5** was the later card (`.later(.payments)`), because a new route put TabsView over the
  lint's complexity; PR 4 split the destinations, and PR 5 added the route.
- **QR decoding:** the current Vision revision first, then revision 1 whenever it reads nothing: the simulator cannot
  run revisions 2 to 4 ("Could not create inference context", probed) and CI's runner answered empty (PR 5's first CI
  run failed; fixed in the PR). Cost if wrong: none on a device.
- **The scanner is a sheet** (a swipe closes it), not a full-screen cover with a drawn Cancel: system chrome only, so no
  unboarded design. Cost if wrong: the owner may want a drawn Cancel, which needs a board.
- **The review's raw-space QR question:** iOS 26's `URLComponents` parses `pn=JOHN DOE`; the test stays as a pin.

## The hand run (issue #50)

From a cold simulator against a freshly reset seed, every Phase 5 write through the screens and in the database. It
found two bugs, both fixed in #52 with tests: the receipt sheet stayed open and empty after Undo; Today's Due tile kept
the month a link had opened. It also found two things about the driver, now in the runbook: iOS 26's switch sometimes
needs a 0.15 s press, and an Undo has to be tapped without a screenshot read in between (the toast stays 8 s). The order
differed from the plan's table where the run's state required it (Undo proven on Nikhil; Remind on Hemanth's November
fee). The fees CSV was saved to Files, copied out and opened in Numbers: 11 rows, 7 columns.

## The final review

A fresh reviewer (Opus) on the whole range d5a1a42..d13a26e: no Critical. Fixed in #52, each with a test that failed
first: Undo after marking a waived fee paid left it due without its reason; Settings' older workspace put back a
replaced UPI id (`applyWorkspace` with `takingSettings`/`takingPayments`); Scan a QR never asked for the camera
(`CameraAccess`); the scanner could not be closed (now a sheet). The waived-fee Undo was run again in the simulator.

Deferred minors (the owner decides): a failed read's misleading toast in `openFeeAction`; a failed month move draws a
₹0 ledger under the error line; Reports' Share enabled while loading or after an error; the overdue banner hidden on an
empty current month (U14); the generate preview and `generate_fees` for a student still linked to an archived class;
"The's fee …" fallback copy; one retry slot for reads and writes; a double success haptic on generate and waive;
`commitUPI` twice on submit and autocorrect on the UPI and link fields; Reports' attendance rows skip archived students
while the hero counts their marks; a failed due-before read fails the whole month; `applyQR` keeps the image when the
id did not save; CSV formula injection.

## Tried and dropped

- `async let` in the plan's month-move test raced on the main actor (the delay was cleared before the child ran); a
  `Task` given 20 ms to start waiting replaced it.
- Vision's current barcode revision throws "Could not create inference context" in the simulator and answers empty on
  CI's runner; the decoder tries revision 1 whenever the current one reads nothing.
- A new `Route.payments` in PR 3 put TabsView's destination switch over the lint's complexity; Parent payments was the
  later card until PR 5, and the destinations were split by tab in PR 4.
