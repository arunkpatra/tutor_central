# Resume 039: Phase 20 (V3 AI quality, the material), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). Session 40 drew Phase 20's 15 boards (row 28 of the canvas) and wrote
`plan/phase-20-plan.md` with D99 to D102; the owner approved both ("Boards approved, go ahead with the plan"). This session builds the phase from the plan, task by
task, in pull requests, with the hand runs, the cost run, the review and the documents.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D102). Phases 17 to 19 are built and
deployed: the jobs and the recorded call, the server's work and push, the admin portal and the alerts. Phase 20 makes the
material good: an agent per kind with a checking step, prompts versioned, evals gated in CI, a nightly eval, and mathematics
drawn properly on the phone and in the PDFs. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `admin/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D102; D35 the SDK, D59 figures as specs, D62 group kinds,
   D67 `models.json`, D73 to D75 the agents, the evals and mathematics, D76 the recorded call, D83 the platform's identity,
   D84 idempotency keys, D86 merge on local green, D87 production through the signed-in CLIs, D89 Typst, D90 and D93 the
   server's PDFs, D99 to D102 this phase's decisions).
3. `plan/phase-20-plan.md` whole: the goal, the constraints, the 22 decisions, the review focus, the file structure, the
   14 pull requests, the order, Tasks 1 to 18, the cost, the self-review. It is the work order. `plan/phase-20-ai-quality-material.md`
   is the scope and acceptance.
4. The boards: "Phase 20 boards" in `docs/design/information-architecture.md` and "Phase 20 parts" in `docs/design/components.md`;
   the sources `docs/design/mockups/P20-*.dc.html` (render one with headless Chrome when you need to see it: the canvas memory's
   command in `docs/design/README.md`'s neighbours, or `tools/web-shots.ts`'s client).
5. `plan/sessions/040/record.md` and `ledger.md` (this plan's session: the production reads, what was decided and why),
   `plan/sessions/039/ledger.md` (Phase 19's build: the form the ledger keeps).
6. The code the plan changes: `api/src/claude.ts`, `models.ts`, `price.ts`, `db.ts`, `routes/common.ts`, `jobs/call.ts`,
   `make.ts`, `prompts/*.ts`, `pdf/*.ts`, `jobs/kinds/plan.ts`, `pdf.ts`; `supabase/migrations/20261109000035_v3_review_fixes.sql`
   (`start_ai_call` as it stands), `20261121000047_v3_admin_reads.sql` and `20261124000050_v3_admin_reads_review.sql` (the
   functions 0052 re-creates); `ios/TutorCentralKit/Sources/DesignSystem/Components/BoardView.swift`, `PaperCard.swift`,
   `PDF/PDFMaker.swift`, `Kit/KitPhase10.swift`, `Features/Artefacts/*`, `Data/AI/APIClient.swift`, `AppShell/LaunchState.swift`.

**What is already true:** production holds migrations 0001 to 0051; the API at `bf4af37` and the portal at `5cc7b7b` are live in
`bom1`; TestFlight has 1.0.0 (29). The owner's centre has one live batch, meeting on Tuesdays; the first morning plan job with
material is Tuesday 20 October's unless the owner asked for the plan again (Task 1 says how to read it). `bun check` is green on
`main`. Vercel is on Pro (D98); Supabase is on Free (D85). Git deploys are off on all three Vercel projects: deploys only through
`deploy.yml`, `deploy-web.yml` and `deploy-admin.yml`. The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac: set
the one new secret (`ANTHROPIC_API_KEY` for `evals.yml`, from `api/.env.local`, piped) yourself (D87). Real Claude calls for
testing are allowed without asking; be judicious: the plan's budget is about ₹120 for the phase, said in the ledger as spent.
The cost of a call is in `bun cost` and on the portal's Cost page.

**Your work:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; open `plan/sessions/041/ledger.md`
   with the setup lines. Task 1's read of the first material plan job (or the owner's word that he asked for the plan again,
   and then the read); a Phase 18 fault found there is fixed first (D68).
2. The plan's Tasks 2 to 14 in its order, each test first (RED, then GREEN, the ledger line with the counts), one pull request
   each as the table says, merged on local green (D86), with the pictures (D7: `bun shots <state>` for the app, `bun admin-shots`
   for the portal, the PDF pages photographed) by `bun pr-shots`. Deploy A after PR 4 (0052 and the API), Deploy B after PR 8
   (the PDFs); `deploy-admin` after PR 10. Each board is compared side by side with its picture before the PR (a contact sheet in
   the scratchpad); a difference is fixed in that PR.
3. Task 15's ten hand runs by `docs/runbooks/simulator.md` (D32) on the local stack with the real models and the worker, the
   pictures on one issue, each finding fixed with a test that fails first (D68). Task 16: build 30 and the owner's one step.
   Task 17: the cost run against Phase 15's figures, in the ledger and the phase file. Task 12's first production night read
   the morning after.
4. Task 18: the review on Fable 5.1 (two fresh reviewers as Phase 19's), every finding fixed; the rule files (D80); "As built";
   `plan/README.md` (Phase 20 built); `STATE.md`; `plan/sessions/041/{record,owner-messages,ledger}.md`; commit the documents to
   `main` (D12). Stop. The next resume (Phase 21's boards and plan, on Fable 5.1) is written when the owner asks.

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy, what
  a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41): "LaTeX", "render", "model", "agent" and
  "eval" never reach a screen.
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55); the golden sets use the seed's names.
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1): the 15 boards of row 28; a state they do not draw keeps Phase 10's.
