# Resume 002: Phase 2, the plan (shell, sign-in, onboarding, first TestFlight)

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: planning on Fable; the plan's execution goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D23).
3. `plan/phase-02-shell-and-sign-in.md` (the scope you plan).
4. `plan/phase-01-foundation.md`, especially "As built" (what exists, and every way reality differed from the
   last plan).
5. `docs/design/README.md`, `docs/design/information-architecture.md`, `design-tokens.md`, `components.md`,
   `guidelines.md`.
6. `docs/reference/functional-inventory.md`, for the Phase 2 rows.

The spec is `docs/spec.md`. The last session's record is `plan/sessions/002/record.md`; read it for why things
are as they are.

**Your work:** write `plan/phase-02-plan.md` with the `superpowers:writing-plans` skill: tasks in order, tests
first where there is logic, pull request boundaries and branch names, the owner's steps placed where they are
needed, a Review Focus section, and a self-review. Show it to the owner and get his approval. Then write the next
resume prompt (`plan/resume/003-phase-2-build.md`, for an Opus 5.5 session that executes the plan with
`superpowers:executing-plans`), index it in `plan/resume/README.md`, update `plan/STATE.md`, and commit the
documents to `main` (D12). Build nothing in this session.

**What is already true:**
- **Phase 1 is done** (PRs #1 to #8):
  - `bun check` runs format, lint, ios, tools, api and db, with a cache.
  - CI: `check.yml`, iOS on `xcode-27`, api and db on Ubuntu.
  - `bun shots <state>` and `bun pr-shots`.
  - The app launches dark (D23) to a one-line placeholder on the iPhone 17 simulator (D22).
- **Supabase:** the hosted project is `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), with migration 0001 (every
  table, RLS, `create_centre`, `generate_fees`, `delete_centre`). The CLI on this Mac is logged in as the owner
  and `supabase/` is linked to it.
- **Vercel:** the API is in production at `https://api-ten-orpin-51.vercel.app` (`bom1`). It deploys only
  through `deploy.yml` (D21).
- **Tools:**
  - The Vercel CLI and `gh` (arunkpatra) are logged in.
  - Docker Desktop runs the local Supabase stack.
  - This repo's git email is `arunkpatra@gmail.com`. Keep it: Vercel blocks deploys of commits by other authors.
- **Design:** the Phase 2 boards are approved (step 0.3):
  - in `docs/design/mockups/`: `P2-*` and `Kit-*`
  - on the canvas: https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D
  - sign-in dark is in row 1 of the canvas

  No screen is built without a board, and a state without a board is designed and approved first.
- **Accounts the owner has not made yet** (one step at a time, when the plan needs them, each checked before the
  next):
  - App Store Connect app record, with Sign in with Apple on the identifier
  - Google OAuth client for iOS
  - Apple, Google and email-code providers in Supabase
  - App Store Connect API key for CI

**What the plan must settle** (decide small things and write them down; put the owner's decisions to him one at
a time):
- **Tokens as Swift**, and the test that fails when `design-tokens.md` and the source differ. Both appearances
  (D13), dark by default (D23).
- **The Kit screen** in debug builds.
- **Every board state** a `LaunchState` case, so `bun shots <state>` can photograph it (D7). The first screen PR
  must show its pictures rendering on the PR page: the Phase 1 review asked that this be seen once.
- **The session gate:**
  - signed out → sign-in
  - signed in without a centre → onboarding (`create_centre`, which needs a signed-in user)
  - otherwise the five tabs
- **Sign-in flows:** Apple, Google, email code, password when the account has one, each with errors in words.
- **TestFlight:** cloud signing with `-allowProvisioningUpdates`, and `testflight.yml` on a macOS runner with the
  API key. Note the `xcode-27` image (D22).
- **Tests:** Swift Testing for Domain, Data and the stores, against the repositories' in-memory fakes. No UI test
  suites (D15).
- **Fold in the Phase 1 review's deferred minors** where the plan touches their files (listed in
  `plan/STATE.md`, Open items), so they are not lost.

**How to work:**
- Be brief. Build in parts and show each one.
- Ask the owner only for decisions that are his, one at a time.
- Decisions in `plan/README.md` are not reopened; a change gets a new number.

Start by telling the owner in a few lines what you found and how you will plan. Then do it.
