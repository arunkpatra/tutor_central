# Phase 8: The product website, tutorcentral.in

**Status:** Done 2026-10-09 (session 17, Opus 5.5): tutorcentral.in live, PRs #76 to #82, build 1.0.0 (14). **Next:**
Phase 9, user testing (D43), which needs this phase's privacy page for TestFlight's external group. **Depends on:** Phase 0's website boards
approved; the domain `tutorcentral.in`, which the owner has bought. **Must be live before:** the first App Store
submission (Phase 7's release candidate), because App Store review asks for a privacy policy URL, and the app
already links `https://tutorcentral.in/terms` and `https://tutorcentral.in/privacy` from sign-in (Phase 2).

## Goal

A small, fast site that says what Tutor Central is, carries the legal pages the app links to, and gives a tutor and
App Store review somewhere to reach the owner.

## Scope

1. **Pages.** Home (what the app does, for whom, the App Store link once there is one); `/privacy` (what is
   collected, where it is kept: Supabase in Mumbai, the API in Mumbai; no tracking, D18; deletion from the app,
   Phase 7); `/terms`; `/support` (how to reach the owner). The two legal URLs never move once the app ships.
2. **Design.** Boards first, in Ember (D20), on the canvas and in `docs/design/`, approved before any page is built
   (rule 1). Both appearances (D13).
3. **Hosting and DNS.** Next.js in `web/`, beside `api/` and `ios/`, on Vercel as a second project, built with Bun,
   deployed by a workflow started by hand (D42, the owner, 2026-10-09). The DNS records for `tutorcentral.in` and `www`
   (at GoDaddy, where the domain and Resend's records already are) are the owner's steps, one at a time; HTTPS on both.
   `bun check` gains a `web` step (format, lint, types, tests, build).
4. **The polish slice and the minors** (the owner, 2026-10-09, on approving the Phase 7 plan): `plan/ui-polish.md`'s U7,
   U16 and U24 (U6 and U9 were closed in Phase 7, #72 and #70), and Phase 6's deferred minors 1 (the two retain cycles in AppShell's closures), 6 (an 11-digit phone
   with a trunk 0) and 7 (the notes and draft limits count graphemes where Postgres counts code points), from
   `plan/sessions/013/record.md`. Each its own pull request with a board first where what is seen changes, by
   `plan/ui-polish.md`'s "How it works".
5. **Process.** Same as every phase: a plan file first, a pull request per change with pictures of each page
   (D7), deployed by a workflow started by hand, never from a local machine (as D21 does for the API).

## Acceptance

- `https://tutorcentral.in/privacy` and `https://tutorcentral.in/terms` answer 200 with the approved pages, and the
  links on the app's sign-in screen open them.
- Every page matches its board in both appearances; pictures in the PRs.
- The legal text is the owner's, reviewed by him; nothing in it promises what the app does not do.

## As built

Session 17 (2026-10-09, Opus 5.5, from `resume/016-phase-8-build.md`), the plan's 14 tasks in seven pull requests:

| PR | What |
|---|---|
| #76 | `web/`: Next.js 16.4.0 static export (D44), the tokens as CSS with their test, the frame and parts, Home and not found; `bun web-shots` (D46); the `web` step in `bun check` and CI (D47) |
| #77 | `/privacy`, `/terms`, `/support` with the owner's answers (GoodGround LLP, Bangalore; 30 days' notice; the AI service deletes within 30 days and never trains); D50, no internal names on the site |
| #78 | `deploy-web.yml` (D45) and `tools/web-smoke.ts`; `web/vercel.json` (git deploys off, a trailing slash redirects) |
| #79 | U7: Edit event keeps its fields and the note whole with the keyboard up; Delete scrolls under it |
| #80 | U16 (D49): a toast lifts above any footer; U24: the glass under the status bar on the pushed AI and scan screens |
| #81 | Phase 6's minors: trunk-0 phones in the API (6), lengths counted as Postgres counts (7, D48), stores that let go and one scan store per visit (1); the photos' 30-day words in the app |
| #82 | The whole-phase review's two Important fixes: a sheet's toast ignores a covered footer; the `web` step watches Help's answers |

**Production:** tutorcentral.in on Vercel `tutor-central-web` (root `web`, git deploys off), commit `f3f734d` by deploy-web run
37929980186, the smoke green; GoDaddy: `A @ 216.198.79.1`, `www` → the apex (Vercel's 307); Resend's records and `api` untouched.
The privacy URL and the test information are in App Store Connect (App Information, TestFlight). TestFlight 1.0.0 (14) by run
37938735658 with PRs #79 to #82.

**Where it moved from the plan, and why** (every ruling with its cost is in `plan/sessions/017/ledger.md`):
- D50, from the owner on the legal pages: no vendor or internal technology on the site; `/privacy` describes the services by
  role and names only the AI service (as the app's consent does). The boards' hosting sentences and the backup sentence were
  reworded or dropped; a test refuses the internal names.
- Supabase Free keeps no backups, so `/privacy` makes no backup claim (the claims table says so); a move to a plan with backups
  changes the page.
- The owner chose "within 30 days" for Anthropic's retention; the app's consent sheet, Help and the two intros now say the same.
- Next 16 writes `next-env.d.ts` with imports of generated types: it is ignored and `next typegen` runs before `tsc`.
- The hero's glow made a 320 px phone lay Home out 804 px wide: `main` clips it (on `body` it moved to the viewport).
- U7's column keeps the note's size by an explicit gap above Delete, not a Spacer (which grew the editor); the sheet sets
  interactive keyboard dismissal itself.
- U16's footers are tracked by id, so a pop in either order leaves the right one; a sheet's toast ignores them (#82).
- U24 covers the eleven AI and scan screens; the other pushed screens without the glass are U32 (no board yet).
- zod 4.6.5 already counts code points; the API's limits needed no change, a test pins it.
- Scan register's visit is counted by its pushes (like Check a paper's visit id); no `onDisappear` ending (a camera cover fires it).

**What remains:** the review's nine minors (deferred, in the ledger and the session record); U31 and U32 on the polish list;
Apple's badge artwork once the app is live; the owner's read of "deletes it within 30 days" (Anthropic keeps flagged inputs
longer) and of the terms' "What it costs".
