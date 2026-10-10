# Phase 10 plan: V2 design and foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-10 (session 20, Fable 5.1) from `phase-10-v2-design-and-foundation.md` and `docs/spec-v2.md`. Ticked as
it goes. Part A (the boards) runs on Fable (D17) and ends with the owner's approval of each step; Part B (the
plumbing) runs on Opus 5.5 from a resume prompt once Part A's steps 10.1 and 10.2 are approved (the tables do not
depend on the boards, so Part B may start after 10.2 while 10.3 to 10.7 continue).

**Goal:** the V2 screens designed and approved; the tables, syllabus data, API route skeletons and iOS types in place,
with tests, so Phases 11 to 14 build screens without a migration each; a build that shows nothing new.

**Architecture:** boards by the Phase 7 generator pattern (Python parts, boards, render, contact sheets), checked
with headless Chrome, published to the canvas, mirrored to `docs/design/`. Three additive migrations (D26) for the
spec's tables, each with RLS tests; a fourth for the allowance; two generated from syllabus JSON. The API gains four
routes answering 501 after validation and one extended schema. Domain gains the V2 value types and the figure specs
with validators; Data gains the repositories Phase 11 needs, with fakes; the project gains the share extension target
and the background refresh registration.

**Tech stack:** as V1 (Swift 6, SwiftUI, Swift Testing; Supabase CLI, Postgres, Bun tests; Hono, zod 4,
`@anthropic-ai/sdk`; XcodeGen). No new dependency.

**Spec:** `docs/spec-v2.md` sections 4 to 9 and 11 (Phase 10); scope `plan/phase-10-v2-design-and-foundation.md`;
decisions D56 to D65; the board process `plan/phase-00-plan.md` and `docs/design/README.md`.

## Global constraints

- No board, no approval, no code for anything seen (rule 1). This phase puts nothing new on screen (D6).
- Every centre table: `id`, `centre_id`, `created_at`, `updated_at`, the `set_updated_at` trigger, `unique (centre_id,
  id)`, composite references, RLS through `is_member`, a row in `CENTRE_TABLES` of `supabase/tests/rls.test.ts` (rule
  6). A reference table (`syllabi`) has RLS and a select policy for `authenticated` only.
- Migrations are additive: nothing from V1 is renamed, dropped or narrowed (D26). Never edit a migration that has run
  on the hosted project. `types.ts` regenerated and committed after each migration.
