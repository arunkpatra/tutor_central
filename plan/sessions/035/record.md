# Session 35: Phase 17's build (Opus 5.5, 2026-10-12)

From `plan/resume/033-phase-17-build.md`. The owner's messages word for word are `owner-messages.md`; every ruling, task line,
hand run and review finding is `ledger.md`.

## What was built

Phase 17 from `plan/phase-17-plan.md`, all eighteen tasks, in #184 to #214; "As built" in
`plan/phase-17-platform-foundation.md`. The job tables and worker with the minute wake (0028, 0034), the recorded call behind
`start_ai_call` (0029), the observability tables, device tokens and consent history (0030 to 0032), idempotent writes
(0033), the review's fixes (0035), the API's envelope (request ids, logs, rate and body limits, keys, cost), the contract
(`bun contract`), the plan rules ported and held equal on 29 shared cases, the `plan` job and `run-job`, the app's keys and
activity log, the gated deploy with a real smoke, the restore drill (first passed in 182 s).

## Checked

- `bun check` green before every merge; merged on local green from the owner's message 2 on (D86).
- Hand runs 1 to 7 against the local stack, each write confirmed in the database; issue #212 with the pictures.
- Two fresh reviews on Fable 5.1 (app and tooling; database and API): eighteen findings, all fixed with a test that failed
  first (#207 to #211); two more faults found beside them (a Make sheet's keep over the tutor's own; V1 calls never read the
  money cap) and fixed in the same PRs.
- Deploy run 38256073141: 0028 to 0035, Vault, the function's 300 s, the smoke's real check and tick; on production the minute
  wake answers 200 and the sweep runs.
- The owner's centre's first plan job (run 38257459463): done on attempt 1, the plan for 13 October.
- 1.0.0 (27) by run 38258868771.

## Faults found and fixed after the merges

- `run-job.yml` never parsed (a plain value holding ": "): every push recorded a failed run, which the owner saw as CI
  failing on main; #214 fixed it and added a test that every workflow parses.
- A deprecation warning in the new task-local the production build showed (#213).

## Process notes

- Owner step 1's production build was refused to the session; the owner ran it. After that the owner authorized the session
  to do production's setup through the signed-in CLIs (D87), which it should have done from the start for steps 2 and 3:
  the secrets, the variables and the duplicate check were first handed to the owner, who rightly said it wasted his time.
- The owner asked for exact, numbered steps with no compressed parentheticals whenever he must act.
- Local state left: `api/.vercel/project.json` relinked to `tutor-central-api`; `WORKER_SECRET=local` in `api/.env.local`;
  the local database reset to the seed (sign in again in the simulator after a `bun check --only=db`).

## Cost

The hand runs' real calls ₹4.57 (12 calls; ₹4.43 of it the phone's Today material at a sign-in with the real models); the
deploy's smoke check 1 paise; the first plan job no call (its group already named).
