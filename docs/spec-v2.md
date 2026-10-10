# Tutor Central V2: product and technical specification

Drafted 2026-10-10 from the V2 brainstorm and `docs/v2/research.md`. Not yet approved. V1 (`docs/spec.md`, Phases 0 to 9) is
the spine this builds on; nothing V1 does is dropped (rule 10). The decisions this spec needs are listed at the end; on
approval they take numbers in `plan/README.md`.

## 1. What it is

V1 was the tutor's bookkeeping: who is enrolled, who came, who paid. V2 is the tutor's teaching: the app plans every
class, makes the material, closes the class in thirty seconds of taps, keeps each child's record, tells the parents, and
says which child is not on track and what to do about it.

The promise: *every class planned, every parent told.* The tutor types nothing. They forward what the school sends,
photograph a timetable, a contents page, a marked paper or a report card, and tap what happened. The app does the
planning, the preparation, the tracking and the writing. Tools are never browsed: the plan pulls them.

### Who it is for

One person who teaches, on their own, 10 to 15 children of mixed classes in the same evening slot, LKG to class 7 for the
most part, sometimes to class 10, all subjects for the younger ones, in English-medium schools. India: rupees, UPI,
WhatsApp. iPhone, often one-handed, often on mobile data. Not a centre and not a team; those come after this product has
many tutors. Android follows later by the owner's plan.

### What it is not, in V2

- Not a menu of AI tools. Every artefact is made for a child, a session or an exam from the record; an ad hoc "Make
  something" exists in More for the rare case and is not the way in.
- No student app, no video, no live classes, no marketplace, no leads. Parents receive WhatsApp messages and PDFs.
- No textbook text. Syllabus facts only (chapter names, skills, outcomes, blueprints); nothing copied from a book
  (research section 2).
- No server-sent WhatsApp yet: deep links as in V1 (D3). The cadence and the drafting make the taps few.
- No claims of marks multiplied. The product claims measurable progress the parent can see, and a tenth of the tutor's
  preparation time.
- No Kannada or Hindi teaching: the lesson, the sheet and the brief are in English. Parent messages are in the parent's
  language.
- No server push notifications: a local notification tells the tutor the plan is ready.

## 2. The loop

```
  the school sends ──► School tab: items (exam, homework, notice) per child
                                  │
  the child's textbook ──► chapters ──► skills ──┐
  placement (LKG to 3: the ladder) ──────────────┤
                                                 ▼
                              the record (per child: skills, checks, marks, attendance, homework)
                                                 │
                 ┌───────────────────────────────┼─────────────────────────────┐
                 ▼                               ▼                             ▼
      Tonight: the plan              on track / not on track            the parent's note
      groups, teach, practise,        with the reason and the            (≤3 a week, in their
      check, homework; material       next move                          language, read first)
      made before the batch
                 │
                 ▼
      the close: came, 3 checks tapped, homework given  ──► back into the record
```

Every arrow is automatic except the four the tutor owns: forward or photograph, tap the close, read and send the note,
decide what to do about a child who is not on track.

## 3. Information architecture

Sign-in and onboarding as V1, plus one question: "Which classes do you teach?" Five tabs.

