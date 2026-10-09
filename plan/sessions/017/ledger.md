# SDD ledger — plan: plan/phase-08-plan.md
Spec: plan/phase-08-website.md + boards docs/design/mockups/P8-* (binding).
Setup: Ruling: branches per PR in the main checkout (phase-8/...), not a worktree, as session 15 did — the plan names its branches — cost if wrong: none, main untouched until merge.
Setup: start state main 35c080d clean, no open PRs, bun check green (cached); the six pinned web packages exist on the registry.
Pre-flight: the plan's own "Type consistency" section was checked by its author; rows added as tasks consume earlier interfaces.
Task 1: Ruling: next-env.d.ts is ignored, not committed, and `next typegen` runs before tsc in web's check — Next 16 rewrites it to import .next/types/*.d.ts, which a fresh clone lacks — cost if wrong: one script line.
Task 1: Ruling: tsconfig is what next build writes (jsx react-jsx, .next/dev/types included) so the build never rewrites it — cost: none.
Task 1: Ruling: the secondary button's fill is a new CSS variable --buttonFill (#272220 dark, #FFFFFF light, the token's values), not surface1 — the boards' --btn2 — cost if wrong: a shade in dark.
Task 1: Ruling: the brand tile's fixed #131110/#FFAB38 are variables --iconGround/--iconMark in :root (the app icon's colours, D29, both schemes) — the plan's raw hex failed its own no-raw-colour test — cost: none.
Task 1: Ruling: the no-raw-colour test slices after the end of the dark --textOnAccent line, not inside its value — the plan's slice caught the token's own hex — cost: none.
Task 1: Ruling: the reduced-motion rule (transition: none !important) is dropped — the site has no transition, so it was dead, and Biome's lint refuses !important — cost: none.
Task 1: Ruling: biome.json uses "preset": "recommended" (Biome 2.5.15 deprecates "recommended": true; its own migrate wrote "none", which would turn the rules off; checked noExplicitAny still fires) — cost: none.
Task 1: complete (commits 35c080d..e4fa99b, tests: bun check → all green incl. web (tokens 2, layout 2, export 2))
Task 2: Ruling: Brand takes small (24 px tile, radius 6, book 13) or the default (28, 8, 16), the boards' exact sizes, instead of the plan's size scaling (6.86, 13.7) — cost: none.
Task 2: Ruling: the brand tile's rim is --iconRim rgba(255,171,56,.25), the boards' value, not accentTint (.14) — cost: none.
Task 2: Ruling: the parts' inline styles (footer column, footer nav gap, footer email colour, question row, text link) are classes in globals.css; the footer nav's 24 px gap holds at phone width as the board's inline style does — cost: none.
Task 2: Ruling: MAKER = "[OWNER: legal name]" added to content/site.ts now (the plan's note), the footer reads it — cost: none.
Task 2: complete (commits e4fa99b..50e9c67, tests: cd web && bun run check → unit 6/6, export 2/2, build green)
Task 3: Ruling: fileFor and shotName take the export's file check as a parameter (default: web/out); the test passes a fixed five-page export — the plan's test read web/out, which CI's iOS job (where tools runs) never builds, and would have needed flipping in Task 6 — cost: none.
Task 3: Ruling: the DevTools client rejects a command's promise on a protocol error (the plan resolved with a rejected promise), drops an event's waiter once it fires, and removes Chrome's temporary profile on close — cost: none.
Task 3: complete (commits 50e9c67..6adfe57, tests: bun test tools/web-shots.test.ts → 4/4; bun check --only=tools green; bun web-shots / and /nope at 1280,390 both → 8 pictures, looked at)
Task 4: Ruling: today-dark.png rendered by a DevTools script at 393 × 852, 2× (786 × 1704, 188 KB), not Chrome's --window-size (its 500 px floor) — cost: none.
Task 4: Ruling: the hero phone's rim is --phoneRim #1C1917 / --phoneEdge #3D3632 in both schemes (the boards draw the dark phone's rim on the light page too), not surface1/lineStrong — cost: none.
Task 4: Ruling: the feature row's text column has a 4 px gap (the board), the plain and question rows 6 — the plan's one .plain gap of 6 made each row 2 px taller — cost: none.
Task 4: Ruling: the apple glyph is the board's filled path (the plan's stroked one differs) — cost: none.
Task 4: Ruling: Home's maker line is built from MAKER and CITY (content/site.ts, CITY added now) so Owner step 0 fills one place; the phone's alt and "privacy page" are content strings — cost: none.
Task 4: Ruling: main has overflow-x: clip — the 920 px glow made a 320 px phone lay the page out 804 px wide (measured: scrollWidth 804 / innerWidth 804; after: 320 / 320, 390 / 390); clip on body did not help (it moves to the viewport, which a phone browser still widens); the pictures hid it because they clip to the width — cost: none. Review focus 3.
Task 4: Ruling: added tests: a blank APP_STORE_URL counts as unset; the words check ignores attributes (its own test); the counts 7/6/4 — cost: none.
Task 4: Seen: Home against its boards by pixel difference at 2×: 1280 dark and light, 390 dark and light: same heights (6214, 9210), mean difference 0.20–0.27 of 255 (anti-aliasing); the badge build against P8-Home-Badge 1280 dark/light and 390: same. Boards rendered without mobile emulation (no viewport meta on a board).
Task 4: complete (commits 6adfe57..a59169b, tests: bun check --only=tools,web → green; web unit 12/12, export 2/2)
Task 5: complete (commits a59169b..22beac3, tests: bun check → all green; web unit 13/13, export 2/2; not found against P8-NotFound at 1280/390 both: 390 mean diff ≤ 0.35; 1280 the same above the page's end (the board's frame is white below it, the site's ground); /anything-else at 320 and 390 lays out at the viewport's width)
Owner step 0.1: legal name = "GoodGround LLP" (the owner, 2026-10-09).
