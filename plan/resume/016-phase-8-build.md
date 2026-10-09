# Resume 016: Phase 8 (the website, tutorcentral.in, and the polish slice), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(decision D17: the build runs on Opus once the plan is approved).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres, and building its website.
Read, in this order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D49; D42 and D44 to D47 are the website's, D48 and
   D49 the app's two small rules this phase adds), `plan/ui-polish.md`.
3. `plan/phase-08-website.md` (the scope) and **`plan/phase-08-plan.md`** (the approved plan: 14 tasks, 6 pull requests, 6
   owner steps, a review focus, the decisions written out). You execute it with `superpowers:executing-plans`, inline, task
   by task, ticking its boxes, with one ledger as session 15 kept (`plan/sessions/015/ledger.md`): every ruling with what it
   costs if wrong.
4. `docs/design/README.md`, `information-architecture.md` ("Phase 8 boards": the frame, the type scale, what the boards settle,
   the claims table for the legal pages), `components.md` ("Phase 8 parts"), `design-tokens.md`; the boards
   `docs/design/mockups/P8-*.dc.html` (binding, rule 1: render one with headless Chrome to read it, the command is in the plan).
5. `docs/runbooks/simulator.md` (D32: how the app is driven in the simulator; its waits), `docs/release.md`.
6. `plan/sessions/016/record.md` (how the boards were drawn and what was decided), `plan/sessions/015/record.md` and
   `ledger.md` (how the last build ran: rulings, the review, the owner's findings).

**What is already true:** Phases 1 to 7 are done (PRs #1 to #75); build 1.0.0 (13) is on TestFlight's internal group. Production:
Supabase in Mumbai (migrations 0001 to 0008), the API on Vercel (`tutor-central-api`) deployed only by `deploy.yml`. The app
links `https://tutorcentral.in/terms` and `/privacy` from sign-in, Settings' About and Help; the domain is the owner's at
GoDaddy with Resend's mail records; nothing serves the web root yet. The step 0.9 boards (27, row 11 of the canvas) and the
plan are approved. Google Chrome 155 is on this Mac at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`.

**Your work:** execute `plan/phase-08-plan.md` in its order:
- PR 1 (Tasks 1 to 5): `web/` (Next.js 16.4.0, static export), the tokens as CSS with their test, the frame, Home, not found;
  `tools/web-shots.ts`; the `web` step of `bun check` and CI. Pictures at 1280 and 390 (and 320), dark and light, in the PR (D7).
- Owner step 0 (the five placeholders), asked one at a time, as early as the first PR is open: the legal pages (PR 2, Task 6) need
  them, and the export test refuses a legal page with `[OWNER:` on it.
- PR 2 (Task 6): privacy, terms, support from the boards' text with the owner's words in.
- PR 3 (Task 7), then Owner steps 1 to 5 one at a time (the Vercel project with root `web`, the two repo variables, the domain,
  the records at GoDaddy without touching Resend's, the first `gh workflow run deploy-web`), then Task 8 (the smoke by hand, the
  app's links opening the live pages in the simulator, the pictures), then Owner step 6 (the privacy URL in App Store Connect,
  App Information and TestFlight's Test Information). **That is what Phase 9 waits for**; say so to the owner when it is done.
- PRs 4 to 6 (Tasks 9 to 13): U7, U16 and U24, then Phase 6's minors 6 and 7, then minor 1; boards first where what is seen
  changes (they exist: P8-Event-Edit-Keyboard, P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled); hand runs by the runbook.
- Task 14: the D32 hand run, `gh workflow run testflight` (build 14), the documents close ("As built", README, STATE, the polish
  list, the session record and `owner-messages.md`).

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and write them
down in the ledger and the record. Be brief with the owner; show each finished part (the PR, its pictures beside the boards).
Verify your own work: `bun check` before every commit; look at every picture before putting it in a PR; the smoke and the curl
lines of Task 8 before telling the owner the site is live. Documents only go to `main` directly (D12), never mixed with code: the
`CLAUDE.md`, `plan/` and `docs/` changes of each PR are their own commit, as the plan says after each task. No technical words in
anything a tutor reads (D41), on the site as in the app (`web/test/unit/words.test.ts` holds it). Never `vercel deploy` from a
machine; never npm. If a board and the built page disagree, the board wins; if a board's figure and the data disagree, the data
wins (the owner's rule). Prove motion by recording, not single screenshots, if any motion comes up.

**Carry forward:** the deferred minors of Phase 7 (`plan/sessions/015/record.md`) and earlier phases stay the owner's; offer, take
none. The owner tests every build on his phone and reports what a tutor would notice; fix what he reports in its own PR and say
so. The Apple badge on Home is a drawing until the owner downloads Apple's badge artwork once the app is live (not this phase).

Start by telling the owner in a few lines what you found and what you will do. Then do it.
