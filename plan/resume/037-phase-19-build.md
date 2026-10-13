# Resume 037: Phase 19 (V3 the admin portal, reading), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan is approved; the boards are approved and mirrored. The session builds the
whole phase, task by task, inline, with one ledger, and ends with the portal live at admin.tutorcentral.in, the owner signed
in with his second factor, a real alert received, the review's findings fixed, and the documents on `main`.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight, build 29). V3 is the platform under them (`docs/spec-v3.md`, D70 to D96). Phases 17 and 18 put the
work on the server (jobs run by the API's worker, every paid call recorded, request ids, the observability tables, APNs).
Phase 19 gives the owner the eyes: `admin/`, a Next.js portal that reads all of it behind a second factor, and an alerts
job that reaches him by email and push. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `web/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D96; D77 observability, D78 the portal, D79 DPDP, D83 the
   platform's identity, D85 no paid plan, D86 merge on local green, D87 production's setup through the signed-in CLIs, D94
   to D96 this phase's).
3. `plan/phase-19-plan.md`, whole: the goal, the constraints, decisions 1 to 24, the review focus, the file structure,
   the pull requests, the order, Tasks 1 to 18, the cost. It is the work order; this prompt only points at it.
4. `plan/phase-19-admin-portal-reading.md` (the scope and acceptance), `docs/spec-v3.md` sections 8 to 11, the boards:
   "Phase 19 boards" and "Phase 19 parts" in `docs/design/information-architecture.md` and `components.md`, and the
   sources `docs/design/mockups/P19-*.dc.html` (a page's CSS is copied from its board's helmet, plan Task 4).
5. `plan/sessions/038/record.md` and `ledger.md` (why the boards and the plan are as they are; the morning job's reading),
   `plan/sessions/037/ledger.md` (Phase 18's build: the jobs, the outbox, what the reviews found).
6. The code the plan builds on: `web/` (the Next.js app the portal copies its shape from), `tools/web-shots.ts` (`cdp`,
   `sideways`), `tools/web-smoke.ts`, `.github/workflows/deploy-web.yml` and `deploy.yml` (the gate job),
   `tools/check/steps.ts`, `tools/check-gate.ts`; migrations 0028 to 0030, 0035, 0038, 0039, 0045; `api/src/jobs/`
   (`types.ts`, `runner.ts`, `kinds/sweep.ts`, `kinds/index.ts`, `db.ts`), `api/src/push/db.ts`, `api/src/routes/jobs.ts`,
   `api/src/env.ts`, `api/src/index.ts`; `supabase/tests/client.ts`, `jobs.test.ts`, `rls.test.ts`.

**What is already true:** production holds 0001 to 0045 and the API at `6d973b9`; the worker, APNs and Typst are live;
Vercel Hobby and Supabase Free (D85); `alerts` and `admin_audit` exist with no writer and no member access; `job_kind`
has no `alerts`; `notifications.kind` has no `alert`. The website is `web/` on Vercel `tutor-central-web`; tutorcentral.in's
DNS is at GoDaddy (an owner step). The Supabase (linked to production), Vercel (`api/` linked) and GitHub CLIs are signed
in on the owner's Mac: production's setup is yours (D87), and a secret is piped straight to its store, never printed.
The owner's own device token exists in production once he has build 28 or 29 with reminders on (ask, Task 1 E).

**Your work:** `plan/phase-19-plan.md`, Tasks 1 to 18 in "The order", each task test first, each pull request merged on
local green (D86) with its pictures (D7, by `bun admin-shots` once it exists, `bun pr-shots`); the ledger
`plan/sessions/039/ledger.md` written by hand after each named test run (a ruling with its cost if wrong; a finding with
its fix); Task 1's owner steps sent exactly as written, one list per message, A and B in your first message; Deploy A
after PR 12, the portal's first deploy after PR 14; the hand runs by the new runbook; Task 17 in production with the
owner; the review with every finding fixed (D68); the trust page's sentence; the rule files; "As built"; `STATE.md`;
`plan/sessions/039/{record,owner-messages}.md`; documents to `main` (D12). Stop when Phase 19 is done or when the owner
must act and has not yet.

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and
its reasons; decide the rest and say so in the ledger; any step the owner must take is the plan's numbered list, exact; plain
voice in documents; no technical words in anything a tutor reads (D41: the alert push and the trust page); no secret in the
repository (D11, D87); no tutor's name, email or number in it (D55: the admin's and the owner's emails are typed at prompts
and read into commands, never written to a file); decisions are never reopened, a change gets a new number; a phase fixes
what it finds (D68); polish seen on screen goes on `plan/ui-polish.md`, not into the change in hand.
