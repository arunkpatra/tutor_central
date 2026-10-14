# Resume 040: Phase 21 (V3 AI quality, parents and exams), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 20 is built and deployed: the agent pipeline for the nine material kinds,
`ai_models` with the kill switch, versioned prompts, `bun evals` with its gate, the nightly `eval_run`, mathematics on the phone
and in the PDFs; migrations 0001 to 0056 in production; 1.0.0 (30) checked by the owner on his iPhone on 14 October ("build 30
ok"). Phase 21 changes what the tutor sees (exam preparation as one job, the tutor's reason when making something again, a
refused note's words) and what the owner sees (the cost report). So its boards come first (rule 1; boards before the plan, the
owner's 2026-10-11 rule). This session reads production, draws the boards, gets them approved, mirrors them, then writes
`plan/phase-21-plan.md` and the build's resume prompt, and stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D105). Phase 20 made the material good. Phase
21 brings the parent kinds, the exam kinds and the rest of Make's and V1's kinds onto the same pipeline. It runs the exam as
one job, keeps the tutor's edits as feedback, batches the morning's plans, and makes cost a standing report. It also starts
with the first nightly's findings (D105). Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `admin/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D105; in particular D35 the SDK, D58 the placement, D62 group
   kinds, D64 the price, D67 `models.json`, D68 a phase fixes what it finds, D73 an agent per kind, D74 prompts, evals and
   feedback, D76 the recorded call, D81 the order, D86 merge on local green, D87 production through the signed-in CLIs, D90
   the server's PDFs, D99 to D104 Phase 20's, D105 the nightly's findings).
3. `plan/phase-21-ai-quality-parents-and-exams.md` (the scope and acceptance, item 7 is D105), `docs/spec-v3.md`'s sections
   on the agents, feedback, batches and cost, `plan/phase-20-ai-quality-material.md`'s "As built",
   `plan/phase-19-admin-portal-reading.md`'s "As built" (the portal's pages the cost report joins).
