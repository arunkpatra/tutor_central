# api: rules

Hono on Vercel. Exists only for AI and scanning (D5, D11); everything else is the app talking to Supabase.

- `src/index.ts` is the entry: it builds the app with the real verifier and default-exports it. Vercel's Hono
  preset takes as its entry the first of `app`, `index`, `server`, `src/app`, `src/index`, `src/server` whose
  source imports `"hono"`, so no other file may have one of those names (`test/entry.test.ts` holds this).
  `src/make-app.ts` builds the app from injected dependencies so tests run with a fake verifier.
- Vercel runs the files as Node ES modules: relative imports end in `.js` (`./auth.js`). `tsc` runs with
  `NodeNext` and refuses an import without it. Bun does not mind, so trust `tsc`, not `bun test`.
- Every `/ai/*` route passes `requireUser`: 401 "sign in again" for a token that is not a live user's; 503 `{ reason:
  "unreachable" }` when Supabase could not be asked (`src/verify.ts`: a 4xx is the token's; a thrown fetch, a 5xx or an
  error with no status is unreachable, D68); never 500. A named student's missing consent is 403 `reason:
  "student_consent"` in the student's words; the centre's notice keeps "consent".
- Inputs are zod schemas in `src/schemas.ts`; a route validates first and answers 400 with the issue list.
- `/health` answers `{ ok, commit }`; the commit is `TC_COMMIT`, set by the deploy workflow.
- Secrets only in Vercel's environment variables and `api/.env.local` (ignored); `.env.example` lists names.
  `SUPABASE_ANON_KEY` holds the project's publishable key. `SUPABASE_SERVICE_ROLE_KEY` is the platform's identity (D83):
  the observability client, the worker's jobs and record, and the finish of a call's row; never a tutor's read.
- Dependencies pinned exactly. Bun only (D16). The repo installs with bun's hoisted linker (`bunfig.toml`):
  Vercel's TypeScript check cannot follow the isolated linker's symlinks.
- Tests: `bun test` with `app.request(...)`; no network in tests.
- Deployment (D21): only `.github/workflows/deploy.yml`, started by hand (Actions → deploy → Run workflow, or
  `gh workflow run deploy`). It builds on the runner with Vercel's CLI pinned at 59.19.0, deploys `--prebuilt
  --prod` to project `tutor-central-api` ("Arun's projects", functions in `bom1`), smokes `/health` for the commit
  and `/ai/generate` for a 401, and prints the rollback (`vercel promote <previous>`). Since Phase 17 a gate job first
  refuses a commit whose check is not green (`tools/check-gate.ts`) and names the one commit the other jobs take; the
  migration job writes the worker's address and secret to Vault; the smoke also signs in as the smoke account (Production
  secrets `SMOKE_EMAIL`, `SMOKE_PASSWORD`, variable `SMOKE_CENTRE_ID`) for one `check` keyed `smoke-<commit>` and gets
  `/jobs/tick` with `WORKER_SECRET`. Git deploys are off
  (`vercel.json`). Production: the repo variable `API_ORIGIN`. Vercel blocks deployments that carry a commit
  author it does not know, so never deploy from a local checkout.
- Claude through `@anthropic-ai/sdk` (D35), the named `Anthropic` export (the default breaks Vercel's CommonJS type
  check): `messages.create` with the schema's output format, parsed in `claude.ts` (ok, refused, unfit, truncated,
  failed, each with its tokens, stop reason and latency), one model per work type, no fallbacks. The models are `models.json`
  (D67): `modelFor(kind, classLevel?)` is the one place a prompt asks; `AI_MODEL_<WORK_TYPE>` (the table's keys
  upper-cased) overrides one at deploy, and an unknown name stops the API at start. The app's price sheet and `bun cost`
  read the same file. One deadline across both tries
  (`CLAUDE_DEADLINE_MS`, 110 s, under the app's 125 s); a timeout is a 502 and the row is marked failed.
- `POST /account/revoke-apple` (D38) exchanges the app's Apple authorization code and revokes the refresh token with a
  client secret signed from `APPLE_SIGNIN_KEY` (ES256, `dsaEncoding: "ieee-p1363"`, five minutes). The three `APPLE_*`
  values are read at boot (a deploy without them fails its smoke); Vercel keeps the `.p8`'s newlines, `.env.local` holds
  it on one line with `\n`, which `index.ts` turns back. `APPLE_FAKE=1` answers without Apple: local runs only. Its
  failures are Apple refused (400), signed out (401) and Apple unreachable (502); the app never shows the route's words.
- `AI_FAKE=1` answers from `claude-fake.ts` (local runs only; never set on Vercel); the consent, limit and record paths
  still run against the database.
- A route's call is started as the user (`db.ts`, the user's JWT) through `start_ai_call` (0029), the consent, allowance,
  key and record gate, and finished by the platform (0035: a member writes no `ai_generations` row).
  No photo is stored: `ai_generations.input` holds the page count and bytes, never the image.
- Photos are checked before any cost: magic bytes, round-trip base64, 3 MB decoded, six pages.
- `test/entry.test.ts` spawns the entry with `--no-env-file`, so `.env.local` does not leak into it.

- The V2 routes live in `routes/v2.ts` (`/parse-textbook`; `/plan`, a first topic per group with no record; `/make` for
  `sheet`, `worked_example`, `figure`, `brief`, `check` and `placement`; `mock` and the personal kinds answer 501). The
  plan's group kinds are `.strict()`, so a body naming a student is a 400 (D62). A figure whose spec breaks its rule is an
  unfit answer, refused in words (422), as the fake reports any answer its schema refuses; a triangle's `labels[i]` names
  the side opposite `angles[i]` (the prompt says so; the app draws it so);
  what both route files share (run, parse, answer, the not-yet answer) is `routes/common.ts`. The fake answers by the
  call's kind (`kindOf`), so a check is never answered with a paper. The textbook photo is read and dropped:
  `textbooks.photo_path` stays null (Phase 11).

Commands: `bun run dev` (local on :3000, needs `api/.env.local` with `WORKER_SECRET`, and `SUPABASE_URL=… SUPABASE_ANON_KEY=…
SUPABASE_SERVICE_ROLE_KEY=…` from `supabase status -o env` on the command line); `bun run check` (tsc and tests);
`bun check --only=api`; `gh workflow run deploy`.

- Phase 13: the models overrun an output schema's string limits unless the prompt states them; state each limit in the
  system words and leave the schema a little room (the gap report's day lines: 160 asked, 200 allowed). A student's work
  goes to a model only with `studentId` and their consent (check-paper with a mock's key, gap_report, test_tomorrow).
- Phase 14: a prompt asks only for the parts its facts hold (a part asked for and absent is invented); the English beside a
  parent's message is the tutor's aid, never sent, and may run longer than the message (1,000; 700 asked). The message kinds
  refuse in their own words. A validation 400 carries `reason: "invalid"`. The verifier treats 408, 429 and a retryable
  fetch error as unreachable. `bun cost` counts every billed call (`tokens_in` set), a failed one included.
- Phase 15: the note takes the tutor's own words (`tutorSays`, trimmed, 300 counted in characters as the app counts them); the
  prompt quotes them, says they are the tutor's message and not instructions, carries them whole and shortens the week to
  keep within 500. A progress note names its student for the gate (consent, 0027).
- Phase 17 (V3 platform): every request gets an `X-Request-Id` (kept when valid), one JSON log line and an `api_requests`
  row (`request.ts`, `observe.ts`); 20 answered calls a minute per user and 60 requests per address (Vercel's
  x-forwarded-for) answer 429 `rate`; a body over 4.4 MB is 413 in words. Every AI call carries an `Idempotency-Key`: the
  same key and body within a day replays the call (`replay: true`, no second charge), another body under the key is 409
  `key_reused`, the same key still running 409 `in_progress`. A row's cost is priced from `models.json` at finish
  (`price.ts`), with the prompt's hash. `AI_FAKE` and `APPLE_FAKE` stop the API at start in production.
- The worker (D71, D85): `GET /jobs/tick` (pg_cron each minute) and `POST /jobs/wake` (a job queued) behind
  `WORKER_SECRET`'s bearer; one run claims one job at a time while its 200 s budget leaves a step's room, and records each
  step (`jobs/runner.ts`). The tick queues the sweep each ten minutes (rows pending past ten minutes closed). The `plan`
  kind (`jobs/kinds/plan.ts`) reads, groups by the rules ported to `src/plan/` (held equal to the app's by
  `tools/contract/plan-cases.json`), names unnamed groups with one platform call keyed `<job>:name`, and writes the plan
  through `make_plan`; it never replaces a plan the phone made, and leaves an exam week or a holiday to the phone.
  `vercel.json`'s `functions` gives every function 300 s (the only pattern the Hono builder honours); the deploy checks it.
- Tests against the local stack (`jobs-db.test.ts`, `platform-db.test.ts`) skip with a line when it is down.