- New functions: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute … to
  authenticated` (supabase/CLAUDE.md).
- No textbook text anywhere in the repo or the database: chapter names, section headings and blueprints only (D58).
- The API runs every `/ai/*` call as the user; no service role (D60). Inputs are zod schemas in `src/schemas.ts`;
  a route validates first and answers 400 with the issue list; a skeleton answers 501.
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4); tokens only
  (D10); Swift Testing in the existing test targets.
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull
  requests; documents directly to `main` (D12), never mixed with code.
- Plain voice in every document and comment; no technical words in anything a tutor reads (D41).

## Decisions this plan takes

Small decisions, written here so they are not re-decided. None needs a number.

- **Class levels** are text with a check constraint, not an enum, so Swift and TypeScript use the same strings:
  `lkg`, `ukg`, `1` to `10`. **Boards:** `cbse`, `icse`, `karnataka`, `other`. **Message languages:** `en`,
  `hinglish`, `hi`, `kn` (default `en`).
- **Enums added:** `skill_state` (`not_started`, `taught`, `practising`, `secure`, `revisit`); `plan_item_kind`
  (`teach`, `practise`, `check`, `homework`, `brief`, `catch_up`); `artefact_kind` (`sheet`, `worked_example`, `figure`,
  `brief`, `check`, `placement`, `mock`, `note`, `can_do`, `test_tomorrow`, `gap_report`); `artefact_source` (`made`,
  `own`); `homework_status` (`given`, `done`, `partial`, `not_done`); `school_item_kind` (`exam`, `homework`, `notice`,
  `holiday`). `message_kind` gains `note`, `can_do`, `test_tomorrow`, `homework`, `consent`. `ai_kind` gains `plan`,
  `sheet`, `worked_example`, `figure`, `brief`, `check`, `placement`, `mock`, `note`, `can_do`, `test_tomorrow`,
  `gap_report`, `parse_school`, `parse_textbook`.
- **The allowance:** V1's daily limits stay for V1's kinds. The V2 kinds share one monthly allowance per centre of
  600 generations (calendar month, Asia/Kolkata), with a hard cap of 900 started; Phase 12 measures and Phase 16 sets
  the paid allowance. The personal kinds (`note`, `can_do`, `test_tomorrow`, `gap_report`) need the student's
  `consent_at` (D62); the others need no consent.
- **Photos** go to one private Storage bucket `photos`, path `<centre id>/<kind>/<uuid>.jpg`, read and written by
  members of that centre only (a policy on `storage.objects` through `is_member` of the first path segment).
- **Syllabus data** lives once, as JSON: `supabase/syllabi/<board>/<class>/<subject>.json`; `bun syllabi` writes a
  migration from them (`tools/syllabi.ts`). The migration is committed; the JSON is the source a person edits.
- **Repositories in this phase:** only what Phase 11 reads and writes (schools, textbooks with chapters and skills,
  the close). Plans, artefacts, school items and marks get theirs in Phases 12 to 14 (YAGNI).
- **The share extension:** target `TutorCentralShare`, bundle id `in.tutorcentral.app.share`, app group
  `group.in.tutorcentral`, accepting one text or one image, writing it to the app group's `inbox/` and completing. The
  app reads `inbox/` on foreground from Phase 13; in this phase the folder is read and left alone.
- **Background refresh:** identifier `in.tutorcentral.app.refresh`, registered at launch, scheduled on background;
  its handler does nothing until Phase 12.
- **Canvas rows:** Phase 10's boards go in rows 14 to 20 (y 37200, 38600, 40000, 41400, 42800, 44200, 45600; a `title1`
  note 300 above each), one row per step; sources `docs/design/mockups/P10-<Screen>-<State>[-Light].dc.html`.
- **Migration names:** `20261015000009_v2_students_schools_textbooks.sql`, `20261016000010_v2_plans_close.sql`,
  `20261017000011_v2_school_items_marks_syllabi_photos.sql`, `20261018000012_v2_allowance.sql`,
  `20261019000013_syllabi_cbse.sql`, `20261020000014_syllabi_karnataka.sql`.

## Review focus

Five things a person will meet that no task's happy path exercises; each has its test in the task that owns the code.

1. **A V1 student after migration 0009:** `class_level` null, no school, no consent. They must still be listed, marked
   present and invoiced; `track_status` must read `not_known`. Pinned in Task 1 (the row inserted by V1's columns
   only reads back with the defaults).
2. **A contents page shared by a class:** two students of the same school and class must get chapters and skills from
   one `textbooks` row, and deleting one student must leave the other's chapters. Pinned in Task 1 (the composite
   references and `on delete`).
3. **`close_session` twice for the same batch and day** must replace, not duplicate, the checks and the homework, and
   must keep V1's `save_attendance` unique index. Pinned in Task 2.
4. **`syllabi` to an anonymous caller** must answer nothing, and a signed-in member must not be able to insert or change
   a row. Pinned in Task 3.
5. **A V2 kind at the allowance:** the 601st `sheet` in a month must answer `ai_limit_reached` with the limit in its
   detail, while a V1 `paper` the same day still follows the daily rule. Pinned in Task 4.

---

## Part A: the boards (steps 10.1 to 10.7, on Fable)

Each step: read `plan/phase-00-plan.md` and `docs/design/README.md`; copy the Phase 7 generator (`lib.py` parts,
`boards.py`, `render.py`, `sheets.py`, in the session's scratchpad) and add the step's boards; render each board with
headless Chrome at 393 × 852 (both appearances; light by token-block substitution); stitch contact sheets; look at
them against the spec's section and D41's words; send the sheets to the owner; on approval, `Artifact read` the canvas,
publish the row (`canvas.json` with the new `boards` entries and `order`, the `.dc.html` files), mirror into
`docs/design/mockups/` and `docs/design/directions/canvas.json`, add the list, the launch states and what the boards
settle to `docs/design/information-architecture.md` ("Phase 10 boards"), new parts to `components.md`, new values to
`design-tokens.md` (with their Swift tokens in the same later PR, D25), and commit as documents (D12). A board's
figures are illustrative (`docs/design/README.md`).

- [ ] **10.1 The shell** (row 14). The tab bar with Today, Students, School, Fees, More, dark and light; More's
      layout with Organise (Schedule, Attendance, Reports), Make (Make something, Check a paper, Scan register), App
      (Settings, Account, Help); the School tab empty ("Nothing from a school yet" and the "Ask parents to forward"
      button, a plain label, no icon).
- [ ] **10.2 Students** (row 15). Add student V2 (class level picker LKG to 10; school: pick or add; board row shown
      from class 8; parent name and phone; language), the consent message sheet (the text, Send on WhatsApp, "Parent
      agreed" with the date), the textbook capture (intro, camera, the parsed chapters for confirmation with edit and
      delete rows, saved), the ladder (LKG to 3: reading, writing, numbers with their levels), the placement in the
      close's form, the student's page with the record (this week; skills by subject with state marks; check trend;
      marks; attendance; homework; school items; messages; consent; fees; notes), the list sorted by tracking status
      with its marks (on track, watch, not on track, not known yet), the empty list.
- [ ] **10.3 Today** (row 16). The plan for a batch (groups with their level, one line per student: teach, practise,
      check, homework; the material's marks; the brief row), "Planning today's class", a plan with a student moved and
      a line skipped, Start class, the close (the checklist, per student: came, three checks right or wrong, homework
      given), Done, after the close (what goes to parents), the note day, a day with no batch, V1's Today sections
      around the plan (tiles, events, tasks).
- [ ] **10.4 Artefacts** (row 17). The sheet in three forms (PDF preview, board view, key), regenerate with a reason
      (easier, shorter, more sums), the worked example one step at a time, each figure template (number line, fraction
      bar, place value, unit circle, triangle, labelled cell, food chain), the brief, the check in the close, the
      placement, the mock, the gap report, Own (a photo in a plan line).
- [ ] **10.5 School** (row 18). The share sheet's hand-off, items for confirmation (exam, homework, notice, holiday,
      each with student or class of a school, subject, date, portions), the list by date, an item's page, edit and
      delete, "Ask parents to forward" (the text, Send), test tomorrow (the message), exam preparation (the countdown,
      the split, today's set, the mock two days before, marking, the gap report).
- [ ] **10.6 Parents** (row 19). The note (the parent's language with English beside, Edit, Send on WhatsApp), the
      note day's list (sent, waiting, held), can-now-do, the sent log on the student's page, a held suggestion, not on
      track with the next step on the student's page and on Today's line.
- [ ] **10.7 Make and the Kit** (row 20). Make something (the kinds as a list, a kind's form from a student, a group, a
      class level or a topic), Check a paper under Make, Reports extended (progress per student, per term), the Kit's
      new rows (tracking marks, skill state marks, the figure templates, the sheet's board view type).

Part A ends with every V2 screen and state of spec sections 4 to 8 on an approved board; `docs/design/README.md`'s
status table gains the seven steps.

---

## Part B: the plumbing (on Opus 5.5)

### File structure

```
supabase/
  migrations/20261015000009_v2_students_schools_textbooks.sql
  migrations/20261016000010_v2_plans_close.sql
  migrations/20261017000011_v2_school_items_marks_syllabi_photos.sql
  migrations/20261018000012_v2_allowance.sql
  migrations/20261019000013_syllabi_cbse.sql            # generated by bun syllabi
  migrations/20261020000014_syllabi_karnataka.sql       # generated by bun syllabi
  syllabi/cbse/8/mathematics.json … karnataka/10/english.json   # the source: chapters and skills
  tests/rls.test.ts                                      # CENTRE_TABLES grows; syllabi tests
  tests/v2.test.ts                                       # the review-focus tests 1 to 5
  tests/syllabi.test.ts                                  # counts per board, class, subject
  types.ts                                               # regenerated
tools/
  syllabi.ts, syllabi.test.ts                            # JSON → migration SQL
api/
  src/schemas.ts                                         # PlanInput, MakeInput, ParseSchoolInput, ParseTextbookInput; Scheme gains mock
  src/routes/ai.ts                                       # four routes answering 501 after validation
  src/db.ts                                              # AIKind grows
  test/schemas.test.ts, test/app.test.ts                 # the new schemas and routes
ios/
  project.yml                                            # TutorCentralShare target; app group; refresh identifier
  App/Info.plist                                         # BGTaskSchedulerPermittedIdentifiers
  App/TutorCentral.entitlements                          # the app group
  Share/ShareViewController.swift, Share/Info.plist, Share/TutorCentralShare.entitlements
  TutorCentralKit/Sources/Domain/ClassLevel.swift, Ladder.swift, Skill.swift, FigureSpec.swift, School.swift, Textbook.swift
  TutorCentralKit/Sources/Data/Schools/SchoolsRepository.swift, FakeSchoolsRepository.swift, SupabaseSchoolsRepository.swift
  TutorCentralKit/Sources/Data/Textbooks/TextbooksRepository.swift, FakeTextbooksRepository.swift, SupabaseTextbooksRepository.swift, TextbookRow.swift
  TutorCentralKit/Sources/Data/Refresh/BackgroundRefresh.swift
  TutorCentralKit/Sources/AppShell/SharedInbox.swift
  TutorCentralKit/Tests/DomainTests/ClassLevelTests.swift, FigureSpecTests.swift
  TutorCentralKit/Tests/DataTests/TextbookRowTests.swift
```

### Pull requests

| PR | Tasks | Title |
|---|---|---|
| 1 | 1, 2 | V2 tables: students, schools, textbooks, chapters, skills; plans, close |
| 2 | 3, 4 | V2 tables: school items, marks, syllabi, photos; the allowance |
| 3 | 5 | Syllabus data: CBSE and Karnataka state, classes 8 to 10 |
| 4 | 6 | API: the V2 route skeletons |
| 5 | 7, 8 | iOS: V2 Domain types and the Phase 11 repositories |
| 6 | 9 | iOS: the share extension target and background refresh |
| main | 10 | As built, state, resume (documents only, D12) |

Branch names: `phase-10/tables-a`, `phase-10/tables-b`, `phase-10/syllabi`, `phase-10/api`, `phase-10/domain-data`,
`phase-10/share-refresh`.

---

### Task 1: Migration 0009, students extended, schools, textbooks, chapters, skills

**Files:**
- Create: `supabase/migrations/20261015000009_v2_students_schools_textbooks.sql`, `supabase/tests/v2.test.ts`
- Modify: `supabase/tests/rls.test.ts` (`CENTRE_TABLES`), `supabase/types.ts` (regenerated)

**Interfaces:**
- Produces: tables `schools`, `textbooks`, `chapters`, `skills`; columns on `students`: `class_level`, `school_id`,
  `board`, `message_language`, `consent_at`, `consent_phone`, `track_status`, `track_reasons`, `tracked_at`; enum
  `skill_state`.

- [ ] **Step 1: Write the failing tests**

`supabase/tests/v2.test.ts`:

```ts
import { beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

let l: Local;
let a: SupabaseClient;
let centre: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  a = await userClient(l, `v2-a-${stamp}@example.com`);
  const { data, error } = await a.rpc("create_centre", { p_name: "Centre V2", p_whatsapp: "+919999999901" });
  if (error) throw error;
  centre = data as string;
});

test("a V1 student reads back with V2 defaults", async () => {
  const { data, error } = await a.from("students").insert({ centre_id: centre, name: "Old Student" })
    .select("class_level, school_id, board, message_language, consent_at, track_status, track_reasons").single();
  expect(error).toBeNull();
  expect(data).toEqual({ class_level: null, school_id: null, board: null, message_language: "en", consent_at: null, track_status: "not_known", track_reasons: [] });
});

test("class level, board and language are checked", async () => {
  expect((await a.from("students").insert({ centre_id: centre, name: "X", class_level: "11" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "X", board: "state" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "X", message_language: "ta" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "Y", class_level: "lkg", message_language: "kn" })).error).toBeNull();
});

test("one textbook per school, class and subject serves two students; deleting one keeps the other's chapters", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Vidya School" }).select("id").single()).data!;
  const book = (await a.from("textbooks").insert({ centre_id: centre, school_id: school.id, class_level: "5", subject: "Mathematics", title: "Maths 5" }).select("id").single()).data!;
  const dup = await a.from("textbooks").insert({ centre_id: centre, school_id: school.id, class_level: "5", subject: "Mathematics", title: "Again" });
  expect(dup.error).not.toBeNull();
  const s1 = (await a.from("students").insert({ centre_id: centre, name: "S1", class_level: "5", school_id: school.id }).select("id").single()).data!;
  const s2 = (await a.from("students").insert({ centre_id: centre, name: "S2", class_level: "5", school_id: school.id }).select("id").single()).data!;
  for (const s of [s1, s2]) {
    const ch = (await a.from("chapters").insert({ centre_id: centre, student_id: s.id, textbook_id: book.id, subject: "Mathematics", position: 1, name: "Fractions" }).select("id").single()).data!;
    expect((await a.from("skills").insert({ centre_id: centre, chapter_id: ch.id, student_id: s.id, position: 1, name: "Equivalent fractions" })).error).toBeNull();
  }
  expect((await a.from("students").delete().eq("id", s1.id)).error).toBeNull();
  expect((await a.from("chapters").select("id").eq("student_id", s2.id)).data?.length).toBe(1);
  expect((await a.from("skills").select("state").eq("student_id", s2.id)).data).toEqual([{ state: "not_started" }]);
  expect((await a.from("chapters").select("id").eq("student_id", s1.id)).data).toEqual([]);
});
```

In `supabase/tests/rls.test.ts`, add to `CENTRE_TABLES`, keeping the array sorted as the catalogue test expects:
`"schools"`, `"textbooks"`, `"chapters"`, `"skills"`. In the isolation test's row map (the object that gives each table
one insertable row), add rows:

```ts
schools: { name: "Isolation School" },
textbooks: { school_id: schoolId, class_level: "3", subject: "English", title: "English 3" },
chapters: { student_id: studentId, subject: "English", position: 1, name: "Chapter one" },
skills: { chapter_id: chapterId, student_id: studentId, position: 1, name: "A skill" },
```

where `schoolId`, `studentId` and `chapterId` are made in `beforeAll` as centre A's rows (insert a school, a student and
a chapter after `create_centre`, the way the test already makes a class for `students`).

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests/v2.test.ts`
Expected: FAIL, the columns and tables do not exist.

- [ ] **Step 3: Write the migration**

```sql
-- V2 (docs/spec-v2.md section 9): the student's class, school, board, language and consent; schools; textbooks
-- captured once per school, class and subject; chapters and skills copied per student. Additive (D26).

create type public.skill_state as enum ('not_started', 'taught', 'practising', 'secure', 'revisit');

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  board text check (board is null or board in ('cbse', 'icse', 'karnataka', 'other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id)
);
create trigger schools_updated before update on public.schools for each row execute function public.set_updated_at();

alter table public.students
  add column class_level text check (class_level is null or class_level in ('lkg', 'ukg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')),
  add column school_id uuid,
  add column board text check (board is null or board in ('cbse', 'icse', 'karnataka', 'other')),
  add column message_language text not null default 'en' check (message_language in ('en', 'hinglish', 'hi', 'kn')),
  add column consent_at timestamptz,
  add column consent_phone text check (consent_phone is null or consent_phone ~ '^\+[1-9][0-9]{7,14}$'),
  add column track_status text not null default 'not_known' check (track_status in ('not_known', 'on_track', 'watch', 'not_on_track')),
  add column track_reasons jsonb not null default '[]'::jsonb,
  add column tracked_at timestamptz,
  add foreign key (centre_id, school_id) references public.schools(centre_id, id) on delete set null (school_id);
create index students_school on public.students(centre_id, school_id);

create table public.textbooks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  school_id uuid not null,
  class_level text not null check (class_level in ('lkg', 'ukg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')),
  subject text not null check (char_length(subject) between 1 and 80),
  title text not null check (char_length(title) between 1 and 200),
  publisher text check (publisher is null or char_length(publisher) <= 120),
  edition text check (edition is null or char_length(edition) <= 40),
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, school_id, class_level, subject),
  foreign key (centre_id, school_id) references public.schools(centre_id, id) on delete cascade
);
create trigger textbooks_updated before update on public.textbooks for each row execute function public.set_updated_at();

create table public.chapters (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  subject text not null check (char_length(subject) between 1 and 80),
  position integer not null check (position >= 1),
  name text not null check (char_length(name) between 1 and 200),
  textbook_id uuid,
  syllabus_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, student_id, subject, position),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, textbook_id) references public.textbooks(centre_id, id) on delete set null (textbook_id)
);
create trigger chapters_updated before update on public.chapters for each row execute function public.set_updated_at();
create index chapters_student on public.chapters(centre_id, student_id);

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  chapter_id uuid not null,
  student_id uuid not null,
  position integer not null check (position >= 1),
  name text not null check (char_length(name) between 1 and 200),
  state public.skill_state not null default 'not_started',
  state_at timestamptz not null default now(),
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, chapter_id, position),
  foreign key (centre_id, chapter_id) references public.chapters(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger skills_updated before update on public.skills for each row execute function public.set_updated_at();
create index skills_student on public.skills(centre_id, student_id);

do $$
declare t text;
begin
  foreach t in array array['schools', 'textbooks', 'chapters', 'skills'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests`
Expected: PASS, including the catalogue test (every table has RLS and a policy) and the isolation test.

- [ ] **Step 5: Regenerate types and check**

Run: `cd supabase && supabase gen types typescript --local > types.ts && cd .. && bun check --only=db`
Expected: green.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261015000009_v2_students_schools_textbooks.sql supabase/tests supabase/types.ts
git commit -m "db: V2 students, schools, textbooks, chapters, skills (0009)"
```

### Task 2: Migration 0010, plans, plan items, artefacts, checks, homework, the close

**Files:**
- Create: `supabase/migrations/20261016000010_v2_plans_close.sql`
- Modify: `supabase/tests/v2.test.ts`, `supabase/tests/rls.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: tables `plans`, `plan_items`, `artefacts`, `checks`, `homework`; columns `attendance_sessions.plan_id`,
  `attendance_sessions.closed_at`; enums `plan_item_kind`, `artefact_kind`, `artefact_source`, `homework_status`;
  function `close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb, p_homework jsonb,
  p_track jsonb) returns uuid`.
  - `p_marks`: `{"<student id>": "present" | "absent"}` as `save_attendance` takes.
  - `p_checks`: `[{"student_id", "skill_id", "question": {...}, "correct": true}]`.
  - `p_homework`: `[{"student_id", "artefact_id", "status": "given"}]`.
  - `p_track`: `{"<student id>": {"status": "on_track", "reasons": [...]}}`; may be `{}`.

- [ ] **Step 1: Write the failing tests** (append to `supabase/tests/v2.test.ts`)

```ts
test("close_session writes the session, the checks, the homework and the tracking status, and a second close replaces them", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Evening batch", meeting_days: [1, 2, 3] }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "Closer", class_level: "4", class_id: cls.id }).select("id").single()).data!;
  const ch = (await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Mathematics", position: 1, name: "Fractions" }).select("id").single()).data!;
  const sk = (await a.from("skills").insert({ centre_id: centre, chapter_id: ch.id, student_id: st.id, position: 1, name: "Halves" }).select("id").single()).data!;
  const art = (await a.from("artefacts").insert({ centre_id: centre, kind: "sheet", source: "own", title: "My sheet" }).select("id").single()).data!;
  const close = (marks: object, correct: boolean) => a.rpc("close_session", {
    p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_marks: marks,
    p_checks: [{ student_id: st.id, skill_id: sk.id, question: { text: "Half of 8?" }, correct }],
    p_homework: [{ student_id: st.id, artefact_id: art.id, status: "given" }],
    p_track: { [st.id]: { status: "on_track", reasons: ["checks"] } },
  });
  const first = await close({ [st.id]: "present" }, true);
  expect(first.error).toBeNull();
  const second = await close({ [st.id]: "absent" }, false);
  expect(second.error).toBeNull();
  expect(second.data).toBe(first.data);
  expect((await a.from("checks").select("correct").eq("session_id", first.data as string)).data).toEqual([{ correct: false }]);
  expect((await a.from("homework").select("status").eq("session_id", first.data as string)).data).toEqual([{ status: "given" }]);
  expect((await a.from("attendance_marks").select("status").eq("session_id", first.data as string)).data).toEqual([{ status: "absent" }]);
  expect((await a.from("students").select("track_status, track_reasons").eq("id", st.id).single()).data).toEqual({ track_status: "on_track", track_reasons: ["checks"] });
  expect((await a.from("skills").select("last_checked_at").eq("id", sk.id).single()).data?.last_checked_at).not.toBeNull();
  expect((await a.from("attendance_sessions").select("closed_at").eq("id", first.data as string).single()).data?.closed_at).not.toBeNull();
});

test("close_session with attendance alone is a close", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Alone", meeting_days: [4] }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "Alone S", class_id: cls.id }).select("id").single()).data!;
  const r = await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-13", p_marks: { [st.id]: "present" }, p_checks: [], p_homework: [], p_track: {} });
  expect(r.error).toBeNull();
  expect((await a.from("checks").select("id").eq("session_id", r.data as string)).data).toEqual([]);
});
```

Add `"plans"`, `"plan_items"`, `"artefacts"`, `"checks"`, `"homework"` to `CENTRE_TABLES` and their rows to the
isolation map:

```ts
plans: { date: "2026-10-12", groups: [], subjects: {} },
plan_items: { plan_id: planId, kind: "brief" },
artefacts: { kind: "sheet", source: "own", title: "Own sheet" },
checks: { session_id: sessionId, student_id: studentId, skill_id: skillId, question: {}, correct: true },
homework: { student_id: studentId, session_id: sessionId, artefact_id: artefactId, status: "given" },
```

with `planId`, `sessionId` (from `save_attendance`), `skillId` and `artefactId` made in `beforeAll`.

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests/v2.test.ts`
Expected: FAIL, `close_session` and the tables do not exist.

- [ ] **Step 3: Write the migration**

```sql
-- V2 (docs/spec-v2.md sections 6 and 9): plans and their lines, artefacts, the checks and homework of a session, and
-- the close in one write. Additive (D26): attendance_sessions gains two columns; save_attendance stays.

create type public.plan_item_kind as enum ('teach', 'practise', 'check', 'homework', 'brief', 'catch_up');
create type public.artefact_kind as enum ('sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock',
  'note', 'can_do', 'test_tomorrow', 'gap_report');
create type public.artefact_source as enum ('made', 'own');
create type public.homework_status as enum ('given', 'done', 'partial', 'not_done');

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  class_id uuid,
  date date not null,
  made_at timestamptz not null default now(),
  groups jsonb not null default '[]'::jsonb,
  subjects jsonb not null default '{}'::jsonb,
  session_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, class_id) references public.classes(centre_id, id) on delete set null (class_id),
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete set null (session_id)
);
create trigger plans_updated before update on public.plans for each row execute function public.set_updated_at();
create unique index plans_one_per_day on public.plans(centre_id, class_id, date) nulls not distinct;

create table public.artefacts (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  kind public.artefact_kind not null,
  source public.artefact_source not null default 'made',
  student_id uuid,
  plan_id uuid,
  school_item_id uuid,
  title text not null check (char_length(title) between 1 and 200),
  content jsonb not null default '{}'::jsonb,
  photo_path text,
  generation_id uuid,
  regenerated_from uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete set null (plan_id),
  foreign key (centre_id, generation_id) references public.ai_generations(centre_id, id) on delete set null (generation_id),
  foreign key (centre_id, regenerated_from) references public.artefacts(centre_id, id) on delete set null (regenerated_from)
);
create trigger artefacts_updated before update on public.artefacts for each row execute function public.set_updated_at();
create index artefacts_student on public.artefacts(centre_id, student_id);
create index artefacts_plan on public.artefacts(centre_id, plan_id);

create table public.plan_items (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  plan_id uuid not null,
  student_id uuid,
  group_no integer check (group_no is null or group_no between 1 and 9),
  kind public.plan_item_kind not null,
  skill_id uuid,
  artefact_id uuid,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, skill_id) references public.skills(centre_id, id) on delete set null (skill_id),
  foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete set null (artefact_id)
);
create trigger plan_items_updated before update on public.plan_items for each row execute function public.set_updated_at();
create index plan_items_plan on public.plan_items(centre_id, plan_id);

alter table public.attendance_sessions
  add column plan_id uuid,
  add column closed_at timestamptz,
  add foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete set null (plan_id);

create table public.checks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  session_id uuid not null,
  student_id uuid not null,
  skill_id uuid not null,
  question jsonb not null default '{}'::jsonb,
  correct boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, skill_id) references public.skills(centre_id, id) on delete cascade
);
create trigger checks_updated before update on public.checks for each row execute function public.set_updated_at();
create index checks_student on public.checks(centre_id, student_id, created_at);

create table public.homework (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  session_id uuid not null,
  artefact_id uuid not null,
  given_at timestamptz not null default now(),
  status public.homework_status not null default 'given',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, session_id, student_id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete cascade,
  foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete cascade
);
create trigger homework_updated before update on public.homework for each row execute function public.set_updated_at();

do $$
declare t text;
begin
  foreach t in array array['plans', 'plan_items', 'artefacts', 'checks', 'homework'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- The close: attendance (through save_attendance, so V1's rule of one session per class and day holds), then the
-- session's checks and homework replaced, each checked skill's last_checked_at moved, the students' stored tracking
-- status written, closed_at set. One transaction; security invoker, so RLS decides.
create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_homework) <> 'array' or jsonb_typeof(p_track) <> 'object' then
    raise exception 'checks and homework must be arrays, track an object' using errcode = '22023';
  end if;
  sid := public.save_attendance(p_centre, p_class, p_date, p_marks);
  delete from public.checks c where c.centre_id = p_centre and c.session_id = sid;
  insert into public.checks (centre_id, session_id, student_id, skill_id, question, correct)
  select p_centre, sid, (c->>'student_id')::uuid, (c->>'skill_id')::uuid, coalesce(c->'question', '{}'::jsonb), (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  delete from public.homework h where h.centre_id = p_centre and h.session_id = sid;
  insert into public.homework (centre_id, student_id, session_id, artefact_id, status)
  select p_centre, (h->>'student_id')::uuid, sid, (h->>'artefact_id')::uuid, coalesce(h->>'status', 'given')::public.homework_status
  from jsonb_array_elements(p_homework) h;
  update public.students s
     set track_status = t.value->>'status', track_reasons = coalesce(t.value->'reasons', '[]'::jsonb), tracked_at = now()
    from jsonb_each(p_track) t
   where s.centre_id = p_centre and s.id = t.key::uuid;
  update public.attendance_sessions a set closed_at = now() where a.id = sid;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb) to authenticated;
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests`
Expected: PASS.

- [ ] **Step 5: Regenerate types, check, commit**

```bash
cd supabase && supabase gen types typescript --local > types.ts && cd .. && bun check --only=db
git add supabase && git commit -m "db: V2 plans, artefacts, checks, homework and close_session (0010)"
```

Open PR 1 from `phase-10/tables-a` (no screenshots: nothing seen changes).

### Task 3: Migration 0011, school items, marks, syllabi, message kinds, photos

**Files:**
- Create: `supabase/migrations/20261017000011_v2_school_items_marks_syllabi_photos.sql`
- Modify: `supabase/tests/v2.test.ts`, `supabase/tests/rls.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: tables `school_items`, `marks`, `syllabi`; `message_log.kind` values `note`, `can_do`, `test_tomorrow`,
  `homework`, `consent`; columns `message_log.language`, `message_log.body`; `artefacts.school_item_id` reference;
  bucket `photos`; enum `school_item_kind`.

- [ ] **Step 1: Write the failing tests** (append to `supabase/tests/v2.test.ts`)

```ts
import { anonClient } from "./client";

test("syllabi: a member reads, cannot write; anonymous reads nothing", async () => {
  const sql = new (await import("bun")).SQL(l.db);
  await sql`insert into public.syllabi (board, class_level, subject, edition, chapters) values ('cbse', '9', 'Test subject', '2026-27', '[{"position":1,"name":"One","skills":["a"]}]') on conflict do nothing`;
  await sql.close();
  const mine = await a.from("syllabi").select("board, class_level, subject").eq("subject", "Test subject");
  expect(mine.data).toEqual([{ board: "cbse", class_level: "9", subject: "Test subject" }]);
  expect((await a.from("syllabi").insert({ board: "cbse", class_level: "9", subject: "Nope", edition: "x", chapters: [] })).error).not.toBeNull();
  const upd = await a.from("syllabi").update({ subject: "Changed" }).eq("subject", "Test subject").select("id");
  expect(upd.data).toEqual([]);
  expect((await anonClient(l).from("syllabi").select("id")).data ?? []).toEqual([]);
});

test("school items and marks are checked and belong to the centre", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Item School" }).select("id").single()).data!;
  const ok = await a.from("school_items").insert({ centre_id: centre, school_id: school.id, class_level: "6", kind: "exam", subject: "Science", date: "2026-11-02", portions: "Chapters 1 to 3" });
  expect(ok.error).toBeNull();
  expect((await a.from("school_items").insert({ centre_id: centre, kind: "party", date: "2026-11-02" })).error).not.toBeNull();
  const st = (await a.from("students").insert({ centre_id: centre, name: "Marked", class_level: "6" }).select("id").single()).data!;
  expect((await a.from("marks").insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "FA2", date: "2026-09-20", score: 18, max: 20 })).error).toBeNull();
  expect((await a.from("marks").insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "FA2", date: "2026-09-20", score: 25, max: 20 })).error).not.toBeNull();
});

test("message_log takes the V2 kinds with a language and a body", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Noted" }).select("id").single()).data!;
  const r = await a.from("message_log").insert({ centre_id: centre, student_id: st.id, kind: "note", channel: "whatsapp_link", language: "kn", body: "ಈ ವಾರ" });
  expect(r.error).toBeNull();
});

test("photos bucket: a member reads their centre's folder and not another's", async () => {
  const b = await userClient(l, `v2-b-${stamp}@example.com`);
  const bytes = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: "image/jpeg" });
  expect((await a.storage.from("photos").upload(`${centre}/textbooks/one.jpg`, bytes)).error).toBeNull();
  expect((await b.storage.from("photos").download(`${centre}/textbooks/one.jpg`)).error).not.toBeNull();
  expect((await b.storage.from("photos").upload(`${centre}/textbooks/two.jpg`, bytes)).error).not.toBeNull();
  expect((await a.storage.from("photos").download(`${centre}/textbooks/one.jpg`)).error).toBeNull();
});
```

Add `"school_items"`, `"marks"` to `CENTRE_TABLES` with rows `school_items: { kind: "notice", date: "2026-10-20" }`
and `marks: { student_id: studentId, subject: "Maths", test: "FA1", date: "2026-07-20", score: 10, max: 15 }`. The
catalogue test's expected list gains `"syllabi"` beside `centre_members`, `centres` and `profiles` (it is not a centre
table).

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests/v2.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write the migration**

```sql
-- V2 (docs/spec-v2.md sections 5, 8 and 9): what the school sent, school marks, the reference syllabi, the V2 message
-- kinds, and the photos bucket. Additive (D26).

create type public.school_item_kind as enum ('exam', 'homework', 'notice', 'holiday');

create table public.school_items (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  school_id uuid,
  student_id uuid,
  class_level text check (class_level is null or class_level in ('lkg', 'ukg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')),
  kind public.school_item_kind not null,
  subject text check (subject is null or char_length(subject) <= 80),
  date date not null,
  portions text check (portions is null or char_length(portions) <= 2000),
  source_text text check (source_text is null or char_length(source_text) <= 4000),
  photo_path text,
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, school_id) references public.schools(centre_id, id) on delete set null (school_id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger school_items_updated before update on public.school_items for each row execute function public.set_updated_at();
create index school_items_date on public.school_items(centre_id, date);

alter table public.artefacts
  add foreign key (centre_id, school_item_id) references public.school_items(centre_id, id) on delete set null (school_item_id);

create table public.marks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  subject text not null check (char_length(subject) between 1 and 80),
  test text not null check (char_length(test) between 1 and 80),
  date date not null,
  score numeric(6, 2) not null check (score >= 0),
  max numeric(6, 2) not null check (max > 0),
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (score <= max),
  unique (centre_id, id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger marks_updated before update on public.marks for each row execute function public.set_updated_at();
create index marks_student on public.marks(centre_id, student_id, date);

do $$
declare t text;
begin
  foreach t in array array['school_items', 'marks'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- Reference data, not a centre table: written by migrations only; read by signed-in users. Chapters:
-- [{"position": 1, "name": "...", "skills": ["...", "..."]}]. Blueprint (class 10): the board's marks pattern.
create table public.syllabi (
  id uuid primary key default gen_random_uuid(),
  board text not null check (board in ('cbse', 'icse', 'karnataka')),
  class_level text not null check (class_level in ('8', '9', '10')),
  subject text not null check (char_length(subject) between 1 and 80),
  edition text not null check (char_length(edition) between 1 and 40),
  chapters jsonb not null default '[]'::jsonb,
  blueprint jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (board, class_level, subject, edition)
);
create trigger syllabi_updated before update on public.syllabi for each row execute function public.set_updated_at();
alter table public.syllabi enable row level security;
create policy syllabi_read on public.syllabi for select to authenticated using (true);
grant select on public.syllabi to authenticated;

alter type public.message_kind add value 'note';
alter type public.message_kind add value 'can_do';
alter type public.message_kind add value 'test_tomorrow';
alter type public.message_kind add value 'homework';
alter type public.message_kind add value 'consent';
alter table public.message_log
  add column language text check (language is null or language in ('en', 'hinglish', 'hi', 'kn')),
  add column body text check (body is null or char_length(body) <= 4000);

-- One private bucket; a member reads and writes under their centre's folder only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 3145728, array['image/jpeg']) on conflict (id) do nothing;
create policy photos_member_read on storage.objects for select to authenticated
  using (bucket_id = 'photos' and public.is_member(((storage.foldername(name))[1])::uuid));
create policy photos_member_write on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and public.is_member(((storage.foldername(name))[1])::uuid));
create policy photos_member_delete on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and public.is_member(((storage.foldername(name))[1])::uuid));
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests`
Expected: PASS. If `alter type … add value` fails inside the migration's transaction, split the five `add value`
lines into their own migration file `20261017000011a_v2_message_kinds.sql` placed before this one (Supabase runs files
in name order), and say so in the PR.

- [ ] **Step 5: Regenerate types, check, commit**

```bash
cd supabase && supabase gen types typescript --local > types.ts && cd .. && bun check --only=db
git add supabase && git commit -m "db: V2 school items, marks, syllabi, message kinds, photos (0011)"
```

### Task 4: Migration 0012, the allowance

**Files:**
- Create: `supabase/migrations/20261018000012_v2_allowance.sql`
- Modify: `supabase/tests/v2.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: `ai_kind` gains the V2 kinds; `start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb,
  p_model text, p_student uuid default null) returns uuid` with the monthly allowance and the per-student consent for
  the personal kinds; errors `ai_consent_missing` (as V1), `ai_limit_reached` with the limit in `detail`.

- [ ] **Step 1: Write the failing tests** (append to `supabase/tests/v2.test.ts`)

```ts
test("the V2 kinds share a monthly allowance; a personal kind needs the student's consent; V1 kinds keep their daily rule", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Allowed" }).select("id").single()).data!;
  const sheet = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "sheet", p_input: {}, p_model: "claude-haiku-5-5" });
  expect(sheet.error).toBeNull();
  const note = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "note", p_input: {}, p_model: "claude-haiku-5-5", p_student: st.id });
  expect(note.error?.message).toContain("ai_consent_missing");
  await a.from("students").update({ consent_at: new Date().toISOString(), consent_phone: "+919999999902" }).eq("id", st.id);
  expect((await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "note", p_input: {}, p_model: "claude-haiku-5-5", p_student: st.id })).error).toBeNull();
  const sql = new (await import("bun")).SQL(l.db);
  await sql`insert into public.ai_generations (centre_id, kind, input, model, status)
            select ${centre}::uuid, 'sheet', '{}', 'claude-haiku-5-5', 'ok' from generate_series(1, 598)`;
  await sql.close();
  const last = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "check", p_input: {}, p_model: "claude-haiku-5-5" });
  expect(last.error?.message).toContain("ai_limit_reached");
  expect(last.error?.details).toBe("600");
  const paper = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "paper", p_input: {}, p_model: "claude-sonnet-5-5" });
  expect(paper.error).toBeNull();
});
```

- [ ] **Step 2: Run the test to see it fail**

Run: `cd supabase && supabase db reset --no-seed > /dev/null && bun test tests/v2.test.ts`
Expected: FAIL, `sheet` is not an `ai_kind`.

- [ ] **Step 3: Write the migration**

```sql
-- V2 (docs/spec-v2.md section 9, D62, D63): the V2 kinds; one monthly allowance for them per centre (600 made, 900
-- started); the personal kinds need the student's recorded consent. V1's kinds keep V1's daily rules. The function is
-- replaced with a fifth parameter; migration 0007 is not edited.

alter type public.ai_kind add value 'plan';
alter type public.ai_kind add value 'sheet';
alter type public.ai_kind add value 'worked_example';
alter type public.ai_kind add value 'figure';
alter type public.ai_kind add value 'brief';
alter type public.ai_kind add value 'check';
alter type public.ai_kind add value 'placement';
alter type public.ai_kind add value 'mock';
alter type public.ai_kind add value 'note';
alter type public.ai_kind add value 'can_do';
alter type public.ai_kind add value 'test_tomorrow';
alter type public.ai_kind add value 'gap_report';
alter type public.ai_kind add value 'parse_school';
alter type public.ai_kind add value 'parse_textbook';
```

and, in a second file `20261018000012b_v2_allowance_function.sql` (the new enum values cannot be used in the transaction
that adds them):

```sql
drop function public.start_ai_generation(uuid, public.ai_kind, jsonb, text);

create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                           p_student uuid default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report']::public.ai_kind[];
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
  v_started integer;
  v_since timestamptz;
  v_id uuid;
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  if p_kind = any (v_v1) then
    if p_kind in ('scan_register', 'check_paper', 'progress_note')
       and (select c.ai_consent_at from public.centres c where c.id = p_centre) is null then
      raise exception 'ai_consent_missing';
    end if;
    if p_kind in ('paper', 'homework', 'worksheet', 'progress_note') then
      v_group := array['paper', 'homework', 'worksheet', 'progress_note']::public.ai_kind[];
      v_limit := 40;
    else
      v_group := array[p_kind];
      v_limit := 20;
    end if;
    v_since := now() - interval '24 hours';
  else
    if p_kind = any (v_personal) then
      if p_student is null or (select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null then
        raise exception 'ai_consent_missing';
      end if;
    end if;
    v_group := array['plan', 'sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock', 'note', 'can_do',
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook']::public.ai_kind[];
    v_limit := 600;
    v_since := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) from public, anon;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) to authenticated;
```

- [ ] **Step 4: Run the tests to see them pass; regenerate types; check; commit**

```bash
cd supabase && supabase db reset --no-seed > /dev/null && bun test tests && supabase gen types typescript --local > types.ts && cd .. && bun check --only=db
git add supabase && git commit -m "db: the V2 kinds and the monthly allowance (0012)"
```

Open PR 2 from `phase-10/tables-b`. After PR 1 and PR 2 merge: `gh workflow run deploy` (D26) so the hosted database
leads the app; confirm in the run's summary that nothing is pending.

### Task 5: Syllabus data, CBSE and Karnataka state, classes 8 to 10

**Files:**
- Create: `supabase/syllabi/<board>/<class>/<subject>.json` (24 files: `cbse` and `karnataka` × `8`, `9`, `10` ×
  `mathematics`, `science`, `social-science`, `english`), `tools/syllabi.ts`, `tools/syllabi.test.ts`,
  `supabase/tests/syllabi.test.ts`, the two generated migrations
- Modify: `package.json` (`"syllabi": "bun tools/syllabi.ts"`), `tools/check/steps.ts` (the `db` step's inputs gain
  `supabase/syllabi/**`)

**Interfaces:**
- JSON shape, one file per board, class and subject:

```json
{
  "board": "cbse",
  "classLevel": "9",
  "subject": "Mathematics",
  "edition": "2026-27",
  "source": "NCERT, Mathematics Textbook for Class IX (new, NCF 2023), contents page; https://ncert.nic.in/textbook.php",
  "chapters": [
    { "position": 1, "name": "Number Systems", "skills": ["Irrational numbers on the number line", "Decimal expansions", "Rationalising denominators", "Laws of exponents for real numbers"] }
  ],
  "blueprint": null
}
```

  `blueprint` for class 10 only: `{ "marks": 80, "durationMinutes": 180, "sections": [{ "name": "A", "questions": 20, "marksEach": 1 }] }`
  from the board's published pattern.
- Produces: `tools/syllabi.ts` reads every JSON under `supabase/syllabi/<board>/`, validates it (zod), and writes
  `supabase/migrations/<name>.sql` as `insert into public.syllabi (board, class_level, subject, edition, chapters,
  blueprint) values (...) on conflict (board, class_level, subject, edition) do update set chapters = excluded.chapters,
  blueprint = excluded.blueprint;` with the JSON as `$json$…$json$::jsonb`. Usage: `bun syllabi cbse
  20261019000013_syllabi_cbse` and `bun syllabi karnataka 20261020000014_syllabi_karnataka`.

- [ ] **Step 1: Write the failing tests**

`tools/syllabi.test.ts`:

```ts
import { expect, test } from "bun:test";
import { renderMigration, SyllabusFile } from "./syllabi";

const file = {
  board: "cbse", classLevel: "9", subject: "Mathematics", edition: "2026-27", source: "NCERT contents page",
  chapters: [{ position: 1, name: "Number Systems", skills: ["Irrational numbers", "Decimal expansions"] }],
  blueprint: null,
};

test("a syllabus file is validated", () => {
  expect(SyllabusFile.safeParse(file).success).toBe(true);
  expect(SyllabusFile.safeParse({ ...file, classLevel: "7" }).success).toBe(false);
  expect(SyllabusFile.safeParse({ ...file, chapters: [{ position: 1, name: "X", skills: [] }] }).success).toBe(false);
  expect(SyllabusFile.safeParse({ ...file, chapters: [{ position: 2, name: "X", skills: ["a"] }] }).success).toBe(false);
});

test("the migration upserts one row per file with the chapters as jsonb", () => {
  const sql = renderMigration([file]);
  expect(sql).toContain("insert into public.syllabi (board, class_level, subject, edition, chapters, blueprint)");
  expect(sql).toContain("('cbse', '9', 'Mathematics', '2026-27', $json$");
  expect(sql).toContain("on conflict (board, class_level, subject, edition) do update");
  expect(sql).toContain('"name":"Number Systems"');
});
```

`supabase/tests/syllabi.test.ts`:

```ts
import { beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

let a: SupabaseClient;
beforeAll(async () => {
  const l: Local = await local();
  a = await userClient(l, `syl-${Date.now()}@example.com`);
});

const SUBJECTS = ["Mathematics", "Science", "Social Science", "English"];

test("every board, class and subject has a syllabus with at least eight chapters, each with at least three skills", async () => {
  for (const board of ["cbse", "karnataka"]) {
    for (const cls of ["8", "9", "10"]) {
      const { data } = await a.from("syllabi").select("subject, chapters, blueprint").eq("board", board).eq("class_level", cls);
      expect({ board, cls, subjects: data?.map((r) => r.subject).sort() }).toEqual({ board, cls, subjects: [...SUBJECTS].sort() });
      for (const row of data ?? []) {
        const chapters = row.chapters as { position: number; name: string; skills: string[] }[];
        expect({ board, cls, subject: row.subject, chapters: chapters.length >= 8 }).toEqual({ board, cls, subject: row.subject, chapters: true });
        for (const ch of chapters) expect({ board, cls, subject: row.subject, chapter: ch.name, skills: ch.skills.length >= 3 }).toEqual({ board, cls, subject: row.subject, chapter: ch.name, skills: true });
        expect({ board, cls, subject: row.subject, blueprint: row.blueprint !== null }).toEqual({ board, cls, subject: row.subject, blueprint: cls === "10" });
      }
    }
  }
});
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `bun test tools/syllabi.test.ts` → FAIL (no module). `cd supabase && bun test tests/syllabi.test.ts` → FAIL (no rows).

- [ ] **Step 3: Write `tools/syllabi.ts`**

```ts
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { z } from "zod";

const Chapter = z.object({ position: z.number().int().min(1), name: z.string().min(1).max(200), skills: z.array(z.string().min(1).max(200)).min(1) });
export const SyllabusFile = z
  .object({
    board: z.enum(["cbse", "karnataka", "icse"]),
    classLevel: z.enum(["8", "9", "10"]),
    subject: z.string().min(1).max(80),
    edition: z.string().min(1).max(40),
    source: z.string().min(1),
    chapters: z.array(Chapter).min(1),
    blueprint: z.object({ marks: z.number().int().positive(), durationMinutes: z.number().int().positive(), sections: z.array(z.object({ name: z.string(), questions: z.number().int().positive(), marksEach: z.number().positive() })) }).nullable(),
  })
  .refine((f) => f.chapters.every((c, i) => c.position === i + 1), { message: "chapters must be numbered 1, 2, 3 in order" });
export type SyllabusFile = z.infer<typeof SyllabusFile>;

const q = (s: string) => `'${s.replace(/'/g, "''")}'`;

/** One upsert per file; the JSON is quoted with a dollar tag so no escaping is needed. */
export function renderMigration(files: SyllabusFile[]): string {
  const rows = files.map((f) => {
    const chapters = JSON.stringify(f.chapters.map(({ position, name, skills }) => ({ position, name, skills })));
    const blueprint = f.blueprint ? `$json$${JSON.stringify(f.blueprint)}$json$::jsonb` : "null";
    return `  (${q(f.board)}, ${q(f.classLevel)}, ${q(f.subject)}, ${q(f.edition)}, $json$${chapters}$json$::jsonb, ${blueprint})`;
  });
  return [
    "-- Generated by `bun syllabi` from supabase/syllabi/**.json (D58: chapter names and skills, no textbook text).",
    "insert into public.syllabi (board, class_level, subject, edition, chapters, blueprint) values",
    rows.join(",\n") + "",
    "on conflict (board, class_level, subject, edition) do update set chapters = excluded.chapters, blueprint = excluded.blueprint;",
    "",
  ].join("\n");
}

