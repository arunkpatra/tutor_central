# Resume 014: Phase 7, settings, account, notifications, offline, the release candidate, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D36); `plan/phase-07-settings-and-hardening.md`
(the scope) and `plan/phase-07-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md` (its
"Numbers in code", the Phase 7 paragraph), `components.md` (its "Phase 7 parts" and the texts table: every row, line,
sheet and word), `guidelines.md` ("States every screen has", "Accessibility"), `information-architecture.md` ("Phase 7
boards": the 35 launch states and what the boards settle); `docs/runbooks/simulator.md` (D32: how every hand run is
done); `docs/testing/device-tests.md` (D1 to D7: what the tester runs on the release candidate); `docs/release.md` does
not exist yet (Task 20 writes it). The last session's record is `plan/sessions/014/record.md` (the boards and the plan:
why things are as they are); for how a build session ran, `plan/sessions/013/record.md` (Phase 6: its rulings, its
hand run, its review).

**Your work:** execute `plan/phase-07-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Twenty-three tasks, eight pull requests, tests first: the RLS test against local
Supabase, the API with `bun test` and `app.request` against a fake Apple client (no network), Domain and Data against
the in-memory fakes, the scheduler against `FakeNotificationCenter`, the queue's replay against the repository fakes
with scripted errors, the stores against the fakes. Every screen is built to its approved board and photographed in
both appearances (`bun shots <state>`), and the pictures are in the pull request before it is merged (D7). Open every
board's source in `docs/design/mockups/P7-*` before building its screen; the canvas is
https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (row 10).

**What is already true:** Phases 1 to 6 are done (PRs #1 to #62); build 0.1.0 (9) is on TestFlight; `main`'s check is
green. The 41 Phase 7 boards are approved (2026-10-09). The owner chose option A for deletion (a `security definer`
`delete_account()`, D37) plus Apple token revocation through the API (D38); the function was proven on the local stack
on 2026-10-09 (every count 0 after one call as the seed's tutor), so Task 1 holds no surprise. Nothing of Phase 7 is
built: Settings is minimal, More shows Account and Help as later rows, only the register is cached, no notification
exists, `profiles.has_password` is never written, `Appearance` is stored but has no row. The plan's decisions table
settles the small things (the cached-read helper and which lists get one; the offline bar and the sync banners as
AppShell's status line; when the replay runs; the planner and the scheduler; what the tap of a notification does; the
password without the current one; the Apple row from `identities`; the deletion's counts from the register; the launch
screen and version 1.0.0; Help's email; the register cache removed on sign-out; Google's mark, offered). Four decisions
carry numbers: D37 (PR 1), D38 (PR 2), D39 and D40 (PR 4): add them to `plan/README.md` in those pull requests.

**The owner's rulings on the plan (2026-10-09):** everything approved; the polish slice (U6, U7, U9, U16, U24) and
Phase 6's deferred minors 1, 6 and 7 go to Phase 8, not this phase: take none of them, whatever Task 18 touches.

**The lint's shapes and the test timings, now in the plan:** no tuple of three or more members (structs), at most
six parameters to a function (an initialiser may take more), files under 400 lines and types under 250 (a test
struct too), lines under 120, no force-unwrap in a test (`try #require`), `@MainActor` fakes and stores, a pure
`static func` on a view `nonisolated`; an `async let` in a `@MainActor` test does not start until the test suspends
(start a `Task` and give it 20 ms), and a scripted error set before a store's first read is used up by that read.
Where a board settles a layout, a detent or an interaction, build the board; where it shows a figure the fixture
cannot produce, the screen follows the data and the board is not redrawn (the owner's rule, `docs/design/README.md`).

**Rules this phase adds:** `delete_account` is the second `security definer` function and the last (D37); the Sign
in with Apple key lives only in Vercel and `api/.env.local` (`APPLE_FAKE=1` makes the local API skip Apple so a hand
run costs nothing); every error says what is true (an offline sentence only when the monitor or the transport says
offline; "nothing was saved" only where it is so: Task 18 reviews every string); a write the tutor can leave runs in a
task its store owns; words meant for a screen that has gone are the caller's (the runner's toasts are AppShell's, shown
wherever the tutor is); sign-out and deletion wipe the phone (D40); the three offline writes and nothing else queue
(D39).

**Every write proven:** `setPassword`, `delete_account` and `profiles.has_password` are run in Swift against the local
stack before PR 4 merges (Task 7, step 5: a throwaway test with an in-memory session, deleted before the commit; then
`supabase db reset`). The Delete account screen (Task 13), the reminder (Task 17) and the offline runs (Tasks 15 and 16)
are proven in the simulator before their pull requests merge.

**Hand runs (D32):** Task 22's table names thirteen runs, what to tap and the SQL that confirms each, which pull request
each gates, and the owner's six steps (the Apple key into Vercel and `api/.env.local`; the deploy after PR 2; the
TestFlight build after PR 8; App Store Connect's test information and the external group, which waits for Phase 8's
privacy page; the tester). Offline is the stopped gateway (`docker stop supabase_kong_tutor_central`, then `docker
start`); a reminder is proven with a class that starts 16 minutes from now; Dynamic Type with `xcrun simctl ui booted
content_size accessibility-extra-large` (then `large` again); a deletion row by row with psql, then `supabase db reset`
(which ends the signed-in session: sign in again). Do them by the runbook from a cold simulator, keep the screenshots on
the phase's issue.

**Every state has a board.** Build nothing that is not on a board; if a board cannot be built as drawn, stop and
ask. A value a board uses that no token names becomes a token first (`design-tokens.md` and Swift in the same
commit, D25); an anatomy number lives as a named constant on its component. The notification permission alert, the
lock screen, the launch screen and the home screen are the system's and have no launch state (the launch and the home
pictures go in PR 8 by hand, Task 19). The Kit gains the Phase 7 parts in Task 18 and is re-shot.

**Owner steps, in order:** (1) the Sign in with Apple key; (2) the three variables into Vercel and `api/.env.local`;
(3) the deploy; (4) the TestFlight build; (5) App Store Connect; (6) the tester. One message, one step, checked before
the next. The owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the local stack with `cd
supabase && supabase start` so `bun check`'s db step runs), the Supabase CLI logged in and linked, Vercel's CLI and
`gh` logged in, Google Chrome.

**How to work:** one branch per pull request as the plan names them (`phase-7/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; merge when the check is green and the pictures
match their boards (rule 2 of `CLAUDE.md` says how to check one without a browser if in doubt). Documents only go
to `main` directly, never mixed with code (D12). Decide small and medium things yourself and write them down; ask
the owner only for decisions that are his, one at a time. Polish seen on screen goes on `plan/ui-polish.md`, not
into the change in hand. This repo's git email stays `arunkpatra@gmail.com`.

**When a plan step does not match reality** (a supabase-swift shape, a UserNotifications behaviour, an
AuthenticationServices detail, Apple's endpoints), fix it, record the deviation in
`plan/phase-07-settings-and-hardening.md` under "As built", and add a numbered decision in `plan/README.md` if it
changes a rule. Never bend a board to the code: if a board cannot be built as drawn, stop and ask.

**End of the session** (Tasks 21 to 23): the reviewer pass on the eight merged pull requests with the
`superpowers:requesting-code-review` skill, its Important findings fixed with a test that failed first; then the
TestFlight build and the owner's steps; "As built"; `plan/README.md`, `plan/STATE.md`, `plan/ui-polish.md`, the design
documents where the build corrected a board's words, the rules files, `docs/testing/device-tests.md` kept lean, the
session record `plan/sessions/015/record.md` and `owner-messages.md`; commit to `main`.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
