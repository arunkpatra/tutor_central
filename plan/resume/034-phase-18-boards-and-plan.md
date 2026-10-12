# Resume 034: Phase 18 (V3 the server's work and push), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 17 is built and deployed (1.0.0 (27), the worker live in production). Phase 18
changes what is on screen in three places, so its boards come first (rule 1; boards before the plan, the owner's 2026-10-11
rule): this session draws the three boards on the design canvas, gets each approved, mirrors them into `docs/design/`, then
writes `plan/phase-18-plan.md` and the build's resume prompt, and stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (built, on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D87). Phase 17 laid its foundation:
jobs in Postgres run by the API's worker (woken each minute by pg_cron and when queued), every paid call recorded once through
`start_ai_call` with an idempotency key, request ids and our own observability tables, a generated contract, a deploy gated on
a green check with a real smoke, and a first `plan` job that reads, groups, names and writes a batch's plan. Phase 18 moves the
phone's platform work onto the server as jobs and reaches the phone through APNs. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`, `docs/design/README.md`,
   `docs/design/feedback.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D87; D70 to D82 are V3's; D83 the platform's identity, D84 the
   keys, D85 no paid plan yet, D86 merge on local green, D87 the session runs production's setup through the signed-in CLIs).
3. `plan/phase-18-server-work-and-push.md` (the scope and acceptance), `docs/spec-v3.md` sections on jobs, push, the phone's
   retirements, one data layer and DPDP (D70 to D72, D76, D79), and `plan/phase-17-platform-foundation.md`'s "As built".
4. `plan/sessions/035/record.md` and `ledger.md` (Phase 17's build: every ruling, what the reviews found, what the plan job
   leaves to the phone), `plan/phase-17-plan.md` (the plan's form to follow), `plan/sessions/034/record.md`.
5. What Phase 18 builds on: `api/src/jobs/` (runner, types, `kinds/plan.ts`, `record.ts`, `call.ts`), `api/src/plan/` (the
   ported rules), `api/src/routes/jobs.ts`; migrations 0028 (jobs), 0029 (`start_ai_call`), 0031 (`device_tokens`), 0032
   (`consent_events`), 0034 (the wakes), 0035 (no member queues a job yet); on the phone `Features/Today/PlanMaker*.swift`,
   `PlanStore`, `AppShell/ReminderScheduler*.swift`, `BackgroundRefresh`, `PDFMaker`, `Domain/Plan/ArtefactBudget.swift`,
   `SpacedQueue.swift`, `ExamPreparation.swift` (what Phase 17 did not port), the student's page and its consent rows.

**What is already true:** production holds 0001 to 0035 and the API at `a3c6012` with the worker answering its minute tick;
Vercel Hobby and Supabase Free (D85: the worker's run budget 200 s under 300 s); the Smoke centre takes the deploy's one real
check; `run-job.yml` queues a plan job by hand. The plan job never replaces a plan the phone made, leaves exam weeks and
holidays to the phone, and the phone still makes the material on open: Phase 18 moves the material (`ArtefactBudget`,
`SpacedQueue`, the exam split) onto the job and retires `PlanMaker`. `enqueue_job` is granted to no member (0035): the
screens Phase 18 adds grant what they need, limited to their kinds and the centre's own batches. The Supabase, Vercel and
GitHub CLIs are signed in on the owner's Mac: do production's setup yourself (D87); ask the owner only for what no CLI can
do (the APNs `.p8` key is made in his Apple developer account).

**Your work:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; open
   `plan/sessions/036/ledger.md`.
2. The three boards, on the design canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, a new row below row 25), drawn
   to the design system and the existing boards' grammar, both appearances where the screen has both:
   - **Consent withdrawn** on the student's page (the withdrawal recorded as an event, what stops at once, how to give it
     again);
   - **The export** on the student's page (asked, being made, ready to share, failed), the file a tutor shares;
   - **Plan ready**: the notification's words and what Today shows for a plan the server made before the batch (and while
     its material is still being made).
   Words from `docs/design/feedback.md`, no technical words (D41). Show each to the owner and get it approved before the next;
   mirror each approved board into `docs/design/` (the canvas memory's steps).
3. `plan/phase-18-plan.md` with `superpowers:writing-plans`, in Phase 17's form: the jobs (`plan` with its material as steps,
   `note_day`, `reminder_sweep`, `pdf`, `export`, the sweep's Storage clean-up), the schedules written by pg_cron, push (the
   device token, `@parse/node-apn` pinned with a decision, the 410 retirement, the background push), the phone's
   retirements, one data layer (U10, U27), DPDP on screen; each task test first, the review focus, the hand runs (D32), the
   pictures for each changed state (D7), the cost of the real calls, the owner's steps written as exact numbered actions.
4. Write `plan/resume/035-phase-18-build.md` (Opus 5.5) and index both in `plan/resume/README.md`; the session's record and
   owner messages; `STATE.md`; to `main` (D12). Stop for the owner's review of the plan.

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and its
reasons; decide the rest and say so; any step the owner must take is a numbered list of exact actions (the site, each menu
item by its label, what to copy, what a prompt asks, what success shows); plain voice in documents; no technical words in
anything a tutor reads (D41); no secret in the repository (D11); no tutor's name, email or number in it (D55); decisions are
never reopened, a change gets a new number; a phase fixes what it finds (D68).
