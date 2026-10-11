# Phase 15: Make and polish

**Status:** Built (session 32, 2026-10-12) from `phase-15-plan.md` in #152 to #183 (hand runs #174); "As built, the build" below. The tutor round (Tasks 18 to 23) starts after the owner's own test of the build. **Depends on:** Phases 11 to 14; boards 10.7 and row 25.

## Goal

The ad hoc path exists for tutors who want it, Reports show progress, the polish list is worked, and tutors test V2.

## Scope

1. **Make something.** The kinds, each from a student, a group, a class level or a topic; the result as elsewhere.
   Question paper, Homework and Worksheet already take a class level with no batch (#122, P12-Form-Paper-Class); Make's
   For tile adds Student and Group around that, and does not bring back a batch for those kinds.
2. **Check a paper** moved from AITools to Make; Scan register stays in Students (D36).
3. **Reports** extended: progress per student and per term (skills secure, check trend, marks, attendance).
4. **Polish.** The open rows of `plan/ui-polish.md` the owner picks, by its "How it works".
5. **Tutor testing.** The first tutor round, on V2 (D66), on TestFlight by Phase 9's method (D52 to D55), with V2's guide; findings into
   fixes, the polish list or Phase 16.

## Acceptance

- Boards matched; pictures; the reports' numbers proven against the seed.
- The testing round has run its weeks and its findings are triaged.

## As built, the build (session 32, 2026-10-12)

Built from `plan/phase-15-plan.md` in pull requests #152 to #183 (the hand runs are issue #174). The ledger with each
ruling, hand run, fix and review finding is `plan/sessions/032/ledger.md`.

**The pull requests.** #152 AITools becomes Make; #153 migration 0026 (`artefacts.made_from`, `keep_artefact`'s eighth
parameter, the seed's three weeks of checks); #154 the note's `tutorSays` in the API; #155 Domain (the kinds, the target,
`MakeRules`, `Term`); #156 `ProgressRules` and `ProgressCSV`; #157 Data and Make's home; #158 the forms, the For sheet, the
choosers, the call and the made artefact's screen; #159 Check a paper under Make (U22, U23); #160 Reports' Progress (U26);
#161 the Kit's Phase 10 rows; #162 to #164 the twelve polish rows; #165 the trust page; #166 Check a paper waits for the
parent's consent with any scheme (found writing the trust page, D62); #167 to #173 the hand runs' fixes; #175 the price
sheet; #176 a test's clock; #177 to #183 every finding of the fresh review on Fable 5.1 (D68).

**Make something** (More, then "Make something"; Today's Create row). Five kinds for a student or a group (sheet, worked
example, figure, note to a parent, mock test) and four for the tutor (brief, question paper, homework, worksheet; the V1
three keep their forms). The For sheet picks a student, one of today's groups (each line naming its batch when two batches
meet), a batch or a class level, and opens on the chosen target's segment. A target's record gives the subject and the
skill; only the level and skill names reach the AI service, so no consent is needed (D62). A target with no class says the
way out in the helper's place (set it on the student's page, or choose a class in For). The made artefact keeps
`made_from = 'make'` and `made_for` (its eyebrow, Make it again's target) and opens on the Artefacts screens. Recent shows
the newest three of Make's artefacts and V1's results together ("today" for today's); History lists them by month, with a
copy on the iPhone. The note to a parent opens Phase 14's note with the tutor's own words (What to say, 300), carried whole;
the words are taken once. A mock for an exam that has one opens it. Each form remembers its last target or student (the
brief its class and subject); sign-out wipes them. "Key at the end" is for the tutor: Print carries the key, the shared PDF
does not.

**Check a paper under Make.** The intro has a Scheme tile and chooser (the student's mocks first, then the papers made
here with their day and time, or typed); a scheme chosen there skips the scheme step. Marking waits for the parent's
consent with any scheme. Mark from a photo names the mock on the tile; a scheme chosen in its place marks no exam.

**Reports' Progress.** By month or by term (the centre's calendar; Term 2 runs October to March, Karnataka's to April):
the hero (skills made secure, checks right, not on track, "at the end" for an ended span), a row per active student
(skills secure and percent right, the ladder's steps for the young, "Placed …" or the count while not known, absences),
three sorts, a row opens the student, the CSV. Each span and month has a copy on the iPhone, shown at once offline with
the line's time. No students reads Reports' empty card in Progress's words.

**The Kit's Phase 10 rows** and the twelve polish rows (U11, U17 to U23, U26, U32, U34, U40) are done; U36 was done by
#133. U48 (the Students empty card's Create a batch) was seen and added.

**The trust page** (`/trust`): what is kept, what reaches the AI service without consent (material from names; a school's
message), what goes only after the parent agrees, how consent is kept, what a parent can ask, and that deleting a student
deletes everything about them, including the messages and the AI records (migration 0027). Each sentence was checked
against the code twice (the build, then the review).

**Migration 0027** (the review): `ai_generations.student_id` with cascade, `message_log` deleted with the student, a V1
progress note waits for the parent's consent.

**Offline, as built.** A good read keeps its time in every list store, so a list on screen offline says when it was saved
(never "Nothing saved") (#169).

**The cost measured** (Task 15, real models): today's two plans with their material 21 calls ₹7.31; Make's nine kinds 9
calls ₹15.23 (a sheet on Sonnet ₹0.90, on Haiku ₹0.05; worked example ₹0.59; figure ₹0.51; brief ₹1.06; mock ₹3.51; note
₹0.06; question paper ₹1.41; marking two pages on Opus ₹7.14). A tutor's ad hoc sheet costs about what the plan's does;
the price sheet's typical tokens follow the run.

**Where the build moved from the plan, and why.** The made mock's eyebrow for a class's exam is the exam alone (Phase
13's rule). The sheet, worked example and figure forms have no Class tile (P10-Make-Form draws none): the helper names
the way out. Make's notes are not in Recent (opening them by week could write a new note): Recent's empty line no longer
names notes. P15-Consent-Note's words drop "our servers" (D41). The trust page's words follow the code where the board's
did not.

