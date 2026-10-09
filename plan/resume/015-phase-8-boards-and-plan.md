# Resume 015: Phase 8 (the product website, tutorcentral.in), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D43; D42 settles the website's stack, D43 adds
   Phase 9), `plan/ui-polish.md`.
3. `plan/phase-08-website.md` (the scope), `plan/phase-09-user-testing.md` (what this phase unblocks),
   `plan/phase-00-design.md` and `plan/phase-00-plan.md` (step 0.9 is yours), `plan/phase-07-settings-and-hardening.md`
   "As built".
4. `docs/design/README.md` (including the owner's rule that a board's figures are illustrative), `design-tokens.md`,
   `components.md`, `guidelines.md`, `information-architecture.md`; `docs/spec.md` (what the app does and does not do,
   for the privacy page's claims: data in Supabase in Mumbai, the API in Mumbai, no tracking (D18), Claude through the
   API (D35), photos never stored (Phase 6), deletion from the app (D37, D38), WhatsApp links only (D3)).
5. The records of the last two sessions: `plan/sessions/014/record.md` (how the Phase 7 boards were drawn by script,
   checked by headless Chrome and approved, and how the plan was written) and `plan/sessions/015/record.md` and its
   `ledger.md` (Phase 7's build: its rulings, its review and the owner's findings on build 10).

**What is already true:** Phases 1 to 7 are done (PRs #1 to #73). Build 1.0.0 (11) is on TestFlight's internal group
(the owner's phone). Production: Supabase in Mumbai with migrations 0001 to 0008, the API on Vercel (`tutor-central-api`)
at the commit `STATE.md` names, deployed only through `deploy.yml` (D21, D26). What Phase 8 starts from:
- **The app already links** `https://tutorcentral.in/terms` and `https://tutorcentral.in/privacy` (sign-in, Settings'
  About, Help); Help's email is `hello@tutorcentral.in` (Resend sends from that domain, D30; its DNS is at GoDaddy).
- **The domain** `tutorcentral.in` is the owner's, at GoDaddy, holding Resend's records (DKIM, SPF via `send`, DMARC).
  Nothing serves the web root yet.
- **The stack (D42):** Next.js in `web/`, beside `api/` and `ios/`, on Vercel as a second project, built with Bun (D16,
  never npm), dependencies pinned (D14), deployed by a workflow started by hand (as `deploy.yml` does for the API).
  Vercel Hobby refuses deploys whose commit author it does not know; the repo's git email stays `arunkpatra@gmail.com`.
- **The look:** Ember (D20): warm charcoal, marigold, SF Pro on Apple devices (the site needs a web font stack that
  falls back well elsewhere: decide it and write it down), the icon and the book (D29). The app's tokens are in
  `docs/design/design-tokens.md`; the site should read as the same product, not as the app's screens.
- **The canvas:** https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 10 and row 10b (y 14600) hold Phase 7's boards.
- **The polish slice Phase 8 owns:** U7, U16, U24 and Phase 6's minors 1, 6, 7 (`plan/sessions/013/record.md`); U6 and U9
  were closed in Phase 7.

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.9, the website's boards** (`phase-00-plan.md`): Home (what the app does and for whom, in plain words a
   tuition teacher in India would use, the App Store link as a placeholder until there is one, TestFlight not mentioned),
   `/privacy`, `/terms`, `/support` (how to reach the owner; the Help email), a not-found page. Each at a desktop width
   (1280 to 1440) and a phone width (390), dark and light (D13); a PAGE's root is fluid (the Design type's rules). The
   legal pages' text is drafted from what the app really does (read the code and the spec, not the plan) and marked for
   the owner to review: nothing in it may promise what the app does not do. No invented figures, testimonials or
   features. Plus a board for each polish item Phase 8 takes where what is seen changes. A new canvas row (row 11).
   Draw by script and look at each one rendered (headless Chrome at the board's width) before showing; check the
   rendered colours against the tokens. Mirror the approved boards into `docs/design/mockups/` and `directions/canvas.json`,
   list them in `information-architecture.md`, commit as documents (D12).
2. **The Phase 8 plan**, `plan/phase-08-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first where there
   is logic, pull-request boundaries. Name, as the plan's own decisions or as one question at a time for the owner:
   Next.js's router and rendering (static where the pages are static), the web font, how `bun check` gains a `web` step
   (format, lint, types, tests, build) and CI runs it, the deploy workflow (`gh workflow run deploy-web` or one more job in
   `deploy.yml`) with a smoke that the four URLs answer 200, the Vercel project and its domain, and the owner's steps one
   at a time (the Vercel project, the DNS records at GoDaddy for `tutorcentral.in` and `www` without touching Resend's,
   HTTPS, the privacy URL into App Store Connect). Say how each page is proven: pictures at both widths and both
   appearances in the pull request (D7), the smoke after the deploy, the app's links opening the live pages in the
   simulator. Include the polish slice as its own pull requests (boards first where what is seen changes, hand runs by
   the runbook). Add a Review Focus and a self-review. Show the plan to the owner; on approval, write
   `plan/resume/016-phase-8-build.md` for an Opus 5.5 session and index it in `plan/resume/README.md`.

**Learn from Phase 7's build (session 15's record and ledger):**
- The owner tests every build on his phone and reports what a tutor would notice: keyboards covering fields, calendars
  and pickers, things too fast or too small. Draw those states on the boards (the keyboard up, the narrowest width).
- No technical words in anything a tutor reads (D41): no "server", "sync", "cache", "API", "backend", error codes. That
  holds for the website's copy too.
- Apple's own patterns are the reference when the owner asks "the Apple way": say which Apple app does it, and where
  Apple's guidance says not to (the launch screen is not a splash screen).
- Prove motion and timing by recording, not by single screenshots.

**Carry forward:**
- The deferred minors of Phase 7 (`plan/sessions/015/record.md`) and earlier phases stay the owner's; offer, take none.
- Phase 9 (user testing, D43) needs `/privacy` live for TestFlight's external group: the plan should end with the URL in
  App Store Connect, so Phase 9 can start.
- Sign-in follows Google's branding guidelines since #74 (the owner, 2026-10-09); the website's sign-in references, if any, should match.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/016/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
