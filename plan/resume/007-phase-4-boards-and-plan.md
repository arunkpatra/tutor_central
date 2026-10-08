# Resume 007: Phase 4 (attendance, schedule, tasks, Today live), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D32), `plan/ui-polish.md`.
3. `plan/phase-04-attendance-schedule-today.md` (the scope), `plan/phase-00-design.md` and `plan/phase-00-plan.md`
   (step 0.5 is yours), `plan/phase-03-students-and-classes.md` "As built" (what Phase 3 left and why).
4. `docs/design/README.md`, `design-tokens.md`, `components.md`, `guidelines.md`, `information-architecture.md`;
   the Phase 4 rows of `docs/reference/functional-inventory.md`; `docs/spec.md`.
5. The records of the last two sessions: `plan/sessions/006/record.md` (Phase 3's build and final review) and
   `plan/sessions/007/record.md` (the simulator runbook); `plan/sessions/005/record.md` says how the Phase 3 boards
   were drawn and approved.

**What is already true:** Phases 1 to 3 are done (PRs #1 to #33). Build 0.1.0 (6) is on TestFlight: sign-in, onboarding,
Today (its counts are real, the rest of it is Phase 2's fixed content), and the register (students and classes: add,
edit, archive, restore, delete, members, deep links); build 5 has a save bug and must not be used. Production:
Supabase in Mumbai with migrations 0001 to 0003 (migrations go up only through `deploy.yml`, D26), the API on Vercel,
email through Resend (D30). The schema from migration 0001 already holds the Phase 4 tables (`attendance_sessions`,
`attendance_marks`, `calendar_events`, `tasks`, `message_log`); check them against the scope before planning a
migration. The canvas is https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 6 holds the 22 Phase 3 boards. The
simulator runbook `docs/runbooks/simulator.md` (D32) is how the build session will prove each write path against
the local stack; plan for it.

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.5, the Phase 4 boards** (`phase-00-plan.md` lists them): attendance mark (fresh, exceptions,
   saved, past date), the absence alert, history by date and by student, schedule month and day, new and edit
   event, tasks on Today and under More, Today live (morning with a class soon, evening with nothing left, a day
   with no class). A new canvas row (row 7), dark for every state board, light for the shell-level ones (Today live
   and attendance mark at least), built from the tokens and the Kit, with the seed's real content
   (`supabase/seed.sql`: ten students, Class 10 Maths and Class 8 Science with their days and times). Partial sheets
   are iOS 26's floating sheets (D28). Every state the phase file names has a board. Mirror the approved boards into
   `docs/design/mockups/` and `directions/canvas.json`, list them in `information-architecture.md` with their launch
   states, commit as documents (D12).
2. **The Phase 4 plan**, `plan/phase-04-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first
   against in-memory fakes (as Phase 3's plan did), pull-request boundaries, any migration (additive only, D26; a
   new table carries `id`, `centre_id`, timestamps, RLS through `is_member` and a test), owner steps if any, a
   Review Focus, a self-review. Name, for each write path, the hand run against the local stack the build session
   does by the runbook before the TestFlight build (D32). Learn from session 6's Critical: a write's answer is
   decoded in a test against the shape the server really returns. Show the plan to the owner; on approval, write
   `plan/resume/008-phase-4-build.md` for an Opus 5.5 session and index it in `plan/resume/README.md`.

**Carry forward:**
- `plan/ui-polish.md` has three open items, all on Today. U2 (the "Start here" card beside a full register) and U3
  ("No classes yet" beside "1 Classes today") are Phase 2's fixed content that Today live replaces: draw Today so
  they are gone, and say in the plan which task closes them (they move to "Done" with that pull request). U1 (Today
  scrolls under the status bar) is the owner's: offer it, since the Today boards are being redrawn; don't take it
  unless he agrees.
- Open owner calls in `STATE.md` (the register cache on sign-out, P3-Students-Searching's "3 of 10", Google's mark)
  stay his; don't reopen them unless he raises one.
- If the owner reports anything from build 6, record it in `STATE.md`; a fix to the app is its own pull request in a
  build session, proven with the runbook, not part of this one.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/008/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
