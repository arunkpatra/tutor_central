# Session 23 (2026-10-10): Phase 11's plan

Model: Claude Fable 5.1 (D17), from `resume/021-phase-11-boards-and-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-11-plan.md` (24 tasks, ten pull requests, tests first, the launch states, the hand runs, the review focus, the
decisions it takes) and `plan/resume/022-phase-11-build.md`, indexed; `STATE.md`; this record. Documents only, to `main`
(D12). No code.

## What was done, in order

1. Read the rules, the state, the decisions (D1 to D66), the polish list, the V2 spec's sections 2, 4, 5, 6, 8 and 9, the
   Phase 11 scope, Phase 10's two "As built" sections, the 10.1 to 10.3 notes in `information-architecture.md`, the parts
   and texts in `components.md`, the numbers in `design-tokens.md`, `feedback.md`, the records of sessions 21 and 22 with
   the ledger, migrations 0009, 0010, 0013 and 0016, the V2 tests, the API's schemas, routes, fakes and tests, Domain's
   record types, the schools, textbooks and attendance repositories, the queue, the API client, the Students, Today and
   Attendance features, the shell's tabs, links, launch states and fixtures, the simulator runbook, the Phase 7 and 10
   plans for the house style. Reality matched `STATE.md` (`main` at f1b6107, nothing open); `bun check` green from its
   cache.
2. Wrote the plan: the header, the global constraints, twenty decisions, seven review-focus lines each pinned to a test,
   the file structure by module, the launch states with their boards and pull requests, the ten pull requests, Tasks 1
   to 24 with the tests written out (the migration's SQL in full; the API's schemas, prompts and route; Domain's types
   and rules with their tests; Data's rows, repositories and the write proofs; the shell; the Students and Today screens
   by their Kit parts and the boards' texts; the hand runs; the documents), the self-review.
3. Wrote resume 022 and indexed it; updated `STATE.md`; this record and the owner's messages.

## Why things are as they are

- **One migration, additive (0017):** the close needed to move skill states (the spec's states follow the checks; 0010's
  `close_session` wrote only `last_checked_at`), the placement needed a write of its own (checks without a session, the
  states, the status), and Keep needed the class-wide copy in one call rather than one call per student. The old
  seven-argument `close_session` still works through the default, so build 19 keeps closing.
- **Checks are made at the close, per student:** there is no plan yet (Phase 12); the boards say a student with no plan
  gets three checks from the spaced queue or the placement, so the close asks `/ai/make` for them when it opens. Phase 12
  moves that ahead to the plan per group.
- **The textbook photo is never kept:** the approved intro says "We keep no copy"; `photo_path` stays null, and the
  photos-deletion contract of Phase 10 moves to Phase 13's first stored photo.
- **The trust page and App Privacy wait:** spec section 9 ties them to the phase that first sends a student's own data,
  which this phase does not; Phase 14's note is that phase.
- **The hero is the one owner question:** P10-Shell-Today (10.1) draws Today with V1's hero and Mark attendance;
  P10-Today-Plan (10.3) draws the batch hero with Start class above the plan's cards; the close is this phase's and the
  plan is Phase 12's, so Today must carry Start class without the cards. The plan builds the 10.3 hero over V1's content
  and asks the owner to confirm, since a state no board draws exactly is his to rule on (rule 1).
- **Class required for a new student only:** the boards' "Save needs the name and the class" is for New student; a V1
  student edited with Class required would be blocked from changing a phone number.
- **The rules are numbered in the plan, not as decisions:** the spaced queue's intervals, the skill moves, the tracking
  bands and the term calendar are the plan's working numbers, tested, and Phase 12 refines them with the plan; the
  phase file's "As built" records what the build settled.

## Tried and dropped

- Building the School tab's empty card with its two buttons (P10-School-Empty) now: the buttons lead to Phase 13's
  screens; the 10.1 note itself says the Later card until then.
- A `Change` action on the tracking card: its four next steps are P10-NextStep (10.6, Phase 14); a button that does
  nothing is not built.

## Machine

Reading only; `bun check` from its cache. No simulator run.

## Next

The owner's answer on the hero (the end of this session's message); then Phase 11's build on Opus 5.5 from
`resume/022-phase-11-build.md`.
