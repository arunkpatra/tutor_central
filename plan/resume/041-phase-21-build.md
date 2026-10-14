# Resume 041: Phase 21 (V3 AI quality, parents and exams), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). Phase 21 is planned: the 18 boards of row 29 (`docs/design/mockups/P21-*`; 13 on the
canvas, the five light twins in the mirror) and `plan/phase-21-plan.md`, both approved by the owner. Production holds
migrations 0001 to 0056, the API at 29e79fb and the portal at `main`'s head of 13 October, both in `bom1`; 1.0.0 (30) is on
the owner's iPhone. This session builds the phase task by task, inline, with one ledger, deploys three times, ships build
31, runs the last cost run and the review, and writes the documents.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D110). Phase 20 put the material on
agents; Phase 21 puts every other kind on one, fixes the first nightly's findings, runs the exam as one job, keeps the
tutor's edits as feedback, batches the morning's plans and makes cost a standing report. Read, in this order, before doing
anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `admin/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D110; in particular D68 a phase fixes what it finds, D73,
   D74, D76, D84, D86, D87, D90, D93, D99 to D105 Phase 20's and the nightly's findings, D106 to D110 this phase's).
3. `plan/phase-21-plan.md` whole: the global constraints (Phase 20's lessons are binding), the decisions, the review focus,
   the file structure, the pull requests, the order, the sixteen tasks, the cost and the owner's question.
4. `plan/phase-21-ai-quality-parents-and-exams.md` (the scope and acceptance), "Phase 21 boards" and "Phase 21 parts" in
   `docs/design/information-architecture.md` and `docs/design/components.md`, the boards themselves (`docs/design/mockups/P21-*`,
   or the canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D row 29 at y 83600).
5. `plan/sessions/042/record.md` and `ledger.md` (the reads of production, the boards, the rulings), `plan/sessions/041/ledger.md`
   (Phase 20's build: what was found and what went wrong), `plan/phase-20-plan.md` (the form this plan follows).
6. The code the plan changes, surveyed by hand before Task 1: `api/src/agents/`, `api/src/prompts/`, `api/evals/`,
   `api/src/jobs/kinds/{plan,note-day,eval-run,pdf}.ts`, `api/src/jobs/{call,runner,record,db}.ts`, `api/src/plan/exam-prep.ts`,
   `api/src/routes/`, `api/src/make.ts`, `supabase/migrations/2026112*` (0046 to 0056), `admin/app/cost/`,
   `ios/TutorCentralKit/Sources/Features/{Artefacts,School,Today,Make}/`.

**What is already true:**
- The first production nightly (14 October, ₹34.04) passed 4 of 9 kinds; its nine failures and their fixes are Task 1
  (D105). The morning plan jobs and the alerts of 14 October had nothing to fix.
- The prompts are at version 4 (brief 5, parse_school 3, plan and parse_textbook 3); Task 1 bumps seven of them.
- `bun evals` costs about ₹10 a kind; a pull request that touches a shared file (`schemas.ts`, `shared.ts`, `agent.ts`,
  `check.ts`, `provider.ts`) runs every kind with a golden set in CI; the plan batches shared-file changes into PR 1 and
  says where a second is allowed. The nightly is a measure, not a gate (D103).
- The owner approved the boards, the plan, about ₹550 of real calls for the build and the nightly's cadence as the plan's
  decision 8 on 2026-10-14 (`plan/sessions/042/owner-messages.md`): nothing to ask before Task 1.
- The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac: production's setup is yours (D87). Real Claude calls
  are allowed within the budget; the ledger sums the spend from the runs' tables after every paid run.
- The native speakers for the Hindi and Kannada anchors are the owner's to arrange (Task 3's guide); the build does not wait
  for them.

**Your work:**

1. **Reality.** `git fetch`, `git status`, `gh pr list`; `bun check` green; open `plan/sessions/043/ledger.md` with the
   setup line.
2. **The tasks, in the plan's order,** each test first, RED shown, then GREEN with the full `bun check` before every push;
   one pull request per task as the table says, merged on local green (D86); every PR that changes what is seen carries
   its pictures by `bun pr-shots` (D7) beside its board; a ruling in the ledger with its cost if wrong whenever the plan is
   departed from; the real-call spend summed in the ledger after every run that pays.
3. **The deploys** at their places (A after PR 2, B after PR 7, C after PR 10; the portal after PR 10b), each read back
   with `--linked`; build 31 after PR 12 and the hand runs; the owner's one step as a numbered list.
4. **The hand runs** (Task 13) by `docs/runbooks/simulator.md`, never the API's database tests meanwhile, the API restarted
   after each branch switch, the pictures on one issue; each finding fixed in its own pull request with a test first (D68).
5. **The last cost run** (Task 15) and the review (Task 16) on Fable 5.1 with two fresh reviewers, every finding fixed.
6. **Close.** The documents of Task 16, `STATE.md`, the session's record, owner messages and ledger; the resume for Phase 22
   if the owner asks; commit to `main` (D12).

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy, what
  a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41).
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55); the golden and anchor sets use the seed's names.
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1).