export function readBoard(root: string, board: string): SyllabusFile[] {
  const out: SyllabusFile[] = [];
  for (const cls of readdirSync(join(root, board))) {
    for (const file of readdirSync(join(root, board, cls))) {
      const parsed = SyllabusFile.parse(JSON.parse(readFileSync(join(root, board, cls, file), "utf8")));
      if (parsed.board !== board || parsed.classLevel !== cls) throw new Error(`${board}/${cls}/${file} names another board or class`);
      out.push(parsed);
    }
  }
  return out.sort((x, y) => `${x.classLevel}${x.subject}`.localeCompare(`${y.classLevel}${y.subject}`));
}

if (import.meta.main) {
  const [board, name] = process.argv.slice(2);
  if (!board || !name) {
    console.error("usage: bun syllabi <board> <migration name without .sql>");
    process.exit(2);
  }
  const files = readBoard(join(import.meta.dir, "..", "supabase", "syllabi"), board);
  const path = join(import.meta.dir, "..", "supabase", "migrations", `${name}.sql`);
  writeFileSync(path, renderMigration(files));
  console.log(`${files.length} syllabi → ${path}`);
}
```

- [ ] **Step 4: Transcribe the chapter lists**

For each of the 24 files: open the board's published contents page (CBSE: the NCERT textbook portal
`https://ncert.nic.in/textbook.php`, the 2026-27 book for the class, new for 8 and 9, old for 10; Karnataka:
`https://textbooks.karnataka.gov.in/`, 2026-27, English medium), transcribe the chapter titles in order as `name`, and
each chapter's section headings as `skills` (three or more; a heading that is a page of exercises is skipped). Write the
`source` line with the book's title and the URL. For class 10, write the `blueprint` from the board's published
pattern (CBSE: the sample paper's marks and sections at `cbseacademic.nic.in`; Karnataka: KSEAB's SSLC blueprint). No
sentence from the book is copied; headings only (D58). Where a class 9 Karnataka or CBSE book is not yet published in
2026-27, use the 2025-26 edition and say so in `edition` ("2025-26 (2026-27 book not published)").

