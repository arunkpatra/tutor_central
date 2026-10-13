# Session 39: Phase 19's build (Opus 5.5, 2026-10-13)

From `plan/resume/037-phase-19-build.md`. The owner's messages are `owner-messages.md`; every ruling, test run, hand run,
fix and finding is `ledger.md`.

## What was done

- **The plan's Tasks 1 to 18**, in its order, each test first, each pull request merged on local green (D86): #262 to #287.
  Migrations 0046 to 0050; `admin/` (fifteen pages to the sixty boards of row 27, each picture compared side by side with
  its board by a board renderer and contact sheets in the scratchpad); the alerts job in the API; `deploy-admin.yml` and its
  smoke; `tools/totp.ts`, `tools/admin-shots.ts`, `tools/admin-smoke.ts`, `tools/admin-local.ts`; the trust page's sentence.
- **The owner's steps:** A (the admin account) and B (the Resend key and the alert address) at the start; C was not needed
  (the Vercel CLI set the Root Directory through `vercel api`); D (the CNAME at GoDaddy); E (his first sign-in and the
  authenticator, build 29 with reminders on).
- **The hand runs** (issue #286) by the new runbook `docs/runbooks/admin.md` in the built-in browser: nine runs, six
  findings (F1 to F6), each fixed with a test that failed first (#279 to #281). The commit-time security review found two
  redirect cases in F6's fix (a tab, `/.//`); both fixed in the same PR.
- **The review** on Fable 5.1, two fresh reviewers over an integration branch of everything built: thirteen findings, all
  fixed (#277, #283, #284, #285). The most serious: the portal's deploy would have failed its own smoke (the commit never
  reached the running functions); `job_stuck` would have alerted on every long morning plan; a V1 progress note or a
  typed-scheme paper check showed a student's name on a call's page.
- **Production:** Deploy A (0046, 0047, the API's alerts job), then 0048 to 0050, the portal's first deploy and the website.
  The owner signed in with his second factor; a job made to fail for the Smoke centre raised an alert that reached his
  email and his iPhone, and he acknowledged it in the portal.

## Why things are as they are

- **Merges wait while a deploy waits.** On `main` a newer push cancels a pending check, and the deploy's gate needs the
  check of the commit it takes; Deploy A's first try was refused for a cancelled check. From then on no merge went in while
  a deploy waited for its check.
- **Vercel's Git links removed.** The website's and the API's projects were still linked to GitHub; git deploys were off in
  `vercel.json`, but each push (main, every PR branch, `pr-shots`) still made a cancelled deployment, and those count
  against Hobby's 100 a day. This session's many pull requests used them up, and the API's last deploy was refused. Both
  projects are disconnected; deploys are the workflows' alone, as D21, D45 and D78 always meant.
- **Variables from Supabase, not from Vercel.** `vercel env pull` answers "[SENSITIVE]" for a sensitive variable, so the
  first copy of the API's keys wrote placeholders; the portal's three were set again from `supabase projects api-keys
  --reveal`, piped, never printed.
- The other rulings (the gate split across two modules, emails from the Auth admin API, row helpers by id, the enrolment's
  retry, the filters as menus of links, no "replayed" in the calls list) are the ledger's, with their cost if wrong.

## Tried and dropped

- Holding a failed enrolment's square in a cookie: the square is a 321 KB SVG; the retry keeps the factor and shows the key.
- Reading `auth.users` in SQL as the platform: refused (42501); the Auth admin API instead.
- Functions taking a table's row: PostgREST exposes them as columns and the generated types demand them of every row.

## What is next

The API's deploy of `main` when Vercel's window frees (the alerts job's code then matches 0049); 14 October's first morning
`alerts` rows; then Phase 20 (AI quality, the material) on Fable 5.1, boards first.
