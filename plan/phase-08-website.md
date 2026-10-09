# Phase 8: The product website, tutorcentral.in

**Status:** Not started (added in session 4 at the owner's request). **Depends on:** Phase 0's website boards
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
3. **Hosting and DNS.** The owner's decision, asked one question at a time when the phase starts: where it is
   hosted (Vercel is already in use for the API), how it is built, and the DNS records for `tutorcentral.in` and
   `www`. HTTPS on both.
4. **The polish slice and the minors** (the owner, 2026-10-09, on approving the Phase 7 plan): `plan/ui-polish.md`'s U6, U7,
   U9, U16 and U24, and Phase 6's deferred minors 1 (the two retain cycles in AppShell's closures), 6 (an 11-digit phone
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

(Written when the phase ends.)
