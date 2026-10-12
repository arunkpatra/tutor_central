# Session 34: Phase 17's plan (Fable 5.1, 2026-10-12)

From `plan/resume/032-phase-17-plan.md`. The owner's messages word for word are `owner-messages.md`.

## Setup

- Reality matched `STATE.md`: `main` clean at `63aa2d0`, no open pull request. Documents-only session; nothing built.
- Read in the resume's order: the five rule files, `STATE.md`, `SESSIONS.md`, `README.md` (D1 to D82), `docs/spec-v3.md`,
  `docs/v3/interview.md`, the research, the Phase 17 to 20 scope files, the platform as it is (`run`, `claude.ts`, `db.ts`,
  `verify.ts`, `auth.ts`, `errors.ts`, `vercel.json`, the 0001, 0002, 0006, 0012, 0013, 0027 migrations, the catalogue
  test, `check.ts` and `steps.ts`, `deploy.yml`, `check.yml`, `testflight.yml`, `seed-review.yml`, `smoke.ts`, `review-seed.ts`,
  `APIClient.swift`, `APIFailure.swift`, `QueueRunner.swift`, `Wipe.swift`, `PlanMaker.swift` and `+Calls`, `PlanStore.load`),
  the 032 ledger and the 033 record. Four facts checked outside: Vercel's `functions`/`maxDuration` by file glob and Hobby's
  300 s; Supabase Pro's seven days of daily backups at $25 and point-in-time recovery at $100 a month; pg_net's `http_post`
  from a trigger with a Vault secret; the request's role claim surviving a definer function. Locally: pg_cron 1.6.4, pg_net
  0.20.4 and Vault are available on the local stack; `centres` has twelve columns; `is_member` and `delete_account` are the
  two definer functions.

## What was written

`plan/phase-17-plan.md` with `superpowers:writing-plans`: 18 tasks, 15 pull requests, 28 decisions, ten review-focus lines,
the file structure, the order, the self-review. Its shape: the job tables and functions tested against the local stack
(duplicate key, lease, retry, cancel, a lost lease's write refused); the worker's step loop with a fake clock; the gate
locked with two concurrent starts; the key's same answer; the enriched row; the allowance the owner cannot raise (column
grants); the contract generated three ways with `bun check` failing on drift; the deploy gated on a green check and a real
`check` call by a smoke account; the restore drill as a workflow; CI's two flakes first; the plan rules ported to
TypeScript and proven equal to Domain's by a shared case file, so the `plan` job can read, group, name and write while the
artefacts stay the phone's until Phase 18.

## Decided, and why

- **The job key is the service role (D83):** a dedicated role would need a minted JWT or a direct connection with a new
  dependency, and the membership checks of the functions the worker calls would still need the same clause. `is_member`
  answers true for the platform's role claim; the worker reaches the database only through named functions.
- **Idempotency keys (D84):** deterministic from the body by default, a fresh key where the screen means "another one"
  (V1's Create again); pending → 409 `in_progress`, another body → 409 `key_reused`, a failed row is a new call; a job
  step's key is `<job>:<step>`, so a step retaken after a lost lease replays the paid call.
- **The `plan` job's cut:** read, groups, name, write; the rules ported with shared cases; `ArtefactBudget` and the
  artefact steps are Phase 18's. The reason: the rules are about 1,200 lines of Swift the job cannot do without, and
  the port is Phase 18's prerequisite either way; the shared case file is itself a contract test (D80).
- **The gate's insert trigger** (a row not through `start_ai_call` refused) closes the reading's **W** on the table-wide
  insert grant; the seed, `psql` and the platform pass (no request claim, or the service role).
- Smaller rulings are the plan's numbered decisions 3 to 28 (the three `centre_id` exceptions, leases and backoff, the two
  wakes, the envelope's limits, the tables' policies, the consent trigger, the two idempotent writes, the five event kinds,
  the contract's mechanism, the gate's rules, the smoke's shape, `run-job.yml`, the restore drill, CI's fixes, the sweep).

## The owner's question and his ruling (D85)

The plan's one question was point-in-time recovery ($100 a month on Supabase Pro), recommended against until Phase 16. The
owner asked instead whether a backup was mission critical at all, and if not, whether the Pro subscription was needed
(message 2). Answered plainly: neither Supabase Pro nor Vercel Pro is needed for the platform to work; what each buys (daily
backups and seven-day logs; per-minute cron and 800 s functions) and the one risk of each without (no copy of the database
anywhere; Vercel's Hobby terms are non-commercial); the recommendation to skip both now and buy both before the external
testing round, with the minute wake moved into the database (pg_cron through pg_net), `maxDuration` 300 and a 200 s budget,
the restore drill's scratch project on the free organisation. His answer: "yes, skip both for now and update the plan."
Recorded as D85, superseding D71's "bought" clause to that extent; the plan changed in those places (decisions 5, 6, 22,
25, the ruling in place of the question, Task 2's steps now two, Task 9's `vercel.json` without `crons`, Task 11's
`wake_worker_tick` and its schedule with a test, Task 16's checks, Task 17's scratch project, the secret renamed
`WORKER_SECRET`).

## Written

- `plan/phase-17-plan.md`; `plan/resume/033-phase-17-build.md`, indexed in `plan/resume/README.md`.
- `plan/README.md`: D83 to D85; Phase 17's and the V3 row's status.
- `plan/phase-17-platform-foundation.md`: the status line and item 1 amended by D85.
- `plan/STATE.md`; `plan/sessions/034/{record,owner-messages}.md`.

## What is next

Session 035: Phase 17's build on Opus 5.5 from `plan/resume/033-phase-17-build.md`. The owner's findings on build 26, if any,
go into `plan/phase-15-findings.md` (Who = Owner).