4. `plan/sessions/041/record.md` and `ledger.md` (Phase 20's build: what was found, the spend, the mistakes),
   `plan/phase-20-plan.md` (the plan's form to follow).
5. What Phase 21 moves:
   - the parent kinds in `api/src/routes/` (note, can-now-do, test tomorrow, not on track, read marks) and the note day's job;
   - the exam kinds (Phase 13: the split, the daily sets, the mock and its marking, the gap report);
   - Make's and V1's kinds (paper, homework, worksheet, progress note, scan register, Check a paper);
   - `api/src/agents/`, `api/src/prompts/`, `api/evals/`, `api/src/jobs/kinds/eval-run.ts` (the batch runner the morning's plans
     will share);
   - the portal's Cost page;
   - Phase 14's and Phase 13's boards (`P14-*`, `P13-*`) and Phase 20's cost run, the figures Phase 21's are set against.

**First, before the boards:** reads in production with `supabase db query --linked`. Put each in
`plan/sessions/042/ledger.md` and in one line to the owner.

1. **Every nightly `eval_run` since 14 October:** per kind, the cases, check passes, grade passes and cost, and each failed
   case's reasons. The first night (job `a01907fc…`, ₹34.04) passed 4 of 9 kinds at one try a case: check, sheet and worked
   example 5 of 5; brief 4; parse_textbook, parse_school, plan, placement and figure 3. Its nine failures are listed in D105.
   A case that failed on more than one night is named as such; it is the strongest evidence for a fault rather than a strict
   grade.
2. **The morning plan jobs and their calls** (`ai_generations` by `job_id`): steps, repairs, refusals, cost. The first
   scheduled one on Phase 20's code ran at 05:30 IST on 14 October: 12 calls, ₹4.85, no repair. So the read planned for
   Tuesday 20 October is done; read the latest mornings for anything refused or failed.
3. **The `alerts` rows since 14 October:** what was raised, emailed and pushed; whether any is a false alarm (Phase 19's to
   fix, D68).

**What is already true:**
- Production holds 0001 to 0056. The API (29e79fb) and the portal are at `main`'s head of 13 October, both in `bom1`.
- The prompts are at version 4 (brief 5, parse_school 3, plan and parse_textbook 3). Placements draft on Sonnet (D104,
  0056).
- `bun evals` costs about ₹10 a kind. A pull request that touches a shared file runs all nine kinds in CI, about ₹95. The
  nightly is about ₹34 at half price and is a measure, not a gate (D103).
- Phase 20 spent about ₹700 in real calls against ₹520 approved, almost all on eval runs. So the plan states the build's eval
  cost and how it batches shared-file changes.
- The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac: do production's setup yourself (D87). Real Claude
  calls for testing are allowed; be judicious.

**Your work:**

1. **Reality and the reads.** Check reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`). Get `bun check`
   green. Open `plan/sessions/042/ledger.md`. Do the reads above.
2. **Phase 21's boards,** on the design canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D), in a new row below row
   28 (y 82000).
   - First settle, from `docs/design/information-architecture.md` and the existing boards, which of Phase 21's states have
     no board. Those are drawn; a state an approved board already draws is not.
   - The candidates:
     - exam preparation running as one job across its days (being prepared, ready, the gap report changing the last days,
       a photo's marking waiting);
     - the reason asked when the tutor makes something again (D74's feedback) and keeping their own words in its place;
     - the words when a note is refused by its check;
     - the portal's cost report at 1280 and 390 (per kind, model, step and centre; by day and month; against D64's price;
       batched work shown at its half price);
     - a V1 result's PDF page, if V1's results move to the server's PDFs (D90's last half).
   - The tutor's words only, no technical words (D41). Show them to the owner in groups. Get each group approved and mirror
     it into `docs/design/` (the canvas memory's steps).
3. **`plan/phase-21-plan.md`,** with `superpowers:writing-plans`, in Phase 20's form.
   - **Task 1 is D105, the nightly's findings.** Take each failed case from the nightlies read:
     - fix the fault with a free `verify` rule where it can be computed (the brief's slip: its wrong answer is evaluated as
       the key's `proof` is; a plan's chapter must be one the request lists), else in the prompt with a version bump;
     - or rule the grader too strict and change the rubric or the case, with the reason in the ledger.

     Work test first. The kind's evals must be green (D103). Batch the prompt changes into one pull request where they share
     files, so CI runs all nine kinds once.
   - **The parent kinds** on the pipeline. Rubrics: facts from the record only, the parent's language and script, length,
     the tutor's own words carried whole. The planted test: a note naming a fact not in the record is refused. The Hindi and
     Kannada anchor sets need a native speaker the owner arranges: say what the speaker does and when, and hold no real
     student in the sets.
   - **The exam orchestrator** as one job with sub-steps: the split, the daily sets, the mock in the school's pattern, marking
     from a photo, and the gap report that adjusts the last days. The mock's marks must sum.
   - **Make's and V1's kinds** on the pipeline, each with its rubric, golden set and board.
   - **`generation_feedback`:** its table, policy and test (rule 6). It is written at an edit, at a regeneration with its
     reason, and at a replacement. It is read by the portal and by the eval set's growth.
   - **Batches** for the morning's plans, with the one-hour cache. Kinds made at a tap stay live.
   - **The standing cost report** in the portal's data. The session cost runs are retired as a practice, except one last
     run against Phase 20's to prove the report.
   - **For every task:** test first, the review focus, the hand runs (D32), and the pictures (D7: `tools/shots.ts` for the
     app, `bun admin-shots` for the portal).
   - **The build's real-call budget,** with its parts (evals by kind, the hand runs, the cost proof). It is the owner's
     question, asked once with a recommendation.
   - **Phase 20's lessons, written in:**
     - the full `bun check` before every push;
     - never the API's database tests during a hand run (they clear the local jobs table);
     - restart the API after a branch switch (`--hot` keeps old modules);
     - deploy before TestFlight while migrations are pending.

   Decide what is yours to decide and say so; ask the owner only what is his.
4. **Close.** Write `plan/resume/041-phase-21-build.md` (Opus 5.5) and index it in `plan/resume/README.md`. Write the
   session's record and owner messages, update `STATE.md`, and commit to `main` (D12). Stop for the owner's review of the
   plan.

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy, what
  a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41): "LaTeX", "render", "model", "agent" and
  "eval" never reach a screen.
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55); the golden and anchor sets use the seed's names.
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1).
