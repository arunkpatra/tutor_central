# Tutor Central V2: product and technical specification

Drafted 2026-10-10 from the V2 brainstorm and `docs/v2/research.md`, revised the same day after a review. Not yet
approved. V1 (`docs/spec.md`, Phases 0 to 9) is the spine this builds on; nothing V1 does is dropped (rule 10). The
decisions this spec needs are listed at the end; on approval they take numbers in `plan/README.md`.

## 1. What it is

V1 was the tutor's bookkeeping: who is enrolled, who came, who paid. V2 is the tutor's teaching: the app plans every
class, makes the material, closes the class in thirty seconds of taps, keeps each child's record, tells the parents, and
says which child is not on track and what to do about it.

The promise, in one line: *open at five and the class is ready; tap what happened and the parent is told.* The tutor
never has to type. They forward what the school sends, photograph a timetable, a contents page, a marked paper or a
report card, and tap what happened. The app does the planning, the preparation, the tracking and the writing. The plan
is the default; every tool in it is also there on its own, where it is needed (section 2).

### Who it is for

One person who teaches, on their own, 10 to 15 children of mixed classes in the same evening slot, LKG to class 7 for the
most part, sometimes to class 10, all subjects for the younger ones, in English-medium schools. India: rupees, UPI,
WhatsApp. iPhone, often one-handed, often on mobile data. Not a centre and not a team; those come after this product has
many tutors. Android follows later by the owner's plan.

### What it is not, in V2

- Not a menu first. Every artefact is made for a child, a group, a session or an exam from the record, and each can be
  made on its own from a child's page, a batch or More; the plan is where most will be made, not the only place.
- No student app, no video, no live classes, no marketplace, no leads. Parents receive WhatsApp messages and PDFs.
- No textbook text. Syllabus facts only (chapter names, skills, outcomes, blueprints); nothing copied from a book
  (research section 2).
- No server-sent WhatsApp yet: deep links as in V1 (D3). The cadence and the drafting make the taps few.
- No claims of marks multiplied. The product claims measurable progress the parent can see, and a tenth of the tutor's
  preparation time.
- No Kannada or Hindi teaching: the lesson, the sheet and the brief are in English. Parent messages are in the parent's
  language.
- No server job and no service-role key: the app makes the plan (section 9). No server push notifications.

## 2. How it is designed: suggest, never require

The tutors who will use this have their own ways of working, and they are not digital-savvy (D41). Two things pull
against each other: the least possible headspace, and no fixed process. The methodology that holds both: *the tutor's
freedom is in ignoring, never in configuring.* The app decides by default and lets the tutor do otherwise on the spot.

1. **Every feature stands alone.** Each works from its first tap with what is known at that moment. A sheet needs a
   class and a topic; a note needs a name and what happened; attendance needs no plan. No set-up gate stands before a
   feature ("add the textbook first"). The one gate is consent, and it stands only before the child's own data goes to
   the AI (section 8), never before material made from a skill at a level.
2. **The plan is a suggestion.** Tonight shows what the app would do. The tutor follows it, follows a part, changes a
   line, or ignores it and runs the class their way. What they did is what the record learns; the plan adapts to the
   tutor, never the reverse. A skipped line is not a debt and nothing nags.
