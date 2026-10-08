# Resume 012: Phase 6, the AI tools, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D34); `plan/phase-06-ai-tools.md` (the
scope) and `plan/phase-06-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md` (its "Numbers
in code", the Phase 6 paragraph), `components.md` (its "Phase 6 parts" and the texts table: every row, card, sheet
and word), `guidelines.md`, `information-architecture.md` ("Phase 6 boards": the 38 launch states and what the
boards settle); `docs/runbooks/simulator.md` (D32: how every hand run is done); `plan/ui-polish.md` (U9, offered and
not taken). The spec is `docs/spec.md` (section 6 is the AI contract). The last session's record is
`plan/sessions/012/record.md` (the boards and the plan: why things are as they are); for how a build session ran,
`plan/sessions/011/record.md` (Phase 5: its rulings are the lint's shapes and the test timings the plan now follows).

**Before writing any call to Claude, load the `claude-api` skill** and write the API's client from its TypeScript
reference, not from memory: the plan's Task 2 names the exact shapes (`messages.parse`, `zodOutputFormat`,
`output_config.effort`, no `thinking` parameter, `stop_reason === "refusal"` checked first).

**Your work:** execute `plan/phase-06-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Twenty tasks, six pull requests, tests first: the RLS tests against local
Supabase, the API with `bun test` and `app.request` against a fake Claude and a fake database client (no network),
Domain and Data against the in-memory fakes, the stores against the fakes. Every screen is built to its approved
board and photographed in both appearances (`bun shots <state>`), and the pictures are in the pull request before
it is merged (D7). Open every board's source in `docs/design/mockups/P6-*` before building its screen; the canvas is
https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (row 9).

**What is already true:** Phases 1 to 5 are done (PRs #1 to #52); build 0.1.0 (8) is on TestFlight and the owner
tested it, the QR camera included; `main`'s check is green. The 44 Phase 6 boards are approved (2026-10-08).
Migration 0001 already holds `ai_generations`, the enums and `centres.ai_consent_at`; the plan adds two additive
migrations (0006 `pending`, 0007 `start_ai_generation`) and nothing else. The API's three routes validate and answer
501 today; the plan rewrites them. No Anthropic key exists yet: Task 20's steps 1 and 2 are the owner's (one message,
one step, checked before the next), and the deploy (`gh workflow run deploy`, the database first, D26) comes after PR
2 and the key, before PR 3. The decoding fixtures in the plan are the local stack's real answers, fetched on
2026-10-08 and pasted whole: use them as they are. The plan's decisions table settles the small things (downscale on
the device, no Storage; consent for scans, checks and progress notes; one `ClaudeClient` with a fake for tests and
local runs; one answer shape from the API; the call outlives the screen; results reopened from the database; the
paper's answer key as a scheme; scan rows and the register; the check's writes and their undo; the note's Send; the
API origin; the camera; the sample pictures). Two decisions carry numbers: D35 (the SDK dependency, PR 2) and D36
(Scan register in Students, PR 5): add them to `plan/README.md` in those pull requests.

**The lint's shapes and the test timings, now in the plan:** no tuple of three or more members (structs), at most
six parameters to a function (an initialiser may take more), files under 400 lines and types under 250 (a test
struct too), no force-unwrap in a test (`try #require`), `@MainActor` fakes and stores, a pure `static func` on a
view `nonisolated`; an `async let` in a `@MainActor` test does not start until the test suspends (start a `Task` and
give it 20 ms), and a scripted error set before a store's first read is used up by that read (set it after setup).
Where a board settles a layout, a detent or an interaction, build the board; where it shows a figure the fixture
cannot produce, the screen follows the data and the board is not redrawn (the owner's rule, `docs/design/README.md`).

**Rules this phase adds:** no photo is ever stored (not in Storage, not in `ai_generations.input`, not on the API);
every database call the API makes carries the tutor's own JWT (no service-role key); the Anthropic key lives only
in Vercel and `api/.env.local`; `AI_FAKE=1` makes the local API answer from the fake so a hand run of a failure
costs nothing while the consent, the limit and the record still run for real against local Supabase.

**Every read decoded, every write proven:** every repository read decodes a fixture that is the stack's real answer
(the plan's Tasks 6 and 7), and every write path is run in Swift against the local stack before its pull request
merges (a throwaway test with an in-memory session, deleted before the commit; Task 7's step 4).

**Hand runs (D32):** Task 20's table names every write path, which runs call the real API (one paper, one create
again, one scan, two checks: about $0.60) and which use the local fake, what to tap and the SQL that confirms it, and
what the simulator cannot do: it has no camera, so every photo comes from Photos (`xcrun simctl addmedia` of
`tools/samples/*.png`, which Task 20's decisions make with `tools/samples/make.swift`); the camera, its permission
alert and the refused state are the owner's iPhone after the TestFlight build (Task 20, step 6: three steps, one
message each, the answers recorded). Do them by the runbook from a cold simulator before `gh workflow run
testflight`, keep the screenshots on the phase's issue. Tasks 16 and 19 are the two write proofs in the simulator
that gate PRs 5 and 6.

**Every state has a board.** Build nothing that is not on a board; if a board cannot be built as drawn, stop and
ask. A value a board uses that no token names becomes a token first (`design-tokens.md` and Swift in the same
commit, D25); an anatomy number lives as a named constant on its component. The three system surfaces (the camera
alert, the document camera, the photo picker) are the system's and have no launch state. The Kit boards do not
change in this phase.

**Owner steps, in order:** (1) and (2), the Anthropic key into Vercel's `ANTHROPIC_API_KEY` and into `api/.env.local`,
are already done (the owner, 2026-10-09): skip Task 20's steps 1 and 2 and run its step 2 check (`bun run dev`, one real
call) when the API is built; (3) nothing until the TestFlight build; (4) the three checks on the phone. The
owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the local stack with `cd supabase &&
supabase start` so `bun check`'s db step runs), the Supabase CLI logged in and linked, Vercel's CLI and `gh` logged
in, Google Chrome.

**How to work:** one branch per pull request as the plan names them (`phase-6/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; merge when the check is green and the pictures
match their boards (rule 2 of `CLAUDE.md` says how to check one without a browser if in doubt). Documents only go
to `main` directly, never mixed with code (D12). Decide small and medium things yourself and write them down; ask
the owner only for decisions that are his, one at a time. Polish seen on screen goes on `plan/ui-polish.md`, not
into the change in hand. This repo's git email stays `arunkpatra@gmail.com`.

**When a plan step does not match reality** (an SDK signature, a VisionKit behaviour, a supabase-swift shape, a
fixture's number), fix it, record the deviation in `plan/phase-06-ai-tools.md` under "As built", and add a
numbered decision in `plan/README.md` if it changes a rule. Never bend a board to the code: if a board cannot be
built as drawn, stop and ask.

**End of the session** (Task 20): the hand runs, the TestFlight build, the owner's phone checks; "As built";
`plan/README.md`, `plan/STATE.md`, `plan/ui-polish.md`, the design documents where the build corrected a board's
words, the rules files, the session record `plan/sessions/013/record.md` and `owner-messages.md`; commit to `main`;
then ask for a reviewer pass on the six merged pull requests with the `superpowers:requesting-code-review` skill and
record its outcome.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
