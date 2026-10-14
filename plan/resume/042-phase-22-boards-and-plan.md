# Resume 042: Phase 22 (V3 the admin portal, control and analytics), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus).

Phase 21 is built and deployed:
- The parents' kinds, the exam kinds, and Make's and V1's kinds run on their agents.
- The exam runs as one job.
- Feedback and the reasons menus are in; the morning's plans go through Message Batches with the hour's cache; the standing
  cost report is on the portal.
- Migrations 0001 to 0065 are in production; the API is at 69d8389.
- The owner checked 1.0.0 (31) on 14 October ("build 31 fine").
- D112 holds: no automation spends on AI calls.

Phase 22 puts the platform's controls and its product figures in the portal, and brings the DPDP retention rule into force.
It adds pages and states the portal and the website do not yet have, so its boards come first (rule 1; boards before the
plan, the owner's 2026-10-11 rule). This session:
1. reads production;
2. draws the boards, gets them approved and mirrors them;
3. writes `plan/phase-22-plan.md` and the build's resume prompt;
4. stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D112). Phase 19 built the portal's reading
pages; Phases 20 and 21 put every AI kind on its agent and made cost a standing report. Phase 22 is V3's last phase. After it
come the external testing round, then Phase 16 (D81).

Read, in this order, before doing anything:

1. `CLAUDE.md`, then `admin/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`, `ios/CLAUDE.md`,
   `docs/design/README.md`, `docs/working/pre-pr-proof.md`, `docs/working/testing.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D112). In particular:
   - D64 the price; D67 `models.json`; D68 a phase fixes what it finds; D73 an agent per kind; D74 prompts, evals and
     feedback;
   - D76 the recorded call; D78 the portal; D79 privacy and retention; D81 the order; D82 analytics; D86 merge on local
     green; D87 production through the signed-in CLIs;
   - D94 to D98 Phase 19's; D100 the kill switch in `ai_models`; D107 feedback; D109 the cost report; D112 no automatic
     paid AI calls.
3. `plan/phase-22-admin-portal-control.md` (the scope and acceptance) and `docs/spec-v3.md` sections 8 (privacy and the DPDP
   Act), 10 (the admin portal), 11 (data and analytics) and 13 (cost and money). Also each "As built" in
   `plan/phase-19-admin-portal-reading.md`, `plan/phase-20-ai-quality-material.md` and
   `plan/phase-21-ai-quality-parents-and-exams.md`.
4. `plan/sessions/043/record.md` and `ledger.md` (Phase 21's build: the findings, the rulings, the mistakes), and
   `plan/phase-21-plan.md` (the plan's form to follow).
5. What Phase 22 touches:
   - `admin/` (its pages, `content/`, `lib/data*`, the gate and the second factor, preview mode, `bun admin-shots`);
   - the `admin_*` functions (0047, 0048, 0061) and the audit (`admin_audit_write`, `admin_open_record`);
   - `ai_models` (0052, append-only; the newest row of a kind and step is current, read each minute);
   - `centres.ai_allowance` and `ai_allowance_paise`; the alert lines (`api/src/alerts/lines.ts`, still in code);
   - the `sweep` job (`api/src/jobs/kinds/sweep.ts`); `web/`'s trust page;
   - the Phase 19 boards (`docs/design/mockups/P19-*`) and P21-Cost, the frame the new pages join.

**First, before the boards:** read production with `supabase db query --linked`. Put each read in
`plan/sessions/044/ledger.md`, with one line to the owner.

1. **The morning plan jobs since 15 October,** the first mornings by Message Batches (D108, D111, plan time 00:05 IST): per
   job, the steps, how long the batches took, the rows batched and priced at half, repairs, refusals, the deadline's live
   fallback if any, and cost against Phase 21's local ₹6.34 for two plans.
2. **The exam jobs (`exam_prep`)** and their gap reports, if any exam is in its window; and the replaced plans after a
   report (#344: a replace is live; its material replays at no cost).
3. **`generation_feedback` since 14 October:** counts by kind and reason. Never print a revised text; it may hold a parent's
   message (D55). Then `bun feedback-cases --since 7d` to see whether the eval sets have candidates.
4. **The `alerts` rows since 14 October:** what was raised, emailed and pushed, and any false alarm (D68).

**What is already true:**
- The kill switch exists: an `ai_models` row with `enabled` false refuses with the kind's words (D100). The portal only
  reads that table today; Phase 22's control page writes it, append-only, with its history.
- The allowance lives on `centres`: `ai_allowance` is calls a month and `ai_allowance_paise` the month's cost. Members cannot
  update it; today the session sets it by SQL.
- The alert lines are four constants in `api/src/alerts/lines.ts`; Phase 19 said "The lines change in Phase 22."
- The Cost page is the cost figure since Phase 21. No session runs a cost run any more (D109).
- The golden sets and the `eval_run` job run by hand only (D112). A portal button that a person presses to run them would be
  a human trigger, so D112 allows it. Whether to add one is the owner's call; ask him, with a recommendation.
- The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac: do production's setup yourself (D87).

**Phase 21 left these for Phase 22,** each in the session 43 ledger. Rule each in or out in the plan:
- **R-api-4:** an exam reaching two batches that meet on different days shows the first batch's split on its page. Each
  batch's plan follows its own days. The job writes one split, to `school_items.preparation`, for the first reached student.
- **The call page's Feedback row:** `admin_call` returns a call's feedback rows (kind, reason, time; never the revised text),
  but no board draws them yet.
- **The per-centre month figure** (`admin_cost_by_month`) counts the Smoke centre as an active centre.
- **Phase 19's known gap:** an alert push that failed is not retried.
- **U53 on `plan/ui-polish.md`:** a polish row, the owner's to take.

**Your work:**

1. **Reality and the reads.** Check reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`). Get `bun check`
   green. Open `plan/sessions/044/ledger.md`. Do the reads above.
