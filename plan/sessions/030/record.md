# Session 30 (2026-10-11): Phase 14 built

Model: Claude Opus 5.5 (D17), from `resume/028-phase-14-build.md`, with `superpowers:executing-plans` (inline, task by
task, tests first). Outcome: Phase 14 built in fifteen pull requests (#135 to #149); hand runs 1 to 15 against the local
stack with every write confirmed in the database; the cost run on the real models; a fresh review on Fable 5.1 (two
reviewers: the app; the API, database and tools) with every finding fixed or ruled; two deploys; TestFlight; the documents
to `main` (D12). The ledger with every ruling, hand run and fix is `ledger.md` beside this record (96 rulings).

## What was done, in order

1. Read the rules, the state, the plan, the spec and the boards; the ledger and the pre-flight scan.
2. #135 (0023, 0024, the seed's consents), #136 (D67), #137 (the lost connection, the student's consent words, U45), #138
   (the API's parents' kinds and `/ai/read-marks`); deploy run 38137427740 (0023, 0024, the API at a4e87d6).
3. #139 (Domain with the signature; six message sheets' pictures), #140 (Data, its write paths proven against the local
   stack).
4. #141 (the note day on Today), #142 (the note and can-now-do), #143 (the sent log), #144 (not on track, the next step,
   Today's caption, 0025), #145 (marks from a photo), #146 (School: U41 to U44, two minors).
5. The hand runs (all fifteen of the plan's, by `docs/runbooks/simulator.md`): five faults found and fixed in #146 with
   tests that failed first (Step back's words on a book's first skill; a note held for consent opened the three-messages
   sheet with Send it now; a copied note counted toward the cadence; the paste footer's line; the note day offline read
   "No notes this week").
6. The cost run (real Claude): 15 calls, ₹2.52; two faults the real model found (a Hindi note's English over 600 refused
   the answer; the refusal read "Change the topic") fixed in #147. Reading marks stays on Sonnet, so the planned
   read-marks pull request was not needed.
7. The review on Fable 5.1: API, database and tools 3 Important, 9 Minor (#148); the app 6 Important, 10 Minor (#149). All
   fixed with a test that failed first (two database tests passed first: coverage of right behaviour), but two app
   findings ruled (below).
8. Deploy 2: run 38151333693 (0025, the API at bc68758; the smoke green). TestFlight run 38151541726, 1.0.0 (25). The
   documents. CI on main crashed once in SchoolTests after every suite passed (run 38148815276, #148's merge, no app
   change); main's head was green and the deploy went from it (ledger).

## Why things are as they are

- **Today's caption from the log** (Task 16): carried on the plan's line, a sent message would need the plan made again,
  which makes its material again.
- **A trigger clears the step** (0025): one rule for the close, the placement and a queued close; the register mirrors it,
  and a choice waits while a queued close tracks the student (review Important 3 of the API).
- **Taught means first taught** (review): a skill that only moved on was taught before; the record keeps no earlier state,
  so one taught and moved on within one week shows under Got right.
- **The English may run longer** (cost run): it is the tutor's reading aid, never sent; a translation runs longer than its
  source.
- **Two rulings on the review**: the not-on-track message is not held by the three-a-week cadence (the tutor's deliberate
  send, counted toward the week; a held card would need a board); a copy made offline is not logged (a record only, and a
  copy never counts).

## What it cost

The cost run: notes ₹0.43 (8), can-now-do ₹0.18 (4), not on track ₹0.07, reading marks ₹0.56 on Sonnet and ₹1.28 on Opus
(compared, discarded). A week of notes for twelve students ₹0.61. The hand runs ran on the fake (AI_FAKE) but run 12 (one
note on Sonnet, fake answer, no cost).

## Left for later

Nothing of the phase's own. U46 and U47 on `plan/ui-polish.md`; T11 to T14 for the tester.
