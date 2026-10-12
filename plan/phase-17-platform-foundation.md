# Phase 17: V3 platform foundation

**Status:** Not started. **Depends on:** Phase 15 built (1.0.0 (26)); `docs/spec-v3.md` approved (D70 to D82).

## Goal

The backend becomes the platform: a job can run on the server with its state in Postgres, a paid call is recorded once with
what it cost, and what happens is written where the admin portal will read it. Nothing new on screen (D6).

## Scope

1. **Plans bought** (D71): Vercel Pro on `tutor-central-api` (functions to 800 s, cron each minute), Supabase Pro on the hosted
   project (daily backups, point-in-time recovery, seven-day logs); the owner's steps one at a time.
2. **The job tables** (D71): `jobs` and `job_steps` as spec-v3 section 3, with RLS through `is_member` for the app's reads and
   the server's key for writes; `kind`, `state`, `idempotency_key`, `attempts`, `max_attempts`, `lease_until`, `leased_by`,
   `step`, `input`, `result`, `error`, `run_at`, `started_at`, `finished_at`, `cost_paise`; tested first (the lease, a retry,
   a duplicate key, a cancel).
3. **The worker** (D71): Hono routes in `api/` that take a lease (`for update skip locked`), do one step, write the row and
   the step, continue while time allows; woken by Vercel Cron each minute and by a database webhook (`pg_net`) on enqueue; the
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
