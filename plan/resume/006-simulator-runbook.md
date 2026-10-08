# Resume 006: the simulator runbook (issue #34)

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, then `ios/CLAUDE.md` and `supabase/CLAUDE.md`; `plan/STATE.md`,
`plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D31); GitHub issue #34 (`gh issue view 34`), which is the
work order; and the last session's record, `plan/sessions/006/record.md`: "Not done, and why", "Final review" and
the open items it names.

**Your work:** issue #34. Find a way for a session to drive the app in the iOS Simulator against the local Supabase
stack (sign in, type into fields, tap, take settled screenshots) that works every time. Write it down as a runbook,
link the runbook from `CLAUDE.md` and `ios/CLAUDE.md`, and prove it with one full run. This is research first:
try each avenue the issue lists, measure what actually lands, and keep the evidence (commands, timings,
screenshots). Then decide, and say why.

**What is already true:**
- Phase 3 is done (PRs #24 to #31, review fixes #33). Build 0.1.0 (6) is on TestFlight; build 5 has a save bug and
  must not be used. `main`'s check is green.
- D31: a commit of documents only runs no CI.
- Session 6 could not type reliably through the Claude Code iOS Simulator tool's `text` and `tap`. The symptoms are
  in the issue: a missed tap, typing cut off by the next action, stale screenshots, and a simulator that later
  stalled failing test runs for ten minutes.
- These worked: `xcrun simctl launch booted in.tutorcentral.app --state <name>`, `xcrun simctl openurl booted
  "tutorcentral://…"`, `xcrun simctl io booted screenshot`, `bun shots`, and a throwaway Swift test with an
  in-memory session that ran every repository write against the local stack.
- The seed's tutor is `meera@example.com` / `tutor-local-1`, local only (`supabase/seed.sql`). The app reads the
  local stack through `ios/Config/Local.xcconfig`.
- The owner's Mac has Xcode 27, the iPhone 17 simulator, bun, Docker Desktop (start the stack with
  `cd supabase && supabase start`), the Supabase CLI, and `gh`, all logged in.

**Deliverables** (the issue's list):
1. A runbook, for example `docs/runbooks/simulator.md`, with the exact commands and the waits that make each step
   reliable. It covers: start the local stack; build and install a Debug build against it; launch; sign in as the
   seed's tutor; type into a field and confirm it landed; take a settled screenshot; open a deep link; recover a
   wedged simulator.
2. Links to the runbook from the root `CLAUDE.md` ("Where things are" and "Working with the owner": verify your
   own work, including a hand run against the local stack before any TestFlight build that changes a write path)
   and from `ios/CLAUDE.md`.
3. Any code the research needs, each change in its own pull request under the repo's rules (tests first where
   there is logic, `bun check` green). Two likely candidates: a debug-only local sign-in launch option, and
   `-collect-test-diagnostics never` in `tools/check/steps.ts`. A numbered decision in `plan/README.md` where a rule
   changes; the local sign-in touches rule 5 and D15, so weigh it explicitly.
4. Proof: follow the runbook end to end, in this session and from a cold simulator. Sign in; add, edit, archive,
   restore and delete a student; add a class, move a student into it, archive the class. Post the screenshots of
   each step on issue #34 (or in the pull request) and close the issue with a link to the runbook.

**How to work:** the runbook is documents only, so it goes to `main` directly (D12). Code goes through a pull
request on its own branch with a green check, never mixed with documents. Decide small and medium things yourself
and write them down. Ask the owner only for decisions that are his, one at a time: a launch option that signs in
with the seed's credentials is one, so put the trade-off to him before building it. Show each finding as you go,
briefly. This repo's git email stays `arunkpatra@gmail.com`.

If the owner reports anything from build 6, record it in `plan/STATE.md`. A fix to the app is its own pull
request, after the runbook exists, and is proven with it.

**End of the session:** issue #34 closed with the proof; the runbook linked; `plan/STATE.md` (the open item
closed), the session record `plan/sessions/007/record.md` and `owner-messages.md`; commit to `main` (documents
only).

Start by telling the owner in a few lines what you found and what you will do. Then do it.