- [ ] **Step 5: Generate, run the tests, check, commit**

```bash
bun syllabi cbse 20261019000013_syllabi_cbse && bun syllabi karnataka 20261020000014_syllabi_karnataka
bun test tools/syllabi.test.ts
cd supabase && supabase db reset --no-seed > /dev/null && bun test tests && cd .. && bun check --only=tools,db
git add supabase/syllabi supabase/migrations tools/syllabi.ts tools/syllabi.test.ts tools/check/steps.ts package.json supabase/tests/syllabi.test.ts
git commit -m "db: syllabus data for CBSE and Karnataka state, classes 8 to 10 (0013, 0014)"
```

Open PR 3 from `phase-10/syllabi`; after merge, `gh workflow run deploy`.

### Task 6: API route skeletons

**Files:**
- Modify: `api/src/schemas.ts`, `api/src/routes/ai.ts`, `api/src/db.ts` (`AIKind`), `api/test/schemas.test.ts`,
  `api/test/app.test.ts`

**Interfaces:**
- Produces, in `schemas.ts`: `PlanInput`, `MakeInput` (discriminated on `kind`), `ParseSchoolInput`,
  `ParseTextbookInput`, `FigureKind`; `Scheme` gains `{ kind: "mock", artefactId }`. Routes `POST /ai/plan`,
  `/ai/make`, `/ai/parse-school`, `/ai/parse-textbook`, each: 401 without a user (the existing middleware), 400 with
  the issue list on a bad body, else 501 `{ error: "not yet", route }`.

