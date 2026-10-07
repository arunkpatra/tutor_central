# Resume 004: Phase 3 (students and classes), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D30).
3. `plan/phase-03-students-and-classes.md` (the scope), `plan/phase-00-design.md` and `plan/phase-00-plan.md`
   (step 0.4 is yours), `plan/phase-02-shell-and-sign-in.md` "As built" (what Phase 2 left and why).
4. `docs/design/README.md`, `design-tokens.md`, `components.md`, `guidelines.md`, `information-architecture.md`;
   the Phase 3 rows of `docs/reference/functional-inventory.md`; `docs/spec.md`.
5. The last session's record: `plan/sessions/004/record.md`.

**What is already true:** Phases 1 and 2 are done (PRs #1 to #21). The app on TestFlight signs in with Apple, Google,
an email code or a password, creates the centre at onboarding, and shows Today empty with real counts, four tabs
that say "on the way", and minimal Settings. The design system is in code: every token of `design-tokens.md` is
Swift and a test holds the two together (D25); every Kit component exists. Production: Supabase in Mumbai with
migrations 0001 and 0002 (migrations go up only through `deploy.yml`, D26), the API on Vercel, email through
Resend from tutorcentral.in (D30), bundle id `in.tutorcentral.app` (D27). The canvas is
https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 5 holds the Phase 2 boards and the app icon (D29).

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.4, the Phase 3 boards** (`phase-00-plan.md` lists them): Students (empty, few, many, searching,
   filtered), the "+" menu, new student (empty, filled, invalid), edit student, student detail, archive and delete
   confirmations, classes (empty, list), new and edit class, class detail. A new canvas row (row 6), dark for every
   state board, light for the shell-level ones (the Students list and the student detail at least), built from the
   tokens and the Kit, with the seed's real content (`supabase/seed.sql`: ten students, two classes). Partial
   sheets are iOS 26's floating sheets (D28). Every state the phase file names has a board. Mirror the approved
   boards into `docs/design/mockups/` and `directions/canvas.json`, list them in `information-architecture.md`
   with their launch states, commit as documents (D12). Use the `artifact-design` and Design-type guidance the
   canvas carries; the record of session 3 says how a board was added before.
2. **The Phase 3 plan**, `plan/phase-03-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first
   against in-memory fakes (as Phase 2's plan did), pull-request boundaries, the migrations (new tables carry
   `id`, `centre_id`, timestamps, RLS through `is_member`, a test each; additive only, D26), owner steps if any, a
   Review Focus, a self-review. Show it to the owner; on approval, write `plan/resume/005-phase-3-build.md` for an
   Opus 5.5 session and index it.

**Carry forward from Phase 2** (in `STATE.md` and the session 4 record): the final review's fixes are merged
(PRs #22, #23; build 0.1.0 (4) on TestFlight). The owner wants a UI polish pass on the built screens later (first item seen: Today's content scrolls under
the status bar), and the review's minors are listed in the session 4 record. Do not start either unless the owner
asks; polish is its own slice with its own boards where anything changes.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/005/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
