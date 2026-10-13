# Phase 19 plan: V3 the admin portal, reading

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-13 (session 38, Fable 5.1) from `phase-19-admin-portal-reading.md`, `docs/spec-v3.md` (sections 8 to 11),
Phase 18's "As built" and ledger (`plan/sessions/037/`), the 60 approved boards of row 27 (`docs/design/mockups/P19-*`,
"Phase 19 boards" in `docs/design/information-architecture.md`), Phase 8's website as the model of a Next.js app here, and
the code as it is. Shown whole to the owner for approval. The build runs on Opus 5.5 from `resume/037-phase-19-build.md`,
inline, task by task, with one ledger (`plan/sessions/038/ledger.md` continues as the build's record in
`plan/sessions/039/ledger.md`) as sessions 22 to 37 kept.

**Goal:** the owner signs in to `admin.tutorcentral.in` with his admin account and a code from his authenticator, and sees
what is happening on the platform: the centres and their tutors, each centre's activity and cost, the AI calls, the jobs
with their steps (a failed one retried, a live one cancelled), the API's errors by route and reason, the alerts, and the
audit of every admin action. A failed job, a centre's cost in a day, the error rate and a stuck job raise an alert that
reaches him by email and as a push on his iPhone. Every open of a centre's record is written to the audit with a reason;
no parent's number, photo or personal input without consent is ever shown.

**Architecture:** a third app, `admin/` (Next.js 16 with server code, beside `web/`), on a third Vercel project, deployed
only by `deploy-admin.yml`. Every read runs in server code as the platform (the service-role key in the portal's server
environment only, D83) through named `admin_*` database functions granted to `service_role` alone; every write (an
acknowledgement, a retry, a cancel, the audit) is a named function too. Sign-in is the same Supabase Auth with an
`admin_users` allow-list and a TOTP second factor: a request is served only when the session's assurance level is `aal2`
and the user is on the list, checked on the server for every page. The alerts are a job (`alerts`, each ten minutes,
queued by the tick as the sweep is) that reads one facts function, compares four lines, raises each alert once by key,
emails through Resend's HTTP API and queues a push through the outbox. Pictures come from a preview mode that renders every
page from fixtures outside production, photographed by `bun web-shots`' Chrome client.

