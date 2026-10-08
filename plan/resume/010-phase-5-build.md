# Resume 010: Phase 5, fees, UPI settings, reminders, receipts and reports, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D33); `plan/phase-05-fees-and-reports.md`
(the scope) and `plan/phase-05-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md` (its
"Numbers in code"), `components.md` (its "Phase 5 parts": every new row, card and sheet, and the two message texts),
`guidelines.md`, `information-architecture.md` ("Phase 5 boards": the 24 launch states and what the boards settle);
`docs/runbooks/simulator.md` (D32: how every hand run is done); `plan/ui-polish.md` (U12, which this phase closes;
U9, offered and not taken). The spec is `docs/spec.md`. The last session's record is `plan/sessions/010/record.md`
(the boards and the plan); for how a build session ran, `plan/sessions/009/record.md` (Phase 4: its rulings are the
lint's shapes the plan now follows) and `plan/sessions/007/record.md` (the runbook's measurements).

**Your work:** execute `plan/phase-05-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Fifteen tasks, six pull requests, tests first against the in-memory fakes.
Every screen is built to its approved board and photographed in both appearances (`bun shots <state>`), and the
pictures are in the pull request before it is merged (D7). Open every board's source in `docs/design/mockups/P5-*`
before building its screen; the canvas is https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (row 8).

**What is already true:** Phases 1 to 4 are done (PRs #1 to #44); build 0.1.0 (7) is on TestFlight and the owner
tested it; `main`'s check is green. The 27 Phase 5 boards are approved (2026-10-08). There is no migration in this
phase: migration 0001 holds every column, a reminder names its invoice by student and `about_date` set to the month,
and Generate's count is made on the device; the plan's decisions table says why. The decoding fixtures in the plan
are the local stack's real answers, fetched on 2026-10-08 and pasted whole: use them as they are. The plan's
decisions table settles the small things (every money write waits for the server and Undo is a second write; the fee
row's line; overdue and its banner; the payee card; the receipt after Mark paid; the QR kept on the phone only; the
student detail's actions open on the Fees tab; one fees store per centre). None needs a number; a decision the build
takes that changes a rule gets one in `plan/README.md`.

**The lint's shapes, now in the plan:** no tuple of three or more members (structs), at most six parameters to a
function (an initialiser may take more), files under 400 lines, no force-unwrap in a test (`try #require`),
`@MainActor` fakes and stores, a pure `static func` on a view `nonisolated`. Where a board settles a layout, a
detent or an interaction, build the board; where it shows a figure the fixture cannot produce, the screen follows the
data and the board is not redrawn (the owner's rule, `docs/design/README.md`).

**Session 6's lesson, now a rule:** every read's answer is decoded in a test against the shape the local stack
really returns, and every write path is run in Swift against the local stack before its pull request merges (a
throwaway test with an in-memory session, deleted before the commit). The plan names these steps in Tasks 5 and 6.

**Hand runs (D32):** Task 15's table names every write path this phase adds, what to tap and the SQL that confirms
it, plus what the simulator cannot do: the QR path is proven from Photos with a generated UPI QR added to the
simulator (Task 12 makes it; `xcrun simctl addmedia`), the camera on the owner's iPhone after the TestFlight build
(one step, one message, record the answer), the CSV copied out of the simulator and opened in Numbers. Do them by the
runbook from a cold simulator before `gh workflow run testflight`, keep the screenshots on the phase's issue.

**Every state has a board.** Build nothing that is not on a board; if a board cannot be built as drawn, stop and
ask. A value a board uses that no token names becomes a token first (`design-tokens.md` and Swift in the same
commit, D25); an anatomy number lives as a named constant on its component. The Kit boards do not change in this
phase.

**Owner steps:** none inside the tasks. After PR 6 and the hand runs, `gh workflow run testflight`; the owner
installs the build and scans a real UPI QR on the phone (Task 15, step 4). Nothing to deploy with `deploy.yml`. The
owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the local stack with `cd supabase &&
supabase start` so `bun check`'s db step runs), the Supabase CLI logged in and linked, Vercel's CLI and `gh` logged in.

**How to work:** one branch per pull request as the plan names them (`phase-5/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; merge when the check is green and the pictures
match their boards (rule 2 of `CLAUDE.md` says how to check one without a browser if in doubt). Documents only go
to `main` directly, never mixed with code (D12). Decide small and medium things yourself and write them down; ask
the owner only for decisions that are his, one at a time. Polish seen on screen goes on `plan/ui-polish.md`, not
into the change in hand. This repo's git email stays `arunkpatra@gmail.com`.

**When a plan step does not match reality** (a supabase-swift signature, a Vision or VisionKit behaviour, a
fixture's number), fix it, record the deviation in `plan/phase-05-fees-and-reports.md` under "As built", and add a
numbered decision in `plan/README.md` if it changes a rule. Never bend a board to the code: if a board cannot be
built as drawn, stop and ask.

**End of the session** (Task 15): the hand runs, the TestFlight build, the owner's camera check; "As built";
`plan/README.md`, `plan/STATE.md`, `plan/ui-polish.md` (U12 to Done), the design documents where the build corrected
a board's words, the rules files, the session record `plan/sessions/011/record.md` and `owner-messages.md`; commit
to `main`; then ask for a reviewer pass on the six merged pull requests with the
`superpowers:requesting-code-review` skill and record its outcome.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
