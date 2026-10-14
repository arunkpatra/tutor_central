# Session 43: Phase 21's build (Opus 5.5, 2026-10-14)

From `plan/resume/041-phase-21-build.md`. The owner's messages word for word are `owner-messages.md`; each ruling, hand run,
fix and review finding, with its cost if wrong, is `ledger.md`. The language anchors' cases are in `anchors/`.

## What was built

Phase 21 in pull requests #318 to #349 (the list is in the phase file's "As built"):
- The nightly's findings fixed first (D105).
- The parents' four kinds on their agents with the message rules and the language anchors.
- The exam as one job: the split, the mock on its morning, the gap reports, today's plan asked again.
- The exam's page reading that job.
- Make's and V1's kinds on their agents, with V1's PDFs made on the server.
- The tutor's feedback, and the reasons menus on the brief, the mock and the note.
- The set-aside note.
- The morning's plans through Message Batches with the hour's cache.
- The standing cost report and the portal's Cost page.
- The nightly's sets and `bun feedback-cases`.

## Decisions by the owner

- D111: a batched plan's repairs and their checks go in batches too.
- D112: no automation spends on AI calls. The evals and the nightly run by hand only, and the deploy's smoke is free. The
  pre-PR proof (`docs/working/pre-pr-proof.md`) and the testing layers (`docs/working/testing.md`) are linked from
  CLAUDE.md.
- The budget: ₹950, then ₹3,000. The spend at the close was about ₹1,770.
- Cost is tracked, but the owner is not to be told its details: the product is not designed around API costs.

## The hand runs (issue #343)

All twelve were done on the local stack, on the real models and the fake. The six findings were each fixed with a test that
failed first:
- A note made again with a reason kept the fact it was asked to drop (#337).
- An exam moved in date was never split again; the gap report was refused for its skills' order and never tried again (#338).
- A check refused a clear answer sheet with "findings" that said the marks were fair. The full eval run on the new rule
  also fixed three kinds' words (#339).
- A student was shown as "working" when the job could not make their report (#340).
- A fresh V1 result shared the phone's drawing, not the server's PDF (#341).
- Footers and exam rows clipped at the largest text size (#342).

## The review (Fable 5.1, two fresh reviewers)

Twelve findings in all: eight fixed, four ruled.
- **Fixed:**
  - A replaced plan paid for its whole material again, in a batch (#344).
  - The nightly's progress note cases were refused at the gate (#348, migration 0065).
  - The exam job spun on a mock key held by another body (#349).
  - Try again on a mock showed nothing happening (#345).
  - A note's feedback was kept on every Send, and a server's note was kept as the tutor's own (#346).
  - Share could hand out the last result's PDF (#347).
- **Ruled in the ledger:** the two-batch exam split (for Phase 22's list), a lost function's second batch, and two minors.

## The cost run

Tomorrow's two plans by batch cost ₹6.34, against Phase 20's ₹11.24. Make's nine kinds once each cost ₹17.82. The Cost page's
function agrees with the rows to the paisa, so the standing report is the figure from here.

A mistake on the way: a database test run during the cost run cleared its first two plans. Their batches were paid, about ₹6.
The runbook now says so (section 15).

## Production

- Deploys A to F; migrations to 0065; the API at 69d8389.
- The portal (run 38563016478).
- TestFlight 1.0.0 (31) by run 38583690172.

## For the owner (build 31)

1. On the iPhone, open TestFlight and install Tutor Central 1.0.0 (31).
2. More → Make something → Note to a parent → choose a student whose parent agreed → Write the note → Write again → pick a
   reason (for example "Less about marks"). The new note arrives, and the old one stays on screen until it does. (Corrected:
   the first wording named a "Write a note" button on the student's page, which does not exist.)
3. More → Make something → Question paper → fill it in and make it. Wait a few seconds, then Share as PDF: the shared file
   has the questions and an answer key on its last page.
4. If an exam is within its window, open its page in School. It shows the days of preparation, and on the mock's day,
   Being made and then Ready.
5. Tell me "build 31 fine", or what you saw.
