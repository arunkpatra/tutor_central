# Resume 005: Phase 3, students and classes, the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`;
`plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D30); `plan/phase-03-students-and-classes.md`
(the scope) and `plan/phase-03-plan.md` (the plan you execute); `docs/design/README.md`, `design-tokens.md`,
`components.md` (its Phase 3 additions), `guidelines.md`, `information-architecture.md` ("Phase 3 boards" and the
Phase 3 launch states). The spec is `docs/spec.md`. The last session's record is `plan/sessions/005/record.md`
(the boards and the plan) and, for how a build session ran, `plan/sessions/004/record.md`.

**Your work:** execute `plan/phase-03-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Nineteen tasks, eight pull requests, tests first against the in-memory fakes.
Every screen is built to its approved board and photographed in both appearances (`bun shots <state>`), and the
pictures are in the pull request before it is merged (D7). Open every board's source in `docs/design/mockups/P3-*`
before building its screen; the canvas is https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (row 6).

**What is already true:** Phases 1 and 2 are done (PRs #1 to #23); build 0.1.0 (4) is on TestFlight; `main`'s
check is green. The 22 Phase 3 boards are approved (2026-10-08). The schema already holds `students` and `classes`
with every column (migration 0001); the plan adds one additive migration, 0003 `archive_class`, which goes to
production only through `gh workflow run deploy` (D26) before the TestFlight lane will build. The plan's decisions
table settles the small things (the type is `Classroom`; the "+" menu is a popover so its state can be photographed;
removal from a class is the row's context menu; a JSON cache per centre; optimistic writes except delete). None
of them needs a number; a decision the build takes that changes a rule gets one in `plan/README.md`.

**Every state has a board.** Build nothing that is not on a board; if a board cannot be built as drawn, stop and
ask. A value a board uses that no token names becomes a token first (`design-tokens.md` and Swift in the same
commit, D25); an anatomy number lives as a named constant on its component. The Kit screen stays as its boards draw
it; the new components get previews.

**Owner steps:** none inside the tasks. After PR 7, run `gh workflow run deploy` (0003 to production; it also ran
once after PR 3) and `gh workflow run testflight`; the owner installs the build and tries the register with real
students. The owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the local stack with
`cd supabase && supabase start` so `bun check`'s db step runs), the Supabase CLI logged in and linked, Vercel's CLI
and `gh` logged in.

**How to work:** one branch per pull request as the plan names them (`phase-3/...`); `bun check` before every
commit; `gh pr create` with the pictures table from `bun pr-shots`; merge when the check is green (the pictures
render on the PR page; rule 2 of `CLAUDE.md` says how to check one without a browser if in doubt). Documents only
go to `main` directly, never mixed with code (D12). Decide small and medium things yourself and write them down;
ask the owner only for decisions that are his, one at a time. This repo's git email stays `arunkpatra@gmail.com`.

**When a plan step does not match reality** (a supabase-swift signature, a PostgREST embed, what iOS 26 does with
a popover or a compact date picker), fix it, record the deviation in `plan/phase-03-students-and-classes.md` under
"As built", and add a numbered decision in `plan/README.md` if it changes a rule. Never bend a board to the code:
if a board cannot be built as drawn, stop and ask.

**End of the session** (Task 19): the deploy and the TestFlight build; "As built"; the design-document corrections
the plan names (the popover, the context menu, the `class-archive-confirm` state); `plan/README.md`, `plan/STATE.md`,
the rules files, the session record `plan/sessions/006/record.md` and `owner-messages.md`; commit to `main`; then
ask for a reviewer pass on the eight merged pull requests with the `superpowers:requesting-code-review` skill and
record its outcome.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
