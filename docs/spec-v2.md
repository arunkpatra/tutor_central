# Tutor Central V2: product and technical specification

Drafted 2026-10-10 from the V2 brainstorm and `docs/v2/research.md`, revised the same day after a review. Not yet
approved. V1 (`docs/spec.md`, Phases 0 to 9) is the base; nothing V1 does is dropped (rule 10). The decisions this spec
needs are listed at the end; on approval they take numbers in `plan/README.md`.

## 1. What it is

V1 keeps the tutor's records: students, attendance, fees. V2 supports the teaching: the app plans each class, makes the
material, records the class in a few taps, keeps a record per student, drafts messages to parents, and flags students
who are falling behind with a suggested next step.

The tutor does not have to type. Inputs are forwarded school messages, photos (a timetable, a contents page, a marked
paper, a report card) and taps. The plan is the default way in; each tool in it can also be used on its own from the
screen where it applies (section 2).

### Who it is for

A tutor working alone, with 10 to 15 students of mixed classes in one evening batch, mostly LKG to class 7, sometimes to
class 10, all subjects for the younger ones, in English-medium schools. India: rupees, UPI, WhatsApp. iPhone, often
one-handed, often on mobile data. Not a centre or a team; those follow once the product has a large number of tutors.
Android follows later by the owner's plan.

### Out of scope in V2

- A menu of AI tools as the main way in. Artefacts are made for a student, a group, a session or an exam from the
  record; each can also be made directly from a student's page, a batch or More.
- A student app, video, live classes, a marketplace, lead generation. Parents receive WhatsApp messages and PDFs.
- Textbook text. The app holds syllabus facts (chapter names, skills, outcomes, blueprints) and nothing copied from a
  book (research section 2).
- Server-sent WhatsApp. Deep links as in V1 (D3).
- Claims about marks. The product claims measurable progress the parent can see and less preparation time for the
  tutor.
- Teaching material in Kannada or Hindi. Lessons, sheets and briefs are in English; parent messages are in the
  parent's language.
- A server job, a service-role key, server push notifications. The app makes the plan (section 9).

## 2. Design method

The tutors have their own ways of working and are not digital-savvy (D41). Two requirements compete: minimal effort
from the tutor, and no fixed process. The method that satisfies both: the app decides by default; the tutor can ignore
or change any decision where it appears; the app does not ask the tutor to configure anything.

1. **Each feature works on its own.** It works from the first tap with what is known at that moment. A sheet needs a
   class and a topic; a note needs a name and what happened; attendance needs no plan. No feature has a set-up step in
   front of it. The one exception is consent, and it applies only before a student's own data goes to the AI (section
   8), not to material made from a skill at a level.
2. **The plan is a suggestion.** Tonight shows what the app proposes. The tutor can follow it, follow part of it, change
   a line, or ignore it. The record learns from what the tutor did. A skipped line is not carried over and the app does
   not remind the tutor of it.
3. **The record grows from use, not from data entry.** What the tutor does adds to it. What the tutor does not do
   reduces precision and does not block anything. Where more information would help, the app says so once, at the place
   it applies, and not as a checklist.
4. **Defaults instead of questions.** Each choice has a default from the student's class and the tutor's past choices.
   A default can be changed where it appears, and the change is kept: note day, language, sheet length, number of
   groups, which students sit together, which subject on which day.
5. **Depth is optional and useful at once.** Attendance and fees alone are V1 and complete. A contents page makes the
   sheets follow the book. A forwarded school message enables exam preparation. Tapping the checks enables tracking.
   No layer depends on another.
6. **Hand-made material is treated the same as generated.** The tutor's own sheet (a photo), their own words in a note
   and their own grouping take the same place in the plan and the record.
7. **The close is the one routine the app makes easiest.** It is not required (attendance alone is a close), but it is
   what makes the rest accurate, so it is the simplest action on the screen.

A feature that needs a gate, a sequence or a setting to work is redesigned until it does not.

## 3. The loop

