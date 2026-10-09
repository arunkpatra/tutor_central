# Session 17 (2026-10-09): the Phase 8 build

Model: Claude Opus 5.5, from `resume/016-phase-8-build.md`, executing `plan/phase-08-plan.md` inline
(`superpowers:executing-plans`). Outcome: Phase 8 done in PRs #76 to #82; tutorcentral.in live on Vercel and its privacy URL in
App Store Connect, so Phase 9 can start; TestFlight 1.0.0 (14) with the polish slice and Phase 6's minors. The task-by-task
ledger, with every ruling and its cost if wrong, is `ledger.md` beside this record.

## What was done, in order

1. Read the rules, the state, the plan, the boards; reality matched `STATE.md` (`main` at `35c080d`, nothing open, `bun check`
   green). Told the owner what would happen.
2. PR #76 (Tasks 1 to 5): `web/`, the tokens as CSS, the frame, Home, not found, `bun web-shots`, the `web` check step and CI.
   Each page compared with its board rendered at the same width by the same DevTools client: same heights, a mean pixel
   difference of 0.2 to 0.3 of 255. A measure at 320 px found the hero's glow laying the page out 804 px wide (the pictures
   hid it: they clip to the width); `main` clips it now.
3. Owner step 0, one question at a time: GoodGround LLP; Bangalore; no backups (Supabase Free); 30 days' notice; on the legal
   pages the owner's rule, no internal technology on the public site (D50); Anthropic's retention checked in its privacy
   center (deleted within 30 days, never trained on) and the owner chose to say "within 30 days" in the app and on the site.
4. PR #77 (Task 6): privacy, terms, support, the D50 words test. PR #78 (Task 7): `deploy-web.yml`, the smoke, `vercel.json`.
5. Owner steps 1 to 6: the Vercel project (the session set the two repository variables); the domain in Vercel (the session
   read Vercel's wanted records with the CLI rather than asking for them); GoDaddy (the owner replaced the parking A records
   with `216.198.79.1` and kept `www` as a CNAME to the apex, which works: Vercel redirects `www` with a 307); the first
   `deploy-web` (run 37929980186, the smoke green); Task 8's curls and the app's links opening the live pages in the simulator
   (light from sign-in, dark from Settings); the privacy URL in App Store Connect and TestFlight. Told the owner Phase 9 can
   start.
6. PRs #79 (U7), #80 (U16 and U24), #81 (minors 1, 6, 7 and the 30-day words), each with tests first, pictures beside the
   boards and a hand run against the local stack (the event write; Scan's remove, Add and the Students toast; a second Scan
   visit starting fresh; Undo after the screen has gone).
7. The whole-phase review by a fresh Fable 5.1 reviewer: no Critical, two Important (fixed in #82, each with a test that failed
   first), nine minors deferred. The D32 hand run on the final code from a cold simulator, then `testflight` (run 37938735658,
   build 14).

## Why things are as they are

- **No internal names on the site (D50).** The owner's rule: the public pages say what a tutor and Apple's review need, by role
  (the hosting, an email service), and name only the AI service because the app's consent sheet already does and Apple asks
  that sharing with a third-party AI be disclosed. A test keeps it so.
- **The 30-day words in the app.** The consent sheet's "kept neither there nor by us" was not exact against Anthropic's terms;
  the owner chose to say "the service deletes it within 30 days and never uses it for training" everywhere.
- **Boards win over the plan's code** where they differed: the secondary button's `buttonFill`, the dark phone rim on the light
  page, the 4 pt feature-row gap, the legal pages' full-width paragraphs, Suggested marks without its AI line once saved.
- **Measured, not assumed:** Next 16's `next-env.d.ts`, Biome's lowercase hex, zod 4.6.5's code-point counting, Swift's three
  graphemes in क्षत्रिय, the sheet that does not take the root's keyboard dismissal: each found by running it, each a ruling.
- **U24 stops at the AI screens.** The plan's "every hidden navigation bar" test found 21 more screens without the glass; with
  no board for them they are U32, the owner's to take.

## Tried and dropped

- `overflow-x: clip` on `body` (moves to the viewport, which a phone still widens); on `main` it holds.
- A Spacer above Delete in Edit event (it shared the room with the text editor, which grew to 300 pt).
- Ending a scan visit on `onDisappear` (a full-screen cover fires it mid-scan).
- `pbcopy` without a UTF-8 locale for the Hindi paste (MacRoman mojibake; the well correctly turned red at 5,000+).

## The review's deferred minors

The `rgba(` filter in the tokens test; `themeColor` repeating the ground hex; "© 2026" hardcoded; "deletes it within 30 days"
absolute (Anthropic keeps flagged inputs longer: the owner's call); the hero phone's rim at 320 (U31); `web-shots` not draining
Chrome's stderr; `web-shots` not reporting `scrollWidth`; a spare scan store possible between Back and the pop; orphan words in
doc comments; the smoke not pinning `/Privacy` → 404.

## Machine

Xcode 27, Google Chrome 155 headless driven over DevTools from Bun, Python 3 with Pillow for pixel diffs, bun 1.3.11, the local
Supabase stack and the API with `AI_FAKE=1`. The Vercel CLI on this Mac is the owner's login (read-only use: `domains inspect`,
`api` for the domain's config).

## Next

Phase 9 (user testing, D43): its first step is the external group in App Store Connect. The owner installs build 14 and looks at
Edit event with the keyboard, a checked paper's Saved mark with its toast, and the scan list scrolled.
