# Phase 10: V2 design and foundation

**Status:** Done (2026-10-10): Part A, the boards, approved in full (session 21); Part B, the plumbing, PRs #90 to #96 (session 22). **Depends on:** `docs/spec-v2.md`; V1 done through Phase 8;
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

## As built, Part B (the plumbing, session 22, 2026-10-10, Opus 5.5)

Seven pull requests, each with `bun check` green; nothing on screen changed (D6). Executed inline from `phase-10-plan.md`
with a ledger (`plan/sessions/022/ledger.md`: every ruling with its cost if wrong) and a final review by a fresh reviewer
on Fable 5.1.

| PR | What |
|---|---|
| #90 | Migrations 0009 (students extended, schools, textbooks, chapters, skills, `copy_textbook_chapters`) and 0010 (plans, plan items, artefacts, checks, homework, `close_session`) |
| #91 | 0011 (school items, marks, syllabi, the V2 message kinds, the `photos` bucket), 0012 (the V2 `ai_kind` values), 0013 (the monthly allowance and per-student consent in `start_ai_generation`); CI starts Storage for the database tests |
| #92 | The API: `/ai/plan`, `/ai/make`, `/ai/parse-school`, `/ai/parse-textbook` validate and answer 501; check-paper takes a mock's key (501); the model for each V2 kind (`api/src/models.ts`) |
| #93 | iOS Domain (`Sources/Domain/Record/`): class levels, boards, message languages, how consent was given, tracking status, the ladder, skills and chapters, schools, textbooks, figure specs with validators; Data: the schools and textbooks repositories with fakes, the close (`AttendanceRepository.close`, `SessionClose`) |
| #94 | The share extension `TutorCentralShare` (`in.tutorcentral.app.share`), embedded, with the app group `group.in.tutorcentral`; `SharedInbox`; the background refresh `in.tutorcentral.app.refresh` |
| #95 | The syllabus data: 24 files under `supabase/syllabi/` (CBSE and Karnataka state, classes 8 to 10, the four subjects, 2026-27 books, class 10 blueprints), `bun syllabi`, migrations 0014 and 0015 |
| #96 | The review's three Important findings: 0016 (a second capture of a book keeps the students' progress; photo paths read the centre's id in any case; photos are add-only) and the mock's blueprint names |

**Production.** Deploy run 38042680418 applied 0009 to 0013 and put the API at `ea25689` (`/ai/plan` answers 401 without a
token); deploy run 38046925061 applied 0014 to 0016 with nothing pending after and the API at `d98e8e5`. TestFlight 1.0.0 (19), run
38047105651, carries the share extension (cloud-signed under its new App ID and the app group) and shows no new screen.

**Where the build moved from the plan, and why** (the full list with costs is the ledger):

- **What the approved boards show is in the tables.** `students.consent_how` (in person, on a call, on WhatsApp) and
  `track_since` (the tracking card's "since"); the ladder as one chapter per area (`chapters.ladder`) whose skills are the
  boards' five steps, so the close's checks and the states work the same for LKG to 3; `checks.kind` with a nullable session
  (the placement taken from the student's page); `homework.artefact_id` nullable (Phase 11's close runs without a plan);
  the close links the day's plan both ways.
- **The ladder's steps are the boards'** (Letters, Words, Sentences, Paragraph, Story; Traces, Letters, Words, Sentences,
  Short text; To 9, To 99, Add, Subtract, Multiply), not the plan's enums.
- **Migration numbers:** the enum values and the allowance are 0012 and 0013 (a version is digits; "0012b" is not one), so
  the syllabi are 0014 and 0015; `textbooks.chapters` and `copy_textbook_chapters` went into 0009 (PR 1 had not merged),
  so there is no plan-0015; 0016 is the review's.
- **`ai_generations` gained `unique (centre_id, id)`** so artefacts reference it compositely.
- **The photos policies go through `photo_centre(name)`,** which reads the first folder as a centre id or nothing; a cast
  in the policy would throw on any other bucket's paths.
- **The model per kind** (`api/src/models.ts`, the scope's table): the plan and the gap report, which the spec does not
  name, on Sonnet; marking stays check-paper's Opus. A mock's key on check-paper answers 501 until Phase 13.
- **The share extension** was first kept out of the app (Phase 9's testers would have seen a share entry that does
  nothing); when the owner cancelled Phase 9's tester run it was embedded, as planned, and the owner registered the app
  group, the extension's App ID and the group on the app's App ID. The extension writes JSON with an encoder (the plan's
  hand-escaped string broke on control characters); `SharedInbox` skips a file it cannot read.
- **The background refresh registers in `AppDelegate`** (iOS refuses a registration after launch ends) and is asked for
  when the app goes to the background; its handler does nothing until Phase 12.
- **The syllabus lists were transcribed by two research agents** from the publishers' 2026-27 PDFs and checked here
  (schema, blueprint sums, spot checks; no book text). Soft spots to correct in the JSON: English skills are short names
  for each lesson's task headings; a few chapters with fewer than three headings took the chapter's own key topics; some
  Karnataka headings were read by OCR.

**What later phases build to** (contracts this phase settled):

- Photos: `photos/<centre id>/<kind>/<uuid>.jpg`, JPEG up to 3 MB, add-only (a new photo takes a new path; no overwrite,
  move or copy). Nothing deletes a photo with its student or the account yet: the first phase that writes one (Phase 11,
  the textbook) deletes it through Storage.
- A textbook captured again is copied to the class again with `copy_textbook_chapters`; chapters match by position, skills
  by position; progress stays. A copy collides with a chapter of the same subject and position from another source.
- `errors.limit` says "today's"; the first V2 route that reaches the monthly allowance (Phase 12) words it for a month.
- `FigureSpec`'s JSON is Swift's synthesized shape; Phase 12 sets the wire format with the API's snake_case kinds.
- `SharedInbox` names every shared image `.jpg`; Phase 13 reads it by content (Photos may give HEIC).

Deferred minors from the review: the ledger's `Final: minor (deferred)` lines.
