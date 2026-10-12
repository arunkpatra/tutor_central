# Resume 033: Phase 17 (V3 platform foundation), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan is `plan/phase-17-plan.md`, approved by the owner on 2026-10-12 with his
ruling on the paid plans (D85: none bought this phase). Nothing new is on screen (D6), so no board waits on it and no pull
request carries pictures. This session builds the phase's fifteen pull requests, tests first, runs the deploys, the owner's
production plan job, the hand runs and the restore drill, has the work reviewed, ships a TestFlight build with nothing new on
screen, and writes the documents. One session per slice if the context runs long (`plan/SESSIONS.md`); this prompt is pasted
again at each.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product and are built (1.0.0 (26) on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D85): the backend
is the platform and the app its presentation layer. Phase 17 lays the foundation: the job tables and the worker, the
recorded call with idempotency keys and the locked gate, the observability tables, the generated contract, the gated deploy
with a real smoke, CI's flakes, the restore drill. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D85; D70 to D82 are V3's, D83 the job key, D84 the
   idempotency keys, D85 the plans not bought).
3. `plan/phase-17-plan.md` in full: the goal, the constraints, the 28 decisions, the owner's ruling (D85), the review focus,
   the file structure, the pull requests, the order, Tasks 1 to 18, the self-review. Then `plan/phase-17-platform-foundation.md`
   (the scope and acceptance) and `docs/spec-v3.md` sections 3, 7, 9 and 12.
4. `plan/sessions/034/record.md` (this plan's session: what was decided and why), `plan/sessions/032/ledger.md` (Phase 15's
   build: the ledger's form, the double spends the keys remove), `docs/runbooks/simulator.md` (D32).
5. What the phase builds on: `api/src/routes/common.ts`, `claude.ts`, `db.ts`, `verify.ts`, `auth.ts`, `errors.ts`,
   `index.ts`, `make-app.ts`, `vercel.json`, `api/test/ai.test.ts` (the test style); `supabase/migrations/20261101000027_*.sql`
   (`start_ai_generation`'s body), `20261024000019_*.sql` (`make_plan`), `20261031000026_*.sql` (`keep_artefact`),
   `supabase/tests/rls.test.ts` and `client.ts`; `tools/check/steps.ts`, `tools/smoke.ts`, `.github/workflows/deploy.yml`,
   `check.yml`, `testflight.yml`, `seed-review.yml`; `ios/TutorCentralKit/Sources/Data/AI/APIClient.swift`, `APIFailure.swift`,
   `Data/Queue/QueueRunner.swift`, `Data/Cache/Wipe.swift`, `Data/Messages/SupabaseMessageLogRepository.swift`,
   `Data/Plans/SupabasePlansRepository.swift`, `Features/Today/PlanMaker*.swift` and `Domain/Plan/*` (what Task 12 ports),
   `Tests/DomainTests/PlanRulesTests*.swift` (the shared cases' source).

**What is already true:** production holds migrations 0001 to 0027 and the API at `54adb24`; Vercel is on Hobby and
Supabase on Free and both stay so this phase (D85: pg_cron and pg_net wake the worker from inside the database; `maxDuration`
300 and a 200 s run budget; no copy of the database exists until Pro is bought before the external testing round, said in
`STATE.md`); there is one environment (D80); `main` is clean at the commit that carries this prompt. The owner approved real
AI calls in testing without asking each time (be judicious: this phase's are the smoke's one `check` on Haiku per deploy, the
production plan job's naming call and two hand-run calls, under ₹5, each recorded in the ledger). The owner builds alone with
Claude and wants no question he can see the answer to: decide small and medium things, write each ruling in the ledger
with its cost if wrong, and say what you decided.

**Your work, in the plan's order:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; the ledger
   `plan/sessions/035/ledger.md` opened with the setup lines. Ask the owner for Owner step 1 (the smoke account, Task 2) in
   the session's first message and go on with Task 1 while he does it; Owner step 2 (the secrets and variables) after he
   says done; check each result before the next.
2. PRs 1 to 9 (Tasks 1, 3 to 10): branch `phase-17/<slug>` from `main`, the failing tests first and run to see them fail,
   the change, `bun check` green, the pull request described by what it does and how it was checked with "Nothing on screen
   changes; no pictures (D6, D7)", merged when CI is green. Then Deploy 1 (`gh workflow run deploy`): the gate's first real
   pass, 0028 to 0033 up, the smoke's `check` made.
3. PRs 10 to 12 (Tasks 11 to 13): the worker and the minute wake, the plan rules with the shared cases, the `plan` job and
   `run-job.yml`. Deploy 2. Then Owner step 3: his centre's first plan job for tomorrow, and the next morning's check on his
   iPhone.
4. PRs 13 to 15 (Tasks 14, 15, 17): the app's keys and idempotent writes, the events, the restore drill (run once; its first
   log line in the runbook). The hand runs of Task 16 after PRs 12 and 14, each write confirmed in the database, the
   screenshots on the phase's issue; a fault fixed in its own pull request with a test first (D68); the cost record.
5. Task 18: the review on Fable 5.1 (two fresh reviewers, the plan's review focus and the ledger's rulings), every finding
   fixed (D68), Deploy 3, `gh workflow run testflight` (nothing new on screen), the rule files (D80), "As built" in
   `plan/phase-17-platform-foundation.md`, `plan/README.md`, `plan/STATE.md`, the session's record, ledger and owner
   messages, to `main` (D12). Then write `plan/resume/034-phase-18-boards-and-plan.md` (Fable 5.1: Phase 18's three boards
   first, then its plan) and index it.

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and its
reasons; decide the rest and say so; plain voice in documents; no technical words in anything a tutor reads (D41); no secret
in the repository (D11); no tutor's name, email or number in it (D55: the owner's email and batch name are typed by him in
the chat for `run-job`, never written to a file); decisions are never reopened, a change gets a new number; a phase fixes
what it finds (D68).
