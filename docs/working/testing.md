# Testing: what exists, where it runs, who runs it

The rules for a change are `docs/working/pre-pr-proof.md`. This page names the layers.

| Layer | Where | Runs | Costs |
|---|---|---|---|
| Unit and store tests (Domain, Data, the features' stores, DesignSystem) | `ios/TutorCentralKit/Tests/*` | `bun check` locally; CI's `check.yml` on every pull request and on `main` | free |
| The API's tests (routes, agents on the fake, jobs, the batch runner, prices) | `api/test/*` | the same | free |
| The database's tests (RLS on every table, the functions, the schedules) | `supabase/tests/*` | the same (they reset the local database) | free |
| The portal's and the website's tests and builds | `admin/test/*`, `web/` | the same | free |
| The tools' tests | `tools/*.test.ts` | the same | free |
| The golden sets (the AI's answers on its agents, graded by Opus 5.5) | `api/evals/<kind>/` | **by hand only**: `bun evals --kinds a,b` locally, or `gh workflow run evals -f kinds=a,b` | paid; `--fake` is free |
| The nightly `eval_run` (the golden sets as Message Batches in production, under the Smoke centre) | the worker | **by hand only**: `select public.schedule_evals()` through `supabase db query --linked`, or an `eval_run` job with `input.kinds` | paid, at half price |
| Screens beside their boards | `bun shots`, `bun admin-shots`, `bun web-shots` | by the session, for each change seen | free |
| Hand runs against the local stack | `docs/runbooks/simulator.md`, `docs/runbooks/admin.md` | by the session, before a TestFlight build that changes a write path (D32), and in a phase's hand-run task | free on the fake; paid on the real models |
| Device checks on a real iPhone | `docs/testing/device-tests.md` | by a tester | free |
| The deploy's smoke (health, the commit, the 401 guard, the worker's tick and health) | `tools/smoke.ts` in `deploy.yml` | at each deploy, started by hand | free (D112) |

## Principles

- **Test first where there is logic**, and see the test fail before the code exists (RED, then GREEN).
- **No automation spends on AI calls** (D112): nothing on a pull request, a push, a schedule or a deploy makes a Claude
  call for testing or measurement. A paid run is a person's decision, noted in the session's ledger with its cost.
- **The product's own work is not testing**: the plan, note-day and exam jobs make paid calls because tutors use the app.
- **A failing check is fixed, never relaxed.** A flaky test is made deterministic (the hour race of #322).
