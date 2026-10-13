# Phase 19: V3 the admin portal, reading

**Status:** Boards approved and plan written (session 38, 2026-10-13): the 60 boards of row 27 (`docs/design/mockups/P19-*`, "Phase 19 boards" in `docs/design/information-architecture.md`); `phase-19-plan.md` (18 tasks, 16 pull requests, decisions 1 to 24, D94 to D96) awaits the owner's review; the build runs from `resume/037-phase-19-build.md` on Opus 5.5. **Depends on:** Phase 17 (the tables); Phase 18 (the jobs the portal reads).

## Goal

The owner signs in to the admin portal and sees what is happening: centres, activity, cost, the AI calls, the jobs, the
errors, the alerts.

## Scope

1. **Boards** for each screen and state, on the canvas and mirrored in `docs/design/` (the portal may use the trade's words,
   D41 being for tutors): sign-in and the second factor, the centres list, a centre, cost, generations, jobs, errors, alerts,
   the audit.
2. **The app** (D78): `admin/` beside `web/`, Next.js with server code, Bun (D16), Biome, pinned dependencies (D14); a third
   Vercel project at a tutorcentral.in subdomain, git deploys off, deployed only by `deploy-admin.yml` (D21's shape) with its
   smoke; `admin/CLAUDE.md`; `bun check` gains an `admin` step.
3. **Sign-in** (D78): the same Supabase Auth; `admin_users` allows the account; TOTP enrolled and required (`aal2` on the
   server on each request); the service-role key in the portal's server environment only; every data read in server code
   behind the admin check.
4. **Audit** (D77, D78): `admin_audit` written on each action and each open of a centre's record; shown in the portal.
5. **Pages:** centres and their tutors (name and email; no parent's number); activity from `events`; usage and cost per centre,
   kind, model and day against the allowance and D64's ₹499; the AI calls with prompt version, tokens, latency, outcome and
   fallback; jobs and steps with retry and cancel; API errors by route and reason; alerts.
6. **Alerts** (D77): thresholds (failed jobs, a centre's cost a day, the error rate, a stuck job) evaluated by a job; sent by
   email through Resend (D30) and a push to the owner's device; acknowledged in the portal.

## Acceptance

- The owner signs in with his second factor and sees the production centres' cost and jobs; a read of a centre's record is in
  the audit; an admin account without `aal2` is refused.
- The service-role key appears in no client bundle (a test reads the build output).
- A failed job raises an alert that reaches the owner's email and phone.
- Pictures of each page and state at 1280 and 390 (D7, by `bun web-shots`' method); the smoke green.
