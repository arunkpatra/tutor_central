# Phase 6: AI tools

**Status:** Done (session 13, 2026-10-09): PRs #53 to #60 and #62, the hand run on issue #61, migrations 0006 and 0007 in production, build 0.1.0 (9) on TestFlight. Planned in session 12 (the 44 boards in canvas row 9, `phase-06-plan.md`). **Depends on:** Phase 3 (students and classes feed the forms); Phase 1's API
skeleton; Phase 0's Phase 6 boards approved.

## Goal

The tutor creates a question paper, homework, a worksheet or a progress note in under a minute, turns a
photographed paper register into students, and gets suggested marks for a handwritten answer sheet, with every
result reviewed before it reaches a student or parent.

## Scope

1. **API, for real.** The three routes from Phase 1 get their bodies: Claude with structured outputs
   (`claude-opus-5-5` for checking and scanning, `claude-sonnet-5-5` for generation unless quality says
   otherwise), prompts in `api/src/prompts/` with tests on the schemas, per-centre rate limits in Postgres,
   every call written to `ai_generations`, image inputs validated (type, size), consent checked.
2. **AI Assistant.** Home with the four tools; a form per tool (class or subject, topic, level, length, marks
   for a paper, tone for a note; the student picker for a progress note); generating state with the old result
   kept if there is one; the result as formatted text with copy, share as PDF, regenerate; history under More.
3. **Scan register.** Intro with the notices; consent recorded once per centre; camera or Photos; upload;
   the review table (name, phone, fee per row, editable, delete a row); duplicates against existing students
   flagged; save creates the students; nothing saved before review.
4. **Check a paper.** Intro; capture the answer sheet (one or more pages); the marking scheme (free text or a
   generated paper's key); result with per-question suggested marks and a note; the tutor edits every mark;
   total; save to the student's notes or share; nothing saved before review.
5. **Disclaimers.** "AI can make mistakes" on every result; the consent notice before the first photo.

## Owner steps

1. Anthropic API key into Vercel.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Each tool returns a usable result for the seed's classes; a failure says what happened and offers retry.
- A register photo of ten names becomes ten reviewed students.
- Rate limits hold; `ai_generations` records every call with token counts.
- API tests cover the schemas, the middleware, the consent check and the rate limit.

## As built

Session 13 (2026-10-09), from `resume/012-phase-6-build.md`, executing `phase-06-plan.md` inline with one ledger.
Pull requests: #53 (the database), #54 and #55 (the API; #55 the SDK's named import for Vercel), #56 (Domain and
Data), #57 (AI Assistant, More's row, Today's Create row), #58 (Scan register, D36), #59 (Check a paper), #60 (the
hand run's two focus fixes), #62 (the final review's fixes). The hand run on issue #61. Migrations 0006 (`pending` on
`ai_status`) and 0007 (`start_ai_generation`) in production (deploy run 37829835784); the API at `6eea8b8` (run
37869867840); build 0.1.0 (9) on TestFlight (run 37870068225), the owner's camera scan on the iPhone: "Works". The
rest of the device checks are a tester's, in `docs/testing/device-tests.md`.

**What differs from the plan, and why** (each was a ruling in the build's ledger, with its cost if wrong):

- **The limit cannot be dodged.** The security review of 0007 found a member could delete their rows or mark them
  failed to reset the day's count. 0007 also caps every call started at the limit and a half (60 a day, 30 per kind
  group), revokes DELETE on `ai_generations` and grants UPDATE only on `status`, `output`, `model`, `tokens_in`,
  `tokens_out`; an RLS test holds it. A tutor with many genuine failures meets the cap at 60.
- **A refused answer** (`messages.parse` throws "Failed to parse structured output" before `stop_reason` can be read)
  is a refusal (422) with its tokens null; the output schemas landed with the client in PR 2.
- **A paper's marks always add up:** a real call gave 17 of 20; the API plans the sections (`sectionPlan`) and the
  prompt follows it.
- **Ids** are validated with `z.guid()` (zod 4's `uuid()` refuses the seed's `2222…` ids, which Postgres accepts).
- **The API records `classId` and `studentId`** (not sent to Claude), so a result read back has its class and a note
  its student.
- **The SDK's named export** (`import { Anthropic }`): the default import broke Vercel's CommonJS type check (#55).
- **Shapes the lint asked for:** `ScanAnswer` and `CheckAnswer` structs for the API's answers; `deletedMany` beside
  `deleted` in the students fake; `StudentNoteLine.make` without a calendar; `GenerateRequest.isValid` needs a
  subject (the API refuses an empty one).
- **DesignSystem names:** the AI history row is `ResultRow` (`HistoryRow` is Attendance's); `MarkRow` takes its tile
  as a view (the popover anchors on it); `ReviewRow` takes `tonedLead`; the section title and question number reuse
  `buttonStrong` and `buttonSecondary` (the same values); `CreatingCard` has the scan's photo layout.
- **The register is read by the AI screens** (`AIStore.prepare()`, `ScanStore.read`): only the Students tab read it,
  so names and classes were missing when an AI screen opened first.
- **`PhotoReducer` is in Data** (D36), so Students and AITools both reduce a photo.
- **Fix this row** is the student form in `.fix` mode (five fields, Remove this row; a row's own class); the sheet
  holds its form store in `@State` (the hand run of PR 5 lost typed digits when the list re-rendered).
- **Check a paper's routes carry a visit id** and the shell keeps that visit's `CheckStore`; Share opens the system's
  sheet through `ActivitySheet`.
- **Fixtures:** the generate-failed state uses `.offline` to show the board's words.
- **The hand run's fixes (#60):** Create puts the keyboard away (`Keyboard.dismiss()`), so an at-once failure's error
  row is seen; the whole of an empty multiline well takes a tap, through a layer behind the field (the final review
  asked for that shape, so the field keeps its own gestures).
- **The final review's fixes (#62),** a fresh reviewer on the whole phase, no Critical, six Important, all fixed with a
  test that failed first: a worksheet whose key is off leaves the key out of Copy and the PDF (`Generation.printsKey`);
  Check a paper runs one check at a time and Cancel abandons it (`CheckStore.begin()`, `cancel()`); a server consent
  refusal opens the consent sheet over the failure instead of an endless spinner; Scan's failed Undo is said
  (`undoAdd` answers the words); one 110 s deadline across Claude's two tries, under the app's 125 s, and a timeout is
  its own failure (`APIFailure.timedOut`), not "offline… Nothing was used up". No `maxDuration` is pinned: Vercel runs
  the Hono preset on Fluid compute (300 s). The review's minors are in `plan/sessions/013/record.md`.

**Seen in the real calls (2026-10-09):** a paper in 8 to 9 s on Sonnet 5.5 (about 1,000 tokens in, 1,200 out); the
sample register read right, 8 of 8, in 5 s on Opus 5.5; a two-page check in 21 s, a six-page one in 16 s (16,871
tokens in), under the body limit. No photo is kept: every `ai_generations.input` is under 210 characters.

**Acceptance:** every screen was shot in both appearances beside its board in its pull request; each tool returned a
usable result against the seed, and every failure says what happened and offers Retry; the register sample (eight
names) became seven reviewed students and one flagged as already here; the limit holds (RLS tests); every call is in
`ai_generations` with its tokens; the API's tests cover the schemas, the middleware, the consent check and the limit.