| Tab | Holds |
|---|---|
| **Tonight** | The batches of the day, each with its plan: the level groups, one line per child (teach, practise, check, homework) with the material ready; the tutor's brief for the chapter; Start class → the close; after the close, what goes to parents. On a note day, the notes waiting to be read and sent. On a day with no batch, the next one and what is being prepared |
| **Children** | The list, sorted by on track status; add a child (name, class level LKG to 10, school, parent, language, consent); the child's page: this week, the record (skills by subject, checks trend, marks, attendance, homework), the school's items, messages sent, fees (V1), notes, edit, archive |
| **School** | What the schools sent, as items per child or per class of a school: exams with dates and portions, homework, notices, holidays; the exam calendar; "Ask parents to forward" (the message that starts the flow); exam prep for each coming test |
| **Fees** | As V1: month, ledger, remind, mark paid, receipt, generate month, UPI |
| **More** | Organise: Schedule (batches), Reports, Attendance history. Make: Make something (the kinds, for ad hoc use), Scan register (Children's screen, D36). App: Settings, Account, Help |

V1's Attendance tab folds into Tonight (the close) and the child's page (history). Deep links as V1, plus
`tutorcentral://tonight`, `.../child/<id>`, `.../school/<item>`.

Every create and edit is a sheet with Cancel and Save, as V1. Every AI-made artefact is shown before it is used or sent;
the tutor can regenerate it with one tap and a reason ("easier", "shorter", "more sums"), or edit the text.

## 4. The record

Per child, the record is what the app knows, and everything it makes is made from it.

| Part | Comes from | Holds |
|---|---|---|
| Identity | Add child | Name, class level (LKG, UKG, 1 to 10), school, board from class 8, subjects, parent name and phone, message language (English, Hinglish, Hindi, Kannada), consent |
| Chapters and skills | A photo of each textbook's contents page (classes 1 to 7); the board's list (8 to 10); the stage ladder (LKG to 3) | Per subject, the ordered chapters and the skills under each, with a state: not started, taught, practising, secure, revisit |
| Placement | A ten-minute placement on joining, repeated each term | LKG to 3: reading, writing and number levels on an ASER/NIPUN-style ladder; 4 to 10: a short check per subject that sets the starting chapter |
| Checks | The close | Three questions per session, right or wrong, each tied to a skill; one from tonight, two spaced from earlier weeks |
| Attendance | The close (V1's marks) | Present, absent |
| Homework | The plan and the next close | Given (which sheet), done, partial, not done |
| School items | The School tab | Exams (subject, date, portions), homework the school set, notices, holidays |
| Marks | A photo of a report or a marked test | Subject, test, date, score out of max |
| Messages | The note flow, V1's reminders | What was sent, when, in which language, opened |

**On track.** Computed by rules in Domain and in a Postgres function, with the reasons: the gap between skills secure
and the class's expected skills in bands; the check accuracy trend over three weeks; absences in four weeks; homework
not done in a row; a school mark below the child's usual. Three states: on track, watch, not on track. Each carries the
next move the plan will take unless the tutor changes it: re-teach with a worked example, step back to the prerequisite
skill, put the skill in the spaced queue, tell the parent.

**LKG to class 3** is a stage, not a class with chapters: the ladder is the record, the material is tracing, reading and
counting sheets, homework is light, and the note tells the parent what the child can now do.

## 5. The plan

Made for each session of a batch, the morning of the day, by the job (section 8) or when the app opens if the job has
not run.

1. **Who.** The children of the batch, by the schedule; those absent twice in a row get a catch-up item.
2. **Groups.** Two or three level groups across classes, by subject band, from the record (teaching at the right level,
   not by age; research section 4). The tutor can move a child.
3. **Per child, four lines.** *Teach*: the next skill, or the one to re-teach, or the exam's next portion. *Practise*:
   a short set at the child's level. *Check*: three questions. *Homework*: a sheet sized to the class (light for 1 to 5).
4. **The material, made before the batch:** the sheets (practice, homework), the check questions, the worked example for
   the skill, a figure where the skill has one, and the tutor's brief when the chapter is one the tutor has asked about or
   is above class 7: five minutes to read, the three misconceptions to expect, the worked example to use.
5. **Exam mode.** When a school item puts an exam within the prep window (14 days unless the tutor sets another), that subject's lines become revision: the
   portions split across the days, a daily set, a mock in the school's pattern two days before, marking from a photo, and
   the gap report that reshapes the last days. Class 10 carries two target dates.
6. **The close.** Start class → the groups and lines as a checklist → for each child: came (default present), the three
   checks tapped right or wrong, homework given (default yes) → Done. Thirty seconds for twelve children. Everything flows
   into the record; the next plan is different because of it.

Rules in Domain, tested first: grouping, the spaced queue (which skills to check, Leitner intervals), homework size by
class, exam day-splitting, track status, note cadence. Choosing words is Claude's; choosing what is not.

## 6. The artefacts

A kind is a schema, a prompt, a model and a renderer. Kinds grow over time; adding one is additive.

| Kind | For | Made from | Forms |
|---|---|---|---|
| Sheet (practice, homework) | A child or a group | Skills, level, class | PDF (print, share), board view (big type on the phone for the class to copy), the key |
| Worked example | A skill | The skill | On the phone, the steps one at a time |
| Figure | A skill with a figure | A typed figure spec (number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain, …) drawn natively | On the phone, printable with the sheet |
| Brief | The tutor | A chapter | Five minutes of reading |
| Check | A child, a session | The spaced queue | Three questions and answers, in the close |
| Mock | A child, an exam | Portions, the school's pattern or the board's blueprint | PDF, the key, marking from a photo |
| Note | A parent | The week's record | Text in the parent's language, in WhatsApp |
| Can-now-do | A parent of a LKG to 3 child | The ladder | Text, in WhatsApp |
| Test tomorrow | A parent | A school item | Text: subject, portions, what to revise tonight |
| Gap report | The tutor, after a mock | The marking | On the phone |

Figures are never free-form pictures: the API returns a spec the app validates (a fraction bar's parts sum to the
whole) and draws with tokens; a kind without a template has no figure. Vetted simulations (PhET, CC BY 4.0, attribution
shown) open in the browser from the skill when one fits; nothing from GeoGebra, Desmos, Khan Academy or CK-12 is embedded
(research section 3).

Every artefact records its generation (V1's `ai_generations`), the model, the tokens and the child it was made for.

## 7. Parents

- **Consent first.** Before any of a child's data goes to Claude, the parent agrees: the app gives the tutor a WhatsApp
  message naming what the app does with the child's name, class and progress and asking for a yes; the tutor records
  the reply (date, phone). Without it the child has a record but no AI-made material. This is ahead of DPDP's children's
  duties (May 2027) and is shown on the website's trust page.
- **The note.** Weekly, on the day the tutor chooses (weekends help), per child, in the parent's language: what was
  taught, what the child got right, what to practise, what is coming. Child-specific facts, never a generic tip. The
  tutor reads it, edits if they want, and sends it by the WhatsApp link, one tap per parent. At most three messages a
  week per parent of any kind; the app holds the rest.
- **Test tomorrow** when a school item says so; **can-now-do** for the little ones; **homework** shared as a PDF when the
  tutor chooses; V1's reminder, receipt and absence messages stay.
- **"Ask parents to forward."** One message, sent once: "Please forward me whatever the school sends about tests,
  portions, homework and holidays." Every forward the tutor shares into the app becomes a school item.
- Every message carries the tutor's name and ends with "Made with Tutor Central": the growth loop.

## 8. iOS, API and data

### iOS

As V1 (section 4 of `docs/spec.md`): Swift 6, SwiftUI, Observation, XcodeGen, one package, tokens only. New or changed
targets:

| Target | Holds |
|---|---|
| `Domain` | Class levels and stages; the ladder; skills and states; the rules: grouping, spaced queue, homework size, exam split, track status, note cadence; figure specs and their validation |
| `Data` | Repositories for the new tables; the API client for the new routes; PDF rendering (UIKit's PDF renderer behind a wrapper, the DesignSystem's only other UIKit); the share-into-app receiver |
| `Features/Tonight` | The plan, the brief, the close, the note day |
| `Features/Children` | V1's Students grown: the record, placement, textbook capture, consent |
| `Features/School` | Items, the calendar, exam prep |
| `Features/Make` | Make something |
| `Features/Fees`, `Settings`, `Onboarding` | As V1, Onboarding plus the classes question |
| `AppShell` | Five tabs, the share extension's hand-off, the plan-ready local notification |

Features never import each other (rule 4); the record is read through a Domain protocol as `Register` is (D33).
Reads and writes as V1 (cache first, optimistic writes, the offline queue of D39 extended to the close).

### API (Hono on Vercel)

| Route | Does |
|---|---|
| `POST /school/parse` | Text or a photo of what the school sent; returns items (kind, class, subject, date, portions) for the tutor to confirm |
| `POST /textbook/parse` | A photo of a contents page; returns the chapters and, per chapter, the skills |
| `POST /plan/make` | A session; reads the record as the user, returns the plan and starts its artefacts |
| `POST /make` | One artefact of a kind for a child, group, session or exam; structured output per kind |
| `POST /mark` | A photo of answers and the key; per-question marks and notes (V1's check-paper) |
| `POST /ai/scan-register` | As V1 |
| `POST /jobs/plan` | The daily job: for every session today whose plan is not made, make it. Called by Vercel's cron with a secret; runs with the service role, the one route that does |
| `GET /health` | As V1 |

Every user route verifies the JWT and runs as the user (D5). The job route is the exception and is written as one:
cron secret, no user, service role, its reason in the file. Models by kind: Haiku for sheets up to class 5, checks,
notes and can-now-do; Sonnet for sheets from class 6, worked examples, figures, briefs, mocks, school and textbook
parsing; Opus for marking. One model per kind, no fallbacks (D35). A per-centre monthly allowance in Postgres (V1's
`start_ai_generation` grown) gates every call; the plan job batches a child's sheet, checks and homework into one call.

### Data model

Centre tables as V1 (`id`, `centre_id`, `created_at`, `updated_at`, RLS through `is_member`, composite references).

| Table | Columns of note |
|---|---|
| `students` (grown) | `class_level` (lkg, ukg, 1 to 10), `school_id?`, `board?` (cbse, icse, karnataka, other; from class 8), `message_language`, `consent_at?`, `consent_phone?`, `placed_at?` (the last placement; a term later it is due) |
| `schools` | `name`, `board?` |
| `textbooks` | `student_id`, `subject`, `title`, `publisher?`, `edition?` |
| `chapters` | Always per child: `student_id`, `subject`, `position`, `name`, and where it came from, `textbook_id?` or `syllabus_id?` (copied from the syllabus for classes 8 to 10, so states stay the child's) |
| `skills` | `chapter_id`, `student_id`, `position`, `name`, `state`, `state_at`, `last_checked_at?` |
| `placements` | `student_id`, `domain` (reading, writing, numbers, subject), `level`, `measured_at` |
| `sessions` (V1's `attendance_sessions`, grown) | `plan_status` (none, making, ready, failed), `closed_at?` |
| `plans` | `session_id`, `made_at`, `made_by` (job, app), `groups` (jsonb) |
| `plan_items` | `plan_id`, `student_id`, `kind` (teach, practise, check, homework, brief, catch_up), `skill_id?`, `artefact_id?`, `done_at?` |
| `artefacts` | `kind`, `student_id?`, `session_id?`, `school_item_id?`, `title`, `content` (jsonb, per kind), `pdf_path?`, `generation_id`, `regenerated_from?` |
| `checks` | `session_id`, `student_id`, `skill_id`, `question` (jsonb), `correct` |
| `homework` | `student_id`, `session_id`, `artefact_id`, `given_at`, `status` (given, done, partial, not_done) |
| `school_items` | `school_id?`, `student_id?`, `class_level?`, `kind` (exam, homework, notice, holiday), `subject?`, `date`, `portions?`, `source` (text or a storage path), `confirmed_at?` |
| `marks` | `student_id`, `subject`, `test`, `date`, `score`, `max`, `source?` |
| `message_log` (grown) | `kind` adds note, can_do, test_tomorrow, homework, consent; `language`, `body` |
| `syllabi` (reference, not a centre table) | `board`, `class_level`, `subject`, `edition`, `chapters` and `skills` (jsonb); read by every signed-in user, written by migrations only |

Functions: `track_status(student_id)` (the rules, mirrored in Domain and tested on both sides), `close_session(...)`
(attendance, checks, homework in one write), `start_ai_generation` grown with the allowance. The job's service-role
writes go through the same functions. Photos sent to the API are not stored (V1's rule); a confirmed school item keeps
its photo in Storage under the centre, deletable with the child.

### Privacy

As V1 (section 7), plus: consent per child before any AI use of that child's data; export and delete per child; no
analytics on children; the trust page on tutorcentral.in; the job reads only sessions of the day; the service role key
lives only in Vercel and `api/.env.local`.

### Engineering

As V1 (section 8): boards before code (rule 1), screenshots in every PR (rule 2), tokens (rule 3), tests first in
Domain, Data, API and RLS, `bun check`, migrations through `deploy.yml`. New: a figure kind needs its validator and a
preview in the Kit; a syllabus seed is a migration with a test that counts its chapters; the job is tested against the
local stack with a fake clock; the share-into-app path is in the simulator runbook.

## 9. Money

A flat, visible price through In-App Purchase with UPI Autopay: a free allowance a month, then ₹499 a month or ₹3,999 a
year (research section 6: about ₹110 of AI a month per tutor on the routing above holds a 70% margin). Comes last,
after the loop is proven with tutors; until then everything is free and unlimited as V1 (D4). Supersedes D4 when the
phase starts.

## 10. Phases

V1 ended at Phase 9. Each V2 phase has its scope file and, when it starts, its plan file; each ends with something to
show. Phase 9's findings keep flowing into fixes alongside.

| # | Phase | Ends with |
|---|---|---|
| 10 | V2 design and foundation | Boards for every V2 screen and state approved and mirrored; migrations for the tables above with RLS tests; the syllabus seed for classes 8 to 10 (CBSE first); the API routes as skeletons; the job and its cron; a build that shows nothing new |
| 11 | The child's record | Add child V2 (class level, school, language, consent); the textbook contents photo to chapters and skills; the ladder and placement; the child's page with the record; track status with its rules and tests; Children tab |
| 12 | Tonight | The plan (groups, lines), the sheets in three forms, worked examples, figures, the brief; the close; the job making plans each morning; the local notification; the offline close |
| 13 | Parents | The note in the parent's language, can-now-do, the cadence, the sent log; marks from a photo; "not on track" with the next move; "Ask parents to forward" |
| 14 | School | Share-into-app and photo to items; the calendar; test tomorrow; exam prep: the split, daily sets, the mock, marking from a photo, the gap report |
| 15 | Make and polish | Make something; Reports grown (progress per child, per term); the open polish rows the owner picks; a second round of tutor testing on TestFlight |
| 16 | Release | The subscription and the allowance; the trust page and the website's V2 words; the App Store listing and screenshots; submission |

## 11. Decisions this spec needs

Proposed; numbered on approval in `plan/README.md`.

| Proposed | Decision |
|---|---|
| D56 | V2's shape: the plan, not the tools. A solo tutor of LKG to class 10 children in English-medium schools; V1 is the spine; Android later by the owner's plan. |
| D57 | Below class 8 the record is keyed by the school and the child's own textbook (a photo of its contents page); from class 8 by the board's chapter list per subject and edition, kept by hand. Syllabus facts only; no textbook text is stored, cached or embedded. |
| D58 | Figures are typed specs the app validates and draws with tokens; no free-form generated pictures, no SVG from the model, no web views for figures. Vetted simulations open in the browser with attribution. |
| D59 | The API gains one service-role route, `POST /jobs/plan`, called by Vercel's cron with a secret, to make the day's plans; every user route still runs as the user (D5). The service role key lives only in Vercel and `api/.env.local`. Narrows `api/CLAUDE.md`'s "never used here". |
| D60 | Parent messages stay WhatsApp deep links (D3), at most three a week per parent, each read by the tutor before sending. Server-sent WhatsApp is evaluated at a tutor count the owner sets. |
| D61 | Consent per child, recorded with the parent's phone and date, before any AI use of that child's data; export and delete per child. |
| D62 | Claude is routed by kind (Haiku, Sonnet, Opus as section 8), one model per kind, with a monthly allowance per centre; the plan job batches a child's artefacts into one call. |
| D63 | Money comes last (Phase 16): In-App Purchase, a free allowance, ₹499 a month or ₹3,999 a year. Until that phase D4 stands. |
| D64 | The plan-ready notification is local, scheduled by the app; no APNs in V2. |
| D65 | V2's phases are 10 to 16; the spec is `docs/spec-v2.md`; V1's spec stays as built. The Attendance tab folds into Tonight and the child's page. |