- [ ] **Step 1: Write the failing tests**

Append to `api/test/schemas.test.ts`:

```ts
import { MakeInput, ParseSchoolInput, ParseTextbookInput, PlanInput, Scheme } from "../src/schemas.js";

test("PlanInput takes a batch and a day", () => {
  expect(PlanInput.safeParse({ centreId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718", classId: null, date: "2026-10-12" }).success).toBe(true);
  expect(PlanInput.safeParse({ centreId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718", classId: null, date: "12/10/2026" }).success).toBe(false);
});

test("MakeInput accepts each kind with its fields and nothing else", () => {
  const c = { centreId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718" };
  expect(MakeInput.safeParse({ ...c, kind: "sheet", classLevel: "5", subject: "Mathematics", skills: ["Halves"], questions: 10, forHomework: true }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "worked_example", classLevel: "9", subject: "Mathematics", skill: "Rationalising denominators" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "figure", figure: "fraction_bar", classLevel: "4", subject: "Mathematics", skill: "Quarters" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "figure", figure: "pie_chart", classLevel: "4", subject: "Mathematics", skill: "Quarters" }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "brief", classLevel: "10", subject: "Mathematics", chapter: "Trigonometry" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: ["Cells", "Tissues", "Organs"] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: ["Cells"] }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "placement", classLevel: "7", subject: "English", chapters: ["Chapter 1", "Chapter 2"] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "mock", classLevel: "10", subject: "Science", portions: ["Light", "Electricity"], pattern: { marks: 40, durationMinutes: 90 } }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "note", studentId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719", studentName: "Dev", language: "kn", week: { taught: ["Halves"], right: ["Halves"], practise: ["Quarters"], coming: [] }, tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "can_do", studentId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719", studentName: "Anu", language: "en", ladder: { reading: "words", writing: "letters", numbers: "to_20" }, tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "test_tomorrow", studentId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719", studentName: "Anu", language: "hinglish", subject: "Science", date: "2026-11-02", portions: "Chapters 1 to 3", tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "gap_report", studentId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719", marking: [{ question: 1, marks: 2, max: 5, note: "Sign error" }] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "poem", classLevel: "5" }).success).toBe(false);
});

test("the parsers take text or a photo, and a contents photo with its class and subject", () => {
  const img = { imageBase64: "AAAA", mediaType: "image/jpeg" };
  const c = { centreId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718" };
  expect(ParseSchoolInput.safeParse({ ...c, text: "Science test on 2 Nov, ch 1-3" }).success).toBe(true);
  expect(ParseSchoolInput.safeParse({ ...c, image: img }).success).toBe(true);
  expect(ParseSchoolInput.safeParse({ ...c }).success).toBe(false);
  expect(ParseTextbookInput.safeParse({ ...c, image: img, classLevel: "5", subject: "Mathematics" }).success).toBe(true);
  expect(ParseTextbookInput.safeParse({ ...c, image: img, classLevel: "11", subject: "Mathematics" }).success).toBe(false);
});

test("Scheme accepts a mock's key", () => {
  expect(Scheme.safeParse({ kind: "mock", artefactId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60720" }).success).toBe(true);
});
```

Append to `api/test/app.test.ts`:

```ts
test("the V2 routes validate, then answer 501 until their phase", async () => {
  const centreId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718";
  for (const [path, body] of [
    ["/ai/plan", { centreId, classId: null, date: "2026-10-12" }],
    ["/ai/make", { centreId, kind: "brief", classLevel: "9", subject: "Science", chapter: "Motion" }],
    ["/ai/parse-school", { centreId, text: "FA2 on Monday" }],
    ["/ai/parse-textbook", { centreId, image: { imageBase64: "AAAA", mediaType: "image/jpeg" }, classLevel: "3", subject: "English" }],
  ] as const) {
    const r = await post(path, JSON.stringify(body));
    expect({ path, status: r.status, body: await r.json() }).toEqual({ path, status: 501, body: { error: "not yet", route: path } });
    const bad = await post(path, JSON.stringify({ centreId }));
    expect({ path, status: bad.status }).toEqual({ path, status: 400 });
    const anon = await app.request(path, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
    expect({ path, status: anon.status }).toEqual({ path, status: 401 });
  }
});
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd api && bun test`
Expected: FAIL, the schemas and routes do not exist.

- [ ] **Step 3: Write the schemas** (append to `api/src/schemas.ts`)

```ts
export const ClassLevel = z.enum(["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]);
export const Language = z.enum(["en", "hinglish", "hi", "kn"]);
export const FigureKind = z.enum(["number_line", "fraction_bar", "place_value", "unit_circle", "triangle", "labelled_cell", "food_chain"]);
const Day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const Subject = z.string().min(1).max(80);
const Skills = z.array(z.string().min(1).max(200));
const Student = { studentId: z.guid(), studentName: z.string().min(1).max(80), tutorName: z.string().min(1).max(80) };

/** POST /ai/plan: the batch (null: the session for all students) and the day; the API reads the record as the user. */
export const PlanInput = z.object({ ...CentreInput.shape, classId: z.guid().nullable(), date: Day });
export type PlanInput = z.infer<typeof PlanInput>;

/** POST /ai/make: one artefact of a kind (docs/spec-v2.md section 7). Group material names skills and a level and no
 *  student; the personal kinds name the student and need their consent (start_ai_generation). */
export const MakeInput = z.discriminatedUnion("kind", [
  z.object({ ...CentreInput.shape, kind: z.literal("sheet"), classLevel: ClassLevel, subject: Subject, skills: Skills.min(1).max(6), questions: z.number().int().min(3).max(30).default(10), forHomework: z.boolean().default(false), groupNo: z.number().int().min(1).max(9).optional() }),
  z.object({ ...CentreInput.shape, kind: z.literal("worked_example"), classLevel: ClassLevel, subject: Subject, skill: z.string().min(1).max(200) }),
  z.object({ ...CentreInput.shape, kind: z.literal("figure"), figure: FigureKind, classLevel: ClassLevel, subject: Subject, skill: z.string().min(1).max(200) }),
  z.object({ ...CentreInput.shape, kind: z.literal("brief"), classLevel: ClassLevel, subject: Subject, chapter: z.string().min(1).max(200) }),
  z.object({ ...CentreInput.shape, kind: z.literal("check"), classLevel: ClassLevel, subject: Subject, skills: Skills.length(3) }),
  z.object({ ...CentreInput.shape, kind: z.literal("placement"), classLevel: ClassLevel, subject: Subject, chapters: z.array(z.string().min(1).max(200)).min(1).max(30) }),
  z.object({ ...CentreInput.shape, kind: z.literal("mock"), classLevel: ClassLevel, subject: Subject, portions: z.array(z.string().min(1).max(200)).min(1).max(30), pattern: z.object({ marks: z.number().int().min(5).max(100), durationMinutes: z.number().int().min(10).max(240), sections: z.array(z.object({ name: z.string().max(20), questions: z.number().int().positive(), marksEach: z.number().positive() })).optional() }) }),
  z.object({ ...CentreInput.shape, kind: z.literal("note"), ...Student, language: Language, week: z.object({ taught: Skills, right: Skills, practise: Skills, coming: z.array(z.string().max(200)) }) }),
  z.object({ ...CentreInput.shape, kind: z.literal("can_do"), ...Student, language: Language, ladder: z.record(z.string().max(40), z.string().max(40)) }),
  z.object({ ...CentreInput.shape, kind: z.literal("test_tomorrow"), ...Student, language: Language, subject: Subject, date: Day, portions: z.string().max(2000).optional() }),
  z.object({ ...CentreInput.shape, kind: z.literal("gap_report"), studentId: z.guid(), marking: z.array(z.object({ question: z.number().int().positive(), marks: z.number().min(0), max: z.number().positive(), note: z.string().max(500).optional() })).min(1) }),
]);
export type MakeInput = z.infer<typeof MakeInput>;

/** POST /ai/parse-school: what the school sent, as text or one photo. */
export const ParseSchoolInput = z
  .object({ ...CentreInput.shape, text: z.string().min(1).max(4000).optional(), image: Image.optional() })
  .refine((v) => v.text !== undefined || v.image !== undefined, { message: "text or image is needed" });
export type ParseSchoolInput = z.infer<typeof ParseSchoolInput>;

/** POST /ai/parse-textbook: a contents page, with the class and subject it is for. */
export const ParseTextbookInput = z.object({ ...CentreInput.shape, image: Image, classLevel: ClassLevel, subject: Subject });
export type ParseTextbookInput = z.infer<typeof ParseTextbookInput>;
```

