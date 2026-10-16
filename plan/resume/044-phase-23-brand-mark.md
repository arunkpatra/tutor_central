# Resume 044: Phase 23 (the brand mark), the board, the plan and the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5.
Phase 23 is small and its source has its own runbook, so one session draws its board, writes a short plan, has both
approved, builds, deploys and ships build 32 (D120, D121). Production holds migrations 0001 to 0068, the API, the portal and
the website at `ff534ffd`; `main` also holds #363 (formulae drawn in rows), which no build carries yet. 1.0.0 (31) is on the
owner's iPhone. The brand kit is the sister repository `/Users/arunkpatra/codebase/tutor_central_logo` at tag `v1.1.0`, approved
by the owner on 2026-10-16. Add it to the session as a working directory and read it, but never change it.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight); V3, the platform under them, is built (Phases 17 to 22). Phase 23 replaces D29's open book with the
approved brand mark (the cap, T and C) in the app, the website and the admin portal. The external testing round then starts on
its build, build 32 (D121), and Phase 16 follows (D81). Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `web/CLAUDE.md`, `admin/CLAUDE.md`, `docs/design/README.md`,
   `docs/working/pre-pr-proof.md`, `docs/working/testing.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D121; in particular D7, D10, D24, D29, D44 to D47, D68, D78,
   D86, D97, D120, D121).
3. `plan/phase-23-brand-mark.md` whole: the source, the scope, what is not in scope, the acceptance.
4. The kit, `/Users/arunkpatra/codebase/tutor_central_logo`: `README.md`, `CLAUDE.md`, then `docs/06-integration-tutor-central.md`
   (the runbook this phase follows), `docs/01-brand-mark.md`, `docs/03-ios-app-icon.md`, `docs/04-website.md`, `CHANGELOG.md`.
   Confirm the version: `git -C ../tutor_central_logo describe --tags` answers `v1.1.0`.
5. `plan/sessions/045/record.md` and `ledger.md` (Phase 22's build, #363, the owner's steps), `plan/phase-22-plan.md` (the form
   a plan takes).
6. The code the runbook names, surveyed by hand: `ios/App/Assets.xcassets/`, `ios/App/Info.plist`, `ios/project.yml`,
   `ios/TutorCentralKit/Sources/DesignSystem/Components/Marks.swift`, `Tokens+Color.swift` and the tests that hold the tokens
   to `docs/design/design-tokens.md`, `ios/TutorCentralKit/Sources/AppShell/OpeningCover.swift`, `web/components/Brand.tsx`,
   `web/components/Icon.tsx`, `web/app/` (`layout.tsx`, `icon.svg`, `globals.css`), `admin/components/Frame.tsx` and
   `Icon.tsx`, `admin/app/icon.svg`, `admin/proxy.ts`, and the boards P2-AppIcon, P7-Launch, P7-AppIcon-Home and P8's site
   header in `docs/design/mockups/`.

**What is already true:**
- The approved mark is in the kit, with Apple's own renders of the icon (`previews/icon-composer/`). The kit is the source:
  copy its files and never edit a copy. If an asset is wrong, stop and tell the owner; the fix is a new kit version.
- The website and the portal already have `--iconGround` (#131110) and `--iconMark` (#FFAB38). The app has no such tokens yet.
- The runbook was written against `c00e494e`; on 2026-10-16 the places it names had not changed. Check again before Task 1.
- No AI call is involved. `bun evals-changed` is expected to name nothing.
- Canvas 1 is full. Boards go on canvas 2 (https://claude.ai/artifact/JV9q2AGk1fmMDVjsGgpAqw, index
  `docs/design/directions/canvas-2.json`): row 31, below row 30 (its lowest edge is at y 21993).
- The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac. Deploys and the TestFlight run are yours.

**Your work:**
1. Check reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`). `bun check` green. Open
   `plan/sessions/046/ledger.md`.
2. **The board.** Draw one board (or a small group) on canvas 2's row 31, mirrored in `docs/design/mockups/P23-*`:
   - the icon in default, dark and tinted (the kit's renders);
   - sign-in in light and dark with the new 56 pt charcoal tile;
   - the launch screen;
   - the website's header and footer in light and dark, at 1280 and 390;
   - the portal's header and its sign-in door.

   Settle on the board whether the tile keeps `shadowLogo`'s glow and whether the website gets the link preview. Render it
   with headless Chrome, look at it, and send it to the owner. Get his approval: one question, with your recommendation and its
   reasons.
3. **The plan.** Write `plan/phase-23-plan.md`, short: the tasks, the pull requests (the app; the website and portal), the
   tests, the checks from the runbook's step 3, the deploys, build 32 and the owner's steps. Show it and get his approval.
   Then one documents commit to `main`: the board's mirror, `design-tokens.md` (`iconGround`, `iconMark`), `components.md`,
   `information-architecture.md`, `mockups/AppIcon.svg` from the kit, the plan.
4. **Build** by the plan. Every pull request: tests first where there is logic (the tokens' checks, the build tests that
   find the old book), RED and GREEN in the ledger, `bun check`, `bun evals-changed`, the pictures (`bun shots` for sign-in
   and the launch screen in both appearances; the Home Screen icon in light, dark and tinted with the app deleted first;
   `bun web-shots`, `bun admin-shots`; `bun pr-shots` for the table), the runbook's checks (`CFBundleIconName`, the icon's
   three layers in `Assets.car`), the pre-PR proof in the body. Merge on local green (D86).
5. **Ship.** After `main`'s check is green: `gh workflow run deploy-web` and `gh workflow run deploy-admin`, each read back
   (the new tab icon served, the smoke green); then `gh workflow run testflight` for build 32.
6. **The owner's steps,** one at a time, each a numbered list of exact actions with what success shows:
   - install build 32 from TestFlight and see the icon on his Home Screen, in light and dark;
   - open a brief with a formula and see The worked example to use drawn as maths (#363);
   - open tutorcentral.in and admin.tutorcentral.in and see the mark in the header and the browser tab.
7. **The round's documents:** a device test for the icon in `docs/testing/device-tests.md` (default, dark, clear and tinted, on
   light and dark wallpapers, in Spotlight, Settings and a notification); `docs/release.md` names build 32 for the round.
8. **Review.** One fresh reviewer on Fable 5.1 over the phase's diff: the kit's rules (no edited copy, Apple's icon rules),
   rule 3 (tokens), what the pictures show. Every finding fixed or ruled (D68).
9. **Close:** "As built" in `plan/phase-23-brand-mark.md`, the rule files the phase touched, `plan/README.md` (the phase's
   status), `plan/STATE.md`, `plan/sessions/046/record.md` and `owner-messages.md`; one documents commit to `main`. Then
   the next resume: the external testing round on build 32 (Phase 15's Tasks 20 to 23 by D52 to D55, on Fable 5.1), indexed
   in `plan/resume/README.md`.

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Keep count of costs in the ledger. Don't trouble the owner with cost details.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy,
  what a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41); the trade's words on the portal (D78).
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55).
- No automation spends on AI calls (D112).
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1). Marketing never shows an iPhone Home Screen (the kit's L7).
- Never a database test while local jobs run; `git add` only the files a commit is for; file lists through `xargs`.
