# Phase 6 AI Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The tutor creates a question paper, homework, a worksheet or a progress note in under a minute, turns a photographed paper register into students they check row by row, and gets suggested marks for a photographed answer sheet they edit before anything is saved; every call goes through our API to Claude with structured outputs, is recorded in `ai_generations`, is limited per centre in Postgres and needs the centre's consent before a child's data leaves the phone; every screen built to its approved Phase 6 board in both appearances; every write proven against the local stack by the runbook (D32); on TestFlight.

**Architecture:** Two migrations (0006 adds `pending` to `ai_status`; 0007 adds `start_ai_generation`, which checks membership, the consent and the day's limit and records the call in one `security invoker` function) with RLS tests. The API (`api/`) gets its bodies: a `ClaudeClient` (the Anthropic SDK, `messages.parse` with zod output formats; a scripted fake for tests and for local runs with `AI_FAKE=1`), a per-request Supabase client carrying the tutor's JWT (so RLS, not the API, decides what is read and written; no service-role key), prompts in `api/src/prompts/`, the three routes rewritten (validate, start, call, finish, answer), image validation by magic bytes and size, errors in words with the status that lets the app say the right thing. In the app, `Domain` gains the generation and result types and the rules (duplicates in a scanned list, marks within bounds and the total, the note line and the notes append, the plain text of a paper); `Data` gains the API client (`AIRepository`), the history read (`AIHistoryRepository`), the consent write, a bulk student insert and delete, a notes update and a `progress` log, each decoded from the local stack's real answer. `Features/AITools` holds the AI Assistant (one `AIStore` per centre on `ShellState`, so a generation outlives its screen), the forms, the results, History, and Check a paper; `Features/Students` holds Scan register (it creates students and reuses the student form for Fix this row). `AppShell` wires the routes, the two consent merges, More's three rows, Today's Create row and 38 launch states. The device reduces every photo to 2000 px on its long edge as a JPEG before it is sent, so six pages fit Vercel's 4.5 MB body.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, `supabase-swift` 2.55.3, VisionKit (`VNDocumentCameraViewController` behind a `UIViewControllerRepresentable`, D8), PhotosUI (`PhotosPicker`), ImageIO (the downscale), `ImageRenderer` into a PDF context (Share as PDF), `ShareLink`; Hono 4.13.13 on Vercel (Node, `bom1`), `@anthropic-ai/sdk` 0.132.1 (pinned; a new dependency, D14: decision D35 below), zod 4.6.5, `@supabase/supabase-js` 2.117.2; Bun tests with `app.request`; the Supabase CLI and `bun test` for RLS; XcodeGen; GitHub Actions (`check`, `deploy`, `testflight`); the simulator runbook (D32).

**Spec:** `docs/spec.md` sections 2, 6 and 7; scope and acceptance in `plan/phase-06-ai-tools.md`; the boards `docs/design/mockups/P6-*.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 9; the list, the launch states and what the boards settle in `docs/design/information-architecture.md`, "Phase 6 boards"); `design-tokens.md` ("Numbers in code", the Phase 6 paragraph); `components.md` ("Phase 6 parts" and its texts); `guidelines.md`; the AI rows and the Scan register row of `docs/reference/functional-inventory.md`; decisions D1 to D34 in `plan/README.md`; Phase 5's "As built" and the rulings in `plan/sessions/011/record.md`; `docs/runbooks/simulator.md` for every hand run; `plan/ui-polish.md` (U9 is offered to the owner, not taken).

## Global Constraints

- iOS 26.0 minimum, iPhone only (D1), bundle id `in.tutorcentral.app` (D27). Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation (D8). Features never import each other: AITools reads the register through Domain's `Register` (D33) and reaches a student's page through `AIToolsActions.openStudent`; Scan register lives in Students because it creates students and reuses `StudentFormSheet`; Check a paper writes a student's notes through `StudentsRepository.updateNotes` (Data) and asks AppShell to refresh the register. UIKit only behind a wrapper with the reason in the file: the document camera (`DocumentCameraView`), because SwiftUI has no camera.
- The lint's shapes (session 11's rulings): no tuple of three or more members (a struct with named fields); at most six parameters to a function (an initialiser may take more; else a struct with an `init`); files under 400 lines (a store over it splits into `+Extension.swift` files; a test struct over 250 lines splits into a second file); no force-unwrap in a test (`try #require(...)`); `@MainActor` on the fakes and the stores; a pure `static func` on a view is `nonisolated`; no one-letter names; `!x.isEmpty` for `count > 0`; lines under 120 columns.
- Concurrency in tests (session 11): an `async let` in a `@MainActor` test does not start until the test suspends: start work in a `Task` and give it 20 ms (`try await Task.sleep(for: .milliseconds(20))`) before asserting the in-flight state; a scripted error set before a store's first read is used up by that read: set it after setup.
- Style only through `DesignSystem` tokens (D10, D25): no raw colour, size, radius, shadow or duration in a feature view; a board value the document does not name becomes a token in `design-tokens.md` and Swift in the same commit; an anatomy number lives as a named constant on its component. Every new component gets a SwiftUI preview.
- Both appearances built and photographed (D13, D23). Every board state is a `LaunchState` whose raw value is the name in `information-architecture.md`'s Phase 6 table; `bun shots <state>` photographs it; every pull request that changes what is seen carries the table `bun pr-shots` prints, for each changed state in both appearances (D7, rule 2). No board, no screen (rule 1): a state this plan did not foresee is drawn and approved first. Where a board settles a layout, a detent or an interaction, the build follows the board; where it shows a figure the fixtures cannot produce, the screen follows the data and the board is not redrawn (the owner, 2026-10-08). The three system surfaces (the camera alert, the document camera, the photo picker) have boards and no launch state.
- Copy: sentence case, no exclamation marks, no emoji, no jargon ("fee" never "invoice"; "AI service" never "LLM" on screen); buttons are verbs with an object; errors say what happened and what to do (`guidelines.md`). The copy of every screen is on its board and in `components.md` ("Phase 6 parts"), word for word; the "AI can make mistakes" line is on every result.
- Secrets (D11): the Anthropic key only in Vercel's environment and `api/.env.local`; the app holds no key and never calls Anthropic; the API never holds the service-role key: every database call it makes carries the tutor's own JWT, so RLS applies. Photos are never stored: not in Storage, not in `ai_generations.input` (which holds the page count and the byte count), not on the API.
- Database (`supabase/CLAUDE.md`): two additive migrations (D26), `20261012000006_ai_status_pending.sql` and `20261013000007_start_ai_generation.sql`; the function is `security invoker`, `set search_path = ''`, grants `authenticated` only; `supabase gen types typescript --local > types.ts` after them; RLS tests pin every rule. They reach production only through `deploy.yml`, before the API (the same run deploys both); the TestFlight lane refuses a build while they are pending, so the deploy runs before the build.
- The API (`api/CLAUDE.md`): `src/index.ts` stays the only file importing `"hono"` among the entry names; relative imports end in `.js`; every `/ai/*` route behind `requireUser`; inputs are zod schemas in `src/schemas.ts`; tests with `app.request`, no network, a fake `ClaudeClient` and a fake `Db`; `bun run check` (tsc and tests) green; dependencies pinned exactly, Bun only (D16), the hoisted linker.
- Models and the call (the `claude-api` skill, read on 2026-10-08): generation on `claude-sonnet-5-5`, scanning and checking on `claude-opus-5-5` (the scope's choice); thinking adaptive (the `thinking` parameter omitted; `budget_tokens` is rejected on these models); `output_config: { effort: "medium" }` for generation and `"high"` for a scan or a check; structured outputs through `client.messages.parse` with `zodOutputFormat(schema)` (zod 4 is accepted by SDK 0.132.1); `max_tokens: 16000`; the SDK client made with `timeout: 120_000` and `maxRetries: 1`; `stop_reason === "refusal"` (checked before the content is read) and a null `parsed_output` are a 422 in words; no `fallbacks` parameter (one model per route, a predictable cost: the decisions table). Images go in a `user` content block before the text, labelled "Page 1:" and so on; the high-resolution tier reads up to 2576 px on the long edge, so 2000 px is within it and costs at most about 4800 visual tokens a page.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/AppShellTests`, `Tests/StudentsTests` and the new `Tests/AIToolsTests` (in `Package.swift` and the scheme in `project.yml`). Stores are tested against the fakes. No UI test suites (D15). Every repository read decodes a fixture copied from what the local stack answered on 2026-10-08 (pasted whole in Task 7); every write path is run in Swift against the local stack before its pull request merges (`ios/CLAUDE.md`: a throwaway test with an in-memory session, deleted before the commit).
- Hand runs (D32): before the TestFlight build, every write path this phase adds is driven through the screens against the local stack and the local API by `docs/runbooks/simulator.md` and confirmed in the database; Task 20 names each run, which ones call the real API (they cost money) and which use the local API with the fake, what the simulator cannot do (the camera: the owner's phone), and the owner's steps.
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). A new decision gets its number in `plan/README.md` in the pull request that acts on it (D35: the SDK dependency; D36: scan register in Students).
- Nothing from the reference app is dropped (rule 10): the inventory's AI rows (the assistant's four tools with form, result, copy, share as PDF, history; check a paper with the tutor editing every mark; scan register with consent recorded and every row editable before save; the "AI can make mistakes" line; Claude through our API) are all placed below.

## Review Focus

Inputs the spec implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **Consent and the limit are the server's, never the app's alone:** a scan, a check or a progress note for a centre without `ai_consent_at` is refused by `start_ai_generation` (the app shows the consent sheet and asks again); the 41st generation in 24 hours is refused with the limit in the answer; failed calls do not count; a paper, homework or worksheet needs no consent. Tests in Task 1 (`rls.test.ts`: `start_ai_generation refuses a scan without consent and allows a paper`, `the limit counts only calls that did not fail`) and Task 3 (`ai.test.ts`: `a missing consent answers 403 in words`, `a reached limit answers 429 with the limit`).
2. **A photo is checked before it costs anything:** a body whose base64 does not decode, whose bytes do not match the declared media type (JPEG `FF D8 FF`, PNG `89 50 4E 47`, WebP `RIFF….WEBP`), that is over 3 MB decoded, or more than six pages, is a 400 before any call; the app reduces every photo to 2000 px on its long edge as a JPEG at 0.7 and refuses to send more than 4,200,000 characters of base64 in one body ("That's too many pages. Up to six, and try sharper, smaller photos."). Tests in Task 3 (`images.test.ts`: `bytes that are not the declared type are refused`, `a seventh page is refused`) and Task 9 (`PhotoReducerTests`: `aLargePhotoComesBackUnder2000pxAsJPEG`, `sixReducedPagesFitTheBody`).
3. **A scanned list never silently adds a child twice or with a wrong number:** a row whose normalised phone (digits, +91 assumed for ten digits) or whose name (case and spaces folded) matches an active student starts unticked with "Already here"; a phone that is not ten digits after normalisation reads "No number read" and is saved as no number, never as a wrong one; a fee that is not a whole number of rupees is dropped; Add writes only the ticked rows in one request and Undo deletes exactly those ids. Tests in Task 5 (`ScanReviewTests`: `aMatchByPhoneOrNameIsFlaggedAndUnticked`, `aBadPhoneBecomesNoNumber`) and Task 15 (`ScanStoreTests`: `addWritesTheTickedRowsOnceAndUndoDeletesThem`).
4. **Marks stay within bounds and the total is always the sum:** a suggested mark above the question's marks is clamped on arrival and the row says so; a mark the tutor sets is 0 to `of`; the total rolls to the sum of the rows; Save appends one line to the student's notes and refuses in words when the 2000 characters would overflow; Undo puts back the notes exactly as they were (a nil stays nil). Tests in Task 5 (`CheckResultTests`: `marksAreClampedAndTheTotalIsTheSum`, `theNoteLineAppendsOrRefuses`) and Task 18 (`CheckStoreTests`: `saveAppendsAndUndoRestoresExactly`).
5. **A generation outlives its screen and only one runs at a time:** leaving the form while creating keeps the call running in the centre's store and the result lands in History and in Recent; a second Create while one runs is refused with "One at a time: the last one is still being written."; a failed call leaves the form filled with Retry; the app's call times out at 125 s and says so. Tests in Task 12 (`AIStoreTests`: `aGenerationSurvivesLeavingTheScreen`, `aSecondCreateWhileOneRunsIsRefused`, `aFailureKeepsTheFormAndOffersRetry`).

---

## Decisions this plan settles

Small and medium things, decided here and written down. Two need a number in `plan/README.md` (D35, D36) in the pull request that acts on them.

| Decision |
|---|
| **D35 (PR 2):** `@anthropic-ai/sdk` 0.132.1 is the API's one new dependency, pinned exactly (D14): the structured-output helper (`messages.parse`, `zodOutputFormat`) and the typed errors are worth more than a hand-written fetch. |
| **D36 (PR 5):** Scan register is built in `Features/Students`, not `Features/AITools`: it creates students, its "+" menu entry is the Students tab's, and Fix this row is the student form (`StudentFormSheet`), which only Students may hold (rule 4). AI Assistant and Check a paper are `Features/AITools`. |
| **Two migrations, no new table.** `ai_generations` from 0001 holds every call: 0006 adds `pending` to `ai_status` (its own file, so the function in 0007 can use the value); 0007 adds `start_ai_generation(p_centre, p_kind, p_input, p_model) returns uuid`, which refuses a non-member (`ai_not_a_member`), a scan, check or progress note without consent (`ai_consent_missing`), and the 41st generation (paper, homework, worksheet, progress_note together) or the 21st scan or the 21st check in the last 24 hours (`ai_limit_reached`, the limit in `detail`), counting rows whose status is not `failed`; it inserts the pending row and returns its id. The API finishes the row with a plain update (output, model, tokens, status) as the user. The limits are constants in the function (D4 keeps paywalls out; these are abuse limits, not a plan). |
| **The consent covers a child's data leaving the phone:** scan register, check a paper and the progress note (it names a child and the parent). A paper, homework or worksheet needs none. The app shows the consent sheet (P6-Scan-Consent, the same sheet over the note form) before the first of those three when `ai_consent_at` is null, writes `centres.ai_consent_at` and merges it through `RootView.applyWorkspace` with `Workspace.takingAIConsent(from:)`; the function is the gate the app cannot skip. |
| **Downscale on the device, no Storage.** `PhotoReducer` (ImageIO) makes every photo a JPEG at most 2000 px on its long edge, quality 0.7 (a page of handwriting is 350 to 900 KB); the app refuses a body over 4,200,000 base64 characters; the schemas cap one image at 4,000,000 characters and the check at six pages and 4,200,000 together; the API checks magic bytes and the decoded size (3 MB). Vercel's body limit (4.5 MB) is never hit by a valid request. Storage would add a bucket, policies, a cleanup job and a second round trip for a photo nobody wants kept. |
| **Models and effort** (Global Constraints): Sonnet 5.5 at medium effort for the four generations (about $0.01 to $0.03 a call), Opus 5.5 at high effort for a scan (one page, about $0.03) and a check (up to six pages, about $0.15 to $0.30). No `fallbacks`: a refusal is a 422 the app shows in words; these prompts do not touch the categories that refuse. |
| **One `ClaudeClient` interface, two implementations:** `anthropicClaude(apiKey)` (the SDK) and `fakeClaude(script)` (tests; `bun run dev` with `AI_FAKE=1`, so a hand run of a failure, a refusal or a slow answer costs nothing and the consent, limit and record paths still run for real against local Supabase). `ANTHROPIC_API_KEY` is read at boot like the Supabase variables (a deployment without it fails its smoke, loudly), except when `AI_FAKE=1`. |
| **The API answers one shape:** `200 { id, result }` (`result` is the kind's output object); `400 { error }` (the body; an image that is not what it says); `401 { error: "sign in again" }`; `403 { error, reason: "consent" }`; `429 { error, limit, kind }`; `422 { error }` (a refusal or an answer that did not fit the schema); `502 { error }` (the AI service failed or timed out). The app maps each to its board's words and never shows a status code. |
| **The call outlives the screen.** `AIStore` is one per centre on `ShellState` (`shell.ai`), holding the forms' drafts per kind, the one in-flight generation (`Task`) with its kind and input, the last results by id, and History's rows. A form's Create hands the store the request and pushes nothing; the store pushes the result route when the answer arrives if the form is still on top, else leaves it in Recent and History. A second Create while one runs is refused in words. Create again on a result runs the same input and keeps the old result until the new one lands. |
| **Results are reopened from the database.** A result screen takes a generation id; the store has it in memory after a call and reads `ai_generations` by id otherwise (History, Recent, a relaunch). `output` is the JSON the API wrote; Domain decodes it by kind. |
| **The paper's answer key is Check a paper's scheme.** A paper's output carries `answer` on every question; "A paper I created" lists the centre's papers, homework and worksheets from History and sends `{ kind: "paper", generationId }`; the API reads that row as the user and builds the scheme text from the questions, marks and answers. "Type it" sends `{ kind: "typed", text }` (4000). |
| **Scan rows and the register:** the API normalises a phone to E.164 when it can (ten digits: +91; twelve starting with 91: +; else null) and the fee to a whole rupee or null; the app's `ScanReview.flag(rows:against:)` marks a row that matches an active student by phone or by folded name as a duplicate (unticked, the match named); Add to names the class (or No class) for every ticked row, a fee read from the page becomes the student's own fee, a missing one means the class fee; Add is one `insert` of the ticked drafts (`StudentsRepository.createMany`), Undo one `delete` of those ids (`deleteMany`); a row's edits stay on the device until Add; Back asks before leaving a list with rows. |
| **Check a paper's writes:** nothing until Save; Save appends "7 Oct · Quadratic equations · 15 of 20 · <summary>" on its own line to `students.notes` through `updateNotes(id:notes:)` (the full text, trimmed to the 2000 limit's rule: when the append would overflow, the save says so and offers Share); the toast's Undo writes the previous notes back exactly. Share is `ShareLink` over the marks as plain text. The student picker lists the register's active students (`Register.activeStudents`). |
| **A progress note's Send:** the Phase 4 message sheet pattern as a DesignSystem part (`MessageSheet`, so AITools need not copy Fees' or Attendance's copies; those two keep theirs, a deferred minor), the note as edited plus the signature, Open WhatsApp logs a `progress` row (`MessageLogRepository.logProgress(centre:studentID:)`) before the link opens and copies the text. |
| **Share as PDF:** `PDFMaker.pdf(for result)` renders the paper card's SwiftUI view through `ImageRenderer` into a PDF context at A4 (595 × 842 pt), paginated by the renderer's height, to a temporary file `Quadratic equations.pdf`; `ShareLink(item:)` offers it. Copy puts `PaperText.plain(result)` on the pasteboard. |
| **The API origin:** `API_ORIGIN` joins `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `Local.xcconfig` (local: `http:/$()/127.0.0.1:3000`), `Info.plist` and `testflight.yml` (the repository variable `API_ORIGIN` already exists for `deploy.yml`; the lane writes it into the xcconfig with the two it writes today). `APIClient` reads it from the bundle and sends `Authorization: Bearer <the Supabase session's access token>` (refreshed by supabase-swift before each call: `client.auth.session`). |
| **The camera:** `DocumentCameraView` wraps `VNDocumentCameraViewController` (full screen cover, the system's own Cancel and Save; one page kept for the register, up to six for a paper; `isSupported` is false in the simulator, where the button shows `CameraAccess.noCameraMessage`); `AVCaptureDevice.requestAccess` first, the refused state shows the toast with Open Settings (`UIApplication.openSettingsURLString`). Photos: `PhotosPicker` (`maxSelectionCount: 1` for the register, 6 for a paper). The usage text in `Info.plist` becomes "To photograph your paper register and answer sheets so they can be read, and the QR of your UPI app." |
| **Sample pictures for the simulator** (the hand runs): `tools/samples/` holds `register-page.png` (a drawn register of eight rows with the boards' names, numbers and fees, one row a duplicate of Dev Kumar, one without a number) and `answer-sheet-1.png`, `answer-sheet-2.png` (two pages of handwritten-style answers to the sample paper), and `blank.png` (a white 64 × 64 page, under 1 KB, for the nothing-found run), made once by `tools/samples/make.swift` (Core Graphics, run with `swift tools/samples/make.swift`) and committed; `xcrun simctl addmedia` puts them in Photos. The owner's phone proves a real paper register and a real answer sheet. |
| **Type names.** Domain: `GenerationKind`, `GenerateRequest` (`.paper(PaperForm)`, `.homework(HomeworkForm)`, `.worksheet(WorksheetForm)`, `.progressNote(NoteForm)`), `Level`, `Tone`, `PaperResult` (`Section`, `Question`), `QuestionSetResult` (homework and worksheet), `NoteResult`, `GenerationResult` (an enum over the four), `Generation` (id, kind, createdAt, title, line, result), `PaperText`, `ScanRow`, `ScanReview`, `ScanRowFlag`, `CheckResult` (`QuestionMark`), `MarkEdit`, `StudentNoteLine`, `NotesAppend`, `SchemeSource`. Data: `AIRepository`, `APIClient`, `APIFailure`, `FakeAIRepository`, `AIHistoryRepository`, `GenerationRow`, `FakeAIHistoryRepository`, `ScanRowDTO`, `CheckResultDTO`. AITools: `AIStore`, `AIToolsActions`, `CheckStore`, `PhotoReducer`, `PDFMaker`, `DocumentCameraView`, `CameraAccess` (moves from Fees to DesignSystem with `QRScannerView`'s sibling: see Task 8). Students: `ScanStore`, `ScanRegisterView` and its pieces. |
| **Fixtures.** `FakeAIHistoryRepository.seed`: the six generations the boards draw (Quadratic equations paper Tue 6 Oct 18:32; Hemanth's note Mon 5 Oct; Photosynthesis worksheet Sat 3 Oct; Linear equations homework Thu 1 Oct; Light and reflection paper Mon 28 Sep; Trigonometry basics worksheet Tue 22 Sep), ids `cccccccc-0000-0000-0000-%012d`, with full results. `FakeAIRepository` answers by script: the paper result (the board's ten questions), the note result (the board's text), the scan rows (the board's eight), the check result (the board's ten marks); `delay` and `failure` for the generating and failed states. `FakeStudentsRepository` gains `createMany`, `deleteMany`, `updateNotes` records. `Fixtures.workspace(for:)` gives the scan and check states a consented centre (`meeraWorkspaceConsented`, `ai_consent_at` 1 Oct) and `scan-consent` an unconsented one. |

## File structure

```
supabase/
  migrations/20261012000006_ai_status_pending.sql, 20261013000007_start_ai_generation.sql, types.ts (regenerated)
  tests/rls.test.ts                                    # + five tests (Task 1)
api/
  package.json (+ @anthropic-ai/sdk 0.132.1), .env.example (+ ANTHROPIC_API_KEY, AI_FAKE)
  src/env.ts (+ ANTHROPIC_API_KEY), src/index.ts (the real claude and db), src/make-app.ts (deps: claude, db)
  src/claude.ts (ClaudeClient, anthropicClaude, ClaudeFailure), src/claude-fake.ts (fakeClaude, the sample answers)
  src/db.ts (Db, makeDb: start, finish, generation(id); DbFailure), src/db-fake.ts
  src/images.ts (decodeImage: base64, magic bytes, size), src/schemas.ts (+ level, withAnswers, the note's context, the scheme, the outputs)
  src/prompts/paper.ts, homework.ts, worksheet.ts, progress-note.ts, scan-register.ts, check-paper.ts, src/prompts/shared.ts (the tutor's voice)
  src/routes/ai.ts (rewritten), src/errors.ts (the one answer shape)
  test/ai.test.ts (replaces the 501 tests in app.test.ts), test/images.test.ts, test/prompts.test.ts, test/schemas.test.ts (+)
tools/samples/make.swift, register-page.png, answer-sheet-1.png, answer-sheet-2.png, blank.png
.github/workflows/testflight.yml (+ API_ORIGIN into the xcconfig)
ios/
  App/Info.plist (+ API_ORIGIN, the camera text), Config/Local.xcconfig.example (+ API_ORIGIN), project.yml (+ AIToolsTests)
  TutorCentralKit/Package.swift (+ AIToolsTests: AITools, Students)
  TutorCentralKit/Sources/Domain/
    Generation.swift (GenerationKind, GenerateRequest, Level, Tone, the forms), GenerationResult.swift (PaperResult, QuestionSetResult, NoteResult, GenerationResult, Generation)
    PaperText.swift, ScanReview.swift (ScanRow, ScanRowFlag, ScanReview), CheckResult.swift (CheckResult, QuestionMark, MarkEdit, SchemeSource)
    StudentNote.swift (StudentNoteLine, NotesAppend), Workspace.swift (+ takingAIConsent), Centre.swift (+ aiConsentAt)
  TutorCentralKit/Sources/Data/
    AI/AIRepository.swift, APIClient.swift, APIFailure.swift, FakeAIRepository.swift, AIHistoryRepository.swift, SupabaseAIHistoryRepository.swift, GenerationRow.swift, FakeAIHistoryRepository.swift
    Centres/CentreRepository.swift (+ recordAIConsent), SupabaseCentreRepository.swift (CentreRow + ai_consent_at), FakeCentreRepository.swift
    Students/StudentsRepository.swift (+ createMany, deleteMany, updateNotes), SupabaseStudentsRepository.swift, FakeStudentsRepository.swift
    Messages/MessageLogRepository.swift (+ logProgress), SupabaseMessageLogRepository.swift, FakeMessageLogRepository.swift
    SupabaseConfig.swift (+ apiOrigin)
  TutorCentralKit/Sources/DesignSystem/Components/
    ToolRows.swift (ToolRow, HistoryRow), CreatingCard.swift, ErrorRow.swift, ResultHero.swift, PaperCard.swift (SectionRow, QuestionRow)
    MarkRow.swift (MarkRow, MarkTile, MarkPicker), ReviewRow.swift, NoticesCard.swift, IntroHero.swift, PageTile.swift (PageTile, AddPageTile), MessageSheet.swift, ConsentSheet.swift, Camera/CameraAccess.swift (from Fees), Camera/DocumentCameraView.swift
  TutorCentralKit/Sources/Features/AITools/
    AIStore.swift, AIStore+Generate.swift, AIToolsActions.swift, AssistantView.swift, GenerateFormView.swift, FormPieces.swift, StudentPickerSheet.swift
    ResultView.swift, ResultFooter.swift, NoteResultView.swift, NoteSendSheet.swift, HistoryView.swift
    CheckStore.swift, CheckStore+Marks.swift, CheckIntroView.swift, CheckPagesView.swift, CheckSchemeView.swift, CheckResultView.swift, CheckingView.swift
    PhotoReducer.swift, PDFMaker.swift, DocumentCameraView.swift, AITools.swift (the marker deleted)
  TutorCentralKit/Sources/Features/Students/
    ScanStore.swift, ScanStore+Add.swift, ScanRegisterView.swift, ScanReviewView.swift, ScanReadingView.swift, FixRowSheet.swift, StudentsActions.swift (openScanRegister → a push of .scanRegister)
  TutorCentralKit/Sources/Features/Fees/PaymentsView.swift (CameraAccess from DesignSystem), QRScannerView.swift (CameraAccess removed)
  TutorCentralKit/Sources/AppShell/
    RootView+AITools.swift (new: the store, the routes, the actions, the consent merge), RootView+Students.swift (scan register), RootView+Today.swift (openAI), MoreView.swift (three rows live)
    TabsState.swift (+ routes), TabsView.swift (+ destinations), ShellState.swift (+ ai), Dependencies.swift (+ ai, aiHistory), LaterView.swift (scanRegister removed: the enum becomes empty and the file goes)
    LaunchState.swift (+38), RootView+LaunchStates.swift, Fixtures.swift (+ ai), Fixtures+AI.swift (new)
  TutorCentralKit/Tests/DomainTests/GenerationTests.swift, GenerationResultTests.swift, PaperTextTests.swift, ScanReviewTests.swift, CheckResultTests.swift, StudentNoteTests.swift, WorkspaceTests.swift (+ consent)
  TutorCentralKit/Tests/DataTests/GenerationRowTests.swift, APIClientTests.swift, CentreRowTests.swift (+ consent), StudentWriteRowTests.swift, ProgressLogRowTests.swift
  TutorCentralKit/Tests/AIToolsTests/AIStoreTests.swift, AIStoreGenerateTests.swift, CheckStoreTests.swift, PhotoReducerTests.swift, PDFMakerTests.swift
  TutorCentralKit/Tests/StudentsTests/ScanStoreTests.swift
  TutorCentralKit/Tests/AppShellTests/LaunchStateTests.swift (+ Phase 6), TabsStateTests.swift (+ routes)
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-6/db` | Database: `pending` on `ai_status`, `start_ai_generation` (consent, the day's limit, the record); the RLS tests; types | none |
| 2 | 2, 3, 4 | `phase-6/api` | The API for real: Claude with structured outputs, the prompts, image checks, the per-request Supabase client, the routes, the fake for tests and local runs (D35) | none |
| main | | | `gh workflow run deploy` after PR 2 (the migrations, then the API): the owner's key is in Vercel first (Task 20, steps 1 and 2) | |
| 3 | 5, 6, 7 | `phase-6/domain-data` | Domain: generations, results, the scan review, marks, the note line; Data: the API client, history, consent, bulk students, notes, the progress log, every answer decoded; `API_ORIGIN` | none |
| 4 | 8 to 13 | `phase-6/assistant` | AI Assistant: the home, the four forms, the student picker, creating, results, create again, the note on WhatsApp, History; More's rows; Today's Create row | `ai-assistant`, `ai-assistant-empty`, `ai-paper`, `ai-homework`, `ai-worksheet`, `ai-note`, `ai-note-student`, `ai-generating`, `ai-generate-failed`, `ai-result-paper`, `ai-result-regenerating`, `ai-result-note`, `ai-note-send`, `ai-history`, `ai-history-empty`, `more`, `today-ai`, both appearances |
| 5 | 14, 15, 16 | `phase-6/scan-register` | Scan register: the intro, the consent, the camera and Photos, reading, the list to check, Fix this row, Undo, leaving, nothing found, failure, added (D36) | `scan-intro`, `scan-consent`, `scan-camera-refused`, `scan-reading`, `scan-review`, `scan-review-edit`, `scan-review-removed`, `scan-review-leave`, `scan-nothing`, `scan-failed`, `scan-saved`, `students-add-menu`, `students-empty`, both |
| 6 | 17, 18, 19 | `phase-6/check-paper` | Check a paper: the intro, the pages, the scheme, checking, the marks, changing one, saved, failure | `check-intro`, `check-pages`, `check-scheme`, `check-scheme-typed`, `check-checking`, `check-result`, `check-mark-picker`, `check-result-edited`, `check-saved`, `check-failed`, both |
| main | 20 | | The hand runs, TestFlight, the owner's phone check; as built, state, record, resume (documents only, D12) | |

---

### Task 1: The database: `pending`, `start_ai_generation`, the RLS tests, the types (PR 1)

**Files:**
- Create: `supabase/migrations/20261012000006_ai_status_pending.sql`, `supabase/migrations/20261013000007_start_ai_generation.sql`
- Modify: `supabase/tests/rls.test.ts` (five tests at the end, before the catalogue probe), `supabase/types.ts` (regenerated)

**Interfaces:**
- Consumes: `ai_generations`, `ai_kind`, `ai_status`, `centres.ai_consent_at`, `is_member` (migration 0001).
- Produces: `public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text) returns uuid`, raising `ai_not_a_member`, `ai_consent_missing` or `ai_limit_reached` (with the limit in `detail`); the enum value `pending`. The API (Task 3) calls it by `rpc` and finishes the row with an update.

- [ ] **Step 1: Write the failing tests** (appended to `supabase/tests/rls.test.ts` before `anonymous gets no grant…`):

```ts
test("start_ai_generation records a pending call for a member and refuses a non-member", async () => {
  const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: { topic: "Fractions" }, p_model: "claude-sonnet-5-5" });
  expect(r.error).toBeNull();
  const row = await a.from("ai_generations").select("kind, status, input, model, output").eq("id", r.data as string).single();
  expect(row.data).toEqual({ kind: "paper", status: "pending", input: { topic: "Fractions" }, model: "claude-sonnet-5-5", output: null });
  const theirs = await b.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
  expect(theirs.error?.message).toContain("ai_not_a_member");
  // The member finishes the row with a plain update; the other user cannot see it.
  const done = await a.from("ai_generations").update({ status: "ok", output: "{}", tokens_in: 10, tokens_out: 20 }).eq("id", r.data as string).select("status, tokens_in").single();
  expect(done.data).toEqual({ status: "ok", tokens_in: 10 });
  expect((await b.from("ai_generations").select("id").eq("id", r.data as string)).data).toEqual([]);
});

test("start_ai_generation refuses a scan without consent and allows a paper", async () => {
  await a.from("centres").update({ ai_consent_at: null }).eq("id", centreA);
  for (const kind of ["scan_register", "check_paper", "progress_note"]) {
    const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: kind, p_input: {}, p_model: "m" });
    expect(r.error?.message).toContain("ai_consent_missing");
  }
  expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "homework", p_input: {}, p_model: "m" })).error).toBeNull();
  await a.from("centres").update({ ai_consent_at: new Date().toISOString() }).eq("id", centreA);
  expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "scan_register", p_input: {}, p_model: "m" })).error).toBeNull();
});

test("the limit counts only calls that did not fail, per kind group, over 24 hours", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    // 40 generations in the last day (two of them failed, which do not count), and one older than a day.
    await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at)
      select ${centreA}::uuid, 'worksheet', '{}', 'ok', now() - interval '1 hour' from generate_series(1, 38)`;
    await sql`insert into public.ai_generations (centre_id, kind, input, status) values (${centreA}, 'paper', '{}', 'failed'), (${centreA}, 'paper', '{}', 'failed')`;
    await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at) values (${centreA}, 'paper', '{}', 'ok', now() - interval '25 hours')`;
    const thirtyNinth = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "progress_note", p_input: {}, p_model: "m" });
    expect(thirtyNinth.error).toBeNull();
    const fortieth = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    expect(fortieth.error).toBeNull();
    const fortyFirst = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    expect(fortyFirst.error?.message).toContain("ai_limit_reached");
    expect(fortyFirst.error?.details).toBe("40");
    // Scans have their own count of 20, untouched by the generations.
    expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "scan_register", p_input: {}, p_model: "m" })).error).toBeNull();
    await sql`insert into public.ai_generations (centre_id, kind, input, status) select ${centreA}::uuid, 'check_paper', '{}', 'ok' from generate_series(1, 20)`;
    const check = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "check_paper", p_input: {}, p_model: "m" });
    expect(check.error?.details).toBe("20");
  } finally {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    await sql.close();
  }
});

test("a refused start leaves no row", async () => {
  const before = (await a.from("ai_generations").select("id").eq("centre_id", centreA)).data?.length ?? 0;
  await a.from("centres").update({ ai_consent_at: null }).eq("id", centreA);
  await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "check_paper", p_input: {}, p_model: "m" });
  expect((await a.from("ai_generations").select("id").eq("centre_id", centreA)).data?.length).toBe(before);
});

test("ai_status has pending and anonymous cannot start a generation", async () => {
  const sql = new SQL(l.db);
  const values = await sql`select enumlabel from pg_enum where enumtypid = 'public.ai_status'::regtype order by enumsortorder`;
  expect([...values].map((v) => v.enumlabel)).toEqual(["ok", "failed", "pending"]);
  await sql.close();
  const anon = anonClient(l);
  expect((await anon.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" })).error).not.toBeNull();
});
```

- [ ] **Step 2: Run to see them fail.** `cd supabase && supabase db reset && bun test tests` → the five fail (no function, no `pending`).

- [ ] **Step 3: The migrations**

`supabase/migrations/20261012000006_ai_status_pending.sql`:

```sql
-- A call that has started and not yet answered (start_ai_generation, migration 0007). Its own migration: a new enum
-- value cannot be used in the transaction that adds it.
alter type public.ai_status add value 'pending';
```

`supabase/migrations/20261013000007_start_ai_generation.sql`:

```sql
-- One call before an AI call: the member check, the consent for a child's data (a scan, a check, a progress note), the
-- day's limit per kind group (40 generations; 20 scans; 20 checks; failed calls do not count), and the pending record.
-- The API finishes the row with a plain update as the user (docs/spec.md section 6).
create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
  v_id uuid;
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
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
  select count(*) into v_count from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.status <> 'failed'
     and g.created_at >= now() - interval '24 hours';
  if v_count >= v_limit then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) from public;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) to authenticated;
```

- [ ] **Step 4: Run to see them pass.** `supabase db reset && bun test tests` → green, the catalogue tests included (the function grants nothing to `anon` or `PUBLIC`).

- [ ] **Step 5: Types.** `supabase gen types typescript --local > types.ts`; `git diff types.ts` shows `pending` and the function.

- [ ] **Step 6: Commit and open PR 1.** `bun check --only=db` green. `git add supabase && git commit -m "Database: pending on ai_status, start_ai_generation with the consent and the day's limit; RLS tests"`, push, `gh pr create`, merge when green.

### Task 2: The API's Claude client, its fake, the database client, the errors (PR 2)

**Files:**
- Create: `api/src/claude.ts`, `api/src/claude-fake.ts`, `api/src/db.ts`, `api/src/db-fake.ts`, `api/src/errors.ts`
- Modify: `api/package.json` (`"@anthropic-ai/sdk": "0.132.1"` under dependencies; `bun install`), `api/.env.example`, `api/src/env.ts`
- Test: `api/test/claude-fake.test.ts`, `api/test/db-fake.test.ts`

**Interfaces:**
- Consumes: `env(name)` (Task 2 widens its union), `@supabase/supabase-js`, `@anthropic-ai/sdk`.
- Produces:

```ts
// src/claude.ts
import type { ZodType } from "zod";
export type ImageInput = { mediaType: "image/jpeg" | "image/png" | "image/webp"; base64: string };
export type ClaudeRequest<T> = {
  model: "claude-sonnet-5-5" | "claude-opus-5-5";
  effort: "medium" | "high";
  system: string;
  text: string;            // the user turn's text, after the images
  images?: ImageInput[];   // "Page 1:" … before the text
  schema: ZodType<T>;      // the structured output
};
export type ClaudeAnswer<T> =
  | { kind: "ok"; parsed: T; model: string; tokensIn: number; tokensOut: number }
  | { kind: "refused"; model: string; tokensIn: number; tokensOut: number }   // stop_reason refusal, or parsed_output null
  | { kind: "failed"; reason: string };                                        // the SDK threw, or timed out
export type ClaudeClient = { complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> };
export function anthropicClaude(apiKey: string): ClaudeClient;   // messages.parse, output_config { effort, format: zodOutputFormat(schema) }, max_tokens 16000, timeout 120_000, maxRetries 1

// src/claude-fake.ts
export type FakeScript = { answer?: unknown; refuse?: boolean; fail?: string; delayMs?: number };
export function fakeClaude(script: FakeScript | ((request: ClaudeRequest<unknown>) => FakeScript)): ClaudeClient & { requests: ClaudeRequest<unknown>[] };
export const SAMPLE: { paper: unknown; homework: unknown; worksheet: unknown; progress_note: unknown; scan_register: unknown; check_paper: unknown };  // the boards' results, parse under each output schema

// src/db.ts
export type Db = {
  start(token: string, args: { centre: string; kind: AIKind; input: unknown; model: string }): Promise<string>;   // the row id; throws DbFailure
  finish(token: string, id: string, result: { status: "ok" | "failed"; output: string | null; model: string; tokensIn: number | null; tokensOut: number | null }): Promise<void>;
  generation(token: string, id: string): Promise<{ id: string; kind: AIKind; output: string | null } | null>;   // for the scheme from a paper
};
export type AIKind = "paper" | "homework" | "worksheet" | "progress_note" | "scan_register" | "check_paper";
export class DbFailure extends Error { constructor(public readonly reason: "not_a_member" | "consent" | "limit" | "other", public readonly limit?: number) }
export function makeDb(supabaseUrl: string, anonKey: string): Db;   // createClient per call with { global: { headers: { Authorization: `Bearer ${token}` } }, auth: { persistSession: false, autoRefreshToken: false } }

// src/db-fake.ts
export function fakeDb(options?: { consent?: boolean; limit?: number; generations?: Record<string, { kind: AIKind; output: string | null }> }): Db & { started: unknown[]; finished: unknown[] };

// src/errors.ts
export type ApiError = { status: 400 | 401 | 403 | 422 | 429 | 502; body: Record<string, unknown> };
export const errors: {
  consent: () => ApiError;            // 403 { error: "Agree to the notice before the first photo.", reason: "consent" }
  limit: (kind: AIKind, limit: number) => ApiError;   // 429 { error: "You've made today's 40. Try again tomorrow.", limit, kind }
  refused: (kind: AIKind) => ApiError; // 422 { error: "Couldn't make this one. Change the topic and try again." } (a scan: "Couldn't read this photo. Try another."; a check: "Couldn't check these pages. Try clearer photos.")
  service: () => ApiError;            // 502 { error: "The AI service didn't answer. Try again." }
  badImage: (why: string) => ApiError; // 400 { error: why }
};
```

- [ ] **Step 1: Write the failing tests**

`api/test/claude-fake.test.ts`:

```ts
import { expect, test } from "bun:test";
import { z } from "zod";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { PaperOutput } from "../src/schemas.js";

const request = { model: "claude-sonnet-5-5" as const, effort: "medium" as const, system: "s", text: "t", schema: PaperOutput };

test("the fake answers what its script says and records the request", async () => {
  const ok = fakeClaude({ answer: SAMPLE.paper });
  const r = await ok.complete(request);
  expect(r.kind).toBe("ok");
  if (r.kind === "ok") expect(r.parsed.title).toBe("Quadratic equations");
  expect(ok.requests).toHaveLength(1);
  expect((await fakeClaude({ refuse: true }).complete(request)).kind).toBe("refused");
  const failed = await fakeClaude({ fail: "timeout" }).complete(request);
  expect(failed).toEqual({ kind: "failed", reason: "timeout" });
});

test("the fake's sample answers fit their schemas", () => {
  expect(PaperOutput.safeParse(SAMPLE.paper).success).toBe(true);
  expect(z.object({ note: z.string() }).safeParse(SAMPLE.progress_note).success).toBe(true);
});

test("a script can depend on the request", async () => {
  const byModel = fakeClaude((r) => (r.model === "claude-opus-5-5" ? { answer: SAMPLE.scan_register } : { refuse: true }));
  expect((await byModel.complete({ ...request, model: "claude-opus-5-5", schema: z.any() })).kind).toBe("ok");
  expect((await byModel.complete(request)).kind).toBe("refused");
});
```

`api/test/db-fake.test.ts`:

```ts
import { expect, test } from "bun:test";
import { fakeDb } from "../src/db-fake.js";
import { DbFailure } from "../src/db.js";

test("the fake db starts, finishes and refuses as the function would", async () => {
  const db = fakeDb({ consent: false });
  const id = await db.start("tok", { centre: "c", kind: "paper", input: {}, model: "m" });
  expect(db.started).toHaveLength(1);
  await db.finish("tok", id, { status: "ok", output: "{}", model: "m", tokensIn: 1, tokensOut: 2 });
  expect(db.finished[0]).toMatchObject({ id, status: "ok" });
  await expect(db.start("tok", { centre: "c", kind: "scan_register", input: {}, model: "m" })).rejects.toBeInstanceOf(DbFailure);
  const limited = fakeDb({ limit: 0 });
  const err = await limited.start("tok", { centre: "c", kind: "paper", input: {}, model: "m" }).catch((e) => e as DbFailure);
  expect(err).toMatchObject({ reason: "limit", limit: 0 });
  const withPaper = fakeDb({ generations: { g1: { kind: "paper", output: '{"title":"x"}' } } });
  expect(await withPaper.generation("tok", "g1")).toEqual({ id: "g1", kind: "paper", output: '{"title":"x"}' });
  expect(await withPaper.generation("tok", "nope")).toBeNull();
});
```

- [ ] **Step 2: Run to see them fail.** `cd api && bun test` → the modules do not exist.

- [ ] **Step 3: Implement.** `bun add --exact @anthropic-ai/sdk@0.132.1`. `env.ts`'s union becomes `"SUPABASE_URL" | "SUPABASE_ANON_KEY" | "ANTHROPIC_API_KEY"`. `.env.example` gains `ANTHROPIC_API_KEY=` and `# AI_FAKE=1 answers from the fake instead of Claude (local runs that must not cost money)`.

`src/claude.ts` (the real client; every name from the skill's TypeScript reference):

```ts
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import type { ZodType } from "zod";

export type ImageInput = { mediaType: "image/jpeg" | "image/png" | "image/webp"; base64: string };
export type ClaudeRequest<T> = {
  model: "claude-sonnet-5-5" | "claude-opus-5-5";
  effort: "medium" | "high";
  system: string;
  text: string;
  images?: ImageInput[];
  schema: ZodType<T>;
};
export type ClaudeAnswer<T> =
  | { kind: "ok"; parsed: T; model: string; tokensIn: number; tokensOut: number }
  | { kind: "refused"; model: string; tokensIn: number; tokensOut: number }
  | { kind: "failed"; reason: string };
export type ClaudeClient = { complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> };

/** One call per request: images first ("Page 1:" and so on), then the text; the answer parsed against the schema. A
 *  refusal (stop_reason) or an answer that did not fit is "refused"; anything the SDK throws is "failed" in a word. */
export function anthropicClaude(apiKey: string): ClaudeClient {
  const client = new Anthropic({ apiKey, timeout: 120_000, maxRetries: 1 });
  return {
    async complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> {
      const content: Anthropic.ContentBlockParam[] = [];
      (request.images ?? []).forEach((image, i) => {
        content.push({ type: "text", text: `Page ${i + 1}:` });
        content.push({ type: "image", source: { type: "base64", media_type: image.mediaType, data: image.base64 } });
      });
      content.push({ type: "text", text: request.text });
      try {
        const response = await client.messages.parse({
          model: request.model,
          max_tokens: 16000,
          system: request.system,
          output_config: { effort: request.effort, format: zodOutputFormat(request.schema) },
          messages: [{ role: "user", content }],
        });
        const tokens = { tokensIn: response.usage.input_tokens, tokensOut: response.usage.output_tokens };
        if (response.stop_reason === "refusal" || response.parsed_output == null) {
          return { kind: "refused", model: response.model, ...tokens };
        }
        return { kind: "ok", parsed: response.parsed_output, model: response.model, ...tokens };
      } catch (e) {
        const reason = e instanceof Anthropic.APIError ? `api ${e.status}` : (e as Error).name === "APIConnectionTimeoutError" ? "timeout" : "error";
        console.error("claude", reason, (e as Error).message);
        return { kind: "failed", reason };
      }
    },
  };
}
```

`src/claude-fake.ts`: `fakeClaude(script)` resolves the script (a function gets the request), waits `delayMs`, returns `{ kind: "failed", reason: fail }`, `{ kind: "refused", model: request.model, tokensIn: 100, tokensOut: 0 }` or `{ kind: "ok", parsed: request.schema.parse(answer), model: request.model, tokensIn: 812, tokensOut: 1460 }`, pushing the request onto `requests`. `SAMPLE` holds the six answers: the paper from P6-Result-Paper (ten questions in sections A, B and C with marks and answers), the homework and worksheet as five and twelve questions with answers, the note from P6-Result-ProgressNote, the eight scan rows of P6-Scan-Review (phones as read: "9876543210", "99887 76655", "", "90080 11223" …; Dev Kumar's as "+91 98848 43831"), the ten marks of P6-Check-Result.

`src/db.ts`: `makeDb` keeps `url` and `anon`; `client(token)` is `createClient(url, anon, { global: { headers: { Authorization: \`Bearer ${token}\` } }, auth: { persistSession: false, autoRefreshToken: false } })`; `start` calls `rpc("start_ai_generation", { p_centre, p_kind, p_input, p_model })` and maps an error whose message contains `ai_not_a_member` to `DbFailure("not_a_member")`, `ai_consent_missing` to `DbFailure("consent")`, `ai_limit_reached` to `DbFailure("limit", Number(error.details))`, anything else to `DbFailure("other")`; `finish` is `from("ai_generations").update({ status, output, model, tokens_in, tokens_out }).eq("id", id)` (an error is logged and swallowed: the tutor has their result; the row stays pending and counts against the limit, which is the safe side); `generation` is `from("ai_generations").select("id, kind, output").eq("id", id).maybeSingle()` mapped to the type.

`src/db-fake.ts`: an in-memory `Db` with `consent` (default true), `limit` (default 40), a counter, `generations`, `started` and `finished` arrays; `start` throws `DbFailure("consent")` for the three kinds when consent is false, `DbFailure("limit", limit)` when the count reaches it, else returns `gen-<n>`.

`src/errors.ts` as the interface above, the words exactly as `components.md` ("Phase 6 parts", the error row and the limit).

- [ ] **Step 4: Run to see them pass.** `bun test` green; `bun run check` (tsc) green.

- [ ] **Step 5: Commit.** `git add api && git commit -m "API: the Claude client with structured outputs, its fake, the per-request database client, the error words"`.

### Task 3: The schemas, the images, the prompts (PR 2)

**Files:**
- Create: `api/src/images.ts`, `api/src/prompts/shared.ts`, `paper.ts`, `homework.ts`, `worksheet.ts`, `progress-note.ts`, `scan-register.ts`, `check-paper.ts`
- Modify: `api/src/schemas.ts`
- Test: `api/test/schemas.test.ts` (extended), `api/test/images.test.ts`, `api/test/prompts.test.ts`

**Interfaces:**
- Consumes: `ClaudeRequest`, `ImageInput` (Task 2).
- Produces:

```ts
// src/schemas.ts (the inputs the app sends)
export const Level = z.enum(["easy", "medium", "hard"]);
export const GenerateInput = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("paper"), subject, classLevel, topic, level: Level.default("medium"), marks: z.number().int().min(5).max(100).default(20), questions: z.number().int().min(1).max(50).default(10) }),
  z.object({ kind: z.literal("homework"), subject, classLevel, topic, level: Level.default("medium"), questions: z.number().int().min(1).max(30).default(5) }),
  z.object({ kind: z.literal("worksheet"), subject, classLevel, topic, level: Level.default("medium"), questions: z.number().int().min(1).max(40).default(10), withAnswers: z.boolean().default(true) }),
  z.object({ kind: z.literal("progress_note"), subject, classLevel, studentName: z.string().min(1).max(80), parentName: z.string().max(80).optional(), observations: z.string().min(1).max(2000), attendanceLine: z.string().max(120).optional(), tone: z.enum(["warm", "plain"]).default("warm"), tutorName: z.string().max(80), centreName: z.string().max(120) }),
]);
const Image = z.object({ imageBase64: z.string().min(1).max(4_000_000), mediaType: z.enum(["image/jpeg", "image/png", "image/webp"]) });
export const ScanRegisterInput = Image;
export const Scheme = z.discriminatedUnion("kind", [z.object({ kind: z.literal("typed"), text: z.string().min(1).max(4000) }), z.object({ kind: z.literal("paper"), generationId: z.string().uuid() })]);
export const CheckPaperInput = z.object({ pages: z.array(Image).min(1).max(6), scheme: Scheme, studentName: z.string().min(1).max(80) })
  .refine((v) => v.pages.reduce((n, p) => n + p.imageBase64.length, 0) <= 4_200_000, { message: "pages: too many characters in one request" });
// the outputs Claude is held to
export const PaperOutput = z.object({ title: z.string(), sections: z.array(z.object({ title: z.string(), marksEach: z.number().int().min(1), questions: z.array(z.object({ number: z.number().int().min(1), text: z.string(), marks: z.number().int().min(1), answer: z.string() })).min(1) })).min(1) });
export const QuestionSetOutput = z.object({ title: z.string(), instructions: z.string().nullable(), questions: z.array(z.object({ number: z.number().int().min(1), text: z.string(), answer: z.string() })).min(1) });
export const NoteOutput = z.object({ note: z.string().min(1) });
export const ScanOutput = z.object({ rows: z.array(z.object({ name: z.string().min(1), phone: z.string().nullable(), fee: z.number().int().min(0).nullable() })) });
export const CheckOutput = z.object({ questions: z.array(z.object({ number: z.number().int().min(1), text: z.string(), note: z.string(), marks: z.number().int().min(0), of: z.number().int().min(1) })).min(1), summary: z.string() });
export type GenerateInput = z.infer<typeof GenerateInput>; // and the others

// src/images.ts
export type DecodedImage = ImageInput & { bytes: number };
export function decodeImage(image: { imageBase64: string; mediaType: ImageInput["mediaType"] }): DecodedImage | string;   // a string is the refusal in words: "That photo isn't a JPEG, PNG or WebP.", "That photo is over 3 MB.", "That photo didn't arrive whole."
export const MAX_IMAGE_BYTES = 3 * 1024 * 1024;

// src/prompts/*.ts: each exports
export function request(input: <its input>, extra?: …): ClaudeRequest<<its output>>;   // model, effort, system, text (and images), schema
export function normalisePhone(raw: string | null): string | null;   // scan-register.ts: digits only; 10 → "+91" + digits; 12 starting "91" → "+" + digits; else null
export function schemeText(output: unknown, kind: AIKind): string | null;   // check-paper.ts: from a stored paper/homework/worksheet output
```

- [ ] **Step 1: Write the failing tests**

`api/test/schemas.test.ts` gains:

```ts
test("GenerateInput takes the level, the worksheet's answer switch and the note's context", () => {
  const paper = GenerateInput.parse({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" });
  expect(paper).toMatchObject({ level: "medium", marks: 20, questions: 10 });
  expect(GenerateInput.safeParse({ kind: "paper", subject: "M", classLevel: "C", topic: "T", level: "brutal" }).success).toBe(false);
  expect(GenerateInput.parse({ kind: "worksheet", subject: "M", classLevel: "C", topic: "T" })).toMatchObject({ withAnswers: true, questions: 10 });
  const note = GenerateInput.parse({ kind: "progress_note", subject: "Mathematics", classLevel: "Class 10 Maths", studentName: "Hemanth Reddy", parentName: "Lakshmi Reddy", observations: "Improving", attendanceLine: "2 of 3 classes attended", tutorName: "Meera Nair", centreName: "Bright Minds Tuition" });
  expect(note).toMatchObject({ tone: "warm" });
  expect(GenerateInput.safeParse({ kind: "progress_note", subject: "M", classLevel: "C", studentName: "H", observations: "x".repeat(2001), tutorName: "M", centreName: "B" }).success).toBe(false);
});

test("CheckPaperInput takes a typed scheme or a paper's id, and caps the pages together", () => {
  const page = { imageBase64: "A".repeat(1_000_000), mediaType: "image/jpeg" };
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "typed", text: "Q1 (1) b" }, studentName: "Hemanth Reddy" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "paper", generationId: "fbc6ae19-2769-4934-bf10-c830207fd6a3" }, studentName: "H" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "paper", generationId: "not-a-uuid" }, studentName: "H" }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: Array(5).fill(page), scheme: { kind: "typed", text: "x" }, studentName: "H" }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: Array(7).fill({ ...page, imageBase64: "A" }), scheme: { kind: "typed", text: "x" }, studentName: "H" }).success).toBe(false);
});

test("the outputs hold Claude to the shape the app decodes", () => {
  expect(PaperOutput.safeParse({ title: "T", sections: [{ title: "A", marksEach: 1, questions: [{ number: 1, text: "q", marks: 1, answer: "a" }] }] }).success).toBe(true);
  expect(PaperOutput.safeParse({ title: "T", sections: [] }).success).toBe(false);
  expect(ScanOutput.safeParse({ rows: [{ name: "Aarav Mehta", phone: null, fee: null }] }).success).toBe(true);
  expect(CheckOutput.safeParse({ questions: [{ number: 1, text: "q", note: "n", marks: 2, of: 1 }], summary: "s" }).success).toBe(true, "a mark over its maximum is clamped by the app, not refused here");
});
```

`api/test/images.test.ts`:

```ts
import { expect, test } from "bun:test";
import { decodeImage, MAX_IMAGE_BYTES } from "../src/images.js";

const b64 = (bytes: number[]) => Buffer.from(bytes).toString("base64");
const jpeg = b64([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const png = b64([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const webp = b64([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]);

test("bytes that are not the declared type are refused", () => {
  expect(decodeImage({ imageBase64: jpeg, mediaType: "image/jpeg" })).toMatchObject({ mediaType: "image/jpeg", bytes: 8 });
  expect(decodeImage({ imageBase64: png, mediaType: "image/png" })).toMatchObject({ bytes: 8 });
  expect(decodeImage({ imageBase64: webp, mediaType: "image/webp" })).toMatchObject({ bytes: 12 });
  expect(decodeImage({ imageBase64: png, mediaType: "image/jpeg" })).toBe("That photo isn't a JPEG, PNG or WebP.");
  expect(decodeImage({ imageBase64: b64([1, 2, 3, 4]), mediaType: "image/png" })).toBe("That photo isn't a JPEG, PNG or WebP.");
});

test("base64 that does not decode, and a photo over 3 MB, are refused", () => {
  expect(decodeImage({ imageBase64: "!!!!", mediaType: "image/jpeg" })).toBe("That photo didn't arrive whole.");
  const big = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(MAX_IMAGE_BYTES)]).toString("base64");
  expect(decodeImage({ imageBase64: big, mediaType: "image/jpeg" })).toBe("That photo is over 3 MB.");
});
```

`api/test/prompts.test.ts`:

```ts
import { expect, test } from "bun:test";
import { request as paper } from "../src/prompts/paper.js";
import { request as note } from "../src/prompts/progress-note.js";
import { normalisePhone, request as scan } from "../src/prompts/scan-register.js";
import { request as check, schemeText } from "../src/prompts/check-paper.js";
import { GenerateInput } from "../src/schemas.js";

test("a paper asks Sonnet at medium effort for sections, marks and answers that add up", () => {
  const r = paper(GenerateInput.parse({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" }));
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.effort).toBe("medium");
  expect(r.text).toContain("Quadratic equations");
  expect(r.text).toContain("20 marks");
  expect(r.system).toContain("Indian");
  expect(r.images).toBeUndefined();
});

test("a progress note is written to the parent in the tutor's voice, with the attendance line when given", () => {
  const input = GenerateInput.parse({ kind: "progress_note", subject: "Mathematics", classLevel: "Class 10 Maths", studentName: "Hemanth Reddy", parentName: "Lakshmi Reddy", observations: "Careless with signs", attendanceLine: "2 of 3 classes attended", tutorName: "Meera Nair", centreName: "Bright Minds Tuition" });
  if (input.kind !== "progress_note") throw new Error("kind");
  const r = note(input);
  expect(r.text).toContain("Lakshmi");
  expect(r.text).toContain("2 of 3 classes attended");
  expect(r.system).toContain("no signature");
});

test("a scan asks Opus at high effort with the page first, and phones are normalised to +91", () => {
  const r = scan({ mediaType: "image/jpeg", base64: "AAAA", bytes: 3 });
  expect(r.model).toBe("claude-opus-5-5");
  expect(r.effort).toBe("high");
  expect(r.images?.[0]?.base64).toBe("AAAA");
  expect(normalisePhone("98765 43210")).toBe("+919876543210");
  expect(normalisePhone("+91 98848 43831")).toBe("+919884843831");
  expect(normalisePhone("919884843831")).toBe("+919884843831");
  expect(normalisePhone("4321")).toBeNull();
  expect(normalisePhone(null)).toBeNull();
});

test("a check sends every page in order with the scheme text; a paper's output becomes a scheme", () => {
  const pages = [1, 2].map((n) => ({ mediaType: "image/png" as const, base64: `P${n}`, bytes: 2 }));
  const r = check(pages, "Q1 (1) b", "Hemanth Reddy");
  expect(r.images?.map((i) => i.base64)).toEqual(["P1", "P2"]);
  expect(r.text).toContain("Q1 (1) b");
  const stored = JSON.stringify({ title: "Quadratic equations", sections: [{ title: "Section A", marksEach: 1, questions: [{ number: 1, text: "Which…", marks: 1, answer: "b" }] }] });
  expect(schemeText(JSON.parse(stored), "paper")).toBe("Quadratic equations\nQ1 (1 mark) Which… → b");
  expect(schemeText({ title: "H", instructions: null, questions: [{ number: 1, text: "q", answer: "a" }] }, "homework")).toBe("H\nQ1 q → a");
  expect(schemeText({ note: "x" }, "progress_note")).toBeNull();
});
```

- [ ] **Step 2: Run to see them fail.** `bun test` → the modules and exports are missing.

- [ ] **Step 3: Implement.** `schemas.ts` as the interface. `images.ts`: `Buffer.from(base64, "base64")`, refused when its re-encoding (padding stripped) differs from the input (“didn't arrive whole”), when `length > MAX_IMAGE_BYTES`, or when the first bytes are not the type's (`FF D8 FF`; `89 50 4E 47 0D 0A 1A 0A`; `52 49 46 46 … 57 45 42 50` at 8). `prompts/shared.ts`: the voice (`"You write for a tutor who runs a small tuition centre in India…"`, Indian English, the CBSE and state-board idiom, rupees, no exclamation marks, no emoji, sentence case; never invent a student's facts) and `level` words. `paper.ts`: Sonnet, medium, the system asks for a paper whose sections' marks add to `marks` exactly, `questions` questions, each with an answer the tutor can mark against; `homework.ts` and `worksheet.ts` (the worksheet's `withAnswers` false still returns answers in the output, since the app decides what to show; the key is for the tutor); `progress-note.ts`: a note to the parent by first name, the child by first name, one paragraph of four to six sentences, the attendance line used when given, warm or plain, **no signature** (the app adds it); `scan-register.ts`: Opus, high, the register page as one image, "every row of the table that is a person; name as written; phone digits as written or null; fee as a whole number of rupees or null; no row twice"; `normalisePhone`; `check-paper.ts`: Opus, high, the pages first, the scheme text, "a mark for every question of the scheme, the question's text in a few words, a one-line note saying what was right or wrong, the student's name is `studentName`"; `schemeText` for the three stored kinds.

- [ ] **Step 4: Run to see them pass.** `bun run check` green.

- [ ] **Step 5: Commit.** `git commit -am "API: the input and output schemas, image checks by magic bytes, the six prompts"`.

### Task 4: The routes for real, the entry, the tests (PR 2)

**Files:**
- Modify: `api/src/routes/ai.ts` (rewritten), `api/src/make-app.ts` (`deps: { verify, commit?, claude, db }`), `api/src/index.ts` (the real `anthropicClaude(env("ANTHROPIC_API_KEY"))` unless `process.env.AI_FAKE === "1"`, then `fakeClaude` with `SAMPLE` by kind; `makeDb(supabaseUrl, supabaseAnonKey)`)
- Test: `api/test/ai.test.ts` (new), `api/test/app.test.ts` (the three 501 tests removed; `health` and `404` stay), `api/test/entry.test.ts` (the boot test lists `ANTHROPIC_API_KEY` among the settings that stop the server, and a run with `AI_FAKE=1` boots without it)

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces: `POST /ai/generate` → `200 { id, result }` where `result` is the kind's output; `POST /ai/scan-register` → `200 { id, result: { rows: [{ name, phone, fee }] } }` with phones normalised; `POST /ai/check-paper` → `200 { id, result: { questions: [{ number, text, note, marks, of }], summary } }`; the errors of Task 2. The `userId` from `requireUser` and the centre id from the body (`centreId`, a uuid, added to every input schema's object: the app knows its centre; `start_ai_generation` refuses one the user is not a member of).

- [ ] **Step 1: Write the failing tests** (`api/test/ai.test.ts`):

```ts
import { expect, test } from "bun:test";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const app = (claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r.text)] })), db = fakeDb()) => makeApp({ verify, claude, db });
const kindOf = (text: string) => (text.includes("register") ? "scan_register" : text.includes("answer sheet") ? "check_paper" : text.includes("progress") ? "progress_note" : "paper") as keyof typeof SAMPLE;
const post = (a: ReturnType<typeof makeApp>, path: string, body: unknown) => a.request(path, { method: "POST", headers: auth, body: JSON.stringify(body) });
const paper = { kind: "paper", centreId, subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" };
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");

test("generate starts the record, calls Claude with the paper prompt, finishes the row and answers the result", async () => {
  const claude = fakeClaude({ answer: SAMPLE.paper });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/generate", paper);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string } };
  expect(body.id).toBe("gen-1");
  expect(body.result.title).toBe("Quadratic equations");
  expect(db.started[0]).toMatchObject({ token: "good", centre: centreId, kind: "paper", model: "claude-sonnet-5-5", input: { topic: "Quadratic equations" } });
  expect(db.finished[0]).toMatchObject({ id: "gen-1", status: "ok", tokensIn: 812, tokensOut: 1460 });
  expect(JSON.parse((db.finished[0] as { output: string }).output).title).toBe("Quadratic equations");
  expect(claude.requests[0]?.model).toBe("claude-sonnet-5-5");
});

test("a missing consent answers 403 in words, and the limit 429 with the limit", async () => {
  const noConsent = await post(app(undefined, fakeDb({ consent: false })), "/ai/scan-register", { centreId, imageBase64: jpeg, mediaType: "image/jpeg" });
  expect(noConsent.status).toBe(403);
  expect(await noConsent.json()).toEqual({ error: "Agree to the notice before the first photo.", reason: "consent" });
  const limited = await post(app(undefined, fakeDb({ limit: 0 })), "/ai/generate", paper);
  expect(limited.status).toBe(429);
  expect(await limited.json()).toEqual({ error: "You've made today's 0. Try again tomorrow.", limit: 0, kind: "paper" });
});

test("a refusal is 422, a failed service 502, and both finish the row as failed", async () => {
  const db = fakeDb();
  const refused = await post(app(fakeClaude({ refuse: true }), db), "/ai/generate", paper);
  expect(refused.status).toBe(422);
  expect(db.finished[0]).toMatchObject({ status: "failed", output: null });
  const down = await post(app(fakeClaude({ fail: "timeout" }), fakeDb()), "/ai/generate", paper);
  expect(down.status).toBe(502);
  expect(await down.json()).toEqual({ error: "The AI service didn't answer. Try again." });
});

test("scan-register checks the photo before any call and normalises the phones", async () => {
  const db = fakeDb();
  const bad = await post(app(undefined, db), "/ai/scan-register", { centreId, imageBase64: "AAAA", mediaType: "image/jpeg" });
  expect(bad.status).toBe(400);
  expect(db.started).toHaveLength(0);
  const r = await post(app(fakeClaude({ answer: SAMPLE.scan_register }), db), "/ai/scan-register", { centreId, imageBase64: jpeg, mediaType: "image/jpeg" });
  expect(r.status).toBe(200);
  const rows = ((await r.json()) as { result: { rows: { name: string; phone: string | null }[] } }).result.rows;
  expect(rows[0]).toEqual({ name: "Aarav Mehta", phone: "+919876543210", fee: 1200 });
  expect(rows.find((x) => x.name === "Kavya Nair")?.phone).toBeNull();
  expect(db.started[0]).toMatchObject({ kind: "scan_register", input: { pages: 1, bytes: 8 } });
});

test("check-paper takes the scheme from a paper the centre made, or typed, and refuses a seventh page", async () => {
  const db = fakeDb({ generations: { "fbc6ae19-2769-4934-bf10-c830207fd6a3": { kind: "paper", output: JSON.stringify(SAMPLE.paper) } } });
  const claude = fakeClaude({ answer: SAMPLE.check_paper });
  const page = { imageBase64: jpeg, mediaType: "image/jpeg" };
  const r = await post(app(claude, db), "/ai/check-paper", { centreId, pages: [page, page], scheme: { kind: "paper", generationId: "fbc6ae19-2769-4934-bf10-c830207fd6a3" }, studentName: "Hemanth Reddy" });
  expect(r.status).toBe(200);
  expect(claude.requests[0]?.text).toContain("Quadratic equations");
  expect(claude.requests[0]?.images).toHaveLength(2);
  const unknown = await post(app(claude, db), "/ai/check-paper", { centreId, pages: [page], scheme: { kind: "paper", generationId: "00000000-0000-0000-0000-000000000000" }, studentName: "H" });
  expect(unknown.status).toBe(400);
  expect(await unknown.json()).toEqual({ error: "That paper is no longer here. Type the scheme instead." });
  const seven = await post(app(claude, db), "/ai/check-paper", { centreId, pages: Array(7).fill(page), scheme: { kind: "typed", text: "Q1 (1) b" }, studentName: "H" });
  expect(seven.status).toBe(400);
});
```

- [ ] **Step 2: Run to see them fail.** `bun test` → `makeApp` does not take `claude`/`db`; the routes answer 501.

- [ ] **Step 3: Implement.** `make-app.ts`'s `deps` type becomes `{ verify: Verify; commit?: string; claude: ClaudeClient; db: Db }` and `app.route("/ai", aiRoutes(deps))`. `routes/ai.ts` exports `aiRoutes(deps)` building a `Hono<Vars>` with the three posts, each: parse the body (400 with the issues as today); the token from the header (`c.req.header("authorization")` after `requireUser`, re-read with the same regex; or `c.set("token", …)` in `requireUser`: do that, `Vars` gains `token: string`); for the images `decodeImage` (400 `errors.badImage(why)`); for a check with `scheme.kind === "paper"`, `db.generation(token, id)` and `schemeText` (400 "That paper is no longer here. Type the scheme instead." when null); build the request from the prompt module; `db.start` (catch `DbFailure`: `consent` → 403, `limit` → 429, `not_a_member` → 403 `{ error: "sign in again", reason: "member" }`, `other` → 502); `claude.complete`; `ok` → `db.finish(ok, JSON.stringify(parsed))` (for a scan, after `normalisePhone` on every row) and `200 { id, result }`; `refused` → `db.finish(failed)` and 422; `failed` → `db.finish(failed)` and 502. The record's `input` is the parsed body without the images (a scan: `{ kind, pages: 1, bytes }`; a check: `{ kind, pages: n, bytes, scheme: { kind, generationId? }, studentName }`; a generation: the body). `index.ts`: `const claude = process.env.AI_FAKE === "1" ? fakeClaude(localScript) : anthropicClaude(env("ANTHROPIC_API_KEY"))` where `localScript` (exported by `claude-fake.ts` as `kindOf(request)` plus the rule) answers `SAMPLE[kindOf(request)]`, except a scan whose image is under 1 KB, which answers `{ rows: [] }` (so the "No names found" state can be run by hand with `tools/samples/blank.png`); `const db = makeDb(supabaseUrl, supabaseAnonKey)`.

- [ ] **Step 4: Run to see them pass.** `bun run check` green (tsc and every test).

- [ ] **Step 5: `bun run dev` with `AI_FAKE=1` and curl** as the seed's tutor against local Supabase: `curl -s -X POST localhost:3000/ai/generate -H "authorization: Bearer $TOKEN" -H "content-type: application/json" -d '{"kind":"paper","centreId":"22222222-2222-2222-2222-222222222222","subject":"Mathematics","classLevel":"Class 10 Maths","topic":"Quadratic equations"}'` → 200 with the sample paper; `psql`: one `ai_generations` row, `ok`, with tokens; a scan without consent → 403; then `update centres set ai_consent_at = now()` and the scan with `tools/samples/register-page.png` base64 → 200 (the fake's rows). Record the curl outputs in the PR.

- [ ] **Step 6: Commit, open PR 2 (D35 in `plan/README.md` in the same PR), merge when green.** Then the owner's steps and the deploy (Task 20, steps 1 to 3) before PR 3 starts: the database first, then the API, in one `deploy.yml` run.

---

### Task 5: Domain: generations, results, the plain text; the scan review; the marks; the note line (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Generation.swift`, `GenerationResult.swift`, `PaperText.swift`, `ScanReview.swift`, `CheckResult.swift`, `StudentNote.swift`
- Modify: `ios/TutorCentralKit/Sources/Domain/Centre.swift` (`aiConsentAt`), `Workspace.swift` (`takingAIConsent`)
- Test: `ios/TutorCentralKit/Tests/DomainTests/GenerationTests.swift`, `GenerationResultTests.swift`, `PaperTextTests.swift`, `ScanReviewTests.swift`, `CheckResultTests.swift`, `StudentNoteTests.swift`, `WorkspaceTests.swift` (+ one test)

**Interfaces:**
- Consumes: `Student`, `Classroom`, `PhoneNumber(e164:)`, `Money`, `Day`, `StudentDraft`.
- Produces:

```swift
public enum GenerationKind: String, Hashable, Sendable, CaseIterable, Codable { case paper, homework, worksheet, progressNote = "progress_note"
    public var title: String        // "Question paper", "Homework", "Worksheet", "Progress note"
    public var symbol: String       // "doc.text", "list.bullet", "pencil.line", "text.bubble"
    public var line: String         // the tool row's line (components.md)
    public var createLabel: String  // "Create the paper", "Create the homework", "Create the worksheet", "Write the note"
    public var needsConsent: Bool   // progressNote only
}
public enum Level: String, Hashable, Sendable, CaseIterable, Codable { case easy, medium, hard; public var title: String }
public enum Tone: String, Hashable, Sendable, CaseIterable, Codable { case warm, plain; public var title: String }
public struct PaperForm: Hashable, Sendable, Codable { public var classID: UUID?; public var subject: String; public var topic: String; public var level: Level; public var questions: Int; public var marks: Int
    public static let questionsRange = 1...50; public static let marksRange = 5...100; public init(classID: UUID? = nil, subject: String = "", topic: String = "", level: Level = .medium, questions: Int = 10, marks: Int = 20) }
public struct HomeworkForm: Hashable, Sendable, Codable { classID, subject, topic, level, questions (1...30, default 5) }
public struct WorksheetForm: Hashable, Sendable, Codable { classID, subject, topic, level, questions (1...40, default 12), withAnswers = true }
public struct NoteForm: Hashable, Sendable, Codable { public var studentID: UUID?; public var observations: String; public var tone: Tone; public static let observationsLimit = 2000 }
public enum GenerateRequest: Hashable, Sendable, Codable { case paper(PaperForm), homework(HomeworkForm), worksheet(WorksheetForm), progressNote(NoteForm)
    public var kind: GenerationKind
    /// Create is enabled: a class chosen and a topic typed (trimmed, 1 to 200), or a student chosen and observations typed (1 to 2000).
    public var isValid: Bool
    /// "Writing 10 questions on Quadratic equations" / "Writing 5 questions on Cell structure" / "Writing a note about Hemanth" (the student's first name given).
    public func creatingLine(studentFirstName: String?) -> String
}
public struct PaperResult: Hashable, Sendable, Codable { public struct Section: Hashable, Sendable, Codable, Identifiable { public let title: String; public let marksEach: Int; public let questions: [Question]; public var id: String { title } }
    public struct Question: Hashable, Sendable, Codable, Identifiable { public let number: Int; public let text: String; public let marks: Int; public let answer: String; public var id: Int { number } }
    public let title: String; public let sections: [Section]
    public var questionCount: Int; public var totalMarks: Int }
public struct QuestionSetResult: Hashable, Sendable, Codable { public struct Question: Hashable, Sendable, Codable, Identifiable { number, text, answer }; title, instructions: String?, questions }
public struct NoteResult: Hashable, Sendable, Codable { public let note: String }
public enum GenerationResult: Hashable, Sendable { case paper(PaperResult), homework(QuestionSetResult), worksheet(QuestionSetResult), progressNote(NoteResult)
    /// The API's output JSON by kind; nil when it does not parse (a row written by a newer build).
    public static func decode(kind: GenerationKind, output: String) -> GenerationResult?
    public var title: String   // the paper's title; the note: "Progress note" }
public struct Generation: Hashable, Sendable, Identifiable { public let id: UUID; public let kind: GenerationKind; public let createdAt: Date; public let request: GenerateRequest?; public let result: GenerationResult
    /// "Quadratic equations" or, for a note, the student's name (from `request` and the register; else "Progress note").
    public func title(studentName: (UUID) -> String?) -> String
    /// "Question paper · Class 10 Maths · Tue 6 Oct" (the class name from the register; "No class" when none).
    public func line(className: (UUID?) -> String?, calendar: Calendar) -> String
    /// The hero's line: "10 questions · 20 marks · Medium · created today, 18:32" / "…created Tue 6 Oct, 18:32".
    public func heroLine(today: Day, calendar: Calendar) -> String }
public enum PaperText { public static func plain(_ result: GenerationResult) -> String }   // the title, a blank line, sections and numbered questions "1. … (1 mark)"; the answer key last; a note is its text
public struct ScanRow: Hashable, Sendable, Identifiable { public let id: UUID; public var name: String; public var phone: PhoneNumber?; public var fee: Money?; public var parentName: String; public var included: Bool; public var flag: ScanRowFlag?
    public var line: String   // "+91 98765 43210 · ₹1,200" / "No number read · ₹1,200" / "+91 … · class fee"
    public func draft(classID: UUID?) -> StudentDraft }
public enum ScanRowFlag: Hashable, Sendable { case alreadyHere(name: String, className: String?), noNumber
    public var chip: String?   // "Already here" for alreadyHere
    public var line: String    // "Matches Dev Kumar in Class 8 Science" / "No number read" }
public enum ScanReview {
    /// Rows from the API's answer: an E.164 phone or nil, a whole-rupee fee or nil; a row that matches an active student by phone or by folded name is flagged and unticked; a row without a phone is flagged noNumber and ticked.
    public static func rows(name: [String], phone: [String?], fee: [Int?]) -> [ScanRow]   // see Task 7: built from ScanRowDTO
    public static func flag(_ rows: [ScanRow], against students: [Student], classes: [Classroom]) -> [ScanRow]
    public static func folded(_ name: String) -> String   // lower-cased, whitespace collapsed, diacritics stripped
    public static func title(found: Int) -> String   // "8 found" / "1 found"
    public static func addLabel(ticked: Int) -> String   // "Add 7 students" / "Add 1 student" / "Nothing to add"
    public static func addedToast(count: Int) -> String   // "7 students added from the register."
}
public struct CheckResult: Hashable, Sendable, Codable { public struct QuestionMark: Hashable, Sendable, Codable, Identifiable { public let number: Int; public let text: String; public let note: String; public var marks: Int; public let of: Int; public var changedFrom: Int?; public var id: Int { number } }
    public var questions: [QuestionMark]; public let summary: String
    public var total: Int; public var outOf: Int; public var fraction: Double
    /// From the API: a mark above its maximum is clamped and its note gains " (was N, over the question's marks)".
    public static func clamped(_ raw: CheckResult) -> CheckResult }
public enum MarkEdit { public static func set(_ result: CheckResult, question number: Int, to marks: Int) -> CheckResult   // within 0...of; changedFrom set once, cleared when set back to the original
    public static func saveLabel(_ result: CheckResult, studentFirstName: String) -> String   // "Save to Hemanth's notes" / "Save 15 of 20 to Hemanth's notes" once any mark changed
}
public enum SchemeSource: Hashable, Sendable { case paper(generationID: UUID), typed(String); public static let typedLimit = 4000; public var isValid: Bool }
public enum StudentNoteLine {
    /// "7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted."
    public static func make(day: Day, title: String, result: CheckResult, calendar: Calendar) -> String
    public static func toast(studentFirstName: String, title: String, result: CheckResult) -> String   // "Saved to Hemanth's notes: 15 of 20 on Quadratic equations."
}
public enum NotesAppend { public static let limit = 2000
    /// The existing notes with the line on its own last line; nil when the result would be over the limit.
    public static func append(_ line: String, to notes: String?) -> String?
    public static let overflowMessage = "Hemanth's notes are full. Share the marks instead, or shorten the notes first." // made with the first name: overflow(studentFirstName:)
}
// Centre gains `public var aiConsentAt: Date?` (init default nil); Workspace gains `takingAIConsent(from:)`.
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/GenerationTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct GenerationTests {
    static let maths = UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID()

    @Test func kindsHaveTheirWords() {
        #expect(GenerationKind.allCases.map(\.title) == ["Question paper", "Homework", "Worksheet", "Progress note"])
        #expect(GenerationKind.paper.createLabel == "Create the paper" && GenerationKind.progressNote.createLabel == "Write the note")
        #expect(GenerationKind.progressNote.needsConsent && !GenerationKind.paper.needsConsent)
        #expect(GenerationKind(rawValue: "progress_note") == .progressNote, "the API's and the enum's spelling")
    }

    @Test func aRequestIsValidWithAClassAndATopicOrAStudentAndObservations() {
        #expect(!GenerateRequest.paper(PaperForm()).isValid)
        #expect(!GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "Mathematics", topic: "   ")).isValid)
        #expect(GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "Mathematics", topic: "Quadratic equations")).isValid)
        #expect(!GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "M", topic: String(repeating: "x", count: 201))).isValid)
        #expect(!GenerateRequest.progressNote(NoteForm(studentID: nil, observations: "Improving", tone: .warm)).isValid)
        #expect(GenerateRequest.progressNote(NoteForm(studentID: UUID(), observations: "Improving", tone: .warm)).isValid)
        #expect(GenerateRequest.paper(PaperForm()).kind == .paper && GenerateRequest.worksheet(WorksheetForm()).kind == .worksheet)
    }

    @Test func theCreatingLineNamesTheWork() {
        let paper = GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "Mathematics", topic: "Quadratic equations"))
        #expect(paper.creatingLine(studentFirstName: nil) == "Writing 10 questions on Quadratic equations")
        let homework = GenerateRequest.homework(HomeworkForm(classID: Self.maths, subject: "Science", topic: "Cell structure"))
        #expect(homework.creatingLine(studentFirstName: nil) == "Writing 5 questions on Cell structure")
        let note = GenerateRequest.progressNote(NoteForm(studentID: UUID(), observations: "x", tone: .plain))
        #expect(note.creatingLine(studentFirstName: "Hemanth") == "Writing a note about Hemanth")
    }

    @Test func formsCarryTheirDefaultsAndRanges() {
        #expect(PaperForm().questions == 10 && PaperForm().marks == 20 && PaperForm().level == .medium)
        #expect(HomeworkForm().questions == 5 && WorksheetForm().questions == 12 && WorksheetForm().withAnswers)
        #expect(PaperForm.questionsRange == 1...50 && PaperForm.marksRange == 5...100 && NoteForm.observationsLimit == 2000)
        #expect(Level.allCases.map(\.title) == ["Easy", "Medium", "Hard"] && Tone.allCases.map(\.title) == ["Warm", "Plain"])
    }
}
```

`Tests/DomainTests/GenerationResultTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct GenerationResultTests {
    static let paperJSON = """
    {"title":"Quadratic equations","sections":[{"title":"Section A","marksEach":1,"questions":[{"number":1,"text":"Which of the \
    following is a quadratic equation in x?","marks":1,"answer":"(a)"},{"number":2,"text":"Write the discriminant of 2x² − 4x + 3 = 0.",\
    "marks":1,"answer":"−8"}]},{"title":"Section C","marksEach":4,"questions":[{"number":9,"text":"A train travels 360 km…","marks":4,\
    "answer":"40 km/h"}]}]}
    """
    static let noteJSON = #"{"note":"Hello Lakshmi, a quick note on Hemanth's progress."}"#
    static let sixOct = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 18, minute: 32)) ?? .distantPast
    static let maths = UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID()

    @Test func decodesEachKindAndRefusesTheWrongShape() throws {
        let paper = try #require(GenerationResult.decode(kind: .paper, output: Self.paperJSON))
        guard case let .paper(result) = paper else { Issue.record("not a paper"); return }
        #expect(result.title == "Quadratic equations" && result.questionCount == 3 && result.totalMarks == 6)
        #expect(result.sections.map(\.title) == ["Section A", "Section C"])
        let note = try #require(GenerationResult.decode(kind: .progressNote, output: Self.noteJSON))
        #expect(note.title == "Progress note")
        #expect(GenerationResult.decode(kind: .paper, output: Self.noteJSON) == nil)
        #expect(GenerationResult.decode(kind: .homework, output: "{not json") == nil)
    }

    @Test func aGenerationHasItsTitleLineAndHeroLine() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: Self.paperJSON))
        let form = PaperForm(classID: Self.maths, subject: "Mathematics", topic: "Quadratic equations")
        let generation = Generation(id: UUID(), kind: .paper, createdAt: Self.sixOct, request: .paper(form), result: result)
        #expect(generation.title(studentName: { _ in nil }) == "Quadratic equations")
        #expect(generation.line(className: { $0 == Self.maths ? "Class 10 Maths" : nil }, calendar: DayHeading.india) == "Question paper · Class 10 Maths · Tue 6 Oct")
        let seventh = try #require(Day(year: 2026, month: 10, day: 7))
        #expect(generation.heroLine(today: seventh, calendar: DayHeading.india) == "3 questions · 6 marks · Medium · created Tue 6 Oct, 18:32")
        let sixth = try #require(Day(year: 2026, month: 10, day: 6))
        #expect(generation.heroLine(today: sixth, calendar: DayHeading.india) == "3 questions · 6 marks · Medium · created today, 18:32")
        let note = Generation(id: UUID(), kind: .progressNote, createdAt: Self.sixOct, request: .progressNote(NoteForm(studentID: Self.maths, observations: "x", tone: .warm)), result: .progressNote(NoteResult(note: "n")))
        #expect(note.title(studentName: { _ in "Hemanth Reddy" }) == "Hemanth Reddy")
        #expect(note.line(className: { _ in "Class 10 Maths" }, calendar: DayHeading.india) == "Progress note · Class 10 Maths · Tue 6 Oct")
        let orphan = Generation(id: UUID(), kind: .homework, createdAt: Self.sixOct, request: nil, result: .homework(QuestionSetResult(title: "Fractions", instructions: nil, questions: [])))
        #expect(orphan.line(className: { _ in nil }, calendar: DayHeading.india) == "Homework · No class · Tue 6 Oct")
    }
}
```

`Tests/DomainTests/PaperTextTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct PaperTextTests {
    @Test func aPaperReadsAsPlainTextWithTheKeyLast() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: GenerationResultTests.paperJSON))
        let text = PaperText.plain(result)
        #expect(text.hasPrefix("Quadratic equations\n\nSection A (1 mark each)\n1. Which of the following is a quadratic equation in x? (1 mark)\n"))
        #expect(text.contains("\nSection C (4 marks each)\n9. A train travels 360 km… (4 marks)\n"))
        #expect(text.hasSuffix("\nAnswer key\n1. (a)\n2. −8\n9. 40 km/h"))
        #expect(PaperText.plain(.progressNote(NoteResult(note: "Hello Lakshmi."))) == "Hello Lakshmi.")
        let set = QuestionSetResult(title: "Fractions", instructions: "Show your working.", questions: [.init(number: 1, text: "Add ½ and ⅓.", answer: "⅚")])
        #expect(PaperText.plain(.homework(set)) == "Fractions\n\nShow your working.\n\n1. Add ½ and ⅓.\n\nAnswer key\n1. ⅚")
    }
}
```

`Tests/DomainTests/ScanReviewTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct ScanReviewTests {
    static let science = UUID(uuidString: "33333333-3333-3333-3333-333333333332") ?? UUID()
    static let dev = Student(
        id: UUID(), name: "Dev Kumar", classID: science, monthlyFee: Money(rupees: 1000), parentName: "Ramesh Kumar",
        parentPhone: PhoneNumber(e164: "+919884843831"), dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil
    )
    static let classes = [Classroom(id: science, name: "Class 8 Science", subject: "Science", monthlyFee: Money(rupees: 1000), meetingDays: [], startTime: nil, endTime: nil, archivedAt: nil)]
    static func row(_ name: String, phone: String?, fee: Int?) -> ScanRow {
        ScanRow(id: UUID(), name: name, phone: phone.flatMap(PhoneNumber.init(e164:)), fee: fee.map(Money.init(rupees:)), parentName: "", included: true, flag: nil)
    }

    @Test func aMatchByPhoneOrNameIsFlaggedAndUnticked() {
        let rows = [Self.row("Aarav Mehta", phone: "+919876543210", fee: 1200), Self.row("DEV  kumar", phone: nil, fee: nil), Self.row("Someone Else", phone: "+919884843831", fee: 1000)]
        let flagged = ScanReview.flag(rows, against: [Self.dev], classes: Self.classes)
        #expect(flagged[0].flag == nil && flagged[0].included)
        #expect(flagged[1].flag == .alreadyHere(name: "Dev Kumar", className: "Class 8 Science") && !flagged[1].included)
        #expect(flagged[2].flag == .alreadyHere(name: "Dev Kumar", className: "Class 8 Science") && !flagged[2].included, "the phone matches")
        #expect(flagged[1].flag?.chip == "Already here" && flagged[1].flag?.line == "Matches Dev Kumar in Class 8 Science")
        var archived = Self.dev
        archived.archivedAt = Date()
        #expect(ScanReview.flag(rows, against: [archived], classes: Self.classes)[1].flag == .noNumber, "an archived student is not a match")
    }

    @Test func aBadPhoneBecomesNoNumber() {
        #expect(PhoneNumber(e164: "+91432") == nil)
        let row = ScanReview.flag([Self.row("Kavya Nair", phone: nil, fee: 1200)], against: [], classes: [])[0]
        #expect(row.flag == .noNumber && row.included && row.line == "No number read · ₹1,200")
        #expect(Self.row("Aarav Mehta", phone: "+919876543210", fee: 1200).line == "+91 98765 43210 · ₹1,200")
        #expect(Self.row("Aarav Mehta", phone: "+919876543210", fee: nil).line == "+91 98765 43210 · class fee")
        #expect(ScanReview.folded("  Bir  Bikram   SINGH ") == "bir bikram singh")
    }

    @Test func aRowBecomesADraftAndTheWordsCount() {
        var row = Self.row("Kavya Nair", phone: "+919876543210", fee: 1200)
        row.parentName = "Asha Nair"
        let draft = row.draft(classID: Self.science)
        #expect(draft.trimmedName == "Kavya Nair" && draft.classID == Self.science && draft.fee == Money(rupees: 1200))
        #expect(draft.trimmedParentName == "Asha Nair" && draft.parentDigits == "9876543210")
        #expect(ScanReview.title(found: 8) == "8 found" && ScanReview.title(found: 1) == "1 found")
        #expect(ScanReview.addLabel(ticked: 7) == "Add 7 students" && ScanReview.addLabel(ticked: 1) == "Add 1 student" && ScanReview.addLabel(ticked: 0) == "Nothing to add")
        #expect(ScanReview.addedToast(count: 7) == "7 students added from the register." && ScanReview.addedToast(count: 1) == "1 student added from the register.")
    }
}
```

`Tests/DomainTests/CheckResultTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct CheckResultTests {
    static func mark(_ n: Int, _ marks: Int, of: Int) -> CheckResult.QuestionMark {
        .init(number: n, text: "Q\(n)", note: "n", marks: marks, of: of, changedFrom: nil)
    }
    static let result = CheckResult(questions: [mark(1, 1, of: 1), mark(2, 1, of: 2), mark(3, 2, of: 4)], summary: "Sign errors.")

    @Test func marksAreClampedAndTheTotalIsTheSum() {
        #expect(Self.result.total == 4 && Self.result.outOf == 7 && abs(Self.result.fraction - 4.0 / 7.0) < 0.001)
        let over = CheckResult(questions: [Self.mark(1, 3, of: 1)], summary: "s")
        let clamped = CheckResult.clamped(over)
        #expect(clamped.questions[0].marks == 1 && clamped.questions[0].note == "n (was 3, over the question's marks)")
        let edited = MarkEdit.set(Self.result, question: 2, to: 2)
        #expect(edited.total == 5 && edited.questions[1].marks == 2 && edited.questions[1].changedFrom == 1)
        #expect(MarkEdit.set(edited, question: 2, to: 1).questions[1].changedFrom == nil, "set back: no change")
        #expect(MarkEdit.set(Self.result, question: 3, to: 9).questions[2].marks == 4 && MarkEdit.set(Self.result, question: 3, to: -1).questions[2].marks == 0)
        #expect(MarkEdit.set(Self.result, question: 42, to: 1) == Self.result)
        #expect(MarkEdit.saveLabel(Self.result, studentFirstName: "Hemanth") == "Save to Hemanth's notes")
        #expect(MarkEdit.saveLabel(edited, studentFirstName: "Hemanth") == "Save 5 of 7 to Hemanth's notes")
    }

    @Test func theSchemeSourceKnowsWhenItIsReady() {
        #expect(SchemeSource.paper(generationID: UUID()).isValid)
        #expect(!SchemeSource.typed("   ").isValid && SchemeSource.typed("Q1 (1) b").isValid)
        #expect(!SchemeSource.typed(String(repeating: "x", count: 4001)).isValid && SchemeSource.typedLimit == 4000)
    }
}
```

`Tests/DomainTests/StudentNoteTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct StudentNoteTests {
    @Test func theNoteLineAppendsOrRefuses() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let result = CheckResult(questions: [.init(number: 1, text: "q", note: "n", marks: 15, of: 20, changedFrom: nil)], summary: "Sign errors in Q4 and Q6; Q7 not attempted.")
        let line = StudentNoteLine.make(day: day, title: "Quadratic equations", result: result, calendar: DayHeading.india)
        #expect(line == "7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted.")
        #expect(StudentNoteLine.toast(studentFirstName: "Hemanth", title: "Quadratic equations", result: result) == "Saved to Hemanth's notes: 15 of 20 on Quadratic equations.")
        #expect(NotesAppend.append(line, to: nil) == line)
        #expect(NotesAppend.append(line, to: "Shy in class.") == "Shy in class.\n" + line)
        #expect(NotesAppend.append(line, to: "Ends with a newline\n") == "Ends with a newline\n" + line)
        let full = String(repeating: "x", count: 2000 - line.count)
        #expect(NotesAppend.append(line, to: full) == nil, "one more character than the limit")
        #expect(NotesAppend.append(line, to: String(full.dropLast())) != nil)
        #expect(NotesAppend.overflow(studentFirstName: "Hemanth") == "Hemanth's notes are full. Share the marks instead, or shorten the notes first.")
    }
}
```

`Tests/DomainTests/WorkspaceTests.swift` gains:

```swift
    @Test func takingAIConsentChangesThatFieldAlone() {
        var consented = Self.current   // the file's existing Workspace fixture
        consented.centre.aiConsentAt = Date(timeIntervalSince1970: 1_790_000_000)
        consented.centre.name = "Renamed elsewhere"
        let merged = Self.current.takingAIConsent(from: consented)
        #expect(merged.centre.aiConsentAt == consented.centre.aiConsentAt)
        #expect(merged.centre.name == Self.current.centre.name, "only the consent crosses")
    }
```

- [ ] **Step 2: Run to see them fail.** `bun check --only=ios` → the types do not exist.

- [ ] **Step 3: Implement** as the interface. Notes: `GenerationResult.decode` uses a `JSONDecoder` (keys as the API writes them: `marksEach`, `withAnswers` camel case, no strategy); `Generation.heroLine` reads the counts from the result and the level from the request (a note: "Written Tue 6 Oct, 18:32" with the tone); the time is `HH:mm` in the calendar's time zone; `ScanReview.flag` builds a dictionary of folded names and E.164 phones of the active students, then flags each row (phone first, then name) and sets `included = flag == nil || flag == .noNumber`; `PhoneNumber.display` gives the line's "+91 98765 43210"; `NotesAppend.append` joins with one newline (none added after a trailing one) and refuses over 2000 characters (`count` of characters, as the column's `char_length`). `Centre` gains `aiConsentAt`; `Workspace.takingAIConsent(from:)` copies that one field.

- [ ] **Step 4: Run to see them pass.** `bun check --only=format,lint,ios` green.

- [ ] **Step 5: Commit.** `git add ios && git commit -m "Domain: generations and results, the paper's text, the scan review, marks, the note line, the consent"`.

### Task 6: Data: the API client and the AI repository; history; the fakes (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/AI/AIRepository.swift`, `APIClient.swift`, `APIFailure.swift`, `FakeAIRepository.swift`, `AIHistoryRepository.swift`, `SupabaseAIHistoryRepository.swift`, `GenerationRow.swift`, `FakeAIHistoryRepository.swift`, `ScanRowDTO.swift` (with `CheckResultDTO`)
- Modify: `ios/TutorCentralKit/Sources/Data/SupabaseConfig.swift` (`apiOrigin: URL`), `ios/App/Info.plist` (`API_ORIGIN` = `$(API_ORIGIN)`), `ios/Config/Local.xcconfig.example` (`API_ORIGIN = http:/$()/127.0.0.1:3000`), `.github/workflows/testflight.yml` (the step that writes the xcconfig adds `API_ORIGIN = ${{ vars.API_ORIGIN }}`, with `https:/$()/` spelled as the two URLs are), `ios/TutorCentralKit/Sources/AppShell/Dependencies.swift` (`ai`, `aiHistory`; `live()` builds `SupabaseAIHistoryRepository(client:)` and `APIClient(origin:session:)`)
- Test: `ios/TutorCentralKit/Tests/DataTests/APIClientTests.swift`, `GenerationRowTests.swift`, `SupabaseConfigTests.swift` (+ `apiOrigin`), `FakeAIRepositoryTests.swift`

**Interfaces:**
- Consumes: Task 5's types; `SupabaseClient.auth.session` (supabase-swift; `try await client.auth.session` refreshes when needed and gives `accessToken`); `PostgRESTDecoder`.
- Produces:

```swift
/// What the app sends the API, mirroring api/src/schemas.ts.
public struct ImageUpload: Hashable, Sendable { public let data: Data; public let mediaType: String   // "image/jpeg"
    public var base64: String }
public enum APIFailure: Error, Hashable, Sendable { case offline, signedOut, consent, limit(Int), refused(String), service, tooLarge, server(String)
    /// The words the boards use: offline "Couldn't reach the AI service. Check your connection and try again."; consent is handled by the store (the sheet); limit "You've made today's 40. Try again tomorrow."; refused carries the API's text; service "The AI service didn't answer. Try again."; tooLarge "That's too many pages. Up to six, and try sharper, smaller photos."
    public var message: String }
public struct ScanRowDTO: Decodable, Hashable, Sendable { public let name: String; public let phone: String?; public let fee: Int? }
public struct CheckResultDTO: Decodable, Hashable, Sendable { public let questions: [Question]; public let summary: String; public struct Question: Decodable, Hashable, Sendable { number, text, note, marks, of }
    public var result: CheckResult   // CheckResult.clamped of the raw }
public protocol AIRepository: Sendable {
    /// POST /ai/generate: the kind's result and the generation's id.
    func generate(_ request: GenerateRequest, context: GenerateContext) async throws(APIFailure) -> Generation
    /// POST /ai/scan-register.
    func scanRegister(_ image: ImageUpload, centre: UUID) async throws(APIFailure) -> (id: UUID, rows: [ScanRowDTO])
    /// POST /ai/check-paper.
    func checkPaper(pages: [ImageUpload], scheme: SchemeSource, studentName: String, centre: UUID) async throws(APIFailure) -> (id: UUID, result: CheckResult)
}
/// What a generation needs beyond the form: the names the register knows (the API never sees ids).
public struct GenerateContext: Hashable, Sendable { public let centre: UUID; public let className: String?; public let subject: String; public let studentName: String?; public let parentName: String?; public let attendanceLine: String?; public let tutorName: String; public let centreName: String }
public struct APIClient: AIRepository { public init(origin: URL, token: @escaping @Sendable () async throws -> String, session: URLSession = .shared, now: @escaping @Sendable () -> Date = Date.init)
    public static let bodyLimit = 4_200_000   // base64 characters; tooLarge before the request
    public static let timeout: TimeInterval = 125 }
public struct GenerationRow: Decodable { id, kind: String, input: AnyJSONValue?, output: String?, createdAt: Date   // + var generation: Generation? (decodes output by kind; input back into a GenerateRequest when its kind matches, else nil) }
public protocol AIHistoryRepository: Sendable {
    /// The centre's ok generations of the four kinds, newest first, at most 50.
    func generations(centre: UUID) async throws -> [Generation]
    func generation(id: UUID) async throws -> Generation?
}
@MainActor public final class FakeAIRepository: AIRepository { public var script: Script; public var delay: Duration?; public private(set) var requests: [GenerateRequest]; public private(set) var scans: Int; public private(set) var checks: [SchemeSource]
    public enum Script: Sendable { case answer, failure(APIFailure) }
    public static let samplePaper: PaperResult; samplePaperJSON: String; sampleNote: NoteResult; sampleScanRows: [ScanRowDTO]; sampleCheck: CheckResult   // the boards' content }
@MainActor public final class FakeAIHistoryRepository: AIHistoryRepository { public var generations: [Generation]; public var nextError: (any Error)?; public nonisolated static let seed: [Generation]   // the six of the decisions table }
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/GenerationRowTests.swift` (the stack's answers, 2026-10-08):

```swift
import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answers on 2026-10-08: an insert's row, a failed scan's row, and the history read.
struct GenerationRowTests {
    static let inserted = Data("""
    [{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","centre_id":"22222222-2222-2222-2222-222222222222","kind":"paper","input":{"kind": "paper", \
    "level": "medium", "marks": 20, "topic": "Quadratic equations", "subject": "Mathematics", "questions": 10, "classLevel": "Class 10 Maths"},\
    "output":"{\\"title\\":\\"Quadratic equations\\",\\"sections\\":[]}","model":"claude-sonnet-5-5","tokens_in":812,"tokens_out":1460,\
    "status":"ok","created_at":"2026-10-08T18:09:01.372972+00:00","updated_at":"2026-10-08T18:09:01.372972+00:00"}]
    """.utf8)
    static let failedScan = Data("""
    [{"id":"86c64b2d-486a-434f-8243-9c0cabe22a3c","centre_id":"22222222-2222-2222-2222-222222222222","kind":"scan_register","input":{"kind": \
    "scan_register", "bytes": 412330, "pages": 1},"output":null,"model":"claude-opus-5-5","tokens_in":null,"tokens_out":null,"status":"failed",\
    "created_at":"2026-10-08T18:09:01.387448+00:00","updated_at":"2026-10-08T18:09:01.387448+00:00"}]
    """.utf8)
    static let history = Data("""
    [{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","kind":"paper","input":{"kind": "paper", "level": "medium", "marks": 20, "topic": \
    "Quadratic equations", "subject": "Mathematics", "questions": 10, "classLevel": "Class 10 Maths"},"output":"{\\"title\\":\\"Quadratic \
    equations\\",\\"sections\\":[]}","model":"claude-sonnet-5-5","tokens_in":812,"tokens_out":1460,"status":"ok",\
    "created_at":"2026-10-08T18:09:01.372972+00:00"}]
    """.utf8)

    @Test func decodesARowIntoAGenerationWhenItsOutputParses() throws {
        let rows = try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Self.history)
        let row = try #require(rows.first)
        #expect(row.kind == "paper" && row.createdAt.timeIntervalSince1970 > 1_790_000_000)
        // An empty sections array fails PaperOutput on the API, so the app treats this stored output as a paper with no sections: nil.
        #expect(row.generation == nil, "sections must not be empty")
        let okRow = try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Self.inserted)
        #expect(okRow.first?.id == UUID(uuidString: "fbc6ae19-2769-4934-bf10-c830207fd6a3"))
        let failed = try #require(try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Self.failedScan).first)
        #expect(failed.generation == nil && failed.output == nil)
    }

    @Test func aStoredInputComesBackAsTheRequestWhenItsKindMatches() throws {
        let withSections = String(decoding: Self.inserted, as: UTF8.self)
            .replacingOccurrences(of: #"\"sections\":[]"#, with: #"\"sections\":[{\"title\":\"A\",\"marksEach\":1,\"questions\":[{\"number\":1,\"text\":\"q\",\"marks\":1,\"answer\":\"a\"}]}]"#)
        let row = try #require(try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Data(withSections.utf8)).first)
        let generation = try #require(row.generation)
        #expect(generation.kind == .paper)
        guard case let .paper(form)? = generation.request else { Issue.record("no form"); return }
        #expect(form.topic == "Quadratic equations" && form.marks == 20 && form.level == .medium && form.subject == "Mathematics")
        #expect(form.classID == nil, "the API's input names the class, not its id; the app reads the id from its own copy when it has one")
    }
}
```

`Tests/DataTests/APIClientTests.swift` (a `URLProtocol` stub, as `SupabaseAuthRepositoryTests` does for its session):

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct APIClientTests {
    static let origin = URL(string: "https://api.test") ?? URL(fileURLWithPath: "/")
    static let centre = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
    static let context = GenerateContext(centre: centre, className: "Class 10 Maths", subject: "Mathematics", studentName: nil, parentName: nil, attendanceLine: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition")

    static func client(status: Int, body: String) -> (APIClient, StubProtocol.Recorder) {
        let recorder = StubProtocol.Recorder(status: status, body: body)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        StubProtocol.recorder = recorder
        return (APIClient(origin: origin, token: { "tok" }, session: URLSession(configuration: config)), recorder)
    }

    @Test func generatePostsTheFormWithTheBearerAndDecodesTheResult() async throws {
        let body = #"{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","result":{"title":"Quadratic equations","sections":[{"title":"A","marksEach":1,"questions":[{"number":1,"text":"q","marks":1,"answer":"a"}]}]}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let form = PaperForm(classID: UUID(), subject: "Mathematics", topic: "Quadratic equations")
        let generation = try await client.generate(.paper(form), context: Self.context)
        #expect(generation.id == UUID(uuidString: "fbc6ae19-2769-4934-bf10-c830207fd6a3") && generation.kind == .paper)
        let request = try #require(recorder.requests.first)
        #expect(request.url?.path == "/ai/generate" && request.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
        let sent = try #require(recorder.bodies.first.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(sent["kind"] as? String == "paper" && sent["classLevel"] as? String == "Class 10 Maths" && sent["centreId"] as? String == Self.centre.uuidString.lowercased())
        #expect(sent["topic"] as? String == "Quadratic equations" && sent["marks"] as? Int == 20)
    }

    @Test func everyAnswerBecomesItsFailure() async {
        for (status, body, expected) in [
            (403, #"{"error":"Agree to the notice before the first photo.","reason":"consent"}"#, APIFailure.consent),
            (429, #"{"error":"You've made today's 40. Try again tomorrow.","limit":40,"kind":"paper"}"#, .limit(40)),
            (422, #"{"error":"Couldn't make this one. Change the topic and try again."}"#, .refused("Couldn't make this one. Change the topic and try again.")),
            (502, #"{"error":"The AI service didn't answer. Try again."}"#, .service),
            (401, #"{"error":"sign in again"}"#, .signedOut),
            (400, #"{"error":"topic: too long"}"#, .server("topic: too long")),
        ] {
            let (client, _) = Self.client(status: status, body: body)
            do {
                _ = try await client.scanRegister(ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg"), centre: Self.centre)
                Issue.record("\(status) did not throw")
            } catch {
                #expect(error == expected, "\(status)")
            }
        }
    }

    @Test func aBodyOverTheLimitIsRefusedBeforeTheRequest() async {
        let (client, recorder) = Self.client(status: 200, body: "{}")
        let page = ImageUpload(data: Data(repeating: 0xFF, count: 1_100_000), mediaType: "image/jpeg")
        do {
            _ = try await client.checkPaper(pages: Array(repeating: page, count: 3), scheme: .typed("Q1 (1) b"), studentName: "Hemanth Reddy", centre: Self.centre)
            Issue.record("did not throw")
        } catch {
            #expect(error == .tooLarge && recorder.requests.isEmpty)
        }
        #expect(APIFailure.tooLarge.message == "That's too many pages. Up to six, and try sharper, smaller photos.")
        #expect(APIFailure.offline.message == "Couldn't reach the AI service. Check your connection and try again.")
    }

    @Test func checkPaperSendsThePagesInOrderAndTheScheme() async throws {
        let body = #"{"id":"11111111-1111-1111-1111-111111111111","result":{"questions":[{"number":1,"text":"q","note":"n","marks":3,"of":1}],"summary":"s"}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let pages = [Data([0xFF, 0xD8, 0xFF, 1]), Data([0xFF, 0xD8, 0xFF, 2])].map { ImageUpload(data: $0, mediaType: "image/jpeg") }
        let answer = try await client.checkPaper(pages: pages, scheme: .paper(generationID: UUID()), studentName: "Hemanth Reddy", centre: Self.centre)
        #expect(answer.result.questions[0].marks == 1, "clamped on arrival")
        let sent = try #require(recorder.bodies.first.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let sentPages = try #require(sent["pages"] as? [[String: String]])
        #expect(sentPages.map { $0["imageBase64"] } == pages.map(\.base64))
        #expect((sent["scheme"] as? [String: String])?["kind"] == "paper")
    }
}

/// Answers every request with one status and body, recording what was sent.
final class StubProtocol: URLProtocol {
    @MainActor static var recorder: Recorder?
    final class Recorder: @unchecked Sendable {
        let status: Int
        let body: String
        var requests: [URLRequest] = []
        var bodies: [Data] = []
        init(status: Int, body: String) { self.status = status; self.body = body }
    }
    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let recorder = MainActor.assumeIsolated({ Self.recorder }) else { return }
        recorder.requests.append(request)
        recorder.bodies.append(request.httpBody ?? request.httpBodyStream.map { stream in
            stream.open(); var data = Data(); var buffer = [UInt8](repeating: 0, count: 65536)
            while stream.hasBytesAvailable { let n = stream.read(&buffer, maxLength: buffer.count); if n <= 0 { break }; data.append(buffer, count: n) }
            return data
        } ?? Data())
        let response = HTTPURLResponse(url: request.url ?? Self.placeholder, statusCode: recorder.status, httpVersion: nil, headerFields: ["content-type": "application/json"])
        if let response { client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed) }
        client?.urlProtocol(self, didLoad: Data(recorder.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
    static let placeholder = URL(fileURLWithPath: "/")
}
```

(`URLSession` copies a body into `httpBodyStream`; the recorder reads either. If `SupabaseAuthRepositoryTests` already has a stub protocol with a recorder, reuse it and drop this one.)

`Tests/DataTests/FakeAIRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeAIRepositoryTests {
    static let context = GenerateContext(centre: UUID(), className: "Class 10 Maths", subject: "Mathematics", studentName: nil, parentName: nil, attendanceLine: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition")

    @Test func theFakeAnswersTheBoardsAndRecordsTheCall() async throws {
        let fake = FakeAIRepository()
        let generation = try await fake.generate(.paper(PaperForm(classID: UUID(), subject: "Mathematics", topic: "Quadratic equations")), context: Self.context)
        guard case let .paper(paper) = generation.result else { Issue.record("not a paper"); return }
        #expect(paper.title == "Quadratic equations" && paper.questionCount == 10 && paper.totalMarks == 20)
        #expect(fake.requests.count == 1)
        let scan = try await fake.scanRegister(ImageUpload(data: Data([1]), mediaType: "image/jpeg"), centre: UUID())
        #expect(scan.rows.map(\.name) == ["Aarav Mehta", "Diya Pillai", "Dev Kumar", "Kavya Nair", "Rohan Gupta", "Sneha Joshi", "Ishaan Bose", "Tanvi Kulkarni"])
        #expect(scan.rows[3].phone == nil && scan.rows[2].phone == "+919884843831")
        let check = try await fake.checkPaper(pages: [], scheme: .typed("x"), studentName: "Hemanth Reddy", centre: UUID())
        #expect(check.result.total == 14 && check.result.outOf == 20 && check.result.questions.count == 10)
        fake.script = .failure(.service)
        await #expect(throws: APIFailure.service) { try await fake.generate(.paper(PaperForm()), context: Self.context) }
        #expect(FakeAIHistoryRepository.seed.count == 6 && FakeAIHistoryRepository.seed.first?.kind == .paper)
    }
}
```

`SupabaseConfigTests` gains: `apiOrigin` read from `API_ORIGIN` and a missing one throws (as `SUPABASE_URL` does).

- [ ] **Step 2: Run to see them fail.** `bun check --only=ios` → the types do not exist.

- [ ] **Step 3: Implement.** `APIClient.generate` builds the JSON body from the request and the context (`kind`, `centreId` lower-cased uuid, `subject`, `classLevel` = `context.className ?? "No class"`, `topic`, `level`, `questions`, `marks`, `withAnswers`; a note: `studentName`, `parentName`, `observations`, `attendanceLine`, `tone`, `tutorName`, `centreName`), posts with `URLRequest` (`timeoutInterval` 125, `Authorization: Bearer <await token()>`, `content-type: application/json`), maps `URLError` to `.offline`, the statuses to the failures (the body's `error` and `limit`), decodes `200` by kind (`GenerationResult.decode` of the re-serialised `result`; `id` as `UUID`), and makes `Generation(id:kind:createdAt: now(), request:, result:)`. The base64 total of a check's pages (and a scan's one) over `bodyLimit` throws `.tooLarge` first. `SupabaseAIHistoryRepository.generations` selects `id, kind, input, output, created_at` with `kind=in.(paper,homework,worksheet,progress_note)`, `status=eq.ok`, `order=created_at.desc`, `limit=50`, and keeps the rows whose `generation` is non-nil; `generation(id:)` selects the one row. `GenerationRow.generation` decodes `output` by kind and `input` (an `AnyJSON`, re-serialised) into the matching form, with `classID` nil. `Dependencies.live()`: `APIClient(origin: config.apiOrigin, token: { try await client.auth.session.accessToken })`. The fakes as the interface, the samples word for word from the boards.

- [ ] **Step 4: Run to see them pass.** `bun check --only=format,lint,ios` green.

- [ ] **Step 5: Commit.** `git commit -am "Data: the API client, the AI repository and its fake, the history read decoded from the stack's answers, the API origin"`.

### Task 7: Data: the consent, bulk students, notes, the progress log; the write proofs (PR 3)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Data/Centres/CentreRepository.swift` (`recordAIConsent(id:at:)`), `SupabaseCentreRepository.swift` (`CentreRow` + `aiConsentAt`; the select adds `ai_consent_at`), `FakeCentreRepository.swift` (`consents: [Date]`, `meeraWorkspaceConsented`); `Students/StudentsRepository.swift` (`createMany`, `deleteMany`, `updateNotes`), `SupabaseStudentsRepository.swift`, `FakeStudentsRepository.swift` (`createdMany: [[StudentDraft]]`, `deleted: [[UUID]]`, `notesUpdates: [(UUID, String?)]` as a struct `NotesUpdate`); `Messages/MessageLogRepository.swift` (`logProgress(centre:studentID:) -> Date`), `SupabaseMessageLogRepository.swift`, `FakeMessageLogRepository.swift` (`progressLogs: [UUID]`)
- Test: `Tests/DataTests/CentreRowTests.swift` (+), `StudentWriteRowTests.swift` (new), `ProgressLogRowTests.swift` (new), `FakeStudentsRepositoryTests.swift` (+), `FakeCentreRepositoryTests.swift` (+)

**Interfaces:**

```swift
public protocol CentreRepository { … func recordAIConsent(id: UUID, at: Date) async throws }   // update centres set ai_consent_at; the row's new value is the Workspace's
public protocol StudentsRepository { …
    /// One insert of several rows (an array body); the created students in the order sent.
    func createMany(_ drafts: [StudentDraft], centre: UUID) async throws -> [Student]
    /// One delete of these ids (Undo after Add); nothing else.
    func deleteMany(ids: [UUID]) async throws
    /// The whole notes text (nil clears), answering the student as stored.
    func updateNotes(id: UUID, notes: String?) async throws -> Student }
public protocol MessageLogRepository { … func logProgress(centre: UUID, studentID: UUID) async throws -> Date }   // the opened_at of the inserted row
```

- [ ] **Step 1: Write the failing tests** (the stack's answers, 2026-10-08):

`Tests/DataTests/CentreRowTests.swift` gains the consent answer:

```swift
    static let consented = Data("""
    [{"id":"22222222-2222-2222-2222-222222222222","ai_consent_at":"2026-10-08T07:35:00+00:00"}]
    """.utf8)

    @Test func decodesTheConsentAnswerAndACentreWithout() throws {
        let decoder = SupabaseCentreRepository.decoder
        let consent = try #require(try decoder.decode([ConsentRow].self, from: Self.consented).first)
        #expect(consent.aiConsentAt?.timeIntervalSince1970 == 1_791_444_900)
        let row = try #require(try decoder.decode([CentreRow].self, from: Self.centres).first)
        #expect(row.centre.aiConsentAt == nil, "the select without the column decodes: the key is optional")
    }
```

(`centres` in the existing fixture lacks `ai_consent_at`: `CentreRow.aiConsentAt` is `Date?` decoded with `decodeIfPresent`, so the old fixture still decodes; the live select adds the column.)

`Tests/DataTests/StudentWriteRowTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answers on 2026-10-08: a bulk insert of two students, the delete of both, a notes update and its undo.
struct StudentWriteRowTests {
    static let inserted = Data("""
    [{"id":"304ba383-7481-4c35-96bd-6e63a1b0d3f2","name":"Aarav Mehta","class_id":"33333333-3333-3333-3333-333333333331","monthly_fee":null,\
    "parent_name":null,"parent_phone":"+919876543210","date_of_birth":null,"gender":null,"notes":null,"archived_at":null}, \
     {"id":"36ce1230-3997-432e-9794-0bb245212cb6","name":"Kavya Nair","class_id":"33333333-3333-3333-3333-333333333331","monthly_fee":1200,\
    "parent_name":null,"parent_phone":null,"date_of_birth":null,"gender":null,"notes":null,"archived_at":null}]
    """.utf8)
    static let deleted = Data("""
    [{"id":"304ba383-7481-4c35-96bd-6e63a1b0d3f2"}, \
     {"id":"36ce1230-3997-432e-9794-0bb245212cb6"}]
    """.utf8)
    static let notes = Data("""
    [{"id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533","notes":"7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted."}]
    """.utf8)
    static let notesCleared = Data("""
    [{"id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533","notes":null}]
    """.utf8)

    @Test func decodesTheInsertedStudentsInOrder() throws {
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: Self.inserted)
        let students = rows.map(\.student)
        #expect(students.map(\.name) == ["Aarav Mehta", "Kavya Nair"])
        #expect(students[0].parentPhone?.e164 == "+919876543210" && students[0].monthlyFee == nil)
        #expect(students[1].parentPhone == nil && students[1].monthlyFee == Money(rupees: 1200))
        let ids = try SupabaseStudentsRepository.decoder.decode([IDRow].self, from: Self.deleted).map(\.id)
        #expect(ids.count == 2 && ids.first == UUID(uuidString: "304ba383-7481-4c35-96bd-6e63a1b0d3f2"))
    }

    @Test func decodesANotesUpdateAndItsUndo() throws {
        let row = try #require(try SupabaseStudentsRepository.decoder.decode([NotesRow].self, from: Self.notes).first)
        #expect(row.notes?.hasPrefix("7 Oct · Quadratic equations · 15 of 20") == true)
        let cleared = try #require(try SupabaseStudentsRepository.decoder.decode([NotesRow].self, from: Self.notesCleared).first)
        #expect(cleared.notes == nil)
    }
}
```

(`updateNotes` selects the full student columns and answers a `Student`; the two-column fixture above pins the `select=id,notes` variant the write proof used. Keep `NotesRow` and `IDRow` as small `Decodable`s in `SupabaseStudentsRepository.swift`.)

`Tests/DataTests/ProgressLogRowTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answer on 2026-10-08 to a progress log insert.
struct ProgressLogRowTests {
    static let logged = Data("""
    [{"student_id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533","kind":"progress","opened_at":"2026-10-08T18:09:01.503638+00:00","about_date":null}]
    """.utf8)

    @Test func decodesTheOpenedAt() throws {
        let row = try #require(try SupabaseMessageLogRepository.decoder.decode([ProgressLogRow].self, from: Self.logged).first)
        #expect(row.kind == "progress" && row.openedAt.timeIntervalSince1970 > 1_791_000_000)
        #expect(row.studentId == UUID(uuidString: "50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533"))
    }
}
```

`FakeStudentsRepositoryTests` gains:

```swift
    @Test func createManyDeleteManyAndUpdateNotesAreRecorded() async throws {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        var one = StudentDraft(); one.name = "Aarav Mehta"; one.parentDigits = "9876543210"
        var two = StudentDraft(); two.name = "Kavya Nair"; two.fee = Money(rupees: 1200)
        let made = try await fake.createMany([one, two], centre: UUID())
        #expect(made.map(\.name) == ["Aarav Mehta", "Kavya Nair"] && fake.createdMany.count == 1)
        #expect(try await fake.students(centre: UUID(), period: Period(year: 2026, month: 10)).count == 12)
        try await fake.deleteMany(ids: made.map(\.id))
        #expect(try await fake.students(centre: UUID(), period: Period(year: 2026, month: 10)).count == 10 && fake.deleted == [made.map(\.id)])
        let updated = try await fake.updateNotes(id: FakeStudentsRepository.akshita, notes: "A line")
        #expect(updated.notes == "A line" && fake.notesUpdates.last?.notes == "A line")
        fake.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await fake.updateNotes(id: FakeStudentsRepository.akshita, notes: nil) }
    }
```

`FakeCentreRepositoryTests` gains: `recordAIConsent` appends to `consents`; `meeraWorkspaceConsented.centre.aiConsentAt` is 1 October 2026.

- [ ] **Step 2: Run to see them fail.**

- [ ] **Step 3: Implement.** `SupabaseCentreRepository.recordAIConsent`: `from("centres").update(["ai_consent_at": .string(ISO8601DateFormatter().string(from: at))]).eq("id", value: id).select("id, ai_consent_at").single().execute()`, decoded as `ConsentRow`. `createMany`: `from("students").insert(drafts.map { Self.values($0, centre: centre) }).select(Self.columns).execute()` → `[StudentRow]`; `deleteMany`: `from("students").delete().in("id", values: ids.map(\.uuidString)).execute()`; `updateNotes`: `update(["notes": notes.map(AnyJSON.string) ?? .null]).eq("id", …).select(Self.columns).single()`. `logProgress`: insert `{ centre_id, student_id, kind: "progress" }` with `select("student_id, kind, opened_at, about_date").single()`, answer `openedAt`. The fakes record each call and throw `nextError` once.

- [ ] **Step 4: The write proofs in Swift against the local stack** (a throwaway test in `DataTests`, an in-memory session signed in as the seed's tutor, as Phase 5's PR 2 did; deleted before the commit): `recordAIConsent` then `psql` shows the timestamp; `createMany` of two drafts (one without a phone) → two rows, then `deleteMany` → gone; `updateNotes` with a line, then with nil; `logProgress` → one `progress` row. Reset the seed after (`supabase db reset`). Note each answer in the PR.

- [ ] **Step 5: Run to see them pass; commit; open PR 3; merge when green.** `git commit -am "Data: the consent write, bulk students and their undo, a notes update, the progress log; the fakes"`.

---

### Task 8: DesignSystem: the Phase 6 parts; the camera pieces shared (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Components/ToolRows.swift`, `CreatingCard.swift`, `ErrorRow.swift`, `ResultHero.swift`, `PaperCard.swift`, `MarkRow.swift`, `ReviewRow.swift`, `NoticesCard.swift`, `IntroHero.swift`, `PageTile.swift`, `MessageSheet.swift`, `ConsentSheet.swift`, `Camera/CameraAccess.swift` (moved from `Features/Fees/QRScannerView.swift`, with its AVFoundation import and the reason: the one place the app asks for the camera), `Camera/DocumentCameraView.swift`
- Modify: `Features/Fees/QRScannerView.swift` (the `CameraAccess` enum removed; `PaymentsView` imports it from DesignSystem, unchanged otherwise), `docs/design/design-tokens.md` and `Tokens` only if a value below is missing (none is expected: every number is a token or an anatomy constant)
- Test: `Tests/DesignSystemTests/TokenDocumentTests` stays green; the parts are proven by their previews and the pictures (D7, D15)

**Interfaces** (every number a token; the anatomy constants named on the type):

```swift
public struct ToolRow: View { public init(symbol: String, title: String, line: String, action: @escaping () -> Void) }   // icon tile 40, rowTitle, footnote text2, chevron (components.md, Tool row)
public struct HistoryRow: View { public init(symbol: String, title: String, line: String, action: @escaping () -> Void) }   // the same row; kept apart so the Kit names both
public struct CreatingCard: View { public init(title: String, line: String, thumbnail: (any View)? = nil, cancel: @escaping () -> Void) }   // hero card padding 16: rowHeading, quiet Cancel, three SkeletonRow-like bars breathing (Tokens.breathe), the footnote line; a thumbnail (a page) on the left when given
public struct ErrorRow: View { public init(title: String, line: String, retry: (() -> Void)?) }   // a list card with one row: exclamationmark.circle 24 in overdue, rowHeading, rowLine text2, quiet Retry 700
public struct ResultHero: View { public init(eyebrow: String, title: String, line: String) }
public struct SectionRow: View { public init(title: String, line: String) }   // surface2 band: 15 700 and footnote text2
public struct QuestionRow: View { public init(number: Int, text: String, marks: String?, isLast: Bool) }   // the number in a 24 pt column text2 600, subhead text, footnote text3 marks on the right
public struct MarkTile: View { public init(marks: Int, of: Int, action: @escaping () -> Void) }   // 36 high, min 64 wide, surface2, line, radius 10, accentText 700 tabular "2 / 4"
public struct MarkRow: View { public init(number: Int, text: String, note: String, changedFrom: Int?, marks: Int, of: Int, pick: @escaping () -> Void) }   // rowTitle "4. Nature of the roots", the note footnote text2 (+ "· Changed from 1" in ok 600), the tile
public struct MarkPicker: View { public init(number: Int, of: Int, selected: Int, choose: @escaping (Int) -> Void) }   // the popover's content: eyebrow "Marks for question 4", FilterChips 0...of, 200 wide
public struct ReviewRow: View { public init(name: String, line: String, lineTone: StatusTone?, chip: String?, included: Binding<Bool>, open: @escaping () -> Void) }   // Checkbox 24, name rowTitle (+ compact due chip with exclamationmark.circle), the line (the tone colours the first words when given), chevron
public struct NoticesCard: View { public struct Notice: Identifiable { public init(symbol: String, text: String) }; public init(_ notices: [Notice]) }
public struct IntroHero: View { public init(symbol: String, title: String, line: String) }   // hero card padding 24: FeatureTile 56, emptyTitle centred, subhead text2 centred max measureLine + 20
public struct PageTile: View { public init(image: UIImage, number: Int, remove: @escaping () -> Void) }   // compact card padding 10, the page thumbnail, "Page 1" footnote text2, a 28 round remove mark top right
public struct AddPageTile: View { public init(action: @escaping () -> Void) }   // dashed lineStrong, radius 16, camera 22, "Add a page" accentText 600, min 150 high
public struct MessageSheet: View { public init(title: String, name: String, headline: String, parentLine: String, label: String, text: String, note: String, canOpen: Bool, open: @escaping () async -> Void, close: @escaping () -> Void) }   // the absence alert's body as one part (components.md, Message sheet): Cancel, avatar 56, headline title3, parent line, the label over the text in a well, the note, Open WhatsApp primary 52 with the loading state
public struct ConsentSheet: View { public init(centreName: String, agree: @escaping () async -> Bool, close: @escaping () -> Void) }   // P6-Scan-Consent: Cancel and "Before the first photo", the consent text, the footnote with the centre's name, the primary "I agree, continue" 52 (loading while agree runs); shown by the note form, Scan register and Check a paper, so it is DesignSystem's (Students and AITools cannot share it otherwise)
public enum CameraAccess { … as today, in DesignSystem/Components/Camera }
public struct DocumentCameraView: UIViewControllerRepresentable { public init(maxPages: Int, onPages: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void)
    @MainActor public static var isSupported: Bool   // VNDocumentCameraViewController.isSupported: false in the simulator
}   // VisionKit's document camera (full screen cover: its own Cancel and Save); the delegate hands the scan's pages (up to maxPages, the first ones) as UIImages; the reason in the file: SwiftUI has no camera (D8)
```

- [ ] **Step 1: Build the parts with previews** (one `#Preview` per file showing each state the boards draw: the error row with and without Retry; the mark row plain and changed; the review row ticked, "Already here", "No number read"; the creating card with and without a thumbnail). `MessageSheet`'s body is `AbsenceAlertSheet`'s content lifted (Attendance and Fees keep their own sheets this phase: a deferred minor to adopt it).
- [ ] **Step 2: Move `CameraAccess` and add `DocumentCameraView`.** `QRScannerView.swift` keeps the QR scanner; `PaymentsView` compiles unchanged (`import DesignSystem` is already there). `DocumentCameraView`'s coordinator implements `documentCameraViewController(_:didFinishWith:)` (pages `0..<min(scan.pageCount, maxPages)` through `scan.imageOfPage(at:)`), `…DidCancel` and `…didFailWithError` (treated as cancel; the error logged).
- [ ] **Step 3: `bun check --only=format,lint,ios` green** (the Kit's token test unchanged). Commit: `git commit -am "DesignSystem: the Phase 6 parts; the camera access and the document camera shared"`.

### Task 9: The photo reducer and the PDF (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/AITools/PhotoReducer.swift`, `PDFMaker.swift`
- Test: `ios/TutorCentralKit/Tests/AIToolsTests/PhotoReducerTests.swift`, `PDFMakerTests.swift`; `Package.swift` and `project.yml` gain `AIToolsTests` (depends on `AITools`, `Students`)

**Interfaces:**

```swift
public enum PhotoReducer {
    public static let longEdge: CGFloat = 2000
    public static let quality: CGFloat = 0.7
    /// A JPEG at most 2000 px on its long edge (never upscaled), the EXIF orientation applied; nil when the data is not an image.
    public nonisolated static func reduce(_ data: Data) -> ImageUpload?
    public nonisolated static func reduce(_ image: UIImage) -> ImageUpload?
}
public enum PDFMaker {
    /// The result as an A4 PDF in the temporary directory, named after the title ("Quadratic equations.pdf"); pages of 595 × 842 pt.
    @MainActor public static func pdf(for result: GenerationResult, title: String) throws -> URL
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import ImageIO
import Testing
import UIKit
@testable import AITools

struct PhotoReducerTests {
    static func image(width: Int, height: Int) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor.black.setFill()
            context.fill(CGRect(x: 40, y: 40, width: width / 2, height: 12))
        }
        return image.pngData() ?? Data()
    }
    static func size(of upload: ImageUpload) -> CGSize {
        guard let source = CGImageSourceCreateWithData(upload.data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat, let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else { return .zero }
        return CGSize(width: width, height: height)
    }

    @Test func aLargePhotoComesBackUnder2000pxAsJPEG() throws {
        let reduced = try #require(PhotoReducer.reduce(Self.image(width: 4000, height: 3000)))
        #expect(reduced.mediaType == "image/jpeg")
        #expect(reduced.data.prefix(3) == Data([0xFF, 0xD8, 0xFF]))
        let size = Self.size(of: reduced)
        #expect(size.width == 2000 && size.height == 1500)
        let small = try #require(PhotoReducer.reduce(Self.image(width: 800, height: 600)))
        #expect(Self.size(of: small) == CGSize(width: 800, height: 600), "never upscaled")
        #expect(PhotoReducer.reduce(Data("not an image".utf8)) == nil)
    }

    @Test func sixReducedPagesFitTheBody() throws {
        let page = try #require(PhotoReducer.reduce(Self.image(width: 3024, height: 4032)))
        #expect(Self.size(of: page).height == 2000)
        let total = page.base64.count * 6
        #expect(total < APIClient.bodyLimit, "six pages of a drawn page: \(total) characters")
    }
}
```

(A drawn page is far smaller than a photograph; the real check is the hand run's six photographs, Task 20.)

```swift
import Domain
import Foundation
import Testing
@testable import AITools

@MainActor struct PDFMakerTests {
    @Test func aPaperBecomesAPDFFileNamedAfterIt() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: GenerationResultFixture.paperJSON))   // the ten-question sample of FakeAIRepository.samplePaperJSON
        let url = try PDFMaker.pdf(for: result, title: "Quadratic equations")
        #expect(url.lastPathComponent == "Quadratic equations.pdf")
        let data = try Data(contentsOf: url)
        #expect(data.prefix(5) == Data("%PDF-".utf8))
        #expect(data.count > 2000)
    }
}
```

(`GenerationResultFixture.paperJSON` is `FakeAIRepository.samplePaperJSON` from Data; import Data and use it directly.)

- [ ] **Step 2: Run to see them fail.** The target does not exist yet: add `AIToolsTests` to `Package.swift` (`.testTarget(name: "AIToolsTests", dependencies: ["AITools", "Students"])`) and the scheme in `project.yml`, `bun gen`, then `bun check --only=ios` fails on the missing types.

- [ ] **Step 3: Implement.** `PhotoReducer.reduce(_ data:)`: `CGImageSourceCreateWithData`, `CGImageSourceCreateThumbnailAtIndex` with `[kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 2000, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceShouldCacheImmediately: true]` only when the longer side exceeds 2000 (else the image itself with the transform applied), then `UIImage(cgImage:).jpegData(compressionQuality: 0.7)`. `reduce(_ image:)` goes through `image.pngData()` or draws it at the reduced size with `UIGraphicsImageRenderer` (the camera's pages are UIImages). `PDFMaker`: a `UIGraphicsPDFRenderer(bounds: A4)`; the content is a SwiftUI `PaperPDFPage` view (the hero's title and line, then the sections and questions in the paper card's type styles, then the answer key) rendered by `ImageRenderer` whose `render { size, draw in … }` is called per page: the renderer draws the whole view's height into a context translated by `-pageIndex * pageHeight` inside `beginPage()` until the height is covered. The file goes to `FileManager.default.temporaryDirectory`.

- [ ] **Step 4: Run to see them pass; commit.** `git commit -am "AITools: the photo reducer and the PDF"`.

### Task 10: `AIStore`: forms, one generation at a time, results, history (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/AITools/AIStore.swift`, `AIStore+Generate.swift`, `AIToolsActions.swift`, `AITools.swift` (the marker deleted)
- Test: `ios/TutorCentralKit/Tests/AIToolsTests/AIStoreTests.swift`, `AIStoreGenerateTests.swift`

**Interfaces:**
- Consumes: `AIRepository`, `AIHistoryRepository`, `CentreRepository.recordAIConsent`, `MessageLogRepository.logProgress`, `any Register`, `Workspace`, the Domain types.
- Produces:

```swift
@MainActor @Observable public final class AIStore {
    public private(set) var workspace: Workspace
    public var forms: [GenerationKind: GenerateRequest]   // the drafts, one per kind, kept between visits
    public private(set) var history: [Generation]          // newest first, from the repository
    public private(set) var historyLoaded: Bool
    public private(set) var historyError: String?
    public private(set) var results: [UUID: Generation]    // what this session has seen
    public private(set) var inFlight: InFlight?            // the one call running
    public struct InFlight: Hashable, Sendable { public let kind: GenerationKind; public let request: GenerateRequest; public let regenerating: UUID?; public let line: String }
    public private(set) var failure: Failure?              // the last call's failure, for the form's error row
    public struct Failure: Hashable, Sendable { public let kind: GenerationKind; public let message: String; public let consent: Bool }
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    public var onResult: ((Generation) -> Void)?           // AppShell pushes the result route when the form is on top
    public var recent: [Generation]                         // the first three of history
    public var needsConsent: Bool                           // workspace.centre.aiConsentAt == nil
    public init(workspace: Workspace, register: any Register, ai: any AIRepository, history: any AIHistoryRepository, centres: any CentreRepository, messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
    public func workspaceChanged(_ workspace: Workspace)
    public func loadHistory() async
    public func generation(_ id: UUID) async -> Generation?   // results, then the repository
    /// Create: refused in words while one runs; the consent sheet first for a note without consent; the request runs in a Task the store owns.
    public func create(_ request: GenerateRequest) -> CreateOutcome
    public enum CreateOutcome: Hashable, Sendable { case started, busy, needsConsent, invalid }
    public func createAgain(_ generation: Generation) -> CreateOutcome
    public func cancel()                                     // cancels the Task; the row stays pending on the server (counts; a later build may clean it)
    public func retry()                                      // the last failed request
    public func recordConsent() async -> Bool                // writes ai_consent_at; merges through onWorkspaceChanged; false with a toast message when the write fails
    public func studentName(_ id: UUID) -> String?; className(_ id: UUID?) -> String?
    public func context(for request: GenerateRequest) -> GenerateContext   // the names the API needs; the attendance line from the register's student month (Task 11 passes it)
    public func noteMessage(_ generation: Generation, text: String) -> NoteMessage?   // the student, parent line, the text with the signature, the wa.me URL (nil without a number)
    public func openNote(_ generation: Generation, text: String) async   // logs progress, copies the text, opens the URL
    public var message: String?                              // a toast for the shell (a failed consent write, a copy)
}
public struct NoteMessage: Hashable, Sendable { public let studentID: UUID; public let headline: String; public let parentLine: String; public let text: String; public let url: URL? }
public struct AIToolsActions { public let openStudent: (UUID) -> Void; public let openResult: (UUID) -> Void; public let openForm: (GenerationKind) -> Void; public let openHistory: () -> Void; public init(…) }
```

- [ ] **Step 1: Write the failing tests** (`Tests/AIToolsTests/AIStoreTests.swift`; the second file holds the generation tests):

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import AITools

@MainActor struct AIStoreTests {
    static let now = FakeCountsRepository.fixedNow

    static func make(
        ai: FakeAIRepository = FakeAIRepository(), history: FakeAIHistoryRepository = FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed),
        centres: FakeCentreRepository = FakeCentreRepository(), workspace: Workspace = FakeCentreRepository.meeraWorkspaceConsented
    ) async -> AIStore {
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        return AIStore(workspace: workspace, register: register, ai: ai, history: history, centres: centres, messages: FakeMessageLogRepository(), now: { now })
    }

    @Test func historyLoadsNewestFirstAndRecentIsThree() async {
        let store = await Self.make()
        #expect(!store.historyLoaded && store.recent.isEmpty)
        await store.loadHistory()
        #expect(store.historyLoaded && store.history.count == 6 && store.recent.count == 3)
        #expect(store.history.first?.title(studentName: store.studentName) == "Quadratic equations")
        #expect(store.history[1].title(studentName: store.studentName) == "Hemanth Reddy", "the note names its student from the register")
        #expect(store.history.first?.line(className: store.className, calendar: DayHeading.india) == "Question paper · Class 10 Maths · Tue 6 Oct")
    }

    @Test func aFailedHistoryReadSaysSoAndKeepsNothingStale() async {
        let history = FakeAIHistoryRepository(generations: [])
        let store = await Self.make(history: history)
        history.nextError = URLError(.notConnectedToInternet)
        await store.loadHistory()
        #expect(store.historyError == "Couldn't load History. Check your connection and try again." && !store.historyLoaded)
        await store.loadHistory()
        #expect(store.historyError == nil && store.historyLoaded)
    }

    @Test func aResultIsFoundInMemoryThenInTheRepository() async throws {
        let store = await Self.make()
        let seeded = try #require(FakeAIHistoryRepository.seed.first)
        #expect(await store.generation(seeded.id)?.id == seeded.id)
        #expect(await store.generation(UUID()) == nil)
    }

    @Test func theNoteMessageCarriesTheSignatureAndTheParentsNumber() async throws {
        let store = await Self.make()
        let note = try #require(FakeAIHistoryRepository.seed.first { $0.kind == .progressNote })
        let message = try #require(store.noteMessage(note, text: "Hello Lakshmi, a short note."))
        #expect(message.headline == "Hemanth's progress note" && message.parentLine == "Lakshmi Reddy · +91 93802 60871")
        #expect(message.text == "Hello Lakshmi, a short note.\n\nMeera Nair\nBright Minds Tuition")
        #expect(message.url?.absoluteString.hasPrefix("https://wa.me/919380260871?text=") == true)
    }

    @Test func consentIsRecordedAndMerged() async {
        let centres = FakeCentreRepository()
        let store = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(store.needsConsent)
        var merged: Workspace?
        store.onWorkspaceChanged = { merged = $0 }
        #expect(await store.recordConsent())
        #expect(centres.consents.count == 1 && merged?.centre.aiConsentAt != nil && !store.needsConsent)
        centres.nextError = URLError(.notConnectedToInternet)
        let again = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(!(await again.recordConsent()) && again.message == "Couldn't save your agreement. Check your connection and try again.")
    }
}
```

`Tests/AIToolsTests/AIStoreGenerateTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import AITools

@MainActor struct AIStoreGenerateTests {
    static let maths = FakeClassesRepository.maths.id
    static let paper = GenerateRequest.paper(PaperForm(classID: maths, subject: "Mathematics", topic: "Quadratic equations"))

    @Test func aGenerationSurvivesLeavingTheScreen() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(60)
        let store = await AIStoreTests.make(ai: ai)
        var arrived: Generation?
        store.onResult = { arrived = $0 }
        #expect(store.create(Self.paper) == .started)
        #expect(store.inFlight?.line == "Writing 10 questions on Quadratic equations")
        // The form's screen is gone (nothing observes the store) and the call keeps running.
        try await Task.sleep(for: .milliseconds(120))
        #expect(store.inFlight == nil && arrived?.kind == .paper)
        #expect(store.history.first?.id == arrived?.id, "the new result leads History and Recent without a reload")
        #expect(ai.requests.count == 1)
    }

    @Test func aSecondCreateWhileOneRunsIsRefused() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(60)
        let store = await AIStoreTests.make(ai: ai)
        #expect(store.create(Self.paper) == .started)
        #expect(store.create(Self.paper) == .busy)
        #expect(store.message == "One at a time: the last one is still being written.")
        try await Task.sleep(for: .milliseconds(120))
        #expect(store.create(Self.paper) == .started)
    }

    @Test func aFailureKeepsTheFormAndOffersRetry() async throws {
        let ai = FakeAIRepository()
        let store = await AIStoreTests.make(ai: ai)
        ai.script = .failure(.service)
        #expect(store.create(Self.paper) == .started)
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure == Failure(kind: .paper, message: "The AI service didn't answer. Try again.", consent: false))
        #expect(store.forms[.paper] == Self.paper, "the form is still filled")
        ai.script = .answer
        store.retry()
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure == nil && store.history.first?.kind == .paper)
        ai.script = .failure(.limit(40))
        _ = store.create(Self.paper)
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure?.message == "You've made today's 40. Try again tomorrow.")
    }

    @Test func aNoteWithoutConsentAsksFirstAndAnInvalidFormIsRefused() async {
        let store = await AIStoreTests.make(workspace: FakeCentreRepository.meeraWorkspace)
        let note = GenerateRequest.progressNote(NoteForm(studentID: FakeStudentsRepository.akshita, observations: "Improving", tone: .warm))
        #expect(store.create(note) == .needsConsent)
        #expect(store.create(.paper(PaperForm())) == .invalid)
        #expect(store.create(Self.paper) == .started, "a paper needs no consent")
    }

    @Test func createAgainKeepsTheOldResultUntilTheNewOneLands() async throws {
        let ai = FakeAIRepository()
        let store = await AIStoreTests.make(ai: ai)
        await store.loadHistory()
        let old = try #require(store.history.first)
        ai.delay = .milliseconds(60)
        #expect(store.createAgain(old) == .started)
        #expect(store.inFlight?.regenerating == old.id)
        #expect(await store.generation(old.id) != nil, "the old one is still there")
        try await Task.sleep(for: .milliseconds(120))
        #expect(store.inFlight == nil && store.history.first?.id != old.id && store.history.count == 7)
    }

    @Test func theContextNamesTheClassTheStudentAndTheAttendance() async throws {
        let store = await AIStoreTests.make()
        let context = store.context(for: Self.paper)
        #expect(context.className == "Class 10 Maths" && context.subject == "Mathematics" && context.tutorName == "Meera Nair" && context.centreName == "Bright Minds Tuition")
        let hemanth = try #require(FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" })
        let note = store.context(for: .progressNote(NoteForm(studentID: hemanth.id, observations: "x", tone: .warm)))
        #expect(note.studentName == "Hemanth Reddy" && note.parentName == "Lakshmi Reddy" && note.className == "Class 10 Maths")
    }
}
```

(`Failure` is `AIStore.Failure`; write it so. `FakeCentreRepository.meeraWorkspaceConsented` and `consents` come from Task 7.)

- [ ] **Step 2: Run to see them fail.**

- [ ] **Step 3: Implement.** `create` checks `isValid`, `inFlight == nil` (else sets `message` and returns `.busy`), `kind.needsConsent && needsConsent` (returns `.needsConsent`: the view shows the consent sheet and calls `create` again after `recordConsent`), then stores the form, clears `failure`, sets `inFlight` and starts `Task { await run(request, regenerating:) }`: `ai.generate(request, context:)`, on success inserts the result at the head of `history` and `results`, clears `inFlight`, calls `onResult`; on `APIFailure` sets `failure` (`.consent` → the consent flag true, so the view opens the sheet) and clears `inFlight`; on `CancellationError` just clears. `cancel()` cancels the Task. `noteMessage` builds the headline "\(first name)'s progress note", the parent line from the student's `parentName` and `parentPhone?.display`, the text with the signature from the workspace's profile name and centre name, the URL `https://wa.me/<digits>?text=<percent-encoded>` (as `AbsenceMessage` does: reuse its encoding helper from Domain). `openNote` logs `progress`, sets the pasteboard (`UIPasteboard.general.string`) and opens the URL through `UIApplication.shared.open` (behind a `@MainActor` closure injected for tests: `openURL: (URL) async -> Void`, default the application). `context(for:)` reads the register for the class name and subject (`classroom.subject ?? form.subject`), the student's name and parent, and the attendance line from `register.student(id)?.thisMonth` and the month's attendance (the register has the fee state; the attendance line comes from `AttendanceRepository` as Today's store reads it: pass `attendance: any AttendanceRepository` to the store, read `sessions(centre:month:)` and count the student's marks: "2 of 3 classes attended · October fee due"; the test above does not assert it).

- [ ] **Step 4: Run to see them pass; commit.** `git commit -am "AITools: the store: forms, one generation at a time, results, history, the consent, the note message"`.

### Task 11: The AI Assistant screens (PR 4)

**Files:**
- Create: `AssistantView.swift`, `GenerateFormView.swift`, `FormPieces.swift`, `StudentPickerSheet.swift`, `ResultView.swift`, `ResultFooter.swift`, `NoteResultView.swift`, `NoteSendSheet.swift`, `HistoryView.swift` (all in `Sources/Features/AITools/`)
- Test: proven by the pictures (Task 13) and the store's tests; `AssistantView.recentTitle(for:)`-style pure helpers are `nonisolated static func`s with a test each in `AIStoreTests` when they carry words.

**Interfaces:**

```swift
public enum AIBoardState: Sendable { case generating, failed, regenerating, noteSend, studentPicker, consent }
public struct AssistantView: View { public init(store: AIStore, actions: AIToolsActions, boardState: AIBoardState? = nil) }
public struct GenerateFormView: View { public init(store: AIStore, kind: GenerationKind, actions: AIToolsActions, boardState: AIBoardState? = nil, showsFocus: Bool = false) }
public struct ResultView: View { public init(store: AIStore, generationID: UUID, actions: AIToolsActions, boardState: AIBoardState? = nil) }   // a paper, homework or worksheet; a note hands to NoteResultView
public struct HistoryView: View { public init(store: AIStore, actions: AIToolsActions) }   // ConsentSheet is DesignSystem's (Task 8)
```

- [ ] **Step 1: Build each screen to its board**, pieces and copy from `components.md` ("Phase 6 parts"):
  - **AssistantView** (P6-Assistant, -Light, -Empty): a `ScrollView` with `BackRow(title: "AI Assistant", action: ("History", openHistory))`, the lead line (`intro` style, `text2`), `SectionHeader("Create")` over a `Card` of four `ToolRow`s (`GenerationKind.allCases`: symbol, title, line; `openForm`), `SectionHeader("Recent", action: ("See all", openHistory))` when `recent` is not empty over a `Card` of `HistoryRow`s (`openResult`), else a `Card { EmptyRow(symbol: "sparkles", title: "Nothing created yet", line: "Papers, homework, worksheets and notes you create appear here, ready to open again.") }`, the AI line as a `footnote` in `text3`. `.task { await store.loadHistory() }`; the nav bar and tab bar hidden (`toolbar(.hidden, for:)`), as PaymentsView.
  - **GenerateFormView** (P6-Form-Paper, -Homework, -Worksheet, -ProgressNote, P6-Generating, P6-Generate-Failed): `BackRow(title: kind.title)`; a `Card { VStack(spacing: Tokens.rowPaddingHorizontal) { fields }.padding(Tokens.rowPaddingHorizontal) }` of `FormPieces` by kind: `PickerTile("Class", value:)` opening a popover menu of `register.activeClasses` (the first active class chosen by default; choosing one refills `subject` with the class's subject unless the tutor edited it), `TextWell("Subject", …, helper: "From the class. Change it for another subject.")`, `TextWell("Topic", …, showsFocus:, autofocus:)`, `Segmented` for the level under a `label`, `PickerTile("Questions", value: "10")` and `PickerTile("Marks", value: "20")` opening a wheel `Picker` in a popover over the range, `Switch` row "Answer key at the end" with its line; the note: `PickerTile("Student", value:)` with the helper line (class · parent and number), a `Banner(symbol: "info.circle", text: "This month: 2 of 3 classes attended · October fee due")`, `MultilineWell(label: "What you have seen", text:, placeholder: "", limit: 2000)`, `Segmented` for the tone under "Tone"; the `footnote` under the card (the board's words per kind); the footer (`.safeAreaInset(edge: .bottom)`) with `FooterButton { Button(kind.createLabel, systemImage: "sparkles") { … }.buttonStyle(.primary(.card, loading: store.inFlight?.kind == kind)).disabled(!request.isValid) }`. While `store.inFlight?.kind == kind`: the card at `Tokens.opacityDisabled` and `allowsHitTesting(false)`, and a `CreatingCard(title: inFlight.line, line: "Usually under a minute. You can wait here or come back from History.", cancel: store.cancel)` in the footnote's place; when `store.failure?.kind == kind`: `ErrorRow(title: "Couldn't create the paper.", line: "Check your connection and try again. Nothing was used up.", retry: store.retry)` (the limit failure's title is the failure's message and `retry` nil). Create: `switch store.create(request) { case .needsConsent: consent = true … }`; `.onChange(of: store.inFlight)`: nothing (AppShell's `onResult` pushes). `.sheet(isPresented: $pickingStudent) { StudentPickerSheet(students: register.activeStudents, chosen:, pick:) }` at `.large` with `SearchWell`, a `Card(.onSheet)` of rows (avatar, name, class line, the tick in `accentText` or a ring). `.sheet(isPresented: $consent) { ConsentSheet(centreName:, agree: store.recordConsent, close:) }` (DesignSystem's, P6-Scan-Consent's words with the centre's name; `.fraction(0.45)`; on agree the Create runs again).
  - **ResultView** (P6-Result-Paper, -Light, -Regenerating): `BackRow(title: kind.title)`; `ResultHero(eyebrow: "\(className) · \(subject)", title:, line: generation.heroLine(today:calendar:))`; `SectionHeader("Paper")` with, while `store.inFlight?.regenerating == id`, a trailing `HStack { RefreshSpinner(); Text("Creating again") }`; a `Card` of `SectionRow`s and `QuestionRow`s, the answer key as the last `SectionRow("Answer key", line: "")` with `QuestionRow(number:, text: answer, marks: nil)`; homework and worksheets: one `SectionRow(title, line: instructions ?? "")` then the questions without marks, then the key (a worksheet with `withAnswers` false shows the key under "Answer key (for you)"). The whole content at `Tokens.opacityStale` while regenerating. `ResultFooter` in `.safeAreaInset(edge: .bottom)`: `FooterButton { VStack(spacing: Tokens.rowPaddingDense) { footnote AI line; quiet "Create again" (or the footnote "A new paper is on its way. This one stays until it arrives." while regenerating); HStack { Button("Copy", systemImage: "doc.on.doc") …; ShareLink(item: pdfURL, …) { Label("Share as PDF", systemImage: "square.and.arrow.up") } } } }`, the buttons `.secondary(.form)`, disabled while regenerating. Copy puts `PaperText.plain(result)` on the pasteboard and toasts "Copied."; the PDF is made lazily when the share is tapped (`PDFMaker`), a failure toasts "Couldn't make the PDF. Copy the text instead.". When the regeneration lands, `store.onResult` pushes the new result over this one.
  - **NoteResultView** (P6-Result-ProgressNote, P6-ProgressNote-Send): `BackRow(title: "Progress note")`; the student line (avatar 56, name `title3`, parent line `subhead` `text2`); `MultilineWell(label: "Note", text: $text, placeholder: "", limit: 4000)` 220 high with the helper; the footer: the AI line, `HStack { Copy; Write again (secondary, "arrow.clockwise") }`, the primary `Send on WhatsApp` (`message` symbol as the alert) opening `NoteSendSheet` = `MessageSheet(title: "Send the note", name:, headline:, parentLine:, label: "Message", text: message.text, note: "Opens WhatsApp with the note ready to send. We note the date on Hemanth's page. The text is copied too, in case WhatsApp can't open.", canOpen: message.url != nil, open: { await store.openNote(generation, text: text) }, close:)` at `.fraction(0.75)`; a student without a number shows the sheet with the button disabled and the line "Add the parent's number first" in place of the note (the fees sheets' precedent).
  - **HistoryView** (P6-History, -Empty): `BackRow(title: "History")`; groups by month (`Eyebrow("October")` over a `Card` of `HistoryRow`s), the footnote "Results are kept for your centre. Scans and checked papers are not listed here; what you added or saved is on the student's page."; empty: the `EmptyRow` card; a failed read: the error line with Retry (the attendance `ErrorLine` pattern: a `footnote` in `overdue` with a quiet Retry).
- [ ] **Step 2: `bun check --only=format,lint,ios` green; commit.** `git commit -am "AITools: the Assistant, the forms, the student picker, creating, the results, the note on WhatsApp, History"`.

### Task 12: AppShell: the routes, the store, More's rows, Today's row, the consent merge (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/AppShell/RootView+AITools.swift`
- Modify: `TabsState.swift` (routes `.aiAssistant`, `.aiForm(GenerationKind)`, `.aiResult(UUID)`, `.aiHistory`), `TabsView.swift` (`moreDestination` and `todayDestination` gain them; `todayDestination` exists for Schedule: extend it), `ShellState.swift` (`@ObservationIgnored var ai: AIStore?`, reset with the rest), `Dependencies.swift` (Task 6 added `ai`, `aiHistory`), `MoreView.swift` (the three `LaterRow`s become `SettingRow`s: `open(.aiAssistant)`, `open(.checkPaper)` (Task 19's route; until then it pushes `.aiAssistant`'s sibling: add the `Route` case now and let its destination be `LaterView(place: .checkPaper)`: no, `LaterPlace` goes in PR 5; in PR 4 `Check a paper` and `Scan register` stay `LaterRow`s and only AI Assistant goes live; PR 5 and PR 6 flip theirs), `RootView+Today.swift` (`TodayActions` gains `openAI: { shell.tabs.push(.aiAssistant) }`; `Features/Today/TodayView.swift` gains the Create section at the end: `SectionHeader("Create")` over a `Card(.compact) { TileRow(symbol: "sparkles", title: "Create with AI", line: "A paper, homework, a worksheet or a progress note", action: actions.openAI) }` (P6-Today-AITools; `TileRow` exists in `Tiles.swift`; use the Classes row's shape from `StudentsListSections` as the model), `TodayBoardState` gains `.aiRow` which scrolls to the end as `.addingTask` scrolls to Coming up)
- Test: `Tests/AppShellTests/TabsStateTests.swift` (+ `theAIRoutesPushOnTheTabThatAsked`)

**Interfaces:**

```swift
extension RootView {
    func aiStore(for workspace: Workspace) -> AIStore   // one per centre on shell.ai; onWorkspaceChanged merges takingAIConsent; onResult pushes .aiResult(id) when the tab's top route is .aiForm(kind) (or .aiResult(old) when regenerating), else nothing
    var aiToolsActions: AIToolsActions   // openStudent: push .student(id) on the Students tab (select it first); openResult: push .aiResult; openForm: push .aiForm; openHistory: push .aiHistory
    @ViewBuilder func assistant() -> some View; aiForm(_ kind: GenerationKind) -> some View; aiResult(_ id: UUID) -> some View; aiHistory() -> some View   // built with the store and the launch's board state
}
```

- [ ] **Step 1: Write the failing test** (`TabsStateTests`):

```swift
    @Test func theAIRoutesPushOnTheTabThatAsked() {
        let tabs = TabsState()
        tabs.select(.more)
        tabs.push(.aiAssistant)
        tabs.push(.aiForm(.paper))
        #expect(tabs.paths[.more] == [.aiAssistant, .aiForm(.paper)])
        tabs.select(.today)
        tabs.push(.aiAssistant)
        #expect(tabs.paths[.today] == [.aiAssistant] && tabs.paths[.more]?.count == 2, "each tab keeps its own stack")
        let id = UUID()
        tabs.push(.aiResult(id))
        #expect(tabs.paths[.today]?.last == .aiResult(id))
        tabs.remove(.aiResult(id))
        #expect(tabs.paths[.today] == [.aiAssistant])
    }
```

- [ ] **Step 2: Run to see it fail; implement** as the interface. `onResult`: `if shell.tabs.paths[shell.tabs.selected]?.last == .aiForm(generation.kind) || (inFlight.regenerating.map { .aiResult($0) } == last) { shell.tabs.push(.aiResult(generation.id)) }`. The store's `message` reaches the toasts as Today's does (`.onChange(of: store.message)`).
- [ ] **Step 3: `bun check` green; commit.** `git commit -am "AppShell: the AI Assistant's routes and store, More's row, Today's Create row, the consent merge"`.

### Task 13: The Assistant's launch states, the fixtures, the pictures (PR 4)

**Files:**
- Modify: `LaunchState.swift` (+ `aiAssistant = "ai-assistant"`, `aiAssistantEmpty`, `aiPaper`, `aiHomework`, `aiWorksheet`, `aiNote`, `aiNoteStudent`, `aiGenerating`, `aiGenerateFailed`, `aiResultPaper`, `aiResultRegenerating`, `aiResultNote`, `aiNoteSend`, `aiHistory`, `aiHistoryEmpty`, `todayAI = "today-ai"`), `RootView+LaunchStates.swift` (the tab is `.more` for the `ai-*` states, `.today` for `today-ai`; `initialRoutes`: `[.aiAssistant]`; `[.aiAssistant, .aiForm(.paper)]`; `[.aiAssistant, .aiResult(Fixtures.quadraticID)]`; `[.aiAssistant, .aiHistory]`; the board states: `aiNoteStudent → .studentPicker`, `aiGenerating → .generating`, `aiGenerateFailed → .failed`, `aiResultRegenerating → .regenerating`, `aiNoteSend → .noteSend`), `Fixtures.swift` and `Fixtures+AI.swift` (the `FakeAIRepository` script per state: `ai-generating` and `ai-result-regenerating` a delay of an hour; `ai-generate-failed` `.failure(.service)`; `FakeAIHistoryRepository(generations: state == .aiAssistantEmpty || state == .aiHistoryEmpty ? [] : seed)`; the forms prefilled by state: the paper form with Class 10 Maths and "Quadratic equations", the homework with Class 8 Science and "Cell structure", the worksheet with "Linear equations in two variables", Easy, 12, the note with Hemanth and the board's observations; the generating and failed states start with the paper's Create already tapped (the view's `boardState` triggers it `onAppear`), the regenerating state with Create again tapped on the Quadratic equations result)
- Test: `LaunchStateTests` (the new states have fixtures and start on their tab with their routes)

- [ ] **Step 1: Add the states, the fixtures, the board-state wiring.** `LaunchStateTests.everyBoardStateHasAFixture` covers them; add `theAIStatesStartOnTheMoreTabAtTheirRoute` asserting the tab and the routes of five of them.
- [ ] **Step 2: `bun check` green. Shots:** `bun shots <state>` for the 17 states in the PR table (both appearances), compared beside their boards (a contact sheet with PIL as session 11 did); differences that are the data's are noted in the PR, differences that are the build's are fixed.
- [ ] **Step 3: `bun pr-shots phase-6-assistant <files>`; open PR 4 with the table; merge when green.**

---

### Task 14: `ScanStore`: the consent gate, the photo, reading, the list, edits, Undo (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/ScanStore.swift`, `ScanStore+Add.swift`
- Modify: `Features/Students/StudentsActions.swift` (`openScanRegister` stays; AppShell pushes `.scanRegister`), `RegisterStore.swift` (nothing: `refresh()` is called after Add)
- Test: `ios/TutorCentralKit/Tests/StudentsTests/ScanStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class ScanStore {
    public enum Stage: Hashable, Sendable { case intro, reading, review, nothing, failed(String) }
    public private(set) var stage: Stage
    public private(set) var photo: ImageUpload?         // the reduced photo, kept for Retry
    public var rows: [ScanRow]
    public var classID: UUID?                           // "Add to": the first active class by default, nil = No class
    public private(set) var generationID: UUID?
    public private(set) var adding: Bool
    public private(set) var removed: (row: ScanRow, index: Int)?   // for the toast's Undo (a struct RemovedRow)
    public var message: String?                         // toasts
    public var needsConsent: Bool
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    public var onAdded: ((Int) -> Void)?                // AppShell pops to the list and toasts with Undo
    public init(workspace: Workspace, register: RegisterStore, ai: any AIRepository, students: any StudentsRepository, centres: any CentreRepository, now: @escaping @Sendable () -> Date)
    public func recordConsent() async -> Bool
    public func read(_ upload: ImageUpload) async      // stage reading; the API; rows flagged against the register; stage review, nothing or failed
    public func retry() async                          // the same photo again
    public func reset()                                // back to the intro (another photo)
    public var ticked: [ScanRow]; public var title: String; public var addLabel: String; public var canAdd: Bool
    public func update(_ row: ScanRow)                 // from Fix this row
    public func remove(_ id: UUID)                     // keeps it for Undo
    public func undoRemove()
    public func add() async -> Int?                    // createMany of the ticked drafts; refresh the register; the count; nil on failure (a toast with Retry)
    public func undoAdd(ids: [UUID]) async -> Bool     // deleteMany; refresh; false with a toast on failure
    public private(set) var lastAdded: [UUID]
    public var hasRows: Bool                           // Back asks when true
}
```

- [ ] **Step 1: Write the failing tests** (`Tests/StudentsTests/ScanStoreTests.swift`):

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct ScanStoreTests {
    static let now = FakeCountsRepository.fixedNow
    static let photo = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 0]), mediaType: "image/jpeg")

    static func make(ai: FakeAIRepository = FakeAIRepository(), students: FakeStudentsRepository = FakeStudentsRepository(students: FakeStudentsRepository.seed),
                     centres: FakeCentreRepository = FakeCentreRepository(), workspace: Workspace = FakeCentreRepository.meeraWorkspaceConsented) async -> ScanStore {
        let register = RegisterStore(workspace: workspace, students: students, classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now })
        await register.load()
        return ScanStore(workspace: workspace, register: register, ai: ai, students: students, centres: centres, now: { now })
    }

    @Test func readingFlagsTheRowsAgainstTheRegister() async {
        let store = await Self.make()
        await store.read(Self.photo)
        #expect(store.stage == .review && store.rows.count == 8 && store.title == "8 found")
        let dev = store.rows[2]
        #expect(dev.name == "Dev Kumar" && !dev.included && dev.flag == .alreadyHere(name: "Dev Kumar", className: "Class 8 Science"))
        #expect(store.rows[3].flag == .noNumber && store.rows[3].included)
        #expect(store.ticked.count == 7 && store.addLabel == "Add 7 students" && store.canAdd)
        #expect(store.classID == FakeClassesRepository.maths.id, "the first active class by default")
    }

    @Test func nothingAndAFailureHaveTheirStages() async {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai)
        ai.scanRows = []
        await store.read(Self.photo)
        #expect(store.stage == .nothing)
        ai.script = .failure(.service)
        await store.retry()
        #expect(store.stage == .failed("The AI service didn't answer. Try again.") && store.photo == Self.photo)
        ai.script = .failure(.consent)
        await store.retry()
        #expect(store.stage == .intro && store.needsConsent, "the server said no consent: back to the intro, the sheet asks")
    }

    @Test func editingRemovingAndUndoingStayOnTheDevice() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        await store.read(Self.photo)
        var kavya = try #require(store.rows.first { $0.name == "Kavya Nair" })
        kavya.phone = PhoneNumber(e164: "+919876500000")
        kavya.parentName = "Asha Nair"
        store.update(kavya)
        #expect(store.rows.first { $0.id == kavya.id }?.flag == nil, "a number fixed is no longer flagged")
        store.remove(kavya.id)
        #expect(store.rows.count == 7 && store.title == "7 found" && store.addLabel == "Add 6 students")
        store.undoRemove()
        #expect(store.rows.count == 8 && store.rows[3].id == kavya.id, "back where it was")
        #expect(students.createdMany.isEmpty, "nothing written")
    }

    @Test func addWritesTheTickedRowsOnceAndUndoDeletesThem() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        await store.read(Self.photo)
        var added: Int?
        store.onAdded = { added = $0 }
        let count = await store.add()
        #expect(count == 7 && added == 7 && students.createdMany.count == 1 && students.createdMany[0].count == 7)
        let drafts = try #require(students.createdMany.first)
        #expect(drafts.allSatisfy { $0.classID == FakeClassesRepository.maths.id })
        #expect(drafts.first { $0.trimmedName == "Rohan Gupta" }?.fee == Money(rupees: 1500) && drafts.first { $0.trimmedName == "Aarav Mehta" }?.fee == Money(rupees: 1200))
        #expect(!drafts.contains { $0.trimmedName == "Dev Kumar" })
        #expect(store.lastAdded.count == 7)
        #expect(await store.undoAdd(ids: store.lastAdded))
        #expect(students.deleted == [store.lastAdded])
        students.nextError = URLError(.notConnectedToInternet)
        await store.read(Self.photo)
        #expect(await store.add() == nil && store.message == "Couldn't add them. Check your connection and try again.")
    }

    @Test func consentIsAskedBeforeTheFirstPhotoAndRecorded() async {
        let centres = FakeCentreRepository()
        let store = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(store.needsConsent)
        var merged: Workspace?
        store.onWorkspaceChanged = { merged = $0 }
        #expect(await store.recordConsent() && !store.needsConsent && merged?.centre.aiConsentAt != nil && centres.consents.count == 1)
    }
}
```

(`FakeAIRepository` gains `scanRows: [ScanRowDTO]` as a settable override of the sample: add it in Task 6's fake; `FakeStudentsRepository.createMany` records the drafts and makes students with new ids.)

- [ ] **Step 2: Run to see them fail; implement** as the interface (`read`: `stage = .reading`, `ai.scanRegister(photo, centre:)`, rows through `ScanReview.flag(rows, against: register.activeStudents, classes: register.activeClasses)` where the DTOs become `ScanRow`s (`PhoneNumber(e164:)` of the API's phone, `Money` of the fee, `included` true, no parent name), `.nothing` when empty, `.failed(message)` on `APIFailure` except `.consent` (sets `needsConsent`, `stage = .intro`); `add`: `createMany(ticked.map { $0.draft(classID: classID) }, centre:)`, `register.refresh()`, `lastAdded`, `onAdded(count)`; `undoAdd`: `deleteMany`, `register.refresh()`).
- [ ] **Step 3: Commit.** `git commit -am "Students: the scan store: reading, the list to check, edits and Undo on the device, Add and its Undo"`.

### Task 15: The Scan register screens (PR 5)

**Files:**
- Create: `Features/Students/ScanRegisterView.swift`, `ScanReviewView.swift`, `ScanReadingView.swift`, `FixRowSheet.swift`
- Modify: `Features/Students/StudentsView.swift` (the menu and the empty card call `actions.openScanRegister`, unchanged), `AppShell/RootView+Students.swift` (`openScanRegister: { shell.tabs.push(.scanRegister) }`; the destination builds `ScanRegisterView` with a fresh `ScanStore` in `@State`, `onAdded` pops the stack to the root and toasts `ScanReview.addedToast(count:)` with Undo running `undoAdd`), `TabsState.swift` (`.scanRegister`), `TabsView.swift`, `LaterView.swift` and `LaterPlace` (deleted: no place is left; `Route.later` goes with it; `laterStudents`, `laterAttendance`, `laterMore` launch states stay as they are if they still build, else they go too, with `P2-Later`'s board noted as superseded in `information-architecture.md`), `MoreView.swift` (Scan register live: `open(.scanRegister)`), `ios/App/Info.plist` (the camera text)

**Interfaces:**

```swift
public enum ScanBoardState: Sendable { case consent, cameraRefused, reading, review, edit, rowRemoved, leave, nothing, failed }
public struct ScanRegisterView: View { public init(store: ScanStore, boardState: ScanBoardState? = nil) }   // one screen with the stages; its own navigation title hidden, BackRow
```

- [ ] **Step 1: Build each state to its board** (`components.md`, "Phase 6 parts"):
  - **Intro** (P6-Scan-Intro): `BackRow(title: "Scan register")`; `IntroHero(symbol: "doc.viewfinder", title: "Read a paper register", line: …)`; `NoticesCard([lock, checkmark])`; `Button("Take a photo", systemImage: "camera")` primary `.card` and `PhotosPicker(selection:, maxSelectionCount: 1, matching: .images) { Label("Choose from Photos", systemImage: "photo.on.rectangle") }` secondary; the AI footnote. Take a photo: `CameraAccess.decide(supported: DocumentCameraView.isSupported, status:)` → `.scan` presents `DocumentCameraView(maxPages: 1, …)` as `.fullScreenCover`; `.ask` requests and then presents or shows the refused toast; `.denied` toasts "Allow the camera for Tutor Central in Settings." with the action ("Open Settings", `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString))`) (P6-Scan-CameraRefused); `.noCamera` toasts `CameraAccess.noCameraMessage` (the simulator). Both ways in run `PhotoReducer.reduce` (a failure toasts "Couldn't read that picture.") and then, when `store.needsConsent`, the `ConsentSheet` first (P6-Scan-Consent; agree → `recordConsent` → `read`), else `read` at once.
  - **Reading** (P6-Scan-Reading): `CreatingCard(title: "Reading the register", line: "Usually under a minute.", thumbnail: the photo, cancel:)` (Cancel: `reset()`; the call is abandoned, the row stays pending).
  - **Review** (P6-Scan-Review, -RowRemoved, -Leave, -Edit): `BackRow(title: "Check the list")` whose back asks `DialogView(title: "Leave without adding?", message: "The names read from the photo will be lost. Nothing has been saved.", cancel: "Keep checking", action: "Leave", destructive: false)` over the screen when `hasRows`; `PickerTile("Add to", value: className ?? "No class")` with a popover menu of the active classes and No class, the helper under it; `SectionHeader(store.title, action: ("Add a row", addRow))` (a blank `ScanRow`, ticked, opened in Fix this row); a `Card` of `ReviewRow`s (included binding → `update`; open → `FixRowSheet`); the footer: the footnote and the primary `store.addLabel` (`person.badge.plus`), disabled when `!canAdd`, loading while adding. Remove (from the sheet) → `store.remove` and the toast `"\(name) removed."` with Undo → `undoRemove`.
  - **Fix this row** (P6-Scan-Review-Edit): `StudentFormSheet(store: StudentFormStore(mode: .new, classes:, today:), …)` prefilled from the row (`name`, `digits`, `parentName`, `feeText`, `classID`), its title "Fix this row" (add a `title` override to `StudentFormStore` or a `heading:` parameter to the sheet: a one-line change in Students), `onSave` → `store.update(row from the draft)` and close; a `Remove this row` destructive quiet button under the fields (`FixRowSheet` wraps the form sheet with the extra button; the helper under the phone: "Nothing was read for the number. Type it, or leave it empty and add it later." when the row's flag is `.noNumber`).
  - **Nothing** (P6-Scan-Nothing): the reading card without the skeleton ("No names found", "Nothing on this photo read as a name."), `Card { EmptyRow(symbol: "doc.viewfinder", title: "Try another photo", line: "The whole page, straight on, in good light. One page at a time reads best.") }`, the two buttons (Take another photo primary; Choose from Photos).
  - **Failed** (P6-Scan-Failed): the reading card ("Reading the register", "The photo is still here."), `ErrorRow(title: "Couldn't read the register.", line: "Check your connection and try again. The photo is sent again as it is.", retry: { Task { await store.retry() } })`, `Take another photo` secondary (`reset()`).
  - **Saved** (P6-Scan-Saved): AppShell: after `onAdded`, `shell.tabs.paths[.students] = []` and `toasts.show(ScanReview.addedToast(count:), action: ("Undo", { Task { await store.undoAdd(ids: ids) } }))`; the list shows the new rows through the register's refresh.
- [ ] **Step 2: The launch states**: `scanIntro = "scan-intro"`, `scanConsent`, `scanCameraRefused`, `scanReading`, `scanReview`, `scanReviewEdit`, `scanReviewRemoved`, `scanReviewLeave`, `scanNothing`, `scanFailed`, `scanSaved` (the Students root with seventeen students in the fake and the toast up: the fixture seeds the seven added and AppShell shows the toast `onAppear` for that state); `students-add-menu` and `students-empty` re-shot (their scan entries are live). Fixtures: `scan-reading` a delay of an hour; `scan-review*` start past the reading (the view's `boardState` calls `read` with the fake's rows `onAppear`); `scan-nothing` empty rows; `scan-failed` `.failure(.service)`; `scan-consent` the unconsented workspace with the sheet up; `scan-camera-refused` the intro with the toast up.
- [ ] **Step 3: `bun check` green; the shots of the 13 states beside their boards; D36 in `plan/README.md`; `bun pr-shots phase-6-scan-register …`; open PR 5; merge when green.**

### Task 16: The Scan register write proof in the simulator (PR 5, before merge)

- [ ] **Step 1:** `xcrun simctl addmedia booted tools/samples/register-page.png`; the local API with `AI_FAKE=1`; the app against the local stack by the runbook: More → Scan register → Choose from Photos → the page → the consent sheet → I agree, continue (`psql`: `ai_consent_at` set) → the list (8 found, Dev Kumar unticked) → tap Kavya Nair → type a number → Save → Add 7 students → the list with 17 and the toast → Undo → 10 again. `psql` after Add: `select count(*) from students where centre_id = '2222…'` → 17, after Undo → 10; `ai_generations`: one `scan_register` row, `ok`, `input` `{"kind":"scan_register","pages":1,"bytes":…}`. Screenshots kept in `.shots/run/scan/`, attached to the PR.

### Task 17: `CheckStore` and the check's pieces (PR 6)

**Files:**
- Create: `Features/AITools/CheckStore.swift`, `CheckStore+Marks.swift`
- Test: `Tests/AIToolsTests/CheckStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class CheckStore {
    public enum Stage: Hashable, Sendable { case intro, pages, scheme, checking, result, failed(String) }
    public private(set) var stage: Stage
    public var studentID: UUID?
    public private(set) var pages: [ImageUpload]      // reduced, in order, at most 6
    public var scheme: SchemeSource                  // .paper(generationID) or .typed(text); the segmented control switches between the last of each
    public private(set) var papers: [Generation]     // the centre's papers, homework and worksheets from History (the scheme choices)
    public private(set) var result: CheckResult?
    public private(set) var title: String            // the scheme's paper title, or "Typed scheme"
    public private(set) var saved: Bool
    public private(set) var saving: Bool
    public var message: String?
    public var needsConsent: Bool
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    public var onStudentChanged: (() -> Void)?       // AppShell refreshes the register after Save or Undo
    public init(workspace: Workspace, register: any Register, ai: any AIRepository, history: any AIHistoryRepository, students: any StudentsRepository, centres: any CentreRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
    public func loadPapers() async
    public func addPages(_ uploads: [ImageUpload])   // up to 6 together; over: message "Up to six pages. The extra ones were left out."
    public func removePage(at index: Int)
    public var canContinue: Bool                     // a student chosen and at least one page
    public func check() async                        // stage checking; the API; result clamped; stage result or failed
    public func retry() async
    public func set(question: Int, to marks: Int)    // MarkEdit.set
    public var student: Student?; public var saveLabel: String; public var shareText: String; public var totalLine: String   // "14" / "of 20" are the hero's; the line "10 questions · 2 pages · checked today"
    public func save() async -> Bool                 // the note line appended; refused in words on overflow; the toast with Undo is the view's (saved true)
    public func undoSave() async -> Bool             // the previous notes written back exactly
    public private(set) var previousNotes: String?
}
```

- [ ] **Step 1: Write the failing tests** (`CheckStoreTests.swift`):

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import AITools

@MainActor struct CheckStoreTests {
    static let now = FakeCountsRepository.fixedNow
    static let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 1]), mediaType: "image/jpeg")
    static let hemanth = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id ?? UUID()

    static func make(ai: FakeAIRepository = FakeAIRepository(), students: FakeStudentsRepository = FakeStudentsRepository(students: FakeStudentsRepository.seed)) async -> CheckStore {
        let workspace = FakeCentreRepository.meeraWorkspaceConsented
        let register = RegisterStore(workspace: workspace, students: students, classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now })
        await register.load()
        let store = CheckStore(workspace: workspace, register: register, ai: ai, history: FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed), students: students, centres: FakeCentreRepository(), now: { now })
        store.studentID = hemanth
        return store
    }

    @Test func pagesAreCappedAtSixAndTheSchemeComesFromHistoryOrIsTyped() async {
        let store = await Self.make()
        store.addPages(Array(repeating: Self.page, count: 7))
        #expect(store.pages.count == 6 && store.message == "Up to six pages. The extra ones were left out.")
        store.removePage(at: 0)
        #expect(store.pages.count == 5 && store.canContinue)
        await store.loadPapers()
        #expect(store.papers.map { $0.title(studentName: { _ in nil }) } == ["Quadratic equations", "Photosynthesis", "Linear equations in two variables", "Light and reflection", "Trigonometry basics"], "notes are not schemes")
        store.scheme = .typed("Q1 (1) b")
        #expect(store.scheme.isValid)
    }

    @Test func checkClampsAndFailsInWords() async throws {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai)
        store.addPages([Self.page, Self.page])
        let paper = try #require(FakeAIHistoryRepository.seed.first)
        store.scheme = .paper(generationID: paper.id)
        await store.check()
        #expect(store.stage == .result && store.result?.total == 14 && store.result?.outOf == 20 && store.title == "Quadratic equations")
        #expect(store.totalLine == "10 questions · 2 pages · checked today")
        #expect(ai.checks == [SchemeSource.paper(generationID: paper.id)])
        ai.script = .failure(.tooLarge)
        await store.retry()
        #expect(store.stage == .failed("That's too many pages. Up to six, and try sharper, smaller photos."))
    }

    @Test func saveAppendsAndUndoRestoresExactly() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        store.addPages([Self.page])
        store.scheme = .typed("Q1 (1) b")
        await store.check()
        store.set(question: 6, to: 2)
        #expect(store.result?.total == 15 && store.saveLabel == "Save 15 of 20 to Hemanth's notes")
        #expect(await store.save())
        let update = try #require(students.notesUpdates.last)
        #expect(update.id == Self.hemanth && update.notes == "7 Oct · Typed scheme · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted.")
        #expect(store.saved && store.previousNotes == nil)
        #expect(await store.undoSave())
        #expect(students.notesUpdates.last?.notes == nil && !store.saved, "nil goes back as nil")
        // Full notes refuse in words.
        let full = String(repeating: "x", count: 1990)
        _ = try await students.updateNotes(id: Self.hemanth, notes: full)
        let again = await Self.make(students: students)
        again.addPages([Self.page]); again.scheme = .typed("Q1 (1) b")
        await again.check()
        #expect(!(await again.save()) && again.message == "Hemanth's notes are full. Share the marks instead, or shorten the notes first.")
    }
}
```

(`FakeStudentsRepository.notesUpdates` is `[NotesUpdate]` with `id` and `notes`; `ai.checks` records the scheme passed.)

- [ ] **Step 2: Run to see them fail; implement.** `save`: `NotesAppend.append(StudentNoteLine.make(day: today, title:, result:, calendar:), to: student.notes)` (nil → message overflow, false), remembers `previousNotes = student.notes`, `students.updateNotes(id:notes:)`, `saved = true`, `onStudentChanged`; `undoSave`: `updateNotes(id:, notes: previousNotes)`. `shareText`: the title, the student, then "Q1 · 1 of 1 · Correct" per row and the total.
- [ ] **Step 3: Commit.** `git commit -am "AITools: the check store: pages, the scheme, checking, marks, save and its undo"`.

### Task 18: The Check a paper screens (PR 6)

**Files:**
- Create: `Features/AITools/CheckIntroView.swift`, `CheckPagesView.swift`, `CheckSchemeView.swift`, `CheckingView.swift`, `CheckResultView.swift`
- Modify: `AppShell/RootView+AITools.swift` (`.checkPaper` builds `CheckIntroView` with a `@State` `CheckStore`; its stages push `.checkPages`, `.checkScheme`, `.checkResult` on the same tab, carrying the store through the environment (`.environment(store)`), as the schedule's sheets do), `TabsState.swift` (the three routes), `MoreView.swift` (Check a paper live)

**Interfaces:**

```swift
public enum CheckBoardState: Sendable { case markPicker, edited, saved, failed }
public struct CheckIntroView: View { public init(store: CheckStore, actions: AIToolsActions, boardState: CheckBoardState? = nil) }
public struct CheckPagesView: View { public init(store: CheckStore, boardState: CheckBoardState? = nil) }
public struct CheckSchemeView: View { public init(store: CheckStore, typed: Bool = false) }
public struct CheckResultView: View { public init(store: CheckStore, actions: AIToolsActions, boardState: CheckBoardState? = nil) }
```

- [ ] **Step 1: Build each screen to its board:**
  - **Intro** (P6-Check-Intro): `BackRow(title: "Check a paper")`; `IntroHero(symbol: "doc.text.magnifyingglass", …)`; a `Card` with `PickerTile("Student", value:)` (the student picker sheet of Task 11, shared: move `StudentPickerSheet` to be built from `[Student]`), its helper (the class); `NoticesCard([lock])`; `Take photos` (primary; `DocumentCameraView(maxPages: 6)` after `CameraAccess`, the consent sheet first when needed) and `Choose from Photos` (`maxSelectionCount: 6`); the AI footnote. Pages chosen → `addPages` → push `.checkPages`.
  - **Pages** (P6-Check-Pages, P6-Check-Failed): `BackRow(title: "Answer sheet")`; `SectionHeader("2 pages", action: ("From Photos", …))`; a two-column `LazyVGrid` of `PageTile`s and the `AddPageTile` (the camera); the footnote "Up to 6 pages, in order. Each page is reduced on this iPhone before it is sent."; the footer primary "Next: the marking scheme" (disabled without a page) → push `.checkScheme`. Failed (`stage == .failed`): the `CreatingCard` without skeleton ("Checking 2 pages", "The pages are still here.") then `ErrorRow(title: "Couldn't check the paper.", line: "Check your connection and try again. The pages are sent again as they are.", retry:)` and `Back to the pages` secondary (`stage = .pages`): shown by `CheckingView` when the stage is failed.
  - **Scheme** (P6-Check-Scheme, -Typed): `BackRow(title: "Marking scheme")`; `Segmented([(false, "A paper I created"), (true, "Type it")])`; a `Card` of `ChoiceCard`-like rows (`ChoiceCard(title:line:selected:action:)` exists for the CSV sheet: reuse it inside a `Card`) over `store.papers`, or `MultilineWell(label: "Marking scheme", text:, placeholder: "", limit: 4000)` 220 high; the footnote; the footer primary "Check 2 pages" (`sparkles`) → `check()` and push `.checkResult` (the result route shows `CheckingView` while `stage == .checking`, the failed card while `.failed`, the marks when `.result`).
  - **Checking** (P6-Check-Checking): `CreatingCard(title: "Checking 2 pages", line: "Against Quadratic equations · 20 marks. Usually a minute or two.", thumbnail: the first page, cancel:)`.
  - **Result** (P6-Check-Result, -MarkPicker, -Result-Edited, -Saved): `BackRow(title: "Suggested marks", action: ("Share", share))` (a `ShareLink(item: store.shareText)`); the hero (`Card(.hero)`: `Eyebrow("Hemanth Reddy · Quadratic equations")`, the total in `numberHero` with "of 20" `subhead` `text2`, `ProgressBar(fraction:, tone: nil)` in accent, the line); `SectionHeader("Questions")` with the trailing footnote "Tap a mark to change it"; a `Card` of `MarkRow`s whose tile opens a `.popover` with `MarkPicker` (choose → `set`); the footer: the AI footnote and the primary `store.saveLabel` (loading while saving) → `save()`; saved: the footer becomes `SavedMark("Saved to Hemanth's notes")` and the toast `StudentNoteLine.toast(…)` with Undo → `undoSave()` (on success the footer is the button again).
- [ ] **Step 2: The launch states**: `checkIntro = "check-intro"`, `checkPages`, `checkScheme`, `checkSchemeTyped`, `checkChecking`, `checkResult`, `checkMarkPicker`, `checkResultEdited`, `checkSaved`, `checkFailed`; the fixtures: two sample pages (`tools/samples/answer-sheet-1.png`, `-2.png` bundled into the fixtures as `Data` through `Fixtures+AI.swift`'s base64 literals, reduced by `PhotoReducer`), Hemanth chosen, the scheme Quadratic equations; `check-checking` a delay of an hour; `check-failed` `.failure(.service)`; `check-result-edited` question 6 set to 2 `onAppear`; `check-saved` saved `onAppear` with the toast; `check-mark-picker` the popover open on question 4.
- [ ] **Step 3: `bun check` green; the shots of the 10 states beside their boards; `bun pr-shots phase-6-check-paper …`; open PR 6; merge when green.**

### Task 19: The Check a paper write proof in the simulator (PR 6, before merge)

- [ ] **Step 1:** `xcrun simctl addmedia booted tools/samples/answer-sheet-1.png tools/samples/answer-sheet-2.png`; the local API with `AI_FAKE=1`: More → Check a paper → Student Hemanth Reddy → Choose from Photos (two pages) → Next → A paper I created: Quadratic equations (made first through the Assistant with the fake) → Check 2 pages → the marks → tap question 6's mark → 2 → Save 15 of 20 to Hemanth's notes → the toast → Undo. `psql`: `select notes from students where name = 'Hemanth Reddy'` → the line after Save, null after Undo; `ai_generations`: one `check_paper` row, `ok`, `input` with `pages: 2`. Screenshots in `.shots/run/check/`, attached to the PR.

### Task 20: The deploy, the owner's steps, the hand runs, TestFlight, the owner's phone, the documents (main)

- [ ] **Step 1: The owner's step, one message:** create an Anthropic API key (console.anthropic.com → API keys → Create key, named "tutor-central-api"); paste it into Vercel: project `tutor-central-api` → Settings → Environment Variables → `ANTHROPIC_API_KEY`, Production (and Preview), Sensitive. Check: the variable is listed. Do not paste the key in chat.
- [ ] **Step 2: The owner's second step:** the same key into `api/.env.local` on the Mac as `ANTHROPIC_API_KEY=…` (the file is ignored). Check: `cd api && bun run dev` starts (`/health` answers) and, with the key, `AI_FAKE` unset, one curl of `/ai/generate` as the seed's tutor answers a real paper (about $0.02). Record the answer's token counts from `ai_generations`.
- [ ] **Step 3: The deploy** (after PR 2 merged and step 1 done): `gh workflow run deploy`; the run's summary shows 0006 and 0007 pending, pushed, nothing after; the API smoke green (`/health` the commit, `/ai/generate` 401). Record the run id in `STATE.md`'s Production. Then PR 3 onward.
- [ ] **Step 4: The hand runs (D32),** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed and the local API (`cd api && bun run dev`), signed in as Meera, every write confirmed in the database, every screenshot kept in `.shots/run/` and attached to the phase's issue ("Phase 6 hand run"). The simulator has no camera: every photo comes from Photos (`xcrun simctl addmedia booted tools/samples/*.png`); "Take a photo" is tapped once to see "No camera on this device."; the camera, its permission alert and the refused state are the owner's phone (step 6).

| Run | API | Through the screens | Confirm |
|---|---|---|---|
| Consent | fake | More → AI Assistant → Progress note → Hemanth → observations → Write the note → the consent sheet → Cancel (nothing written) → Write the note again → I agree, continue | `select ai_consent_at from centres` set once |
| A note, sent | fake | The note arrives → edit a word → Send on WhatsApp → Open WhatsApp (nothing opens in the simulator; the sheet closes) | `message_log`: one `progress` row for Hemanth; the pasteboard holds the text (`xcrun simctl pbpaste booted`); `ai_generations`: one `progress_note` row, `ok` |
| A paper, real | **real** (about $0.03) | Question paper → Class 10 Maths, Quadratic equations → Create the paper → leave the screen (Back twice) while creating → More → AI Assistant → Recent shows it → open it → Copy → Share as PDF → Save to Files | `ai_generations`: a `paper` row, `ok`, `model` `claude-sonnet-5-5`, tokens set; the PDF under the device's File Provider Storage opens (`open`) with the title and ten questions; the pasteboard holds the text |
| Create again | **real** (about $0.03) | On the paper → Create again → the old stays at 0.55 → the new one arrives on top | a second `paper` row |
| A failure | fake | Stop the local API (`Ctrl-C`) → Homework → Create → the error row → start the API → Retry → the result | `ai_generations` unchanged by the failure (the API never ran) |
| The limit | RLS test | not a hand run: Task 1's test is the proof | |
| Scan register, real | **real** (about $0.03) | More → Scan register → Choose from Photos → `register-page.png` → the list (the names as read; Dev Kumar flagged) → Fix Kavya's number → Remove Tanvi → Undo → Add → the list and the toast → Undo | `students` 17 then 10; `ai_generations`: a `scan_register` row, `ok`, `claude-opus-5-5`; the register page's names match the rows (note the misreads, if any, in the record) |
| Scan: nothing, failure | fake | A blank photo (`tools/samples/blank.png`: the local fake answers no rows for an image under 1 KB, Task 4) → No names found; the API stopped → Retry → the error row → the API started → Retry | `ai_generations`: one `scan_register` row `ok` with no rows; the failed try wrote nothing (the API never ran) |
| Check a paper, real | **real** (about $0.20) | More → Check a paper → Hemanth → Choose from Photos (two pages) → Next → A paper I created: the real Quadratic equations paper → Check 2 pages → the marks → change one → Save → Undo → Save again | `students.notes` for Hemanth: the line, null, the line; `ai_generations`: a `check_paper` row, `ok`, `claude-opus-5-5`; the marks make sense for the drawn answers (note any that do not) |
| Six pages | **real** (about $0.30) | Check a paper with six photographs of a real page (the owner's, step 6) is the phone's run; in the simulator: six copies of `answer-sheet-1.png` → the body under 4.2 MB (the app says so if not) → a result | one `check_paper` row with `pages: 6` |
| Typed scheme | fake | Check a paper → Type it → three lines → Check | a `check_paper` row with `scheme: {kind: typed}` |
| Today's row, More's rows | fake | Today → scroll to Create with AI → the Assistant; More → the three rows | reads only |
| Links | | none new | |

- [ ] **Step 5: TestFlight.** `gh workflow run testflight` (the lane now writes `API_ORIGIN`); the build number from the run; the owner installs it.
- [ ] **Step 6: The owner's phone, one message at a time:** (a) More → Scan register → Take a photo: the camera alert → Allow → the document camera → a real paper register page → Save → the list: say whether the names, numbers and fees are right; (b) Check a paper with a real answer sheet, two or three pages, the scheme typed: say whether the marks are reasonable; (c) Settings → Tutor Central → Camera off → Scan register → Take a photo: the refused toast and Open Settings opens Settings. Record the answers in the phase file's "As built".
- [ ] **Step 7: Documents (D12), one commit to `main`:** `plan/phase-06-ai-tools.md` "As built"; `plan/README.md` (Phase 6 done; D35, D36 already numbered); `plan/STATE.md` (production: migrations 0006 and 0007, the API commit, the key in Vercel); `plan/ui-polish.md`; `docs/design/components.md` and `information-architecture.md` where the build corrected a board's words; `ios/CLAUDE.md` and `api/CLAUDE.md` rules learned (the camera shared in DesignSystem, `AI_FAKE`, the body limit); `plan/sessions/013/record.md` and `owner-messages.md`; then a reviewer pass on the six merged pull requests with `superpowers:requesting-code-review`, its outcome recorded.

---

## Self-review

- **Spec coverage.** Phase file scope 1 (the API for real: structured outputs with the two models, prompts in `api/src/prompts/` with tests on the schemas, per-centre limits in Postgres, every call in `ai_generations`, image inputs validated, consent checked): Tasks 1 to 4. Scope 2 (the Assistant: the home with the four tools, a form per tool with class or subject, topic, level, length, marks, tone, the student picker, generating with the old result kept, the result as formatted text with copy, share as PDF, regenerate, history under More): Tasks 5, 6, 8 to 13. Scope 3 (scan register: intro with the notices, consent once per centre, camera or Photos, upload, the review table editable with delete, duplicates flagged, save creates the students, nothing saved before review): Tasks 1, 3, 5, 7, 14 to 16. Scope 4 (check a paper: intro, one or more pages, the scheme free text or a generated paper's key, per-question marks and a note, every mark editable, the total, save to the student's notes or share, nothing saved before review): Tasks 3, 5, 7, 17 to 19. Scope 5 (the AI line on every result, the consent before the first photo): Tasks 11, 15, 18 and the decisions table. Owner step (the key into Vercel): Task 20. Acceptance: pictures in PRs 4 to 6; each tool returns a usable result for the seed's classes and a failure offers retry (Tasks 10, 11, 20's runs); a register photo of ten names becomes ten reviewed students (Task 20's scan run with the eight-row sample; the owner's phone with a real page); the limits hold and `ai_generations` records every call with tokens (Tasks 1, 4, 20); API tests cover the schemas, the middleware, the consent check and the limit (Tasks 3, 4, and `auth.test.ts` as it is). Inventory rows: all placed (Global Constraints, last line). D32: Task 20's table names every write path and which runs cost money.
- **Placeholders.** The views (Tasks 11, 15, 18) are given as their pieces with the exact components, tokens, copy and wiring; every number is a token or a named anatomy constant and every word is on a board or in `components.md`. The decoding fixtures are the stack's answers of 2026-10-08, pasted whole. The API's sample answers are the boards' content. No "TBD", no "handle edge cases".
- **Type consistency.** `GenerateRequest`, `GenerationKind`, `Generation`, `GenerationResult` (Task 5) are what `AIRepository.generate`, `GenerationRow.generation`, `FakeAIHistoryRepository.seed` (Task 6), `AIStore` (Task 10) and the views (Task 11) carry; `GenerateContext` (Task 6) is built by `AIStore.context(for:)` (Task 10); `ImageUpload` (Task 6) is what `PhotoReducer.reduce` returns (Task 9) and `ScanStore.read`, `CheckStore.addPages` take (Tasks 14, 17); `ScanRowDTO` (Task 6) becomes `ScanRow` through `ScanReview` (Task 5) in `ScanStore` (Task 14); `CheckResult` and `MarkEdit` (Task 5) are what `CheckResultDTO.result` (Task 6) and `CheckStore` (Task 17) use; `SchemeSource` (Task 5) is what `AIRepository.checkPaper` takes (Task 6) and the API's `Scheme` mirrors (Task 3); `StudentNoteLine` and `NotesAppend` (Task 5) are `CheckStore.save`'s (Task 17); `CentreRepository.recordAIConsent`, `StudentsRepository.createMany/deleteMany/updateNotes`, `MessageLogRepository.logProgress` (Task 7) are called by Tasks 10, 14 and 17; `Workspace.takingAIConsent` (Task 5) is AppShell's merge (Tasks 12, 15, 18); `APIFailure` (Task 6) is what the stores map to words (Tasks 10, 14, 17); `CameraAccess`, `DocumentCameraView`, `MessageSheet`, the rows and cards (Task 8) are what Tasks 11, 15, 18 draw; the API's `ClaudeClient`, `Db`, `errors` (Task 2) are what the routes (Task 4) and `index.ts` use; the routes' answers (Task 4) are what `APIClient` decodes (Task 6); `start_ai_generation`'s errors (Task 1) are what `makeDb` maps (Task 2). `LaunchState` raw values match `information-architecture.md`'s Phase 6 table (38 states; `more` keeps its name; `students-add-menu` and `students-empty` are re-shot).
- **Review Focus.** 1 → Task 1 `start_ai_generation refuses a scan without consent and allows a paper`, `the limit counts only calls that did not fail…`; Task 4 `a missing consent answers 403 in words, and the limit 429 with the limit`. 2 → Task 3 `bytes that are not the declared type are refused`, `base64 that does not decode, and a photo over 3 MB, are refused`, `CheckPaperInput … caps the pages together`; Task 9 `aLargePhotoComesBackUnder2000pxAsJPEG`, `sixReducedPagesFitTheBody`; Task 6 `aBodyOverTheLimitIsRefusedBeforeTheRequest`. 3 → Task 5 `aMatchByPhoneOrNameIsFlaggedAndUnticked`, `aBadPhoneBecomesNoNumber`; Task 3 `…phones are normalised to +91`; Task 14 `readingFlagsTheRowsAgainstTheRegister`, `addWritesTheTickedRowsOnceAndUndoDeletesThem`. 4 → Task 5 `marksAreClampedAndTheTotalIsTheSum`, `theNoteLineAppendsOrRefuses`; Task 17 `checkClampsAndFailsInWords`, `saveAppendsAndUndoRestoresExactly`. 5 → Task 10 `aGenerationSurvivesLeavingTheScreen`, `aSecondCreateWhileOneRunsIsRefused`, `aFailureKeepsTheFormAndOffersRetry`.
- **The polish list.** U9 (a failure toast behind the keyboard on sheets) touches the student picker, Fix this row and the typed scheme: offered to the owner with this plan, not taken; the build takes it only if the owner says so, as its own pull request after a board. Seen while planning, for `plan/ui-polish.md` if the owner wants them: Attendance's and Fees' message sheets could adopt DesignSystem's `MessageSheet` (three copies otherwise).
