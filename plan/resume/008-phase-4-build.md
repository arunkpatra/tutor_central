# Resume 008: Phase 4, attendance, schedule, tasks and Today live, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D32); `plan/phase-04-attendance-schedule-today.md`
(the scope) and `plan/phase-04-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md`,
`components.md` (its Phase 4 additions), `guidelines.md`, `information-architecture.md` ("Phase 4 boards" and the
Phase 4 launch states); `docs/runbooks/simulator.md` (D32: how every hand run is done); `plan/ui-polish.md` (U1 to
U4, which this phase closes). The spec is `docs/spec.md`. The last session's record is `plan/sessions/008/record.md`
(the boards and the plan); for how a build session ran, `plan/sessions/006/record.md` (Phase 3, with the Critical the
final review found and why) and `plan/sessions/007/record.md` (the runbook's measurements).

**Your work:** execute `plan/phase-04-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Twenty tasks, seven pull requests, tests first against the in-memory fakes.
Every screen is built to its approved board and photographed in both appearances (`bun shots <state>`), and the
pictures are in the pull request before it is merged (D7). Open every board's source in `docs/design/mockups/P4-*`
before building its screen; the canvas is https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (row 7).

**What is already true:** Phases 1 to 3 are done (PRs #1 to #33); build 0.1.0 (6) is on TestFlight; `main`'s
check is green. The 27 Phase 4 boards are approved (2026-10-08), and the Kit's attendance row was redrawn with
them (one pill per row, the whole row toggles). The schema already holds `attendance_sessions`, `attendance_marks`,
`calendar_events`, `tasks` and `message_log` with every column (migration 0001); the plan adds one additive
migration, 0004 `save_attendance`, which goes to production only through `gh workflow run deploy` (D26) before
the TestFlight lane will build. The plan's decisions table settles the small things (one attendance store and one
tasks store on `ShellState`; everyone starts present; the date picker and the class menu are popovers; a save waits
for the server, task and event edits are optimistic; the status-bar glass is one modifier on the four tab roots;
tiles share a height; the More root is AppShell's; the fixtures' clocks per Today state). None needs a number; a
decision the build takes that changes a rule gets one in `plan/README.md`.

**Session 6's lesson, now a rule:** every read's answer is decoded in a test against the shape the local stack
really returns (run the request with curl as the seed's tutor and paste the text into the test), and every write
path is run in Swift against the local stack before its pull request merges (a throwaway test with an in-memory
session, deleted before the commit). The plan names these steps in Tasks 6, 7, 8 and 16 and in PR 7's close.

**Hand runs (D32):** Task 20's table names every write path this phase adds, what to tap and the SQL that confirms
it. Do them by the runbook from a cold simulator before `gh workflow run testflight`, keep the screenshots on the
phase's issue.

**Every state has a board.** Build nothing that is not on a board; if a board cannot be built as drawn, stop and
ask. A value a board uses that no token names becomes a token first (`design-tokens.md` and Swift in the same
commit, D25); an anatomy number lives as a named constant on its component. The Kit screen changes only where its
boards changed (the attendance rows).

**Owner steps:** none inside the tasks. After PR 2, `gh workflow run deploy` (0004 to production). After PR 7,
`gh workflow run deploy` again (nothing should be pending) and, after the hand runs, `gh workflow run testflight`;
the owner installs the build. The owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the
local stack with `cd supabase && supabase start` so `bun check`'s db step runs), the Supabase CLI logged in and
linked, Vercel's CLI and `gh` logged in.

**How to work:** one branch per pull request as the plan names them (`phase-4/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; merge when the check is green and the pictures
match their boards (rule 2 of `CLAUDE.md` says how to check one without a browser if in doubt). Documents only go
to `main` directly, never mixed with code (D12). Decide small and medium things yourself and write them down; ask
the owner only for decisions that are his, one at a time. Polish seen on screen goes on `plan/ui-polish.md`, not
into the change in hand. This repo's git email stays `arunkpatra@gmail.com`.

**When a plan step does not match reality** (a supabase-swift signature, an iOS 26 behaviour such as
`onScrollGeometryChange` or a popover from a row, a fixture's number), fix it, record the deviation in
`plan/phase-04-attendance-schedule-today.md` under "As built", and add a numbered decision in `plan/README.md` if it
changes a rule. Never bend a board to the code: if a board cannot be built as drawn, stop and ask.

**End of the session** (Task 20): the deploy, the hand runs, the TestFlight build; "As built"; `plan/README.md`,
`plan/STATE.md`, `plan/ui-polish.md` (U1 to U4 to Done), the design documents where the build corrected a board's
words, the rules files, the session record `plan/sessions/009/record.md` and `owner-messages.md`; commit to `main`;
then ask for a reviewer pass on the seven merged pull requests with the `superpowers:requesting-code-review` skill
and record its outcome.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
