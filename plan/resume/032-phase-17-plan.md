# Resume 032: Phase 17 (V3 platform foundation), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). V3's spec is approved (`docs/spec-v3.md`, D70 to D82, 2026-10-12). Phase 17 is the
platform foundation: nothing new on screen (D6), so no board waits on it. This session writes `plan/phase-17-plan.md` and the
build's resume prompt, then stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product and are built (Phase 15 on TestFlight as 1.0.0 (26)). V3 is the platform under it (D69, `docs/spec-v3.md`): the
backend becomes the platform and the app its presentation layer (D70); long work runs as jobs in Postgres with Hono workers
on Vercel (D71); paid calls are recorded once with what they cost (D76); what happens is written in our own tables (D77).
Phase 17 lays that foundation. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D82; D70 to D82 are V3's; D81 is the order: V3's six phases,
   then the external testing round, then Phase 16).
3. `docs/spec-v3.md` in full, `docs/v3/interview.md` (what the owner said and why each choice was made; the "What the reading
   found" section lists the platform's weaknesses with file paths), `plan/sessions/033/research.md` (the sources: Vercel
   Functions, Cron, pg_cron, `pg_net`, APNs, Claude pricing).
4. `plan/phase-17-platform-foundation.md` (the scope and acceptance), then `plan/phase-18-server-work-and-push.md` and
   `plan/phase-19-admin-portal-reading.md` (what builds on Phase 17's tables, so the tables fit them).
5. The platform as it is: `api/src/routes/common.ts` (`run`), `api/src/claude.ts`, `api/src/db.ts`, `api/src/verify.ts`,
   `api/vercel.json`, `supabase/migrations/20261101000027_*.sql` (`start_ai_generation`'s body), `supabase/tests/rls.test.ts`
   (the catalogue test every new table must satisfy), `.github/workflows/deploy.yml` and `tools/smoke.ts`,
   `ios/TutorCentralKit/Sources/Data/AI/APIClient.swift`, `Data/Queue/`, `Features/Today/PlanMaker*.swift` (what Phase 18
   retires; Phase 17 only adds the key and request id the app sends).
6. `plan/sessions/032/ledger.md` (the last review's findings and the hand runs' faults: the double spends and the 20 s waits
   Phase 17's keys and Phase 18's data layer remove) and `plan/sessions/033/record.md`.

**What is already true:** production holds migrations 0001 to 0027 and the API at `54adb24`; Vercel is on Hobby and Supabase
on Free (Phase 17 buys Pro on both, the owner's steps one at a time, D71); there is one environment (D80); the owner approved
real AI calls in testing without asking each time (be judicious; record what ran and what it cost); the owner builds alone
with Claude (Q4) and wants no question he can see the answer to (interview message 7): decide small and medium things and say
what you decided.

**Your work:** write `plan/phase-17-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (the job tables'
lease, retry, duplicate key and cancel against the local stack; the worker's step loop with a fake clock; the locked gate
with two concurrent starts; the idempotency key's same answer; the enriched row; the allowance policy the owner cannot raise;
the contract tests), the migrations (one per change, RLS and the catalogue test for each table, additive, D26), the job key's
choice (the service role or a dedicated role: weigh the grants and write the decision), the worker's wakes (Vercel Cron each
minute, `pg_net` on enqueue) and `maxDuration`, the deploy's gate on a green check and its real smoke call against a smoke
centre (how the centre is made without a tutor's data), the restore drill's steps and runbook, CI's two flakes, the generated
types (which tool, where they live, how `bun check` fails on drift), the `events` batches from the app, the rule files'
changes, the pull requests (one change each; D7 pictures only where a screen changes, which should be none), the owner's
steps (Vercel Pro, Supabase Pro, the first production run of a `plan` job for his centre), the D32 hand runs of every write
the change touches, and the review focus (what a person meets that no happy path exercises: a lease that expires mid-step, a
function killed after the Claude call and before the row's finish, a key reused with a different body, a tutor whose
allowance is exactly reached by two calls at once, a deploy whose check is pending rather than red).

Show the plan whole and wait for the owner's approval. Then write `plan/resume/033-phase-17-build.md` (Opus 5.5) and index
it in `plan/resume/README.md`, update `plan/STATE.md`, write `plan/sessions/034/record.md`, and commit the documents to
`main` (D12).

**The owner's rules:** be brief; one question at a time and only for decisions that are his, with a recommendation and its
reasons; decide the rest and say so; plain voice in documents; no technical words in anything a tutor reads (D41); no secret
in the repository (D11); no tutor's name, email or number in it (D55); decisions are never reopened, a change gets a new
number.
