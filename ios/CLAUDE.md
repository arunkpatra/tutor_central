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
  `SettingsTests`, `StudentsTests`, `AttendanceTests`, `ScheduleTests`, `FeesTests`; stores are tested against the
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
  Check a paper. `PhotoReducer` (2000 px JPEG at 0.7) is Data's, so Students and AITools both reduce a photo (D36).
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
- Reminders: `ReminderScheduler` (AppShell) plans and replaces on sign-in, foreground (after the register is read
  again), any saved class, student, event or fee write, and a queue run; a call during a run plans again after it; a
  failed read keeps that kind's pending reminders. `AppDelegate` installs `NotificationDelegate` before launch ends; a
  tap's link reaches `RootView.openLink`. The simulator's lock screen and banners take no injected taps: open the
  reminder's link with `simctl openurl` and leave the tap to the tester.
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

Commands: `bun gen`; `bun check --only=format,lint,ios`; `cd ios && swiftformat .` (apply formatting);
`bun shots <state>`; open `ios/TutorCentral.xcodeproj` in Xcode.
