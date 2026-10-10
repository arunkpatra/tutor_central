# Session 24 (2026-10-10): Phase 11's build

Model: Claude Opus 5.5, from `resume/022-phase-11-build.md`, with `superpowers:executing-plans` (inline, tests first, one
ledger: `ledger.md` beside this record, every ruling with what it costs if wrong). Outcome: Phase 11 built as ten pull
requests (#97 to #106), the deploy of 0017 and the API, the ten hand runs (#107), a fresh review on Fable 5.1 with its
Critical and Important findings fixed (#106, #108, #109), migration 0018, the TestFlight build, and the documents.

## What was done, in order

1. Read the rules, the state, the plan, the spec and the boards; set up the plan's workspace and ledger; the pre-flight
   scan of the plan's interfaces.
2. PR 1 #97 (Task 1): migration 0017 (`close_session` with states, `record_placement`, the class-wide copy), the seed's
   class levels and Vidya Niketan, the RLS and behaviour tests, the types. PR 2 #98 (Tasks 2, 3): `/parse-textbook` and
   `/make` (check, placement) with the fake; `routes/common.ts` and `routes/v2.ts`. Deploy run 38052646487: 0017 applied,
   the API at `8dde6d0`, the smoke green.
3. PR 3 #99 (Tasks 4 to 7): Domain (Student V2, the record types, SpacedQueue, SkillProgress, TrackingRules, the consent
   message, the queue's close). PR 4 #100 (Tasks 8 to 10): Data (students V2, schools, textbooks, record, message log, the
   close's params, the queue runner's close, the AI client's V2 calls), with the write proofs.
4. PR 5 #101 (Task 11): the five tabs, Attendance under More, V1's links. Hand run 1.
5. PR 6 #102 (Tasks 12, 13): the list by status, New student V2 and its edit. Hand runs 2 and 3.
6. PR 7 #103 (Tasks 14 to 16): the student's page, consent. Hand run 4.
7. PR 8 #104 (Tasks 17, 18): the check row, Add a textbook. Hand run 5. PR 9 #105 (Task 19): the placement. Hand runs 7
   and 6.
8. PR 10 #106 (Tasks 20 to 22): the batch hero, the close, the close offline. Hand runs 8, 9 and 10 found seven faults,
   each fixed with a failing test first in the same pull request.
9. The review (fresh context, Fable 5.1, over `2ecfe22..phase-11/close`): With fixes. Critical 1 (a close kept on this
   iPhone opened again from scratch) and Important 3 (Done live while checks were made) fixed in #106; Important 2 (a
   student moved up a class broke the class's book copy) as migration 0018 in #108; Important 4 (`/parse-textbook` could not
   answer "no chapters") in #109. Six minors deferred (the ledger's `Final: minor (deferred)` lines).
10. The deploy of 0018 and the API; the TestFlight build; the documents (this record, the ledger, the owner's messages,
    "As built", STATE, the polish rows U34 to U39, device tests T1 to T3, the rules learned, the design notes, resume 023).

## Why things are as they are

- **The placement's rules are Domain's:** Today's close needs them and features never import each other.
- **The hero:** Start class while a batch not yet closed is soon or running; the latest close holds the hero until the
  next batch is soon; "No batch today" names the next one. Two hand-run faults shaped this (a closed batch kept the hero
  while the next one started; two closes picked the running one, not the latest).
- **The close lists students at once and runs its reads together:** offline with the gateway down, each read waited about
  20 s; in turn the close stayed empty for minutes. Done waits for the reads and the checks so the statuses it writes see
  the record.
- **A re-close replaces:** `close_session` replaces the session's checks and homework; a tap unchanged since the server
  kept it moves no state twice, while a close still waiting in the queue moves them fully (the server has moved nothing).
- **0018, not an edit of 0017:** 0017 had run in production; last year's chapters move behind the new book's so states and
  checks stay.

## Tried and dropped

- Making checks lazily per student on reopen for everyone: absent students' checks are made only when marked present.
- A footer "Saved on this iPhone" mark on the close: the close pops at once, so Today's hero says it.

## Machine

`bun check` green per pull request locally and on CI; the hand runs on the iPhone 17 simulator against the local stack
with the local API (`AI_FAKE=1`); the local database not reset before runs 8 to 10 (the seed has no class 10 book; Riya,
placed in run 7, carried the checks); the batches' times moved for the runs by psql and put back after.

## Next

The owner approved the batch hero and found build 20 fine on his iPhone. Phase 12's plan on Fable from
`resume/023-phase-12-plan.md`.
