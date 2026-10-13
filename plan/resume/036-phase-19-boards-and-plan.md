# Resume 036: Phase 19 (V3 the admin portal, reading), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 18 is built and deployed (0001 to 0045, 1.0.0 (29) on TestFlight). Phase 19 is a
new app, the admin portal, and every one of its pages is new on screen, so its boards come first (rule 1; boards before the
plan, the owner's 2026-10-11 rule): this session draws the portal's boards on the design canvas, gets them approved, mirrors
them into `docs/design/`, then writes `plan/phase-19-plan.md` and the build's resume prompt, and stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D93). Phase 17 laid the foundation (jobs run
by the API's worker, every paid call recorded once, request ids, our own observability tables, a gated deploy); Phase 18 moved
the phone's platform work onto the server (the plan and its material, the note day, PDFs, the export, the sweep) and reaches
the iPhone through APNs. Phase 19 gives the owner the eyes: an admin portal that reads all of it. Read, in this order, before
doing anything:

1. `CLAUDE.md`, then `web/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D93; D77 observability, D78 the portal, D79 DPDP, D82 data and
   analytics, D83 the platform's identity, D85 no paid plan yet, D86 merge on local green, D87 production's setup through the
   signed-in CLIs, D88 APNs).
3. `plan/phase-19-admin-portal-reading.md` (the scope and acceptance), `docs/spec-v3.md` sections 8 to 11 (privacy, observability,
   the portal, data and analytics), `plan/phase-18-server-work-and-push.md`'s "As built".
4. `plan/sessions/037/record.md` and `ledger.md` (Phase 18's build: what the jobs write, what the reviews found),
   `plan/phase-18-plan.md` (the plan's form to follow), and Phase 8's website as the model for a Next.js app here:
   `plan/phase-08-website.md`'s "As built", `web/`, `.github/workflows/deploy-web.yml`, `tools/web-shots.ts` (D44 to D49).
5. What the portal reads: migrations 0028 (`jobs`, `job_steps`), 0029 and 0035 (`ai_generations`, `start_ai_call`), 0030
   (`events`, `api_requests`, `alerts`, `admin_audit`), 0031 (`device_tokens`), 0038 (`notifications`), `api/models.json`,
   `api/src/observe.ts`, and the RLS tests' catalogue (`supabase/tests/rls.test.ts`: the security definer functions stay four).

**First, before the boards:** read the owner's centre's first morning plan job on the server (13 October, 05:30 India time) with
`supabase db query --linked`: its steps, made and not made, any failure, its cost. Put it in the ledger and in one line to the
owner. A failure there is Phase 18's to fix (D68) before Phase 19 starts.

**What is already true:** production holds 0001 to 0045 and the API at `6d973b9` (Deploy 2, run 38311560782); the worker,
APNs and Typst are live; Vercel Hobby and Supabase Free (D85). The tables the portal reads exist and are written: `alerts` and
`admin_audit` exist with no writer yet and no member access. The website is `web/` on Vercel `tutor-central-web`, deployed only
by `deploy-web.yml`; tutorcentral.in's DNS is at GoDaddy (no CLI: a subdomain record is an owner step). The Supabase, Vercel and
GitHub CLIs are signed in on the owner's Mac: do production's setup yourself (D87); ask the owner only for what no CLI can do
(a DNS record at GoDaddy, enrolling his TOTP authenticator).

**Your work:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; open `plan/sessions/038/ledger.md`;
   the morning plan job above.
2. The portal's boards, on the design canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, a new row below row 26), as
   fluid pages at 1280 and 390 like Phase 8's (both appearances where the page has both): sign-in and the second factor
   (enrol, verify, refused without it), the centres list, a centre (its tutors, activity, cost, the audited open of its
   record), cost (per centre, kind, model and day against the allowance and D64's ₹499), the AI calls, jobs and their steps
   (with retry and cancel), errors by route and reason, alerts (with acknowledge), and the audit. The trade's words are allowed
   (no tutor reads the portal); never a parent's number, a student's name only on an audited open (D79). Show them to the owner
   in groups, get each group approved, mirror each approved board into `docs/design/` (the canvas memory's steps).
3. `plan/phase-19-plan.md` with `superpowers:writing-plans`, in Phase 18's form: `admin/` (Next.js with server code, Bun,
   Biome, pinned dependencies with a decision for each new one), the third Vercel project and `deploy-admin.yml` with its
   smoke, `bun check`'s `admin` step; sign-in (`admin_users`, TOTP, `aal2` on every server request, the service-role key in
   server code only and a test that reads the build output for it); the audit; each page's queries; the alerts job
   (thresholds, Resend email, a push to the owner's device through the outbox); each task test first, the review focus, the
   hand runs (D32), the pictures for each page and state (D7, `bun web-shots`' method), the owner's steps written as exact
   numbered actions. Decide what is yours to decide and say so; ask the owner only what is his.
4. Write `plan/resume/037-phase-19-build.md` (Opus 5.5) and index both in `plan/resume/README.md`; the session's record and
   owner messages; `STATE.md`; to `main` (D12). Stop for the owner's review of the plan.

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and its
reasons; decide the rest and say so; any step the owner must take is a numbered list of exact actions (the site, each menu
item by its label, what to copy, what a prompt asks, what success shows); plain voice in documents; no technical words in
anything a tutor reads (D41); no secret in the repository (D11), and a secret is piped straight to its store, never printed
(D87); no tutor's name, email or number in it (D55); decisions are never reopened, a change gets a new number; a phase fixes
what it finds (D68).