2. **Phase 22's boards,** on the design canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D), in a new row below row
   29 (y 83600), at 1280 and 390 as Phase 19's.
   - First settle, from `docs/design/information-architecture.md` and the existing boards, which states have no board.
     Draw those; a state an approved board already draws is not drawn again.
   - The candidates:
     - **Controls:** a kind's model, effort, fallback and on/off with its history; a centre's allowance; the alert lines;
       a read-only view of the syllabus data.
     - **Support within consent:** an audited open with its reason; a student's record and the outputs made about them,
       never a parent's number, a photo, or an input whose consent is not current.
     - **Analytics:** tutors active a week, closes, plans made and followed, notes sent, artefacts made and made again with
       their reasons, Make's use, consent given, cost per active tutor; the weekly report as a page and as an email.
     - **The call page's Feedback row.**
     - **The trust page's retention words** on the website.
     - **The tutor's words** when a kind is switched off or a centre's allowance is reached, if no approved board draws
       them yet.
   - The trade's words are allowed on the portal (D78). Anything a tutor reads uses no technical words (D41). Show the
     boards to the owner in groups. Get each group approved and mirror it into `docs/design/` (the canvas memory's steps).
     The canvas was at the Design type's 512-file limit in Phase 21: settle how this row fits before drawing.
3. **`plan/phase-22-plan.md`,** with `superpowers:writing-plans`, in Phase 21's form.
   - **Every write from the portal** goes through a named `security invoker` function granted to `service_role` alone, and
     writes its own audit row:
     - `ai_models` append-only, so the history is the table;
     - the allowance;
     - the alert lines, which move from code to a table the alerts job reads.
   - **A switch takes effect within a minute,** the model table's read. The acceptance: switched off refuses in the tutor's
     words, switched on works again, and the audit shows both.
   - **Retention (D79):** the `sweep` job reduces a personal kind's input to a reference after 90 days. The trust page's
     words change in the same phase (`web/`, with its smoke).
   - **Analytics:**
     - the figures come from the tables already kept, with no new collection on the phone unless D82 asks for it;
     - the weekly report's email goes through Resend as the alerts' does;
     - the report makes no AI call, or D112 rules it out.
   - **The round's documents** read once more against V3 (`docs/release.md`, `docs/testing/tester-guide.md`,
     `docs/testing/device-tests.md`): a push, a plan that arrives and an export become device tests.
   - **For every task:** test first, the review focus, the hand runs (D32, `docs/runbooks/admin.md` for the portal), the
     pictures (D7: `bun admin-shots` for the portal, `bun web-shots` for the website), and the pre-PR proof in each pull
     request's body.
   - **The build's real-call budget,** if any: evals only where a prompt, agent or schema changes (`bun evals-changed`).
     If the build needs one, it is the owner's question, asked once with a recommendation. Otherwise keep the count in the
     ledger without troubling him.
   - **Phase 21's lessons, written in:**
     - never a database test (`bun check`'s api or db step, `bun test` in `api/` or `supabase/`) while local jobs run; they
       clear the jobs and the calls;
     - before replacing a function, read every migration that defines it;
     - `git add` only the files a commit is for; documents never ride in a code commit;
     - a docs push to `main` cancels a pending check, so push documents after a deploy has its check;
     - zsh does not split a variable into words: pass file lists through `xargs`.

   Decide what is yours to decide and say so; ask the owner only what is his.
4. **Close.** Write `plan/resume/043-phase-22-build.md` (Opus 5.5) and index it in `plan/resume/README.md`. Write the
   session's record and owner messages, update `STATE.md`, and commit to `main` (D12). Stop for the owner's review of the
   plan.

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Keep count of costs in the ledger. Don't trouble the owner with cost details: the product is not designed around API
  costs, though it is designed for performance and correctness by construction.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy, what
  a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41).
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55).
- No automation spends on AI calls (D112).
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1).
