# Phase 19: V3 the admin portal, reading

**Status:** Built (session 39, 2026-10-13): #262 to #287, hand runs #286; the portal live at admin.tutorcentral.in; migrations 0046 to 0050 in production; the API's alerts job live (its last deploy waits for Vercel's daily window, below). Boards: the 60 of row 27 (session 38). **Depends on:** Phase 17 (the tables); Phase 18 (the jobs the portal reads).

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

## As built (session 39, 2026-10-13)

Built from `plan/phase-19-plan.md` in pull requests #262 to #287; the hand runs are issue #286. Every ruling, hand run, fix
and review finding is in `plan/sessions/039/ledger.md`.

**The pull requests.** #262 migration 0046 (`admin_users`, the alerts' key and message, the `alerts` and `alert` kinds, the
write functions), #263 and #264 migration 0047 (the read functions) and the API's generated types it had left stale. #265
`admin/` (the frame, the tokens, the gate's pieces, `/health`, the `admin` check step, `bun admin-shots`). #266 the door
(sign-in, the authenticator's set-up and code, refused, sign-out, `tools/totp.ts`). #267 centres and a centre, #268 the
audited record, #269 cost, #270 and #271 the calls, #272 jobs with Retry and Cancel, #273 errors, #274 alerts and the audit.
#275 the API's alerts job. #276 preview mode refused in production and every page's sixty pictures. #277 `deploy-admin.yml`
and its smoke. #278 `tools/admin-local.ts`. #279 to #281 what the hand runs found (F1 to F6). #282 the trust page's
sentence. #283 to #285 every finding of the two fresh reviews on Fable 5.1 (thirteen). #287 the footer's commit, seen in
production.

**Deviations from the plan, each a ruling in the ledger.**
- `decide` lives in `lib/gate.ts` and `requireAdmin` in `lib/admin.ts` (the gate reads through `server-only` modules); the
  unit tests mock `server-only` by a preload.
- The tutors' emails come from the Auth admin API, not SQL: `auth.users` is not the platform's to read in SQL.
- A row helper takes an id: PostgREST makes a function of a table's row a column of that table.
- `admin_record_opened` and the cost functions' centre landed in 0047 (0047 had not run in production); 0048 to 0050 are
  the hand runs' and the review's.
- A wrong first code keeps the same factor (the square is 321 KB); the retry shows the key and "Start again".
- The filters are `<details>` menus of links (no script of the portal's own); Sign out is a form's POST.
- No "replayed" chip in the calls list: a replay makes no row (D84); a job's steps say it.
- Cancel shows only on a job that can be cancelled (the board drew it beside Retry on a failed one).
- A failed job's alert is keyed by its failure's minute (a retried job failing again alerts again); a stuck job is one with
  no step for ten minutes; the hour's requests leave out the worker's ticks (the review).
- The Root Directory was set by `vercel api`, so the owner's step C was not needed.

**Production.** The portal: Vercel `tutor-central-admin` (no git link), `admin.tutorcentral.in` (a CNAME at GoDaddy to
Vercel), deployed by `deploy-admin.yml` (run 38347870083 at `f37ffc3`, the smoke green), its three variables in Vercel's
Production (the URL, the publishable key, the default secret key). The owner's admin account on `admin_users`, his tutor
account the push target; TOTP enrolled 2026-10-13. Migrations 0046 to 0050 by deploy runs 38345041694 and 38347866740.
The API at `4d8294e` (the alerts job); the API's deploy of `f37ffc3` was refused by Vercel Hobby's 100 deployments a day:
the website's and the API's projects were still linked to GitHub, so every push made a cancelled deployment that counted.
Both were disconnected (no project is linked now); the API's deploy is retried as the window frees. `RESEND_API_KEY` and
`ALERT_EMAIL` on `tutor-central-api`'s Production. `/trust` carries the staff sentence (deploy-web run 38347873084).

**Proved in production (Task 17).** The owner signed in with his second factor and saw the four centres; a job made to fail
for the Smoke centre raised `job_failed` at the next ten minutes, the email reached him, the push reached his iPhone, and
he acknowledged it in the portal; each step is in the audit.

**Open.** The first morning's `alerts` rows are read on 14 October. The API's deploy of `f37ffc3` (0049's stuck rule and
the failure's key in the job's code) when Vercel's window frees. Hand run 7's push on a simulator was not driven (the
owner's iPhone proved it).
