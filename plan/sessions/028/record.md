# Session 28 (2026-10-11): Phase 13 built

Model: Claude Opus 5.5 (D17), from `resume/026-phase-13-build.md`, with `superpowers:executing-plans` (inline, task by
task, tests first). Outcome: Phase 13 built in ten pull requests (#123 to #126, #128 to #134) with #127 for the compiler's
warnings; the runbook's share path (section 11) to `main`; hand runs 1 to 15 against the local stack; the cost run on the
real models; a fresh review on Fable 5.1 with its four Important findings fixed in #134; two deploys; TestFlight 1.0.0
(24); the documents to `main` (D12). The ledger with every ruling and hand run is `ledger.md` beside this record.

## What was done, in order

1. Read the rules, the state, the plan, the spec and the boards; the workspace and ledger; the pre-flight scan.
2. PR 1 #123 (0021: items' title, end date, source and received time; marks from a mock; the forward ask's kind; the keeps
   with an exam; a marking's consent; the seed's items and marks) and PR 2 #124 (the API: `/ai/parse-school`, `/ai/make`
   mock, gap report and test tomorrow, check-paper with a mock's key and the student's consent); deploy run 38110074045.
   #126 (0022: `name_plan_group` finds the group by the app's key).
3. PR 3 #125 (Domain), PR 4 #128 (Data), #127 (the warnings, the owner's ask), PR 5 #129 (the School tab, Check what was
   read, an item's sheet and page, the share hand-off, the student page's School); hand runs 14, 1, 2, 3 with three fixes.
4. PR 6 #130 (Ask parents, Test tomorrow, To parents after the close); hand runs 4, 5, 15 with one fix.
5. PR 7 #131 (the plan in exam mode, holidays, a plan remade on an item's change; the exam's page with Preparation); hand
   runs 6 and 7 with one fix.
6. PR 8 #132 (the mock, marking it from a photo with marks written, the gap report, the last days); hand runs 8 to 10 with
   two fixes.
7. PR 9 #133 (U36, Marks); PR 10 #134 (a new batch's first checks; an unnamed group named at the next open); hand runs 11
   to 13 with a seed fix.
8. The review (Fable 5.1, 51 commits): no Critical, four Important (the test day's revision plan, a holiday's plan back on
   reopen, the gap request over the API's limits, two mocks for two batches), five Minor; each Important fixed with a test
   that failed first, in #134.
9. The cost run with the owner's yes: mock ₹3.94, marking ₹8.18, gap report ₹0.43; two fixes the real model found (the gap
   request within the API's limits, the prompt within the output's).
10. Deploy run 38123899264 (0022 and the API at cfddfc5); TestFlight run 38124050257, build 24; the documents.

## Why things are as they are

- **The split starts when the item came** (Ruling, Task 17): decision 9's "from today" read each day moves the mock day away
  and the last days never come; the page and the plan read one split.
- **A shared mock** (Task 17, review Important 4): one mock per exam, linked into every batch's plan; plan reads take
  artefacts their lines link from another plan.
- **Marks from Check a paper** (Task 20): a mock's preset skips the scheme and writes a mark with the notes line; a paper
  made here writes one too; a typed scheme none.
- **The hand runs found eleven defects** the tests had not: a photo two items share, the source time, the calendar's frame,
  Ask parents offline, the day picker, Back after saving marks, the page under it, Below usual in the seed, and the cost
  run's two. Each fix came with a test that failed first.
- **Slips:** two tasks' tests were not seen failing before the code (Task 4, Task 21's gap report store); both ledgered.

## Left for the owner

- T8 to T10 on a real iPhone (`docs/testing/device-tests.md`), the share from WhatsApp first.
- The cost: ₹8.18 a marking on Opus is most of an exam's ₹30 for a class of three; D64's price reads it.
- U41 to U45 on the polish list; the review's five minors; the three CI warnings kept.
