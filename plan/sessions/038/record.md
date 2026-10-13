# Session 38: Phase 19's boards and plan (Fable 5.1, 2026-10-13)

From `plan/resume/036-phase-19-boards-and-plan.md`. The owner's messages word for word are `owner-messages.md`; each ruling
with its cost if wrong is `ledger.md`.

## Setup

- Reality matched `STATE.md`: `main` clean at `8f755f2`, no open pull request; `bun check` green (cached). Documents only;
  nothing built.
- Read in the resume's order; the code the portal reads surveyed by hand (the migrations, the jobs' code, the observe and
  request middleware, the outbox, the RLS catalogue, the website and its tools).

## The morning plan job

No plan job ran at 05:30 on 13 October for the owner's centre. The day's plan already existed: a job keyed
`plan:<class>:2026-10-13`, created at 19:12 IST on 12 October by the `run-job` workflow (run 38257459463) twelve minutes
after Phase 17's deploy and before Deploy 1, so it ran Phase 17's `plan` kind: read, groups, name, write, done in 1.4 s,
₹0, no failure, no material (six lines, no artefact). `schedule_plans` skips a day with a plan, as designed; pg_cron's
798 runs in the last 12 hours all succeeded; 14 October is the first true morning run. No device token is registered
(build 28 or 29 not yet installed, or reminders not turned on), so no push could have reached the owner. Not a Phase 18
defect; nothing to fix. The material for the 13th comes with Make the plan again.

## The boards (row 27, y 58000)

Drawn by a generator in the scratchpad (`lib.py` the parts, `pages.py` the fifteen pages, `gen.py` the writer and placer,
`render.ts` over `tools/web-shots.ts`'s DevTools client, `sheets.py` the contact sheets), in the website's grammar: one
source per page and appearance, container queries, the Ember tokens as variables on the root, rendered at 1280 and 390
(mobile emulation off: without a viewport meta Chrome lays a "mobile" page out at 980). Every render looked at on contact
sheets before publishing; five things fixed first (the phone header's Sign out, the chart label's clearance, the Errors
page's two tables stacked, the audit's Who column, the alerts' email tile). Sixty boards, fifteen pages, published as row
27 in one version (1791857631-e3ee), shown in four groups: sign-in; centres and the record; cost and calls; jobs, errors,
alerts and the audit. The owner asked one question (what the second factor costs: nothing, TOTP is in Supabase's basic
MFA on the Free plan) and approved all four groups at once. Mirrored into `docs/design/` with "Phase 19 boards"
(`information-architecture.md`) and "Phase 19 parts" (`components.md`).

## Decided, and why

- **A separate admin account with email, password and TOTP (D94):** the app has no second-factor prompt, the audit then
  names an admin and never a tutor, and the account owns no centre.
- **admin.tutorcentral.in**, a third Vercel project, `@supabase/ssr` 0.12.7 as the one new dependency (D94).
- **Reads through `admin_*` functions granted to the platform alone, writes through functions that write their own audit
  row (D94):** the service role on the server is the point of the portal, and a function per page keeps every aggregation
  in SQL with a test that a member cannot call it.
- **The alerts job (D95):** a kind of its own each ten minutes (the board says so honestly), four lines as constants
  until Phase 22, raised once by key, Resend's HTTP API with a key the owner makes, a push through the outbox to the
  owner's tutor account's iPhone (the admin account has no device).
- **Preview mode for the pictures (D96):** the portal is dynamic and behind a second factor, so `bun web-shots`' method
  needs fixtures; `ADMIN_PREVIEW` is refused in production as `AI_FAKE` is.
- **The record's open is one function** that writes the audit row and answers the record in the same transaction, and
  the record page is served only from a fresh `open_record` row, so a bookmarked URL asks again.
- The smaller rulings are the plan's decisions 1 to 24 (the gate as a pure function, the local-stack gate test with a
  computed TOTP, the Calls page's consent rule, the activity and reason words, server actions for the writes, the
  retry's semantics, the smoke without a second factor, the hand runs in the built-in browser, the trust page's sentence).

## The plan

`plan/phase-19-plan.md` with `superpowers:writing-plans`, in Phase 18's form: 18 tasks, 16 pull requests, 24 decisions, D94
to D96 in the README, eight review-focus lines with their tests, the file structure, the order, the owner's five steps as
exact lists, the cost (nothing new a month) and the self-review. Resume 037 written and indexed.

## One question for the owner

None left open by the session: the plan is his to review. The owner's steps A and B are asked by the build session's first
message.

## What is next

Session 39: Phase 19's build on Opus 5.5 from `plan/resume/037-phase-19-build.md`, after the owner's review of the plan.
