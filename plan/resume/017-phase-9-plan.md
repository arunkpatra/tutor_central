# Resume 017: Phase 9 (user testing), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: planning on Fable; the work that follows goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D51; D43 adds Phase 9, D51 the App Store page),
   `plan/ui-polish.md` (the open rows are the owner's to schedule).
3. `plan/phase-09-user-testing.md` (the scope and acceptance you plan from), `docs/release.md` (the release checklist and
   TestFlight's test information), `docs/testing/device-tests.md` (D1 to D7 wait for the tester; S1 passed on build 9).
4. `docs/store/listing.md` (the App Store page as saved in App Store Connect, not submitted, and the review account),
   `docs/design/feedback.md` (how the app tells the tutor what happened, U33).
5. The last session's record: `plan/sessions/017/record.md`, its `ledger.md` and `owner-messages.md` (Phase 8's build, the
   crash a tester logged on build 13 and its fix, U33, the sheet title the owner found on build 16, the App Store page).

**What is already true:** Phases 1 to 8 are done (PRs #1 to #89). Build 1.0.0 (18) is on TestFlight's internal group (the
owner's phone). Production: Supabase in Mumbai (migrations 0001 to 0008), the API at `https://api.tutorcentral.in`, the
website at `https://tutorcentral.in` (Home, `/privacy`, `/terms`, `/support`), each deployed only by its workflow started by
hand (`deploy.yml`, `deploy-web.yml`). What Phase 9 starts from:
- **App Store Connect:** the Privacy Policy URL and TestFlight's Test Information (feedback email `hello@tutorcentral.in`)
  are set, so an external group can be made. The App Store page is filled and saved (screenshots, listing, App Privacy
  published, 4+, App Review Information with the demo account); submission waits for the end of this phase.
- **The review account** `review@tutorcentral.in` holds a seeded sample centre (`seed-review`, #89; every parent's number is
  the owner's). Testers get their own accounts: they sign in with Apple, Google or an email code, as any tutor.
- **Crashes:** TestFlight's crash reports and screenshot feedback are what the app has (no crash service, D18). The owner
  downloads a feedback zip; Claude reads it (session 17 did, for build 13's crash).
- **The owner tests every build** on his own iPhone and reports what a tutor would notice; findings so far were fixed in
  their own pull requests, boards first where what is seen changes.

**Your work, one part, approved by the owner:** the Phase 9 plan, `plan/phase-09-plan.md`, with
`superpowers:writing-plans`. Name, as one question at a time for the owner (only the owner's decisions):
- who tests (how many tutors, which: centre sizes, sign-in kinds, older iPhones, patchy networks) and for how long;
- whether the tester's device checks (D1 to D7) run before the tutors are invited or beside them.

Decide and write down yourself, as the plan's own decisions:
- the owner's App Store Connect steps for the external group, one at a time, each checked before the next: the group,
  Beta App Review, the build, the invitations (public link or emails);
- a tester's guide in plain words (D41: no technical words), where it lives (a page on the site, or a document the owner
  sends), and what to try in the first week;
- how findings are logged (a findings file under `plan/` with the build, the tester's words, a screenshot), how often they are
  read, and how each is triaged (bug, polish row, later phase, no change, with the reason);
- the cadence of builds and release notes (`docs/release.md`);
- what ends the phase: the acceptance in `phase-09-user-testing.md`, then App Store submission (attach the build, Add for
  Review) as the owner's step.

The plan has tasks in order and says how each is proven. Where a fix changes what is seen, the plan says: a board first,
pictures in the pull request (D7), the hand run by the runbook (D32). Add a Review Focus and a self-review. Show the plan
to the owner; on approval, write `plan/resume/018-phase-9-run.md` for an Opus 5.5 session and index it in
`plan/resume/README.md`.

**Learn from session 17:**
- Apple's way is the reference (the owner asks for it by name): say which Apple app does it and cite Apple's guidance. Toasts
  are for Undo only; everything else is native (U33, `docs/design/feedback.md`).
- Words Apple reads (the listing, review notes, a tester's guide sent through TestFlight) are held to App Review Guidelines
  2.3: accurate, no other company's name in keywords, AI disclosed as 5.1.2(i) asks.
- Claude creates no account and handles no password on a live system: the owner does those steps (the Supabase dashboard,
  App Store Connect), Claude gives them one at a time and checks each result.

**Carry forward:**
- The open polish rows (`plan/ui-polish.md`) and the deferred minors of earlier phases stay the owner's; offer, take none.
- `docs/testing/device-tests.md` D2 (tapping a class reminder) re-checks build 13's crash fix on a real iPhone.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and write them
down. This session writes no code. Documents only go to `main` directly. Update `STATE.md` and write
`plan/sessions/018/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