`Image` and `CentreInput` are already in the file above these lines (move `CentreInput` above if it is declared later).
In `Scheme`, add `z.object({ kind: z.literal("mock"), artefactId: z.guid() })` as a third variant.

In `api/src/db.ts`, extend `AIKind`:

```ts
export type AIKind =
  | "paper" | "homework" | "worksheet" | "progress_note" | "scan_register" | "check_paper"
  | "plan" | "sheet" | "worked_example" | "figure" | "brief" | "check" | "placement" | "mock"
  | "note" | "can_do" | "test_tomorrow" | "gap_report" | "parse_school" | "parse_textbook";
```

- [ ] **Step 4: Write the routes** (in `api/src/routes/ai.ts`, inside `aiRoutes`, after the V1 routes)

```ts
  // V2 (docs/spec-v2.md section 9): validated now, built in Phases 11 to 14.
  const notYet = <T>(path: string, schema: ZodType<T>) =>
    routes.post(path, async (c) => {
      const body = await parse(c, schema);
      if (!isParsed(body)) return body;
      return c.json({ error: "not yet", route: `/ai${path}` }, 501);
    });
  notYet("/plan", PlanInput);
  notYet("/make", MakeInput);
  notYet("/parse-school", ParseSchoolInput);
  notYet("/parse-textbook", ParseTextbookInput);
```

with `PlanInput`, `MakeInput`, `ParseSchoolInput`, `ParseTextbookInput` added to the import from `../schemas.js`.
`parse` and `isParsed` are the file's existing helpers (they validate the body against the schema and pull the centre
id); if `parse` requires `centreId` in the schema, every V2 schema carries it through `CentreInput.shape`.

- [ ] **Step 5: Run the tests to see them pass; check; commit**

```bash
cd api && bun run check && cd .. && bun check --only=api
git add api && git commit -m "api: the V2 route skeletons and schemas"
```

Open PR 4 from `phase-10/api`; after merge, `gh workflow run deploy` and confirm `/ai/plan` answers 401 without a token
in the smoke.

### Task 7: iOS Domain, the V2 value types and the figure specs

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/ClassLevel.swift`, `Ladder.swift`, `Skill.swift`, `FigureSpec.swift`,
  `School.swift`, `Textbook.swift`; `ios/TutorCentralKit/Tests/DomainTests/ClassLevelTests.swift`,
  `FigureSpecTests.swift`

**Interfaces:**
- Produces: `ClassLevel` (raw values as the database's), `Stage`, `Ladder` with `Ladder.Domain` and levels, `Skill`,
  `SkillState`, `FigureSpec` with `validate()`, `School`, `Textbook`, `Chapter`.

- [ ] **Step 1: Write the failing tests**

`ClassLevelTests.swift`:

```swift
import Testing
@testable import Domain

struct ClassLevelTests {
    @Test func rawValuesMatchTheDatabase() {
        #expect(ClassLevel.allCases.map(\.rawValue) == ["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
        #expect(ClassLevel(rawValue: "11") == nil)
    }

    @Test func stagesAndRules() {
        #expect(ClassLevel.lkg.stage == .preschool && ClassLevel.two.stage == .early && ClassLevel.six.stage == .middle)
        #expect(ClassLevel.seven.expectsBoard == false && ClassLevel.eight.expectsBoard == true)
        #expect(ClassLevel.five.homeworkIsLight == true && ClassLevel.six.homeworkIsLight == false)
        #expect(ClassLevel.one.usesLadder == true && ClassLevel.four.usesLadder == false)
    }

    @Test func titlesAndOrder() {
        #expect(ClassLevel.lkg.title == "LKG" && ClassLevel.ten.title == "Class 10")
        #expect(ClassLevel.ukg < ClassLevel.one && ClassLevel.nine < ClassLevel.ten)
    }
}
```

`FigureSpecTests.swift`:

```swift
import Testing
@testable import Domain

