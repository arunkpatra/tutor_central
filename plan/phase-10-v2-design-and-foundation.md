# Phase 10: V2 design and foundation

**Status:** Running (session 21, 2026-10-10): Part A, the boards, approved in full; Part B, the plumbing, on Opus from `resume/020-phase-10-build.md`. **Depends on:** `docs/spec-v2.md`; V1 done through Phase 8;
Phase 9 running alongside. **Builds:** boards (design) and plumbing (D6); no new screen reaches a build.

## Goal

The V2 screens designed and approved, and the database, syllabus data and API routes in place so Phases 11 to 14 build
screens on them without a migration each.

## Scope

1. **Boards (Phase 0's method, `phase-00-plan.md`).** In Ember (D20), both appearances (D13), on the canvas and
   mirrored in `docs/design/`, approved by the owner step by step before any screen is built (rule 1). Steps:
   - 10.1 The shell: the five tabs (Today, Students, School, Fees, More) and More's new layout (Attendance and
     Schedule under Organise; Make something and Check a paper under Make).
   - 10.2 Students: add student V2 (class level LKG to 10, school, parent, language), the consent message and its
     record, the textbook contents capture (camera, the parsed chapters for confirmation, saved), the ladder and the
     placement, the student's page with the record (this week, skills by subject, check trend, marks, attendance,
     homework, school items, messages, consent), the list sorted by tracking status with its marks.
   - 10.3 Today: the plan (groups, lines per student, the material ready, the brief), "Planning today's class", Start
     class, the close (came, three checks, homework given, Done), after the close, the note day, a day with no batch.
   - 10.4 Artefacts: the sheet in three forms (PDF, board view, key), the worked example, each figure template, the
     brief, the check in the close, the placement, the mock, the gap report, "Own" (the tutor's photo in a plan line),
     regenerate with a reason.
   - 10.5 School: the share sheet's hand-off, items for confirmation (exam, homework, notice, holiday), the calendar,
     "Ask parents to forward", test tomorrow, exam preparation (the split, a daily set, the mock, marking, the gap
     report), the empty tab.
   - 10.6 Parents: the note (parent's language with English beside), can-now-do, the sent log on the student's page,
     the held suggestions, the not-on-track next step.
   - 10.7 Make: Make something (the kinds), Check a paper moved; Reports extended; the Kit's new rows.
   Each board states its figures are illustrative (`docs/design/README.md`). Copy follows D41.
2. **Migrations.** The tables of spec section 9, additive (D26): `students` extended, `schools`, `textbooks`,
   `chapters`, `skills`, `plans`, `plan_items`, `artefacts`, `attendance_sessions` extended, `checks`, `homework`,
   `school_items`, `marks`, `message_log` extended, `syllabi`; the functions `close_session` and `start_ai_generation`
   extended with the allowance; Storage buckets for textbook, item and mark photos under the centre. RLS and a test
   per table; `syllabi` readable by `authenticated` only, with a test that `anon` reads nothing. Types regenerated.
3. **Syllabus seeds.** Migrations with the chapter lists and skills for classes 8 to 10: CBSE (NCERT 2026-27 editions,
   class 9 new, class 10 old) and Karnataka state (2026-27), for mathematics, science, social science and English;
   the class 10 blueprints. Built by hand from the published PDFs; chapter names and topics only (D58). A test counts
   chapters per board, class and subject.
4. **API skeletons.** `POST /ai/plan`, `/ai/make`, `/ai/parse-school`, `/ai/parse-textbook` with their zod schemas,
   answering 501 with the contract; `/ai/check-paper` extended to take a mock's key; the model-by-kind table; the
   allowance gate; tests for the schemas and the gate.
5. **iOS plumbing.** Domain types for class levels, stages, the ladder, skills and states, figure specs with
   validators, plans and lines; the repositories with in-memory fakes; the share extension target in `project.yml`
   with its App ID (owner step) and app group; the background refresh task registered. Nothing on screen.
6. **Process.** A plan file (`phase-10-plan.md`) before work; pull requests per change; documents to `main` (D12).

## Owner steps (one at a time)

1. Approve each board step.
2. Register the share extension's App ID and the app group in the developer account.

## Acceptance

- Every V2 screen and state in spec sections 4 to 8 has an approved board mirrored in `docs/design/`.
- `bun check` green with the new tables, the RLS tests and the seed tests; migrations deployed to production by
  `deploy.yml` with nothing pending.
- The API's new routes answer 501 with their contract in production; `/health` at `main`'s head.
- A TestFlight build with the plumbing shows no new screen and passes the V1 checklist.

## Out of scope

Any V2 screen in a build; the share extension's UI; the parent-facing website text (Phase 16).

## As built, Part A (the boards, session 21, 2026-10-10)

Seven steps, seven rows of the canvas (14 to 20, y 37200 to 45600), 96 boards, each step approved by the owner the same day and
mirrored into `docs/design/` with its list, launch states, what the boards settle, parts, texts and numbers (`information-
architecture.md` "Phase 10 boards", `components.md` "Phase 10 parts", `design-tokens.md` "Numbers in code"):

| Step | Row | Boards | Approved with |
|---|---|---|---|
| 10.1 The shell | 14 | 7 | "Approved"; redrawn at 10.2 with "Batch" for V1's class |
| 10.2 Students | 15 | 23 | "Approved, Batch everywhere"; then the WhatsApp consent ask made optional (the owner) |
| 10.3 Today | 16 | 14 | "approved" |
| 10.4 Artefacts | 17 | 19 | "Approved" |
| 10.5 School | 18 | 13 | "Approved." |
| 10.6 Parents | 19 | 11 | "Approved" |
| 10.7 Make and the Kit | 20 | 9 | "Approved" |

Where the boards moved from the scope's list, and why:

- **"Batch" on screen for V1's class** (the owner, at 10.2): the student form now has "Class" meaning the student's class, so the
  group needed another word; the spec's word. The table stays `classes` (D56). V1's screens take the word as Phase 11 touches them.
- **Attendance under More has a board** (P10-Attendance-Pushed): moving a tab root changes what is seen (the Back row, the footer).
- **Tasks and Batches stay under Organise**: nothing from V1 is dropped (D56); the plan's line named only three rows.
- **The School tab's "+"** and its two empty-state buttons are drawn at 10.1 so the tab says how things reach it; until Phase 13
  builds the tab, Phase 11 shows the Later card in its place.
- **Consent is a section on the student's page with the WhatsApp ask optional** (the owner): Ask on WhatsApp or Parent agreed
  straight away; the record keeps how, the day and the number (D62 stands).
- **The Change sheet on the plan** (groups, subjects, keep for the weekday) was added at 10.3; the scope named only a moved
  student and a skipped line.
- **The check in the close and the placement** are drawn once (10.3, 10.2) and referenced from 10.4.
- **Print beside Share as PDF** on printable artefacts; the key left out of a shared sheet unless chosen.
- **Items are for a school's class** when the message names a class; Ask parents to forward sends one chat at a time; the calendar
  is a segment of the School root.
- **The note day's setting** is a wheel on the note day's hero, kept per batch; a held message is explained where it is seen.
- **Make something replaces AI Assistant's home** in Phase 15 with V1's four kinds kept; Progress is a third segment of Reports
  with Month | Term.

Part B's "As built" follows from the Opus session (Task 10 of the plan).
