# Resume 028: Phase 14 (Parents), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan is `plan/phase-14-plan.md`, approved by the owner; its seven boards are on
row 24 of the canvas (`docs/design/mockups/P14-*`), approved before PRs 11 and 12 build them. This session builds the
phase to its end: thirteen pull requests, two deploys, the hand runs, the cost run, the review, a TestFlight build, the
documents.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 13
(School) is built and in production; Phase 14 (Parents) is planned. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D68; D67 and D68 are this phase's), `plan/ui-polish.md`
   (U41 to U45 close in this phase).
3. `plan/phase-14-plan.md` in full: the goal, the constraints, the 30 decisions, the review focus, the file structure, the
   launch states, the thirteen pull requests, Tasks 1 to 24, the self-review. Then `plan/phase-14-parents.md` (the scope,
   items 7 and 8 the owner added) and `docs/spec-v2.md` sections 5, 7, 8 and 9.
4. The boards: `docs/design/information-architecture.md` ("Phase 10 boards", 10.6 and 10.3's note day and To parents;
   "Phase 14 boards"), `components.md` ("Phase 10 parts" 10.6; "Phase 14 parts"), `design-tokens.md` ("Numbers in code"),
   `feedback.md`. Open each board on the canvas or in `docs/design/mockups/` before building its screen.
5. `plan/sessions/029/record.md` (the plan session: why things are as they are), `plan/sessions/028/record.md` and
   `ledger.md` (Phase 13's build, the house style of a ledger, the five minors this phase fixes), `docs/runbooks/simulator.md`
   (the hand runs; section 11 for a share).
6. The code the plan builds on, named per task in its "Files" blocks; read each file before changing it.

**What is already true:** production holds migrations 0001 to 0022 and the API at `cfddfc5`; TestFlight carries 1.0.0 (24).
The owner tests the builds together after the last phase (D68), so the hand runs in the simulator against the local stack
are the check of this phase. The owner approved real AI calls in testing without asking each time (be judicious; record what
ran and what it cost; the plan names the cost run's spend). The cadence rule, the two-language sheet, consent per student,
the WhatsApp log and Check a paper's preset exist; the plan extends them.

**Your work:** execute `plan/phase-14-plan.md` with `superpowers:executing-plans` (inline, task by task, tests first, one
ledger at `plan/sessions/030/ledger.md` as sessions 22 to 28 kept: a line per ruling with its cost if wrong, a line per task
with its commits and the test run that went red then green, a line per hand run with what was confirmed in the database):

- PR 1 the database (0023, 0024, the seed's consents); PR 2 D67 (the model table, the overrides, the refusal at start, the
  price sheet and `bun cost`); PR 3 the API's answers (503 for a lost connection, the student's consent words, U45); PR 4 the
  API's note, can_do, not_on_track and `/ai/read-marks`; then `gh workflow run deploy`.
- PR 5 Domain (with the six message sheets' pictures: the signature); PR 6 Data (with the write proofs); PR 7 the note day on
  Today; PR 8 the note and can-now-do; PR 9 the sent log; PR 10 not on track; PR 11 marks from a photo and PR 12 the School
  leftovers (both only once the owner has approved the P14 boards; the plan says what each state shows); the hand runs the
  plan's Task 20 names after each pull request; the cost run (Task 21) and PR 13 (the read-marks default); the review on
  Fable 5.1 with each finding of any grade fixed (Task 22; D68); Task 23's check that nothing of the phase's own is left;
  TestFlight; the documents (Task 24) to `main` (D12).
- Rule 1 and rule 2 hold for each screen: a state without an approved board is not built; each changed state is photographed
  in both appearances where the board has both and the pictures are in the pull request's description through
  `bun pr-shots`.
- Where the plan and the code disagree, the code's facts win and the ledger says what moved and why; where the plan and a
  board disagree, the board wins. A thing the plan did not foresee that changes what is seen needs a board first; one that
  does not is decided, written in the ledger, and built.

**The owner's rules:** check each request against the spec, the decisions, the boards and the code, and push back with a
concrete reason when it is wrong (`docs/working/pushback.md`); be brief; decide small things and say what you decided; ask
one question at a time, only for what is his; no technical words in anything a tutor reads (D41); plain voice in documents
(no slogans, no "every"); the word is Students, and Batch on screen; nothing from V1 renamed in the model (D56); migrations
additive (D26); no service-role key (D37, D60); nothing found in the phase is deferred (D68). Show the owner each finished
part. Update `plan/STATE.md` before you stop; write `plan/sessions/030/record.md`, `ledger.md` and `owner-messages.md` at the
end.
