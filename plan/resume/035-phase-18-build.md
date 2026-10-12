# Resume 035: Phase 18 (V3 the server's work and push), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan is `plan/phase-18-plan.md`, written in session 36 and approved by the owner;
its 14 boards are row 26 of the canvas, approved and mirrored (`docs/design/mockups/P18-*`). This session builds the phase's
22 pull requests, tests first, runs Deploy 1, the hand runs and the real-model proofs, has the work reviewed, runs Deploy 2,
ships build 28 and writes the documents. One session per slice if the context runs long (`plan/SESSIONS.md`); this prompt is
pasted again at each.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (built, on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D92). Phase 17 laid the foundation
(jobs in Postgres run by the API's worker, the recorded call with keys, the observability tables, the contract, the gated
deploy, a first `plan` job). Phase 18 moves the phone's platform work onto the server as jobs and reaches the phone through
APNs. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`, `docs/design/README.md`,
   `docs/design/feedback.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D92; D88 the APNs library, D89 Typst now, D90 what the
   server's PDF covers, D91 automatic work only for a centre in use, D92 the export kept seven days).
3. `plan/phase-18-plan.md` in full: the goal, the constraints, the 28 decisions, the review focus, the file structure, the
   pull requests, the order, Tasks 1 to 25, the cost, the self-review. Then `plan/phase-18-server-work-and-push.md` (scope and
   acceptance), "Phase 18 boards" in `docs/design/information-architecture.md` and "Phase 18 parts" in `components.md`, and
   the boards themselves on the canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 26).
4. `plan/sessions/036/record.md` (this plan's session), `plan/sessions/035/ledger.md` (Phase 17's build: the ledger's form,
   its rulings), `docs/runbooks/simulator.md` (D32).
5. What the phase builds on: `api/src/jobs/` (runner, types, call, record, db, `kinds/plan.ts`, `kinds/sweep.ts`),
   `api/src/plan/`, `api/src/routes/v2.ts`, `routes/jobs.ts`, `index.ts`; migrations 0028 to 0035; `supabase/tests/jobs.test.ts`
   (the style); on the phone `Features/Today/PlanMaker*.swift`, `PlanStore*.swift`, `Domain/Plan/ArtefactBudget.swift`,
   `Domain/Record/SpacedQueue.swift`, `Domain/School/ExamPreparation.swift`, `Domain/Reminders/ReminderPlanner.swift`,
   `Domain/Parents/NoteFacts.swift` and `CanDoFacts.swift`, `AppShell/ReminderScheduler.swift`, `RefreshHandler.swift`,
   `Data/Refresh/BackgroundRefresh.swift`, `DesignSystem/PDF/PDFMaker.swift`, `Features/Students/Consent*.swift`,
   `Features/Artefacts/NoteStore+Make.swift`, `Data/Cache/CachedRead.swift`, `Features/Attendance/AttendanceStore*.swift`.

**What is already true:** production holds 0001 to 0035 and the API at `a3c6012`, Vercel Hobby and Supabase Free (D85);
the Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac and you run production's setup yourself (D87),
piping a secret straight to its store, never printing it; the owner is asked only for Task 1 (the APNs key and the App ID's
push in his Apple developer account), with the plan's numbered list as it stands. Real AI calls in testing are allowed
without asking (this phase's: about ₹5, the plan's "The cost"); the owner's own centre's plan job will run each morning in
production after Deploy 1 (D91), and its cost goes in the ledger. The owner tests the builds at the end of V3 (D68): his
device checks are T16 and T17, not steps now.

**Your work, in the plan's order:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; open
   `plan/sessions/037/ledger.md` with the setup lines. Send the owner Task 1's numbered list in your first message and go on
   with Task 2; when he replies with the Key ID, set the four `APNS_*` variables on Vercel and in `api/.env.local` yourself.
2. PRs 1 to 5 (Tasks 2 to 6), the migrations; PRs 6 to 15 (Tasks 7 to 16), the API: branch `phase-18/<slug>` from `main`,
   the failing tests first and run to see them fail, the change, `bun check` green, the pull request described by what it
   does and how it was checked, merged on local green (D86). Then Deploy 1 and its checks (Task 16's last item).
3. PRs 16 to 22 (Tasks 17 to 23), the app and the web, each to its boards, with the pictures of every changed state, both
   appearances where the board has both, by `bun shots` and `bun pr-shots` (D7).
4. Task 24's hand runs after PR 21, each write confirmed in the database, the pictures on one issue; a fault fixed in its own
   pull request with a test first (D68); the cost record.
5. Task 25: the review on Fable 5.1 (two fresh reviewers, the plan's review focus and the ledger's rulings), every finding
   fixed (D68), Deploy 2, `gh workflow run testflight` (build 28), T16 and T17, the rule files (D80), "As built" in
   `plan/phase-18-server-work-and-push.md`, `plan/README.md`, `plan/STATE.md`, the session's record, ledger and owner
   messages, to `main` (D12). Then ask the owner whether to write the next resume (Phase 19, the admin portal: boards first).

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and its
reasons; decide the rest and say so; any step the owner must take is a numbered list of exact actions (the site, each menu
item by its label, what to copy, what a prompt asks, what success shows); plain voice in documents; no technical words in
anything a tutor reads (D41); no secret in the repository (D11); no tutor's name, email or number in it (D55); decisions are
never reopened, a change gets a new number; a phase fixes what it finds (D68).
