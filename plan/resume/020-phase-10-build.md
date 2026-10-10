# Resume 020: Phase 10 (V2 design and foundation), Part B, the plumbing

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(decision D17: the build runs on Opus once the plan is approved). Part A (the boards) continues on Fable in its own session
from `resume/019-phase-10-boards.md`; the two do not touch the same files.

---

You are continuing Tutor Central, a native iPhone app for tutors. V1 (Phases 0 to 9) is built and in user testing; V2's
Phase 10 lays the foundation. Read, in this order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D65; D56 to D65 are V2's), `plan/ui-polish.md`.
3. `docs/spec-v2.md` (sections 5, 7 and 9 are what you build the tables, routes and types for), `plan/phase-10-v2-design-and-foundation.md`
   (the scope) and **`plan/phase-10-plan.md`**: Part B is yours, Tasks 1 to 10, with their tests written out, the file structure, the
   six pull requests, the decisions the plan takes (class levels as text, the enums, the allowance, the photos bucket, the syllabus
   JSON, the share extension and background refresh identifiers) and the review focus. You execute it with
   `superpowers:executing-plans`, inline, task by task, ticking its boxes, with one ledger as session 15 kept
   (`plan/sessions/015/ledger.md`): every ruling with what it costs if wrong.
4. `docs/design/information-architecture.md` ("Phase 10 boards", steps 10.1 and 10.2: what the approved boards settle; nothing of it is
   built in this phase, but the tables and types must carry what they show: the class levels, the board, the message language, consent as
   the day and the number, the tracking status and its reasons, chapters and skills per student, the ladder, the textbook per school,
   class and subject, the placement's checks).
5. `plan/sessions/020/record.md` (the plan's session) and `plan/sessions/021/record.md` if it exists (the boards' session: the owner's
   rulings, among them "Batch" for V1's class on screen; the table stays `classes`).
6. `supabase/migrations/` 0001 to 0008 and `supabase/tests/` (the catalogue and isolation tests you extend), `api/src/schemas.ts`,
   `api/src/routes/ai.ts`, `api/src/db.ts`, `ios/project.yml`, `ios/TutorCentralKit/Sources/Domain/` and `Data/` (the shapes you add to).

**What is already true:** V1 is on TestFlight (build 18) with Phase 9 running alongside; production holds migrations 0001 to 0008
and the API at `main`'s head; the V2 spec is approved; the Phase 10 boards for steps 10.1 and 10.2 are approved and mirrored
(`docs/design/mockups/P10-*`); steps 10.3 to 10.7 continue on Fable alongside you. No V2 screen reaches a build in this phase (D6).

**Your work:** execute Part B of `plan/phase-10-plan.md` in its order, tests first:
1. Tasks 1 and 2 (migrations 0009 and 0010: students extended, schools, textbooks, chapters, skills; plans, plan items, artefacts,
   checks, homework, `close_session`), PR 1.
2. Tasks 3 and 4 (migration 0011: school items, marks, syllabi, message kinds, photos; 0012: the allowance), PR 2.
3. Task 5 (the syllabus JSON for CBSE and Karnataka state, classes 8 to 10, `bun syllabi`, migrations 0013 and 0014), PR 3.
4. Task 6 (the API's four route skeletons answering 501 after validation, the extended check-paper schema), PR 4.
5. Tasks 7 and 8 (Domain's V2 types and figure validators; Data's schools and textbooks repositories with fakes), PR 5.
6. Task 9 (the share extension target and background refresh; the owner registers the App ID and app group, one step at a time), PR 6.
7. Task 10: "As built", `plan/README.md`, `plan/STATE.md`, `resume/021-phase-11-boards-and-plan.md`, committed to `main` (D12).
Then the deploy (`gh workflow run deploy`: the migrate job first, D26) and a TestFlight build that shows nothing new and passes the V1
checklist. Each pull request: `bun check` green, one change, described by what it does and how it was checked; no screenshots are
needed where nothing on screen changes (rule 2 applies only to what is seen).

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time; no technical words in
anything a tutor reads (D41); plain voice in documents; nothing from V1 renamed in the model (D56); migrations additive (D26);
no service-role key anywhere (D37, D60); dependencies pinned, Bun only. Update `plan/STATE.md` before you stop; write
`plan/sessions/022/record.md` (or the next number) at the end.
