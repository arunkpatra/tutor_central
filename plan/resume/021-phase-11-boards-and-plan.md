# Resume 021: Phase 11 (the record and the close), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 11's boards are already approved (Phase 10 Part A, steps 10.1, 10.2 and the
close of 10.3); this session writes the plan and the build's resume prompt, then stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (the owner,
2026-10-10, D66; V1 was the proof of concept and Phase 9's V1 tester run was cancelled). Phase 10 (the V2 boards and the
plumbing) is done. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66; D56 to D66 are V2's), `plan/ui-polish.md`.
3. `docs/spec-v2.md` (sections 2, 4, 5, 6's close, 8's consent, 9), `plan/phase-11-record-and-close.md` (the scope), and
   `plan/phase-10-v2-design-and-foundation.md`'s two "As built" sections: Part A (what the boards settle) and Part B (the
   tables, functions, routes, types and repositories already built, and the contracts later phases build to).
4. `docs/design/information-architecture.md`, "Phase 10 boards": steps 10.1 (the shell: five tabs, More's layout, the
   School tab's empty state, Attendance under More), 10.2 (Students: the list by status, New student V2, the student's
   page, consent, the textbook capture, the ladder, the placement) and 10.3 (the close and its placement only; the plan
   itself is Phase 12's). `components.md` "Phase 10 parts", `design-tokens.md`, `feedback.md`. Open the boards on the
   canvas (rows 14 to 16) or in `docs/design/mockups/P10-*`.
5. `plan/sessions/022/record.md` and its `ledger.md` (Part B's rulings: why `consent_how`, `track_since`, the ladder as
   chapters, `checks.kind`, the nullable homework sheet, add-only photos), and `plan/sessions/021/record.md` (the owner's
   rulings: "Batch" on screen for V1's class, the table stays `classes`; the WhatsApp consent ask optional).
6. What Phase 11 builds on: `supabase/migrations/` 0009 to 0016, `supabase/tests/v2.test.ts`, `api/src/schemas.ts`
   (`MakeInput`'s placement and check, `ParseTextbookInput`), `api/src/models.ts`, `ios/TutorCentralKit/Sources/Domain/Record/`,
   `Sources/Data/Schools/`, `Sources/Data/Textbooks/`, `Sources/Data/Attendance/SessionClose.swift`.

**What is already true:** production holds migrations 0001 to 0016 and the API at `main`'s head with the four V2 routes
answering 501; the share extension and the app group are registered and in the app; no V2 screen is built (D6).

**Your work:** write `plan/phase-11-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (RLS, Domain's
tracking rules and the ladder, the API's `/ai/parse-textbook` and the placement and check kinds of `/ai/make`, the stores
against fakes), the file structure, the pull requests (one change each, screenshots per D7 for each board state), the
launch states the boards name, the D32 hand runs of each write (add student, consent, Keep a textbook, the placement, the
close online and offline), the review focus (what a person meets that no happy path exercises: a V1 student with no class,
a class with no book yet, a second capture of the book, a student who joins the class later, a close with attendance only,
consent recorded then cleared, a photo path, the five tabs from a V1 deep link). Decide small things in the plan and list
them; ask the owner one question at a time only for what is his. Then write `plan/resume/022-phase-11-build.md` for the
build on Opus 5.5 and index both in `plan/resume/README.md`. Show the owner the plan before any build starts. Documents
only, to `main` (D12).

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time; no technical
words in anything a tutor reads (D41); plain voice in documents (no slogans, no "every"); nothing from V1 renamed in the
model (D56); migrations additive (D26); no service-role key (D37, D60). Update `plan/STATE.md` before you stop; write
`plan/sessions/023/record.md` (or the next number) at the end.