3. **The record grows from use, not from entry.** Whatever the tutor does enriches it. What they do not do lowers
   precision, never blocks. Where knowing more would help, the app says so once, in place ("Add the maths book's
   contents and tonight's sheet follows its chapters"), never as a checklist.
4. **Defaults, not questions.** Every choice has a default from the child's class and the tutor's own past; every
   default can be changed where it appears, and the change is remembered. The app learns the tutor's style: the note
   day, the language, how long a sheet, how many groups, which children sit together, which subject on which day.
5. **Depth is optional and pays at once.** Attendance and fees alone are V1 and complete. Add a contents page and the
   sheets follow the book. Forward what the school sends and exam prep appears. Tap the three checks and on-track
   appears. Each layer pays the day it is used; none is required for another.
6. **Hand-made is first-class.** The tutor's own sheet (a photo), their own words in a note, their own grouping stand in
   the plan and the record exactly as the app's would.
7. **One ritual is worth making easy: the close.** Not required (attendance alone is a close), but the thirty seconds
   that make everything else better, so it is the easiest thing on the screen.

Every screen, rule and phase in this spec is read against these seven; a feature that needs a gate, a sequence or a
setting to work is redesigned until it does not.

## 3. The loop

```
  the school sends ──► School tab: items (exam, homework, notice) per child
                                  │
  the textbook's contents page ──► chapters ──► skills ──┐
  the first week's checks (or a placement) ──────────────┤
                                                         ▼
                              the record (per child: skills, checks, marks, attendance, homework)
                                                         │
                 ┌───────────────────────────────────────┼─────────────────────────────┐
                 ▼                                       ▼                             ▼
      Tonight: the plan                     on track / not on track            the parent's note
      groups, teach, practise,               with the reason and the            (≤3 a week, in their
      check, homework; material              next move                          language, read first)
      made when the app opens
                 │
                 ▼
      the close: came, 3 checks tapped, homework given  ──► back into the record
```

Every arrow is automatic except the four the tutor owns: forward or photograph, tap the close, read and send the note,
decide what to do about a child who is not on track. Each of the four is optional; the record takes what it is given.

## 4. Information architecture

Sign-in and onboarding as V1. Five tabs.

| Tab | Holds |
|---|---|
| **Tonight** | V1's Today grown: the greeting and stat tiles (children, fees due, batches today), then the batches of the day, each with its plan: the level groups, one line per child (teach, practise, check, homework) with the material ready; the tutor's brief for the chapter; Start class → the close; after the close, what goes to parents. Then upcoming events and tasks, as Today has them. On a note day, the notes waiting to be read and sent. On a day with no batch, the next one |
| **Children** | V1's Students grown: the list, sorted by on track status; add a child (name, class level LKG to 10, school, parent, language); the child's page: this week, the record (skills by subject, checks trend, marks, attendance, homework), the school's items, messages sent, consent, fees (V1), notes, edit, archive; the "+" menu (add child, scan register, create batch) |
| **School** | What the schools sent, as items per child or per class of a school: exams with dates and portions, homework, notices, holidays; the exam calendar; "Ask parents to forward" (the message that starts the flow); exam prep for each coming test |
| **Fees** | As V1: month, ledger, remind, mark paid, receipt, generate month, UPI |
| **More** | Organise: Schedule (batches: V1's classes, their days and times; events), Attendance (mark any day, class or all students, and history: V1's screens), Reports. Make: Make something (every kind, for ad hoc use), Check a paper, Scan register (Children's screen, D36). App: Settings, Account, Help |

"Batch" is V1's class (`classes`): a named group with meeting days and times. The Attendance tab's two screens move
under More unchanged; the close is the fast path for tonight's batch. V1's deep links keep working; new ones:
`tutorcentral://tonight`, `.../child/<id>`, `.../school/<item>`.

Every create and edit is a sheet with Cancel and Save, as V1. Every AI-made artefact is shown before it is used or sent;
the tutor can regenerate it with one tap and a reason ("easier", "shorter", "more sums"), edit the text, or replace it
with their own.

## 5. The record

Per child, the record is what the app knows, and everything it makes is made from it.

| Part | Comes from | Holds |
|---|---|---|
| Identity | Add child | Name, class level (LKG, UKG, 1 to 10), school, board from class 8, parent name and phone, message language (English, Hinglish, Hindi, Kannada), consent |
| Chapters and skills | A photo of a textbook's contents page, taken once per school, class and subject and shared by every child of that class; the board's list for classes 8 to 10; the stage ladder for LKG to UKG, and for reading, writing and numbers in classes 1 to 3 | Per subject, the ordered chapters and the skills under each, copied per child with a state: not started, taught, practising, secure, revisit |
| Where the child is | The first week's checks; or, if the tutor wants it sooner, a three-minute placement (a check kind: a few questions per subject, tapped right or wrong) | LKG to 3: reading, writing and number levels on an ASER/NIPUN-style ladder; 4 to 10: the starting chapter per subject |
| Checks | The close | Three questions per session, right or wrong, each tied to a skill; one from tonight, two spaced from earlier weeks |
| Attendance | The close, or V1's Attendance screens | Present, absent |
| Homework | The plan and the next close | Given (which sheet), done, partial, not done |
| School items | The School tab | Exams (subject, date, portions), homework the school set, notices, holidays |
| Marks | A photo of a report or a marked test | Subject, test, date, score out of max |
| Messages | The note flow, V1's reminders | What was sent, when, in which language, opened |

**On track.** Computed in Domain, by rules with reasons, and stored on the child whenever the record changes (a close,
a mark, a school item): the gap between skills secure and the class's expected skills, in bands; the check accuracy
trend over three weeks; absences in four weeks; homework not done in a row; a school mark below the child's usual. Three
states: on track, watch, not on track. Each carries the next move the plan will take unless the tutor changes it:
re-teach with a worked example, step back to the prerequisite skill, put the skill in the spaced queue, tell the parent.
A child with no checks yet is "not known yet", never "not on track".

**LKG and UKG** are a stage with a ladder and no chapters. **Classes 1 to 3** have the ladder for reading, writing and
numbers and the school's books for the rest. The material for the stage is tracing, reading and counting sheets,
homework is light, and the note tells the parent what the child can now do.

## 6. The plan

Made for each batch of the day when the app opens (or in the background when iOS grants a refresh), from the record,
with the material. Opening before the batch shows "Planning tonight" for the seconds it takes; a plan already made is
instant. A reminder at a time the tutor can change ("Batch at 5. Open for tonight's plan") is a local notification.

1. **Who.** The children of the batch, by the schedule; those absent twice in a row get a catch-up line.
2. **Groups.** Two or three level groups across classes, by subject band, from the record (teaching at the right level,
   not by age; research section 4). The tutor can move a child, or drop the groups and teach as they always have.
3. **Which subject.** Per child per session, the subject with the nearest school item; otherwise the one least recently
   taught; a tutor who sets a weekly pattern on the batch ("Monday maths, Tuesday English") overrides both.
4. **Per child, four lines.** *Teach*: the next skill, or the one to re-teach, or the exam's next portion. *Practise*:
   the group's set at that level. *Check*: three questions. *Homework*: the group's sheet sized to the class (light
   for 1 to 5).
5. **The material, made before the batch:** one set, one sheet and the checks per group (per child only for a revisit
   or an exam), the worked example for the skill, a figure where the skill has one, and the tutor's brief when the
   chapter is one the tutor has asked about or is above class 7: five minutes to read, the three misconceptions to
   expect, the worked example to use. A session has a budget of artefacts (a Domain rule) so a batch of twelve costs
   what three groups cost.
6. **Exam mode.** When a school item puts an exam within the prep window (14 days unless the tutor sets another), that
   subject's lines become revision: the portions split across the days, a daily set, a mock in the school's pattern two
   days before, marking from a photo, and the gap report that reshapes the last days. Class 10 carries two target dates.
7. **The close.** Start class → the groups and lines as a checklist → for each child: came (default present), the three
   checks tapped right or wrong, homework given (default yes) → Done. Thirty seconds for twelve children; every tap
   is optional and Done with attendance alone is a close. The close writes V1's attendance session for the day and
   batch; a plan without a close leaves no attendance behind. Everything flows into the record; the next plan is
   different because of it.

Rules in Domain, tested first: grouping, subject choice, the spaced queue (which skills to check, Leitner intervals),
homework size by class, the artefact budget, exam day-splitting, track status, note cadence. Choosing words is Claude's;
choosing what is not.

## 7. The artefacts

A kind is a schema, a prompt, a model and a renderer. Kinds grow over time; adding one is additive. V1's four kinds
(paper, homework, worksheet, progress note) and its two photo tools (scan register, check a paper) stay as they are.

| Kind | For | Made from | Forms |
|---|---|---|---|
| Sheet (practice, homework) | A group, or a child | Skills, level, class | PDF (print, share), board view (big type on the phone for the class to copy), the key |
| Worked example | A skill | The skill | On the phone, the steps one at a time |
| Figure | A skill with a figure | A typed figure spec (number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain, …) drawn natively | On the phone, printable with the sheet |
| Brief | The tutor | A chapter | Five minutes of reading |
| Check | A child, a session | The spaced queue | Three questions and answers, in the close |
| Placement | A child | The class's skills | A few questions per subject, in the close's form |
| Mock | A child, an exam | Portions, the school's pattern or the board's blueprint | PDF, the key, marking from a photo (V1's check a paper) |
| Note | A parent | The week's record | Text in the parent's language, in WhatsApp, with English beside it for the tutor |
| Can-now-do | A parent of a LKG to 3 child | The ladder | Text, in WhatsApp |
| Test tomorrow | A parent | A school item | Text: subject, portions, what to revise tonight |
| Gap report | The tutor, after a mock | The marking | On the phone |
| Own | Anything above | The tutor's photo or words | Stands in the plan and the record as the app's would |

Figures are never free-form pictures: the API returns a spec the app validates (a fraction bar's parts sum to the
whole) and draws with tokens; a kind without a template has no figure. Vetted simulations (PhET, CC BY 4.0, attribution
shown) open in the browser from the skill when one fits; nothing from GeoGebra, Desmos, Khan Academy or CK-12 is embedded
(research section 3).

Every AI-made artefact records its generation (V1's `ai_generations`), the model, the tokens and the child or group it
was made for. PDFs are rendered on the phone when shared or printed, never uploaded.

## 8. Parents

- **Consent, scoped.** Material made from a skill at a level (a sheet, a set, a check, a worked example, a figure, a
  brief) carries nothing about a child and needs no consent. The child's own data (name, school, marks, answers,
  progress, a photo of their work) goes to the AI only after the parent has agreed: the app gives the tutor a WhatsApp
  message naming what the app does with it and asking for a yes; the tutor records the reply (date, phone). Until then
  the note, can-now-do and marking are not made for that child, and nothing else is held back. This is recorded
  consent kept for the tutor, who is the one responsible for the child's data under the DPDP Act; it is shown on the
  website's trust page.
- **The note.** Weekly, on the note day (Sunday evening by default, after the week's last batch; the tutor changes it
  where it appears), per child, in the parent's language with English beside it: what was taught, what the child got
  right, what to practise, what is coming. Child-specific facts, never a generic tip. The tutor reads it, edits if they
  want, and sends it by the WhatsApp link, one tap per parent. The app suggests at most three messages a week per parent
  and holds its other suggestions; what the tutor sends by hand (a reminder, a receipt) is never held.
- **Test tomorrow** when a school item says so; **can-now-do** for the little ones; **homework** shared as a PDF when the
  tutor chooses; V1's reminder, receipt and absence messages stay.
- **"Ask parents to forward."** One message, sent once: "Please forward me whatever the school sends about tests,
  portions, homework and holidays." Every forward the tutor shares into the app becomes a school item.
- Every message carries the tutor's name and ends with "Made with Tutor Central": the growth loop.

## 9. iOS, API and data

### iOS

As V1 (section 4 of `docs/spec.md`): Swift 6, SwiftUI, Observation, XcodeGen, one package, tokens only. New or changed
targets:

| Target | Holds |
|---|---|
| `DesignSystem` | Figure views from their specs; the sheet document view and its PDF export (SwiftUI's `ImageRenderer`, no UIKit) |
| `Domain` | Class levels and stages; the ladder; skills and states; the rules: grouping, subject choice, spaced queue, homework size, artefact budget, exam split, track status, note cadence; figure specs and their validation |
| `Data` | Repositories for the new tables; the API client for the new routes; the background refresh task; the share receiver's hand-off |
| `Features/Tonight` | V1's Today grown: the plan, the brief, the close, the note day |
| `Features/Children` | V1's Students grown: the record, placement, textbook capture, consent; Scan register stays here (D36) |
| `Features/School` | Items, the calendar, exam prep |
| `Features/Make` | Make something, Check a paper (from AITools) |
| `Features/Fees`, `Attendance`, `Schedule`, `Settings`, `Onboarding` | As V1; Attendance and Schedule reached from More |
| `AppShell` | Five tabs, the share extension's hand-off, the reminder notification |
| `ShareExtension` (a second app target, its own App ID) | "Share to Tutor Central" from WhatsApp and Photos: hands the text or image to the app through the app group; the app parses it in the School tab |

Features never import each other (rule 4); the record is read through a Domain protocol as `Register` is (D33).
Reads and writes as V1 (cache first, optimistic writes, the offline queue of D39 extended to the close).

### API (Hono on Vercel)

Every route under `/ai/` verifies the JWT and runs as the user (D5), as V1's do. No job, no cron, no service role.

| Route | Does |
|---|---|
| `POST /ai/plan` | A batch and a date; reads the record as the user, returns the plan (groups, lines, which artefacts to make). The app then asks for each artefact |
| `POST /ai/make` | One artefact of a kind for a group, child, session or exam; structured output per kind; the chapter's context cached for an hour |
| `POST /ai/parse-school` | Text or a photo of what the school sent; returns items (kind, class, subject, date, portions) for the tutor to confirm |
| `POST /ai/parse-textbook` | A photo of a contents page; returns the chapters and, per chapter, the skills |
| `POST /ai/check-paper` | As V1, grown: the key may be a mock's; returns per-question marks and notes |
| `POST /ai/generate`, `POST /ai/scan-register` | As V1 |
| `GET /health` | As V1 |

Models by kind: Haiku for sheets up to class 5, checks, placements, notes, can-now-do and test tomorrow; Sonnet for
sheets from class 6, worked examples, figures, briefs, mocks and both parsers; Opus for marking. One model per kind,
no fallbacks (D35). The per-centre monthly allowance in Postgres (V1's `start_ai_generation` grown) gates every call.

### Data model

Centre tables as V1 (`id`, `centre_id`, `created_at`, `updated_at`, RLS through `is_member`, composite references).
Nothing V1 has is renamed or removed (D26: expand now, contract later).

| Table | Columns of note |
|---|---|
| `students` (grown) | `class_level` (lkg, ukg, 1 to 10), `school_id?`, `board?` (cbse, icse, karnataka, other; from class 8), `message_language`, `consent_at?`, `consent_phone?`, `track_status`, `track_reasons` (jsonb), `tracked_at?` |
| `schools` | `name`, `board?` |
| `textbooks` | `school_id`, `class_level`, `subject`, `title`, `publisher?`, `edition?`, `photo_path?` (Storage, under the centre) |
| `chapters` | Per child: `student_id`, `subject`, `position`, `name`, and where it came from, `textbook_id?` or `syllabus_id?` |
| `skills` | `chapter_id`, `student_id`, `position`, `name`, `state`, `state_at`, `last_checked_at?` |
| `plans` | `class_id?`, `date`, `made_at`, `groups` (jsonb), `subjects` (jsonb), `session_id?` (set by the close) |
| `plan_items` | `plan_id`, `student_id?` (null for a group or tutor line), `group_no?`, `kind` (teach, practise, check, homework, brief, catch_up), `skill_id?`, `artefact_id?`, `done_at?` |
| `artefacts` | `kind`, `source` (made, own), `student_id?`, `plan_id?`, `school_item_id?`, `title`, `content` (jsonb, per kind), `photo_path?` (own), `generation_id?`, `regenerated_from?` |
| `attendance_sessions` (V1, grown) | `plan_id?`, `closed_at?` |
| `checks` | `session_id`, `student_id`, `skill_id`, `question` (jsonb), `correct` |
| `homework` | `student_id`, `session_id`, `artefact_id`, `given_at`, `status` (given, done, partial, not_done) |
| `school_items` | `school_id?`, `student_id?`, `class_level?`, `kind` (exam, homework, notice, holiday), `subject?`, `date`, `portions?`, `source_text?`, `photo_path?`, `confirmed_at?` |
| `marks` | `student_id`, `subject`, `test`, `date`, `score`, `max`, `photo_path?` |
| `message_log` (grown) | `kind` adds note, can_do, test_tomorrow, homework, consent; `language`, `body` |
| `syllabi` (reference, not a centre table) | `board`, `class_level`, `subject`, `edition`, `chapters` and `skills` (jsonb), `blueprint?` (jsonb, class 10); read by every signed-in user, written by migrations only |

Functions: `close_session(...)` (the attendance session, the checks, the homework and the child's stored track status
in one write), `start_ai_generation` grown with the allowance. Photos sent to the API are not stored by it (V1's rule);
a confirmed item's or textbook's photo lives in Storage under the centre and goes with the child or the centre.

### Privacy

As V1 (section 7), plus: recorded consent per child before the child's own data goes to the AI; export and delete per
child; no analytics on children; the trust page on tutorcentral.in and the App Privacy answers updated in the phase
that first sends a child's data to testers.

### Engineering

As V1 (section 8): boards before code (rule 1), screenshots in every PR (rule 2), tokens (rule 3), tests first in
Domain, Data, API and RLS, `bun check`, migrations through `deploy.yml`. New: a figure kind needs its validator and a
preview in the Kit; a syllabus seed is a migration with a test that counts its chapters; the share extension is in the
simulator runbook; the artefact budget is tested against the price sheet.

## 10. Money

A flat, visible price through In-App Purchase with UPI Autopay: a free allowance a month, then about ₹499 a month or
₹3,999 a year. The exact price is set from the cost measured in Phases 12 and 13 (one set, one sheet and the checks per
group, cached chapter context, the budget per session), to hold a margin above 70%. Comes last, after the loop is
proven with tutors; until then everything is free and unlimited as V1 (D4). Supersedes D4 when the phase starts.

## 11. Phases

V1 ended at Phase 9. Each V2 phase has its scope file and, when it starts, its plan file; each ends with something a
tutor can use on its own (section 2). Phase 9's findings keep flowing into fixes alongside.

| # | Phase | Ends with |
|---|---|---|
| 10 | V2 design and foundation | Boards for every V2 screen and state approved and mirrored; migrations for the tables above with RLS tests; the syllabus seeds for classes 8 to 10, CBSE and Karnataka state; the API routes as skeletons; a build that shows nothing new |
| 11 | The record and the close | Add child V2 (class level, school, language), consent and the trust page; the textbook contents photo to chapters and skills (once per school, class and subject); the ladder and the placement; the close (came, three checks, homework) usable without a plan; the child's page with the record; on track with its rules and tests; Children and Tonight's close; the five tabs with Attendance and Schedule under More |
| 12 | The plan | Groups, subject choice, lines; the sheets in three forms, worked examples, figures, the brief; the budget; the plan on open and in background refresh; the reminder; the offline close; the cost measured |
| 13 | School | The share extension and photo to items; the calendar; "Ask parents to forward"; test tomorrow; exam prep: the split, daily sets, the mock, marking from a photo, the gap report |
| 14 | Parents | The note in the parent's language with English beside, can-now-do, the cadence, the sent log; marks from a photo; "not on track" with the next move |
| 15 | Make and polish | Make something and Check a paper in Make; Reports grown (progress per child, per term); the open polish rows the owner picks; a second round of tutor testing on TestFlight |
| 16 | Release | The subscription and the allowance; the website's V2 words; the App Store listing and screenshots; submission |

## 12. Decisions this spec needs

Proposed; numbered on approval in `plan/README.md`.

| Proposed | Decision |
|---|---|
| D56 | V2's shape: the plan, not the tools. A solo tutor of LKG to class 10 children in English-medium schools; V1 is the spine and nothing of it is dropped or renamed; Android later by the owner's plan. |
| D57 | The design methodology, section 2: suggest, never require. Every feature stands alone; the plan is a suggestion; the record grows from use; defaults, not questions; depth optional; hand-made first-class; the close the one ritual made easy. The only gate is consent, and only before a child's own data goes to the AI. |
| D58 | Below class 8 the record is keyed by the school and the textbook's contents page (one photo per school, class and subject, copied per child); from class 8 by the board's chapter list per subject and edition, kept by hand (CBSE and Karnataka state; ICSE by the contents page, since it prescribes no books). Syllabus facts only; no textbook text is stored, cached or embedded. |
| D59 | Figures are typed specs the app validates and draws with tokens; no free-form generated pictures, no SVG from the model, no web views for figures. Vetted simulations open in the browser with attribution. |
| D60 | The plan is made by the app, on open or in a background refresh, as the user. No server job, no cron, no service-role key anywhere (D37 stands). The "plan" notification is a local reminder to open the app, not a claim that the plan is ready. |
| D61 | Parent messages stay WhatsApp deep links (D3). The app suggests at most three a week per parent and holds the rest; what the tutor sends by hand is never held. Every note shows the parent's language with English beside it. Server-sent WhatsApp is evaluated at a tutor count the owner sets. |
| D62 | Recorded consent per child (the parent's phone and date) before the child's own data goes to the AI; material made from a skill at a level needs none; export and delete per child. |
| D63 | Claude is routed by kind (Haiku, Sonnet, Opus as section 9), one model per kind; material is made per level group, with a budget per session and a monthly allowance per centre. |
| D64 | Money comes last (Phase 16): In-App Purchase, a free allowance, about ₹499 a month or ₹3,999 a year, the exact price from the measured cost. Until that phase D4 stands. |
| D65 | V2's phases are 10 to 16; the spec is `docs/spec-v2.md`; V1's spec stays as built. The Attendance tab's screens move under More unchanged; the close is the fast path. |
