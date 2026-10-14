# The pre-PR proof

The checks below run **locally, by the session, before a pull request with code is opened**. CI's `check.yml` repeats
the free part (format, lint, the tests, the builds). Nothing in CI, on a schedule or in a deploy makes paid AI calls
(D112), so the AI's quality is proven here, by hand, or not at all. A pull request without its proof is not opened; one
whose proof could not be run says so in its body and is not merged.

## 1. Every pull request with code

1. **Test first.** For logic (Domain, Data, the API, the database's rules, a store), write the test, run it and see it
   fail for the right reason (RED), then write the code and see it pass (GREEN). Note the RED and GREEN in the session's
   ledger. A fix found by a hand run gets its own failing test first (D68).
2. **`bun check`** green on the branch's final state. The check skips a step whose inputs have not changed since it was
   last green. Use `bun check --fresh` when the step list says "unchanged" for something you changed, or when a cached
   step looks wrong (a step that ran in a few seconds after a large change).
3. **The database step leaves the local database seeded only when it finishes.** If it fails, run `bun check --only=db`
   again before anything that needs the seed (the API's platform tests, a hand run).

## 2. By what the change touches

| The change touches | The proof, in addition to section 1 |
|---|---|
| A prompt, an agent, the schemas, the golden sets, `api/models.json` or the model table | `bun evals-changed`. When it names kinds, `bun evals --kinds <those kinds>` on the real models (by hand; it costs: note it in the ledger). The gate: every free check, and the rubric at 85% or more per kind, a failed case retried once (D103). A red gate is fixed in the words, the rubric or the effort, then run again; it is never merged red. When the words change: raise the prompt's `VERSION`, `bun prompts --write`, `bun contract`. |
| A migration | `bun check --only=db` (it resets the local database and runs every test). `supabase gen types typescript --local > supabase/types.ts` and `bun contract`. Before replacing a function, read **every** migration that defines it and build on the newest body (`grep -l "function public.<name>(" supabase/migrations/*.sql`, then open each: the list is not in date order). Never edit a migration that has run on the hosted project. |
| A job, the worker or a batch | A local run on the fake (`AI_FAKE=1`), queued by the runbook's SQL (`docs/runbooks/simulator.md`, section 12), its steps and rows read back. A run on the real models only when the change is about the models' answers, and only by hand. |
| A screen of the app | Its board first (rule 1). `bun shots <state>` in both appearances where the board has both, set beside the board, and `bun pr-shots` for the description's table (rule 2). |
| A page of the portal or the website | `bun admin-shots --pages …` or `bun web-shots --pages …` at 1280 and 390, both appearances, beside their boards. |
| A write path before a TestFlight build | The hand run of every write it touches (D32), with its screenshots. |
| A workflow file | Read it through for any trigger that is not `workflow_dispatch` reaching a paid call (D112). A deploy's smoke stays free. |

## 3. The pull request's body

Every body carries a **Proof** section: each command run and what it answered, so a reader can see what was proven and
what was not.

```
How it was checked:
- Tests first. RED: <file>, <n> failing (<why>). GREEN: <suite> <n>.
- `bun check` green.
- `bun evals-changed` → <kinds | none>; `bun evals --kinds <kinds>`: <each kind's rubric %>, gate green.
- <the pictures' table, the local run, the hand run, as the change needs>
- Not run: <what, and why>.
```

## 4. Never

- Never rely on CI for the evals: there are none there.
- Never add a `pull_request`, `push` or `schedule` trigger, a pg_cron job or a deploy step that makes a Claude call for
  testing or measurement (D112). Evals by hand: `bun evals --kinds …` locally, or `gh workflow run evals -f kinds=…`.
- Never merge code whose required proof above was skipped without saying so in the pull request and the ledger.
