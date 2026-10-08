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
  `SettingsTests`, `StudentsTests`; stores are tested against the in-memory fakes. XCTest only in `SmokeTests`
  (the launch, and iPhone only). No UI test suites (D15). A new test target goes in `Package.swift` and in the
  scheme in `project.yml`.
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

Commands: `bun gen`; `bun check --only=format,lint,ios`; `cd ios && swiftformat .` (apply formatting);
`bun shots <state>`; open `ios/TutorCentral.xcodeproj` in Xcode.