```
  the school sends ──► School tab: items (exam, homework, notice) per student
                                  │
  the textbook's contents page ──► chapters ──► skills ──┐
  the first week's checks (or a placement) ──────────────┤
                                                         ▼
                              the record (per student: skills, checks, marks, attendance, homework)
                                                         │
                 ┌───────────────────────────────────────┼─────────────────────────────┐
                 ▼                                       ▼                             ▼
      Tonight: the plan                     on track / not on track            the parent's note
      groups, teach, practise,               with the reason and the            (≤3 a week, in their
      check, homework; material              next step                          language, tutor reads first)
      made when the app opens
                 │
                 ▼
      the close: came, 3 checks tapped, homework given  ──► back into the record
```

The tutor's actions are four: forward or photograph, tap the close, read and send the note, decide what to do about a
student who is not on track. Each is optional; the record uses what it is given.

## 4. Information architecture

Sign-in and onboarding as V1. Five tabs.

| Tab | Holds |
|---|---|
| **Tonight** | V1's Today, extended: greeting and stat tiles (students, fees due, batches today); the day's batches, each with its plan: level groups, one line per student (teach, practise, check, homework) with the material ready, the tutor's brief for the chapter, Start class → the close, and after the close what goes to parents; upcoming events and tasks as in Today. On a note day, the notes waiting to be read and sent. On a day with no batch, the next one |
| **Students** | V1's Students, extended: the list, sorted by tracking status; add a student (name, class level LKG to 10, school, parent, language); the student's page: this week, the record (skills by subject, check trend, marks, attendance, homework), the school's items, messages sent, consent, fees (V1), notes, edit, archive; the "+" menu (add student, scan register, create batch) |
| **School** | Items from schools, per student or per class of a school: exams with dates and portions, homework, notices, holidays; the exam calendar; "Ask parents to forward" (the message that starts the flow); exam preparation for each coming test |
| **Fees** | As V1: month, ledger, remind, mark paid, receipt, generate month, UPI |
| **More** | Organise: Schedule (batches: V1's classes, their days and times; events), Attendance (mark any day, class or all students, and history: V1's screens), Reports. Make: Make something (each kind, for ad hoc use), Check a paper, Scan register (the Students tab's screen, D36). App: Settings, Account, Help |

"Batch" is V1's class (`classes`): a named group with meeting days and times. The Attendance tab's two screens move
under More unchanged; the close is the quick path for tonight's batch. V1's deep links keep working; new ones:
`tutorcentral://tonight` and `.../school/<item>`.

Create and edit are sheets with Cancel and Save, as V1. An AI-made artefact is shown before it is used or sent; the
tutor can regenerate it with one tap and a reason ("easier", "shorter", "more sums"), edit the text, or replace it with
their own.

## 5. The record

Per student, the record is what the app knows. Material is made from it.

| Part | Comes from | Holds |
|---|---|---|
| Identity | Add student | Name, class level (LKG, UKG, 1 to 10), school, board from class 8, parent name and phone, message language (English, Hinglish, Hindi, Kannada), consent |
| Chapters and skills | A photo of a textbook's contents page, taken once per school, class and subject and shared by the students of that class; the board's list for classes 8 to 10; the stage ladder for LKG and UKG, and for reading, writing and numbers in classes 1 to 3 | Per subject, the ordered chapters and the skills under each, copied per student with a state: not started, taught, practising, secure, revisit |
| Starting point | The first week's checks; or, if the tutor wants it sooner, a short placement (a check kind: a few questions per subject, tapped right or wrong) | LKG to 3: reading, writing and number levels on an ASER/NIPUN-style ladder; 4 to 10: the starting chapter per subject |
| Checks | The close | Three questions per session, right or wrong, each tied to a skill; one from tonight, two spaced from earlier weeks |
| Attendance | The close, or V1's Attendance screens | Present, absent |
| Homework | The plan and the next close | Given (which sheet), done, partial, not done |
| School items | The School tab | Exams (subject, date, portions), homework the school set, notices, holidays |
| Marks | A photo of a report or a marked test | Subject, test, date, score out of max |
| Messages | The note flow, V1's reminders | What was sent, when, in which language, opened |

**Tracking status.** Computed in Domain by rules with reasons, and stored on the student when the record changes (a
close, a mark, a school item). Inputs: the gap between secure skills and the class's expected skills, in bands; check
accuracy over three weeks; absences over four weeks; consecutive homework not done; a school mark below the student's
usual. Three states: on track, watch, not on track, plus "not known yet" for a student without checks. Each state
carries the next step the plan will take unless the tutor changes it: re-teach with a worked example, step back to the
prerequisite skill, add the skill to the spaced queue, tell the parent.

**LKG and UKG** are a stage with a ladder and no chapters. **Classes 1 to 3** have the ladder for reading, writing and
numbers and the school's books for the other subjects. Material for the stage is tracing, reading and counting sheets;
homework is light; the note tells the parent what the student can now do.

## 6. The plan

Made for each batch of the day when the app opens, or in the background when iOS grants a refresh, from the record, with
the material. Opening before the batch shows "Planning tonight" for the seconds it takes; a plan already made opens at
once. A local notification at a time the tutor can change reminds them to open the app ("Batch at 5. Open for tonight's
plan").

1. **Who.** The students of the batch by the schedule; a student absent twice in a row gets a catch-up line.
2. **Groups.** Two or three level groups across classes, by subject band, from the record (teaching at the right level
   rather than by age; research section 4). The tutor can move a student, or drop the groups.
3. **Subject.** Per student per session: the subject with the nearest school item; otherwise the subject least recently
   taught. A weekly pattern set on the batch ("Monday maths, Tuesday English") overrides both.
4. **Per student, four lines.** Teach: the next skill, the one to re-teach, or the exam's next portion. Practise: the
   group's set at that level. Check: three questions. Homework: the group's sheet, sized to the class (light for 1 to 5).
5. **Material, made before the batch.** One set, one sheet and the checks per group (per student only for a revisit or
   an exam); the worked example for the skill; a figure where the skill has one; the tutor's brief when the chapter is
   one the tutor has asked about or is above class 7 (five minutes of reading, three common misconceptions, the worked
   example to use). A session has an artefact budget (a Domain rule), so a batch of twelve costs about what three groups
   cost.
6. **Exam mode.** When a school item places an exam within the preparation window (14 days unless the tutor sets
   another), that subject's lines become revision: the portions split across the days, a daily set, a mock in the
   school's pattern two days before, marking from a photo, and a gap report that adjusts the last days. Class 10 has
   two target dates.
7. **The close.** Start class → the groups and lines as a checklist → per student: came (default present), the three
   checks tapped right or wrong, homework given (default yes) → Done. About thirty seconds for twelve students; each
   tap is optional, and Done with attendance alone is a close. The close writes V1's attendance session for the day and
   batch; a plan without a close leaves no attendance record. The result goes into the record and changes the next plan.

Rules in Domain, tested first: grouping, subject choice, the spaced queue (which skills to check, Leitner intervals),
homework size by class, the artefact budget, exam day-splitting, tracking status, note cadence. Claude chooses the
wording; the rules choose the content.

## 7. The artefacts

A kind is a schema, a prompt, a model and a renderer. Adding a kind is additive. V1's four kinds (paper, homework,
worksheet, progress note) and its two photo tools (scan register, check a paper) stay as they are.

| Kind | For | Made from | Forms |
|---|---|---|---|
| Sheet (practice, homework) | A group, or a student | Skills, level, class | PDF (print, share), board view (large type on the phone for the class to copy), the key |
| Worked example | A skill | The skill | On the phone, one step at a time |
| Figure | A skill with a figure | A typed figure spec (number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain, …) drawn natively | On the phone, printable with the sheet |
| Brief | The tutor | A chapter | Five minutes of reading |
| Check | A student, a session | The spaced queue | Three questions and answers, in the close |
| Placement | A student | The class's skills | A few questions per subject, in the close's form |
| Mock | A student, an exam | Portions, the school's pattern or the board's blueprint | PDF, the key, marking from a photo (V1's check a paper) |
| Note | A parent | The week's record | Text in the parent's language, in WhatsApp, with English beside it for the tutor |
| Can-now-do | A parent of a LKG to 3 student | The ladder | Text, in WhatsApp |
| Test tomorrow | A parent | A school item | Text: subject, portions, what to revise tonight |
| Gap report | The tutor, after a mock | The marking | On the phone |
| Own | Any of the above | The tutor's photo or words | Takes the same place in the plan and the record |

Figures are not free-form images: the API returns a spec the app validates (a fraction bar's parts sum to the whole)
and draws with tokens; a kind without a template has no figure. Vetted simulations (PhET, CC BY 4.0, attribution shown)
open in the browser from the skill when one fits; nothing from GeoGebra, Desmos, Khan Academy or CK-12 is embedded
(research section 3).

Each AI-made artefact records its generation (V1's `ai_generations`), the model, the tokens and the student or group it
was made for. PDFs are rendered on the phone when shared or printed and are not uploaded.

## 8. Parents

- **Consent, scoped.** Material made from a skill at a level (a sheet, a set, a check, a worked example, a figure, a
  brief) contains nothing about a student and needs no consent. A student's own data (name, school, marks, answers,
  progress, a photo of their work) goes to the AI only after the parent has agreed. The app gives the tutor a WhatsApp
  message that says what the app does with the data and asks for a yes; the tutor records the reply (date, phone).
  Until then the note, can-now-do and marking are not made for that student; nothing else is affected. This is recorded
  consent kept for the tutor, who is responsible for the student's data under the DPDP Act. The website's trust page
  describes it.
- **The note.** Weekly, on the note day (default Sunday evening, after the week's last batch; the tutor changes it where
  it appears), per student, in the parent's language with English beside it: what was taught, what the student got
  right, what to practise, what is coming. Facts about the student, not general advice. The tutor reads it, edits it if
  needed, and sends it by the WhatsApp link, one tap per parent. The app suggests at most three messages a week per
  parent and holds further suggestions; messages the tutor sends by hand (a reminder, a receipt) are not held.
- **Test tomorrow** when a school item says so; **can-now-do** for LKG to 3; **homework** shared as a PDF when the tutor
  chooses; V1's reminder, receipt and absence messages stay.
- **"Ask parents to forward."** One message, sent once: "Please forward me whatever the school sends about tests,
  portions, homework and holidays." A forward the tutor shares into the app becomes a school item.
- Each message carries the tutor's name and ends with "Made with Tutor Central".

## 9. iOS, API and data

### iOS

As V1 (section 4 of `docs/spec.md`): Swift 6, SwiftUI, Observation, XcodeGen, one package, tokens only. New or changed
targets:

| Target | Holds |
|---|---|
| `DesignSystem` | Figure views from their specs; the sheet document view and its PDF export (SwiftUI's `ImageRenderer`, no UIKit) |
| `Domain` | Class levels and stages; the ladder; skills and states; the rules: grouping, subject choice, spaced queue, homework size, artefact budget, exam split, tracking status, note cadence; figure specs and their validation |
| `Data` | Repositories for the new tables; the API client for the new routes; the background refresh task; the share receiver's hand-off |
| `Features/Tonight` | V1's Today, extended: the plan, the brief, the close, the note day |
| `Features/Students` | V1's Students, extended: the record, placement, textbook capture, consent; Scan register stays here (D36) |
| `Features/School` | Items, the calendar, exam preparation |
| `Features/Make` | Make something, Check a paper (from AITools) |
| `Features/Fees`, `Attendance`, `Schedule`, `Settings`, `Onboarding` | As V1; Attendance and Schedule reached from More |
| `AppShell` | Five tabs, the share extension's hand-off, the reminder notification |
| `ShareExtension` (a second app target, its own App ID) | "Share to Tutor Central" from WhatsApp and Photos: passes the text or image to the app through the app group; the app parses it in the School tab |

Features do not import each other (rule 4); the record is read through a Domain protocol as `Register` is (D33).
Reads and writes as V1 (cache first, optimistic writes, the offline queue of D39 extended to the close).

### API (Hono on Vercel)

Each route under `/ai/` verifies the JWT and runs as the user (D5), as V1's do. No job, no cron, no service role.

| Route | Does |
|---|---|
| `POST /ai/plan` | A batch and a date; reads the record as the user; returns the plan (groups, lines, which artefacts to make). The app then requests each artefact |
| `POST /ai/make` | One artefact of a kind for a group, student, session or exam; structured output per kind; the chapter's context cached for an hour |
| `POST /ai/parse-school` | Text or a photo of a school message; returns items (kind, class, subject, date, portions) for the tutor to confirm |
| `POST /ai/parse-textbook` | A photo of a contents page; returns the chapters and the skills under each |
| `POST /ai/check-paper` | As V1, extended: the key may be a mock's; returns per-question marks and notes |
| `POST /ai/generate`, `POST /ai/scan-register` | As V1 |
| `GET /health` | As V1 |

Models by kind: Haiku for sheets up to class 5, checks, placements, notes, can-now-do and test tomorrow; Sonnet for
sheets from class 6, worked examples, figures, briefs, mocks and both parsers; Opus for marking. One model per kind, no
fallbacks (D35). The per-centre monthly allowance in Postgres (V1's `start_ai_generation`, extended) gates each call.

### Data model

Centre tables as V1 (`id`, `centre_id`, `created_at`, `updated_at`, RLS through `is_member`, composite references).
Nothing from V1 is renamed or removed (D26: expand now, contract later).

| Table | Columns of note |
|---|---|
| `students` (extended) | `class_level` (lkg, ukg, 1 to 10), `school_id?`, `board?` (cbse, icse, karnataka, other; from class 8), `message_language`, `consent_at?`, `consent_phone?`, `track_status`, `track_reasons` (jsonb), `tracked_at?` |
| `schools` | `name`, `board?` |
| `textbooks` | `school_id`, `class_level`, `subject`, `title`, `publisher?`, `edition?`, `photo_path?` (Storage, under the centre) |
| `chapters` | Per student: `student_id`, `subject`, `position`, `name`, and the source, `textbook_id?` or `syllabus_id?` |
| `skills` | `chapter_id`, `student_id`, `position`, `name`, `state`, `state_at`, `last_checked_at?` |
| `plans` | `class_id?`, `date`, `made_at`, `groups` (jsonb), `subjects` (jsonb), `session_id?` (set by the close) |
| `plan_items` | `plan_id`, `student_id?` (null for a group or tutor line), `group_no?`, `kind` (teach, practise, check, homework, brief, catch_up), `skill_id?`, `artefact_id?`, `done_at?` |
| `artefacts` | `kind`, `source` (made, own), `student_id?`, `plan_id?`, `school_item_id?`, `title`, `content` (jsonb, per kind), `photo_path?` (own), `generation_id?`, `regenerated_from?` |
| `attendance_sessions` (V1, extended) | `plan_id?`, `closed_at?` |
| `checks` | `session_id`, `student_id`, `skill_id`, `question` (jsonb), `correct` |
| `homework` | `student_id`, `session_id`, `artefact_id`, `given_at`, `status` (given, done, partial, not_done) |
| `school_items` | `school_id?`, `student_id?`, `class_level?`, `kind` (exam, homework, notice, holiday), `subject?`, `date`, `portions?`, `source_text?`, `photo_path?`, `confirmed_at?` |
| `marks` | `student_id`, `subject`, `test`, `date`, `score`, `max`, `photo_path?` |
| `message_log` (extended) | `kind` adds note, can_do, test_tomorrow, homework, consent; `language`, `body` |
| `syllabi` (reference, not a centre table) | `board`, `class_level`, `subject`, `edition`, `chapters` and `skills` (jsonb), `blueprint?` (jsonb, class 10); readable by signed-in users, written by migrations only |

Functions: `close_session(...)` (the attendance session, the checks, the homework and the student's stored tracking
status in one write), `start_ai_generation` extended with the allowance. The API does not store photos sent to it
(V1's rule); a confirmed item's or textbook's photo lives in Storage under the centre and is deleted with the student or
the centre.

### Privacy

As V1 (section 7), plus: recorded consent per student before the student's own data goes to the AI; export and delete
per student; no analytics on students; the trust page on tutorcentral.in and the App Privacy answers updated in the
phase that first sends a student's data to testers.

### Engineering

As V1 (section 8): boards before code (rule 1), screenshots in each PR (rule 2), tokens (rule 3), tests first in
Domain, Data, API and RLS, `bun check`, migrations through `deploy.yml`. New: a figure kind needs its validator and a
preview in the Kit; a syllabus seed is a migration with a test that counts its chapters; the share extension is covered
by the simulator runbook; the artefact budget is tested against the price sheet.

## 10. Money

A flat, visible price through In-App Purchase with UPI Autopay: a free monthly allowance, then about ₹499 a month or
₹3,999 a year. The price is set from the cost measured in Phases 12 and 13 (one set, one sheet and the checks per
group, cached chapter context, the budget per session), to hold a margin above 70%. This comes last, after the loop is
proven with tutors; until then the product is free and unlimited as in V1 (D4). Supersedes D4 when the phase starts.

## 11. Phases

V1 ended at Phase 9. Each V2 phase has a scope file and, when it starts, a plan file; each ends with something a tutor
can use on its own (section 2). Phase 9's findings continue to be fixed alongside.

| # | Phase | Ends with |
|---|---|---|
| 10 | V2 design and foundation | Boards for the V2 screens and states approved and mirrored; migrations for the tables above with RLS tests; the syllabus seeds for classes 8 to 10, CBSE and Karnataka state; the API routes as skeletons; a build that shows nothing new |
| 11 | The record and the close | Add student V2 (class level, school, language), consent and the trust page; the textbook contents photo to chapters and skills (once per school, class and subject); the ladder and the placement; the close (came, three checks, homework) usable without a plan; the student's page with the record; tracking status with its rules and tests; the five tabs with Attendance and Schedule under More |
| 12 | The plan | Groups, subject choice, lines; the sheets in three forms, worked examples, figures, the brief; the budget; the plan on open and in background refresh; the reminder; the offline close; the cost measured |
| 13 | School | The share extension and photo to items; the calendar; "Ask parents to forward"; test tomorrow; exam preparation: the split, daily sets, the mock, marking from a photo, the gap report |
| 14 | Parents | The note in the parent's language with English beside it, can-now-do, the cadence, the sent log; marks from a photo; "not on track" with the next step |
| 15 | Make and polish | Make something and Check a paper in Make; Reports extended (progress per student, per term); the open polish rows the owner picks; a second round of tutor testing on TestFlight |
| 16 | Release | The subscription and the allowance; the website's V2 text; the App Store listing and screenshots; submission |

## 12. Decisions this spec needs

Proposed; numbered on approval in `plan/README.md`.

| Proposed | Decision |
|---|---|
| D56 | V2's scope: the plan as the default way in. A solo tutor of LKG to class 10 students in English-medium schools; V1 is the base and nothing in it is dropped or renamed; Android later by the owner's plan. |
| D57 | The design method, section 2: the app decides by default; the tutor can ignore or change any decision where it appears; nothing has to be configured. Each feature works on its own; the plan is a suggestion; the record grows from use; hand-made material is treated the same as generated; the close is the one routine made easiest. The only gate is consent, and only before a student's own data goes to the AI. |
| D58 | Below class 8 the record is keyed by the school and the textbook's contents page (one photo per school, class and subject, copied per student); from class 8 by the board's chapter list per subject and edition, kept by hand (CBSE and Karnataka state; ICSE by the contents page, since it prescribes no books). Syllabus facts only; no textbook text is stored, cached or embedded. |
| D59 | Figures are typed specs the app validates and draws with tokens; no free-form generated images, no SVG from the model, no web views for figures. Vetted simulations open in the browser with attribution. |
| D60 | The plan is made by the app, on open or in a background refresh, as the user. No server job, no cron, no service-role key (D37 stands). The notification is a local reminder to open the app, not a statement that the plan is ready. |
| D61 | Parent messages stay WhatsApp deep links (D3). The app suggests at most three a week per parent and holds the rest; messages the tutor sends by hand are not held. A note shows the parent's language with English beside it. Server-sent WhatsApp is evaluated at a tutor count the owner sets. |
| D62 | Recorded consent per student (the parent's phone and date) before the student's own data goes to the AI; material made from a skill at a level needs none; export and delete per student. |
| D63 | Claude is routed by kind (Haiku, Sonnet, Opus as section 9), one model per kind; material is made per level group, with a budget per session and a monthly allowance per centre. |
| D64 | Money comes last (Phase 16): In-App Purchase, a free allowance, about ₹499 a month or ₹3,999 a year, the price set from the measured cost. Until that phase D4 stands. |
| D65 | V2's phases are 10 to 16; the spec is `docs/spec-v2.md`; V1's spec stays as built. The Attendance tab's screens move under More unchanged; the close is the quick path. |