struct FigureSpecTests {
    @Test func aFractionBarMustSumToTheWhole() {
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 3, label: "3/4").validate() == nil)
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 5, label: "5/4").validate() == .shadedBeyondParts)
        #expect(FigureSpec.fractionBar(parts: 0, shaded: 0, label: "").validate() == .noParts)
    }

    @Test func aNumberLineNeedsMarksInsideItsRange() {
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, marks: [4, 8]).validate() == nil)
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, marks: [12]).validate() == .markOutOfRange)
        #expect(FigureSpec.numberLine(from: 5, to: 5, step: 1, marks: []).validate() == .emptyRange)
    }

    @Test func aTriangleNeedsAnglesThatAddTo180() {
        #expect(FigureSpec.triangle(angles: [60, 60, 60], labels: ["A", "B", "C"]).validate() == nil)
        #expect(FigureSpec.triangle(angles: [90, 60, 60], labels: ["A", "B", "C"]).validate() == .anglesDoNotSum)
    }

    @Test func aLabelledCellNeedsAtLeastOneLabel() {
        #expect(FigureSpec.labelledCell(kind: .plant, labels: ["Cell wall", "Nucleus"]).validate() == nil)
        #expect(FigureSpec.labelledCell(kind: .animal, labels: []).validate() == .noLabels)
    }

    @Test func specsRoundTripAsJSON() throws {
        let spec = FigureSpec.foodChain(links: ["Grass", "Deer", "Tiger"])
        let data = try JSONEncoder().encode(spec)
        #expect(try JSONDecoder().decode(FigureSpec.self, from: data) == spec)
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `bun check --only=ios` (or `xcodebuild test -scheme TutorCentral -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DomainTests -collect-test-diagnostics never` after `bun gen`)
Expected: FAIL to build, the types do not exist.

- [ ] **Step 3: Write the types**

`ClassLevel.swift`:

```swift
/// The class a student is in, as `students.class_level` stores it. LKG and UKG are a stage with a ladder and no
/// chapters; classes 1 to 3 have the ladder for reading, writing and numbers (docs/spec-v2.md section 5).
public enum ClassLevel: String, CaseIterable, Sendable, Codable, Comparable {
    case lkg, ukg, one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8",
         nine = "9", ten = "10"

    public enum Stage: Sendable { case preschool, early, middle, secondary }

    public var stage: Stage {
        switch self {
        case .lkg, .ukg: .preschool
        case .one, .two, .three: .early
        case .four, .five, .six, .seven: .middle
        case .eight, .nine, .ten: .secondary
        }
    }

    /// The board matters from class 8 (D58).
    public var expectsBoard: Bool { stage == .secondary }
    /// Homework is light up to class 5 (research section 4).
    public var homeworkIsLight: Bool { ordinal <= ClassLevel.five.ordinal }
    /// LKG to 3 use the ladder.
    public var usesLadder: Bool { stage == .preschool || stage == .early }

    public var title: String {
        switch self {
        case .lkg: "LKG"
        case .ukg: "UKG"
        default: "Class \(rawValue)"
        }
    }

    private var ordinal: Int { ClassLevel.allCases.firstIndex(of: self)! }
    public static func < (lhs: ClassLevel, rhs: ClassLevel) -> Bool { lhs.ordinal < rhs.ordinal }
}
```

`Ladder.swift`:

```swift
/// Where a young student is in reading, writing and numbers (an ASER and NIPUN style ladder, research section 4).
public enum Ladder {
    public enum Domain: String, CaseIterable, Sendable, Codable { case reading, writing, numbers }

    public enum Reading: String, CaseIterable, Sendable, Codable { case beginner, letters, words, sentences, story }
    public enum Writing: String, CaseIterable, Sendable, Codable { case beginner, letters, words, sentences, paragraph }
    public enum Numbers: String, CaseIterable, Sendable, Codable {
        case beginner, to9 = "to_9", to20 = "to_20", to99 = "to_99", subtraction, division
    }

    public struct Placement: Hashable, Sendable, Codable {
        public var reading: Reading
        public var writing: Writing
        public var numbers: Numbers
        public init(reading: Reading, writing: Writing, numbers: Numbers) {
            self.reading = reading
            self.writing = writing
            self.numbers = numbers
        }
    }
}
```

`Skill.swift`:

```swift
import Foundation

public enum SkillState: String, Sendable, Codable, CaseIterable { case notStarted = "not_started", taught, practising, secure, revisit }

public struct Chapter: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var subject: String
    public var position: Int
    public var name: String
    public init(id: UUID, subject: String, position: Int, name: String) {
        self.id = id
        self.subject = subject
        self.position = position
        self.name = name
    }
}

public struct Skill: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let chapterID: UUID
    public var position: Int
    public var name: String
    public var state: SkillState
    public var stateAt: Date
    public var lastCheckedAt: Date?
    public init(id: UUID, chapterID: UUID, position: Int, name: String, state: SkillState, stateAt: Date, lastCheckedAt: Date?) {
        self.id = id
        self.chapterID = chapterID
        self.position = position
        self.name = name
        self.state = state
        self.stateAt = stateAt
        self.lastCheckedAt = lastCheckedAt
    }
}
```

`School.swift` and `Textbook.swift`:

```swift
import Foundation

public enum Board: String, Sendable, Codable, CaseIterable { case cbse, icse, karnataka, other }

public struct School: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var board: Board?
    public init(id: UUID, name: String, board: Board?) {
        self.id = id
        self.name = name
        self.board = board
    }
}
```

```swift
import Foundation

/// A textbook captured once per school, class and subject (D58); its chapters are copied per student.
public struct Textbook: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let schoolID: UUID
    public var classLevel: ClassLevel
    public var subject: String
    public var title: String
    public var publisher: String?
    public var edition: String?
    public var chapters: [TextbookChapter]
    public init(id: UUID, schoolID: UUID, classLevel: ClassLevel, subject: String, title: String, publisher: String?, edition: String?, chapters: [TextbookChapter]) {
        self.id = id
        self.schoolID = schoolID
        self.classLevel = classLevel
        self.subject = subject
        self.title = title
        self.publisher = publisher
        self.edition = edition
        self.chapters = chapters
    }
}

/// A chapter as parsed from the contents page, before it is copied to a student.
public struct TextbookChapter: Hashable, Sendable, Codable {
    public var position: Int
    public var name: String
    public var skills: [String]
    public init(position: Int, name: String, skills: [String]) {
        self.position = position
        self.name = name
        self.skills = skills
    }
}
```

`FigureSpec.swift`:

```swift
/// A figure the app draws itself from a spec the API returns (D59). A spec that fails `validate()` is not drawn.
public enum FigureSpec: Hashable, Sendable, Codable {
    case numberLine(from: Int, to: Int, step: Int, marks: [Int])
    case fractionBar(parts: Int, shaded: Int, label: String)
    case placeValue(number: Int)
    case unitCircle(angleDegrees: Int)
    case triangle(angles: [Int], labels: [String])
    case labelledCell(kind: CellKind, labels: [String])
    case foodChain(links: [String])

    public enum CellKind: String, Sendable, Codable { case plant, animal }

    public enum Problem: Sendable, Equatable {
        case emptyRange, badStep, markOutOfRange, noParts, shadedBeyondParts, numberTooLarge, angleOutOfRange,
             anglesDoNotSum, noLabels, tooFewLinks
    }

    public func validate() -> Problem? {
        switch self {
        case let .numberLine(from, to, step, marks):
            if from >= to { return .emptyRange }
            if step <= 0 || (to - from) / step > 40 { return .badStep }
            if marks.contains(where: { $0 < from || $0 > to }) { return .markOutOfRange }
            return nil
        case let .fractionBar(parts, shaded, _):
            if parts <= 0 || parts > 24 { return .noParts }
            if shaded < 0 || shaded > parts { return .shadedBeyondParts }
            return nil
        case let .placeValue(number):
            return (0 ... 9_999_999).contains(number) ? nil : .numberTooLarge
        case let .unitCircle(angle):
            return (0 ... 360).contains(angle) ? nil : .angleOutOfRange
        case let .triangle(angles, labels):
            if angles.count != 3 || labels.count != 3 { return .anglesDoNotSum }
            if angles.contains(where: { $0 <= 0 }) || angles.reduce(0, +) != 180 { return .anglesDoNotSum }
            return nil
        case let .labelledCell(_, labels):
            return labels.isEmpty ? .noLabels : nil
        case let .foodChain(links):
            return links.count < 2 ? .tooFewLinks : nil
        }
    }
}
```

- [ ] **Step 4: Run the tests to see them pass; format; commit**

```bash
cd ios && swiftformat . && swiftlint --strict && cd .. && bun check --only=format,lint,ios
git add ios && git commit -m "ios: V2 Domain types: class levels, the ladder, skills, textbooks, figure specs"
```

### Task 8: iOS Data, the repositories Phase 11 needs

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Schools/SchoolsRepository.swift`, `FakeSchoolsRepository.swift`,
  `SupabaseSchoolsRepository.swift`; `Sources/Data/Textbooks/TextbooksRepository.swift`, `FakeTextbooksRepository.swift`,
  `SupabaseTextbooksRepository.swift`, `TextbookRow.swift`; `Tests/DataTests/TextbookRowTests.swift`
- Modify: `Sources/Data/Attendance/AttendanceRepository.swift` (one new method), its fake and Supabase
  implementation

**Interfaces:**
- Produces:

```swift
public protocol SchoolsRepository: Sendable {
    func schools(centre: UUID) async throws -> [School]
    func create(name: String, board: Board?, centre: UUID) async throws -> School
}

public protocol TextbooksRepository: Sendable {
    func textbooks(centre: UUID) async throws -> [Textbook]
    /// One row per school, class and subject; a second capture for the same three replaces the chapters.
    func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook
    /// Copies the textbook's chapters and skills to the student, keeping any the student already has for the subject.
    func copyChapters(of textbookID: UUID, to studentID: UUID, centre: UUID) async throws
    func chapters(student: UUID) async throws -> [Chapter]
    func skills(student: UUID) async throws -> [Skill]
    func setState(skillID: UUID, _ state: SkillState) async throws
}

/// Added to AttendanceRepository:
public struct SessionClose: Sendable {
    public struct Check: Sendable, Codable { public let studentID: UUID; public let skillID: UUID; public let question: String; public let correct: Bool }
    public struct Homework: Sendable, Codable { public let studentID: UUID; public let artefactID: UUID }
    public struct Track: Sendable, Codable { public let status: String; public let reasons: [String] }
    public let classID: UUID?
    public let date: Day
    public let marks: [UUID: AttendanceStatus]
    public let checks: [Check]
    public let homework: [Homework]
    public let track: [UUID: Track]
}
func close(_ close: SessionClose, centre: UUID) async throws -> UUID   // close_session
```

- [ ] **Step 1: Write the failing test**

`TextbookRowTests.swift`:

```swift
import Foundation
import Testing
@testable import Data
@testable import Domain

struct TextbookRowTests {
    @Test func decodesATextbookWithItsChapters() throws {
        let json = """
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718","school_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719",
          "class_level":"5","subject":"Mathematics","title":"Maths 5","publisher":null,"edition":"2026-27",
          "chapters":[{"position":1,"name":"Fractions","skills":["Halves","Quarters"]}]}]
        """.data(using: .utf8)!
        let rows = try SupabaseTextbooksRepository.decoder.decode([TextbookRow].self, from: json)
        let book = rows[0].textbook
        #expect(book.classLevel == .five && book.chapters == [TextbookChapter(position: 1, name: "Fractions", skills: ["Halves", "Quarters"])])
        #expect(book.publisher == nil && book.edition == "2026-27")
    }

    @Test func refusesAnUnknownClassLevel() {
        let json = #"[{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718","school_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719","class_level":"12","subject":"M","title":"T","chapters":[]}]"#.data(using: .utf8)!
        #expect(throws: (any Error).self) { try SupabaseTextbooksRepository.decoder.decode([TextbookRow].self, from: json) }
    }
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `bun check --only=ios` → FAIL to build.

- [ ] **Step 3: Write the row, the protocols, the fakes and the Supabase implementations**

`TextbookRow.swift`:

```swift
import Domain
import Foundation

/// A `textbooks` row. The chapters are stored on the row as JSON (the parsed contents page) until they are copied to
/// a student; `chapters` and `skills` tables hold the per-student copies.
struct TextbookRow: Decodable {
    let id: UUID
    let schoolId: UUID
    let classLevel: ClassLevel
    let subject: String
    let title: String
    let publisher: String?
    let edition: String?
    let chapters: [TextbookChapter]

    var textbook: Textbook {
        Textbook(id: id, schoolID: schoolId, classLevel: classLevel, subject: subject, title: title,
                 publisher: publisher, edition: edition, chapters: chapters)
    }
}
```

This needs one more column: add to Task 1's migration, before it merges, `chapters jsonb not null default '[]'::jsonb`
on `textbooks` (the parsed list, so a later student of the class gets it at add time; Task 1's test for the shared
contents page inserts chapters per student, which still holds). If PR 1 has merged, add the column in a migration
`20261021000015_textbooks_chapters.sql` instead.

`SchoolsRepository.swift`, `FakeSchoolsRepository.swift`, `SupabaseSchoolsRepository.swift`:

```swift
import Domain
import Foundation

/// The centre's schools. RLS keeps every call inside the member's centre.
public protocol SchoolsRepository: Sendable {
    func schools(centre: UUID) async throws -> [School]
    func create(name: String, board: Board?, centre: UUID) async throws -> School
}
```

```swift
import Domain
import Foundation

@MainActor public final class FakeSchoolsRepository: SchoolsRepository {
    public nonisolated static let vidya = School(id: UUID(uuidString: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60731")!, name: "Vidya Niketan", board: .cbse)
    public private(set) var schools: [School]
    public var error: (any Error)?
    public init(schools: [School] = [vidya]) { self.schools = schools }

    public func schools(centre _: UUID) async throws -> [School] {
        if let error { throw error }
        return schools
    }

    public func create(name: String, board: Board?, centre _: UUID) async throws -> School {
        if let error { throw error }
        let school = School(id: UUID(), name: name, board: board)
        schools.append(school)
        return school
    }
}
```

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseSchoolsRepository: SchoolsRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private struct Row: Decodable {
        let id: UUID
        let name: String
        let board: Board?
        var school: School { School(id: id, name: name, board: board) }
    }

    public init(client: SupabaseClient) { self.client = client }

    public func schools(centre: UUID) async throws -> [School] {
        let response = try await client.from("schools").select("id, name, board").eq("centre_id", value: centre).order("name").execute()
        return try Self.decoder.decode([Row].self, from: response.data).map(\.school)
    }

    public func create(name: String, board: Board?, centre: UUID) async throws -> School {
        let values: [String: AnyJSON] = ["centre_id": .string(centre.uuidString), "name": .string(name), "board": board.map { .string($0.rawValue) } ?? .null]
        let response = try await client.from("schools").insert(values).select("id, name, board").single().execute()
        return try Self.decoder.decode(Row.self, from: response.data).school
    }
}
```

`TextbooksRepository.swift`, `FakeTextbooksRepository.swift`, `SupabaseTextbooksRepository.swift`:

```swift
import Domain
import Foundation

public protocol TextbooksRepository: Sendable {
    func textbooks(centre: UUID) async throws -> [Textbook]
    /// One row per school, class and subject; a second capture for the same three replaces the chapters.
    func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook
    /// Copies the textbook's chapters and skills to the student, keeping any the student already has for the subject.
    func copyChapters(of textbookID: UUID, to studentID: UUID, centre: UUID) async throws
    func chapters(student: UUID) async throws -> [Chapter]
    func skills(student: UUID) async throws -> [Skill]
    func setState(skillID: UUID, _ state: SkillState) async throws
}
```

```swift
import Domain
import Foundation

@MainActor public final class FakeTextbooksRepository: TextbooksRepository {
    public private(set) var textbooks: [Textbook] = []
    public private(set) var chaptersByStudent: [UUID: [Chapter]] = [:]
    public private(set) var skillsByStudent: [UUID: [Skill]] = [:]
    public var error: (any Error)?
    public init() {}

    public func textbooks(centre _: UUID) async throws -> [Textbook] {
        if let error { throw error }
        return textbooks
    }

    public func save(_ textbook: Textbook, centre _: UUID) async throws -> Textbook {
        if let error { throw error }
        textbooks.removeAll { $0.schoolID == textbook.schoolID && $0.classLevel == textbook.classLevel && $0.subject == textbook.subject }
        textbooks.append(textbook)
        return textbook
    }

    public func copyChapters(of textbookID: UUID, to studentID: UUID, centre _: UUID) async throws {
        if let error { throw error }
        guard let book = textbooks.first(where: { $0.id == textbookID }) else { return }
        var chapters = chaptersByStudent[studentID, default: []].filter { $0.subject != book.subject }
        var skills = skillsByStudent[studentID, default: []].filter { skill in chapters.contains { $0.id == skill.chapterID } }
        for chapter in book.chapters {
            let id = UUID()
            chapters.append(Chapter(id: id, subject: book.subject, position: chapter.position, name: chapter.name))
            for (index, name) in chapter.skills.enumerated() {
                skills.append(Skill(id: UUID(), chapterID: id, position: index + 1, name: name, state: .notStarted, stateAt: .now, lastCheckedAt: nil))
            }
        }
        chaptersByStudent[studentID] = chapters
        skillsByStudent[studentID] = skills
    }

    public func chapters(student: UUID) async throws -> [Chapter] { chaptersByStudent[student, default: []] }
    public func skills(student: UUID) async throws -> [Skill] { skillsByStudent[student, default: []] }

    public func setState(skillID: UUID, _ state: SkillState) async throws {
        for (student, skills) in skillsByStudent {
            skillsByStudent[student] = skills.map { $0.id == skillID ? Skill(id: $0.id, chapterID: $0.chapterID, position: $0.position, name: $0.name, state: state, stateAt: .now, lastCheckedAt: $0.lastCheckedAt) : $0 }
        }
    }
}
```

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseTextbooksRepository: TextbooksRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, school_id, class_level, subject, title, publisher, edition, chapters"

    public init(client: SupabaseClient) { self.client = client }

    public func textbooks(centre: UUID) async throws -> [Textbook] {
        let response = try await client.from("textbooks").select(Self.columns).eq("centre_id", value: centre).order("subject").execute()
        return try Self.decoder.decode([TextbookRow].self, from: response.data).map(\.textbook)
    }

    public func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook {
        let chapters = try JSONEncoder().encode(textbook.chapters)
        let values: [String: AnyJSON] = [
            "centre_id": .string(centre.uuidString), "school_id": .string(textbook.schoolID.uuidString),
            "class_level": .string(textbook.classLevel.rawValue), "subject": .string(textbook.subject),
            "title": .string(textbook.title), "publisher": textbook.publisher.map(AnyJSON.string) ?? .null,
            "edition": textbook.edition.map(AnyJSON.string) ?? .null,
            "chapters": try JSONDecoder().decode(AnyJSON.self, from: chapters),
        ]
        let response = try await client.from("textbooks").upsert(values, onConflict: "centre_id,school_id,class_level,subject")
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(TextbookRow.self, from: response.data).textbook
    }

    public func copyChapters(of textbookID: UUID, to studentID: UUID, centre: UUID) async throws {
        try await client.rpc("copy_textbook_chapters", params: ["p_centre": centre.uuidString, "p_textbook": textbookID.uuidString, "p_student": studentID.uuidString]).execute()
    }

    public func chapters(student: UUID) async throws -> [Chapter] {
        struct Row: Decodable { let id: UUID; let subject: String; let position: Int; let name: String }
        let response = try await client.from("chapters").select("id, subject, position, name").eq("student_id", value: student).order("subject").order("position").execute()
        return try Self.decoder.decode([Row].self, from: response.data).map { Chapter(id: $0.id, subject: $0.subject, position: $0.position, name: $0.name) }
    }

    public func skills(student: UUID) async throws -> [Skill] {
        struct Row: Decodable { let id: UUID; let chapterId: UUID; let position: Int; let name: String; let state: SkillState; let stateAt: Date; let lastCheckedAt: Date? }
        let response = try await client.from("skills").select("id, chapter_id, position, name, state, state_at, last_checked_at").eq("student_id", value: student).order("position").execute()
        return try Self.decoder.decode([Row].self, from: response.data).map { Skill(id: $0.id, chapterID: $0.chapterId, position: $0.position, name: $0.name, state: $0.state, stateAt: $0.stateAt, lastCheckedAt: $0.lastCheckedAt) }
    }

    public func setState(skillID: UUID, _ state: SkillState) async throws {
        try await client.from("skills").update(["state": AnyJSON.string(state.rawValue), "state_at": .string(ISO8601DateFormatter().string(from: .now))]).eq("id", value: skillID).execute()
    }
}
```

`copy_textbook_chapters` is one more function, in the migration this task adds (`20261021000015_textbooks_chapters.sql`,
with the `chapters` column above if PR 1 has merged; otherwise in Task 1's file):

```sql
alter table public.textbooks add column if not exists chapters jsonb not null default '[]'::jsonb;

-- Copies a textbook's parsed chapters and skills to a student, replacing the student's chapters of that subject that
-- came from this textbook and keeping the rest. security invoker: RLS decides.
create function public.copy_textbook_chapters(p_centre uuid, p_textbook uuid, p_student uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_subject text; v_chapters jsonb;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.subject, t.chapters into v_subject, v_chapters from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_subject is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  delete from public.chapters c where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook;
  insert into public.chapters (centre_id, student_id, subject, position, name, textbook_id)
  select p_centre, p_student, v_subject, (ch->>'position')::integer, ch->>'name', p_textbook
  from jsonb_array_elements(v_chapters) ch;
  insert into public.skills (centre_id, chapter_id, student_id, position, name)
  select p_centre, c.id, p_student, s.ordinality, s.value
  from public.chapters c
  join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
  cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
  where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook;
end $$;

revoke all on function public.copy_textbook_chapters(uuid, uuid, uuid) from public, anon;
grant execute on function public.copy_textbook_chapters(uuid, uuid, uuid) to authenticated;
```

with a test in `supabase/tests/v2.test.ts`: a textbook with two chapters of two skills, copied to a student, gives two
chapters and four skills; copied again, still two and four.

`AttendanceRepository`'s `close`: add `SessionClose` (as the interface above) to
`Sources/Data/Attendance/AttendanceRepository.swift`, `func close(_ close: SessionClose, centre: UUID) async throws ->
UUID` to the protocol; the fake records the call and returns a fixed id; the Supabase implementation calls
`close_session` with `p_marks` as `[String: String]` (student id to `present` or `absent`), `p_checks`, `p_homework` and
`p_track` encoded through `AnyJSON`, and decodes the returned uuid.

- [ ] **Step 4: Run the tests to see them pass; format; check; commit**

```bash
cd ios && swiftformat . && swiftlint --strict && cd .. && bun check
git add ios supabase && git commit -m "ios: schools and textbooks repositories, the close; copy_textbook_chapters (0015)"
```

Open PR 5 from `phase-10/domain-data`; after merge, `gh workflow run deploy` for 0015.

### Task 9: The share extension target and background refresh

**Files:**
- Create: `ios/Share/ShareViewController.swift`, `ios/Share/Info.plist`, `ios/Share/TutorCentralShare.entitlements`,
  `ios/TutorCentralKit/Sources/Data/Refresh/BackgroundRefresh.swift`,
  `ios/TutorCentralKit/Sources/AppShell/SharedInbox.swift`, `ios/TutorCentralKit/Tests/AppShellTests/SharedInboxTests.swift`
- Modify: `ios/project.yml`, `ios/App/Info.plist`, `ios/App/TutorCentral.entitlements`, `ios/App/TutorCentralApp.swift`

**Interfaces:**
- Produces: app group `group.in.tutorcentral`; `SharedInbox` (reads `inbox/*.json` from the group container:
  `{ "kind": "text" | "image", "text"?: String, "file"?: String, "receivedAt": ISO date }`), `BackgroundRefresh`
  (registers `in.tutorcentral.app.refresh`, schedules on background, runs a handler that returns at once in this phase).

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import AppShell

struct SharedInboxTests {
    @Test func readsItemsInOrderAndLeavesThem() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("inbox"), withIntermediateDirectories: true)
        let a = #"{"kind":"text","text":"FA2 on Monday","receivedAt":"2026-10-12T10:00:00Z"}"#
        let b = #"{"kind":"image","file":"x.jpg","receivedAt":"2026-10-12T11:00:00Z"}"#
        try b.write(to: dir.appendingPathComponent("inbox/b.json"), atomically: true, encoding: .utf8)
        try a.write(to: dir.appendingPathComponent("inbox/a.json"), atomically: true, encoding: .utf8)
        let items = try SharedInbox(container: dir).items()
        #expect(items.map(\.kind) == [.text, .image] && items[0].text == "FA2 on Monday" && items[1].file == "x.jpg")
        #expect(try SharedInbox(container: dir).items().count == 2)
    }

    @Test func anEmptyOrMissingInboxIsEmpty() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(try SharedInbox(container: dir).items().isEmpty)
    }
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `bun check --only=ios` → FAIL to build.

