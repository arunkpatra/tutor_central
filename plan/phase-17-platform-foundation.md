# Phase 17: V3 platform foundation

**Status:** Built (session 35, 2026-10-12) from `phase-17-plan.md` in #184 to #214 (hand runs #212); deployed (0028 to 0035, the worker live); 1.0.0 (27) on TestFlight with nothing new on screen. "As built" below. **Depends on:** Phase 15 built (1.0.0 (26)); `docs/spec-v3.md` approved (D70 to D82).

## As built (session 35, 2026-10-12)

Built from `plan/phase-17-plan.md` in pull requests #184 to #214 (the hand runs are issue #212). The ledger with each ruling,
hand run, fix and review finding is `plan/sessions/035/ledger.md`.

**The pull requests.** #184 CI's database ports and the SchoolTests crash; #185 the gated deploy and its real smoke; #186 to
#189 migrations 0028 to 0033 (jobs and job steps; `start_ai_call` and the enriched row; events, `api_requests`, alerts,
`admin_audit`, device tokens; `consent_events`; idempotent keeps and one absence log a day); #190 and #191 two faults the
first review found (a racing claim; a forged consent history); #192 the contract (`bun contract`); #193 and #194 the API's
envelope and recorded call; #195 the worker and the minute wake (0034); #196 the plan rules in TypeScript, equal to Domain's
on 29 shared cases; #197 the `plan` job and `run-job.yml`; #198 the app's keys and request ids; #199 the activity log; #200
to #206 the restore drill and its first runs' fixes; #207 to #211 every finding of the two fresh reviews on Fable 5.1 (0035
among them); #213 a deprecation the production build showed; #214 `run-job.yml` did not parse.

**Jobs.** `jobs` and `job_steps` in Postgres; a job is queued by key (a second queue of the key is the first job), claimed one
at a time with a lease (`for update skip locked`), taken through its steps by the API's worker (`/jobs/tick` from pg_cron each
minute, `/jobs/wake` when a job is queued, both through pg_net with Vault's address and secret), each step written as it
ends. A wait is not an attempt; a failure retries with backoff (30 s doubling, at most ten minutes) up to the job's attempts;
a lapsed lease is retaken by the next claim and a lost lease stops the old worker's writes. The run's budget is 200 s under
Hobby's 300. The sweep runs each ten minutes and closes calls left pending. The platform is the service role (D83).

**The plan job.** Reads the batch's record, groups by the ported rules, names unnamed groups with one platform call keyed
`<job>:name` (a retaken step replays it, and finds the chapters and skills it wrote), writes the plan through `make_plan`. It
never replaces a plan the phone made and leaves an exam week or a holiday to the phone; the phone makes the material on
open as before (Phase 18 moves it). `gh workflow run run-job.yml` queues one by hand.

**The recorded call.** Every paid call goes through `start_ai_call`: the centre's calls in turn (an advisory lock), the key
replayed within a day, the allowance from the centre's columns (calls a month, and a money cap for every kind), the request
id, the job and the user on the row; the API finishes it as the platform with tokens, cost from `models.json`, latency, the
prompt's hash, the stop reason and the error reason. A member writes no row. The app sends the key (the route, the body and
the day in India; fresh for Make it again and Write again) and maps the new answers to its existing words.

**What is written down.** One JSON log line and an `api_requests` row per request; per-user and per-address rate limits; a
body limit; `events` from the app's activity log (opened, signed in, a tab, a link, signed out; by id, posted in batches);
`alerts` and `admin_audit` for the portal; `device_tokens` for Phase 18; `consent_events` as the consent's history.

**The contract and the deploy.** `bun contract` generates the API's database types, the app's limits, the fake's samples and
the plan cases; `bun check` fails when any is stale and when a workflow does not parse. `deploy.yml` deploys one commit the
gate saw green, writes Vault, checks the function's 300 s, and smokes with a real `check` for the Smoke centre and a tick.
The restore drill (`restore-drill.yml`) dumps production into a blank database on the runner and compares every table's
count; the first passed in 182 s (`docs/runbooks/restore.md`).

