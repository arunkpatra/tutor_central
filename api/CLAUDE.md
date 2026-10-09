# api: rules

Hono on Vercel. Exists only for AI and scanning (D5, D11); everything else is the app talking to Supabase.

- `src/index.ts` is the entry: it builds the app with the real verifier and default-exports it. Vercel's Hono
  preset takes as its entry the first of `app`, `index`, `server`, `src/app`, `src/index`, `src/server` whose
  source imports `"hono"`, so no other file may have one of those names (`test/entry.test.ts` holds this).
  `src/make-app.ts` builds the app from injected dependencies so tests run with a fake verifier.
- Vercel runs the files as Node ES modules: relative imports end in `.js` (`./auth.js`). `tsc` runs with
  `NodeNext` and refuses an import without it. Bun does not mind, so trust `tsc`, not `bun test`.
- Every `/ai/*` route passes `requireUser`: 401 "sign in again" for anything but a live Supabase user, never 500.
- Inputs are zod schemas in `src/schemas.ts`; a route validates first and answers 400 with the issue list.
- `/health` answers `{ ok, commit }`; the commit is `TC_COMMIT`, set by the deploy workflow.
- Secrets only in Vercel's environment variables and `api/.env.local` (ignored); `.env.example` lists names.
  `SUPABASE_ANON_KEY` holds the project's publishable key. The service role key is never used here.
- Dependencies pinned exactly. Bun only (D16). The repo installs with bun's hoisted linker (`bunfig.toml`):
  Vercel's TypeScript check cannot follow the isolated linker's symlinks.
- Tests: `bun test` with `app.request(...)`; no network in tests.
- Deployment (D21): only `.github/workflows/deploy.yml`, started by hand (Actions → deploy → Run workflow, or
  `gh workflow run deploy`). It builds on the runner with Vercel's CLI pinned at 59.19.0, deploys `--prebuilt
  --prod` to project `tutor-central-api` ("Arun's projects", functions in `bom1`), smokes `/health` for the commit
  and `/ai/generate` for a 401, and prints the rollback (`vercel promote <previous>`). Git deploys are off
  (`vercel.json`). Production: the repo variable `API_ORIGIN`. Vercel blocks deployments that carry a commit
  author it does not know, so never deploy from a local checkout.
- Claude through `@anthropic-ai/sdk` (D35), the named `Anthropic` export (the default breaks Vercel's CommonJS type
  check): `messages.parse` with `zodOutputFormat`, one model per route, no fallbacks. One deadline across both tries
  (`CLAUDE_DEADLINE_MS`, 110 s, under the app's 125 s); a timeout is a 502 and the row is marked failed.
- `AI_FAKE=1` answers from `claude-fake.ts` (local runs only; never set on Vercel); the consent, limit and record paths
  still run against the database.
- Every database call is made as the user (`db.ts`, the user's JWT); `start_ai_generation` is the consent and limit gate.
  No photo is stored: `ai_generations.input` holds the page count and bytes, never the image.
- Photos are checked before any cost: magic bytes, round-trip base64, 3 MB decoded, six pages.
- `test/entry.test.ts` spawns the entry with `--no-env-file`, so `.env.local` does not leak into it.

Commands: `bun run dev` (local on :3000, needs `api/.env.local`); `bun run check` (tsc and tests);
`bun check --only=api`; `gh workflow run deploy`.