- [ ] **Step 3: Write the code and the project changes**

`SharedInbox.swift`:

```swift
import Foundation

/// What the share extension left in the app group: read on foreground from Phase 13; read and left alone in Phase 10.
public struct SharedInbox: Sendable {
    public struct Item: Decodable, Sendable {
        public enum Kind: String, Decodable, Sendable { case text, image }
        public let kind: Kind
        public let text: String?
        public let file: String?
        public let receivedAt: Date
    }

    public static let groupID = "group.in.tutorcentral"
    private let container: URL

    public init(container: URL) { self.container = container }

    public static func live() -> SharedInbox? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID).map(SharedInbox.init(container:))
    }

    public func items() throws -> [Item] {
        let inbox = container.appendingPathComponent("inbox")
        guard FileManager.default.fileExists(atPath: inbox.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { try decoder.decode(Item.self, from: Data(contentsOf: $0)) }
            .sorted { $0.receivedAt < $1.receivedAt }
    }
}
```

`BackgroundRefresh.swift` (in Data, since it will call the API in Phase 12):

```swift
import BackgroundTasks
import Foundation

/// iOS's app refresh: registered at launch, scheduled when the app goes to the background. The handler makes the day's
/// plan from Phase 12; until then it completes at once (docs/spec-v2.md section 6, D60).
public enum BackgroundRefresh {
    public static let identifier = "in.tutorcentral.app.refresh"

    @MainActor public static func register(handler: @escaping @Sendable () async -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            let work = Task {
                await handler()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    public static func schedule(earliest: TimeInterval = 4 * 3600) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliest)
        try? BGTaskScheduler.shared.submit(request)
    }
}
```

In `TutorCentralApp.swift`: call `BackgroundRefresh.register { }` in `init`, and `BackgroundRefresh.schedule()` on
`scenePhase == .background`. In `App/Info.plist` add:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key><array><string>in.tutorcentral.app.refresh</string></array>
<key>UIBackgroundModes</key><array><string>fetch</string></array>
```

In both entitlements files add:

```xml
<key>com.apple.security.application-groups</key><array><string>group.in.tutorcentral</string></array>
```

`Share/ShareViewController.swift`:

```swift
import UIKit
import UniformTypeIdentifiers

/// "Share to Tutor Central": one text or one image, written to the app group's inbox, then done. The app reads the
/// inbox when it next opens (Phase 13). No UI of its own beyond the system sheet.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await save(); extensionContext?.completeRequest(returningItems: nil) }
    }

    private func save() async {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.in.tutorcentral"),
              let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        let inbox = container.appendingPathComponent("inbox")
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: .now)
        let id = UUID().uuidString
        for provider in items.flatMap({ $0.attachments ?? [] }) {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
               let url = try? await provider.loadFileRepresentation(for: .image), let data = try? Data(contentsOf: url) {
                try? data.write(to: inbox.appendingPathComponent("\(id).jpg"))
                try? #"{"kind":"image","file":"\#(id).jpg","receivedAt":"\#(stamp)"}"#.write(to: inbox.appendingPathComponent("\(id).json"), atomically: true, encoding: .utf8)
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
                try? #"{"kind":"text","text":"\#(escaped)","receivedAt":"\#(stamp)"}"#.write(to: inbox.appendingPathComponent("\(id).json"), atomically: true, encoding: .utf8)
                return
            }
        }
    }
}
```

`Share/Info.plist`: `NSExtension` with `NSExtensionPointIdentifier` `com.apple.share-services`,
`NSExtensionPrincipalClass` `$(PRODUCT_MODULE_NAME).ShareViewController`, and `NSExtensionAttributes` →
`NSExtensionActivationRule` with `NSExtensionActivationSupportsText` true and `NSExtensionActivationSupportsImageWithMaxCount` 1.

`project.yml`: add the target

```yaml
  TutorCentralShare:
    type: app-extension
    platform: iOS
    sources: [Share]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: in.tutorcentral.app.share
        INFOPLIST_FILE: Share/Info.plist
        CODE_SIGN_ENTITLEMENTS: Share/TutorCentralShare.entitlements
        GENERATE_INFOPLIST_FILE: NO
        TARGETED_DEVICE_FAMILY: "1"
```

and `- target: TutorCentralShare` under the app target's `dependencies` (XcodeGen embeds it). The share extension
has no package dependency in this phase.

Owner step 2 of the phase file: the App ID `in.tutorcentral.app.share` and the app group `group.in.tutorcentral` in
the developer account (the TestFlight lane's cloud signing needs them before the first V2 build; `-allowProvisioningUpdates`
makes the profiles).

- [ ] **Step 4: Generate, build, run the tests; the smoke; commit**

```bash
bun gen && bun check
git add ios && git commit -m "ios: the share extension target, the app group and background refresh"
```

Open PR 6 from `phase-10/share-refresh`. The smoke test still launches; `bun shots today-evening` shows no change
(attach the before and after pictures anyway, as the project's rule 2 asks for a PR that could change what is seen).

### Task 10: As built, state, resume (documents, to `main`)

- [ ] Write "As built" in `plan/phase-10-v2-design-and-foundation.md`: the PRs, the migrations deployed (the run ids),
      what moved from this plan and why.
- [ ] Update `plan/README.md`'s phase row, `plan/STATE.md` (production's migration list, the API commit, the next phase),
      and `docs/design/README.md`'s status table (from Part A).
- [ ] Write `plan/resume/021-phase-11-boards-and-plan.md`: Phase 11 reads the approved 10.2 and 10.3 boards and writes
      its plan (Fable), then its build resume (Opus).
- [ ] Commit the documents directly to `main` (D12) and push.

---

## Self-review (done 2026-10-10)

- Spec coverage: section 9's tables each have a task (1 to 3, 8); the allowance and consent (4); the syllabus data (5);
  the routes (6); the Domain types and figure validators (7); the repositories Phase 11 needs (8); the share extension
  and background refresh (9); the boards for sections 4 to 8 (Part A). Plans, artefacts, school items and marks
  repositories are deferred to their phases by this plan's decisions.
- Placeholders: none; every step carries its code or its exact command.
- Names: `close_session` and `copy_textbook_chapters` match between SQL, tests and Swift; `ClassLevel` raw values match
  the check constraints and the zod enum; `FigureKind` in the API matches `FigureSpec`'s cases.
- Review focus: tests 1 and 2 in Task 1, 3 in Task 2, 4 in Task 3, 5 in Task 4.
