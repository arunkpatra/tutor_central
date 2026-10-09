# Session 16 (2026-10-09): the website's boards (step 0.9) and the Phase 8 plan

Model: Claude Fable 5.1 (D17), from `resume/015-phase-8-boards-and-plan.md`. Outcome: Phase 0 step 0.9 done (27 boards in row
11 of the canvas, approved), mirrored into `docs/design/`; `plan/phase-08-plan.md` written with `superpowers:writing-plans`
and approved; decisions D44 to D49; `resume/016-phase-8-build.md` for the Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, the state, the decisions, the Phase 8 and 9 scopes, the Phase 0 files, Phase 7's "As built", the design
   documents, the spec, the records of sessions 13 to 15 with the ledger, the app's legal links (`AppShell/Legal.swift`), Help's
   questions (`HelpView.questions`), the consent sheet's words, the migrations' columns, the API's prompts and `normalisePhone`,
   the check tooling, the workflows, the shots tools. Reality matched `STATE.md` (`main` at `cb6fc5c`, nothing open); the live
   canvas index equalled the repo's copy.
2. Told the owner what was found: U16 needs no board (P6-Check-Saved and P6-Scan-Review-RowRemoved already draw the toast above
   the footer); U7 and U24 get boards; session 14's generator survives in its scratchpad and its parts are reused.
3. Drew the boards by script: a page generator (`weblib.py`: the Ember tokens as CSS variables, the web's type scale, the frame,
   the list card, the parts; `pages.py`: the five pages' copy; `polish.py`: U7 and U24 derived from the approved P4-Event-Edit,
   P6-Scan-Review and P6-Check-Result-Edited sources by string edits, so nothing drifts; `render.py`; `sheets.py`;
   `check_colours.py`). One HTML per page and appearance, rendered at 1280 and 390 by headless Chrome, each frame as tall as the
   page (the root's bottom edge measured on the render). Looked at every render on contact sheets before showing; the colour
   count found only tokens and the glow's and shadows' blends over the ground (the legal pages are pure tokens).
4. Two renders went wrong before showing, both fixed in the generator: the page's title block sat outside the column (not
   wrapped), and the phone-width renders were laid out at 500 px: headless Chrome will not open a window narrower than 500 CSS
   px. The pages moved from media queries to container queries (the root is a container), and the narrow render wraps the root
   in a 390 px box inside a 500 px window, then crops. The real site keeps container queries: the root's width is the viewport's.
5. Published row 11 (y 16000 on; the title note at 15700): Home before and after the App Store link, `/privacy`, `/terms`,
   `/support`, not found, each at 1280 and 390, dark and light (fluid frames, `expand: fill`); P8-Event-Edit-Keyboard,
   P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled. Sent the sheets; the owner: "approved."
6. Mirrored the sources and the index into `docs/design/`; wrote the Phase 8 section of `information-architecture.md` (the board
   list, the three launch states, what the boards settle, the claims table: where each sentence on `/privacy` and `/terms` comes
   from), "Phase 8 parts" in `components.md`, the status in `README.md`, ticked 0.9 in the Phase 0 files; committed to `main`
   (`1af47d1`, D12).
7. Read the code the plan touches (the event sheet, the toast host and centre, the footer button, the AI stores' wiring, the
   phone normalisers, the Domain limits, the launch states and fixtures, the check steps and workflows, the smoke, the registry's
   current versions) and wrote `plan/phase-08-plan.md`: 14 tasks, 6 PRs, the owner's steps one at a time, tests first everywhere
   there is logic, a review focus of five with the test that pins each, D44 to D49, a self-review. The owner: "Approved".
8. Numbered D44 to D49 in `README.md`, wrote `resume/016-phase-8-build.md` and indexed it, `STATE.md`, this record and the
   owner's messages; committed to `main`.

## Why things are as they are

- **The site is drawn as pages, not phone frames.** The Design type's rule for a PAGE is a fluid root; one source per page and
  appearance is also how the site will be built, so the boards and the pages cannot drift in layout.
- **Container queries, not media queries,** came from the render problem (Chrome's 500 px floor) and stay because they are the
  same thing when the root is the viewport and let a board render at any frame width.
- **The system font stack, no web font** (D44): SF Pro is Apple's and not licensed for the web; a font file adds a request and a
  flash; Segoe and Roboto are the faces a Windows or Android visitor already reads. The app's identity is the tokens and the
  copy, not a typeface.
- **Appearance follows the device, no toggle.** The app has one because the owner prefers dark (D23); a website is read once and
  the device's setting is what the visitor chose. Both schemes are drawn (D13).
- **The hero's phone is the Today board itself,** dark on both pages: the app opens dark, and a dark phone on the cream page is
  true. No invented screen.
- **Copy in plain words for a tuition teacher in India:** "who came today", "who has paid this month", "fees by UPI", "WhatsApp,
  not a new inbox"; no "sync", "server", "API" (D41 holds on the site). No figures, no testimonials.
- **Every legal sentence has a source** (the claims table): the migrations' columns, the decisions, the API's rules. Where the app's
  own words go further than a fact we can prove (the consent sheet's "kept neither there nor by us" against Anthropic's retention
  terms), the page says what we can stand behind and the owner is asked (Owner step 0).
- **Placeholders stay visible until the owner fills them** (`[OWNER: …]`) and a test refuses to ship a legal page with one. The
  legal name, city, backup period and notice period are facts only he has.
- **A separate deploy workflow** (D45): the API's `deploy.yml` runs the migrate job first; a website text fix must not.
- **Pictures by Chrome's DevTools, not Playwright** (D46): no dependency (D14) and the same Chrome the boards were checked with;
  `Emulation.setDeviceMetricsOverride` gives 390 regardless of the window floor.
- **Biome only for `web/`** (D44): one pinned binary for format and lint; the repo's other TypeScript has no formatter today and
  the plan does not widen its scope.
- **U16 as one rule** (D49): the footer tells the toast centre its height; every screen with a footer is covered, including
  Attendance and Pending changes, instead of a flag per screen like the fee sheets' `aboveFooter`.
- **Lengths counted as Postgres counts** (D48): the only count that is never refused by the save.
- **Minor 1's scan store moves to the shell** for its visit, as the check store already does; the handlers capture their store
  weakly; the Undo toast keeps its strong hold on purpose (it must undo after the screen is gone).

## Tried and dropped

- Measuring a page's height by scanning for the ground colour: below the root the body is white, so the first measure returned
  the probe height; the measure now finds the root's bottom edge against the body's colour.
- `--window-size=390` for the phone renders: Chrome's floor is 500; the wrapper and crop replaced it.
- A board for U16: the approved boards already draw the fix.
- Media queries in the board's `<helmet>`: replaced by container queries (above).

## Machine

Xcode 27, Google Chrome 155 headless, Python 3 with Pillow, bun 1.3.11. The generator (`gen/weblib.py`, `pages.py`, `polish.py`,
`render.py`, `sheets.py`, `check_colours.py`), the renders and the sheets live in the session's scratchpad
(`…/592be418-…/scratchpad`); the canvas and `docs/design/mockups/` hold the real copies. Session 14's parts library is in
`…/bd917629-…/scratchpad/gen/lib.py`.

## Next

The build in a fresh Opus 5.5 session from `resume/016-phase-8-build.md`: PR 1 to PR 3 and the owner's steps put the site live
and the privacy URL into App Store Connect, which starts Phase 9; PRs 4 to 6 and build 14 follow.
