# Resume 003: Phase 2, shell and sign-in, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D25); `plan/phase-02-shell-and-sign-in.md`
(the scope) and `plan/phase-02-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md`,
`components.md`, `guidelines.md`, `information-architecture.md`. The spec is `docs/spec.md`. The last session's
record is `plan/sessions/003/record.md` if it exists, else `002/record.md`.

**Your work:** execute `plan/phase-02-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Seventeen tasks, nine pull requests, tests first against the in-memory fakes.
Every screen is built to its approved board and photographed in both appearances (`bun shots <state>`), and the
pictures are in the pull request before it is merged (D7). Open every board's source in
`docs/design/mockups/` (and `directions/A-SignIn.dc.html`) before building its screen; the canvas is
https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (rows 1, 4 and 5).

**What is already true:** Phase 1 is done (PRs #1 to #8): `bun check` with its cache, CI on `xcode-27` and
Ubuntu, `bun shots`, `bun pr-shots`, the API in production through `deploy.yml`, the hosted Supabase project
`esowihbxawvoexflekxa` (Mumbai) with migration 0001. The Phase 2 boards are approved. The plan's decisions table
settles the small things; two of them are numbered (D24 TestFlight lane, D25 tokens as Swift). `bun check` is
green on `main`.

**Every state has a board**, the password sheet included (`P2-Email-Password`, drawn and approved in session 3).
Build nothing that is not on a board; if a board cannot be built as drawn, stop and ask.

**Owner steps:** inside Task 9 (App Store Connect record and App ID, Supabase's Apple and Google providers, the
Google web client, the redirect URL, the email code template and expiry, the two legal URLs) and Task 16 (the
App Store Connect API key, secrets and variables, the internal tester group, the first install). One step at a
time; check each result before the next. The owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker
Desktop, the Supabase CLI logged in and linked, Vercel's CLI and `gh` logged in.

**How to work:** one branch per pull request as the plan names them (`phase-2/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; on the first screen PR (the Kit) open the PR
page and see the pictures render before merging, and say so in the description. Merge when the check is green.
Documents only go to `main` directly, never mixed with code (D12). Decide small and medium things yourself and
write them down; ask the owner only for decisions that are his, one at a time. This repo's git email stays
`arunkpatra@gmail.com`.

**When a plan step does not match reality** (a supabase-swift signature, an Xcode option, what the local stack
answers for a wrong code), fix it, record the deviation in `plan/phase-02-shell-and-sign-in.md` under "As
built", and add a numbered decision in `plan/README.md` if it changes a rule. Never bend a board to the code:
if a board cannot be built as drawn, stop and ask.

**End of the session** (Task 17): "As built", `plan/README.md`, `plan/STATE.md`, the rules files, the session
record `plan/sessions/003/record.md` (or the next number) and `owner-messages.md`; commit to `main`; then ask
for a reviewer pass on the nine merged pull requests with the `superpowers:requesting-code-review` skill and
record its outcome.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