**Tech stack:** as Phase 18 (Supabase CLI 2.120.0, Postgres 17, pg_cron; Bun 1.3.11; Hono 4.13.13, zod 4.6.5,
`@supabase/supabase-js` 2.117.2) plus, in `admin/`: Next.js 16.4.0, React 19.3.0, TypeScript 5.9.3, Biome 2.5.15 (the
website's versions, D44), `@supabase/supabase-js` 2.117.2, and one new dependency pinned with a decision (D14):
`@supabase/ssr` 0.12.7 (D94), the cookie-backed session for Next's server code. No new iOS dependency; no iOS change at
all. Vercel Hobby and Supabase Free stay (D85); TOTP is included in Supabase's basic MFA on every plan.

**Spec:** `docs/spec-v3.md` sections 8 (privacy: what an admin sees), 9 (observability: the tables), 10 (the admin portal),
11 (data and analytics, read only this phase); the scope `plan/phase-19-admin-portal-reading.md` (items 1 to 6, the
acceptance); D77, D78, D79, D82, D83, D85, D86, D87; the boards of row 27.

## Global constraints

- A screen changes only to an approved board (rule 1): the 60 boards of row 27 (fifteen pages, each at 1280 and 390,
  dark and light) and what "Phase 19 boards" settles. A page state the boards do not draw (a loading row, an empty list)
  takes the board's own words for it ("Nothing yet" in a card). The trade's words are allowed (D78); nothing a tutor reads
  changes but one sentence on `/trust` (Task 18), checked by `web/test/unit/words.test.ts`.
- The service-role key lives in Vercel's Production environment of `tutor-central-admin` and `admin/.env.local` (ignored),
  nowhere else (D11, D83): read in server code only (`import "server-only"` in the module that holds it), never in a page
  component's props, never in a client component, never in the build output (`admin/test/build/secret.test.ts`).
- Every page but `/sign-in`, `/mfa/*`, `/refused`, `/health` and the not-found page calls `requireAdmin()` first (a test
  greps for it); `requireAdmin` answers only for a user on `admin_users` whose session is `aal2`; anything else is a redirect.
- An admin never sees a parent's number, a photo, or a personal kind's input for a student without current consent (D78,
  D79): the read functions never select those columns; `admin_call` nulls the input when the row names a student whose
  consent is not current; a student's name appears only on `/centres/<id>/record`, which `admin_open_record` serves after
  writing the audit row in the same transaction.
- Every new table: `id`, `created_at`, `updated_at` with `set_updated_at`, RLS on, a policy, a line in `rls.test.ts`'s
  catalogue, no grant to `anon` or `PUBLIC`; new functions grant `service_role` alone (the portal and the worker) unless a
  task says `authenticated`. The security definer functions stay four (the catalogue's probe).
- Migrations are additive (D26); build 29 keeps working (nothing it reads changes; `notifications.kind` gains a value;
  `job_kind` gains a value).
- No technical words reach a tutor: the one push to the owner's iPhone carries plain words ("Tutor Central needs a look",
  the alert's line in words). The portal itself may say "job", "API", "token".
- Bun only (D16); dependencies pinned exactly (D14); `bun check` green before every commit; a pull request merges on
  local green (D86); documents only go to `main` directly (D12); no tutor's name, email or number in the repository (D55):
  the owner's admin email is typed at a prompt or read into a command, never written to a file; the one email address the
  alerts go to is the Vercel variable `ALERT_EMAIL`.
- Times on the portal are India's (`Asia/Kolkata`), money is rupees from paise with two decimals under ₹10 and none above.

## Decisions this plan takes

The owner approved the boards (2026-10-13, "Approve all") after one question, the second factor's cost (nothing: TOTP is
in Supabase's basic MFA on the Free plan; phone MFA, a paid add-on, is not used). Everything below was mine to decide and
is stated so it can be pushed back on.

1. **A separate admin account (D94).** The owner's admin identity is an account of its own in the same Supabase Auth
   (made by him in the dashboard with a password, Task 1), on `admin_users`, with TOTP enrolled in the portal at its first
   sign-in. Not his tutor account: the app has no second-factor prompt, the audit then names an admin and never a tutor, and
   the account owns no centre. Sign-in is email and password, then the 6-digit code; the session's `aal2` lapses with
   Supabase's session (a refreshed session keeps `aal2`), and `/mfa/verify` is asked again when it does not.
2. **`admin_users`** (migration 0046): `user_id` (the primary key, `auth.users`), `email` (shown in the audit; a copy so the
   audit page needs no auth lookup), `notify_user_id` and `notify_centre_id` (the tutor account and centre whose iPhone
   gets the alert pushes: the owner's own, so his existing device token serves), `created_at`, `updated_at`. RLS on, one
   policy `using (false)` (no member reads it; the portal reads as the platform). Rows are written by the session with
   `supabase db query --linked` (D87), never by the portal.
3. **Reads through `admin_*` functions, granted to `service_role` alone** (migration 0047): one function per page or
   section, `security invoker`, `set search_path = ''`, each returning jsonb or a set of a declared type, each selecting
   only the columns the board shows. The portal's server calls them with the service client; a member calling one gets
   `42501` (the test). The aggregations (cost by day, centre, kind and model; errors by route and reason; a centre's counts)
   live in SQL, not in TypeScript.
4. **Writes through named functions, each writing its own audit row:** `admin_audit_write` (sign-in, refusal, enrolment,
   sign-out), `admin_open_record` (the audit row and the record in one transaction), `admin_acknowledge_alert`,
   `admin_retry_job` (a failed job back to `queued` at its failed step: `attempts` 0, `error` null, the lease cleared,
   `run_at` now; the step data stays, so the job resumes where it failed and a paid step replays by its key),
   `admin_cancel_job` (the existing `cancel_job`'s effect without the member check, as the platform). Each takes the admin's
   user id and the request's address.
5. **The alerts job** (D95): kind `alerts` (the enum gains it), key `alerts:<UTC ten minutes>`, queued by the tick when
   none is live, as the sweep is. One step: `alert_facts(p_now)` (jobs failed in the last 30 minutes, each centre's cost
   today in paise, the last hour's request and error counts, jobs running over ten minutes), the four lines in
   `api/src/alerts/lines.ts` (pure: facts in, alerts out), `raise_alert` per alert (insert by `key`, `on conflict do
   nothing`; answers whether it was new), and for each new one an email through Resend's HTTP API (`RESEND_API_KEY`,
   `ALERT_EMAIL`, from `Tutor Central <hello@tutorcentral.in>`, the domain D30 verified) and a push to each
   `admin_users` row's `notify_user_id` through `replace_notifications` with kind `alert` (no link: the app opens Today on a
   push without one), title "Tutor Central needs a look", body the alert's line in words. The lines: `job_failed` (any job
   failed after its last attempt; key `job_failed:<job id>`), `cost_day` (a centre over ₹60 in India's day; key
   `cost_day:<centre>:<day>`), `error_rate` (answers over 400 above 5% of the hour's requests, at least 20 requests; key
   `error_rate:<hour>`), `job_stuck` (a job running over ten minutes; key `job_stuck:<job id>`). The numbers are constants
   in `lines.ts` until Phase 22 moves them to the portal.
6. **`alerts` gains `key` (unique), `message` and `acknowledged_by`** (0046); `notifications.kind` gains `alert`; the
   push's payload is the row's title and body as every kind's is (`payload.ts` does not read the kind).
7. **The look** is the website's frame with a nav of seven pages (Centres, Cost, Calls, Jobs, Errors, Alerts, Audit) and
   Sign out; tables are the list card with a grid row that stacks to two labelled columns under 760 px; stat tiles four
   across (two at phone width); filters are select pills that change the URL's query; the trade's words. Appearance follows
   the device (no toggle). Colours are the app's tokens as CSS variables (the website's `globals.css` grammar and its tokens
   test), plus the status tints the boards use (`ok`, `due`, `overdue` and their tints, already in `design-tokens.md`).
8. **One `Data` interface** (`admin/lib/data/types.ts`): every page reads through it; `real.ts` calls the `admin_*`
   functions with the service client; `preview.ts` answers the boards' figures from `admin/preview/*.json`. Pages are
   server components rendered from `Data`; unit tests render them with `preview.ts` through `react-dom/server` (as the
   website's tests do) and assert the boards' words.
9. **Preview mode** (D96): `ADMIN_PREVIEW=1` serves `preview.ts` and skips the gate; refused when `VERCEL_ENV` is
   `production` (the app throws at start; a test holds it, as `AI_FAKE` is refused). `bun admin-shots` builds, starts the
   built app on a free port in preview, photographs every page and state at 1280 and 390, dark and light, with
   `tools/web-shots.ts`'s DevTools client into `.shots/admin/`; the pictures go on each pull request by `bun pr-shots`
   (D7). The states with a query: `/centres/<id>?ask=1` (the reason dialog), `/jobs?open=<id>` (a job's steps open), both
   real behaviours.
10. **Writes from the browser are Next server actions** on a `<form>`: Open the record (the reason), Acknowledge, Retry,
    Cancel, Sign in, Verify, Sign out. Each runs `requireAdmin()` again, calls its function, writes nothing else, and
    redirects. No client JavaScript of the portal's own beyond what Next ships for forms.
11. **The gate is a pure function** (`admin/lib/gate.ts`): `decide({ user, admin, verifiedFactors, currentLevel })` answers
    `sign-in`, `refused` (with the email), `enrol`, `verify` or `ok`; `requireAdmin()` reads the session with
    `@supabase/ssr`'s server client (`auth.getUser()`, which checks with the server), the assurance level
    (`auth.mfa.getAuthenticatorAssuranceLevel()`), the factors (`auth.mfa.listFactors()`) and the `admin_users` row with the
    service client, then `decide`s and redirects or answers the admin. `proxy.ts` (Next 16's request middleware) only
    refreshes the session cookie and sends a request without a session to `/sign-in`; it is not the gate.
12. **The local-stack test of the gate** (`admin/test/db/gate.test.ts`): a user made with the admin API, enrolled through
    `auth.mfa.enroll`, verified with a code computed by `tools/totp.ts` (RFC 6238 over Node's `crypto`, no dependency; its
    own test against the RFC's vectors), on `admin_users` by SQL; `decide` answers `verify` at `aal1` and `ok` at `aal2`; a
    user not on the list is `refused`; a user with no factor is `enrol`.
13. **The record's open** is one function, `admin_open_record(p_admin, p_centre, p_reason, p_ip)`: the audit row (action
    `open_record`, the reason, the address), then the students (name, class level, batch, consent state and day, tracking
    status), the batches and what the AI service made about them (kind, title, day, cost; outputs' words are not shown on
    this page). A reason is required (1 to 200 characters); the page is never served without the row.
14. **The Calls page shows a personal kind's input only while consent stands:** `admin_call` answers `input: null` and
    `input_held: true` when `student_id` is set and the student's `consent_at` is null; the page shows "Held: the student's
    consent is not current" in the input's place. Outputs are shown as kept (D79: the output and cost are kept).
15. **A centre's "in use"** is `centre_in_use` (0039); a centre's "last opened" is its latest `app_opened` event; "active
    this week" counts centres with an `app_opened` in seven days.
16. **Activity words:** the events' kinds map to words in `admin/content/activity.ts` (`app_opened` "Opened the app",
    `signed_in` "Signed in", `signed_out` "Signed out", `tab_opened` "Opened <screen>", `link_opened` "Opened a link ·
    <screen>"); closes, notes sent, plans and artefacts come from their own tables (`admin_activity` unions them with a
    `what` column), as the board draws them.
17. **Errors' reasons in words:** `admin/content/reasons.ts` maps `api_requests.reason` to the board's phrases (`timeout`
    "the model did not answer in 110 s", `student_consent` "a note asked without consent", `in_progress` "the same key still
    running", `key_reused`, `rate`, `unreachable`, `invalid`, and a 401 "sign in again · a stale token"); an unknown reason
    is shown as it is.
18. **The third Vercel project** `tutor-central-admin` is made by the session with the CLI (`vercel link` in `admin/`,
    which creates it), its Production variables piped from the API project's (`vercel env pull` into a scratch file, the
    value cut into `vercel env add`, the file removed; nothing printed), git deploys off by `admin/vercel.json`, the domain
    added with `vercel domains add admin.tutorcentral.in`. Two things no CLI does are the owner's: the project's Root
    Directory (`admin`) in Vercel's settings, and the CNAME at GoDaddy (Task 1).
19. **`deploy-admin.yml`** has `deploy.yml`'s gate job (`tools/check-gate.ts`: a commit whose check is not green never
    deploys, D80) and `deploy-web.yml`'s build, deploy and smoke; `tools/admin-smoke.ts` must find `/health` serving the
    commit, `/sign-in` answering 200 with its title, `/centres` and `/jobs` without a session redirecting to `/sign-in`,
    `/health` answering 200 and nothing else without a session, and http redirecting to https. The smoke never signs in
    (it has no second factor).
20. **`bun check` gains an `admin` step** after `web` (Biome, `next typegen`, `tsc`, the unit tests, `next build` with a
    probe service key, the build tests: the probe absent from `.next`, the health route present); CI's Ubuntu job runs it
    (`--only=api,web,admin,db`). Its inputs are `admin/**` as the web step's are, plus `docs/design/design-tokens.md`.
21. **The hand runs** are driven in the Claude desktop app's built-in browser against the local stack and the local admin
    (`bun run dev` in `admin/` on :3100 with `admin/.env.local` from `supabase status`), by a new runbook
    `docs/runbooks/admin.md` (D32's spirit: a settled page before every click, every write confirmed in the database). The
    alert email locally goes to a fake sender that logs; the push goes to the simulator through the local API (runbook 13).
22. **The trust page** gains one sentence under what reaches the AI service's neighbour section ("Who can see your
    records"): Tutor Central's own staff can open a centre's records only for support, with the reason and time written
    down, and never a parent's number or a photo. Its "Last changed" moves (web rule).
23. **Branches and the ledger.** `phase-19/<slug>` in the main checkout, one per pull request; the build's ledger is
    `plan/sessions/039/ledger.md`, written by hand after each named test run, each ruling with its cost if wrong.
24. **Order of deploys.** Deploy A (`gh workflow run deploy`) after PR 12: 0046 and 0047 and the API's alerts job live.
    The admin's first production deploy (`gh workflow run deploy-admin`) after PR 14, before the hand run on production
    (Task 17). The review's fixes deploy by whichever workflow they touch.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A tutor's account at the portal's door.** A tutor who finds the address signs in with their app password: `decide`
   answers `refused`, nothing of any centre is read, the audit holds `refused` with the email, and Sign out clears the
   cookie. Tests: Task 5 (`a user not on admin_users is refused and audited`, `decide: no admin row is refused whatever the
   level`).
2. **An admin whose `aal2` lapsed mid-session.** A page is opened an hour later with the session refreshed to `aal1`: the
   page is not served; `/mfa/verify` is asked; after the code the same page opens. Tests: Task 5 (`decide: an admin at
   aal1 with a verified factor is verify`), Task 4 (`every page outside the public set calls requireAdmin`), hand run 2.
3. **The service key reaching a browser.** A page passes a server object to a client component, or a `NEXT_PUBLIC_`
   variable is added by mistake: the build test greps every file under `.next` for the probe key and fails. Test: Task 4
   (`the service key is in no build output`), and the gate test that `lib/supabase/service.ts` imports `server-only`.
4. **An alert raised twice, or a flood.** The alerts job runs each ten minutes; a failed job must raise once, an error
   rate once an hour, a centre's cost once a day. Keys hold it (`raise_alert` on conflict does nothing; the email and push go
   only for a new row). Tests: Task 13 (`the same failed job raises one alert across two runs`, `the error rate alert is
   keyed by the hour`), Task 2 (`raise_alert answers false for a key already raised`).
5. **A retry of a job whose step paid.** A plan job failed at `make:2` after its call; Retry re-queues it at that step; the
   call replays by its key (no second charge) and the keep is idempotent. Tests: Task 2 (`admin_retry_job re-queues a failed
   job at its step with attempts 0`), Task 10 (the action's test), Phase 18's `a material step retaken after its call keeps
   once and pays once` (unchanged, still green).
6. **Opening the record with no reason, or by a URL alone.** `/centres/<id>/record` opened directly has no reason: the page
   redirects to `/centres/<id>?ask=1`; an empty reason is refused by the function (`P0001 reason_required`). Tests: Task 7
   (`the record page without a reason sends to the ask`, `admin_open_record refuses an empty reason`).
7. **A centre deleted while the portal is open.** `admin_centre` for a gone id answers null; the page shows the not-found
   page, never a 500. Test: Task 6 (`a centre that is gone is not found`).
8. **Preview mode in production.** `ADMIN_PREVIEW=1` on Vercel would serve fixtures to a signed-out world: the app refuses
   to start when `VERCEL_ENV` is production (Task 14's test), and the smoke's `/centres` redirect would catch a deploy that
   slipped (Task 15).

## File structure

Created or changed, by part. A file has one job.

**Database (`supabase/`)**
- `migrations/20261120000046_v3_admin_tables.sql`: `admin_users`; `alerts.key`, `message`, `acknowledged_by`;
  `notifications.kind` gains `alert`; `job_kind` gains `alerts`; `admin_audit_write`, `raise_alert`, `alert_facts`,
  `admin_push_targets`, `admin_acknowledge_alert`, `admin_retry_job`, `admin_cancel_job`; the catalogue's line.
- `migrations/20261121000047_v3_admin_reads.sql`: `admin_centres`, `admin_centre`, `admin_activity`, `admin_centre_jobs`,
  `admin_open_record`, `admin_cost_by_day`, `admin_cost_by_centre`, `admin_cost_by_kind`, `admin_calls`, `admin_call`,
  `admin_jobs`, `admin_job`, `admin_errors_by_route`, `admin_errors_recent`, `admin_alerts`, `admin_audit`.
- `tests/admin-writes.test.ts` (new), `tests/admin-reads.test.ts` (new), `tests/rls.test.ts` (the catalogue), `types.ts`.

**The portal (`admin/`)**
- `package.json`, `bunfig.toml` (none: the root's hoisted linker serves), `biome.json`, `tsconfig.json`, `next.config.ts`,
  `vercel.json`, `.env.example`, `CLAUDE.md`, `proxy.ts`.
- `app/layout.tsx`, `app/globals.css`, `app/icon.svg`, `app/not-found.tsx`, `app/health/route.ts`.
- `app/sign-in/page.tsx` + `actions.ts`, `app/mfa/enrol/page.tsx` + `actions.ts`, `app/mfa/verify/page.tsx` + `actions.ts`,
  `app/refused/page.tsx`, `app/sign-out/route.ts`.
- `app/centres/page.tsx`, `app/centres/[id]/page.tsx` + `actions.ts` (the open), `app/centres/[id]/record/page.tsx`,
  `app/cost/page.tsx`, `app/calls/page.tsx`, `app/calls/[id]/page.tsx`, `app/jobs/page.tsx` + `actions.ts` (retry, cancel),
  `app/errors/page.tsx`, `app/alerts/page.tsx` + `actions.ts` (acknowledge), `app/audit/page.tsx`.
- `components/Frame.tsx` (header, nav, footer), `components/parts.tsx` (title, section, tiles, card, table, chip, filter
  pill, button, field, progress, bars, dialog, code block), `components/Icon.tsx` (the book, the chevron).
- `content/words.ts` (every string the pages show, from the boards), `content/activity.ts`, `content/reasons.ts`,
  `content/site.ts` (the host, the API commit's source).
- `lib/env.ts`, `lib/supabase/server.ts` (the SSR client over cookies), `lib/supabase/service.ts` (`server-only`),
  `lib/gate.ts` (`decide`, `requireAdmin`), `lib/audit.ts`, `lib/format.ts` (IST times, rupees, counts),
  `lib/data/types.ts`, `lib/data/real.ts`, `lib/data/preview.ts`, `lib/data/index.ts` (which one, by `ADMIN_PREVIEW`).
- `preview/*.json`: the boards' figures (centres, centre, record, cost, calls, call, jobs, errors, alerts, audit).
- Tests: `test/unit/tokens.test.ts`, `gate.test.ts`, `format.test.ts`, `pages.test.ts` (each page rendered from preview
  data holds its board's words), `words.test.ts` (the gate's imports), `activity.test.ts`, `reasons.test.ts`; `test/build/
  secret.test.ts`, `health.test.ts`; `test/db/gate.test.ts` (the local stack; skipped with a line when it is down).

**API (`api/`)**
- `src/alerts/lines.ts` (the four lines, pure), `src/alerts/resend.ts` (the email through fetch; a fake that logs),
  `src/alerts/db.ts` (`alert_facts`, `raise_alert`, `admin_push_targets` through the service client; a fake),
  `src/jobs/kinds/alerts.ts`, `src/jobs/kinds/index.ts`, `src/jobs/types.ts` (`alerts` in `JobKind`), `src/routes/jobs.ts`
  (the tick queues `alerts:<ten minutes>`), `src/env.ts` (`RESEND_API_KEY`, `ALERT_EMAIL`), `src/index.ts` (the sender),
  `.env.example`, `src/generated/database.ts` (regenerated).
- Tests: `test/alerts-lines.test.ts`, `test/alerts-job.test.ts`, `test/resend.test.ts`, `test/jobs-routes.test.ts` (the
  tick's second key), `test/platform-db.test.ts` (an alert raised on the local stack).

**Tools and workflows**
- `tools/totp.ts` (+ `tools/totp.test.ts`), `tools/admin-shots.ts` (+ test of its argument parsing and names),
  `tools/admin-smoke.ts` (+ test with a fake fetch), `tools/check/steps.ts` (the `admin` step), `package.json` (the
  `admin-shots` script), `.github/workflows/check.yml` (`admin` in the Ubuntu job), `.github/workflows/deploy-admin.yml`.
- `docs/runbooks/admin.md` (driving the portal locally; the alert's push to the simulator).

**Web (`web/`)**: `content/trust.ts`, `content/site.ts` ("Last changed").

**Documents:** `admin/CLAUDE.md` (new), `api/CLAUDE.md`, `supabase/CLAUDE.md`, `CLAUDE.md` (the table's row and the
commands), `plan/README.md` (D94 to D96 with the plan's approval; the phase's status), `plan/phase-19-admin-portal-reading.md`
("As built"), `plan/STATE.md`, `plan/sessions/039/`, `docs/design/information-architecture.md` (a state the build settles).

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 2 | `phase-19/db-admin-tables` | Migration 0046: `admin_users`, the alerts' key and message, the alert kind, the write functions | none |
| 2 | 3 | `phase-19/db-admin-reads` | Migration 0047: the `admin_*` read functions for every page, granted to the platform alone | none |
| 3 | 4 | `phase-19/admin-scaffold` | `admin/`: the Next.js app, the frame, the tokens, `/health`, the gate's pieces, the `admin` check step | the frame at 1280 and 390 (not found) |
| 4 | 5 | `phase-19/admin-sign-in` | Sign in, the second factor's enrolment and code, refused, sign out; the audit of each | P19-SignIn, -TOTP-Enrol, -TOTP-Verify, -Refused |
| 5 | 6 | `phase-19/admin-centres` | The centres list and a centre's page | P19-Centres, P19-Centre |
| 6 | 7 | `phase-19/admin-record` | The audited open of a centre's record | P19-Centre-OpenAsk, P19-Centre-Record |
| 7 | 8 | `phase-19/admin-cost` | Cost by day, centre, kind and model against the allowance and ₹499 | P19-Cost |
| 8 | 9 | `phase-19/admin-calls` | The AI calls and one call, with the consent rule on inputs | P19-Calls, P19-Call |
| 9 | 10 | `phase-19/admin-jobs` | Jobs and their steps; Retry and Cancel, audited | P19-Jobs |
| 10 | 11 | `phase-19/admin-errors` | Errors by route and reason, and the latest | P19-Errors |
| 11 | 12 | `phase-19/admin-alerts-audit` | Alerts with Acknowledge; the audit page | P19-Alerts, P19-Audit |
| 12 | 13 | `phase-19/api-alerts-job` | The `alerts` job: the four lines, raised once, emailed through Resend, pushed through the outbox | none |
| 13 | 14 | `phase-19/admin-shots` | Preview mode (refused in production) and `bun admin-shots`; every page's pictures | all 60 states |
| 14 | 15 | `phase-19/deploy-admin` | `deploy-admin.yml` with the gate and `tools/admin-smoke.ts`; the project's variables and domain | none |
| 15 | 16 | `phase-19/runbook-admin` | `docs/runbooks/admin.md`; the hand runs' fixes (D68) | the hand runs' pictures on the issue |
| 16 | 18 | `phase-19/web-trust-staff` | `/trust`: one sentence on staff access with a reason written down | /trust at 1280 and 390, dark and light |

Every PR with pictures carries them by `bun pr-shots` (D7); PRs 3 to 11 photograph their pages by `bun admin-shots`
once Task 14 exists, and until then by the same script run from the task's branch (Task 14's tool is small enough to be
written in Task 4 and finished in Task 14: see Task 4, Step 7).

## The order

Task 1 (the owner's steps A and B, asked in the first message; C and D asked when Task 15 reaches them; E at Task 17) →
2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 (and Deploy A, then the admin's first deploy) → 16 → 17
(production) → 18 (the review, the trust page, the documents). Tasks 6 to 12 are independent of each other once 3, 4 and
5 are in; build them in order anyway, one pull request each.

---

### Task 1: The owner's steps (A and B asked at the start; C, D and E when their task reaches them)

No code. Each list is sent to the owner exactly, one list per message, and the next step waits for his word that the
previous one shows its success line.

**A. The admin account** (needed by Task 5's production row and Task 17):

1. Open https://supabase.com/dashboard in your browser and sign in.
2. Click the project **Tutor Central** (the one at `esowihbxawvoexflekxa`).
3. In the left menu click **Authentication**, then **Users**.
4. Click **Add user** (top right), then **Create new user**.
5. In **Email address** type an address you own that is not your tutor account's email (an alias such as
   `yourname+admin@gmail.com` works and lands in the same inbox). In **Password** paste a long password from your
   password manager and save it there under "Tutor Central admin". Leave **Auto Confirm User** switched on.
6. Click **Create user**. Success: the user appears in the list with a green "Confirmed" mark under its email.
7. Tell me the email in chat: I put it on the admin list with a database command (it is read into the command, never
   written to a file).

**B. The key the alert emails are sent with** (needed by Task 13 in production):

1. Open https://resend.com and sign in (the account that verified tutorcentral.in, D30).
2. In the left menu click **API Keys**, then the button **Create API Key**.
3. **Name**: `tutor-central-alerts`. **Permission**: choose **Sending access**. **Domain**: choose `tutorcentral.in`.
   Click **Add**.
4. Click **Copy** beside the key shown. It is shown once.
5. Open Terminal, paste these two lines and press Return after each:
   ```
   cd ~/codebase/tutor_central/api
   vercel env add RESEND_API_KEY production
   ```
   The prompt asks **What's the value of RESEND_API_KEY?**: paste the key and press Return. Success: the line
   `Added Environment Variable RESEND_API_KEY to Project tutor-central-api [production]`.
6. Then one more, the address the alerts go to:
   ```
   vercel env add ALERT_EMAIL production
   ```
   At the prompt type the email address you want alerts at (your usual one) and press Return. Success: the same line with
   `ALERT_EMAIL`.
7. Close the Resend tab. Tell me "done".

**C. The admin project's folder** (after Task 15 has made the project; one minute):

1. Open https://vercel.com and sign in. Click **Arun's projects**, then the project **tutor-central-admin**.
2. Click **Settings** (top), then **General** (left).
3. Find **Root Directory**, click **Edit**, type `admin`, click **Save**. Success: the field shows `admin`.
4. Tell me "done".

**D. The address** (after Task 15 has added the domain; I will give you the exact value to paste):

1. Open https://godaddy.com, sign in, open **My Products**, find **tutorcentral.in** and click **DNS**.
2. Click **Add New Record**. **Type**: `CNAME`. **Name**: `admin`. **Value**: the value I give you (it ends in
   `vercel-dns.com`). **TTL**: leave it. Click **Save**.
3. Success: the record `admin` appears in the list. Tell me "done". Within an hour https://admin.tutorcentral.in answers
   (I check it; you need not).

**E. Your first sign-in and your authenticator** (Task 17, after the first deploy):

1. On your Mac open https://admin.tutorcentral.in. The page **Sign in** shows.
2. Type the admin email from step A and its password. Click **Sign in**.
3. The page **Set up your authenticator** shows a square code. On your iPhone open **Google Authenticator** (or
   1Password, or any app that makes 6-digit codes), tap **+**, tap **Scan a QR code**, point it at the square.
4. The app shows **Tutor Central admin** with a 6-digit code. Type the code into **Code from the app** and click **Verify
   and finish**.
5. Success: the **Centres** page shows your centre and the Smoke centre. From now on every sign-in asks for the current
   code after your password.
6. Also, so the alert push can reach you: make sure build 29 is installed on your iPhone and **More → Settings → Teacher
   reminders → Turn on reminders** is on (it registers your iPhone for pushes).

---

### Task 2: Migration 0046: the admin tables and the write functions (PR 1)

**Files:**
- Create: `supabase/migrations/20261120000046_v3_admin_tables.sql`
- Create: `supabase/tests/admin-writes.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the catalogue: `admin_users` among the platform tables, `memberReads: false`),
  `supabase/types.ts`

**Interfaces:**
- Produces: table `public.admin_users(user_id uuid primary key references auth.users on delete cascade, email text not
  null, notify_user_id uuid references auth.users on delete set null, notify_centre_id uuid references public.centres on
  delete set null, created_at, updated_at)`.
- `alerts` gains `key text unique check (char_length(key) between 1 and 120)`, `message text check (char_length(message)
  <= 400)`, `acknowledged_by uuid`; 0030's rows are none in production (the table is empty), so `key` is added `not null`
  after a backfill of `'legacy:' || id` for any row.
- `alter type public.job_kind add value 'alerts'`; `notifications.kind` check gains `'alert'` (drop and re-add the check).
- `admin_audit_write(p_admin uuid, p_action text, p_centre uuid, p_target jsonb, p_reason text, p_ip text) returns uuid`.
- `raise_alert(p_key text, p_kind text, p_centre uuid, p_threshold numeric, p_value numeric, p_message text) returns
  boolean` (true when inserted, false on the key's conflict).
- `alert_facts(p_now timestamptz) returns jsonb`: `{ "failed_jobs": [{id, kind, centre_id, input, finished_at}],
  "cost_today": [{centre_id, paise}], "requests_hour": {total, errors}, "stuck_jobs": [{id, kind, centre_id, started_at}] }`
  (failed in the last 30 minutes; the day in `Asia/Kolkata`; the hour before `p_now`; running with `started_at < p_now -
  interval '10 minutes'`).
- `admin_push_targets() returns table (user_id uuid, centre_id uuid)` (the `admin_users` rows with both set).
- `admin_acknowledge_alert(p_admin uuid, p_alert uuid, p_ip text) returns boolean` (sets `acknowledged_at`, `acknowledged_by`;
  the audit row `acknowledge_alert` with `target {alert, kind, centre}`; false when already acknowledged or unknown).
- `admin_retry_job(p_admin uuid, p_job uuid, p_ip text) returns boolean` (a `failed` job to `queued`: `attempts` 0, `error`
  null, `leased_by` and `lease_until` null, `finished_at` null, `run_at` now; the audit row `retry_job` with `target {job,
  kind, centre, step}`; false when the job is not failed; `tc.jobs` set for the transaction).
- `admin_cancel_job(p_admin uuid, p_job uuid, p_ip text) returns boolean` (`queued`, `waiting` or `running` to
  `cancelled`, `finished_at` now; the audit row `cancel_job`).
- Grants: every function `revoke all from public, anon, authenticated` and `grant execute to service_role`.

- [ ] **Step 1: the failing tests** (`supabase/tests/admin-writes.test.ts`, the jobs test's frame: `local()`, a member `a`
  of centre A, the service client `svc`, `sql`):

```ts
import { SQL } from "bun";
import { beforeAll, expect, test } from "bun:test";
import { local, type Local, serviceClient, userClient } from "./client";

let l: Local; let svc: ReturnType<typeof serviceClient>; let a: Awaited<ReturnType<typeof userClient>>; let centreA: string; let adminId: string; let sql: SQL;
const stamp = Date.now();

beforeAll(async () => {
  l = await local(); svc = serviceClient(l); sql = new SQL(l.db);
  a = await userClient(l, `admin-w-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Centre A", p_whatsapp: "+919999999999" })).data as string;
  const admin = await userClient(l, `admin-w-admin-${stamp}@example.com`);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${`admin-w-admin-${stamp}@example.com`})`;
});

test("admin_users is read by no member and written by none but the platform", async () => {
  expect((await a.from("admin_users").select("user_id")).data).toEqual([]);
  expect((await a.from("admin_users").insert({ user_id: adminId, email: "x@example.com" })).error).not.toBeNull();
  expect((await svc.from("admin_users").select("email").eq("user_id", adminId)).data?.length).toBe(1);
});

test("admin_audit_write keeps who, what, which centre, the reason and the address", async () => {
  const { data: id, error } = await svc.rpc("admin_audit_write", { p_admin: adminId, p_action: "sign_in", p_centre: null, p_target: {}, p_reason: "second factor verified", p_ip: "49.207.1.1" });
  expect(error).toBeNull();
  const [row] = await sql`select admin_user_id, action, reason, ip from public.admin_audit where id = ${id}`;
  expect(row).toEqual({ admin_user_id: adminId, action: "sign_in", reason: "second factor verified", ip: "49.207.1.1" });
  expect((await a.rpc("admin_audit_write", { p_admin: adminId, p_action: "sign_in", p_centre: null, p_target: {}, p_reason: null, p_ip: null })).error?.code).toBe("42501");
});

test("raise_alert raises a key once and answers false the second time", async () => {
  const key = `job_failed:${crypto.randomUUID()}`;
  const first = await svc.rpc("raise_alert", { p_key: key, p_kind: "job_failed", p_centre: centreA, p_threshold: 0, p_value: 1, p_message: "a plan job failed after 3 tries" });
  const second = await svc.rpc("raise_alert", { p_key: key, p_kind: "job_failed", p_centre: centreA, p_threshold: 0, p_value: 1, p_message: "again" });
  expect([first.data, second.data]).toEqual([true, false]);
  expect((await sql`select count(*)::int as n from public.alerts where key = ${key}`)[0].n).toBe(1);
});

test("admin_acknowledge_alert marks once, by whom, and writes the audit", async () => {
  const key = `cost_day:${centreA}:2026-10-13`;
  await svc.rpc("raise_alert", { p_key: key, p_kind: "cost_day", p_centre: centreA, p_threshold: 6000, p_value: 7200, p_message: "over ₹60" });
  const [{ id }] = await sql`select id from public.alerts where key = ${key}`;
  expect((await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: id, p_ip: "1.2.3.4" })).data).toBe(true);
  expect((await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: id, p_ip: "1.2.3.4" })).data).toBe(false);
  const [row] = await sql`select acknowledged_by, acknowledged_at is not null as done from public.alerts where id = ${id}`;
  expect(row).toEqual({ acknowledged_by: adminId, done: true });
  expect((await sql`select count(*)::int as n from public.admin_audit where action = 'acknowledge_alert' and target->>'alert' = ${id}`)[0].n).toBe(1);
});

test("admin_retry_job re-queues a failed job at its step with attempts 0, and refuses a job that is not failed", async () => {
  await sql`select set_config('tc.jobs', 'on', true)`;
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, step, error, finished_at)
    values (${centreA}, 'plan', ${`retry-${stamp}`}, 'failed', 3, '{"at":"make","n":2}', '{"reason":"attempts"}', now()) returning id`;
  expect((await svc.rpc("admin_retry_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(true);
  const [row] = await sql`select state, attempts, error, leased_by, finished_at, step->>'at' as at from public.jobs where id = ${id}`;
  expect(row).toEqual({ state: "queued", attempts: 0, error: null, leased_by: null, finished_at: null, at: "make" });
  expect((await svc.rpc("admin_retry_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(false);
  expect((await sql`select target->>'step' as step from public.admin_audit where action = 'retry_job' and target->>'job' = ${id}`)[0].step).toBe("make");
});

test("admin_cancel_job cancels a live job and writes the audit; a done job is refused", async () => {
  await sql`select set_config('tc.jobs', 'on', true)`;
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state) values (${centreA}, 'plan', ${`cancel-${stamp}`}, 'queued') returning id`;
  expect((await svc.rpc("admin_cancel_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(true);
  expect((await sql`select state from public.jobs where id = ${id}`)[0].state).toBe("cancelled");
  expect((await svc.rpc("admin_cancel_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(false);
});

test("alert_facts names the failed, the stuck, today's cost and the hour's errors", async () => {
  await sql`select set_config('tc.jobs', 'on', true)`;
  const [{ id: failed }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, finished_at) values (${centreA}, 'plan', ${`facts-f-${stamp}`}, 'failed', 3, now()) returning id`;
  const [{ id: stuck }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at, lease_until) values (${centreA}, 'plan', ${`facts-s-${stamp}`}, 'running', now() - interval '11 minutes', now() + interval '1 minute') returning id`;
  await svc.from("api_requests").insert([{ request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 502, latency_ms: 1, centre_id: centreA, reason: "timeout" }, { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 200, latency_ms: 1, centre_id: centreA }]);
  const facts = (await svc.rpc("alert_facts", { p_now: new Date().toISOString() })).data as { failed_jobs: { id: string }[]; stuck_jobs: { id: string }[]; requests_hour: { total: number; errors: number }; cost_today: unknown[] };
  expect(facts.failed_jobs.map((j) => j.id)).toContain(failed);
  expect(facts.stuck_jobs.map((j) => j.id)).toContain(stuck);
  expect(facts.requests_hour.errors).toBeGreaterThanOrEqual(1);
  expect(facts.requests_hour.total).toBeGreaterThanOrEqual(2);
  expect(Array.isArray(facts.cost_today)).toBe(true);
});

test("a member cannot call the platform's admin functions", async () => {
  for (const fn of ["raise_alert", "alert_facts", "admin_push_targets", "admin_acknowledge_alert", "admin_retry_job", "admin_cancel_job"]) {
    const r = await a.rpc(fn, {});
    expect({ fn, code: r.error?.code }).toEqual({ fn, code: "42501" });
  }
});
```

- [ ] **Step 2: run them: RED** (`cd supabase && bun test tests/admin-writes.test.ts`): every test fails (no table, no
  functions). Write the ledger line.
- [ ] **Step 3: the migration.** The heart of it:

```sql
-- Phase 19 (D78, D94): the admin allow-list, the alerts' key and message, the alert kind, and the platform's write
-- functions. Reads are 0047. No member reads admin_users; every function here is the platform's (service_role).
create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null check (char_length(email) between 3 and 200),
  notify_user_id uuid references auth.users(id) on delete set null,
  notify_centre_id uuid references public.centres(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger admin_users_updated before update on public.admin_users for each row execute function public.set_updated_at();
alter table public.admin_users enable row level security;
create policy admin_users_platform_only on public.admin_users for select to authenticated using (false);
revoke all on public.admin_users from anon, authenticated;

alter table public.alerts add column key text, add column message text check (message is null or char_length(message) <= 400), add column acknowledged_by uuid;
update public.alerts set key = 'legacy:' || id where key is null;
alter table public.alerts alter column key set not null, add constraint alerts_key_unique unique (key), add constraint alerts_key_length check (char_length(key) between 1 and 120);

alter type public.job_kind add value 'alerts';
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in ('class', 'event', 'fees', 'plan_ready', 'notes_ready', 'plan_fetch', 'alert'));

create function public.admin_audit_write(p_admin uuid, p_action text, p_centre uuid, p_target jsonb, p_reason text, p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  insert into public.admin_audit (admin_user_id, action, centre_id, target, reason, ip)
  values (p_admin, p_action, p_centre, coalesce(p_target, '{}'), p_reason, p_ip) returning id into v_id;
  return v_id;
end $$;

create function public.raise_alert(p_key text, p_kind text, p_centre uuid, p_threshold numeric, p_value numeric, p_message text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  insert into public.alerts (key, kind, centre_id, threshold, value, message) values (p_key, p_kind, p_centre, p_threshold, p_value, p_message)
  on conflict (key) do nothing returning id into v_id;
  return v_id is not null;
end $$;

create function public.admin_retry_job(p_admin uuid, p_job uuid, p_ip text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v public.jobs;
begin
  select * into v from public.jobs where id = p_job and state = 'failed' for update;
  if not found then return false; end if;
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'queued', attempts = 0, error = null, leased_by = null, lease_until = null, finished_at = null, run_at = now() where id = p_job;
  perform set_config('tc.jobs', 'off', true);
  perform public.admin_audit_write(p_admin, 'retry_job', v.centre_id, jsonb_build_object('job', v.id, 'kind', v.kind, 'step', v.step->>'at'), null, p_ip);
  return true;
end $$;
```

  `alert_facts` builds its jsonb with four subqueries (`jsonb_build_object('failed_jobs', (select coalesce(jsonb_agg(…),
  '[]') from public.jobs where state = 'failed' and finished_at > p_now - interval '30 minutes'), …)`); `cost_today` sums
  `ai_generations.cost_paise` by centre where `(created_at at time zone 'Asia/Kolkata')::date = (p_now at time zone
  'Asia/Kolkata')::date`; `requests_hour` counts `api_requests` with `created_at > p_now - interval '1 hour'` and
  `status >= 400`. `admin_acknowledge_alert` and `admin_cancel_job` follow `admin_retry_job`'s shape. The `tc.jobs`
  setting lets the retry's and cancel's updates past 0028's trigger (the service role passes anyway; the setting keeps the
  functions correct under any role). Grants at the end:

```sql
revoke all on function public.admin_audit_write(uuid, text, uuid, jsonb, text, text) from public, anon, authenticated;
grant execute on function public.admin_audit_write(uuid, text, uuid, jsonb, text, text) to service_role;
-- the same two lines for raise_alert, alert_facts, admin_push_targets, admin_acknowledge_alert, admin_retry_job, admin_cancel_job
```

- [ ] **Step 4: the catalogue.** In `rls.test.ts` add `"admin_users"` to `PLATFORM_TABLES`, its probe row `{ user_id:
  <a fresh auth user>, email }` with `memberReads: false`, and `alert`'s probe gains `key`. Regenerate `types.ts`
  (`supabase gen types typescript --local > types.ts`).
- [ ] **Step 5: GREEN** (`bun check --only=db,tools,api`): the new tests pass, the catalogue holds, the definers stay four.
- [ ] **Step 6: commit, PR 1, merge on local green** (D86). Ledger line with the test counts.

---

### Task 3: Migration 0047: the read functions, one per page or section (PR 2)

**Files:**
- Create: `supabase/migrations/20261121000047_v3_admin_reads.sql`
- Create: `supabase/tests/admin-reads.test.ts`
- Modify: `supabase/types.ts`

**Interfaces** (every function `security invoker`, `stable`, `set search_path = ''`, `revoke … from public, anon,
authenticated`, `grant execute … to service_role`; a month is its first day as `date`; a `jsonb` answer carries exactly
the fields named, so `admin/lib/data/types.ts` mirrors them):
- `admin_centres(p_month date) returns jsonb`: `{ "tiles": {centres, active_week, cost_paise, failed_today}, "rows":
  [{id, name, owner_name, since, students, tutors, last_opened, cost_paise, in_use, jobs_today, failed_today}] }`.
  `owner_name` is `profiles.full_name` of `centres.owner_id`; `last_opened` the latest `app_opened`.
- `admin_centre(p_centre uuid, p_month date) returns jsonb` or null: `{ id, name, owner_name, since, students, batches,
  city, in_use, cost_paise, calls, allowance, allowance_paise, cost_by_kind: {plan, notes, exams}, cost_by_model:
  [{model, paise}], jobs_today, failed_today, last_close, tutors: [{name, email, last_sign_in, push: {build, env} |
  null}] }`. `tutors` joins `centre_members`, `profiles` and `auth.users.email`; `push` is the newest live `device_tokens`
  row of the user; `last_sign_in` the latest `signed_in` event. `cost_by_kind` groups `ai_generations.kind`: plan =
  `plan, sheet, worked_example, figure, brief, check, placement`; notes = `note, can_do, test_tomorrow, not_on_track,
  progress_note`; exams = `mock, check_paper, gap_report, read_marks`; the rest in `other`.
- `admin_activity(p_centre uuid, p_limit int) returns jsonb`: `[{at, what, who}]`, newest first, a union of `events`
  (kind, screen), closes (`attendance_sessions` with their present count: "Closed a class · <batch> · <n> present"), notes
  sent (`message_log`: "Sent a note · WhatsApp"), fees marked paid (`fee_invoices.paid_at`), artefacts made again
  (`artefacts.made_from`, `regenerate_reason` where the column exists) — each `what` as the board's words, built in SQL
  with the batch's name, never a student's name.
- `admin_centre_jobs(p_centre uuid, p_limit int) returns jsonb`: `[{id, kind, subject, state, finished_at, started_at,
  seconds, attempts, cost_paise, made, not_made, reason}]` (`subject` from the input: a class's name and the day, a
  student's "a student", "hourly" for `reminder_sweep`).
- `admin_open_record(p_admin uuid, p_centre uuid, p_reason text, p_ip text) returns jsonb`: writes the audit row
  (`open_record`, the reason, the address; `P0001 reason_required` when `p_reason` is null, empty or over 200), then
  answers `{ opened_at, students: [{name, class_level, batch, consent: {state, day}, tracking}], batches: [{name, days,
  start_time, end_time, students}], made: [{at, what, cost_paise}] }`. `consent.state` is `given` (consent_at set),
  `withdrawn` (the newest event withdrew), `asked` (an `asked` event after the last withdrawal, nothing recorded), else
  `not_asked`. Never `parent_phone`, never a `photo_path`.
- `admin_cost_by_day(p_month date) returns jsonb` `[{day, paise}]` (every day of the month, zero included, India's day);
  `admin_cost_by_centre(p_month date) returns jsonb` `[{id, name, calls, paise, per_student_paise}]`;
  `admin_cost_by_kind(p_month date) returns jsonb` `[{kind, model, calls, paise}]`; `admin_cost_tiles(p_month date)
  returns jsonb` `{month_paise, per_active_centre_paise, today_paise, average_share_of_499}`.
- `admin_calls(p_day date, p_centre uuid, p_kind text, p_status text, p_limit int) returns jsonb`: `{ tiles: {calls,
  failed, refused, median_latency_ms}, rows: [{id, created_at, centre, kind, model, prompt_version, status, replayed,
  error_reason, tokens_in, tokens_out, latency_ms, cost_paise, started_by}] }`; `started_by` is `"job <kind>"` when
  `job_id` is set, `"deploy"` for the smoke centre's rows, else `"tap"`; a null filter means all.
- `admin_call(p_id uuid) returns jsonb` or null: the row's facts plus `input` (null and `input_held: true` when
  `student_id` is set and that student's `consent_at` is null), `output`, `request_id`, `idempotency_key`, `job: {id, kind,
  step}` or null, `centre: {id, name}`, `fallback_model`, `stop_reason`, `prompt_hash`.
- `admin_jobs(p_day date, p_state text, p_kind text, p_centre uuid, p_limit int) returns jsonb`: `{ tiles: {today, failed,
  running, waiting}, rows: [...] }` as `admin_centre_jobs`' rows plus `centre`.
- `admin_job(p_id uuid) returns jsonb` or null: the row plus `error`, `input`, `idempotency_key`, `steps: [{step, attempt,
  state, note, cost_paise, generation_id, created_at}]` (`note` as the board: the time and seconds for `read`/`groups`,
  the call's kind, model and outcome for a paid step, the error's reason for a failed one).
- `admin_errors_by_route(p_hours int) returns jsonb`: `{ tiles: {requests, errors, rate_pct, timeouts, median_latency_ms},
  rows: [{route, status, reason, last_24h, last_7d}] }` (rows by route, status and reason over 7 days, ordered by
  `last_24h` then `last_7d`).
- `admin_errors_recent(p_limit int) returns jsonb` `[{created_at, route, status, reason, request_id, centre}]`.
- `admin_alerts(p_open_first boolean) returns jsonb`: `{ tiles: {open, acknowledged_week, last_raised}, rows: [{id, kind,
  message, centre, value, threshold, raised_at, acknowledged_at, acknowledged_by_email}] }`.
- `admin_audit(p_days int, p_admin uuid, p_action text, p_limit int) returns jsonb` `[{created_at, admin_email, action,
  centre, target, reason, ip}]` (`admin_email` from `admin_users`, else the audited email in `target->>'email'` for a
  refusal).

- [ ] **Step 1: the failing tests** (`admin-reads.test.ts`): the seed is not loaded under `bun check`'s db step (it resets
  `--no-seed`), so the test builds its own: centre A with two students (one with consent, one without), a batch, three
  `ai_generations` rows written through `start_ai_call` as `a` and finished by `svc` (kinds `sheet` 120 paise, `note` for
  the consented student 7 paise, `note` for the other held), two jobs (done and failed), four `api_requests`, one
  `app_opened` event. Then:

```ts
test("admin_centres counts the centre, its students and tutors, its cost and jobs, and says it is in use", async () => {
  const { data } = await svc.rpc("admin_centres", { p_month: monthStart() });
  const row = (data as { rows: Row[] }).rows.find((r) => r.id === centreA)!;
  expect(row).toMatchObject({ students: 2, tutors: 1, cost_paise: 127, in_use: true, jobs_today: 2, failed_today: 1 });
  expect((data as { tiles: { failed_today: number } }).tiles.failed_today).toBeGreaterThanOrEqual(1);
});

test("admin_centre names the tutors with email and push, and never a parent's number", async () => {
  const { data } = await svc.rpc("admin_centre", { p_centre: centreA, p_month: monthStart() });
  const text = JSON.stringify(data);
  expect(text).toContain(`admin-r-a-${stamp}@example.com`);
  expect(text).not.toContain("+919999999999");
  expect((data as { tutors: unknown[] }).tutors.length).toBe(1);
  expect((await svc.rpc("admin_centre", { p_centre: crypto.randomUUID(), p_month: monthStart() })).data).toBeNull();
});

test("admin_open_record writes the audit first and answers the students' consent states; an empty reason is refused", async () => {
  const r = await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "a support ask", p_ip: "1.1.1.1" });
  expect(r.error).toBeNull();
  const students = (r.data as { students: { name: string; consent: { state: string } }[] }).students;
  expect(students.map((s) => s.consent.state).sort()).toEqual(["given", "not_asked"]);
  expect(JSON.stringify(r.data)).not.toContain("+91");
  expect((await sql`select count(*)::int as n from public.admin_audit where action = 'open_record' and centre_id = ${centreA}`)[0].n).toBe(1);
  expect((await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "  ", p_ip: null })).error?.message).toContain("reason_required");
});

test("admin_call hides a personal kind's input without consent and shows a group kind's", async () => {
  const held = await svc.rpc("admin_call", { p_id: noteWithoutConsent });
  expect(held.data).toMatchObject({ input: null, input_held: true });
  const sheet = await svc.rpc("admin_call", { p_id: sheetCall });
  expect((sheet.data as { input: unknown; input_held: boolean }).input_held).toBe(false);
  expect((sheet.data as { input: unknown }).input).not.toBeNull();
});

test("the cost functions add up to the same rupees", async () => {
  const byCentre = (await svc.rpc("admin_cost_by_centre", { p_month: monthStart() })).data as { id: string; paise: number }[];
  const byKind = (await svc.rpc("admin_cost_by_kind", { p_month: monthStart() })).data as { paise: number }[];
  const byDay = (await svc.rpc("admin_cost_by_day", { p_month: monthStart() })).data as { paise: number }[];
  const total = byCentre.reduce((s, r) => s + r.paise, 0);
  expect(byKind.reduce((s, r) => s + r.paise, 0)).toBe(total);
  expect(byDay.reduce((s, r) => s + r.paise, 0)).toBe(total);
  expect(byDay.length).toBeGreaterThanOrEqual(28);
});

test("admin_jobs filters by state and admin_job lists the steps with their notes", async () => {
  const failed = (await svc.rpc("admin_jobs", { p_day: today(), p_state: "failed", p_kind: null, p_centre: null, p_limit: 50 })).data as { rows: { id: string }[] };
  expect(failed.rows.map((r) => r.id)).toContain(failedJob);
  const job = (await svc.rpc("admin_job", { p_id: failedJob })).data as { steps: { step: string; state: string }[] };
  expect(job.steps.map((s) => `${s.step}:${s.state}`)).toEqual(["read:done", "make:2:failed"]);
});

test("admin_errors_by_route groups by route, status and reason; admin_errors_recent is newest first", async () => {
  const by = (await svc.rpc("admin_errors_by_route", { p_hours: 24 })).data as { rows: { route: string; status: number; reason: string; last_24h: number }[] };
  expect(by.rows.find((r) => r.route === "/ai/make" && r.status === 502)?.last_24h).toBeGreaterThanOrEqual(1);
  const recent = (await svc.rpc("admin_errors_recent", { p_limit: 10 })).data as { status: number }[];
  expect(recent.every((r) => r.status >= 400)).toBe(true);
});

test("admin_alerts, admin_audit: open first; the audit names the admin's email", async () => {
  const alerts = (await svc.rpc("admin_alerts", { p_open_first: true })).data as { rows: { acknowledged_at: string | null }[] };
  const firstAck = alerts.rows.findIndex((r) => r.acknowledged_at !== null);
  expect(alerts.rows.slice(0, Math.max(firstAck, 0)).every((r) => r.acknowledged_at === null)).toBe(true);
  const audit = (await svc.rpc("admin_audit", { p_days: 30, p_admin: null, p_action: "open_record", p_limit: 10 })).data as { admin_email: string }[];
  expect(audit[0]?.admin_email).toBe(`admin-r-admin-${stamp}@example.com`);
});

test("a member cannot call any admin read", async () => {
  for (const fn of ["admin_centres", "admin_centre", "admin_activity", "admin_centre_jobs", "admin_open_record", "admin_cost_by_day", "admin_cost_by_centre", "admin_cost_by_kind", "admin_cost_tiles", "admin_calls", "admin_call", "admin_jobs", "admin_job", "admin_errors_by_route", "admin_errors_recent", "admin_alerts", "admin_audit"]) {
    expect({ fn, code: (await a.rpc(fn, {})).error?.code }).toEqual({ fn, code: "42501" });
  }
});
```

- [ ] **Step 2: RED**, then the migration: each function as its interface says, written with CTEs, every string the board
  shows built in SQL where it depends on a row (the subject of a job, the activity's `what`), nothing else. Day
  boundaries in `Asia/Kolkata`. A function that could return many rows takes `p_limit` and orders newest first.
- [ ] **Step 3: GREEN** (`bun check --only=db,tools,api`; `types.ts` regenerated).
- [ ] **Step 4: commit, PR 2, merge.** Ledger line.

---

### Task 4: `admin/`: the app, the frame, the tokens, `/health`, the gate's pieces, the `admin` check step (PR 3)

**Files:**
- Create: `admin/package.json`, `admin/biome.json`, `admin/tsconfig.json`, `admin/next.config.ts`, `admin/vercel.json`,
  `admin/.env.example`, `admin/CLAUDE.md`, `admin/proxy.ts`, `admin/app/layout.tsx`, `admin/app/globals.css`,
  `admin/app/icon.svg`, `admin/app/not-found.tsx`, `admin/app/health/route.ts`, `admin/app/page.tsx` (redirects to
  `/centres`), `admin/components/Frame.tsx`, `admin/components/parts.tsx`, `admin/components/Icon.tsx`,
  `admin/content/words.ts`, `admin/content/site.ts`, `admin/lib/env.ts`, `admin/lib/supabase/server.ts`,
  `admin/lib/supabase/service.ts`, `admin/lib/gate.ts`, `admin/lib/format.ts`, `admin/lib/data/types.ts`,
  `admin/lib/data/preview.ts`, `admin/lib/data/real.ts` (the client and the call shape; one method per page, filled by
  Tasks 6 to 12), `admin/lib/data/index.ts`, `admin/preview/frame.json`
- Create: `admin/test/unit/tokens.test.ts`, `gate.test.ts`, `format.test.ts`, `frame.test.ts`, `words.test.ts`;
  `admin/test/build/secret.test.ts`, `health.test.ts`
- Modify: `package.json` (the workspace, if `web` is listed; the `admin-shots` script comes in Task 14), `bun.lock`,
  `bunfig.toml` (nothing: hoisted already), `tools/check/steps.ts`, `.github/workflows/check.yml`, `.gitignore`
  (`admin/.next`, `admin/next-env.d.ts`, `admin/*.tsbuildinfo`, `admin/.env.local`, `admin/.vercel`)

**Interfaces:**
- `admin/package.json` scripts: `dev` (`next dev -p 3100`), `build`, `start`, `check` (`biome ci . && next typegen &&
  tsc --noEmit -p tsconfig.json && bun test test/unit && SUPABASE_SERVICE_ROLE_KEY=sb_secret_build_probe_do_not_use
  SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=probe next build && bun test test/build`); dependencies `next`
  16.4.0, `react` 19.3.0, `react-dom` 19.3.0, `@supabase/supabase-js` 2.117.2, `@supabase/ssr` 0.12.7, `zod` 4.6.5,
  `server-only` 0.0.1; dev `@biomejs/biome` 2.5.15, `@types/bun` 1.3.11, `@types/react` 19.3.0, `@types/react-dom`
  19.3.0, `typescript` 5.9.3.
- `lib/env.ts`: `env("SUPABASE_URL" | "SUPABASE_ANON_KEY" | "SUPABASE_SERVICE_ROLE_KEY")`, `commit()` (`TC_COMMIT` or
  "local"), `preview()` (true when `ADMIN_PREVIEW === "1"`; throws `"ADMIN_PREVIEW is for local runs"` when
  `VERCEL_ENV === "production"`).
- `lib/gate.ts`: `type Decision = { to: "sign-in" } | { to: "refused"; email: string } | { to: "enrol" } | { to: "verify" }
  | { to: "ok"; admin: Admin }`; `type Admin = { userId: string; email: string }`; `decide(input: { user: { id: string;
  email: string } | null; admin: Admin | null; verifiedFactors: number; currentLevel: "aal1" | "aal2" | null }): Decision`;
  `requireAdmin(): Promise<Admin>` (redirects by the decision; in preview answers `{ userId: "preview", email:
  "preview@tutorcentral.in" }` without reading anything).
- `lib/format.ts`: `rupees(paise: number): string` ("₹0.07", "₹2.84", "₹182", "₹1,240"), `when(iso: string, now: Date):
  string` ("Today 06:48", "Yesterday 19:20", "11 Oct 18:10", "3 days ago" for a day-only need: `ago(iso, now)`),
  `seconds(ms)`, `count(n)`.
- `lib/data/types.ts`: the TypeScript shapes of Task 3's answers (`Centres`, `Centre`, `Record`, `Cost`, `Calls`, `Call`,
  `Jobs`, `Job`, `Errors`, `Alerts`, `Audit`) and `type Data = { centres(month): Promise<Centres>; centre(id, month):
  Promise<Centre | null>; activity(id, limit); centreJobs(id, limit); openRecord(admin, id, reason, ip): Promise<Record>;
  cost(month): Promise<Cost>; calls(filters): Promise<Calls>; call(id): Promise<Call | null>; jobs(filters): Promise<Jobs>;
  job(id): Promise<Job | null>; errors(hours, limit): Promise<Errors>; alerts(openFirst): Promise<Alerts>; audit(filters):
  Promise<Audit>; acknowledge(admin, alert, ip): Promise<boolean>; retry(admin, job, ip): Promise<boolean>; cancel(admin,
  job, ip): Promise<boolean>; auditWrite(admin, action, centre, target, reason, ip): Promise<void> }`.
- `components/Frame.tsx`: `Frame({ current, admin, children })` renders the header (brand with the ADMIN mark, the nav
  with the current page marked, Sign out as a form posting to `/sign-out`), `main`, the footer with the API's commit and
  the audit line; `AuthFrame({ children })` for the sign-in pages.
- `app/health/route.ts`: `GET` answers `{ ok: true, commit }` with no session.

- [ ] **Step 1: the failing unit tests.** `tokens.test.ts` is the website's test with `USED` extended by `ok`, `okTint`,
  `due`, `dueTint`, `overdue`, `overdueTint`; `gate.test.ts`:

```ts
import { expect, test } from "bun:test";
import { decide } from "../../lib/gate";
const user = { id: "u1", email: "you@tutorcentral.in" };
const admin = { userId: "u1", email: "you@tutorcentral.in" };
test("decide: no user is sign-in", () => expect(decide({ user: null, admin: null, verifiedFactors: 0, currentLevel: null })).toEqual({ to: "sign-in" }));
test("decide: no admin row is refused whatever the level", () => {
  expect(decide({ user, admin: null, verifiedFactors: 1, currentLevel: "aal2" })).toEqual({ to: "refused", email: user.email });
});
test("decide: an admin with no verified factor is enrol", () => expect(decide({ user, admin, verifiedFactors: 0, currentLevel: "aal1" })).toEqual({ to: "enrol" }));
test("decide: an admin at aal1 with a verified factor is verify", () => expect(decide({ user, admin, verifiedFactors: 1, currentLevel: "aal1" })).toEqual({ to: "verify" }));
test("decide: an admin at aal2 is ok", () => expect(decide({ user, admin, verifiedFactors: 1, currentLevel: "aal2" })).toEqual({ to: "ok", admin }));
```

  `format.test.ts` pins the examples above (`rupees(7)` "₹0.07", `rupees(284)` "₹2.84", `rupees(18200)` "₹182",
  `rupees(124000)` "₹1,240"; `when` at a fixed `now` in IST). `frame.test.ts` renders `Frame` with `react-dom/server` and
  asserts the seven nav labels, `aria-current="page"` on the current one, "Sign out", the ADMIN mark and the footer's
  commit. `words.test.ts`: every `app/**/page.tsx` outside `app/sign-in`, `app/mfa`, `app/refused`, `app/not-found.tsx`
  contains `requireAdmin(` (reads the files; at this task only `app/page.tsx` and the not-found exist, both exempt by
  being a redirect and the not-found). `test/build/secret.test.ts`:

```ts
import { expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
const NEXT = join(import.meta.dir, "..", "..", ".next");
const PROBE = "sb_secret_build_probe_do_not_use";
function files(dir: string): string[] { return readdirSync(dir).flatMap((f) => { const p = join(dir, f); return statSync(p).isDirectory() ? files(p) : [p]; }); }
test("the service key is in no build output", () => {
  const hits = files(NEXT).filter((f) => readFileSync(f).includes(PROBE));
  expect(hits).toEqual([]);
});
test("the gate's service client is server-only", () => {
  expect(readFileSync(join(import.meta.dir, "..", "..", "lib", "supabase", "service.ts"), "utf8")).toContain('import "server-only"');
});
```

  `health.test.ts` asserts `.next/server/app/health/route.js` exists.
- [ ] **Step 2: RED** (`cd admin && bun test test/unit` fails on missing modules).
- [ ] **Step 3: the app.** `bun add --exact` the dependencies from `admin/`. `globals.css` is the website's token block
  (both schemes) plus the six status tokens and the portal's classes from the boards (`.wrap`, `.hdr`, `.nav`, `.t1`,
  `.h2`, `.h3`, `.lead`, `.sec`, `.tiles`, `.cols2`, `.card`, `.grid`, `.cell`, `.acts`, `.bars`, `.filters`, `.ftr`,
  `.centered`, `.auth`, the `@container (max-width: 760px)` block), copied from `docs/design/mockups/P19-Centres.dc.html`'s
  helmet so the build cannot drift from the boards. `layout.tsx` as the website's with `<meta name="tc-commit">`.
  `lib/supabase/server.ts`: `createServerClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), { cookies: { getAll, setAll
  } })` over `next/headers`' `cookies()` as `@supabase/ssr`'s documentation gives it for the App Router.
  `lib/supabase/service.ts`: `import "server-only"`; `createClient(url, env("SUPABASE_SERVICE_ROLE_KEY"), { auth: {
  persistSession: false, autoRefreshToken: false } })`. `lib/gate.ts`: `decide` as the tests say; `requireAdmin` reads
  `auth.getUser()`, `auth.mfa.getAuthenticatorAssuranceLevel()`, `auth.mfa.listFactors()` (verified = `totp.filter(f =>
  f.status === "verified").length`), the row through the service client (`from("admin_users").select("user_id,
  email").eq("user_id", id).maybeSingle()`), then `redirect("/sign-in" | "/refused" | "/mfa/enrol" | "/mfa/verify")`.
  `proxy.ts`: the SSR client's cookie refresh (`getUser()`), and a request with no user for a path outside the public set
  answered with a redirect to `/sign-in`. `lib/data/preview.ts` answers `preview/*.json` (only `frame.json` now: the
  admin's email for the header); `real.ts` holds `rpc` with the service client and the method names, each `throw new
  Error("not yet")` until its task.
- [ ] **Step 4: the check step.** `tools/check/steps.ts` gains `admin` after `web` with the web step's inputs under
  `admin/` and `docs/design/design-tokens.md`; `check.yml`'s Ubuntu job runs `--only=api,web,admin,db`; `.gitignore`.
- [ ] **Step 5: GREEN** (`bun check --only=admin,tools`): Biome, typegen, tsc, the unit tests, the build with the probe,
  the build tests.
- [ ] **Step 6: `admin/CLAUDE.md`**: the rules as `web/CLAUDE.md`'s form: the three variables and where they live; every
  page behind `requireAdmin`; reads through `Data`; words in `content/`; the preview mode's rule; the commands.
- [ ] **Step 7: the first `admin-shots`** (`tools/admin-shots.ts`, its final form in Task 14): `bun admin-shots` builds
  `admin/` with `ADMIN_PREVIEW=1`, starts `next start` on a free port, photographs the pages given (`--pages`) at 1280 and
  390, dark and light, with `cdp` from `tools/web-shots.ts`, into `.shots/admin/`. For this PR: `/nothing-here` (the
  not-found page in the frame). Pictures by `bun pr-shots`.
- [ ] **Step 8: commit, PR 3, merge.** Ledger line.

---

### Task 5: Sign in, the second factor, refused, sign out; the audit of each (PR 4)

**Files:**
- Create: `admin/app/sign-in/page.tsx`, `admin/app/sign-in/actions.ts`, `admin/app/mfa/enrol/page.tsx`,
  `admin/app/mfa/enrol/actions.ts`, `admin/app/mfa/verify/page.tsx`, `admin/app/mfa/verify/actions.ts`,
  `admin/app/refused/page.tsx`, `admin/app/sign-out/route.ts`, `admin/lib/audit.ts`, `admin/lib/request.ts` (the
  caller's address from `x-forwarded-for`), `tools/totp.ts`, `tools/totp.test.ts`, `admin/test/db/gate.test.ts`,
  `admin/test/unit/auth-pages.test.ts`
- Modify: `admin/content/words.ts`, `admin/lib/data/real.ts` (`auditWrite`), `admin/preview/frame.json`

**Interfaces:**
- `/sign-in`: the form (email, password) posts to `signIn(formData)`: `auth.signInWithPassword`; a failure re-renders with
  the board's line "That email and password do not match." (`?failed=1`); success runs `decide` and redirects.
- `/mfa/enrol`: the page calls `auth.mfa.enroll({ factorType: "totp", friendlyName: "Tutor Central admin" })` when the
  user has no verified factor (an unverified one from an abandoned attempt is unenrolled first), shows `totp.qr_code`
  (an SVG data URL Supabase returns) and `totp.secret` in groups of four; the form posts `enrol(formData)` with the
  factor id and the code: `auth.mfa.challengeAndVerify({ factorId, code })`; success writes the audit `enrol_totp` and
  redirects to `/centres`; a wrong code re-renders with "That code did not match. Codes change every 30 seconds."
- `/mfa/verify`: lists the verified factor, `challengeAndVerify` on the code, the audit `sign_in` with reason "second
  factor verified", redirect to the page asked for (`?next=`, same-origin paths only) or `/centres`.
- `/refused`: the board's page with the signed-in email; the audit row `refused` with `target {email}` written once per
  visit; Sign out.
- `/sign-out` (POST): `auth.signOut()`, the audit `sign_out` when an admin, redirect to `/sign-in`.
- `tools/totp.ts`: `totp(secretBase32: string, at: number = Date.now(), step = 30, digits = 6): string` (HMAC-SHA1, RFC
  6238); `bun tools/totp.ts <secret>` prints the current code (for the hand runs).

- [ ] **Step 1: the failing tests.** `tools/totp.test.ts` with RFC 6238's SHA-1 vectors (secret `12345678901234567890` as
  base32 `GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ`: at 59 s → `287082`, at 1111111109 s → `081804`, at 1234567890 s →
  `005924`). `auth-pages.test.ts` renders the four pages with `react-dom/server` and asserts the boards' words ("Sign in",
  "Your admin email and password, then the code from your authenticator.", "Set up your authenticator", "Or type the
  key", "Enter your code", "This account cannot use the admin portal", "not on the admin list"). `test/db/gate.test.ts`
  (skipped with a line when `supabase status` fails, as the API's local-stack tests):

```ts
test("an admin enrols, verifies with a computed code, and is ok at aal2; a tutor is refused; a new admin is enrol", async () => {
  const l = await local();
  const admin = await userClient(l, `gate-admin-${stamp}@example.com`);
  const id = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${id}, ${`gate-admin-${stamp}@example.com`})`;
  const before = await levelOf(admin);                       // { current: "aal1", verified: 0 }
  expect(decide({ user: { id, email }, admin: { userId: id, email }, verifiedFactors: before.verified, currentLevel: before.current }).to).toBe("enrol");
  const enrolled = await admin.auth.mfa.enroll({ factorType: "totp", friendlyName: "test" });
  const code = totp(enrolled.data!.totp.secret);
  expect((await admin.auth.mfa.challengeAndVerify({ factorId: enrolled.data!.id, code })).error).toBeNull();
  const after = await levelOf(admin);                        // { current: "aal2", verified: 1 }
  expect(decide({ user: { id, email }, admin: { userId: id, email }, verifiedFactors: after.verified, currentLevel: after.current }).to).toBe("ok");
  const tutor = await userClient(l, `gate-tutor-${stamp}@example.com`);
  const t = (await tutor.auth.getUser()).data.user!;
  expect(decide({ user: { id: t.id, email: t.email! }, admin: null, verifiedFactors: 0, currentLevel: "aal1" })).toEqual({ to: "refused", email: t.email });
});
```

- [ ] **Step 2: RED.** Then the pages and actions, each page's words from `content/words.ts`, the forms as the boards
  draw them (the field, the primary button, the small line under). `lib/audit.ts`: `audit(action, { centre, target,
  reason })` reads the admin and the address and calls `data.auditWrite`.
- [ ] **Step 3: GREEN** (`bun check --only=admin,tools,db`); the gate test on the local stack passes with a real
  enrolment.
- [ ] **Step 4: pictures** (`bun admin-shots --pages /sign-in,/mfa/enrol,/mfa/verify,/refused`; in preview the enrol page
  shows a stand-in QR from `preview/frame.json`), by `bun pr-shots`.
- [ ] **Step 5: commit, PR 4, merge.** Ledger line.

---

### Task 6: The centres list and a centre's page (PR 5)

**Files:**
- Create: `admin/app/centres/page.tsx`, `admin/app/centres/[id]/page.tsx`, `admin/preview/centres.json`,
  `admin/preview/centre.json`, `admin/content/activity.ts`, `admin/test/unit/centres.test.ts`, `admin/test/unit/activity.test.ts`
- Modify: `admin/lib/data/real.ts` (`centres`, `centre`, `activity`, `centreJobs`), `admin/lib/data/types.ts`,
  `admin/components/parts.tsx` (tiles, table, chip, progress, select pill: each a function with the boards' inline sizes)

**Interfaces:**
- `/centres?month=2026-10&sort=cost|name|opened&show=all|in-use|idle`: the four tiles, the table with the allowance bar
  (`progress(paise / 49900)`, `due` tone over 80%), "idle" chip when not in use, each row linking to `/centres/<id>`.
- `/centres/<id>?month=`: as P19-Centre: the title line, the "in use" chip, the four tiles, Tutors and cost (two columns),
  Jobs (the last five, "All jobs of this centre" → `/jobs?centre=<id>`), Activity (two columns: the table and the record
  card with "Open the record" → `/centres/<id>?ask=1`, Task 7). A gone centre: `notFound()`.
- `content/activity.ts`: `words(kind: string, screen: string | null): string` (decision 16); a kind not listed answers
  the kind with underscores as spaces.

- [ ] **Step 1: the failing tests.** `centres.test.ts` renders both pages from `preview.ts` and asserts: the list holds
  "All centres", every preview centre's name, "idle" once, "of ₹499"; the centre page holds "Tutors and cost",
  "Open the record", "All jobs of this centre", the tutor's email and never a "+91"; `a centre that is gone is not found`
  (the page function with an unknown id throws Next's not-found). `activity.test.ts`: `words("app_opened", null)` →
  "Opened the app"; `words("tab_opened", "today")` → "Opened Today"; `words("link_opened", "fees")` → "Opened a link ·
  Fees"; an unknown kind → its own words.
- [ ] **Step 2: RED**, then the pages: a server component reads `data.centres(month)` (the query from `searchParams`,
  the month defaulting to this one in India), renders the parts. Sorting and `show` are applied in the page from the rows
  (small lists) — not in SQL.
- [ ] **Step 3: GREEN**; pictures (`bun admin-shots --pages /centres,/centres/preview`; preview ids are `preview`);
  commit, PR 5, merge. Ledger line.

---

### Task 7: The audited open of a centre's record (PR 6)

**Files:**
- Create: `admin/app/centres/[id]/actions.ts`, `admin/app/centres/[id]/record/page.tsx`, `admin/preview/record.json`,
  `admin/test/unit/record.test.ts`
- Modify: `admin/app/centres/[id]/page.tsx` (`?ask=1` renders the dialog over the page, P19-Centre-OpenAsk),
  `admin/lib/data/real.ts` (`openRecord`), `admin/components/parts.tsx` (`dialog`)

**Interfaces:**
- The dialog's form posts `openRecord(formData)`: `requireAdmin()`, the reason trimmed (1 to 200 characters, else back to
  `?ask=1&empty=1` with "Say why: the reason goes into the audit."), `data.openRecord(admin.userId, id, reason, ip)`,
  the answer kept for the page by one short-lived cookie `tc-record-<id>` holding the audit row's id (HttpOnly, 10
  minutes), then `redirect("/centres/<id>/record")`.
- `/centres/<id>/record`: reads the cookie; none → `redirect("/centres/<id>?ask=1")`; with it, `data.record(auditId)`
  (`admin_record_opened(p_audit uuid)`: answers the record only for an `open_record` row under ten minutes old; added to
  0047 by this task as `20261122000048_v3_admin_record_opened.sql`, so the record is never re-read without its audit row
  and a bookmark of the URL opens the ask again). The banner "Opened at <time> by you · reason: <reason> · written to
  the audit", Students, Batches, What the AI service made about these students.

- [ ] **Step 1: the failing tests.** `record.test.ts`: the page from preview holds "Opened at", "written to the audit",
  the six students' names, "given · 12 Oct", "withdrawn · 12 Oct", "not asked", "Nothing kept" when `made` is empty, and
  never "+91"; `the record page without a reason sends to the ask` (the page function with no cookie throws Next's
  redirect to `/centres/preview?ask=1`); the action's reason check (`reasonOf(formData)` returns null for "  " and for
  201 characters). The migration's test in `supabase/tests/admin-reads.test.ts`: `admin_record_opened answers for a
  fresh open_record row and not for one eleven minutes old or of another action`.
- [ ] **Step 2: RED**, then the dialog (absolute over the page as the board), the action, the page, the migration.
- [ ] **Step 3: GREEN** (`bun check --only=admin,db,tools`); pictures (`/centres/preview?ask=1`,
  `/centres/preview/record` — in preview the cookie is not needed); commit, PR 6, merge. Ledger line.

---

### Task 8: Cost (PR 7)

**Files:**
- Create: `admin/app/cost/page.tsx`, `admin/preview/cost.json`, `admin/test/unit/cost.test.ts`
- Modify: `admin/lib/data/real.ts` (`cost`: the four functions in one `Promise.all`), `admin/components/parts.tsx` (`bars`)

- [ ] **Step 1: the failing test:** the page from preview holds "By day, all centres", "the alert line is ₹60 a day for
  one centre", "By centre, and by kind and model", every kind row of the fixture, "of ₹499", and the highest day's label
  over its bar; a month with no calls renders the chart with zero-height bars and "₹0" tiles (a second fixture
  `cost-empty.json`).
- [ ] **Step 2: RED**, then the page: `?month=` (this month in India by default, "Month" pill lists the last six),
  `?centre=` narrows the day chart and the kind table (`admin_cost_by_day` and `admin_cost_by_kind` gain an optional
  `p_centre uuid default null` in `20261122000048_…` (the same migration as Task 7's, both written in whichever task comes
  first)). Bars: height by the month's largest day; a day over ₹60 for the chosen centre in `overdue`.
- [ ] **Step 3: GREEN**; pictures (`/cost`); commit, PR 7, merge. Ledger line.

---

### Task 9: The AI calls and one call (PR 8)

**Files:**
- Create: `admin/app/calls/page.tsx`, `admin/app/calls/[id]/page.tsx`, `admin/preview/calls.json`,
  `admin/preview/call.json`, `admin/test/unit/calls.test.ts`
- Modify: `admin/lib/data/real.ts` (`calls`, `call`), `admin/components/parts.tsx` (`code`)

**Interfaces:**
- `/calls?day=&centre=&kind=&outcome=`: tiles, the table (time, centre, kind with model and prompt version under it,
  outcome chip: `ok` ok, `ok · replayed` neutral, `failed · <reason>` overdue, `refused` due, `unfit` due, `pending`
  neutral; tokens "in · out"; latency; cost; from), each row linking to `/calls/<id>`.
- `/calls/<id>`: the facts table and the Input and Output blocks; "Held: the student's consent is not current" in the
  input's place when `input_held`; "Open the job" when `job` is set.

- [ ] **Step 1: the failing tests:** the list from preview holds "AI calls", "Today, newest first", "failed · timeout",
  "ok · replayed", "job plan", "tap", "deploy"; the call page holds "sheet · a group kind (no student)", "no fallback",
  "the deadline", "Open the job", the input's `"kind": "sheet"`; `a held input shows the consent line and no input` (a
  second fixture `call-held.json` with `input_held: true`: the page holds "Held: the student’s consent is not current"
  and not `"kind":`).
- [ ] **Step 2: RED**, then the pages.
- [ ] **Step 3: GREEN**; pictures (`/calls`, `/calls/preview`); commit, PR 8, merge. Ledger line.

---

### Task 10: Jobs and their steps; Retry and Cancel (PR 9)

**Files:**
- Create: `admin/app/jobs/page.tsx`, `admin/app/jobs/actions.ts`, `admin/preview/jobs.json`, `admin/preview/job.json`,
  `admin/test/unit/jobs.test.ts`
- Modify: `admin/lib/data/real.ts` (`jobs`, `job`, `retry`, `cancel`)

**Interfaces:**
- `/jobs?day=&state=&kind=&centre=&open=<id>`: tiles, the list; the row named by `open` renders expanded under itself
  (P19-Jobs): the error line, Cancel (for `queued`, `waiting`, `running`) and "Retry from the failed step" (for `failed`),
  the steps table; each row's kind links to `?open=<id>` keeping the filters.
- `actions.ts`: `retryJob(formData)` and `cancelJob(formData)`: `requireAdmin()`, `data.retry`/`data.cancel` (the
  functions write their own audit rows), redirect back to `/jobs?…&open=<id>` with `&done=retried|cancelled|refused`
  (the row's banner "Queued again" / "Cancelled" / "Nothing changed: the job is no longer in that state").

- [ ] **Step 1: the failing tests:** the page from preview with `open` set holds "Retry from the failed step",
  "Cancel", "the lease lapsed on the last attempt", every step of the fixture ("make:2", "timeout on three tries"), the
  chips "done · 11 of 11 made", "running · make:3", "waiting", "cancelled"; without `open` no step is shown; `the retry
  action refuses a job that is not failed` (the action with a fake `Data` whose `retry` answers false redirects with
  `done=refused`).
- [ ] **Step 2: RED**, then the page and the actions. A `Data` for the action tests is injected through
  `lib/data/index.ts`'s `dataFor(preview: boolean)` and a test seam `withData(fake, fn)`.
- [ ] **Step 3: GREEN**; pictures (`/jobs?open=preview-failed`); commit, PR 9, merge. Ledger line.

---

### Task 11: Errors (PR 10)

**Files:**
- Create: `admin/app/errors/page.tsx`, `admin/preview/errors.json`, `admin/content/reasons.ts`,
  `admin/test/unit/errors.test.ts`, `admin/test/unit/reasons.test.ts`
- Modify: `admin/lib/data/real.ts` (`errors`)

- [ ] **Step 1: the failing tests:** the page from preview holds "By route and reason", "The latest", "timeout · the
  model did not answer in 110 s", "student_consent · a note asked without consent", "sign in again · a stale token",
  every request id of the fixture's latest; `reasons.test.ts`: `reasonWords("timeout")`, `reasonWords("unknown_thing")`
  → "unknown_thing".
- [ ] **Step 2: RED**, then the page (`?hours=24|168`, `?route=`).
- [ ] **Step 3: GREEN**; pictures (`/errors`); commit, PR 10, merge. Ledger line.

---

### Task 12: Alerts with Acknowledge; the audit page (PR 11)

**Files:**
- Create: `admin/app/alerts/page.tsx`, `admin/app/alerts/actions.ts`, `admin/app/audit/page.tsx`,
  `admin/preview/alerts.json`, `admin/preview/audit.json`, `admin/test/unit/alerts.test.ts`, `admin/test/unit/audit.test.ts`
- Modify: `admin/lib/data/real.ts` (`alerts`, `acknowledge`, `audit`)

**Interfaces:**
- `/alerts?show=open-first|newest`: tiles (open, acknowledged this week, last raised, "Email + push"), the table with an
  Acknowledge form per open row (`acknowledge(formData)` → `data.acknowledge`, redirect back), the lines card with the
  four thresholds and "The lines change in Phase 22."
- `/audit?days=30&who=&action=`: the table; the viewer's own rows say "you" in Who.

- [ ] **Step 1: the failing tests:** the alerts page holds "Open first", two "Acknowledge" buttons for the fixture's
  two open rows, "acknowledged · 07:20", "The lines, checked every ten minutes by the alerts job", "a centre over ₹60 in
  a day"; the audit page holds "open_record", "retry_job", "acknowledge_alert", "refused", "enrol_totp", "you" for the
  viewer's rows and the other email for the refusal's.
- [ ] **Step 2: RED**, then the pages and the action.
- [ ] **Step 3: GREEN**; pictures (`/alerts`, `/audit`); commit, PR 11, merge. Ledger line.

---

### Task 13: The `alerts` job: the four lines, raised once, emailed, pushed (PR 12)

**Files:**
- Create: `api/src/alerts/lines.ts`, `api/src/alerts/resend.ts`, `api/src/alerts/db.ts`, `api/src/jobs/kinds/alerts.ts`,
  `api/test/alerts-lines.test.ts`, `api/test/alerts-job.test.ts`, `api/test/resend.test.ts`
- Modify: `api/src/jobs/types.ts` (`"alerts"` in `JobKind`), `api/src/jobs/kinds/index.ts` (`alerts: alertsJob(sources.alerts)`),
  `api/src/routes/jobs.ts` (the tick: `if ((await worker.jobs.live("alerts")) === 0) await worker.jobs.enqueue(null,
  "alerts", alertsKey(clock.now()))`, `alertsKey` as `sweepKey` with the prefix `alerts:`), `api/src/env.ts`
  (`RESEND_API_KEY`, `ALERT_EMAIL`), `api/src/index.ts` (the sender: real when `RESEND_API_KEY` is set, else the logging
  fake; production refuses to start without it and `ALERT_EMAIL`, as the APNs variables), `api/.env.example`,
  `api/test/jobs-routes.test.ts` (the tick queues both keys), `api/test/platform-db.test.ts` (an alert raised on the
  local stack), `api/CLAUDE.md`

**Interfaces:**
- `lines.ts`: `type Facts = { failedJobs: { id; kind; centreId: string | null; input: Record<string, unknown> }[];
  costToday: { centreId: string; paise: number }[]; requestsHour: { total: number; errors: number }; stuckJobs: { id;
  kind; centreId; startedAt: string }[] }`; `type Alert = { key: string; kind: "job_failed" | "cost_day" | "error_rate" |
  "job_stuck"; centreId: string | null; threshold: number; value: number; message: string }`; `const LINES = { costDayPaise:
  6000, errorRatePct: 5, errorRateMinRequests: 20, stuckMinutes: 10 }`; `alertsFor(facts: Facts, now: Date): Alert[]`
  (the day for `cost_day`'s key in `Asia/Kolkata`; the hour for `error_rate`'s key as `YYYY-MM-DDTHH` UTC; messages as
  the board: "a plan job failed after 3 tries", "a centre’s cost today over the line: ₹72, over ₹60", "errors over 5% of
  requests in an hour: 6.1%", "a job running over 10 minutes: plan, 14 min").
- `resend.ts`: `type Sender = { send(to: string, subject: string, text: string): Promise<void> }`; `makeResend(apiKey:
  string, from = "Tutor Central <hello@tutorcentral.in>"): Sender` (POST `https://api.resend.com/emails`, JSON `{ from,
  to, subject, text }`, bearer; a non-2xx throws with the status); `fakeSender()` records calls.
- `db.ts`: `type AlertsSource = { facts(now: Date): Promise<Facts>; raise(alert: Alert): Promise<boolean>; targets():
  Promise<{ user: string; centre: string }[]>; notify(centre: string, user: string, rows: NotificationRow[]):
  Promise<void> }`; `makeAlertsDb(url, serviceKey, outbox: OutboxDb)` over `alert_facts`, `raise_alert`,
  `admin_push_targets` and `outbox.replace(centre, user, [], now, rows)`; `fakeAlertsSource(facts)`.
- `alerts.ts`: `alertsJob(source: AlertsSource, sender: Sender, alertEmail: string): JobHandler`: one step `check`:
  facts → `alertsFor` → for each, `raise`; for each new one, the email (subject "Tutor Central alert: <kind>", text the
  message, the centre id and the portal's page `https://admin.tutorcentral.in/alerts`) and the push row `{ kind: "alert",
  key: "alert:<alert key>", due_at: now, title: "Tutor Central needs a look", body: <message> }` to each target; done with
  `{ checked: n, raised: m, emailed: m, pushed: targets × m }`. An email that fails is logged and the step still ends
  done (the alert row stands; the push went); the ledger records it as a known gap for Phase 22's retries.

- [ ] **Step 1: the failing tests.** `alerts-lines.test.ts`: `a failed job is one alert keyed by the job`; `a centre at
  ₹60.00 is not over the line, ₹60.01 is`; `the error rate needs 20 requests` (19 requests, 5 errors → none; 20 and 2 →
  10% → one, keyed by the hour); `a job running 9 minutes is not stuck, 11 is`; `no facts, no alerts`. `alerts-job.test.ts`
  (the fake source, the fake sender, a fake outbox): `a new alert is raised, emailed to ALERT_EMAIL and pushed to each
  target`; `the same failed job raises one alert across two runs` (the fake's `raise` answers false the second time; no
  second email, no second push); `the error rate alert is keyed by the hour` (two runs in one hour → one; the next hour →
  another); `a failing email leaves the step done and logged`. `resend.test.ts`: the request's shape with a fake fetch;
  a 422 throws. `jobs-routes.test.ts`: `the tick queues alerts:<ten minutes> beside the sweep`. `platform-db.test.ts`:
  `an alerts job on the local stack raises job_failed for a job failed by the runner and writes the push row` (a job of
  kind `artefact`, which no handler runs, fails at once; the next alerts step raises it; `alerts` holds the key;
  `notifications` holds one `alert` row for the test's target).
- [ ] **Step 2: RED**, then the code; `bun add` nothing (fetch only).
- [ ] **Step 3: GREEN** (`bun check --only=api,tools,db`, the local stack up).
- [ ] **Step 4: commit, PR 12, merge.** Then **Deploy A** (`gh workflow run deploy`): 0046 to 0048 and the API; the
  smoke green; the first `alerts` job in production seen done (`supabase db query --linked`); the ledger line with the
  run number. `RESEND_API_KEY` and `ALERT_EMAIL` must be on Vercel before it (Task 1 B); the session checks `vercel env
  ls` shows both (names only) first.

---

### Task 14: Preview mode and `bun admin-shots`; every page's pictures (PR 13)

**Files:**
- Create: `tools/admin-shots.ts`, `tools/admin-shots.test.ts`, `admin/test/unit/preview.test.ts`
- Modify: `admin/lib/env.ts` (`preview()`'s production refusal, if not in Task 4), `admin/lib/data/preview.ts` (every
  method answered from `preview/*.json`), `package.json` (the `admin-shots` script), `CLAUDE.md` (the command),
  `admin/CLAUDE.md`

**Interfaces:**
- `bun admin-shots [--pages a,b] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/admin]`: builds
  `admin/` (`ADMIN_PREVIEW=1 next build`, with the probe variables), starts `next start -p <free port>` with
  `ADMIN_PREVIEW=1`, waits for `/health`, photographs each page (default: the fifteen boards' paths: `/sign-in`,
  `/mfa/enrol`, `/mfa/verify`, `/refused`, `/centres`, `/centres/preview`, `/centres/preview?ask=1`,
  `/centres/preview/record`, `/cost`, `/calls`, `/calls/preview`, `/jobs?open=preview-failed`, `/errors`, `/alerts`,
  `/audit`) at each width and appearance, full page at 2×, with `cdp` from `tools/web-shots.ts`; file names
  `<page>-<width>-<appearance>.png` (`sign-in`, `mfa-enrol`, `centres-preview-ask`, …); exits 1 on a sideways page
  (`sideways` from web-shots) or a non-200.
- `preview()` in production: `env.ts` throws at import when `VERCEL_ENV === "production"` and `ADMIN_PREVIEW` is set;
  `proxy.ts` imports it, so the app fails to serve at all.

- [ ] **Step 1: the failing tests.** `admin-shots.test.ts`: the argument parsing and `shotName("/centres/preview?ask=1",
  390, "dark")` → `centres-preview-ask-390-dark.png`. `preview.test.ts`: `preview()` is false with no variable; true with
  `ADMIN_PREVIEW=1` and no `VERCEL_ENV`; throws "ADMIN_PREVIEW is for local runs" with `VERCEL_ENV=production` (set and
  unset `process.env` in the test).
- [ ] **Step 2: RED**, then the tool and the refusal.
- [ ] **Step 3: GREEN**; `bun admin-shots` whole: 60 pictures, each looked at against its board (a contact sheet by the
  canvas memory's method); differences fixed in this PR where the build drifted from a board; by `bun pr-shots`.
- [ ] **Step 4: commit, PR 13, merge.** Ledger line.

---

### Task 15: `deploy-admin.yml` with the gate and the smoke; the project, its variables and domain (PR 14)

**Files:**
- Create: `.github/workflows/deploy-admin.yml`, `tools/admin-smoke.ts`, `tools/admin-smoke.test.ts`
- Modify: `admin/vercel.json` (`{"git": {"deploymentEnabled": false}}`), `CLAUDE.md` (the command and the table's row),
  `plan/STATE.md`'s Production section (at the close)

**Interfaces:**
- `deploy-admin.yml`: `workflow_dispatch` with `commit`; jobs `gate` (as `deploy.yml`'s: `tools/check-gate.ts`), then
  `deploy` (as `deploy-web.yml`'s: checkout, Bun, `bun install --frozen-lockfile`, `vercel pull --environment=production`,
  `vercel build --prod` with `TC_COMMIT`, `vercel deploy --prebuilt --prod`, the summary with the rollback, the smoke);
  env `VERCEL_PROJECT_ID: ${{ vars.VERCEL_ADMIN_PROJECT_ID }}`, `SITE: ${{ vars.ADMIN_ORIGIN }}`.
- `tools/admin-smoke.ts <origin> --commit <sha>`: `/health` 200 with `{ ok: true, commit }` equal to the sha;
  `/sign-in` 200 containing "Sign in"; `/centres`, `/jobs`, `/alerts`, `/calls/abc` each answering a redirect to
  `/sign-in` (no body of a page); `/nothing-here` 404 with "There is nothing at this address."; `http://` redirecting to
  https. Retries as `web-smoke.ts`. The test with a fake fetch covers each failure's words.

- [ ] **Step 1: the failing test** (`admin-smoke.test.ts`): a fake fetch answering the happy path → no problems; a
  `/centres` that answers 200 → "`/centres` served a page without a session"; a wrong commit → "serves …, not …".
- [ ] **Step 2: RED**, then the smoke and the workflow.
- [ ] **Step 3: the project** (D87, the session): `cd admin && vercel link --yes --project tutor-central-admin` (creates
  the project under "Arun's projects"); the owner's step C (Root Directory `admin`); `vercel env add SUPABASE_URL
  production` and `SUPABASE_ANON_KEY` from the API project's values (`cd api && vercel env pull --environment=production
  <scratchpad>/api.env`, then `grep '^SUPABASE_URL=' … | cut -d= -f2- | tr -d '"' | vercel env add SUPABASE_URL production
  --cwd ../admin`, the same for the anon and the service key, then `rm` the file; nothing printed; the ledger says the
  three names); `gh variable set VERCEL_ADMIN_PROJECT_ID --body "$(jq -r .projectId admin/.vercel/project.json)"`,
  `gh variable set ADMIN_ORIGIN --body https://admin.tutorcentral.in`; `vercel domains add admin.tutorcentral.in` in
  `admin/` (prints the CNAME's value) → the owner's step D with that value; `admin/.vercel/` ignored.
- [ ] **Step 4: GREEN** (`bun check --only=tools`); commit, PR 14, merge.
- [ ] **Step 5: the first deploy** (`gh workflow run deploy-admin`): the gate passes on `main`'s green check, the build,
  the deploy, the smoke green at `https://admin.tutorcentral.in` once the CNAME answers (until then the smoke runs
  against the `*.vercel.app` address by `ADMIN_ORIGIN` set to it for the first run, then changed). Ledger line with the
  run number and the served commit.

---

### Task 16: The runbook and the hand runs (PR 15 for what they find)

**Files:**
- Create: `docs/runbooks/admin.md`
- Modify: whatever the runs find (D68), each in its own `phase-19/fix-<what>` pull request with a test that failed first

**The runbook** (`docs/runbooks/admin.md`): 1. the local stack (`supabase start`, `db reset`) and the local API with the
worker (runbook `simulator.md` 12), 2. `admin/.env.local` from `supabase status -o env` (the three values; `ADMIN_PREVIEW`
never set here), 3. a local admin: `bun tools/admin-local.ts <email>` (new, in this task: makes the auth user with a
printed-once password through the admin API, inserts the `admin_users` row with the seed tutor as the push target;
test-only, refuses a hosted URL), 4. `bun run dev` in `admin/` on :3100, 5. the built-in browser: `preview_start` with
the URL, a settled page before every click (`read_page` after each navigation), 6. codes from `bun tools/totp.ts
<secret>` (the secret shown on the enrol page), 7. every write confirmed with `supabase db query --local`, 8. the alert
push to the simulator (`simulator.md` 13), 9. what not to do (never a production key in `.env.local`; never
`ADMIN_PREVIEW` with real keys).

- [ ] **Run 1, sign-in and enrolment:** the local admin signs in; the enrol page; a wrong code refused with its line; the
  right code; Centres shows the seed's centre; `admin_audit` holds `enrol_totp` and `sign_in` with the address.
- [ ] **Run 2, the second factor again:** the session's `aal2` dropped by `auth.mfa.unenroll`? No: by signing out and in
  again: `/mfa/verify` is asked; a page asked for directly (`/jobs`) comes back after the code.
- [ ] **Run 3, a tutor refused:** the seed's tutor signs in at the portal: Refused with their email; `admin_audit` holds
  `refused`; nothing else was read (the API's log shows no `admin_*` call).
- [ ] **Run 4, the record:** Open the record on the seed's centre with a reason; the audit row; the record's students with
  their consent states (Hemanth given, the others as the seed has them); no phone number anywhere on the page (the
  page's text searched); the record URL opened directly after ten minutes asks again.
- [ ] **Run 5, cost and calls:** after a plan job on the fake (runbook `simulator.md` 12's run-job SQL): the Cost page's
  tiles match `select sum(cost_paise)` for the month; the calls list shows the job's calls with "job plan"; a call's page
  shows input and output; a `note` call for a student without consent (the fake's held row) shows "Held".
- [ ] **Run 6, jobs:** a job failed on purpose (an `artefact` kind queued by SQL): the Jobs page shows it failed; Retry
  re-queues it (the row `queued`, `attempts` 0; it fails again at once, as expected); Cancel on a queued `sweep` cancels
  it; both in the audit.
- [ ] **Run 7, alerts:** the `alerts` job (the local tick runs it) raises `job_failed` for run 6's job; the fake sender's
  log shows the email's text; the push row for the seed tutor; the simulator shows "Tutor Central needs a look" (the
  local API with `APNS_*`, runbook 13); Acknowledge in the portal; the row acknowledged by the admin; the audit.
- [ ] **Run 8, errors and audit:** three failing calls (a 403 by a note without consent, a 409 by a reused key, a 413 by
  a big body) appear by route and reason within a minute; the Audit page lists runs 1 to 7 newest first.
- [ ] **Run 9, phone width:** the browser at 390 (`resize_window`): the nav scrolls sideways, the tables stack, nothing
  scrolls sideways (`scrollWidth` at 390 ≤ 390 on every page, read with `javascript_tool`).
- [ ] **Pictures and results** on one issue "Phase 19 hand run"; each finding fixed in its own PR (D68) before Task 17.

---

### Task 17: Production: the owner's row, his first sign-in, a real alert (no pull request; the ledger)

- [ ] **The owner's row** (D87): with the email from Task 1 A read into a shell variable (never a file):
  `supabase db query --linked "insert into public.admin_users (user_id, email, notify_user_id, notify_centre_id) select
  u.id, u.email, o.id, c.id from auth.users u, auth.users o join public.centres c on c.owner_id = o.id where
  lower(u.email) = lower('<admin email>') and lower(o.email) = lower('<owner's tutor email>')"`; the count 1 confirmed.
- [ ] **The owner's step E** (the first sign-in and the authenticator), then his word that Centres showed.
- [ ] **A real alert:** a job of kind `artefact` queued for the Smoke centre by `supabase db query --linked` (`insert into
  public.jobs … 'artefact', 'alert-proof:<epoch>'` with `tc.jobs` set); it fails at the next tick; within ten minutes the
  `alerts` job raises `job_failed`; the owner confirms the email arrived and the push showed on his iPhone; he
  acknowledges it in the portal; the audit row read back with `--linked`. Ledger lines for each.
- [ ] **The first morning's `alerts` rows** read the next day: none raised but the proof's, or each looked into.

---

### Task 18: The review, the trust page, the documents (PR 16 and `main`)

- [ ] **The review** on Fable 5.1, two fresh reviewers as Phase 18's: (a) the portal (`admin/`, the tools, the
  workflows), (b) the database and the API (0046 to 0048, the alerts job); each given this plan, the boards and the diff
  from this phase's first commit; every finding fixed with a test that failed first (D68), each in its own
  `phase-19/fix-<what>` pull request, the ledger's `Review` and `Fix` lines; the deploys for what they touch.
- [ ] **`/trust`** (PR 16, decision 22): one sentence in `web/content/trust.ts` under "Who can see your records" (the
  board P15-Web-Trust settles the layout; the words are the page's own, plain, D41: "Tutor Central's own staff can open a
  centre's records only to help with a problem, with the reason and the time written down. They never see a parent's
  number or a photo."), `TRUST_UPDATED` moved, `web-shots` at both widths and appearances, `deploy-web` run.
- [ ] **The rule files** (D80): `admin/CLAUDE.md` final; `api/CLAUDE.md` (the alerts job, `RESEND_API_KEY`,
  `ALERT_EMAIL`, the kind `alerts`); `supabase/CLAUDE.md` (`admin_users`, the `admin_*` functions granted to the platform
  alone, the alerts' key, the record's open); `CLAUDE.md` (the table's `admin/` row, `bun admin-shots`, `gh workflow run
  deploy-admin`).
- [ ] **The documents:** "As built" in `phase-19-admin-portal-reading.md`; `plan/README.md` (Phase 19 built; D94 to D96
  were written with the plan's approval); `STATE.md` (the Production section gains the portal: project, domain, commit,
  variables' names); `plan/sessions/039/{record,owner-messages,ledger}.md`; `docs/design/information-architecture.md` if
  the build settled a state the boards left open; the resume for Phase 20 if the owner asks.

## The cost

| What | A month | Once |
|---|---|---|
| Vercel Hobby, a third project | nothing (D85) | |
| Supabase basic MFA (TOTP) | nothing on Free and Pro | |
| Resend, the alert emails | nothing within the free tier's 3,000 a month; the alerts are a few a day at most | |
| The `alerts` job each ten minutes | nothing: four reads, no AI call | |
| The hand runs | none: the fake API | ₹0 |
| Task 17's proof in production | | one failed job, one email, one push: ₹0 |

No AI call is made by this phase. The deploys' smokes keep Phase 17's one real `check` each (₹0.01).

## Self-review (done 2026-10-13)

1. **Scope coverage** (`phase-19-admin-portal-reading.md`): boards (row 27, approved; "Phase 19 boards"); the app in
   `admin/` with Bun, Biome, pinned dependencies, the third Vercel project at a subdomain, git deploys off,
   `deploy-admin.yml` with its smoke, `admin/CLAUDE.md`, the `admin` check step (Tasks 4, 15); sign-in with `admin_users`,
   TOTP, `aal2` on the server on every request, the service-role key in server code only with a test reading the build
   output (Tasks 2, 4, 5); the audit on every action and every open of a record, shown in the portal (Tasks 2, 7, 12);
   the pages: centres and their tutors (6), activity from `events` (6), usage and cost per centre, kind, model and day
   against the allowance and ₹499 (8), the AI calls with prompt version, tokens, latency, outcome and fallback (9), jobs
   and steps with retry and cancel (10), API errors by route and reason (11), alerts (12); the alerts job with thresholds,
   Resend and a push to the owner's device (13). Acceptance: the owner signs in with his second factor and sees the
   production centres' cost and jobs (17); a read of a centre's record is in the audit (7, run 4); an admin without
   `aal2` is refused (5, run 2); the key in no client bundle (4); a failed job's alert reaches email and phone (13, 17);
   pictures of each page and state at 1280 and 390 (14); the smoke green (15).
2. **Placeholders:** the test bodies left as one-line names in Tasks 6 to 12 name what they assert and against which
   fixture; each is written in full in its task's Step 1 before Step 2, as Phase 18's were.
3. **Names across tasks:** `admin_audit_write`, `raise_alert`, `alert_facts`, `admin_push_targets`,
   `admin_acknowledge_alert`, `admin_retry_job`, `admin_cancel_job` (2) → `lib/data/real.ts` (4, 10, 12) and
   `api/src/alerts/db.ts` (13); `admin_open_record` and `admin_record_opened` (3, 7) → the record page (7); `decide`,
   `requireAdmin` (4) → every page (5 to 12) and the words test (4); `preview()` (4, 14) → `lib/data/index.ts`; `cdp`,
   `sideways` from `tools/web-shots.ts` → `admin-shots` (14); `alertsKey` beside `sweepKey` (13); the push row's kind
   `alert` (2, 13); `totp` (5) → the runbook (16).
4. **Review focus:** eight lines, each with its test in its owning task.