**Deployed.** Run 38256073141 (commit `a3c6012`): 0028 to 0035, Vault, the smoke green; the minute wake answers 200. The
owner's centre's first plan job (Good Ground, Class 8, 13 October) was done on its first attempt (run 38257459463).

**Cost.** The hand runs' real calls ₹4.57 (12 calls; ₹4.43 of it Today's material made at sign-in); the smoke's check 1 paise.

## Goal

The backend becomes the platform: a job can run on the server with its state in Postgres, a paid call is recorded once with
what it cost, and what happens is written where the admin portal will read it. Nothing new on screen (D6).

## Scope

1. **Plans** (D71, amended by D85): none bought this phase. pg_cron wakes the worker each minute through pg_net from inside
   the database; Vercel Hobby's 300 s holds a step; no copy of the database exists until Supabase Pro is bought before the
   external testing round (a step of its checklist), when Vercel Pro is bought too.
2. **The job tables** (D71): `jobs` and `job_steps` as spec-v3 section 3, with RLS through `is_member` for the app's reads and
   the server's key for writes; `kind`, `state`, `idempotency_key`, `attempts`, `max_attempts`, `lease_until`, `leased_by`,
   `step`, `input`, `result`, `error`, `run_at`, `started_at`, `finished_at`, `cost_paise`; tested first (the lease, a retry,
   a duplicate key, a cancel).
3. **The worker** (D71): Hono routes in `api/` that take a lease (`for update skip locked`), do one step, write the row and
   the step, continue while time allows; woken each minute by pg_cron through `pg_net` and by a `pg_net` trigger on enqueue (D85); the
   job key (Supabase's service role or a dedicated role with the workers' grants, chosen in the plan) in Vercel's environment
   only (D11); `maxDuration` set on each function. One job kind proves it end to end: `plan` for the seed centre, run on the
   local stack and once in production for the owner's own centre.
4. **Idempotency and the recorded call** (D76): the app sends an idempotency key with each paid call and a request id with
   each API call; the API answers the same result for the same key for a day; `start_ai_generation` locks the centre's row;
   `ai_generations` gains cost, latency, prompt version and hash, stop reason, error reason, request id, job and fallback, and
   records billed tokens on a failure; `max_tokens` handled as truncation; `centres.ai_allowance` and `ai_allowance_paise`
   with a policy the owner cannot raise, replacing the literals (600 a month seeded); `keep_artefact` and the absence log made
   idempotent; a `sweep` job closes pending rows; per-user and per-IP limits and a body limit; `APPLE_FAKE` and `AI_FAKE`
   refused in production.
5. **The observability tables** (D77): `events`, `api_requests`, `alerts`, `admin_audit` (empty until Phase 19), `device_tokens`
   (filled in Phase 18), `consent_events` (D79, backfilled from the three columns); structured JSON logs with the request id;
   the app posts `events` in batches (kinds only, never content).
6. **Contracts** (D80): types generated from the database for the API and from the API's schemas for the app, so a limit lives
   once; the first contract tests between the app and the API in `bun check`.
7. **Process** (D80): `deploy.yml` requires a green `check` for its commit and its smoke makes one authenticated call to a smoke
   centre with the real model; CI's database port collision and the SchoolTests teardown crash fixed; the restore drill run
   once into a scratch project and written as `docs/runbooks/restore.md`.
8. **The rule files** (D80): `api/CLAUDE.md` (the stale 501 note out; the workers, the job key), `ios/CLAUDE.md` (four queued
   writes), `supabase/CLAUDE.md` (the job identity beside D37's two functions, the lock, the allowance columns).

## Acceptance

- A `plan` job queued in the database runs on Vercel, writes its steps and result, survives a function's end and a retry,
  and refuses a duplicate key; the app reads its state.
- A paid call retried with the same key costs nothing and answers the same; the row holds cost, latency, version and outcome.
- The gate cannot be passed by two calls at once (a test with two concurrent starts).
- The deploy fails on a red check or a bad key; the restore drill's record exists.
- `bun check` green; a build on TestFlight with nothing new on screen; the hand runs of each write the change touches (D32).
