# Resume 022: Phase 11 (the record and the close), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: the build runs on Opus once the plan is approved). The plan was approved by the owner after session 23; nothing
else runs beside this session.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product (D66); Phase 10 laid its foundation
and Phase 11 builds the first V2 screens: the record and the close. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66; D56 to D66 are V2's), `plan/ui-polish.md`.
3. **`plan/phase-11-plan.md`**: yours, Tasks 1 to 24, with the tests written out, the file structure, the launch states,
   the ten pull requests, the decisions it takes (read them first: the hero with Start class, the School tab's Later
   card, the trust page deferred, Class required for a new student only, the spaced queue, skill progress, the tracking
   rules, checks made at the close, the monthly words, the subject sheet, Keep's class-wide copy, consent after clearing,
   `SessionClose` in Domain, the seed), the review focus, the hand runs. You execute it with `superpowers:executing-plans`,
   inline, task by task, ticking its boxes, with one ledger as sessions 15 and 22 kept (`plan/sessions/022/ledger.md`:
   each ruling with what it costs if wrong). Its scope file is `plan/phase-11-record-and-close.md`.
4. `docs/spec-v2.md` sections 2, 4, 5, 6 (the close), 8 (consent) and 9; `docs/design/information-architecture.md`
   "Phase 10 boards" steps 10.1, 10.2 and 10.3 (the close only); `components.md` "Phase 10 parts" 10.1 to 10.3 (the
   parts and every text on screen); `design-tokens.md` "Numbers in code"; `feedback.md`. The boards are in
   `docs/design/mockups/P10-*` (rows 14 to 16 of the canvas) and are binding: what they draw is what is built, in their
   words.
5. `plan/sessions/023/record.md` (the plan's session: the owner's answer on the hero), `plan/sessions/022/record.md` and
   `ledger.md` (why the tables are as they are), `plan/sessions/021/record.md` (the owner's rulings on the boards).
6. What you build on: `supabase/migrations/` 0009 to 0016 and `tests/v2.test.ts`; `api/src/schemas.ts`, `routes/ai.ts`,
   `claude-fake.ts`, `models.ts`; `ios/TutorCentralKit/Sources/Domain/Record/`, `Data/Schools/`, `Data/Textbooks/`,
   `Data/Attendance/`, `Data/Queue/`, `Features/Students/`, `Features/Today/`, `Features/Attendance/`, `AppShell/`
   (`TabsView`, `TabsState`, `DeepLink`, `MoreView`, `RootView+*`, `LaunchState`, `Fixtures`).

**What is already true:** production holds migrations 0001 to 0016 and the API at `main`'s head with the four V2 routes
answering 501; TestFlight 1.0.0 (19) is on the owner's iPhone; no V2 screen is built; `bun check` is green on `main`.

**Your work:** execute `plan/phase-11-plan.md` in its order, tests first, one pull request per row of its "Pull requests"
table, each with `bun check` green, one change, described by what it does and how it was checked, and the pictures of
each changed state (`bun shots`, `bun pr-shots`, rule 2) where something on screen changes:
1. PR 1 (Task 1): migration 0017, the seed, the types. PR 2 (Tasks 2, 3): the API. Then `gh workflow run deploy` (Task 23
   step 1) and record the run.
2. PR 3 (Tasks 4 to 7): Domain. PR 4 (Tasks 8 to 10): Data, with the write proofs against the local stack in the
   description.
3. PR 5 (Task 11): the shell. PR 6 (Tasks 12, 13): the list and the form. PR 7 (Tasks 14 to 16): the student's page and
   consent. PR 8 (Tasks 17, 18): the textbook. PR 9 (Task 19): the placement. PR 10 (Tasks 20 to 22): the hero and the
   close.
4. Task 23: the hand runs by `docs/runbooks/simulator.md` (D32), each write confirmed in the database, the screenshots on
   the phase's issue; the reviewer pass of Task 24 step 2 (fresh context, Fable 5.1); then `gh workflow run testflight`
   and the owner's check on his iPhone.
5. Task 24: the documents, committed to `main` (D12): "As built", README, STATE, ui-polish, the design documents where
   the build corrected a word, the CLAUDE.md rules learned, `plan/sessions/024/record.md`, `ledger.md`, `owner-messages.md`,
   and `resume/023-phase-12-plan.md` for Phase 12's plan on Fable, indexed in `plan/resume/README.md`.

Show the owner each finished pull request in a few lines: what was built, what was decided, what needs approval. A
state the boards do not draw is not built; say so and put it on `ui-polish.md` or ask. Where the plan's code and the
repository disagree, the repository wins and the ledger says so.

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time; no technical
words in anything a tutor reads (D41, `ErrorWordsTests`); plain voice in documents; nothing from V1 renamed in the model
(D56; "Batch" is only the word on screen); migrations additive (D26); no service-role key (D37, D60); dependencies
pinned, Bun only (D14, D16); each message to the tutor one of `feedback.md`'s rows. Update `plan/STATE.md` before you
stop; write `plan/sessions/024/record.md` (or the next number) at the end.
