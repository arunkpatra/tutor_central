# Session 26 (2026-10-10 and 11): Phase 12's build

Model: Claude Opus 5.5, from `resume/024-phase-12-build.md`, with `superpowers:executing-plans` (inline, tests first, one
ledger: `ledger.md` beside this record, every ruling with what it costs if wrong). Outcome: Phase 12 built as nine pull
requests (#110 to #119), two deploys (0019; then 0020 and the API), the D32 hand runs (#120) with eleven faults found and
fixed test first, the cost run on the real API after the owner's yes, a fresh review on Fable 5.1 with its Critical and
Important findings fixed in #119, TestFlight 1.0.0 (21) (run 38099197755), and the documents.

## What was done, in order

1. Read the rules, the state, the plan, the spec and the boards; the plan's workspace and ledger; the pre-flight scan.
2. PR 1 #110 (Tasks 1 to 3, the database): migration 0019 (`make_plan`, `keep_artefact`, the close's done lines, the
   class's plan pattern), the seed's twelve-student Evening batch, the RLS tests. PR 2 #111 (the API): `/ai/plan`,
   `/ai/make` for sheet, worked example, figure and brief, the fake's answers. Deploy 1 (run 38067327168): 0019 applied.
3. #112 (Domain: the plan's rules, the budget tested against the price sheet, the artefacts, the figure's wire format,
   the reminder's words, the refusals) and #113 (Data: plans and artefacts, the plan's copy, photos, the API client's
   calls, the close's done lines). #114: migration 0020, a group's worked example and figure on lines of their own (the
   two would have overwritten each other's teach link).
4. PR 5 #115 (Tasks 11 to 14): the group cards and lines, the planning card, the line menu, Change the plan, the
   reminder, the background refresh's handler. PR 6 #116 (Tasks 15 to 17): the sheet in three forms, Share as PDF and
   Print, Make it again, Use my own. PR 7 #117 (Tasks 18, 19): the worked example, the brief, the seven figures.
5. PR 8 #118 (Tasks 20 to 22): the close from the plan, its checklist, the card's three states (U37, U38), the waiting
   close's symbol (U39), the close offline from the plan's copy.
6. PR 9 #119 (Task 23): This week's Today (U35), a homework row opens its sheet; then the hand runs' fixes and the
   review's.
7. Deploy 2 (run 38075931282): 0020 applied, the API at `6a23563`, the smoke green.
8. The hand runs on a cold simulator against a fresh seed (#120): the plan on open, a regenerate, Use my own, change the
   plan, U35, a V1 student, the close online and offline (twice). Eleven faults, each with a test that failed first.
9. The cost run (the owner's yes in chat): 13 calls, ₹4.57 for the twelve-student batch; the price sheet's test figures
   take the averages.
10. The review (fresh context, Fable 5.1, over `3a5ea17..49bb048`): With fixes. Critical 1 and Important 2, 3, 5, 6 fixed
    in #119 with tests that failed first; Important 4 ruled (Make the plan again names the group); ten minors deferred.
11. The TestFlight build; the documents (this record, the ledger, the owner's messages, "As built", STATE, the polish rows
    U35, U37 to U40, device tests T4 to T7, the rules learned, the design notes).

## Why things are as they are

- **The plan is Domain's rules on the phone** (D60): `/ai/plan` only names a first topic for a group with no record, so a
  plan costs nothing until its material is made.
- **One run per plan:** a return to the app while the plan was being made started a second run (the review's Critical);
  the store now leaves a live run alone.
- **Checks record on the student's own skill:** skills are per student and a group's checks carry one student's ids; a row
  a student cannot keep is not offered, so no tap goes nowhere.
- **The book's copy:** the first offline close dropped every check (the books could not be read); the plan and the close
  keep each student's book on the iPhone.
- **The figures are the Artefacts feature's:** DesignSystem does not import Domain.

## Tried and dropped

- Filling an unnamed group in `complete()`: it needs a plan write that keeps the made material's links; Make the plan
  again names it.
- The board's "the slip to watch for in step 2" on the brief's example row: the data names no step.

## Machine

`bun check` green per pull request locally and on CI; the hand runs on the iPhone 17 simulator against the local stack
with the local API (`AI_FAKE=1`; the real model for run 8 only, stopped right after); the Evening batch moved to Sunday
01:00 for the runs and put back after; the database reset before runs 5 (twice) and 8; Postgres' `current_date` is UTC, so
the day was queried by date.

## Next

The owner installs 1.0.0 (21) from the internal group and checks the plan on his iPhone (the tester's T4 to T7). Then
Phase 13's plan (School) on Fable; the owner's call on writing a new batch's named topic as each member's chapter and skill
(the ledger's Final ruling on Important 3).

## After the phase (2026-10-11)

- **#121:** a link to another student opened the page already showing; every pushed screen now takes its route as its
  identity. TestFlight 1.0.0 (22), fine on the owner's iPhone.
- **#122:** on a centre with no batches the AI forms' Class picker opened nothing (the owner, build 22). Cause: Question
  paper, Homework and Worksheet took their class from a batch, a V1 leftover; the API never needed one and V2's Make form
  offers "a class on its own". The owner ruled for the class by level; boards P12-Form-Paper-Class, -ClassWheel, -NoClass
  approved (canvas row 22) and mirrored first. Built test first; a hand run with every batch archived on the real
  Anthropic API (₹3.44: a Class 8 Science paper, a Class 5 English homework), which found the remembered values unwired; a
  fresh review on Fable ("With fixes": Check a paper's list named the batch) fixed with a test. My proposed starting order
  (most common class first) was wrong; the build takes the last class chosen first, and the board note says so.
- **The owner's standing rule:** push back on a wrong request with a concrete reason and an alternative, never invent
  one: `docs/working/pushback.md`, linked from CLAUDE.md "Working with the owner".
- TestFlight 1.0.0 (23) by run 38105466595 from `6fa0913`.

