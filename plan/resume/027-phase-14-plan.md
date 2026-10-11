# Resume 027: Phase 14 (Parents), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 14's boards are Phase 10's step 10.6 (approved) and the note day's list in
step 10.3 (P10-Today-NoteDay, approved); marks from a photo has only its entry point drawn (Add from a photo on the student's
Marks, P10-Student-Record). The owner widened the scope on 2026-10-11 (D67, D68). This session writes the plan and the
build's resume prompt, then stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 13
(School) is done: what a school sends becomes items on the School tab (shared from WhatsApp or Photos, pasted, or added by
hand), exams within 14 days turn their students' lines on Today to revision, the mock is made two days before in the
school's pattern and marked from a photo, the gap report sets the last days, Test tomorrow and Ask parents to forward go to
parents, and the student's page shows Marks (U36). Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` (Phase 13 added rules to each).
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D68: D67 and D68 are this phase's), `plan/ui-polish.md`
   (U41 to U45 are Phase 13's and this phase's to close).
3. `docs/spec-v2.md` (the parent sections: the weekly note, can-now-do, the cadence, consent and what is held, marks from a
   photo, not on track and the next step, the signature; the models by kind; section 7's message rows and section 8's
   cadence), `plan/phase-14-parents.md` (the scope, items 7 and 8 added by the owner), `plan/phase-13-school.md`'s "As built" (the messages to parents, the
   cadence as built, marking and marks, the cost measured, what was left open), and `plan/phase-11-record-and-close.md`'s
   "As built" (tracking statuses and their reasons, consent, the close).
4. `docs/design/information-architecture.md`, "Phase 10 boards", step 10.6 (the note, can-now-do, the sent log, a held note,
   not on track with the next step, the message to the parent, Today's line, the note day's setting; its launch states) and
   step 10.3 (the note day's list on Today, To parents after the close); `components.md` "Phase 10 parts" (10.6) and the "As
   built in Phase 13" notes; `design-tokens.md` ("Numbers in code", Phase 13's cadence and limits); `feedback.md`. Open the
   boards on the canvas or in `docs/design/mockups/P10-*`.
5. `plan/sessions/028/record.md` and its `ledger.md` (Phase 13's 102 rulings, the hand runs' eleven faults, the cost run,
   the review's four fixes and five deferred minors), and `plan/sessions/027/record.md` (Phase 13's plan, the house style).
6. What Phase 14 builds on: `Sources/Domain/School/MessageCadence.swift` (three suggested messages a parent a week, hand
   sends not counted), `TestTomorrowMessage.swift` and `DesignSystem`'s `TwoLanguageMessageSheet` (the two-language sheet),
   `Sources/Features/Today/TodayStore+Parents.swift` and `ToParentsSection` (To parents after the close), the message log
   (`Sources/Data/Messages/`, `message_log` and its kinds), `Sources/Domain/Record/TrackingRules.swift` and the student's
   page (`Sources/Features/Students/`), Check a paper's preset and marks (`Sources/Features/AITools/CheckStore*.swift`,
   `CheckPreset`, `MarkTarget`), `api/src/routes/v2.ts` and `prompts/` (test tomorrow's prompt is the pattern for a note in
   the parent's language), V1's progress note (`/ai/generate` kind `progress_note`), `api/src/models.ts` (the per-kind
   table and `MARKING_MODEL`, which D67 replaces), `api/src/auth.ts` (a failed verifier answers 401 "sign in again"),
   `ios/TutorCentralKit/Tests/DomainTests/PriceSheet.swift` (the test-side price sheet).

**What is already true:** production holds migrations 0001 to 0022 and the API at `cfddfc5` (Phase 13's kinds live); TestFlight
carries 1.0.0 (24), Phase 13; the owner installed it and tests the builds together after the last phase (D68), so the hand
runs in the simulator against the local stack are the check of each phase until then: plan them to cover each new screen
and each write. The cadence rule, the two-language
sheet, consent per student and the WhatsApp log already exist; Phase 14 extends them to the weekly note rather than building
them again. "Made with Tutor Central" is in no message yet. The owner approved real AI calls in testing without asking each
time (be judicious; record what ran and what it cost).

**Your work:** write `plan/phase-14-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (the note's facts
from the week's record: taught, got right, to practise, coming; can-now-do from the ladder for LKG to 3; the note day and
its change on the batch; the cadence holding a fourth suggestion and never a hand send; a held note and why; consent gating
the note; not on track and the next step chosen by the plan unless changed; the signature on each message; the API's note
and can-now-do kinds with the fake and the student's consent; marks from a report card or a marked test confirmed and
saved; the stores against fakes), the file structure, the pull requests (one change each, screenshots per D7 for each board
state), the launch states 10.6 names, the D32 hand runs (a note in Kannada and one in Hinglish with English beside, a parent
without consent getting no note with the reason on the student's page, the cadence holding a fourth suggestion, a report
card's marks read and saved), the cost of a week's notes measured for D64, the review focus (what a person meets that no
happy path exercises: a student absent all week, a student with no checks yet, a parent of two students, a note edited past
600 characters, the note day changed after notes were sent, a held suggestion that frees up mid-week, a report card with
subjects the student has no book for). Marks from a photo has no board beyond its entry point: name the boards it needs (the
reading and the marks to confirm) and get them approved on the canvas before their task, as Phase 13's row 23 was.

The owner's two rulings of 2026-10-11 are tasks of this plan, not questions:

- **D67, the model per kind of AI work in one place.** One checked-in table of work type to model, with a class band where
  it matters and marking a handwritten paper apart from reading a printed report card; an environment variable per work
  type (`AI_MODEL_<WORK_TYPE>` on Vercel; an unknown model name stops the API at start, so the deploy's smoke fails, not a
  tutor's call) overrides it at deploy with no code change, the owner's "env vars etc."; `MARKING_MODEL` and `models.ts`' table fold into it; the price sheet and
  the cost run read it; tests prove an override reaches the next call and its log. Measure reading a report card on Sonnet
  and on Opus in the cost run and set the table's default from it (the owner approved real calls for testing).
- **D68, what Phase 13 left, and what this phase finds.** Fold in U41 to U45 (a board first for any that changes what is seen
  beyond an approved board: likely U41, U42 and U43; U44 matches P10-School-Item; U45 is the mock's prompt), the five `Final: minor (deferred)` lines of `plan/sessions/028/ledger.md`, and the API's answer to a lost
  database connection ("sign in again" only when the token is refused). In the plan, the phase closes with no open finding
  of its own: a hand-run fault, a review finding of any grade, or a polish item the phase's work brought is fixed in the
  phase, each with a test that failed first. The review's minors are fixed in the fix pass too.

Decide small things in the plan and list them; ask the owner one question at a time only for what is his.

Then write `plan/resume/028-phase-14-build.md` for the build on Opus 5.5 and index both in `plan/resume/README.md`. Show
the owner the plan before any build starts. Documents only, to `main` (D12).

**The owner's rules:** check each request against the spec, the decisions, the boards and the code, and push back with a
concrete reason when it is wrong (`docs/working/pushback.md`); be brief; decide small things and say what you decided; ask
one question at a time; no technical words in anything a tutor reads (D41); plain voice in documents (no slogans, no
"every"); the word is Students, and Batch on screen; nothing from V1 renamed in the model (D56); migrations additive (D26);
no service-role key (D37, D60); nothing found in the phase is deferred (D68). Update `plan/STATE.md` before you stop; write `plan/sessions/029/record.md` (or the next
number) at the end.
