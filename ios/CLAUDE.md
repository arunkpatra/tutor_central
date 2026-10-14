# ios: rules

The app target is thin (`App/`); everything lives in the local package `TutorCentralKit/`.

- Generate, never edit, the project: `bun gen` (XcodeGen from `project.yml`, D9). The `.xcodeproj` is ignored.
- Modules and their one-way dependencies: `docs/spec.md` section 4. Features never import each other.
- Swift 6 language mode, strict concurrency complete (D8). A `DateFormatter` or `NumberFormatter` is made where it
  is used or kept in a `Sendable` wrapper; nothing mutable is global.
- Style only through `DesignSystem` tokens (D10, from Phase 2). No raw colour, size, radius, shadow or duration in
  a view.
- Appearance: the app opens dark (`AppShell.Appearance`, D23); light and "match iPhone" stay available. Build
  every screen for both (D13).
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`; no bare `@Suite`, SwiftFormat removes it) in
  `Tests/DesignSystemTests`, `DomainTests`, `DataTests`, `AppShellTests`, `OnboardingTests`, `TodayTests`,
  `SettingsTests`, `StudentsTests`, `AttendanceTests`, `ScheduleTests`, `FeesTests`, `ArtefactsTests`; stores are tested against the
  in-memory fakes. XCTest only in `SmokeTests` (the launch, and iPhone only). No UI test suites (D15). A new test target goes
  in `Package.swift` and in the scheme in `project.yml`.
- The package is iOS only: build and test it with `xcodebuild` for the simulator (or `bun check`), not
  `swift test`.
- Screens are proven by `bun shots <state>` and the pictures in the PR (D7). Every state a board has gets a
  `LaunchState` case; the app reads `--state <name>` and `--appearance dark|light|system` at launch.
- The simulator is the iPhone 17 (D22); `TC_SIMULATOR` names another. Simulator builds sign ad hoc, without a
  team. The signed-in session survives a relaunch and a reboot (seen in session 7).
- Driving the app against the local stack (sign in, tap, type, settled screenshots, deep links, a wedged
  simulator): `docs/runbooks/simulator.md` (D32). Its rules: 1.5 s after a tap before looking, 1 s after `text`
  before the next tap, a phone number in two parts, and every write confirmed in the database.
- If the smoke test fails with "Application failed preflight checks" (the simulator is busy after installs or a
  shutdown), run `xcrun simctl shutdown all && xcrun simctl boot "iPhone 17"` and check again; it is not the code.
- iPhone only (D1): the app target sets `TARGETED_DEVICE_FAMILY "1"` itself; XcodeGen's default is "1,2".
- Shadows: `shadowed(_:radius:)` takes a token or a list through one fixed view structure. Never wrap views in
  `AnyView` per state: a view that changes type loses its text field's focus.
- One `SupabaseClient` per process (`RootView.live`); a client made per view would split the session.
- One `RegisterStore` per centre (`ShellState.register`, `@ObservationIgnored`, filled by the first Students screen
  built), so the list and a pushed detail share it. It is cached as JSON in Application Support,
  `TutorCentral/register-<centre id>.json`; fixtures never write it (`Dependencies.cachesRegister`).
- A pushed screen that cannot show (a link to a student no longer here) is taken off the stack by AppShell
  (`TabsState.remove`); `dismiss()` during a push is lost.
- A pure `static func` on a SwiftUI view is `nonisolated` when tests call it: a closure inside it inherits the main
  actor and traps off it.
- Pickers the boards draw as accent values (a date of birth, a class's times) are buttons opening the system's
  picker in a popover; the compact `DatePicker` draws a capsule the boards do not.
- `bun shots` photographs the last `bun check` build: rebuild before shooting a change.
- A repository's write path is proven in Swift against the local stack before a build ships (a throwaway test with
  an in-memory session; the test host has no keychain), not only by curl: Phase 3's insert answer did not decode.
- A failing test can stall `xcodebuild` ten minutes while it collects simulator diagnostics; `bun check` passes
  `-collect-test-diagnostics never` (#35), and a hand-run `xcodebuild test` should too.
- Boards draw focus without a keyboard: fields take `showsFocus` for board states and `autofocus` for real use.
- Local config: `Config/Local.xcconfig` (ignored) from `Config/Local.xcconfig.example`; the anon key (the JWT,
  `ANON_KEY`) from `supabase status -o env`. The local stack sends the code email
  (`supabase/templates/email-code.html`); codes land in Mailpit at :54324.
- `bun check` runs `swiftformat --lint` and `swiftlint --strict`. Fix the code, never relax a rule; where the two
  tools disagree, SwiftFormat owns the concern and the SwiftLint setting says so (`.swiftlint.yml`).
- A feature reads the register through Domain's `Register` (D33): AppShell passes the shared `RegisterStore` as `any
  Register` to Attendance, Schedule and Today; only test targets import Students to build a real one.
- A screen whose store AppShell builds in the view (History, the schedule, a student's month, the student detail)
  keeps it in `@State` (`_store = State(initialValue:)`); otherwise every rebuild swaps a loaded store for an empty
  one.
- A store whose reads can overlap (a month move, a link, a picker) keeps a load generation and drops a stale answer;
  `AttendanceStore` also lets its first load stand aside for an open asked for meanwhile.
- A graphical `DatePicker` in a popover takes `.calendarPopover(timeZone:)` (DesignSystem): without a width it
  collapses to a sliver.
- `Card { ForEach … }` needs a `VStack(spacing: 0)` inside: modifiers on a bare `ForEach` apply to every row (each
  row became its own card).
- A section action built with a ternary of tuples (`cond ? (label, run) : (label, run)`) can stall the type checker:
  give it a typed computed property. `SettingRow`'s trailing closure is its trailing view; pass `action:` by name.
- The local seed is relative to the real day (`current_date`), so a hand run's "today" is the real weekday; the
  fixtures' boards are Wednesday 7 October.
- A paused Docker container hangs requests; stop the gateway (`docker stop supabase_kong_tutor_central`, then `docker
  start`) to test offline paths (supabase-swift takes about 20 s to give up).
- A screen that changes the workspace hands its change to `RootView.applyWorkspace`, which merges only that screen's
  fields onto the session's current workspace (`Workspace.takingSettings(from:)`, `takingPayments(from:)`) before
  Today and Fees hear of it: a store's own copy is older than the session's (Settings' copy put back a replaced UPI id).
- Vision's barcode revisions 2 to 4 cannot run in the simulator ("Could not create inference context") and answer
  empty on CI's runner: `QRDecoder` tries the current revision, then revision 1 whenever it reads nothing.
- The camera: ask with `AVCaptureDevice.requestAccess` before presenting VisionKit's scanner
  (`DataScannerViewController.isAvailable` is false until access is granted); present it in a sheet, which a swipe
  closes.
- A pushed screen's top row (`BackRow`) and the Saved mark (`SaveMark`) are DesignSystem's, for every feature.
- `String(contentsOf:)` drops a file's BOM: test a written CSV as bytes.
- A sheet opened on one tab stays up when a link switches tabs (U13).
- The camera's access and VisionKit's document camera are DesignSystem's (`Camera/`), for Fees' QR, Scan register and
  Check a paper. `PhotoReducer` (2000 px JPEG at 0.7) is Data's, so Students and Make both reduce a photo (D36).
- The AI screens read the register themselves (`AIStore.prepare()`, `ScanStore.read`): the Students tab may never have
  been opened.
- A sheet that builds a form store keeps it in `@State` (`FixRowSheet`): built in the sheet's content, it is remade on
  every re-render of the list behind and typed text is lost.
- A call the tutor can leave (Check a paper) runs in a task its store owns, refused while one runs; Cancel and Back
  cancel it and a late answer is dropped (`CheckStore.begin()` and `cancel()`, `ScanStore.begin()`).
- A store's failure words for a screen that has gone are returned to the caller, not set on the store (`undoAdd`
  answers the words AppShell's toast shows).
- A button under fields puts the keyboard away when its result appears in place (`Keyboard.dismiss()`); a multiline
  well takes a tap anywhere through a layer behind its field.
- `supabase db reset` ends the API's session for the signed-in app (401 "sign in again"): sign out and in after a reset.
- The local API: `cd api && SUPABASE_URL=… SUPABASE_ANON_KEY=… bun run dev`, with `AI_FAKE=1` for the fake (a 1.5 s
  answer; a register photo under 1400 base64 characters reads nothing). `API_ORIGIN` in `Local.xcconfig` is
  `http:/$()/127.0.0.1:3000`.

- Offline (D39, D40): a list's copy is `CachedRead` under the centre (`cache-<centre>-<key>.json`, file protection until
  first unlock); three writes queue in `ChangeQueue` (`queue-<centre>.json`) and `QueueRunner` sends them in order, reading
  the queue again before each send and removing only what it sent. A store gets the queue through
  `RootView.centreQueue()` (the tabs are built before `onChange` runs); a change added while online starts a run
  (`ChangeQueue.onAdded`). Only a PostgREST code fails a change; any outage waits. Sign-out and deletion wipe the
  centre's files, its defaults and every reminder, pending and shown (`SignOutWipe`, `Wipe`).
- A stopped gateway keeps `NWPath` satisfied: reads fail after about 20 s and a replay starts on foreground (`HOME`, then
  `xcrun simctl launch`). Coming back to the app reads every list again (`ShellState.refreshScreens`); a reload that
  fails keeps what is shown.
- Reminders (since Phase 18): the server plans and sends them (APNs); the iPhone schedules none. The settings are the
  account's (`reminder_settings`); `ReminderSettingsMigration` moves build 27's local settings there once, removes its
  pending reminders and the old keys. `AppDelegate` installs `NotificationDelegate` before launch ends; a tap's link reaches
  `RootView.openLink`. The simulator's lock screen and banners take no injected taps: open the link with `simctl openurl`
  and leave the tap to the tester.
- Telling the tutor what happened (U33): the toast is for Undo only; a success shows in place, a failed or refused write is
  the system alert (`NoticeCenter`), a field's error is under the field, a list that could not load says so in its place.
  Before adding any message read `docs/design/feedback.md` and pick its row.
- No technical words on screen (D41): `ErrorWordsTests` reads every sentence in the sources; never pass a backend's
  message through.
- Dynamic Type: rows that put a value beside a title use `AdaptiveRow` (stacks only at the accessibility sizes) with
  `AdaptiveSpacer` where an `HStack` had a `Spacer`; fixed-height rows `growsWithText()`; a drawn-height sheet
  `boardDetents(_:)`; a one-line title, email or initials `singleLineTitle()`. `typeStyle` reads the environment's size,
  so a size changed while the app runs redraws. Compare the default size by pixels before and after.
- Every graphical calendar takes `calendarPopover(timeZone:)` (`CalendarPopoverUseTests` holds it): its width, Monday
  first, the keyboard away as it opens. A sheet sized to its content is a `FittedSheet` (the header pinned, the fields
  scroll). `scrollDismissesKeyboard(.interactively)` is set once on the root.
- The launch screen is carried on by `OpeningCover` until the session is read, then fades over `opening` (500 ms,
  ease-in-out): never in a launch state. Prove a motion by recording (`simctl io booted recordVideo`) and reading frames.

- A rule two features need goes to Domain, never across features: the placement's groups, rows and state changes are
  `Domain/Record/Placement.swift`, used by Students' placement and Today's close. Today closes a batch through `Register`
  (`applyTracking`), never through `RegisterStore`.
- A screen that must work offline lists what it can at once (the close's students from the register) and runs its reads
  together: with the gateway down and `NWPath` satisfied, each read takes about 20 s to fail, so reads in turn left the
  close empty for minutes (run 9). Its Done waits for the reads, so the statuses it writes see the record.
- A store a launch state or a link opens before the register is read is built after `register.loadIfNeeded()` in a small
  screen (`TextbookScreen`), then kept in `@State`.
- Hand runs: an iOS 26 switch in a card needs `tap` with `duration` 0.15 (the runbook's note); the instant tap can miss.

- The plan (Phase 12): `PlanStore` keeps one run; a second `load` (a return to the app, a pull) leaves a live run alone and
  `complete` cancels the run before it, or the material is made twice. A plan whose `sessionID` is set is closed: nothing
  in it changes. Today starts the plans beside the counts' read, so offline each shows its copy at once.
- Skills are per student: a group's checks name one student's skill ids, so the close records a check on the student's
  own skill by id, else by name, and offers no row a student cannot keep.
- `PlanCache` keeps the plan per batch and day and each student's book (`keepBook`), and finds an artefact in the plans
  kept (`artefact(_:)`): the close and the artefact screens read them offline.
- The figures are drawn in the Artefacts feature: DesignSystem does not import Domain (`FigureSpec`).
- Hand runs: Postgres' `current_date` is UTC, so query a plan by the IST day; `bun shots` leaves the app on a launch state,
  so relaunch it without one before driving it against the local stack.
- Phase 13: an exam's split starts at `ExamPreparation.start` (the day the item came), never today, in the maker and the page
  alike. Two plans share one mock (`PlanMaker.sharedMock`, the `MockRuns` actor), and a plan read takes the artefacts its
  lines link that another plan kept. A screen that sits under a write (an exam's page under Check a paper) reads itself
  again from a shell counter (`ShellState.recordChanged`): `onAppear` does not fire for a page that never left the stack.
- `bun check --only=db` resets the local database, which ends the app's session (the API answers 401): sign out and in.
- Request bodies keep within the API's schema limits on the app side (`MakeGapBody.weakest`): a refusal reads as a
  connection fault to the tutor.
- Phase 14: a parent's message is signed by the app (`MessageSignature`), never by a model; its 600 counts the body alone.
  The three-a-week cadence (`MessageCadence.suggested`) counts sends only: a copy and a hand send never count. A note held
  for consent opens the student's page, never the cadence's held sheet.
- A store whose reads can overlap keeps a generation (`NoteDayStore`, `ReadMarksStore`); a write whose call was paid for
  (a note made) runs in a task of its own so leaving the screen does not lose it.
- The tutor's next step belongs to the status it was chosen for: 0025 clears it on a status change and `applyTracking`
  mirrors it; a choice waits while a queued close tracks the student (`PendingChanges.closeWaits`).
- Request bodies are held to the API's limits on the app side (`NoteRequest.Week`); a 400 marked `reason: "invalid"` is the
  schema's and never shown.
- The simulator's screenshot tool at `scale` shrinks the image only: read tap points from the full frame (402 × 874).

- Phase 15: the AI module is `Make` (was `AITools`): Make's home, its forms, History, Check a paper, the V1 forms. A Make
  artefact keeps `made_from = 'make'` and `made_for` (the eyebrow and Make it again's target); Make's list has a copy on the
  iPhone, a made artefact's screen does not. The Kit's figures are drawn by `Artefacts/Figures/FigurePreviews.swift`.
- A list store's `savedAt` is the time of its last good read, not nil after it: a list on screen offline then names when it was
  saved, never "Nothing saved" (#169). A span or month not on screen yet shows its copy at once, else nothing, never the last
  one's figures (Reports, #170).
- Words handed from one screen to another through the shell are taken once (`ShellState.takeNoteWords`): left on the shell, a
  later open repeated a paid call (the review's R-app-1).
- A form's remembered choices are UserDefaults keys listed in `Wipe.defaultsKeys` (sign-out wipes them, D40); a test reads the
  list for every new key.
- Reads that do not depend on each other run together (`async let`, a task group); a failure says so in the list's place (U33).
- A hand-run `xcodebuild` test of some targets builds into `bun check`'s DerivedData: after one, rebuild the tip before a hand-run
  picture (the app installed from DerivedData is the last build).

- Phase 17 (V3 platform): the API's limits and lists are generated (`Domain/Generated/APIContract.swift`, by `bun
  contract` from `api/src/contract.ts`; never edited, `bun check` fails when stale); a body keeps within them, not within
  a literal. The fake's sample answers (`DataTests/Contract`) and the plan cases (`DomainTests/Cases/plan-cases.json`, the
  rules held equal to the API's port) are generated too; a rule change rewrites the cases with
  `TEST_RUNNER_TC_WRITE_PLAN_CASES=<path>` and `bun contract`.
- Every AI call carries an `Idempotency-Key` (`IdempotencyKey`): the route, the body with sorted keys and the day in India,
  so a repeat that day replays and costs nothing; a screen that means "another one" (Make it again, Write again) runs its
  call in `IdempotencyKey.another { }` for a fresh key (V1's Create again through `GenerateContext.again()`). A made artefact is kept by the key
  `<generation>[:<what it replaces>]`. 409 `in_progress` and 429 `rate` read as the timed-out words, 413 as too many pages.
- The activity log (D82): `ActivityLog` (Data, an actor) keeps `activity-<centre>.json`, one event a line, and posts
  batches of twenty, at background and on return; the shell records the app opened (`ShellState.opened()`, the scene's
  active, at a launch once the centre's log is made), a sign-in, a tab, a link, and a sign-out, which closes the log
  before the wipe. Never a name or an id in an event.

- Phase 18 (the server's work and push): the plan and its material, the note day's notes, the PDFs and a student's export
  are made by the server's jobs; the app asks (`JobsRepository`: `request_plan`, `request_note`, `request_export`,
  `cancel_job`) and follows the job, never makes them itself. `PlanPreview` shows the phone's rules for Change before a
  plan is asked again; PlanMaker, the phone's budget and the price sheet are gone. What stays a call from the phone: Write
  again and the tutor's own words on a note, Make, Check a paper, the V1 forms.
- Push: `aps-environment` and `PUSH_ENVIRONMENT` per configuration (`project.yml`: Debug sandbox, Release production).
  `PushRegistrar` keeps one `device_tokens` row per user and device after Allow and forgets it at sign-out; `PushRelay`
  hands the token from the `AppDelegate`. The background push (`plan_fetch`) runs `PlanFetch`: today's plans into
  `PlanCache` within iOS's 30 s, the completion called once.
- Copies first (D39, U27): `CopyFirst<Value>` shows a list's copy, then reads. `RegisterStore.loadIfNeeded` answers from
  its copy at once and reads on; Today shows every batch's plan copy before any batch reads (`PlanStore.showCopy`), and the
  note day the register's rows with no count until its read; the material screens open from `ArtefactRead.copy` (the
  plan's copy) and keep it when the read fails. Offline each read takes about 20 s to fail: never put one before a copy.
- Server PDFs: `ServerFiles` downloads a path once into `files-<centre>` (the wipe removes it); Share on a sheet, mock or
  brief takes the server's PDF (`ServerPDF`), else draws on the phone. The export (`ExportStore`) shares the server's file.
- A note's week is an ISO day in its content (`week_monday`); the API's `noteContent` writes the same, and the contract's
  `kept_note` sample is read by the app's decoder (ContractTests).

- Phase 20 (D102): mathematics in a text is LaTeX (`$…$` inline, `$$…$$` on its own line); `MathText` (DesignSystem) draws
  it with SwiftMath 1.7.3 (`MathRenderer`, XITS Math) inline with the words at the token's Dynamic Type size, a display
  formula centred at 1.25×, a formula wider than its line drawn smaller to fit, a heavy token's formula bold (`\bm`, digits
  `\mathbf`), and anything that does not parse shown as written in `text2`. VoiceOver reads `MathSpeech.words`. Every place
  a question, answer, step, caption or the phone's PDF shows material text goes through `MathText`. The split's rules are
  shared with the PDFs by `tools/contract/maths-cases.json` (`bun contract`). A 503 `paused` is `APIFailure.paused`, shown
  as the system alert in the API's words; the alert's action (a lone OK, Try Again, Open Settings) is the default action,
  tinted by `AlertTint` at launch (SwiftUI's tint does not reach the alert).

- Phase 21: a tutor's feedback is kept by `ArtefactFeedback` (`generation_feedback`): `edit` with the sent text when it
  differs from the draft, `again` with the menu's reason (Make it again, Write again), `replace` when the tutor writes a
  set-aside note themselves. A note the check set aside shows the card with Write it myself (P21-Note-SetAside). The exam's
  page reads its job (`JobsRepository.examJob`): Being made from the mock's morning, Not made with Try again
  (`request_exam_prep`), Working for a marked student only while the job is live, the mock kept and their report not given
  up (`ExamJobStatus.notMade`), Changed once a report is used; Save of marks wakes the job. Share on a V1 result takes the
  server's `gen-<id>.pdf` (`ServerPDF.file(forGeneration:)`), asked again while the screen is up when the phone drew it
  first (`ResultPDF.serverLater`). At the accessibility sizes a footer's Copy pair and a row's trailing chip or button are
  `AdaptiveRow`s (`FooterPairUseTests`, `ExamRowsTypeSizeTests`).

Commands: `bun gen`; `bun check --only=format,lint,ios`; `cd ios && swiftformat .` (apply formatting);
`bun shots <state>`; open `ios/TutorCentral.xcodeproj` in Xcode.
