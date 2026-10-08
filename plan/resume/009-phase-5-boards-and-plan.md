# Resume 009: Phase 5 (fees, UPI settings, reminders, receipts, reports), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D33), `plan/ui-polish.md`.
3. `plan/phase-05-fees-and-reports.md` (the scope), `plan/phase-00-design.md` and `plan/phase-00-plan.md`
   (step 0.6 is yours), `plan/phase-04-attendance-schedule-today.md` "As built" (what Phase 4 left and why).
4. `docs/design/README.md` (including the owner's rule that a board's figures are illustrative), `design-tokens.md`,
   `components.md`, `guidelines.md`, `information-architecture.md`; the Phase 5 rows of
   `docs/reference/functional-inventory.md`; `docs/spec.md`.
5. The records of the last two sessions: `plan/sessions/008/record.md` (how the Phase 4 boards were drawn, checked and
   approved, and how the plan was written) and `plan/sessions/009/record.md` (Phase 4's build: its rulings show where
   the last plan was wrong).

**What is already true:** Phases 1 to 4 are done (PRs #1 to #44). Build 0.1.0 (7) is on TestFlight and the owner has
tested it on the iPhone: sign-in, onboarding, Today live, the register, attendance with the absence alert, history,
the schedule and events, tasks, and the More root. The Fees tab and More's Reports row are still "later"
placeholders (U12 is the Fees card's stale copy). Production: Supabase in Mumbai with migrations 0001 to 0005
(migrations go up only through `deploy.yml`, D26), the API on Vercel, email through Resend (D30). Migration 0001
already holds most of Phase 5: `fee_invoices` (status, `paid_at`, `paid_method`, `waived_reason`, one per student
and month), `generate_fees` (idempotent, returns the count made), `centres.upi_id`, `upi_confirmed_at` and
`send_receipts`, and `message_log` with kinds `reminder` and `receipt` (0005 added `about_date`). Check every one
against the scope before planning a migration: for example, whether a reminder needs to point at its invoice for a
row to say "Reminded on …", and whether "how many will be created" needs a read the database does not yet offer.
The seed has this month's fees for all ten students with six paid. The canvas is
https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 7 holds the 27 Phase 4 boards. The simulator runbook
`docs/runbooks/simulator.md` (D32) is how the build session proves each write path against the local stack.

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.6, the Phase 5 boards** (`phase-00-plan.md` lists them): Fees before generation, all, due,
   paid, overdue; generate month; mark paid (method, date, the undo toast); remind and receipt (the message text);
   waive with a reason; UPI settings (empty, filled, QR added) and the payee confirmation on Fees; the student
   detail's fees section live; reports for a month; export. A new canvas row (row 8), dark for every state board,
   light for the shell-level ones (Fees and Reports at least), built from the tokens and the Kit, with the seed's
   real content (`supabase/seed.sql`). Partial sheets are iOS 26's floating sheets (D28). Every state the phase file
   names has a board. Draw by script and look at each one rendered (headless Chrome) before showing, as session 8
   did. Mirror the approved boards into `docs/design/mockups/` and `directions/canvas.json`, list them in
   `information-architecture.md` with their launch states, extend `components.md` for new parts, commit as
   documents (D12).
2. **The Phase 5 plan**, `plan/phase-05-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first
   against in-memory fakes, pull-request boundaries, any migration (additive only, D26; a new table carries `id`,
   `centre_id`, timestamps, RLS through `is_member` and a test), owner steps if any, a Review Focus, a self-review.
   Name, for each write path, the hand run the build session does by the runbook before the TestFlight build (D32).
   Plan for what the simulator cannot do: it has no camera, so the QR path is proven from Photos with a test image
   from a real UPI app, and the camera path on the owner's phone; the CSV is opened in Numbers or Files. Show the plan
   to the owner; on approval, write `plan/resume/010-phase-5-build.md` for an Opus 5.5 session and index it in
   `plan/resume/README.md`.

**Learn from Phase 4's build (session 9's rulings):**
- Plan the code the lint allows: no 3-tuples (structs), at most six parameters to a function, files under 400 lines,
  no force-unwraps in tests (SwiftFormat strips them). Phase 4's plan needed a dozen rulings for these alone.
- Decoding fixtures are the local stack's real answers (curl), never invented. Test expectations are worked out
  from the seed and checked against the boards; three of Phase 4's were wrong.
- Where a board settles a layout, a detent or an interaction, the plan follows the board; where it shows a figure,
  the data decides. Read `ios/CLAUDE.md`'s newer rules (stores in `@State`, load generations, `Register` through
  Domain, the date-picker popover) and plan with them rather than around them.
- Money is the tutor's: say in the plan which writes wait for the server and which are optimistic with undo, and
  why (Phase 4 rolled back task edits but waited on attendance saves).

**Carry forward:**
- `plan/ui-polish.md`: U12 (the Fees placeholder's copy) goes away when Fees is built; say which task closes it.
  U9 (a failure toast behind the keyboard on sheets) will touch the fees sheets: offer it, don't take it unless the
  owner agrees. The others stay the owner's to choose.
- Open owner calls in `STATE.md` (the register cache on sign-out, Google's mark) stay the owner's; don't reopen them.
- If the owner reports anything from build 7, record it in `STATE.md`; a fix to the app is its own pull request in a
  build session, proven with the runbook, not part of this one.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/010/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
