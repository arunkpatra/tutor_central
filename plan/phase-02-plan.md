# Phase 2 Shell and Sign-in Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app a tutor installs from TestFlight: the design system in code, sign in with Apple, Google, an email code or a password, one onboarding screen that creates the centre, the five tabs with Today empty and the other four saying what comes later, minimal Settings with sign out, every screen built to its approved board in both appearances.

**Architecture:** `DesignSystem` holds the Ember tokens as Swift and every Kit component; a test reads `docs/design/design-tokens.md` and fails when the two differ. `Data` adds three repositories (auth, centre, counts) as protocols with Supabase implementations and in-memory fakes. `AppShell` owns the session gate (`SessionStore`), the tabs, launch-state fixtures for screenshots, deep links and toasts. The screens and their `@Observable` stores live in `Features/Onboarding` (sign-in and onboarding), `Features/Today` and `Features/Settings`. One migration (0002) lets `create_centre` take the tutor's name. `testflight.yml` archives with cloud signing and uploads with an App Store Connect API key.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, AuthenticationServices (Sign in with Apple, `ASWebAuthenticationSession` inside supabase-swift), CryptoKit (nonce), `supabase-swift` 2.55.3 (the only iOS dependency, D14); Supabase Auth (Apple id-token, Google OAuth, email OTP, password); XcodeGen; GitHub Actions on `xcode-27` (D22).

**Spec:** `docs/spec.md` sections 2, 4, 5 and 7; scope and acceptance in `plan/phase-02-shell-and-sign-in.md`; the boards in `docs/design/mockups/P2-*.dc.html`, `Kit-*.dc.html` and `docs/design/directions/A-SignIn.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, rows 1, 4 and 5); `docs/design/design-tokens.md`, `components.md`, `guidelines.md`, `information-architecture.md`; the Phase 2 rows of `docs/reference/functional-inventory.md`; decisions D1 to D25 in `plan/README.md`.

## Global Constraints

- iOS 26.0 minimum, iPhone only, portrait only (D1). Bundle id `app.journium.tutorcentral` (D19). The app's name is Tutor Central (D20).
- Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation; UIKit only behind a wrapper with the reason in the file (D8). Features never import each other; a feature reaches another feature's screen through a closure or protocol that `AppShell` provides (spec section 4).
- Style only through `DesignSystem` tokens: no raw colour, size, radius, shadow or duration in a view (D10). A value a board needs that no token names becomes a token first, in `design-tokens.md` and in Swift in the same commit.
- Both appearances designed and built (D13); the app opens dark (D23). Every screen is photographed in both by `bun shots <state>` and the pictures are in the pull request before merge (D7). No board, no screen: a state without a board is designed and approved first (`CLAUDE.md` rule 1).
- Copy: sentence case, no exclamation marks, no emoji, no jargon; buttons are verbs with an object; errors say what happened and what to do (`guidelines.md`). The exact copy of every screen is on its board and repeated in the task that builds it.
- `supabase-swift` is the only iOS dependency (D14); no Google SDK, no Firebase. No AI key, no service-role key, no secret in the app or the repo (D11). The anon key is public by design.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/DesignSystemTests`, `Tests/AppShellTests`, `Tests/OnboardingTests`, `Tests/TodayTests`, `Tests/SettingsTests`, each in `Package.swift` and in the scheme in `project.yml`. No UI test suites (D15). Stores are tested against the in-memory fakes.
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). Bun only (D16). A new decision gets its number in `plan/README.md` in the pull request that acts on it.
- Supabase: one migration per change, never edit one that has run on the hosted project; every new table or function revokes anon; `supabase gen types typescript --local > types.ts` after every migration (`supabase/CLAUDE.md`).
- The simulator is the iPhone 17 (D22). The repo's git email stays `arunkpatra@gmail.com` (Vercel).

## Review Focus

Inputs the spec implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **A sign-in that is cancelled (Apple's sheet dismissed, the Google web session closed) must leave the landing exactly as it was: no error toast, no spinner stuck, the buttons usable.** Test in Task 9 (`SignInStore`: `cancelled` ends busy with no message).
2. **An Apple sign-in whose private relay hides the email, or a Google account with no name, must still reach onboarding with the name field empty and "Signed in as" showing whatever address the session has.** Test in Task 11 (`OnboardingStore` prefill from a user with nil name and relay email).
3. **A code typed after it expired, or after a new one was requested, must say so in words and offer a resend, never show "wrong code" for an expired one.** Test in Task 10 (`EmailSignInStore` maps `codeExpired` to its own line).
4. **The session gate must never flash the sign-in screen while the keychain session is being read at launch, and must land on onboarding, not the tabs, when a signed-in user has no centre.** Test in Task 8 (`SessionStore` starts in `.loading`; a user with no membership goes to `.needsOnboarding`).
5. **A WhatsApp number typed with spaces, a leading 0 or a +91 prefix must normalise to E.164 or be refused with "Needs 10 digits after +91.", never saved malformed (the database would reject it and the tutor would see a raw error).** Test in Task 11 (`PhoneNumber` parsing cases).

---

## Decisions this plan settles

Small and medium things, decided here and written down. The two numbered ones are added to `plan/README.md` in the documents commit that lands this plan.

| # | Decision |
|---|---|
| D24 | TestFlight lane: `testflight.yml`, by hand (`workflow_dispatch`), on the `xcode-27` image, archives the head of `main` with cloud signing (`-allowProvisioningUpdates` and an App Store Connect API key held in secrets), build number = the workflow run number, uploads through `xcodebuild -exportArchive` with `destination: upload`. The team id and the hosted Supabase URL and anon key are repository variables; the key's id, issuer and `.p8` are secrets. Nothing signs from a local machine. |
| D25 | Tokens as Swift: every token in `design-tokens.md` is a `static let` on `Tokens`, declared with the document's own literal (hex, `rgba(...)`, point values, CSS shadow strings), registered by name in `Tokens.registry`, and resolved to SwiftUI values at use (`Color` through a `UIColor` dynamic provider, the one UIKit wrapper, because SwiftUI has no dynamic colour without an asset catalog). `DesignSystemTests/TokenDocumentTests` parses the document and fails on any name or value that differs either way. The CSS inset highlight of raised surfaces is drawn as a 1 pt top stroke; this approximation is recorded in `components.md`. |
| | Sign-in screens live in `Features/Onboarding` (sign-in landing, email sheet, code entry, password entry, onboarding form): no new feature target, the spec's module list stands. |
| | The Kit is reached by `bun shots kit` and a second scheme `TutorCentral Kit` (launch argument `--state kit`), in `#if DEBUG` only. No row is added to any screen for it, so no board changes. |
| | The Today board has no AI tools row, so Phase 2 builds none; the scope line "AI tools row navigates to a coming-later state" is met when Phase 6's Today board draws the row. Written in "As built". |
| | Today's account button (initials) pushes Settings on the Today stack: Settings' board has a back chevron, the More tab is a placeholder until Phase 7. |
| | Google through Supabase's OAuth flow in `ASWebAuthenticationSession` (the inventory row): Supabase holds a **web** OAuth client (id and secret) whose authorised redirect is Supabase's callback; the app's callback is `tutorcentral://auth-callback`, allowed in Supabase's redirect list. No iOS client id is needed. |
| | Email code: Supabase's email OTP, six digits, 10-minute expiry (the board's words), the template sends `{{ .Token }}`. Resend cooldown 60 s, Supabase's own per-address limit. Supabase's built-in mailer allows a handful of emails an hour: enough for the owner; custom SMTP is an owner decision before other testers (noted in `STATE.md`). |
| | Password sign-in: "Use my password instead" leads to the password sheet, board `P2-Email-Password` (drawn and approved in session 3, canvas row 5). Task 10 step 7 builds it. A wrong password is said under the field; the words are on the board. |
| | Legal links on sign-in open two URLs the owner gives (`Legal.terms`, `Legal.privacy` in `AppShell/Legal.swift`); until he does, the build session asks, once, at Task 9. |
| | Screenshot fixtures: every `LaunchState` builds its `Dependencies` from the fakes with the board's data (Meera Nair, Bright Minds Tuition, meera.nair@gmail.com, +91 96112 99988) and a fixed clock, 2026-10-07 18:30 IST, so "Wednesday 7 October" and "Good evening, Meera" match the board. |
| | Greeting bands: before 12:00 "Good morning", before 17:00 "Good afternoon", else "Good evening"; the name is the first word of the display name. |
| | Zero values in stat tiles are drawn in `text3` (the board); non-zero in `text`. |
| | Later placeholder copy per tab is in Task 13; pushed from a Today action it shows the same card with the action's title. |
| | Settings saves on commit (return or focus loss): "Saving…" in `text3` while in flight, "Saved" with a tick in `ok` after; a failure keeps the typed value and shows the toast "Couldn't save. Check your connection and try again." Sign out asks with the Kit dialog. |
| | Deferred minors from the Phase 1 review are taken in Task 3 (tools and workflows) and Task 4 (database). The brew tools stay unpinned: Homebrew cannot pin a formula version; the toolchain salt makes drift loud. The Phase 6 image-size constraint stays in `STATE.md`. |

## File structure

```
docs/design/design-tokens.md                 # + glowHero, glowHeroSoft, heroInset, heroTop (board-derived, Task 1)
docs/design/components.md                    # + the inset-highlight approximation (Task 2)
docs/design/information-architecture.md      # + kit-surfaces, signin-password launch states (Tasks 2, 10)
ios/
  project.yml                                # + test targets in the scheme, TutorCentral Kit scheme, entitlements, URL type
  App/TutorCentral.entitlements              # Sign in with Apple
  App/Info.plist                             # + CFBundleURLTypes (tutorcentral)
  ExportOptions.plist                        # app-store-connect, destination upload (Task 16)
  TutorCentralKit/Package.swift              # + DesignSystemTests, OnboardingTests, TodayTests, SettingsTests
  TutorCentralKit/Sources/DesignSystem/
    Tokens/Tokens.swift                      # enum Tokens, registry
    Tokens/ColorToken.swift, TypeToken.swift, ShadowToken.swift, RGBA.swift
    Tokens/Tokens+Color.swift, +Type.swift, +Spacing.swift, +Radius.swift, +Elevation.swift, +Motion.swift
    DynamicColor.swift                       # the one UIKit wrapper
    Modifiers/TypeStyle.swift, Shadowed.swift, Pressable.swift, Haptics.swift
    Components/Buttons.swift, IconButton.swift, StatTile.swift, Card.swift, Rows.swift, SectionHeader.swift,
      Segmented.swift, Checkbox.swift, Fields.swift, CodeField.swift, Chip.swift, Avatar.swift, EmptyState.swift,
      Toast.swift, Dialog.swift, ProgressBar.swift, Skeleton.swift, OfflineBar.swift, CalendarMonth.swift, HeroGlow.swift
    Kit/KitView.swift, KitControls.swift, KitSurfaces.swift   # #if DEBUG
  TutorCentralKit/Sources/Domain/
    AuthUser.swift, Centre.swift, Profile.swift, CentreDraft.swift, PhoneNumber.swift, EmailAddress.swift,
    SignInFailure.swift, TodayCounts.swift, Greeting.swift, DayHeading.swift, AppTab.swift
  TutorCentralKit/Sources/Data/
    SupabaseClientFactory.swift              # replaces DataModule.makeClient: options, redirect URL
    Auth/AuthRepository.swift, SupabaseAuthRepository.swift, FakeAuthRepository.swift, AuthErrorMapping.swift, Nonce.swift
    Centres/CentreRepository.swift, SupabaseCentreRepository.swift, FakeCentreRepository.swift
    Counts/CountsRepository.swift, SupabaseCountsRepository.swift, FakeCountsRepository.swift
  TutorCentralKit/Sources/Features/Onboarding/
    SignIn/SignInView.swift, SignInStore.swift, GoogleMark.swift
    SignIn/EmailSignInSheet.swift, CodeEntryView.swift, PasswordEntryView.swift, EmailSignInStore.swift
    OnboardingView.swift, OnboardingStore.swift
  TutorCentralKit/Sources/Features/Today/TodayView.swift, TodayStore.swift, TodayActions.swift
  TutorCentralKit/Sources/Features/Settings/SettingsView.swift, SettingsStore.swift
  TutorCentralKit/Sources/AppShell/
    RootView.swift (rewritten), LaunchState.swift (cases), Fixtures.swift, Dependencies.swift, SessionStore.swift,
    TabsView.swift, LaterView.swift, DeepLink.swift, ToastCenter.swift, Legal.swift, Appearance.swift (unchanged)
  TutorCentralKit/Tests/DesignSystemTests/TokenDocumentTests.swift, RGBATests.swift
  TutorCentralKit/Tests/DomainTests/PhoneNumberTests.swift, EmailAddressTests.swift, GreetingTests.swift, DayHeadingTests.swift
  TutorCentralKit/Tests/DataTests/AuthErrorMappingTests.swift, NonceTests.swift, FakeAuthRepositoryTests.swift
  TutorCentralKit/Tests/AppShellTests/SessionStoreTests.swift, LaunchStateTests.swift, DeepLinkTests.swift, ToastCenterTests.swift
  TutorCentralKit/Tests/OnboardingTests/SignInStoreTests.swift, EmailSignInStoreTests.swift, OnboardingStoreTests.swift
  TutorCentralKit/Tests/TodayTests/TodayStoreTests.swift
  TutorCentralKit/Tests/SettingsTests/SettingsStoreTests.swift
supabase/
  migrations/20261008000002_create_centre_name.sql     # create_centre with p_display_name; default privileges
  config.toml                                          # + redirect URL, OTP length and expiry (local)
  tests/rls.test.ts                                    # + create_centre sets the name; anon has no default grant
  types.ts                                             # regenerated
tools/check/steps.ts                                   # steps.ts among inputs; types drift in db; CODE_SIGNING_ALLOWED=NO
tools/pr-shots.ts, pr-shots.test.ts                    # refuse duplicate basenames and folders with "/"
.github/workflows/check.yml                            # cancel-in-progress only on pull requests
.github/workflows/deploy.yml                           # VERCEL_TOKEN from the environment
.github/workflows/testflight.yml                       # the lane (D24)
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-2/tokens` | Design tokens as Swift, checked against the document | none (nothing seen) |
| 2 | 2 | `phase-2/kit` | Every Kit component, the Kit screen | `kit`, `kit-surfaces`, both appearances. **The first screen PR: open the PR page and see every picture render before merge; say so in the description** |
| 3 | 3 | `phase-2/foundation-minors` | Deferred minors: check inputs, pr-shots refusals, workflows, xcconfig hint, unsigned simulator builds | none |
| 4 | 4 | `phase-2/create-centre-name` | Migration 0002: `create_centre` takes the tutor's name; anon default privileges; types drift check | none |
| 5 | 5 to 10 | `phase-2/sign-in` | Sign in with Apple, Google, an email code and a password; the session gate | `signin`, `signin-email`, `signin-code`, `signin-code-wrong`, `signin-password`, both appearances |
| 5b | 10b | `phase-2/migrate-lane` | Migrations through `deploy.yml` (D26); 0002 to the hosted project | none; the run's summary |
| 6 | 11, 12 | `phase-2/onboarding` | Onboarding creates the centre | `onboarding`, both |
| 7 | 13, 14 | `phase-2/tabs-today` | Five tabs, Today empty, the later placeholders, deep links, toasts | `today-empty`, `later-students`, `later-fees`, `later-attendance`, `later-more`, both |
| 8 | 15 | `phase-2/settings` | Settings: profile, version, sign out | `settings`, both |
| 9 | 16 | `phase-2/testflight` | The TestFlight lane (D24) | none; the run's summary and the build on the owner's phone |
| main | 17 | | As built, state, record, resume (documents only, D12) | |

Owner steps sit inside the task that needs them, each one checked before the next: Task 9 (App Store Connect record and App ID with Sign in with Apple; Supabase Apple provider; Google web client and Supabase Google provider; redirect URL; email OTP template and expiry; the two legal URLs; for D26 a Supabase access token and the database password as secrets in a `production` environment), Task 16 (App Store Connect API key, the three secrets and three variables, the first install).

---

### Task 1: Tokens as Swift, checked against the document (PR 1)

**Files:**
- Modify: `docs/design/design-tokens.md` (four board-derived tokens, see step 1)
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Tokens/RGBA.swift`, `ColorToken.swift`, `TypeToken.swift`, `ShadowToken.swift`, `Tokens.swift`, `Tokens+Color.swift`, `Tokens+Type.swift`, `Tokens+Spacing.swift`, `Tokens+Radius.swift`, `Tokens+Elevation.swift`, `Tokens+Motion.swift`
- Create: `ios/TutorCentralKit/Sources/DesignSystem/DynamicColor.swift`
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Modifiers/TypeStyle.swift`
- Delete: `ios/TutorCentralKit/Sources/DesignSystem/DesignSystem.swift` (the marker)
- Test: `ios/TutorCentralKit/Tests/DesignSystemTests/RGBATests.swift`, `TokenDocumentTests.swift`
- Modify: `ios/TutorCentralKit/Package.swift` (test target), `ios/project.yml` (scheme)

**Interfaces:**
- Produces: `Tokens.<name>` for every token in the document; `ColorToken.color: Color`; `TypeToken.font`, `.lineSpacing`, `.kerning`, `.uppercase`; `View.typeStyle(_:)`; `ShadowToken` (consumed by Task 2's `shadowed(_:)`); `Tokens.registry` (names to kinds, for the test and the Kit).

- [ ] **Step 1: Add the four values the boards use that the document does not name**

The sign-in, email and onboarding boards paint a marigold glow top right and use 24 pt sides and 80 pt top on the landing; the board wins and the document is fixed in the same commit (`docs/design/README.md`). Append to `design-tokens.md`:

Under "### Special", after `homeIndicator`:

```markdown
| `glowHero` | rgba(255,171,56,.18) | rgba(255,171,56,.18) | The radial glow behind sign-in and the email sheet: 460 × 380 at 90% −8%, fading to nothing at 70% |
| `glowHeroSoft` | rgba(255,171,56,.14) | rgba(255,171,56,.14) | The same glow, softer, behind onboarding |
```

Under "## Spacing", after `contentBottom`:

```markdown
| `heroInset` | 24 | Screen edge to content on the sign-in landing |
| `heroTop` | 80 | Top of screen to the logo on the landing and to the eyebrow on onboarding |
```

- [ ] **Step 2: Write the failing colour-string tests**

`Tests/DesignSystemTests/RGBATests.swift`:

```swift
import Testing
@testable import DesignSystem

struct RGBATests {
    @Test func parsesHex() throws {
        let c = try #require(RGBA(css: "#131110"))
        #expect(c == RGBA(red: 0x13, green: 0x11, blue: 0x10, alpha: 1))
    }

    @Test func parsesRGBAWithAFractionalAlpha() throws {
        let c = try #require(RGBA(css: "rgba(28,25,23,.74)"))
        #expect(c.red == 28 && c.green == 25 && c.blue == 23)
        #expect(abs(c.alpha - 0.74) < 0.001)
    }

    @Test func refusesAnythingElse() {
        #expect(RGBA(css: "text2") == nil)
        #expect(RGBA(css: "#12") == nil)
        #expect(RGBA(css: "rgb(1,2,3)") == nil)
    }

    @Test func writesItselfBackTheWayTheDocumentWritesIt() throws {
        #expect(try #require(RGBA(css: "#F8F4EE")).css == "#F8F4EE")
        #expect(try #require(RGBA(css: "rgba(255,171,56,.14)")).css == "rgba(255,171,56,.14)")
        #expect(try #require(RGBA(css: "rgba(8,6,5,.6)")).css == "rgba(8,6,5,.6)")
    }
}
```

- [ ] **Step 3: Add the test target and run it to see it fail**

`Package.swift`: add `.testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"])`. `project.yml`, scheme `TutorCentral` → `test.targets`: add `- package: TutorCentralKit/DesignSystemTests`.

Run: `bun gen && bun check --only=ios`
Expected: FAIL, `RGBA` not found.

- [ ] **Step 4: RGBA and the token value types**

`Tokens/RGBA.swift`:

```swift
import SwiftUI

/// A colour as the design document writes it: `#RRGGBB` or `rgba(r,g,b,a)`. Kept as numbers so the document test can
/// compare, and so `css` writes it back byte for byte.
public struct RGBA: Hashable, Sendable {
    public let red: Int, green: Int, blue: Int
    public let alpha: Double

    public init(red: Int, green: Int, blue: Int, alpha: Double) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    public init?(css: String) {
        let s = css.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#"), s.count == 7, let v = Int(s.dropFirst(), radix: 16) {
            self.init(red: v >> 16 & 0xFF, green: v >> 8 & 0xFF, blue: v & 0xFF, alpha: 1)
            return
        }
        guard s.hasPrefix("rgba("), s.hasSuffix(")") else { return nil }
        let parts = s.dropFirst(5).dropLast().split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4, let r = Int(parts[0]), let g = Int(parts[1]), let b = Int(parts[2]),
              let a = Double(parts[3].hasPrefix(".") ? "0" + parts[3] : parts[3]) else { return nil }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// The document's spelling: upper-case hex when opaque, `rgba(r,g,b,.a)` with no leading zero otherwise.
    public var css: String {
        if alpha == 1 { return String(format: "#%02X%02X%02X", red, green, blue) }
        var a = String(alpha); if a.hasPrefix("0.") { a.removeFirst() }
        return "rgba(\(red),\(green),\(blue),\(a))"
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }
}
```

`Tokens/ColorToken.swift`:

```swift
import SwiftUI

/// One colour in both appearances (D13). Declared with the document's literals; `color` adapts to the appearance.
public struct ColorToken: Hashable, Sendable {
    public let name: String
    public let dark: RGBA
    public let light: RGBA

    init(_ name: String, dark: String, light: String) {
        self.name = name
        self.dark = RGBA(css: dark)!  // swiftlint:disable:this force_unwrapping — literals in this file, pinned by the document test
        self.light = RGBA(css: light)!  // swiftlint:disable:this force_unwrapping
    }

    public var color: Color { DynamicColor.make(dark: dark, light: light) }
}
```

(If SwiftLint's `force_unwrapping` is not in `opt_in_rules` the comments are unnecessary; keep the file lint-clean either way: prefer a failable `init?` and a `static func literal(...)` that traps with a message if the build session's lint refuses the comments.)

`Tokens/TypeToken.swift`:

```swift
import SwiftUI

/// A text style: SF Pro through Dynamic Type (`style` gives the scaling), the design size, line height, weight,
/// tracking in em, and whether the text is upper-cased (eyebrows).
public struct TypeToken: Hashable, Sendable {
    public let name: String
    public let style: Font.TextStyle
    public let size: CGFloat
    public let line: CGFloat
    public let weight: Font.Weight
    public let trackingEm: CGFloat
    public let uppercase: Bool

    init(_ name: String, _ style: Font.TextStyle, size: CGFloat, line: CGFloat, weight: Int, tracking: CGFloat = 0, uppercase: Bool = false) {
        self.name = name; self.style = style; self.size = size; self.line = line
        self.weight = Self.weight(weight); trackingEm = tracking; self.uppercase = uppercase
    }

    /// 400, 600, 700 and 800 are the only weights the system uses.
    static func weight(_ w: Int) -> Font.Weight {
        switch w { case 400: .regular; case 600: .semibold; case 700: .bold; default: .heavy }
    }

    public var weightNumber: Int {
        switch weight { case .regular: 400; case .semibold: 600; case .bold: 700; default: 800 }
    }

    /// Scaled with the text style's Dynamic Type curve.
    public var font: Font {
        let scaled = UIFontMetrics(forTextStyle: style.uiKit).scaledValue(for: size)
        return .system(size: scaled, weight: weight).monospacedDigit()
    }

    /// Extra space between lines so the line height matches the design at the default size.
    public var lineSpacing: CGFloat { line - size }
    /// Tracking in points at the design size.
    public var kerning: CGFloat { trackingEm * size }
}

extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle; case .title: .title1; case .title2: .title2; case .title3: .title3
        case .headline: .headline; case .subheadline: .subheadline; case .body: .body; case .callout: .callout
        case .footnote: .footnote; case .caption: .caption1; case .caption2: .caption2
        @unknown default: .body
        }
    }
}
```

`Tokens/ShadowToken.swift`:

```swift
import SwiftUI

/// One shadow layer as CSS writes it: "x y blur [spread] colour".
public struct ShadowLayer: Hashable, Sendable {
    public let x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat
    public let color: RGBA
}

/// An elevation token in both appearances, kept as the document's CSS strings (the test compares those) and parsed
/// into drop layers plus an optional inset highlight. SwiftUI has no inset shadow: `shadowed(_:)` (Task 2) draws the
/// inset as a 1 pt top stroke.
public struct ShadowToken: Hashable, Sendable {
    public let name: String
    public let dark: String
    public let light: String

    init(_ name: String, dark: String, light: String) { self.name = name; self.dark = dark; self.light = light }

    /// "inset 0 1px 0 rgba(...), 0 1px 2px rgba(...)" → the drop layers and the inset layer, if any.
    public static func parse(_ css: String) -> (drops: [ShadowLayer], inset: ShadowLayer?) {
        if css == "none" || css.hasPrefix("blur") { return ([], nil) }
        var drops: [ShadowLayer] = []
        var inset: ShadowLayer?
        // Split on "), " so the commas inside rgba() stay together.
        for raw in css.components(separatedBy: "), ") {
            var part = raw.trimmingCharacters(in: .whitespaces)
            if !part.hasSuffix(")") { part += ")" }
            let isInset = part.hasPrefix("inset ")
            if isInset { part.removeFirst(6) }
            guard let colourStart = part.range(of: "rgba(") else { continue }
            let numbers = part[..<colourStart.lowerBound].split(separator: " ")
                .compactMap { Double($0.replacingOccurrences(of: "px", with: "")) }
            guard numbers.count >= 3, let color = RGBA(css: String(part[colourStart.lowerBound...])) else { continue }
            let layer = ShadowLayer(x: numbers[0], y: numbers[1], blur: numbers[2], spread: numbers.count > 3 ? numbers[3] : 0, color: color)
            if isInset { inset = layer } else { drops.append(layer) }
        }
        return (drops, inset)
    }
}
```

(The build session may write `parse` more plainly; its contract is the test in step 7: `shadowRaised` dark gives two drops and one inset, `shadowWell` light gives none.)

- [ ] **Step 5: The dynamic colour wrapper**

`DynamicColor.swift`:

```swift
import SwiftUI
import UIKit

/// The one UIKit wrapper in the design system (D8): SwiftUI cannot make a colour that follows the appearance without an
/// asset catalog, and the tokens live in Swift so the document test can read them (D25). `UIColor(dynamicProvider:)`
/// resolves per trait collection, so `preferredColorScheme` (D23) and the system both work.
enum DynamicColor {
    static func make(dark: RGBA, light: RGBA) -> Color {
        Color(uiColor: UIColor { traits in traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor })
    }
}
```

- [ ] **Step 6: The tokens, declared with the document's literals and registered by name**

`Tokens/Tokens.swift`:

```swift
/// Every value a view may use (D10). Names are the document's (`docs/design/design-tokens.md`): `ground` there is
/// `Tokens.ground` here. The registry lists every token by kind so the document test and the Kit can walk them.
public enum Tokens {
    public enum Kind: Sendable { case color(ColorToken), type(TypeToken), spacing(CGFloat), radius(CGFloat), shadow(ShadowToken), duration(Double) }

    public static let registry: [String: Kind] = {
        var r: [String: Kind] = [:]
        for c in colors { r[c.name] = .color(c) }
        for t in types { r[t.name] = .type(t) }
        for (n, v) in spacings { r[n] = .spacing(v) }
        for (n, v) in radii { r[n] = .radius(v) }
        for s in shadows { r[s.name] = .shadow(s) }
        for (n, v) in durations { r[n] = .duration(v) }
        return r
    }()
}
```

`Tokens/Tokens+Color.swift` (every row of the four colour tables and the glow rows, verbatim from the document; `neutral` is the alias the document gives it and is registered under its own name with `text2`'s values):

```swift
public extension Tokens {
    static let ground = ColorToken("ground", dark: "#131110", light: "#F8F4EE")
    static let surface1 = ColorToken("surface1", dark: "#1C1917", light: "#FFFFFF")
    static let surface2 = ColorToken("surface2", dark: "#272220", light: "#F1EBE2")
    static let well = ColorToken("well", dark: "#0E0C0B", light: "#F3EEE6")
    static let chrome = ColorToken("chrome", dark: "rgba(28,25,23,.74)", light: "rgba(255,255,255,.74)")
    static let dim = ColorToken("dim", dark: "rgba(8,6,5,.6)", light: "rgba(40,30,20,.35)")
    static let line = ColorToken("line", dark: "#302A27", light: "#E8E0D5")
    static let lineStrong = ColorToken("lineStrong", dark: "#3D3632", light: "#D5CBBE")
    static let lineGlass = ColorToken("lineGlass", dark: "rgba(255,255,255,.08)", light: "rgba(0,0,0,.06)")
    static let text = ColorToken("text", dark: "#F6F1EA", light: "#1F1B17")
    static let text2 = ColorToken("text2", dark: "#B9AFA5", light: "#625A52")
    static let text3 = ColorToken("text3", dark: "#958B80", light: "#766D66")
    static let textOnAccent = ColorToken("textOnAccent", dark: "#221400", light: "#231500")
    static let accent = ColorToken("accent", dark: "#FFAB38", light: "#FFAB38")
    static let accentPressed = ColorToken("accentPressed", dark: "#E6952A", light: "#E6952A")
    static let accentText = ColorToken("accentText", dark: "#FFAB38", light: "#A35F00")
    static let accentTint = ColorToken("accentTint", dark: "rgba(255,171,56,.14)", light: "rgba(224,138,0,.14)")
    static let ok = ColorToken("ok", dark: "#56D9A6", light: "#0F7F59")
    static let okTint = ColorToken("okTint", dark: "rgba(86,217,166,.14)", light: "rgba(15,127,89,.12)")
    static let due = ColorToken("due", dark: "#FFB84D", light: "#A85F00")
    static let dueTint = ColorToken("dueTint", dark: "rgba(255,184,77,.14)", light: "rgba(168,95,0,.12)")
    static let overdue = ColorToken("overdue", dark: "#FF6F61", light: "#D13B2C")
    static let overdueTint = ColorToken("overdueTint", dark: "rgba(255,111,97,.14)", light: "rgba(209,59,44,.12)")
    static let neutral = ColorToken("neutral", dark: "#B9AFA5", light: "#625A52")
    static let glowHero = ColorToken("glowHero", dark: "rgba(255,171,56,.18)", light: "rgba(255,171,56,.18)")
    static let glowHeroSoft = ColorToken("glowHeroSoft", dark: "rgba(255,171,56,.14)", light: "rgba(255,171,56,.14)")

    static let colors: [ColorToken] = [
        ground, surface1, surface2, well, chrome, dim, line, lineStrong, lineGlass, text, text2, text3, textOnAccent,
        accent, accentPressed, accentText, accentTint, ok, okTint, due, dueTint, overdue, overdueTint, neutral,
        glowHero, glowHeroSoft,
    ]
}
```

`Tokens+Type.swift` (every row of the type table; the two "second values" the table names inline become their own tokens, `displayHero` and `buttonSecondary`, which the test accepts as extras because the document's `display` and `button` rows name them):

```swift
import SwiftUI

public extension Tokens {
    static let display = TypeToken("display", .largeTitle, size: 34, line: 41, weight: 700, tracking: -0.02)
    static let displayHero = TypeToken("displayHero", .largeTitle, size: 44, line: 48, weight: 800, tracking: -0.03)
    static let title1 = TypeToken("title1", .title, size: 28, line: 34, weight: 700, tracking: -0.02)
    static let title2 = TypeToken("title2", .title2, size: 22, line: 28, weight: 700, tracking: -0.015)
    static let title3 = TypeToken("title3", .title3, size: 20, line: 25, weight: 600, tracking: -0.01)
    static let headline = TypeToken("headline", .headline, size: 17, line: 22, weight: 700)
    static let body = TypeToken("body", .body, size: 17, line: 22, weight: 400)
    static let rowTitle = TypeToken("rowTitle", .callout, size: 16, line: 20, weight: 600)
    static let subhead = TypeToken("subhead", .subheadline, size: 15, line: 20, weight: 400)
    static let footnote = TypeToken("footnote", .footnote, size: 13, line: 18, weight: 400)
    static let caption = TypeToken("caption", .caption, size: 12, line: 16, weight: 400)
    static let eyebrow = TypeToken("eyebrow", .caption, size: 12, line: 16, weight: 600, tracking: 0.08, uppercase: true)
    static let tabLabel = TypeToken("tabLabel", .caption2, size: 10, line: 12, weight: 600, tracking: 0.01)
    static let numberTile = TypeToken("numberTile", .title, size: 26, line: 30, weight: 700, tracking: -0.02)
    static let numberHero = TypeToken("numberHero", .largeTitle, size: 40, line: 44, weight: 700, tracking: -0.02)
    static let numberRow = TypeToken("numberRow", .callout, size: 16, line: 20, weight: 700)
    static let time = TypeToken("time", .subheadline, size: 14, line: 18, weight: 600)
    static let button = TypeToken("button", .callout, size: 16, line: 20, weight: 700)
    static let buttonSecondary = TypeToken("buttonSecondary", .subheadline, size: 15, line: 20, weight: 600)
    static let avatar = TypeToken("avatar", .subheadline, size: 14, line: 18, weight: 700)

    static let types: [TypeToken] = [
        display, displayHero, title1, title2, title3, headline, body, rowTitle, subhead, footnote, caption, eyebrow,
        tabLabel, numberTile, numberHero, numberRow, time, button, buttonSecondary, avatar,
    ]
}
```

`Tokens+Spacing.swift` (the two-value rows `rowPadding` 14 × 16 and `tabBarInset` 16 × 34 become `rowPaddingVertical`/`rowPaddingHorizontal` and `tabBarInsetSide`/`tabBarInsetBottom`; `cardPadding` 18 and its "14 inside a compact card" become `cardPadding` and `cardPaddingCompact`; the test knows these three splits):

```swift
import SwiftUI

public extension Tokens {
    static let inline: CGFloat = 8
    static let fieldGap: CGFloat = 6
    static let rowGapInner: CGFloat = 2
    static let tileGap: CGFloat = 10
    static let sectionGap: CGFloat = 18
    static let sectionHeaderGap: CGFloat = 10
    static let cardPadding: CGFloat = 18
    static let cardPaddingCompact: CGFloat = 14
    static let rowPaddingVertical: CGFloat = 14
    static let rowPaddingHorizontal: CGFloat = 16
    static let pageSide: CGFloat = 20
    static let pageTop: CGFloat = 62
    static let tabBarInsetSide: CGFloat = 16
    static let tabBarInsetBottom: CGFloat = 34
    static let contentBottom: CGFloat = 120
    static let heroInset: CGFloat = 24
    static let heroTop: CGFloat = 80

    static let spacings: [(String, CGFloat)] = [
        ("inline", inline), ("fieldGap", fieldGap), ("rowGapInner", rowGapInner), ("tileGap", tileGap),
        ("sectionGap", sectionGap), ("sectionHeaderGap", sectionHeaderGap), ("cardPadding", cardPadding),
        ("cardPaddingCompact", cardPaddingCompact), ("rowPaddingVertical", rowPaddingVertical),
        ("rowPaddingHorizontal", rowPaddingHorizontal), ("pageSide", pageSide), ("pageTop", pageTop),
        ("tabBarInsetSide", tabBarInsetSide), ("tabBarInsetBottom", tabBarInsetBottom), ("contentBottom", contentBottom),
        ("heroInset", heroInset), ("heroTop", heroTop),
    ]
}
```

`Tokens+Radius.swift` (`radiusBar` 33 with "its active item 28" → `radiusBar` and `radiusBarItem`; `radiusAvatar` is "half the size" → a function, registered by name with value 0 so the test only checks presence; `radiusSegment`'s "track of 13" → `radiusSegmentTrack`):

```swift
import SwiftUI

public extension Tokens {
    static let radiusChip: CGFloat = 14
    static let radiusSegment: CGFloat = 10
    static let radiusSegmentTrack: CGFloat = 13
    static let radiusControl: CGFloat = 15
    static let radiusTile: CGFloat = 16
    static let radiusCard: CGFloat = 18
    static let radiusHero: CGFloat = 20
    static let radiusSheet: CGFloat = 22
    static let radiusBar: CGFloat = 33
    static let radiusBarItem: CGFloat = 28
    static let radiusFull: CGFloat = 9999
    static func radiusAvatar(size: CGFloat) -> CGFloat { size / 2 }

    static let radii: [(String, CGFloat)] = [
        ("radiusChip", radiusChip), ("radiusSegment", radiusSegment), ("radiusSegmentTrack", radiusSegmentTrack),
        ("radiusControl", radiusControl), ("radiusTile", radiusTile), ("radiusCard", radiusCard), ("radiusHero", radiusHero),
        ("radiusSheet", radiusSheet), ("radiusBar", radiusBar), ("radiusBarItem", radiusBarItem), ("radiusFull", radiusFull),
        ("radiusAvatar", 0),
    ]
}
```

`Tokens+Elevation.swift` (every row of the elevation table, the CSS strings verbatim; `blurChrome` is kept as its string and read by Task 2's chrome modifier):

```swift
public extension Tokens {
    static let shadowRaised = ShadowToken("shadowRaised",
        dark: "inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35), 0 12px 32px rgba(0,0,0,.28)",
        light: "0 1px 2px rgba(40,30,20,.05), 0 10px 28px rgba(40,30,20,.07)")
    static let shadowButton = ShadowToken("shadowButton",
        dark: "inset 0 1px 0 rgba(255,255,255,.06), 0 1px 2px rgba(0,0,0,.4)", light: "0 1px 2px rgba(40,30,20,.08)")
    static let shadowPrimary = ShadowToken("shadowPrimary",
        dark: "inset 0 1px 0 rgba(255,255,255,.35), 0 8px 22px rgba(255,171,56,.28)",
        light: "inset 0 1px 0 rgba(255,255,255,.4), 0 8px 22px rgba(224,138,0,.26)")
    static let shadowPrimaryPressed = ShadowToken("shadowPrimaryPressed",
        dark: "inset 0 2px 4px rgba(0,0,0,.25)", light: "inset 0 2px 4px rgba(0,0,0,.15)")
    static let shadowWell = ShadowToken("shadowWell", dark: "inset 0 1px 3px rgba(0,0,0,.6)", light: "none")
    static let shadowSegment = ShadowToken("shadowSegment",
        dark: "inset 0 1px 0 rgba(255,255,255,.1), 0 1px 3px rgba(0,0,0,.55)", light: "0 1px 3px rgba(40,30,20,.14)")
    static let shadowFloat = ShadowToken("shadowFloat",
        dark: "0 10px 30px rgba(0,0,0,.35), inset 0 1px 0 rgba(255,255,255,.06)",
        light: "0 10px 30px rgba(40,30,20,.14), inset 0 1px 0 rgba(255,255,255,.6)")
    static let shadowDialog = ShadowToken("shadowDialog", dark: "0 24px 64px rgba(0,0,0,.55)", light: "0 24px 64px rgba(40,30,20,.2)")
    static let haloFocus = ShadowToken("haloFocus", dark: "0 0 0 3px rgba(255,171,56,.18)", light: "0 0 0 3px rgba(224,138,0,.16)")
    static let blurChrome = ShadowToken("blurChrome", dark: "blur 22, saturate 1.3", light: "blur 22, saturate 1.3")

    static let shadows: [ShadowToken] = [
        shadowRaised, shadowButton, shadowPrimary, shadowPrimaryPressed, shadowWell, shadowSegment, shadowFloat,
        shadowDialog, haloFocus, blurChrome,
    ]

    /// Disabled: opacity 0.45 and no shadow. Stale: 0.55 with a spinner beside it.
    static let opacityDisabled = 0.45
    static let opacityStale = 0.55
}
```

`Tokens+Motion.swift` (durations in seconds; the document's milliseconds are divided by 1000 and the test multiplies back; `toastStay` "5 s; 8 s when it carries an undo" → `toastStay` 5 and `toastStayUndo` 8):

```swift
import SwiftUI

public extension Tokens {
    static let press = 0.16
    static let panel = 0.24
    static let number = 0.5
    static let breathe = 1.6
    static let toastStay = 5.0
    static let toastStayUndo = 8.0
    /// cubic-bezier(.2, .8, .2, 1) for every transition the system does not own.
    static let easeOut = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.2, y: 0.8), endControlPoint: UnitPoint(x: 0.2, y: 1))
    static let pressScale: CGFloat = 0.97

    static let durations: [(String, Double)] = [
        ("press", press), ("panel", panel), ("number", number), ("breathe", breathe), ("toastStay", toastStay), ("toastStayUndo", toastStayUndo),
    ]
}
```

`Modifiers/TypeStyle.swift`:

```swift
import SwiftUI

/// Applies a type token: font (Dynamic Type), line height, tracking, upper-casing. Every text in the app goes through it.
public struct TypeStyle: ViewModifier {
    let token: TypeToken
    public func body(content: Content) -> some View {
        content
            .font(token.font)
            .lineSpacing(token.lineSpacing)
            .kerning(token.kerning)
            .textCase(token.uppercase ? .uppercase : nil)
    }
}

public extension View {
    func typeStyle(_ token: TypeToken) -> some View { modifier(TypeStyle(token: token)) }
}
```

Delete `DesignSystem.swift` (the Phase 1 marker).

- [ ] **Step 7: Run the colour tests; write the document test to fail**

Run: `bun check --only=ios` → `RGBATests` PASS.

`Tests/DesignSystemTests/TokenDocumentTests.swift`. The document is read from the repo (`#filePath` is the test's path on the Mac; the simulator reads the host's files), so the test needs no copy of it:

```swift
import Foundation
import Testing
@testable import DesignSystem

/// Reads docs/design/design-tokens.md and holds the Swift tokens to it, both ways (D25).
struct TokenDocumentTests {
    static let document: String = {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "ios" { url.deleteLastPathComponent() }
        url.deleteLastPathComponent()
        return try! String(contentsOf: url.appending(path: "docs/design/design-tokens.md"), encoding: .utf8)  // swiftlint:disable:this force_try
    }()

    /// Every "| `token` | a | b | ... |" row under a "## Heading", as cells without the back-ticks.
    static func rows(under heading: String) -> [[String]] {
        guard let start = document.range(of: "\n## \(heading)") else { return [] }
        let rest = document[start.upperBound...]
        let section = rest.range(of: "\n## ").map { rest[..<$0.lowerBound] } ?? rest
        return section.split(separator: "\n").compactMap { line in
            guard line.hasPrefix("| `") else { return nil }
            return line.dropFirst().dropLast().split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "`", with: "") }
        }
    }

    @Test func everyColourInTheDocumentIsInSwiftWithTheSameValuesBothWays() throws {
        var documented: [String: (String, String)] = [:]
        for row in rows(under: "Colour") where row.count >= 3 {
            documented[row[0]] = (row[1], row[2])
        }
        #expect(documented.count >= 26)
        for (name, (dark, light)) in documented {
            guard case let .color(token)? = Tokens.registry[name] else { Issue.record("\(name) is in the document, not in Swift"); continue }
            if let d = RGBA(css: dark), let l = RGBA(css: light) {
                #expect(token.dark == d && token.light == l, "\(name) differs: Swift \(token.dark.css)/\(token.light.css), document \(dark)/\(light)")
            }
            // Rows whose values are not colours (appleButton, homeIndicator, neutral's alias) need only exist by name.
        }
        for token in Tokens.colors where documented[token.name] == nil {
            Issue.record("\(token.name) is in Swift, not in the document")
        }
    }

    @Test func everyTypeStyleMatches() throws {
        let extras: Set<String> = ["displayHero", "buttonSecondary"]  // named inside the display and button rows
        var documented: Set<String> = []
        for row in rows(under: "Type") where row.count >= 5 {
            let name = row[0]
            documented.insert(name)
            guard case let .type(token)? = Tokens.registry[name] else { Issue.record("\(name) is in the document, not in Swift"); continue }
            let sizeLine = row[2].split(separator: "/").compactMap { Double($0.trimmingCharacters(in: .whitespaces).split(separator: " ").first ?? "") }
            let weight = Int(row[3].split(separator: " ").first ?? "") ?? -1
            let tracking = Double(row[4].split(separator: "em").first?.replacingOccurrences(of: "+", with: "").trimmingCharacters(in: .init(charactersIn: " ,")) ?? "0") ?? 0
            #expect(sizeLine.count == 2 && token.size == sizeLine[0] && token.line == sizeLine[1], "\(name) size/line")
            #expect(token.weightNumber == weight, "\(name) weight")
            #expect(abs(Double(token.trackingEm) - tracking) < 0.0001, "\(name) tracking")
            #expect(token.uppercase == row[4].contains("uppercase"), "\(name) case")
        }
        for token in Tokens.types where !documented.contains(token.name) && !extras.contains(token.name) {
            Issue.record("\(token.name) is in Swift, not in the document")
        }
    }

    @Test func everySpacingRadiusAndDurationMatches() throws {
        let splits: [String: [String]] = [
            "rowPadding": ["rowPaddingVertical", "rowPaddingHorizontal"], "tabBarInset": ["tabBarInsetSide", "tabBarInsetBottom"],
            "cardPadding": ["cardPadding", "cardPaddingCompact"], "radiusSegment": ["radiusSegment", "radiusSegmentTrack"],
            "radiusBar": ["radiusBar", "radiusBarItem"], "toastStay": ["toastStay", "toastStayUndo"],
        ]
        func check(_ heading: String, _ swift: [(String, Double)], scale: Double) {
            var documented: Set<String> = []
            for row in rows(under: heading) where row.count >= 2 {
                let names = splits[row[0]] ?? [row[0]]
                let numbers = row[1].split(whereSeparator: { !"0123456789.".contains($0) }).compactMap { Double($0) }
                for (i, name) in names.enumerated() {
                    documented.insert(name)
                    guard let value = swift.first(where: { $0.0 == name })?.1 else { Issue.record("\(name) is in the document, not in Swift"); continue }
                    if name == "radiusAvatar" { continue }  // "half the size": a function
                    #expect(i < numbers.count && abs(value * scale - numbers[i]) < 0.0001, "\(name): Swift \(value * scale), document \(row[1])")
                }
            }
            for (name, _) in swift where !documented.contains(name) { Issue.record("\(name) is in Swift, not in the document") }
        }
        check("Spacing", Tokens.spacings.map { ($0.0, Double($0.1)) }, scale: 1)
        check("Radius", Tokens.radii.map { ($0.0, Double($0.1)) }, scale: 1)
        check("Motion", Tokens.durations.map { ($0.0, $0.1 < 10 && $0.0.hasPrefix("toast") ? $0.1 : $0.1 * 1000) }, scale: 1)
    }

    @Test func everyElevationTokenExistsWithTheDocumentsStrings() throws {
        var documented: Set<String> = []
        for row in rows(under: "Elevation") where row.count >= 3 {
            documented.insert(row[0])
            guard case let .shadow(token)? = Tokens.registry[row[0]] else { Issue.record("\(row[0]) is in the document, not in Swift"); continue }
            #expect(token.dark == row[1].replacingOccurrences(of: "`", with: ""), "\(row[0]) dark")
            #expect(token.light == row[2].replacingOccurrences(of: "none; `line` border only", with: "none"), "\(row[0]) light")
        }
        for token in Tokens.shadows where !documented.contains(token.name) { Issue.record("\(token.name) is in Swift, not in the document") }
        let raised = ShadowToken.parse(Tokens.shadowRaised.dark)
        #expect(raised.drops.count == 2 && raised.inset != nil)
        #expect(ShadowToken.parse(Tokens.shadowWell.light).drops.isEmpty)
    }
}
```

The Motion row values are "160 ms", "240 ms", "500 ms", "1600 ms", "5 s" and "8 s": the test's `scale` closure above turns Swift seconds into the document's unit (milliseconds for the first four, seconds for the toast rows). If the parsing of the `shadowWell` light cell ("none; `line` border only") or of the Motion units comes out differently when run, fix the test's parsing, never the document's prose and never a token's value.

Run: `bun check --only=ios`
Expected: PASS for all four. Then **prove the test bites**: change `Tokens.ground`'s dark to `#131111`, run, see `ground differs`, revert; change `inline` in the document to 9, run, see `inline: Swift 8`, revert.

- [ ] **Step 8: Format, lint, commit, PR**

```bash
cd ios && swiftformat . && cd .. && bun check
git checkout -b phase-2/tokens
git add docs/design/design-tokens.md ios
git commit -m "Design tokens as Swift, held to design-tokens.md by a test (D25)"
git push -u origin phase-2/tokens
gh pr create --title "Design tokens as Swift, checked against the document" --body "..."
```

The body says what was built, that nothing on screen changed (no pictures, D7 does not apply), how the test was proved to bite (the two reverted edits), and that D25 is recorded. Merge when green.

### Task 2: Every Kit component and the Kit screen (PR 2)

**Files:**
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Modifiers/Shadowed.swift`, `Pressable.swift`, `Haptics.swift`
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Components/Buttons.swift`, `IconButton.swift`, `StatTile.swift`, `Card.swift`, `Rows.swift`, `SectionHeader.swift`, `Segmented.swift`, `Checkbox.swift`, `Fields.swift`, `CodeField.swift`, `Chip.swift`, `Avatar.swift`, `EmptyState.swift`, `Toast.swift`, `Dialog.swift`, `ProgressBar.swift`, `Skeleton.swift`, `OfflineBar.swift`, `CalendarMonth.swift`, `HeroGlow.swift`
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Kit/KitView.swift`, `KitControls.swift`, `KitSurfaces.swift`
- Modify: `ios/TutorCentralKit/Sources/AppShell/LaunchState.swift` (`kit`, `kitSurfaces`), `RootView.swift` (shows the Kit for those states), `ios/project.yml` (scheme `TutorCentral Kit`)
- Modify: `docs/design/components.md` (the inset-highlight note), `docs/design/information-architecture.md` (`kit-surfaces`)
- Test: `ios/TutorCentralKit/Tests/AppShellTests/LaunchStateTests.swift`

**Interfaces:**
- Produces, used by every screen task: `PrimaryButtonStyle`, `SecondaryButtonStyle`, `QuietButtonStyle`, `DestructiveButtonStyle` (each `init(size: ButtonSize = .form, loading: Bool = false)`), `ButtonSize { form = 46, card = 50, sheet = 52 }`; `IconButton(symbol:label:action:)` and `IconButton(initials:label:action:)`; `StatTile(value:label:tone:action:)`; `Card(.hero|.list|.compact|.selected) { }`; `SettingRow`, `FormFieldRow`, `rowDivider()`; `SectionHeader(title:action:)`; `Segmented`, `Checkbox`; `TextWell(label:text:placeholder:helper:error:keyboard:content:)`, `PhoneWell(label:digits:error:helper:)`, `SecureWell(label:text:)`; `CodeField(code:length:isWrong:)`; `Chip(.status(StatusTone, String)|.neutral(String))`; `Avatar(name:size:)`; `EmptyState(symbol:title:line:action:)`; `ToastView(message:action:)`; `DialogView(title:body:cancel:action:destructive:)`; `ProgressBar(fraction:tone:)`; `SkeletonRow()`; `OfflineBar()`; `CalendarMonth(month:today:selected:marked:)`; `HeroGlow(soft:)`; `View.shadowed(_ token: ShadowToken)`, `View.pressable()`, `Haptic.play(.selection|.success|.warning|.error|.impactLight)`.
- Consumes: Task 1's tokens.

- [ ] **Step 1: The three modifiers**

`Modifiers/Shadowed.swift`:

```swift
import SwiftUI

/// Draws a shadow token: every drop layer as a SwiftUI shadow, the CSS inset highlight as a 1 pt stroke along the top
/// edge inside the shape (SwiftUI has no inset shadow; recorded in components.md). The shape's radius is passed so the
/// stroke follows the corners.
struct Shadowed: ViewModifier {
    let token: ShadowToken
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let parsed = ShadowToken.parse(scheme == .dark ? token.dark : token.light)
        return parsed.drops.reduce(AnyView(content)) { view, layer in
            AnyView(view.shadow(color: Color(uiColor: layer.color.uiColor), radius: layer.blur / 2, x: layer.x, y: layer.y))
        }
        .overlay(alignment: .top) {
            if let inset = parsed.inset {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color(uiColor: inset.color.uiColor), lineWidth: inset.y)
                    .mask(alignment: .top) { Rectangle().frame(height: radius + inset.y) }
                    .allowsHitTesting(false)
            }
        }
    }
}

public extension View {
    func shadowed(_ token: ShadowToken, radius: CGFloat) -> some View { modifier(Shadowed(token: token, radius: radius)) }
}
```

`Modifiers/Pressable.swift`:

```swift
import SwiftUI

/// The press of every control: scale to `pressScale` in `press` seconds with `easeOut`; nothing when reduced motion is on.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? Tokens.pressScale : 1)
            .animation(reduceMotion ? nil : .timingCurve(Tokens.easeOut, duration: Tokens.press), value: configuration.isPressed)
    }
}
```

(The `.timingCurve(UnitCurve, duration:)` overload exists on iOS 17+; if it is missing on the toolchain, build the animation from the bezier's control points with `.timingCurve(0.2, 0.8, 0.2, 1, duration:)`, reading the points from `Tokens.easeOut`.)

`Modifiers/Haptics.swift`:

```swift
import SwiftUI

/// The haptics table of the document. `enabled` is read from UserDefaults ("haptics", default on); Phase 7's Settings
/// row writes it.
public enum Haptic: Sendable {
    case selection, success, warning, error, impactLight

    public static let storageKey = "haptics"

    @MainActor public static func play(_ h: Haptic) {
        guard UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true else { return }
        switch h {
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impactLight: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
```

(`UIKit` feedback generators are the system's haptics; SwiftUI's `sensoryFeedback` could replace them, and the build session may use it instead if every case maps. Either way the file names the reason.)

- [ ] **Step 2: Buttons**

`Components/Buttons.swift`, built from the Buttons table of `components.md`:

```swift
import SwiftUI

public enum ButtonSize: CGFloat, Sendable { case form = 46, card = 50, sheet = 52 }

/// Primary: accent fill, textOnAccent, shadowPrimary; pressed accentPressed and shadowPrimaryPressed; disabled 0.45 and no
/// shadow; loading keeps the width and shows a 20 pt spinner in the label colour.
public struct PrimaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let loading: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(size: ButtonSize = .form, loading: Bool = false) { self.size = size; self.loading = loading }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .typeStyle(Tokens.button)
            .opacity(loading ? 0 : 1)
            .overlay { if loading { ProgressView().tint(Tokens.textOnAccent.color) } }
            .foregroundStyle(Tokens.textOnAccent.color)
            .frame(maxWidth: .infinity, minHeight: size.rawValue, maxHeight: size.rawValue)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .background((pressed ? Tokens.accentPressed : Tokens.accent).color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .modifier(ShadowIf(isEnabled && !loading, pressed ? Tokens.shadowPrimaryPressed : Tokens.shadowPrimary, radius: Tokens.radiusControl))
            .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
            .scaleEffect(pressed ? Tokens.pressScale : 1)
            .animation(.timingCurve(Tokens.easeOut, duration: Tokens.press), value: pressed)
    }
}

/// Secondary: surface2 (dark) / surface1 (light), text 15 600, lineStrong border, shadowButton.
public struct SecondaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme

    public init(size: ButtonSize = .form, loading: Bool = false) { self.size = size; self.loading = loading }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .typeStyle(Tokens.buttonSecondary)
            .opacity(loading ? 0 : 1)
            .overlay { if loading { ProgressView().tint(Tokens.text.color) } }
            .foregroundStyle(Tokens.text.color)
            .frame(maxWidth: .infinity, minHeight: size.rawValue, maxHeight: size.rawValue)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .background((scheme == .dark ? Tokens.surface2 : Tokens.surface1).color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous).strokeBorder(Tokens.lineStrong.color, lineWidth: 1))
            .modifier(ShadowIf(isEnabled && !pressed, Tokens.shadowButton, radius: Tokens.radiusControl))
            .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
            .scaleEffect(pressed ? Tokens.pressScale : 1)
            .animation(.timingCurve(Tokens.easeOut, duration: Tokens.press), value: pressed)
    }
}

/// Quiet: accentText 15 600, no fill. Destructive: overdueTint fill, overdue text.
public struct QuietButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(Tokens.buttonSecondary)
            .foregroundStyle(Tokens.accentText.color)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

public struct DestructiveButtonStyle: ButtonStyle {
    let size: ButtonSize
    public init(size: ButtonSize = .form) { self.size = size }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(Tokens.buttonSecondary)
            .foregroundStyle(Tokens.overdue.color)
            .frame(maxWidth: .infinity, minHeight: size.rawValue, maxHeight: size.rawValue)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .background(Tokens.overdueTint.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .scaleEffect(configuration.isPressed ? Tokens.pressScale : 1)
    }
}

/// A shadow only while a condition holds (disabled and loading controls carry none).
struct ShadowIf: ViewModifier {
    let on: Bool; let token: ShadowToken; let radius: CGFloat
    init(_ on: Bool, _ token: ShadowToken, radius: CGFloat) { self.on = on; self.token = token; self.radius = radius }
    func body(content: Content) -> some View {
        if on { content.shadowed(token, radius: radius) } else { content }
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static func primary(_ size: ButtonSize = .form, loading: Bool = false) -> Self { .init(size: size, loading: loading) }
}
public extension ButtonStyle where Self == SecondaryButtonStyle {
    static func secondary(_ size: ButtonSize = .form, loading: Bool = false) -> Self { .init(size: size, loading: loading) }
}
public extension ButtonStyle where Self == QuietButtonStyle { static var quiet: Self { .init() } }
public extension ButtonStyle where Self == DestructiveButtonStyle { static func destructive(_ size: ButtonSize = .form) -> Self { .init(size: size) } }
```

Sign in with Apple is `SignInWithAppleButton` from AuthenticationServices (the system's own, black on light and white on dark, `appleButton`): it is used directly by Task 9, not wrapped here.

- [ ] **Step 3: The rest of the controls**

Each file follows the paragraph of `components.md` with the same name; the code below is the whole of each, so the Kit renders every state. Sizes and colours are tokens only.

`Components/IconButton.swift`:

```swift
import SwiftUI

/// 40 × 40, round, surface2 fill, lineStrong border, icon 20 in text; the account button shows initials in accentText.
public struct IconButton: View {
    public enum Face { case symbol(String), initials(String) }
    let face: Face; let label: String; let action: () -> Void
    public static let size: CGFloat = 40
    public static let iconSize: CGFloat = 20

    public init(symbol: String, label: String, action: @escaping () -> Void) { face = .symbol(symbol); self.label = label; self.action = action }
    public init(initials: String, label: String, action: @escaping () -> Void) { face = .initials(initials); self.label = label; self.action = action }

    public var body: some View {
        Button(action: action) {
            Group {
                switch face {
                case let .symbol(name): Image(systemName: name).font(.system(size: Self.iconSize)).foregroundStyle(Tokens.text.color)
                case let .initials(text): Text(text).typeStyle(Tokens.avatar).foregroundStyle(Tokens.accentText.color)
                }
            }
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.surface2.color, in: .circle)
            .overlay(Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: 1))
            .shadowed(Tokens.shadowButton, radius: Tokens.radiusAvatar(size: Self.size))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}
```

`Components/StatTile.swift`:

```swift
import SwiftUI

public enum StatTone: Sendable { case plain, zero, due }

/// surface1, line border, radiusTile, padding 14, shadowRaised; value numberTile, label footnote text2; the whole tile presses.
public struct StatTile: View {
    let value: String; let label: String; let tone: StatTone; let action: () -> Void
    public init(value: String, label: String, tone: StatTone = .plain, action: @escaping () -> Void) {
        self.value = value; self.label = label; self.tone = tone; self.action = action
    }
    private var valueColor: Color {
        switch tone { case .plain: Tokens.text.color; case .zero: Tokens.text3.color; case .due: Tokens.due.color }
    }
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                Text(value).typeStyle(Tokens.numberTile).foregroundStyle(valueColor)
                Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.cardPaddingCompact)
            .background(Tokens.surface1.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous).strokeBorder(Tokens.line.color, lineWidth: 1))
            .shadowed(Tokens.shadowRaised, radius: Tokens.radiusTile)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }
}
```

`Components/Card.swift`:

```swift
import SwiftUI

/// Hero (radiusHero, padding 18), List (radiusCard, no padding: rows carry their own), Compact (radiusTile, 14),
/// Selected (accent border and haloFocus). All surface1 with shadowRaised.
public struct Card<Content: View>: View {
    public enum Kind { case hero, list, compact, selected(base: CGFloat) }
    let kind: Kind; let content: Content
    public init(_ kind: Kind = .list, @ViewBuilder content: () -> Content) { self.kind = kind; self.content = content() }

    private var radius: CGFloat {
        switch kind { case .hero: Tokens.radiusHero; case .list: Tokens.radiusCard; case .compact: Tokens.radiusTile; case let .selected(r): r }
    }
    private var padding: CGFloat {
        switch kind { case .hero: Tokens.cardPadding; case .list: 0; case .compact: Tokens.cardPaddingCompact; case .selected: Tokens.cardPaddingCompact }
    }
    private var selected: Bool { if case .selected = kind { true } else { false } }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.surface1.color, in: .rect(cornerRadius: radius, style: .continuous))
            .clipShape(.rect(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder((selected ? Tokens.accent : Tokens.line).color, lineWidth: 1))
            .shadowed(selected ? Tokens.haloFocus : Tokens.shadowRaised, radius: radius)
    }
}

public extension View {
    /// The 1 px line between rows inside a list card; the last row has none.
    func rowDivider() -> some View { overlay(alignment: .bottom) { Rectangle().fill(Tokens.line.color).frame(height: 1) } }
}
```

`Components/Rows.swift` (the Setting and Form field rows, which Phase 2 uses; Student, Class, Schedule, Fee, Attendance and Task rows are on the Kit board and are built here too, as display-only views with the exact columns the Rows table names, each taking its strings and an optional action; the Kit shows one of each with the board's sample content):

```swift
import SwiftUI

/// Setting: symbol 20 text2, label body, value body text2 and chevron, or a switch (`trailing`).
public struct SettingRow<Trailing: View>: View {
    let symbol: String?; let label: String; let trailing: Trailing; let action: (() -> Void)?
    public init(symbol: String? = nil, label: String, action: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.symbol = symbol; self.label = label; self.action = action; self.trailing = trailing()
    }
    public var body: some View {
        let row = HStack(spacing: Tokens.inline + 4) {
            if let symbol { Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(Tokens.text2.color) }
            Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
            Spacer(minLength: Tokens.inline)
            trailing
            if action != nil { Image(systemName: "chevron.right").font(.system(size: 20)).foregroundStyle(Tokens.text3.color) }
        }
        .padding(.vertical, Tokens.rowPaddingVertical).padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: 56)
        .contentShape(.rect)
        if let action { Button(action: action) { row }.buttonStyle(PressableStyle()).accessibilityElement(children: .combine) } else { row.accessibilityElement(children: .combine) }
    }
}

/// Student, Class, Schedule, Fee, Attendance and Task rows: as the Rows table of components.md, display-only until their
/// phases wire them. Each is one struct here with the named columns; the Kit shows the board's sample of each.
public struct StudentRow: View { /* Avatar 40; name rowTitle; class and phone footnote text2; fee numberRow; status caption in its colour; chevron */ ... }
public struct ClassRow: View { /* icon tile 40 surface2 with symbol; name; meeting summary; member count; chevron */ ... }
public struct ScheduleRow: View { /* time in text2 width 46; name; subtitle (ok when taken); check in ok or chevron */ ... }
public struct FeeRow: View { /* name; phone; amount; status chip; on a due row a second line: Remind (secondary), Mark paid (primary) */ ... }
public struct AttendanceRow: View { /* name; Present toggle (ok fill when on) and Absent toggle (overdue fill when on), 44 high */ ... }
public struct TaskRow: View { /* Checkbox 24; title (struck through when done); due day footnote text3 */ ... }
```

The six `...` bodies are written in full by the build session from the Rows table and the Kit-Surfaces board (`Akshita Rao · Class 10 Maths · +91 97991 13211 · Paid 3 Oct`, `Dev Kumar`, `Hemanth`, `Lakshmi`, `Mon, Wed, Fri · 17:00–18:00 · ₹1,200`): the columns, type tokens and colours are all named in that table, nothing is left to taste. Each row is `rowPadding`, at least 56 high, presses whole when it has an action, reads as one accessibility element.

`Components/SectionHeader.swift`:

```swift
import SwiftUI

/// Title headline, optional quiet action on the right, 2 pt side inset so text aligns with card content.
public struct SectionHeader: View {
    let title: String; let action: (label: String, run: () -> Void)?
    public init(_ title: String, action: (label: String, run: () -> Void)? = nil) { self.title = title; self.action = action }
    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
            Spacer()
            if let action { Button(action.label, action: action.run).buttonStyle(.quiet) }
        }
        .padding(.horizontal, Tokens.rowGapInner)
        .padding(.bottom, Tokens.sectionHeaderGap)
    }
}
```

`Components/Segmented.swift`, `Checkbox.swift`, `Chip.swift`, `Avatar.swift`, `ProgressBar.swift`, `Skeleton.swift`, `OfflineBar.swift`, `CalendarMonth.swift`: each as its paragraph of `components.md` says, display-only where Phase 2 has no use (calendar, progress), with these signatures:

```swift
public struct Segmented<Option: Hashable>: View { public init(options: [(Option, String)], selection: Binding<Option>) }  // track well, line border, shadowWell dark, radiusSegmentTrack, padding 3; items 36 high radiusSegment, 14 600 text2; active surface2/surface1 with shadowSegment and text 700; selection haptic
public struct Checkbox: View { public init(isOn: Binding<Bool>, label: String) }  // 24 round, lineStrong ring 1.5; checked ok fill, white tick; selection haptic
public struct Chip: View { public enum Kind { case status(StatusTone, String), neutral(String) }; public init(_ kind: Kind) }  // 28 high, radiusChip, padding 0 10, 13 700; status: tint fill, status text, leading symbol (checkmark paid, clock due, exclamationmark.circle overdue); neutral: surface2, text2 600
public enum StatusTone: Sendable { case ok, due, overdue; var color: ColorToken; var tint: ColorToken; var symbol: String }
public struct Avatar: View { public init(name: String, size: CGFloat = 40) }  // initials (first letters of the first two words) on accentTint in accentText, avatar type (13 pt in 36)
public struct ProgressBar: View { public init(fraction: Double, tone: StatusTone? = nil) }  // 4 high, lineStrong track, ok (or accent) fill, radius 2
public struct SkeletonRow: View { public init(lines: Int = 2) }  // surface2 blocks breathing 1 → 0.55 over `breathe`, ease-in-out, repeating; still under reduced motion
public struct OfflineBar: View { public init(text: String = "Offline. Showing what was last saved.") }  // footnote bar under the navigation bar, surface2, text2
public struct CalendarMonth: View { public init(month: Date, today: Date, selected: Binding<Date?>, marked: Set<Date>, calendar: Calendar = .current) }  // weekday initials caption text3; days subhead 600; today accent disc with textOnAccent; selected surface2 disc; 4 pt accentText dot under marked days; other months hidden; month headline with chevron buttons
```

`Components/Fields.swift`:

```swift
import SwiftUI

/// Label footnote text2 above (fieldGap); the well 46 high, well fill, line border, shadowWell (dark), radiusControl,
/// padding 0 14; focus: accent border and haloFocus; error: overdue border and a footnote overdue line under it,
/// never colour alone; helper: footnote text3 under the well.
public struct Well<Content: View>: View {
    let label: String; let optional: Bool; let helper: String?; let error: String?; let focused: Bool; let content: Content
    public init(label: String, optional: Bool = false, helper: String? = nil, error: String? = nil, focused: Bool, @ViewBuilder content: () -> Content) {
        self.label = label; self.optional = optional; self.helper = helper; self.error = error; self.focused = focused; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack(spacing: Tokens.inline / 2) {
                Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                if optional { Text("(optional)").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color) }
            }
            content
                .frame(height: 46)
                .padding(.horizontal, Tokens.cardPaddingCompact)
                .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                    .strokeBorder((error != nil ? Tokens.overdue : focused ? Tokens.accent : Tokens.line).color, lineWidth: 1))
                .shadowed(focused ? Tokens.haloFocus : Tokens.shadowWell, radius: Tokens.radiusControl)
            if let error {
                Label(error, systemImage: "exclamationmark.circle").typeStyle(Tokens.footnote).foregroundStyle(Tokens.overdue.color)
            } else if let helper {
                Text(helper).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
        }
    }
}

/// A text field in a well. `keyboard` and `content` set the keyboard and the autofill kind.
public struct TextWell: View {
    let label: String; @Binding var text: String; let placeholder: String; let optional: Bool; let helper: String?; let error: String?
    let keyboard: UIKeyboardType; let content: UITextContentType?; let autocapitalisation: TextInputAutocapitalization; let onCommit: () -> Void
    @FocusState private var focused: Bool
    public init(label: String, text: Binding<String>, placeholder: String = "", optional: Bool = false, helper: String? = nil, error: String? = nil,
                keyboard: UIKeyboardType = .default, content: UITextContentType? = nil, autocapitalisation: TextInputAutocapitalization = .words, onCommit: @escaping () -> Void = {}) { ... }
    public var body: some View {
        Well(label: label, optional: optional, helper: helper, error: error, focused: focused) {
            TextField(placeholder, text: $text)
                .typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                .keyboardType(keyboard).textContentType(content).textInputAutocapitalization(autocapitalisation)
                .focused($focused)
                .onSubmit(onCommit)
                .onChange(of: focused) { _, now in if !now { onCommit() } }
        }
    }
}

/// "+91" in text2 600, then the national digits in body 600 monospaced, formatted as typed (98765 43210).
public struct PhoneWell: View {
    let label: String; @Binding var digits: String; let optional: Bool; let helper: String?; let error: String?; let onCommit: () -> Void
    @FocusState private var focused: Bool
    public init(label: String, digits: Binding<String>, optional: Bool = false, helper: String? = nil, error: String? = nil, onCommit: @escaping () -> Void = {}) { ... }
    public var body: some View {
        Well(label: label, optional: optional, helper: helper, error: error, focused: focused) {
            HStack(spacing: Tokens.inline) {
                Text("+91").typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text2.color)
                TextField("98765 43210", text: Binding(get: { Self.grouped(digits) }, set: { digits = String($0.filter(\.isNumber).prefix(10)) }))
                    .typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    .keyboardType(.numberPad).textContentType(.telephoneNumber)
                    .focused($focused)
                    .onChange(of: focused) { _, now in if !now { onCommit() } }
            }
        }
    }
    /// "9876543210" → "98765 43210"
    static func grouped(_ d: String) -> String { d.count > 5 ? "\(d.prefix(5)) \(d.dropFirst(5))" : d }
}

/// A secure field in a well (the password state).
public struct SecureWell: View { public init(label: String, text: Binding<String>, error: String? = nil, onCommit: @escaping () -> Void = {}) { ... } }
```

`Components/CodeField.swift` (the six wells of the code board: 56 high, radiusChip, numberTile digits, one hidden text field with `.oneTimeCode` so the code fills from the email on this phone; the active well carries the accent border and halo; a wrong code paints every border `overdue`):

```swift
import SwiftUI

public struct CodeField: View {
    @Binding var code: String
    let length: Int
    let isWrong: Bool
    @FocusState private var focused: Bool
    public init(code: Binding<String>, length: Int = 6, isWrong: Bool = false) { _code = code; self.length = length; self.isWrong = isWrong }

    public var body: some View {
        ZStack {
            TextField("", text: Binding(get: { code }, set: { code = String($0.filter(\.isNumber).prefix(length)) }))
                .keyboardType(.numberPad).textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.02)  // present for the keyboard and autofill, not seen
                .accessibilityLabel("Six-digit code")
            HStack(spacing: Tokens.inline) {
                ForEach(0..<length, id: \.self) { i in
                    let digit = i < code.count ? String(code[code.index(code.startIndex, offsetBy: i)]) : ""
                    let active = focused && i == min(code.count, length - 1)
                    Text(digit).typeStyle(Tokens.numberTile).foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusChip, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Tokens.radiusChip, style: .continuous)
                            .strokeBorder((isWrong ? Tokens.overdue : active ? Tokens.accent : Tokens.line).color, lineWidth: 1))
                        .shadowed(active ? Tokens.haloFocus : Tokens.shadowWell, radius: Tokens.radiusChip)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
            .onTapGesture { focused = true }
        }
        .onAppear { focused = true }
    }
}
```

`Components/EmptyState.swift`, `Toast.swift`, `Dialog.swift`, `HeroGlow.swift`:

```swift
/// Symbol 28 in text3, title headline, one line subhead text2, optional secondary button (or primary when it is the only thing to do).
public struct EmptyState: View { public enum Emphasis { case secondary, primary }; public init(symbol: String, title: String, line: String, action: (label: String, emphasis: Emphasis, run: () -> Void)? = nil) }
/// Bottom, above the tab bar: surface1, lineStrong border, radiusTile, shadowFloat, padding 12 16, subhead, optional quiet action on the right.
public struct ToastView: View { public init(message: String, action: (label: String, run: () -> Void)? = nil) }
/// surface1, lineStrong border, radiusSheet, shadowDialog, padding 22; title title2, body subhead text2; Cancel (secondary) then the action (primary, or destructive); warning haptic on appearance. Drawn over `dim`.
public struct DialogView: View { public init(title: String, body: String, cancel: String = "Cancel", action: String, destructive: Bool, onCancel: @escaping () -> Void, onAction: @escaping () -> Void) }
/// The radial glow of the landing boards: glowHero (or glowHeroSoft) 460 × 380 centred at 90% −8% of the screen, fading to nothing at 70%.
public struct HeroGlow: View { public init(soft: Bool = false) }
```

- [ ] **Step 4: The Kit screen and its launch states**

`Kit/KitView.swift` (`#if DEBUG` around the whole file and the two section files):

```swift
#if DEBUG
import SwiftUI

/// Every component in every state, in the order of the Kit boards (Kit-Controls, Kit-Surfaces), on `ground`.
/// Reached by `bun shots kit` / `kit-surfaces` and the "TutorCentral Kit" scheme; never in a Release build.
public struct KitView: View {
    public enum Section: String, CaseIterable { case controls, surfaces }
    let startAt: Section
    public init(startAt: Section = .controls) { self.startAt = startAt }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionGap * 2) {
                    KitControls().id(Section.controls)
                    KitSurfaces().id(Section.surfaces)
                }
                .padding(.horizontal, Tokens.pageSide)
                .padding(.top, Tokens.pageTop)
                .padding(.bottom, Tokens.contentBottom)
            }
            .background(Tokens.ground.color)
            .onAppear { proxy.scrollTo(startAt, anchor: .top) }
        }
    }
}
#endif
```

`KitControls` shows, with the board's labels as `eyebrow` headings: Buttons (Mark paid primary default/pressed/disabled/loading; Save secondary; Remind quiet; Not now secondary; Delete student destructive; Continue with Apple as `SignInWithAppleButton`); Icon buttons (symbol and initials); Segmented (Paid, To do, Done) · switch · checkbox; Fields (Student name default, Monthly fee focused with ₹ prefix, Parent WhatsApp number error "Needs 10 digits after +91.", Centre name disabled, Class picker row "Class 10 Maths", Notes multiline); Chips (Paid, Due, Overdue, Present, Absent, neutral) · avatars (40, 36, 56); Progress bar · calendar month. `KitSurfaces`: Navigation (large title "Students" sample, pushed "Akshita Rao" with "Edit", sheet "New student" with Cancel/Save); Rows (one of each, the board's samples); Hero card money pair (Outstanding / Collected); Empty · loading (skeleton) · stale (0.55 with spinner) · error ("Couldn't load fees. Showing Tuesday's." with Retry); Toast ("Dev's fee marked paid by UPI." with Undo) · offline bar; Dialog ("Delete Akshita Rao?" destructive, drawn inline over `dim`).

`AppShell/LaunchState.swift`:

```swift
public enum LaunchState: String, CaseIterable, Sendable {
    case placeholder
    case kit
    case kitSurfaces = "kit-surfaces"
    // Task 8 adds the sign-in, onboarding, tabs and settings cases.
    ...
}
```

`RootView.body`: `switch LaunchState.fromArguments() { case .kit: KitView(); case .kitSurfaces: KitView(startAt: .surfaces); default: the Phase 1 placeholder }`, still under `preferredColorScheme`. In Release builds the two cases fall through to the placeholder (`#if DEBUG`).

`project.yml`, add a scheme:

```yaml
  TutorCentral Kit:
    build:
      targets:
        TutorCentral: all
    run:
      config: Debug
      commandLineArguments:
        "--state kit": true
```

Test, `Tests/AppShellTests/LaunchStateTests.swift`:

```swift
import Testing
@testable import AppShell

struct LaunchStateTests {
    @Test func readsTheStateArgument() {
        #expect(LaunchState.fromArguments(["app", "--state", "kit"]) == .kit)
        #expect(LaunchState.fromArguments(["app", "--state", "kit-surfaces"]) == .kitSurfaces)
        #expect(LaunchState.fromArguments(["app"]) == nil)
        #expect(LaunchState.fromArguments(["app", "--state"]) == nil)
    }

    @Test func everyStateHasAKebabCaseNameForTheShotsTool() {
        for s in LaunchState.allCases { #expect(s.rawValue.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" }, s.rawValue) }
    }
}
```

Documents: `components.md` gets one sentence under Elevation's mention in Cards ("In code the inset top highlight of a raised surface is a 1 pt stroke along the inside of the top edge; SwiftUI has no inset shadow."); `information-architecture.md`'s launch-state table gets the row `kit-surfaces | The Kit, scrolled to surfaces and patterns`.

- [ ] **Step 5: Build, photograph, compare with the boards**

```bash
cd ios && swiftformat . && cd .. && bun check
bun shots kit && bun shots kit-surfaces
open .shots/kit/kit-dark.png .shots/kit/kit-light.png .shots/kit-surfaces/kit-surfaces-dark.png .shots/kit-surfaces/kit-surfaces-light.png
```

Put each picture beside its board (`docs/design/mockups/Kit-Controls-Dark.dc.html` opened in a browser, or the canvas row 4). Fix what differs: a radius, a weight, a colour on the wrong surface. The Kit is the one place the owner sees every component, so it is checked carefully here and not again on every screen.

- [ ] **Step 6: Commit, PR with the pictures, and see them render**

```bash
git checkout -b phase-2/kit
git add docs ios
git commit -m "Every Kit component and the Kit screen, to the Kit boards"
git push -u origin phase-2/kit
bun pr-shots phase-2-kit .shots/kit/*.png .shots/kit-surfaces/*.png
gh pr create --title "Every Kit component, the Kit screen" --body-file -   # the table from pr-shots pasted in
```

Then `gh pr view --web`, look at the PR page, and confirm every one of the four pictures renders (the Phase 1 review asked for this to be seen once). Write "Pictures checked on the PR page" in the description. If a picture does not render, the `?raw=true` link or the branch push is the fault: fix `pr-shots.ts` in this PR before merging. Merge when green.

### Task 3: The deferred minors whose files this phase touches (PR 3)

**Files:**
- Modify: `tools/check.ts` (the step definitions are part of every step's salt), `tools/check/steps.ts` (xcconfig hint, unsigned simulator builds, types drift in `db`), `tools/pr-shots.ts` (refusals), `tools/pr-shots.test.ts`, `tools/check/steps.test.ts`
- Modify: `.github/workflows/check.yml` (cancel only pull requests), `.github/workflows/deploy.yml` (token from the environment)

**Interfaces:**
- Produces: `commitShots` throws `"duplicate picture name: x-dark.png"` and `"folder must be one name, not a path: a/b"`; `localConfigHint(exists: boolean): string | null` in `steps.ts`.

- [ ] **Step 1: Write the failing tests**

`tools/pr-shots.test.ts`, append:

```ts
test("refuses two pictures with the same name and a folder that is a path", async () => {
  const repo = await scratchRepo();
  const a = join(repo, "x-dark.png");
  const b = join(repo, "sub");
  await must(["mkdir", "-p", b], { cwd: repo });
  writeFileSync(a, "1");
  writeFileSync(join(b, "x-dark.png"), "2");
  await expect(commitShots({ repo, folder: "demo", files: [a, join(b, "x-dark.png")], push: false, author })).rejects.toThrow("duplicate picture name: x-dark.png");
  await expect(commitShots({ repo, folder: "a/b", files: [a], push: false, author })).rejects.toThrow("folder must be one name, not a path: a/b");
});
```

`tools/check/steps.test.ts`, append:

```ts
import { localConfigHint } from "./steps";

test("a missing Local.xcconfig gets a one-line hint instead of XcodeGen's error", () => {
  expect(localConfigHint(false)).toContain("cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig");
  expect(localConfigHint(true)).toBeNull();
});
```

Run: `bun test tools` → FAIL (three expectations).

- [ ] **Step 2: Make them pass**

`tools/pr-shots.ts`, at the top of `commitShots`:

```ts
  if (o.folder.includes("/")) throw new Error(`folder must be one name, not a path: ${o.folder}`);
  const names = o.files.map((f) => basename(f));
  const dup = names.find((n, i) => names.indexOf(n) !== i);
  if (dup) throw new Error(`duplicate picture name: ${dup}`);
```

`tools/check/steps.ts`:

```ts
/** A fresh clone has no ios/Config/Local.xcconfig; XcodeGen's own error does not say what to do. */
export function localConfigHint(exists: boolean): string | null {
  return exists ? null : "ios/Config/Local.xcconfig is missing: cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig and fill it from `cd supabase && supabase status -o env`";
}
```

In the `ios` step's `run`, first: `const hint = localConfigHint(await Bun.file("ios/Config/Local.xcconfig").exists()); if (hint) throw new Error(hint);`.

The simulator build never needs a signing identity, and the Sign in with Apple entitlement (Task 9) must not make it look for one on a Mac or runner without the team:

```ts
const XCODEBUILD = `xcodebuild -project TutorCentral.xcodeproj -scheme TutorCentral -destination '${simulatorDestination(process.env)}' CODE_SIGNING_ALLOWED=NO`;
```

The `db` step, after the tests and before the re-seed, checks that `types.ts` is what the migrations produce:

```ts
      await run("supabase gen types typescript --local > .types.generated.ts && diff -q .types.generated.ts types.ts && rm .types.generated.ts || (rm -f .types.generated.ts; echo 'supabase/types.ts is stale: run `supabase gen types typescript --local > types.ts`'; exit 1)", "supabase");
```

(`.types.generated.ts` is added to `supabase/.gitignore`.)

`tools/check.ts`: the step definitions become part of the salt, so editing a step's command re-runs it:

```ts
const salt = `${await toolchainSalt()}|${await hashInputs(["tools/check/*.ts", "tools/check.ts"], ".", "")}`;
```

`.github/workflows/check.yml`: `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` (a `--fresh` run on `main` is never cut short by the next push).

`.github/workflows/deploy.yml`: remove every `--token="$VERCEL_TOKEN"`; the CLI reads `VERCEL_TOKEN` from the environment, which each step already sets.

Run: `bun check` → green (`tools` ran; `ios` re-ran because its command changed).

- [ ] **Step 3: Commit, PR**

```bash
git checkout -b phase-2/foundation-minors
git add tools .github supabase/.gitignore
git commit -m "Deferred minors: step definitions in the salt, pr-shots refusals, xcconfig hint, unsigned simulator builds, types drift, workflow fixes"
git push -u origin phase-2/foundation-minors && gh pr create --title "Deferred minors from the Phase 1 review" --body "..."
```

No pictures (nothing seen changes). The body lists the minors taken and the two left (brew pins: Homebrew cannot pin; Phase 6 image size: not this phase). Merge when green. Remove the taken items from `plan/STATE.md` in the documents commit of Task 17.

### Task 4: Migration 0002: `create_centre` takes the tutor's name; anon default privileges (PR 4)

**Files:**
- Create: `supabase/migrations/20261008000002_create_centre_name.sql`
- Modify: `supabase/config.toml` (local auth: redirect URL, OTP expiry), `supabase/tests/rls.test.ts`, `supabase/types.ts` (regenerated)

**Interfaces:**
- Produces: `create_centre(p_name text, p_whatsapp text default null, p_display_name text default null) returns uuid`, called by Task 7's `SupabaseCentreRepository.createCentre`.

- [ ] **Step 1: Write the failing tests**

`supabase/tests/rls.test.ts`, append:

```ts
test("create_centre writes the tutor's name on their profile, and leaves it alone when not given", async () => {
  const c = await userClient(l, `rls-c-${stamp}@example.com`);
  const { data: centreC, error } = await c.rpc("create_centre", { p_name: "Centre C", p_whatsapp: null, p_display_name: "Meera Nair" });
  expect(error).toBeNull();
  const { data: profile } = await c.from("profiles").select("display_name").single();
  expect(profile?.display_name).toBe("Meera Nair");
  const { data: centre } = await c.from("centres").select("name, whatsapp_number").eq("id", centreC as string).single();
  expect(centre).toEqual({ name: "Centre C", whatsapp_number: null });
});

test("create_centre refuses a malformed WhatsApp number in words the app can match", async () => {
  const d = await userClient(l, `rls-d-${stamp}@example.com`);
  const { error } = await d.rpc("create_centre", { p_name: "Centre D", p_whatsapp: "98765 43210" });
  expect(error?.code).toBe("23514"); // check_violation: the app validates first (PhoneNumber), this is the floor
});

test("anonymous gets no grant on a table or function made after migration 0001", async () => {
  const sql = new SQL(l.db);
  await sql`create table public.zz_probe (id int)`;
  await sql`create function public.zz_probe_fn() returns int language sql as 'select 1'`;
  try {
    const grants = await sql`select grantee, privilege_type from information_schema.role_table_grants where table_name = 'zz_probe' and grantee = 'anon'`;
    expect(grants).toEqual([]);
    const fn = await sql`select grantee from information_schema.role_routine_grants where routine_name = 'zz_probe_fn' and grantee in ('anon', 'PUBLIC')`;
    expect(fn).toEqual([]);
  } finally {
    await sql`drop function public.zz_probe_fn()`;
    await sql`drop table public.zz_probe`;
    await sql.close();
  }
});
```

(`l.db` is the database URL `tests/client.ts` exposes; `SQL` is already imported at the top of the file.)

Run: `bun check --only=db` → the first fails (`p_display_name` does not exist), the third fails (anon has grants through default privileges).

- [ ] **Step 2: The migration**

`supabase/migrations/20261008000002_create_centre_name.sql`:

```sql
-- Onboarding is one screen and one call: the centre, the owner membership and the tutor's name (Phase 2).
-- The function is replaced with a third parameter; migration 0001 is not edited.

drop function public.create_centre(text, text);

create function public.create_centre(p_name text, p_whatsapp text default null, p_display_name text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare cid uuid;
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode = '42501'; end if;
  insert into public.centres (owner_id, name, whatsapp_number) values (auth.uid(), p_name, p_whatsapp) returning id into cid;
  insert into public.centre_members (centre_id, user_id, role) values (cid, auth.uid(), 'owner');
  insert into public.profiles (user_id, display_name) values (auth.uid(), p_display_name)
    on conflict (user_id) do update set display_name = coalesce(excluded.display_name, public.profiles.display_name);
  return cid;
end $$;

revoke all on function public.create_centre(text, text, text) from public, anon;
grant execute on function public.create_centre(text, text, text) to authenticated;

-- Deferred from the Phase 1 review: Supabase's default privileges grant anon on future tables and functions.
-- RLS protects either way; this closes the door for what later migrations create.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from anon, public;
alter default privileges in schema public revoke all on sequences from anon;
```

If the probe test still finds a grant, the default privileges were set by a different role than the migration runs as (`postgres` versus `supabase_admin`): add `alter default privileges for role postgres, supabase_admin in schema public revoke ...` for each and keep the test as the proof.

`supabase/config.toml`: `additional_redirect_urls = ["https://127.0.0.1:3000", "tutorcentral://auth-callback"]`; under `[auth.email]` `otp_expiry = 600` (the board says ten minutes; the hosted project gets the same in Task 9's owner step).

```bash
cd supabase && supabase db reset && supabase gen types typescript --local > types.ts && cd ..
bun check --only=db
```

Expected: green, including the types drift check from Task 3.

- [ ] **Step 3: Commit, PR, push the migration to the hosted project after merge**

```bash
git checkout -b phase-2/create-centre-name
git add supabase
git commit -m "Migration 0002: create_centre takes the tutor's name; anon gets no default privileges"
git push -u origin phase-2/create-centre-name && gh pr create --title "Migration 0002: create_centre with the tutor's name; anon default privileges" --body "..."
```

After merge: nothing by hand (D26, superseding this step). 0002 goes up through `deploy.yml`'s `migrate` job, built in Task 10b.

### Task 5: Domain: the user, the centre, the profile, an email address, a failure (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/AuthUser.swift`, `Centre.swift`, `Profile.swift`, `EmailAddress.swift`, `SignInFailure.swift`, `AppTab.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/EmailAddressTests.swift`

**Interfaces:**
- Produces: `AuthUser { id: UUID; email: String?; fullName: String? }`, `Centre { id: UUID; name: String; whatsappNumber: String? }` (E.164 or nil), `Profile { displayName: String? }`, `EmailAddress(_:)` failable with `.string`, `SignInFailure` (below), `AppTab`.

- [ ] **Step 1: Failing test**

```swift
import Testing
@testable import Domain

struct EmailAddressTests {
    @Test func acceptsAnOrdinaryAddressAndNormalisesCaseAndSpaces() {
        #expect(EmailAddress(" Meera.Nair@Gmail.com ")?.string == "meera.nair@gmail.com")
    }

    @Test func refusesWhatIsNotAnAddress() {
        for s in ["", "meera", "meera@", "@gmail.com", "meera@gmail", "me era@gmail.com", "meera@@gmail.com"] {
            #expect(EmailAddress(s) == nil, s)
        }
    }
}
```

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: Implement**

`EmailAddress.swift`:

```swift
/// An email address the app will send a code to: one @, a dot in the domain, no spaces. Lower-cased and trimmed.
public struct EmailAddress: Hashable, Sendable {
    public let string: String

    public init?(_ raw: String) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = s.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."), !parts[1].hasPrefix("."), !parts[1].hasSuffix("."),
              !s.contains(where: \.isWhitespace) else { return nil }
        string = s
    }
}
```

`AuthUser.swift`:

```swift
import Foundation

/// The signed-in person as Supabase Auth knows them. `fullName` comes only from Apple's first sign-in or Google's
/// profile; it prefills onboarding and is never shown as the tutor's name (that is `Profile.displayName`).
public struct AuthUser: Hashable, Sendable {
    public let id: UUID
    public let email: String?
    public let fullName: String?
    public init(id: UUID, email: String?, fullName: String? = nil) { self.id = id; self.email = email; self.fullName = fullName }
}
```

`Centre.swift`, `Profile.swift`:

```swift
import Foundation

public struct Centre: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    /// E.164 (+919611299988) or nil.
    public var whatsappNumber: String?
    public init(id: UUID, name: String, whatsappNumber: String?) { self.id = id; self.name = name; self.whatsappNumber = whatsappNumber }
}

public struct Profile: Hashable, Sendable {
    public var displayName: String?
    public init(displayName: String?) { self.displayName = displayName }
    /// "Meera Nair" → "Meera"; nil when there is no name.
    public var firstName: String? { displayName?.split(separator: " ").first.map(String.init) }
    /// "Meera Nair" → "MN"; "Meera" → "M"; nil → "?"
    public var initials: String { (displayName ?? "").split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased().nilIfEmpty ?? "?" }
}

extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
```

`SignInFailure.swift` (every sign-in error the app can tell apart, mapped from Supabase in Task 6 and put into words by the stores in Tasks 9 and 10):

```swift
/// Why a sign-in step did not complete. The words a tutor reads live with the screens; this is what happened.
public enum SignInFailure: Error, Hashable, Sendable {
    case cancelled              // the Apple sheet or the web session was dismissed: not an error on screen
    case offline
    case wrongCode
    case codeExpired
    case tooManyRequests        // Supabase's email or request rate limit
    case wrongPassword          // invalid credentials on the password path
    case providerRefused        // Apple or Google answered with an error that is not the user's doing
    case other(String)          // Supabase's message, shown as "Couldn't sign in. <message>"
}
```

`AppTab.swift`:

```swift
/// The five tabs, in order. Lives in Domain so a feature can ask AppShell to switch tabs without importing it.
public enum AppTab: String, CaseIterable, Sendable, Hashable {
    case today, students, fees, attendance, more
}
```

Run: `bun check --only=ios` → PASS. Commit on `phase-2/sign-in`: `git checkout -b phase-2/sign-in && git add ios && git commit -m "Domain: user, centre, profile, email address, sign-in failure, tabs"`.

### Task 6: Data: the auth repository, Supabase and fake (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Auth/AuthRepository.swift`, `AuthErrorMapping.swift`, `Nonce.swift`, `SupabaseAuthRepository.swift`, `FakeAuthRepository.swift`
- Create: `ios/TutorCentralKit/Sources/Data/SupabaseClientFactory.swift`; delete `Data.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/NonceTests.swift`, `AuthErrorMappingTests.swift`, `FakeAuthRepositoryTests.swift`

**Interfaces:**
- Produces:

```swift
public protocol AuthRepository: Sendable {
    /// The user from the keychain session at launch, or nil. Never throws: a broken session reads as signed out.
    func currentUser() async -> AuthUser?
    /// Every change after the current state: a user on sign-in, nil on sign-out.
    func changes() -> AsyncStream<AuthUser?>
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws(SignInFailure) -> AuthUser
    func signInWithGoogle() async throws(SignInFailure) -> AuthUser
    func requestCode(email: EmailAddress) async throws(SignInFailure)
    func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser
    func signIn(email: EmailAddress, password: String) async throws(SignInFailure) -> AuthUser
    func signOut() async
}
```

  `Nonce.random() -> String` (32 bytes, hex) and `Nonce.sha256(_:) -> String` (hex); `SignInFailure.init(_ error: any Error)`; `SupabaseClientFactory.make(_ config: SupabaseConfig) -> SupabaseClient` (with `auth.redirectToURL = tutorcentral://auth-callback`); `FakeAuthRepository` (`@MainActor final class`) with `user: AuthUser?`, `nextFailure: SignInFailure?`, `requested: [EmailAddress]`, `verified: [(EmailAddress, String)]`, `signedOut: Int`, and `emit(_ user: AuthUser?)`.

- [ ] **Step 1: Failing tests**

`NonceTests.swift`:

```swift
import Testing
@testable import Data

struct NonceTests {
    @Test func aNonceIsSixtyFourHexCharactersAndNeverRepeats() {
        let a = Nonce.random(), b = Nonce.random()
        #expect(a.count == 64 && a.allSatisfy(\.isHexDigit) && a != b)
    }

    @Test func sha256IsTheKnownDigest() {
        #expect(Nonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
```

`AuthErrorMappingTests.swift`:

```swift
import Auth
import AuthenticationServices
import Foundation
import Testing
@testable import Data

struct AuthErrorMappingTests {
    func api(_ code: ErrorCode, _ message: String = "m") -> AuthError {
        .api(message: message, errorCode: code, underlyingData: Data(), underlyingResponse: HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 400, httpVersion: nil, headerFields: nil)!)
    }

    @Test func supabaseCodesBecomeTheFailuresTheScreensName() {
        #expect(SignInFailure(api(.otpExpired)) == .codeExpired)
        #expect(SignInFailure(api(.overEmailSendRateLimit)) == .tooManyRequests)
        #expect(SignInFailure(api(.overRequestRateLimit)) == .tooManyRequests)
        #expect(SignInFailure(api(.invalidCredentials)) == .wrongPassword)
        #expect(SignInFailure(api(.validationFailed, "Token has expired or is invalid")) == .wrongCode)
        #expect(SignInFailure(api(.emailProviderDisabled, "Email logins are disabled")) == .other("Email logins are disabled"))
    }

    @Test func aDismissedSheetOrSessionIsCancelled() {
        #expect(SignInFailure(ASAuthorizationError(.canceled)) == .cancelled)
        #expect(SignInFailure(ASWebAuthenticationSessionError(.canceledLogin)) == .cancelled)
    }

    @Test func noNetworkIsOffline() {
        #expect(SignInFailure(URLError(.notConnectedToInternet)) == .offline)
        #expect(SignInFailure(URLError(.timedOut)) == .offline)
    }

    @Test func aFailureStaysItself() {
        #expect(SignInFailure(SignInFailure.wrongCode) == .wrongCode)
    }
}
```

`FakeAuthRepositoryTests.swift`:

```swift
import Domain
import Testing
@testable import Data

@MainActor struct FakeAuthRepositoryTests {
    @Test func scriptedFailureFiresOnceThenTheHappyPathReturns() async throws {
        let fake = FakeAuthRepository()
        fake.nextFailure = .wrongCode
        let email = EmailAddress("a@b.co")!
        await #expect(throws: SignInFailure.wrongCode) { try await fake.verifyCode(email: email, code: "000000") }
        let user = try await fake.verifyCode(email: email, code: "481234")
        #expect(user.email == "a@b.co")
        #expect(await fake.currentUser() == user)
        #expect(fake.verified.map(\.1) == ["000000", "481234"])
    }

    @Test func changesStreamSeesSignInAndSignOut() async throws {
        let fake = FakeAuthRepository()
        let stream = fake.changes()
        var it = stream.makeAsyncIterator()
        _ = try await fake.signInWithGoogle()
        #expect(await it.next()??.email == "meera.nair@gmail.com")
        await fake.signOut()
        #expect(await it.next() == .some(nil))
        #expect(fake.signedOut == 1)
    }
}
```

Run: `bun check --only=ios` → FAIL to compile.

- [ ] **Step 2: Implement**

`Nonce.swift`:

```swift
import CryptoKit
import Foundation

/// Sign in with Apple wants a nonce: the raw one goes to Supabase, its SHA-256 goes to Apple.
public enum Nonce {
    public static func random() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
```

`AuthErrorMapping.swift`:

```swift
import Auth
import AuthenticationServices
import Domain
import Foundation

public extension SignInFailure {
    /// Supabase's, Apple's, the web session's and the network's errors, each to the one failure the screens name.
    init(_ error: any Error) {
        switch error {
        case let f as SignInFailure: self = f
        case let e as ASAuthorizationError where e.code == .canceled: self = .cancelled
        case let e as ASWebAuthenticationSessionError where e.code == .canceledLogin: self = .cancelled
        case is ASAuthorizationError, is ASWebAuthenticationSessionError: self = .providerRefused
        case let e as URLError:
            self = [.notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed].contains(e.code) ? .offline : .other(e.localizedDescription)
        case let .api(message, code, _, _) as AuthError:
            switch code {
            case .otpExpired: self = .codeExpired
            case .overEmailSendRateLimit, .overRequestRateLimit: self = .tooManyRequests
            case .invalidCredentials: self = .wrongPassword
            case .validationFailed where message.localizedCaseInsensitiveContains("token"): self = .wrongCode
            default: self = .other(message)
            }
        default: self = .other(error.localizedDescription)
        }
    }
}
```

(Supabase answers a wrong six-digit code with `403 validation_failed "Token has expired or is invalid"` and an expired one with `otp_expired`; both are confirmed against the local stack in step 3.)

`SupabaseClientFactory.swift` (replaces `DataModule`):

```swift
import Foundation
import Supabase

/// The one client. The redirect URL is the app's scheme (Info.plist, Task 9): Google's web session comes back to it.
public enum SupabaseClientFactory {
    public static let redirectURL = URL(string: "tutorcentral://auth-callback")!  // swiftlint:disable:this force_unwrapping

    public static func make(_ config: SupabaseConfig) -> SupabaseClient {
        SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey, options: .init(auth: .init(redirectToURL: redirectURL)))
    }
}
```

`SupabaseAuthRepository.swift`:

```swift
import Auth
import Domain
import Foundation
import Supabase

/// supabase-swift's AuthClient behind the protocol: the keychain session, Apple by id token, Google by its own
/// ASWebAuthenticationSession (the inventory row), the email code and the password.
public final class SupabaseAuthRepository: AuthRepository {
    private let auth: AuthClient
    public init(client: SupabaseClient) { auth = client.auth }

    public func currentUser() async -> AuthUser? {
        (try? await auth.session)?.user.authUser
    }

    public func changes() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in auth.authStateChanges where event != .initialSession {
                    continuation.yield(session?.user.authUser)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws(SignInFailure) -> AuthUser {
        try await wrap {
            let session = try await auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
            var user = session.user.authUser
            if let fullName, user.fullName == nil { user = AuthUser(id: user.id, email: user.email, fullName: fullName) }
            return user
        }
    }

    public func signInWithGoogle() async throws(SignInFailure) -> AuthUser {
        try await wrap { try await auth.signInWithOAuth(provider: .google, redirectTo: SupabaseClientFactory.redirectURL).user.authUser }
    }

    public func requestCode(email: EmailAddress) async throws(SignInFailure) {
        try await wrap { try await auth.signInWithOTP(email: email.string, shouldCreateUser: true) }
    }

    public func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser {
        try await wrap { try await auth.verifyOTP(email: email.string, token: code, type: .email).user.authUser }
    }

    public func signIn(email: EmailAddress, password: String) async throws(SignInFailure) -> AuthUser {
        try await wrap { try await auth.signIn(email: email.string, password: password).user.authUser }
    }

    public func signOut() async {
        try? await auth.signOut(scope: .local)
    }

    private func wrap<T: Sendable>(_ body: () async throws -> T) async throws(SignInFailure) -> T {
        do { return try await body() } catch { throw SignInFailure(error) }
    }
}

extension User {
    /// Apple sends the name only on the first authorisation, in the credential, not in the token; Google puts it in
    /// `user_metadata.full_name` (and `name`).
    var authUser: AuthUser {
        AuthUser(id: id, email: email, fullName: (userMetadata["full_name"] ?? userMetadata["name"])?.stringValue)
    }
}
```

`FakeAuthRepository.swift`:

```swift
import Domain
import Foundation

/// The in-memory auth for tests, previews and `bun shots`: scripted failures, a record of every call, a stream that
/// tests and the session gate can observe.
@MainActor public final class FakeAuthRepository: AuthRepository {
    public static let meera = AuthUser(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, email: "meera.nair@gmail.com", fullName: "Meera Nair")  // swiftlint:disable:this force_unwrapping

    public var user: AuthUser?
    public var nextFailure: SignInFailure?
    public private(set) var requested: [EmailAddress] = []
    public private(set) var verified: [(EmailAddress, String)] = []
    public private(set) var signedOut = 0
    private var continuations: [UUID: AsyncStream<AuthUser?>.Continuation] = [:]

    public init(user: AuthUser? = nil) { self.user = user }

    public func currentUser() async -> AuthUser? { user }

    public nonisolated func changes() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            let key = UUID()
            Task { @MainActor in self.continuations[key] = continuation }
            continuation.onTermination = { _ in Task { @MainActor in self.continuations[key] = nil } }
        }
    }

    public func emit(_ user: AuthUser?) {
        self.user = user
        for c in continuations.values { c.yield(user) }
    }

    private func takeFailure() throws(SignInFailure) {
        if let f = nextFailure { nextFailure = nil; throw f }
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws(SignInFailure) -> AuthUser {
        try takeFailure(); let u = AuthUser(id: Self.meera.id, email: Self.meera.email, fullName: fullName); emit(u); return u
    }
    public func signInWithGoogle() async throws(SignInFailure) -> AuthUser { try takeFailure(); emit(Self.meera); return Self.meera }
    public func requestCode(email: EmailAddress) async throws(SignInFailure) { try takeFailure(); requested.append(email) }
    public func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser {
        verified.append((email, code)); try takeFailure()
        let u = AuthUser(id: Self.meera.id, email: email.string, fullName: nil); emit(u); return u
    }
    public func signIn(email: EmailAddress, password: String) async throws(SignInFailure) -> AuthUser {
        try takeFailure(); let u = AuthUser(id: Self.meera.id, email: email.string, fullName: nil); emit(u); return u
    }
    public func signOut() async { signedOut += 1; emit(nil) }
}
```

Run: `bun check --only=ios` → PASS.

- [ ] **Step 3: Prove the two Supabase codes against the local stack, once, by hand**

With `supabase start` up and the app's `Local.xcconfig` pointing at it, the quickest proof is `curl`:

```bash
cd supabase && eval "$(supabase status -o env | sed 's/^/export /')"
curl -s -X POST "$API_URL/auth/v1/otp" -H "apikey: $ANON_KEY" -H "Content-Type: application/json" -d '{"email":"probe@example.com"}'
curl -s -X POST "$API_URL/auth/v1/verify" -H "apikey: $ANON_KEY" -H "Content-Type: application/json" -d '{"email":"probe@example.com","token":"000000","type":"email"}'
```

Expected: the second answers `403` with `error_code` `otp_expired` or `validation_failed`; set the mapping in `AuthErrorMapping.swift` and its test to what the stack really says for a wrong code (the two codes are both handled; this step pins which one the wrong-code path uses so the test's `.wrongCode` expectation is true). The real code is in Mailpit at http://127.0.0.1:54324.

Commit: `git add ios && git commit -m "Data: the auth repository, Supabase and in-memory, with the error mapping"`.

### Task 7: Data: the centre repository (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Centres/CentreRepository.swift`, `SupabaseCentreRepository.swift`, `FakeCentreRepository.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/FakeCentreRepositoryTests.swift`

**Interfaces:**
- Produces:

```swift
public struct Workspace: Hashable, Sendable { public let user: AuthUser; public var centre: Centre; public var profile: Profile }
public struct CentreDraft: Hashable, Sendable { public var displayName: String; public var centreName: String; public var whatsappNumber: String? }  // E.164 or nil

public protocol CentreRepository: Sendable {
    /// The centre the user belongs to, with their profile, or nil when they have none yet (onboarding).
    func workspace(for user: AuthUser) async throws -> Workspace?
    /// One call: centre, membership, profile name (create_centre, migration 0002).
    func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace
    func updateCentre(id: UUID, name: String, whatsappNumber: String?) async throws
    func updateProfile(displayName: String) async throws
}
```

  `FakeCentreRepository` (`@MainActor final class`): `workspace: Workspace?`, `nextError: Error?`, `created: [CentreDraft]`, `centreUpdates`, `profileUpdates`.

- [ ] **Step 1: Failing test**

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeCentreRepositoryTests {
    @Test func noWorkspaceUntilCreated_thenTheDraftBecomesTheWorkspace() async throws {
        let fake = FakeCentreRepository()
        let user = FakeAuthRepository.meera
        #expect(try await fake.workspace(for: user) == nil)
        let w = try await fake.createCentre(CentreDraft(displayName: "Meera Nair", centreName: "Bright Minds Tuition", whatsappNumber: "+919611299988"), for: user)
        #expect(w.centre.name == "Bright Minds Tuition" && w.profile.displayName == "Meera Nair" && w.centre.whatsappNumber == "+919611299988")
        #expect(try await fake.workspace(for: user) == w)
        try await fake.updateProfile(displayName: "Meera")
        #expect(try await fake.workspace(for: user)?.profile.displayName == "Meera")
    }

    @Test func aScriptedErrorFiresOnce() async {
        let fake = FakeCentreRepository()
        fake.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await fake.updateProfile(displayName: "x") }
        await #expect(throws: Never.self) { try await fake.updateProfile(displayName: "x") }
    }
}
```

- [ ] **Step 2: Implement**

`FakeCentreRepository.swift`: a `@MainActor final class` with the properties above; `createCentre` makes `Workspace(user:, centre: Centre(id: UUID(), name:, whatsappNumber:), profile: Profile(displayName:))`, stores it in `workspace`, appends the draft to `created`; the two updates mutate `workspace` and append to their lists; `nextError` is thrown once by whichever call comes first, as in the auth fake.

`SupabaseCentreRepository.swift`:

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseCentreRepository: CentreRepository {
    private let client: SupabaseClient
    public init(client: SupabaseClient) { self.client = client }

    private struct CentreRow: Decodable { let id: UUID; let name: String; let whatsapp_number: String? }
    private struct ProfileRow: Decodable { let display_name: String? }

    public func workspace(for user: AuthUser) async throws -> Workspace? {
        // centre_members is readable by its own user (members_self); the join reaches the centre through centres_member.
        let rows: [CentreRow] = try await client.from("centres").select("id, name, whatsapp_number").limit(1).execute().value
        guard let row = rows.first else { return nil }
        let profiles: [ProfileRow] = try await client.from("profiles").select("display_name").eq("user_id", value: user.id).execute().value
        return Workspace(user: user, centre: Centre(id: row.id, name: row.name, whatsappNumber: row.whatsapp_number),
                         profile: Profile(displayName: profiles.first?.display_name))
    }

    public func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace {
        let id: UUID = try await client.rpc("create_centre", params: [
            "p_name": draft.centreName, "p_whatsapp": draft.whatsappNumber, "p_display_name": draft.displayName,
        ]).execute().value
        return Workspace(user: user, centre: Centre(id: id, name: draft.centreName, whatsappNumber: draft.whatsappNumber),
                         profile: Profile(displayName: draft.displayName))
    }

    public func updateCentre(id: UUID, name: String, whatsappNumber: String?) async throws {
        try await client.from("centres").update(["name": name, "whatsapp_number": whatsappNumber]).eq("id", value: id).execute()
    }

    public func updateProfile(displayName: String) async throws {
        try await client.from("profiles").update(["display_name": displayName]).eq("user_id", value: try await client.auth.session.user.id).execute()
    }
}
```

(`params` with an optional value: use `[String: AnyJSON]` and `.null` for nil if the dictionary literal does not type-check; `rpc` decoding a bare uuid: if `.value` as `UUID` fails, decode `String` and `UUID(uuidString:)`. Both are found in the first run against the local stack, step 3.)

Run: `bun check --only=ios` → PASS.

- [ ] **Step 3: Against the local stack, by hand, once**

A one-off `#if DEBUG` call is not needed: Task 12's onboarding runs this path end to end in the simulator against local Supabase, and that is where it is proven. Commit: `git add ios && git commit -m "Data: the centre repository, Supabase and in-memory"`.

### Task 8: AppShell: dependencies, the session gate, launch-state fixtures, toasts (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/AppShell/Dependencies.swift`, `SessionStore.swift`, `Fixtures.swift`, `ToastCenter.swift`
- Modify: `ios/TutorCentralKit/Sources/AppShell/LaunchState.swift`, `RootView.swift`
- Test: `ios/TutorCentralKit/Tests/AppShellTests/SessionStoreTests.swift`, `ToastCenterTests.swift`, `LaunchStateTests.swift` (fixtures)

**Interfaces:**
- Produces:

```swift
public struct Dependencies: Sendable {
    public let auth: any AuthRepository
    public let centres: any CentreRepository
    public let counts: any CountsRepository          // Task 14 adds the protocol; until then this line is absent
    public let now: @Sendable () -> Date
    public let bundleVersion: String                 // "0.1 (12)"
}

@MainActor @Observable public final class SessionStore {
    public enum State: Equatable { case loading, signedOut, needsOnboarding(AuthUser), ready(Workspace) }
    public private(set) var state: State
    public init(deps: Dependencies, initial: State = .loading)
    public func start() async          // reads the keychain user, resolves the workspace, then follows auth changes
    public func signedIn(_ user: AuthUser) async   // called by the sign-in stores after a success: resolves the workspace
    public func centreCreated(_ workspace: Workspace)
    public func workspaceChanged(_ workspace: Workspace)   // Settings edits
    public func refresh() async        // foreground: re-reads the workspace when ready
    public func signOut() async
}

@MainActor @Observable public final class ToastCenter {
    public struct Toast: Equatable { public let message: String; public let action: (label: String, run: () -> Void)?; let id: UUID }
    public private(set) var current: Toast?
    public func show(_ message: String, action: (label: String, run: @MainActor () -> Void)? = nil, stay: Duration? = nil)
    public func dismiss()
}
```

  `LaunchState` gains `signin`, `signinEmail`, `signinCode`, `signinCodeWrong`, `signinPassword`, `onboarding`, `todayEmpty`, `laterStudents`, `laterFees`, `laterAttendance`, `laterMore`, `settings` (raw values kebab-case as in `information-architecture.md`); `Fixtures.dependencies(for: LaunchState) -> Dependencies` and `Fixtures.initialState(for:) -> SessionStore.State`; `Fixtures.now = 2026-10-07 18:30 Asia/Kolkata`.

- [ ] **Step 1: Failing tests**

`SessionStoreTests.swift`:

```swift
import Data
import Domain
import Testing
@testable import AppShell

@MainActor struct SessionStoreTests {
    func deps(auth: FakeAuthRepository, centres: FakeCentreRepository = FakeCentreRepository()) -> Dependencies {
        Dependencies(auth: auth, centres: centres, now: { Fixtures.now }, bundleVersion: "0.1 (1)")
    }

    @Test func startsLoadingThenSignedOutWhenTheKeychainIsEmpty() async {
        let store = SessionStore(deps: deps(auth: FakeAuthRepository()))
        #expect(store.state == .loading)
        await store.start()
        #expect(store.state == .signedOut)
    }

    @Test func aSignedInUserWithoutACentreGoesToOnboarding() async {
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera)))
        await store.start()
        #expect(store.state == .needsOnboarding(FakeAuthRepository.meera))
    }

    @Test func aSignedInUserWithACentreIsReady() async throws {
        let centres = FakeCentreRepository()
        let w = try await centres.createCentre(CentreDraft(displayName: "Meera Nair", centreName: "Bright Minds Tuition", whatsappNumber: nil), for: FakeAuthRepository.meera)
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera), centres: centres))
        await store.start()
        #expect(store.state == .ready(w))
    }

    @Test func signInThenCreateThenSignOutWalksTheThreeRoots() async throws {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        let store = SessionStore(deps: deps(auth: auth, centres: centres))
        await store.start()
        await store.signedIn(try await auth.signInWithGoogle())
        #expect(store.state == .needsOnboarding(FakeAuthRepository.meera))
        let w = try await centres.createCentre(CentreDraft(displayName: "M", centreName: "C", whatsappNumber: nil), for: FakeAuthRepository.meera)
        store.centreCreated(w)
        #expect(store.state == .ready(w))
        await store.signOut()
        #expect(store.state == .signedOut && auth.signedOut == 1)
    }

    @Test func aSignOutFromElsewhereIsFollowed() async throws {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = SessionStore(deps: deps(auth: auth))
        await store.start()
        auth.emit(nil)
        await Task.yield(); await Task.yield()
        #expect(store.state == .signedOut)
    }

    @Test func aWorkspaceLookupThatFailsKeepsTheUserSignedInAndReportsIt() async {
        let centres = FakeCentreRepository()
        centres.nextError = URLError(.notConnectedToInternet)
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera), centres: centres))
        await store.start()
        // Not onboarding: a tutor with a centre must never be asked to make a second one because the network blinked.
        #expect(store.state == .loading && store.lastError != nil)
    }
}
```

The last test is the honest behaviour of the gate: when the lookup fails the store stays `.loading` with `lastError` set, and the root shows the skeleton, the footnote line and Retry (`guidelines.md`, "States every screen has"), never onboarding.

`ToastCenterTests.swift`:

```swift
import Testing
@testable import AppShell

@MainActor struct ToastCenterTests {
    @Test func oneAtATimeTheNewerWins() {
        let t = ToastCenter()
        t.show("first"); t.show("second")
        #expect(t.current?.message == "second")
        t.dismiss()
        #expect(t.current == nil)
    }

    @Test func aToastWithUndoStaysLonger() {
        #expect(ToastCenter.stay(hasAction: false) == .seconds(Tokens.toastStay))
        #expect(ToastCenter.stay(hasAction: true) == .seconds(Tokens.toastStayUndo))
    }
}
```

`LaunchStateTests.swift`, append:

```swift
    @Test func everyBoardStateHasAFixture() {
        for s in LaunchState.allCases where s != .placeholder {
            _ = Fixtures.dependencies(for: s)
            _ = Fixtures.initialState(for: s)
        }
        #expect(Fixtures.initialState(for: .signin) == .signedOut)
        #expect(Fixtures.initialState(for: .onboarding) == .needsOnboarding(FakeAuthRepository.meera))
        if case .ready = Fixtures.initialState(for: .todayEmpty) {} else { Issue.record("today-empty starts ready") }
    }
```

Run: `bun check --only=ios` → FAIL to compile.

- [ ] **Step 2: Implement**

`Dependencies.swift`:

```swift
import Data
import Domain
import Foundation
import SwiftUI

/// Everything a store needs, given through the environment; previews and `bun shots` give fakes (Fixtures).
public struct Dependencies: Sendable {
    public let auth: any AuthRepository
    public let centres: any CentreRepository
    public let now: @Sendable () -> Date
    public let bundleVersion: String

    public init(auth: any AuthRepository, centres: any CentreRepository, now: @escaping @Sendable () -> Date, bundleVersion: String) { ... }

    /// The real thing, from Info.plist (SupabaseConfig) and the bundle's version strings.
    public static func live() throws -> Dependencies {
        let client = SupabaseClientFactory.make(try SupabaseConfig.fromMainBundle())
        let info = Bundle.main.infoDictionary ?? [:]
        let version = "\(info["CFBundleShortVersionString"] ?? "0") (\(info["CFBundleVersion"] ?? "0"))"
        return Dependencies(auth: SupabaseAuthRepository(client: client), centres: SupabaseCentreRepository(client: client), now: { Date() }, bundleVersion: version)
    }
}

private struct DependenciesKey: EnvironmentKey { static let defaultValue: Dependencies? = nil }
public extension EnvironmentValues {
    var dependencies: Dependencies? { get { self[DependenciesKey.self] } set { self[DependenciesKey.self] = newValue } }
}
```

`SessionStore.swift`:

```swift
import Data
import Domain
import Foundation
import Observation

/// The session gate (information-architecture.md "Entry"): the one thing that decides which root shows.
@MainActor @Observable public final class SessionStore {
    public enum State: Equatable { case loading, signedOut, needsOnboarding(AuthUser), ready(Workspace) }

    public private(set) var state: State
    /// Set when the workspace could not be read; the root shows a footnote line and Retry (refresh()).
    public private(set) var lastError: String?
    private let deps: Dependencies
    private var following: Task<Void, Never>?

    public init(deps: Dependencies, initial: State = .loading) { self.deps = deps; state = initial }

    public func start() async {
        if let user = await deps.auth.currentUser() { await resolve(user) } else { state = .signedOut }
        following = Task { [weak self] in
            guard let self else { return }
            for await user in deps.auth.changes() {
                if let user { if case .signedOut = state { await resolve(user) } } else { state = .signedOut }
            }
        }
    }

    public func signedIn(_ user: AuthUser) async { await resolve(user) }

    public func centreCreated(_ workspace: Workspace) { state = .ready(workspace) }
    public func workspaceChanged(_ workspace: Workspace) { state = .ready(workspace) }

    public func refresh() async {
        switch state {
        case let .ready(w): await resolve(w.user)
        case .loading: if let user = await deps.auth.currentUser() { await resolve(user) }
        default: break
        }
    }

    public func signOut() async { await deps.auth.signOut(); state = .signedOut }

    private func resolve(_ user: AuthUser) async {
        do {
            lastError = nil
            if let w = try await deps.centres.workspace(for: user) { state = .ready(w) } else { state = .needsOnboarding(user) }
        } catch {
            lastError = "Couldn't load your centre. Check your connection and try again."
            if case .ready = state {} else { state = .loading }
        }
    }
}
```

`ToastCenter.swift`: as the interface says; `show` cancels the previous dismiss task, sets `current`, starts `Task { try await Task.sleep(for: stay ?? Self.stay(hasAction: action != nil)); dismiss() }`; `static func stay(hasAction: Bool) -> Duration`. The view that draws it (`ToastHost`, Task 13) sits at the bottom of the root above the tab bar.

`LaunchState.swift`: the cases listed in Interfaces. `Fixtures.swift`:

```swift
import Data
import Domain
import Foundation

/// What `bun shots <state>` launches: the fakes, filled with the boards' data, and a fixed clock, so every picture
/// is the same every time and matches its board.
public enum Fixtures {
    public static let now: Date = {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = 7; c.hour = 18; c.minute = 30
        c.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return Calendar(identifier: .gregorian).date(from: c)!  // swiftlint:disable:this force_unwrapping
    }()

    @MainActor public static func dependencies(for state: LaunchState) -> Dependencies {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        switch state {
        case .signin, .signinEmail, .signinCode, .signinCodeWrong, .signinPassword, .placeholder, .kit, .kitSurfaces: break
        case .onboarding: auth.user = FakeAuthRepository.meera
        case .todayEmpty, .laterStudents, .laterFees, .laterAttendance, .laterMore, .settings:
            auth.user = FakeAuthRepository.meera
            centres.workspace = meeraWorkspace
        }
        return Dependencies(auth: auth, centres: centres, now: { now }, bundleVersion: "0.1 (12)")
    }

    public static let meeraWorkspace = Workspace(
        user: FakeAuthRepository.meera,
        centre: Centre(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, name: "Bright Minds Tuition", whatsappNumber: "+919611299988"),  // swiftlint:disable:this force_unwrapping
        profile: Profile(displayName: "Meera Nair")
    )

    public static func initialState(for state: LaunchState) -> SessionStore.State {
        switch state {
        case .onboarding: .needsOnboarding(FakeAuthRepository.meera)
        case .todayEmpty, .laterStudents, .laterFees, .laterAttendance, .laterMore, .settings: .ready(meeraWorkspace)
        default: .signedOut
        }
    }
}
```

`RootView.swift` becomes the gate:

```swift
import Data
import DesignSystem
import Domain
import Onboarding
import SwiftUI

public struct RootView: View {
    @AppStorage(Appearance.storageKey) private var storedAppearance: String?
    @State private var session: SessionStore
    @State private var toasts = ToastCenter()
    private let deps: Dependencies
    private let launch: LaunchState?

    public init() {
        let launch = LaunchState.fromArguments()
        if let launch, launch != .placeholder {
            let deps = Fixtures.dependencies(for: launch)
            self.deps = deps
            _session = State(initialValue: SessionStore(deps: deps, initial: Fixtures.initialState(for: launch)))
        } else {
            let deps = (try? Dependencies.live()) ?? Fixtures.dependencies(for: .signin)  // a build without Supabase values still opens, to sign-in
            self.deps = deps
            _session = State(initialValue: SessionStore(deps: deps))
        }
        self.launch = launch
    }

    public var body: some View {
        Group {
            #if DEBUG
            if launch == .kit { KitView() } else if launch == .kitSurfaces { KitView(startAt: .surfaces) } else { gate }
            #else
            gate
            #endif
        }
        .environment(\.dependencies, deps)
        .environment(session)
        .environment(toasts)
        .preferredColorScheme(Appearance.resolve(arguments: ProcessInfo.processInfo.arguments, stored: storedAppearance).colorScheme)
        .task { if launch == nil { await session.start() } }
    }

    @ViewBuilder private var gate: some View {
        switch session.state {
        case .loading: LoadingRoot(error: session.lastError) { Task { await session.refresh() } }
        case .signedOut: SignInView(launch: launch)          // Task 9; until then: Text("Sign in arrives in Task 9") placeholder for one commit
        case let .needsOnboarding(user): OnboardingView(user: user)   // Task 12
        case let .ready(w): TabsView(workspace: w)            // Task 13
        }
    }
}
```

`LoadingRoot`: `ground` with a `SkeletonRow` column, and when `error` is set, the footnote line in `text2` and a Retry quiet button (the "error" state of `guidelines.md`, no board needed: it is the Kit's error pattern on an empty ground). Until Tasks 9, 12 and 13 land, the three roots are one-line placeholders in this file; each task replaces its line.

Run: `bun check --only=ios` → PASS. Commit: `git add ios && git commit -m "AppShell: dependencies, the session gate, launch-state fixtures, toasts"`.

### Task 9: Sign in with Apple and Google: the landing (PR 5)

**Files:**
- Create: `ios/App/TutorCentral.entitlements`; modify `ios/App/Info.plist` (URL type), `ios/project.yml` (entitlements)
- Create: `ios/TutorCentralKit/Sources/Features/Onboarding/SignIn/SignInStore.swift`, `SignInView.swift`, `GoogleMark.swift`
- Create: `ios/TutorCentralKit/Sources/AppShell/Legal.swift`
- Modify: `ios/TutorCentralKit/Package.swift` (`OnboardingTests` target; `Onboarding` depends on `Domain`, `Data`, `DesignSystem` as it already does), `ios/project.yml` (scheme)
- Test: `ios/TutorCentralKit/Tests/OnboardingTests/SignInStoreTests.swift`

**Interfaces:**
- Produces: `SignInStore` (`@MainActor @Observable`): `busy: Provider?` (`.apple`, `.google`), `message: String?` (the toast line), `nonce: String` (fresh per Apple attempt), `func startApple() -> String` (returns the SHA-256 for the request), `func finishApple(result: Result<ASAuthorization, any Error>) async -> AuthUser?`, `func continueWithGoogle() async -> AuthUser?`; `SignInView(launch: LaunchState?)` takes `onSignedIn: (AuthUser) async -> Void` from AppShell's gate (the root passes `session.signedIn`); `Legal.terms`, `Legal.privacy`.

- [ ] **Step 1: Owner steps, one at a time, each checked before the next**

Give these one at a time; check the result of each (`gh`/dashboard where possible, else the owner's word) before the next.

1. **App Store Connect app record.** developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → "+" → App IDs → App; description "Tutor Central"; Bundle ID explicit `app.journium.tutorcentral`; Capabilities: tick **Sign in with Apple** (leave "Enable as a primary App ID"); Register. Then App Store Connect → My Apps → "+" → New App: iOS, name "Tutor Central", primary language English (India) if offered else English (U.K.), bundle id the one just made, SKU `tutorcentral`. Check: the app appears in My Apps. Ask for the **Team ID** (Membership details); it becomes the repository variable `APPLE_TEAM_ID` in Task 16, written down now in `STATE.md`'s open items by the build session.
2. **Supabase, Apple provider.** supabase.com/dashboard → project `esowihbxawvoexflekxa` → Authentication → Providers → Apple: enable; **Client IDs** `app.journium.tutorcentral` (the bundle id; the native id-token flow needs nothing else, no Services ID and no secret key); Save. Check: the provider shows enabled.
3. **Google Cloud, web OAuth client.** console.cloud.google.com → a project (any; "Tutor Central" if new) → APIs & Services → OAuth consent screen: External, app name Tutor Central, support and developer emails the owner's, no scopes beyond the defaults, publish (or add the owner as a test user while in Testing). Then Credentials → Create credentials → OAuth client ID → **Web application**, name "Tutor Central (Supabase)", **Authorised redirect URI** `https://esowihbxawvoexflekxa.supabase.co/auth/v1/callback`; Create. Copy the client id and secret.
4. **Supabase, Google provider.** Authentication → Providers → Google: enable, paste the client id and secret, Save. Then Authentication → URL Configuration → **Redirect URLs** → add `tutorcentral://auth-callback`. Check: both saved.
5. **Supabase, email code.** Authentication → Providers → Email: enabled, "Confirm email" on, **OTP expiry 600**, OTP length 6. Authentication → Emails (templates) → **Magic Link**: subject "Your Tutor Central code", body replaced with plain text that carries `{{ .Token }}` ("Your six-digit code is {{ .Token }}. It works for 10 minutes. If you did not ask for it, ignore this email."). The same for the **Confirm signup** template, since a first sign-in with a new address uses it. Check: a test send from the dashboard, or the first real code in step 6 of Task 10.
6. **The two legal URLs.** Ask where the terms and the privacy policy live; if they do not exist yet, the owner says what to use for now (a page he will fill). Write both into `Legal.swift`.

- [ ] **Step 2: Entitlement and URL scheme**

`ios/App/TutorCentral.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.applesignin</key><array><string>Default</string></array>
</dict>
</plist>
```

`project.yml`, target `TutorCentral` → `settings.base`: `CODE_SIGN_ENTITLEMENTS: App/TutorCentral.entitlements`. `Info.plist`, before `SUPABASE_URL`:

```xml
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLName</key><string>app.journium.tutorcentral</string>
    <key>CFBundleURLSchemes</key><array><string>tutorcentral</string></array>
  </dict></array>
```

`bun gen && bun check --only=ios` → still green (the simulator build is unsigned since Task 3).

- [ ] **Step 3: Failing store tests**

`Tests/OnboardingTests/SignInStoreTests.swift`:

```swift
import AuthenticationServices
import Data
import Domain
import Testing
@testable import Onboarding

@MainActor struct SignInStoreTests {
    @Test func googleSucceedsAndReportsTheUser() async {
        let auth = FakeAuthRepository()
        let store = SignInStore(auth: auth)
        let user = await store.continueWithGoogle()
        #expect(user == FakeAuthRepository.meera && store.busy == nil && store.message == nil)
    }

    @Test func aCancelledSheetLeavesNoMessageAndNothingBusy() async {
        let auth = FakeAuthRepository()
        auth.nextFailure = .cancelled
        let store = SignInStore(auth: auth)
        #expect(await store.continueWithGoogle() == nil)
        #expect(store.busy == nil && store.message == nil)
    }

    @Test func failuresBecomeWords() async {
        for (failure, words) in [
            (SignInFailure.offline, "You're offline. Connect and try again."),
            (.providerRefused, "Google didn't complete the sign-in. Try again, or use your email."),
            (.other("boom"), "Couldn't sign in. boom"),
        ] {
            let auth = FakeAuthRepository(); auth.nextFailure = failure
            let store = SignInStore(auth: auth)
            _ = await store.continueWithGoogle()
            #expect(store.message == words)
        }
    }

    @Test func appleGetsAFreshNonceAndItsHashEachTime() {
        let store = SignInStore(auth: FakeAuthRepository())
        let h1 = store.startApple(), n1 = store.nonce
        let h2 = store.startApple(), n2 = store.nonce
        #expect(n1 != n2 && h1 == Nonce.sha256(n1) && h2 == Nonce.sha256(n2))
    }

    @Test func appleFailureWithTheProvidersCodeIsItsOwnLine() async {
        let auth = FakeAuthRepository()
        let store = SignInStore(auth: auth)
        _ = store.startApple()
        let user = await store.finishApple(result: .failure(ASAuthorizationError(.failed)))
        #expect(user == nil && store.message == "Apple didn't complete the sign-in. Try again, or use your email.")
    }
}
```

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 4: The store**

```swift
import AuthenticationServices
import Data
import Domain
import Foundation
import Observation

/// The landing's two system sign-ins. Email has its own store (EmailSignInStore).
@MainActor @Observable public final class SignInStore {
    public enum Provider: Sendable { case apple, google }

    public private(set) var busy: Provider?
    /// One line for the toast; nil when nothing is wrong or the tutor cancelled.
    public var message: String?
    public private(set) var nonce = ""
    private let auth: any AuthRepository

    public init(auth: any AuthRepository) { self.auth = auth }

    /// A new nonce for this attempt; the request carries its SHA-256.
    public func startApple() -> String {
        nonce = Nonce.random()
        return Nonce.sha256(nonce)
    }

    public func finishApple(result: Result<ASAuthorization, any Error>) async -> AuthUser? {
        await attempt(.apple) {
            let credential: ASAuthorizationAppleIDCredential
            switch result {
            case let .success(authorization):
                guard let c = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let data = c.identityToken, let token = String(data: data, encoding: .utf8) else { throw SignInFailure.providerRefused }
                credential = c
                let name = [c.fullName?.givenName, c.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                return try await auth.signInWithApple(idToken: token, nonce: nonce, fullName: name.isEmpty ? nil : name)
            case let .failure(error): throw error
            }
        }
    }

    public func continueWithGoogle() async -> AuthUser? {
        await attempt(.google) { try await auth.signInWithGoogle() }
    }

    private func attempt(_ provider: Provider, _ body: () async throws -> AuthUser) async -> AuthUser? {
        guard busy == nil else { return nil }
        busy = provider; message = nil
        defer { busy = nil }
        do { return try await body() } catch {
            message = Self.words(for: SignInFailure(error), provider: provider)
            return nil
        }
    }

    static func words(for failure: SignInFailure, provider: Provider) -> String? {
        let name = provider == .apple ? "Apple" : "Google"
        switch failure {
        case .cancelled: return nil
        case .offline: return "You're offline. Connect and try again."
        case .providerRefused: return "\(name) didn't complete the sign-in. Try again, or use your email."
        case .tooManyRequests: return "Too many tries. Wait a minute and try again."
        case let .other(m): return "Couldn't sign in. \(m)"
        case .wrongCode, .codeExpired, .wrongPassword: return "Couldn't sign in. Try again, or use your email."
        }
    }
}
```

(The `credential` constant above is unused once the name is read inline; drop it when writing. SwiftLint will say so.)

Run: `bun check --only=ios` → PASS.

- [ ] **Step 5: The landing view, to `A-SignIn` (dark) and `P2-SignIn-Light`**

`SignInView.swift`: `ground` with `HeroGlow()`; padding `heroTop` top, `heroInset` sides, 54 bottom (the board; use the safe area plus `heroTop − heroInset − 2`? No: the board's 54 is the home indicator area, use `.safeAreaInset` and `pageSide` 20 above it, which lands the legal line where the board has it). Content, top to bottom:

- Logo row: a 56 × 56 tile, `accent` fill, radius `radiusTile`, `shadowPrimary`, with the book-and-spark mark drawn as an SF Symbol `book.closed.fill` in `textOnAccent` at 30 pt (the board's stroke mark is a stand-in; the app icon's mark comes with its Phase 0 board); then "Tutor Central" in `headline`.
- 72 pt below: "Teach more.\nChase less." in `displayHero`, then "Students, fees and attendance for your tuition centre, handled in a tap." in `body` at 18 / 26 (the board's lead paragraph is 18 pt: add `lead` 18 / 26 / 400 to the type table and `Tokens+Type.swift` in this task, the board wins) in `text2`, max width 320.
- `Spacer`.
- Three buttons at `.sheet` height 52, `tileGap` apart:
  - `SignInWithAppleButton(.continue) { request in request.requestedScopes = [.fullName, .email]; request.nonce = store.startApple() } onCompletion: { result in Task { if let user = await store.finishApple(result: result) { await onSignedIn(user) } } }` with `.signInWithAppleButtonStyle(scheme == .dark ? .white : .black)`, `.frame(height: 52)`, `.clipShape(.rect(cornerRadius: Tokens.radiusControl, style: .continuous))`, disabled while `busy != nil`.
  - "Continue with Google": `Button { Task { if let u = await store.continueWithGoogle() { await onSignedIn(u) } } } label: { Label { Text("Continue with Google") } icon: { GoogleMark() } }.buttonStyle(.secondary(.sheet, loading: store.busy == .google))`. `GoogleMark`: a 20 pt ring, 2 pt `text2` stroke, with "G" in 12 pt 800 `text2` (the board's stand-in; no Google asset is shipped).
  - "Continue with email": secondary with `envelope` 20 pt, opens the email sheet (Task 10).
- 14 pt below: "By continuing you agree to the terms and privacy policy." in `caption` `text3`, centred, "terms" and "privacy policy" as links (`Text` with markdown links styled `text2` 600, opening `Legal.terms` and `Legal.privacy` with `.environment(\.openURL)`; the system browser).
- The toast: `store.message` is shown through `ToastCenter` (`onChange(of: store.message) { if let m { toasts.show(m) } }`), bottom, above nothing (no tab bar here).

`AppShell/Legal.swift`: `public enum Legal { public static let terms = URL(string: "<from the owner, step 1.6>")!; public static let privacy = URL(string: "<…>")! }`, with `// swiftlint:disable:this force_unwrapping` on literals.

Busy: while `busy != nil` all three buttons are disabled; the one in flight shows the loading spinner (Google) or stays as Apple draws it (the system sheet is modal).

The gate's `.signedOut` line in `RootView` becomes `SignInView(launch: launch, onSignedIn: session.signedIn)`.

- [ ] **Step 6: Build, photograph, compare, commit**

```bash
bun check && bun shots signin
```

Compare `signin-dark.png` with `A-SignIn` (row 1, board 3) and `signin-light.png` with `P2-SignIn-Light`. The Apple button's colour follows the appearance; the glow sits top right; the legal line is centred. Commit: `git add ios docs && git commit -m "Sign in: the landing with Apple and Google, to its boards"`.

Try it for real: in the simulator (an Apple ID signed in under Settings), launch without `--state`, tap Continue with Apple, complete the sheet: the app must land on the onboarding placeholder (Task 12's screen once it exists). Then Google: the web session opens, the Google account picker shows, the callback returns. If Google says the redirect is wrong, the URL in owner step 3 or 4 is the fault. Record what was run in the PR body.

### Task 10: Sign in with an email code, and with a password (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Onboarding/SignIn/EmailSignInStore.swift`, `EmailSignInSheet.swift`, `CodeEntryView.swift`, `PasswordEntryView.swift`
- Modify: `SignInView.swift` (presents the sheet), `AppShell/LaunchState.swift`, `Fixtures.swift` (the four email states), `docs/design/information-architecture.md` (`signin-password`)
- Test: `ios/TutorCentralKit/Tests/OnboardingTests/EmailSignInStoreTests.swift`

**Interfaces:**
- Produces: `EmailSignInStore` (`@MainActor @Observable`): `step: Step` (`.request`, `.code`, `.password`), `email: String`, `emailError: String?`, `code: String`, `codeError: String?`, `password: String`, `passwordError: String?`, `busy: Bool`, `resendAvailableIn: Int` (seconds, 0 when the quiet Resend shows), `sentTo: EmailAddress?`; `func requestCode() async`, `func verify() async -> AuthUser?`, `func resend() async`, `func usePassword()`, `func useCode()`, `func signInWithPassword() async -> AuthUser?`, `func tick()` (the countdown, driven by a timer in the view, injectable `now`).

- [ ] **Step 1: Failing store tests**

```swift
import Data
import Domain
import Testing
@testable import Onboarding

@MainActor struct EmailSignInStoreTests {
    func make(_ auth: FakeAuthRepository = FakeAuthRepository()) -> EmailSignInStore { EmailSignInStore(auth: auth, cooldown: 60) }

    @Test func aBadAddressIsRefusedInWordsBeforeAnyRequest() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "meera@"
        await store.requestCode()
        #expect(store.emailError == "Enter a full email address, like name@example.com." && auth.requested.isEmpty && store.step == .request)
    }

    @Test func aGoodAddressRequestsACodeAndMovesToCodeEntryWithTheCooldownRunning() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = " Meera.Nair@gmail.com "
        await store.requestCode()
        #expect(auth.requested.map(\.string) == ["meera.nair@gmail.com"])
        #expect(store.step == .code && store.sentTo?.string == "meera.nair@gmail.com" && store.resendAvailableIn == 60)
        for _ in 0..<36 { store.tick() }
        #expect(store.resendAvailableIn == 24)
        for _ in 0..<30 { store.tick() }
        #expect(store.resendAvailableIn == 0)
    }

    @Test func sixDigitsVerifyAndReturnTheUser() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"; await store.requestCode()
        store.code = "481234"
        let user = await store.verify()
        #expect(user?.email == "a@b.co" && auth.verified.last?.1 == "481234")
    }

    @Test func fewerThanSixDigitsNeverCallsVerify() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"; await store.requestCode()
        store.code = "48123"
        #expect(await store.verify() == nil && auth.verified.isEmpty)
    }

    @Test func wrongAndExpiredCodesHaveTheirOwnLinesAndClearTheDigits() async {
        for (failure, words) in [
            (SignInFailure.wrongCode, "That code isn't right. Check the email or ask for a new one."),
            (.codeExpired, "That code has expired. Ask for a new one."),
            (.tooManyRequests, "Too many tries. Wait a minute and try again."),
            (.offline, "You're offline. Connect and try again."),
        ] {
            let auth = FakeAuthRepository()
            let store = make(auth)
            store.email = "a@b.co"; await store.requestCode()
            auth.nextFailure = failure
            store.code = "000000"
            #expect(await store.verify() == nil)
            #expect(store.codeError == words && store.code.isEmpty && store.step == .code)
        }
    }

    @Test func resendOnlyAfterTheCooldownAndItRestartsIt() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"; await store.requestCode()
        await store.resend()
        #expect(auth.requested.count == 1)
        for _ in 0..<60 { store.tick() }
        await store.resend()
        #expect(auth.requested.count == 2 && store.resendAvailableIn == 60 && store.codeError == nil)
    }

    @Test func theRateLimitOnRequestIsSaidUnderTheEmailField() async {
        let auth = FakeAuthRepository(); auth.nextFailure = .tooManyRequests
        let store = make(auth)
        store.email = "a@b.co"; await store.requestCode()
        #expect(store.step == .request && store.emailError == "Too many codes asked for. Wait a minute and try again.")
    }

    @Test func passwordPathValidatesAndMapsAWrongPassword() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.usePassword()
        #expect(store.step == .password)
        store.email = "a@b.co"; store.password = ""
        #expect(await store.signInWithPassword() == nil && store.passwordError == "Enter your password.")
        auth.nextFailure = .wrongPassword
        store.password = "nope"
        #expect(await store.signInWithPassword() == nil)
        #expect(store.passwordError == "That password isn't right. If you never set one, sign in with a code instead.")
        store.password = "right"
        #expect(await store.signInWithPassword()?.email == "a@b.co")
    }
}
```

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: The store**

```swift
import Data
import Domain
import Foundation
import Observation

/// Request a code, enter it, resend after a cooldown; or a password for an account that has one.
@MainActor @Observable public final class EmailSignInStore {
    public enum Step: Equatable { case request, code, password }

    public private(set) var step: Step = .request
    public var email = ""
    public private(set) var emailError: String?
    public var code = "" { didSet { if code != oldValue { codeError = nil } } }
    public private(set) var codeError: String?
    public var password = ""
    public private(set) var passwordError: String?
    public private(set) var busy = false
    public private(set) var resendAvailableIn = 0
    public private(set) var sentTo: EmailAddress?

    public static let codeLength = 6
    private let auth: any AuthRepository
    private let cooldown: Int

    public init(auth: any AuthRepository, cooldown: Int = 60) { self.auth = auth; self.cooldown = cooldown }

    public func requestCode() async {
        guard let address = EmailAddress(email) else { emailError = "Enter a full email address, like name@example.com."; return }
        emailError = nil
        await run {
            try await auth.requestCode(email: address)
            sentTo = address; code = ""; codeError = nil; step = .code; resendAvailableIn = cooldown
        } onFailure: { emailError = Self.requestWords($0) }
    }

    public func verify() async -> AuthUser? {
        guard let sentTo, code.count == Self.codeLength else { return nil }
        var user: AuthUser?
        await run { user = try await auth.verifyCode(email: sentTo, code: code) } onFailure: { codeError = Self.codeWords($0); code = "" }
        return user
    }

    public func resend() async {
        guard let sentTo, resendAvailableIn == 0 else { return }
        await run {
            try await auth.requestCode(email: sentTo)
            code = ""; codeError = nil; resendAvailableIn = cooldown
        } onFailure: { codeError = Self.requestWords($0) }
    }

    /// Once a second from the code view's timer.
    public func tick() { if resendAvailableIn > 0 { resendAvailableIn -= 1 } }

    public func usePassword() { step = .password; passwordError = nil }
    public func useCode() { step = .request; emailError = nil }

    public func signInWithPassword() async -> AuthUser? {
        guard let address = EmailAddress(email) else { emailError = "Enter a full email address, like name@example.com."; return nil }
        emailError = nil
        guard !password.isEmpty else { passwordError = "Enter your password."; return nil }
        var user: AuthUser?
        await run { user = try await auth.signIn(email: address, password: password) } onFailure: { passwordError = Self.passwordWords($0) }
        return user
    }

    private func run(_ body: () async throws -> Void, onFailure: (SignInFailure) -> Void) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do { try await body() } catch { onFailure(SignInFailure(error)) }
    }

    static func requestWords(_ f: SignInFailure) -> String {
        switch f {
        case .tooManyRequests: "Too many codes asked for. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(m): "Couldn't send the code. \(m)"
        default: "Couldn't send the code. Try again."
        }
    }
    static func codeWords(_ f: SignInFailure) -> String {
        switch f {
        case .wrongCode: "That code isn't right. Check the email or ask for a new one."
        case .codeExpired: "That code has expired. Ask for a new one."
        case .tooManyRequests: "Too many tries. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(m): "Couldn't sign in. \(m)"
        default: "Couldn't sign in. Try again."
        }
    }
    static func passwordWords(_ f: SignInFailure) -> String {
        switch f {
        case .wrongPassword: "That password isn't right. If you never set one, sign in with a code instead."
        case .tooManyRequests: "Too many tries. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(m): "Couldn't sign in. \(m)"
        default: "Couldn't sign in. Try again."
        }
    }
}
```

Run: `bun check --only=ios` → PASS.

- [ ] **Step 3: The email sheet, to `P2-Email-Request`**

`EmailSignInSheet.swift`: presented from the landing with `.sheet` at detents `[.medium, .large]` (`presentationDetents`), `presentationDragIndicator(.visible)`, background `surface1`, corner radius `radiusSheet` (`presentationCornerRadius`), the landing dimmed behind it by the system. Inside: a bar with "Cancel" (quiet, left) and "Sign in with email" (`headline`, centre); "We'll email you a six-digit code. No password to remember." in `subhead` `text2`; `TextWell(label: "Email address", text: $store.email, keyboard: .emailAddress, content: .emailAddress, autocapitalisation: .never, error: store.emailError, onCommit: { Task { await store.requestCode() } })`, focused on appear; "Email me a code" primary `.sheet` with `envelope`, loading while busy; "Use my password instead" quiet, 44 high. Gaps `sectionGap`, side `pageSide`, bottom the safe area plus 16.

When `store.step` becomes `.code` the sheet's content switches to `CodeEntryView` by a `NavigationStack` push inside the sheet (so the back chevron of the code board works and the sheet grows to `.large`); `.password` pushes `PasswordEntryView`.

- [ ] **Step 4: Code entry, to `P2-Email-Code` and its wrong-code state**

`CodeEntryView.swift`, full screen inside the sheet's stack (`.large` detent): nav row with an `IconButton(symbol: "chevron.left", label: "Back")` and "Enter your code" `headline` centred; "Check your email" `title1`; "We sent a six-digit code to **meera.nair@gmail.com**. It works for 10 minutes." (`subhead` `text2`, the address in `text` 600); `CodeField(code: $store.code, isWrong: store.codeError != nil)`; "The code fills in by itself from the email on this phone." `footnote` `text3`; when `codeError` is set, the error line with `exclamationmark.circle` in `footnote` `overdue` replaces that helper; "Sign in" primary `.sheet`, disabled until six digits, loading while busy; the resend line, centred, `subhead`: "Didn't get it?" in `text2` then either "Resend in 0:24" in `text3` monospaced (while `resendAvailableIn > 0`, formatted `m:ss`) or the quiet button "Resend the code". Gaps 24 (`sectionGap` + `fieldGap`): add nothing new, use `sectionGap` and accept 18 (the board's 24 is between groups; `sectionGap` is the token, D10).

Six digits typed → `verify()` at once (`onChange(of: store.code)` when `count == 6`); the button does the same for VoiceOver and paste. The countdown: `.task { while !Task.isCancelled { try? await Task.sleep(for: .seconds(1)); store.tick() } }`.

On success the sheet closes and the root's `onSignedIn(user)` runs.

- [ ] **Step 5: Launch states and fixtures**

`LaunchState`: `signinEmail = "signin-email"`, `signinCode = "signin-code"`, `signinCodeWrong = "signin-code-wrong"`, `signinPassword = "signin-password"`. `SignInView(launch:)` reads it: `.signinEmail` opens the sheet on appear with `email = "meera.nair@gmail.com"` and the field focused; `.signinCode` opens it at `.code` with `sentTo` meera, `code = "481"`, `resendAvailableIn = 24`; `.signinCodeWrong` the same with `codeError` set to the wrong-code line and `resendAvailableIn = 0`; `.signinPassword` at `.password`. `EmailSignInStore` gets a `static func fixture(_ state: LaunchState, auth:) -> EmailSignInStore` for these, in the feature, `#if DEBUG`-free (it is harmless in Release and keeps one code path).

- [ ] **Step 6: Build, photograph, compare; a real code against the local stack**

```bash
bun check && for s in signin-email signin-code signin-code-wrong; do bun shots $s; done
```

Compare with the two email boards (the wrong-code state is the lower card on `P2-Email-Code`). Then with `Local.xcconfig` at the local stack, launch without `--state`, Continue with email, type any address, open Mailpit (http://127.0.0.1:54324), copy the six digits, see the app land on onboarding's placeholder. Type a wrong code first: the line must be the wrong-code one (Task 6 step 3 pinned which Supabase code that is). Commit: `git add ios docs && git commit -m "Sign in with an email code, to its boards"`.

- [ ] **Step 7: Password entry, to `P2-Email-Password`**

The board (`docs/design/mockups/P2-Email-Password.dc.html`, canvas row 5) is the Email sheet's family: the bar with "Cancel" (quiet) and "Sign in with password" (`headline`); the line "For an account that set a password in Settings. Otherwise a code is quicker." in `subhead` `text2`; `TextWell(label: "Email address", keyboard: .emailAddress, content: .username, autocapitalisation: .never)` carrying the address typed on the request step; `SecureWell(label: "Password", content: .password)` focused on appear; "Sign in" primary `.sheet`, loading while busy; "Email me a code instead" quiet, 44 high, which calls `useCode()` and pops back. Errors: `emailError` under the email well; `passwordError` under the password well with the `overdue` border and the `exclamationmark.circle` footnote line (the board's upper card shows this state: "That password isn't right. If you never set one, sign in with a code instead."). `PasswordEntryView.swift` builds it, pushed in the sheet's stack from `usePassword()`. The `signin-password` fixture opens the sheet at `.password` with the email filled and the password field focused. `bun shots signin-password`, compare, commit: `git add ios docs && git commit -m "Sign in with a password, to its board"`.

- [ ] **Step 8: The pull request for sign-in**

`bun check`; `bun pr-shots phase-2-sign-in .shots/signin/*.png .shots/signin-email/*.png .shots/signin-code/*.png .shots/signin-code-wrong/*.png .shots/signin-password/*.png`; `gh pr create --title "Sign in with Apple, Google, an email code and a password; the session gate" --body-file -` with: what was built (Tasks 5 to 10), the pictures table, what was run by hand (Apple and Google against the hosted project on the simulator, the email code against the local stack, a wrong code, an expired code if one was waited for), the owner steps done, and the words every failure shows. Merge when green and the pictures render.

### Task 10b: Migrations through `deploy.yml` (PR 5b, D26)

Added in session 4 at the owner's request; the owner chose the design (D26).

**Files:**
- Modify: `.github/workflows/deploy.yml` (a `migrate` job before the API deploy), `supabase/CLAUDE.md` (hosted: no hand pushes; additive rule)
- Later, in Task 16: `.github/workflows/testflight.yml` fails when `supabase db push --dry-run` against the hosted project lists anything pending

- [ ] **Step 1: Owner steps (one at a time, each checked):** a Supabase personal access token (Account → Access tokens), named for the lane; a GitHub environment `production` holding `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` (the project's database password; reset it in the dashboard if unknown). `deploy.yml`'s jobs run in that environment.
- [ ] **Step 2: The job.** `migrate`: checkout; `supabase/setup-cli` pinned to a SHA with the CLI version pinned exactly; `supabase link --project-ref esowihbxawvoexflekxa` (password from the environment); `supabase db push --dry-run` into `$GITHUB_STEP_SUMMARY`; `supabase db push`; then the dry-run again must list nothing pending. The API job `needs: migrate`. Test the parts that have logic (any summary formatting) with `bun test`; the workflow itself is proven by its first run.
- [ ] **Step 3: First run.** After merge, `gh workflow run deploy`: the summary shows `20261008000002_create_centre_name.sql` pending then applied; the API smoke passes; from outside, the anon key is refused on `create_centre` (as session 2 checked 0001). Record in `STATE.md`.

### Task 11: Domain: the phone number; the onboarding store (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/PhoneNumber.swift`, `ios/TutorCentralKit/Sources/Features/Onboarding/OnboardingStore.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/PhoneNumberTests.swift`, `ios/TutorCentralKit/Tests/OnboardingTests/OnboardingStoreTests.swift`

**Interfaces:**
- Produces: `PhoneNumber` (`init?(indianDigits: String)` from what the tutor typed, `init?(e164: String)` from storage, `e164: String` "+919611299988", `nationalDigits: String` "9611299988", `display: String` "+91 96112 99988"); `PhoneNumber.invalidMessage = "Needs 10 digits after +91."`; `OnboardingStore` (`@MainActor @Observable`): `displayName`, `centreName`, `digits`, `phoneError: String?`, `busy`, `message: String?`, `canSubmit: Bool`, `signedInAs: String`, `func submit() async -> Workspace?`, `func notYou() async`.

- [ ] **Step 1: Failing tests**

`PhoneNumberTests.swift`:

```swift
import Testing
@testable import Domain

struct PhoneNumberTests {
    @Test func tenIndianDigitsInAnyDressBecomeE164() {
        for typed in ["9611299988", "96112 99988", "096112 99988", "+91 96112 99988", "+919611299988", "0091 9611299988", "96-112-99988"] {
            #expect(PhoneNumber(indianDigits: typed)?.e164 == "+919611299988", typed)
        }
    }

    @Test func anythingElseIsRefused() {
        for typed in ["", "961129998", "96112999881", "1234567890", "abc", "+44 7700 900123"] {
            #expect(PhoneNumber(indianDigits: typed) == nil, typed)
        }
    }

    @Test func displayAndNationalDigits() {
        let n = PhoneNumber(e164: "+919611299988")!
        #expect(n.display == "+91 96112 99988" && n.nationalDigits == "9611299988")
        #expect(PhoneNumber(e164: "+1415") == nil)
    }
}
```

(Indian mobile numbers start with 6 to 9; "1234567890" is refused for that reason, and the message stays "Needs 10 digits after +91.", which is also what a tutor who typed a landline reads: good enough for this build, D2.)

`OnboardingStoreTests.swift`:

```swift
import Data
import Domain
import Testing
@testable import Onboarding

@MainActor struct OnboardingStoreTests {
    @Test func prefillsFromTheProviderAndShowsWhoIsSignedIn() {
        let store = OnboardingStore(user: FakeAuthRepository.meera, auth: FakeAuthRepository(), centres: FakeCentreRepository())
        #expect(store.displayName == "Meera Nair" && store.signedInAs == "meera.nair@gmail.com")
        let relay = AuthUser(id: FakeAuthRepository.meera.id, email: "x9@privaterelay.appleid.com", fullName: nil)
        let bare = OnboardingStore(user: relay, auth: FakeAuthRepository(), centres: FakeCentreRepository())
        #expect(bare.displayName == "" && bare.signedInAs == "x9@privaterelay.appleid.com")
        let noEmail = OnboardingStore(user: AuthUser(id: relay.id, email: nil), auth: FakeAuthRepository(), centres: FakeCentreRepository())
        #expect(noEmail.signedInAs == "your Apple ID")
    }

    @Test func submitNeedsANameAndACentreAndAValidOptionalPhone() async {
        let centres = FakeCentreRepository()
        let store = OnboardingStore(user: FakeAuthRepository.meera, auth: FakeAuthRepository(), centres: centres)
        store.displayName = "  "; store.centreName = "Bright Minds Tuition"
        #expect(!store.canSubmit)
        store.displayName = "Meera Nair"
        #expect(store.canSubmit)
        store.digits = "96112"
        #expect(await store.submit() == nil && store.phoneError == "Needs 10 digits after +91." && centres.created.isEmpty)
        store.digits = "9611299988"
        let w = await store.submit()
        #expect(w?.centre.whatsappNumber == "+919611299988" && centres.created.first?.displayName == "Meera Nair")
        store.digits = ""
        #expect(store.canSubmit)
    }

    @Test func aFailureIsSaidAndTheFieldsAreKept() async {
        let centres = FakeCentreRepository(); centres.nextError = URLError(.notConnectedToInternet)
        let store = OnboardingStore(user: FakeAuthRepository.meera, auth: FakeAuthRepository(), centres: centres)
        store.centreName = "Bright Minds Tuition"
        #expect(await store.submit() == nil)
        #expect(store.message == "Couldn't create your centre. Check your connection and try again." && store.centreName == "Bright Minds Tuition")
    }

    @Test func notYouSignsOut() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = OnboardingStore(user: FakeAuthRepository.meera, auth: auth, centres: FakeCentreRepository())
        await store.notYou()
        #expect(auth.signedOut == 1)
    }
}
```

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: Implement**

`PhoneNumber.swift`:

```swift
/// An Indian mobile number (D2): ten digits starting 6 to 9, stored E.164 (+91…), shown "+91 98765 43210".
public struct PhoneNumber: Hashable, Sendable {
    public let nationalDigits: String
    public static let invalidMessage = "Needs 10 digits after +91."

    /// From what the tutor typed: spaces, dashes, a leading 0, +91 or 0091 are all fine.
    public init?(indianDigits typed: String) {
        var d = typed.filter(\.isNumber)
        if d.hasPrefix("0091") { d.removeFirst(4) } else if d.hasPrefix("91"), d.count == 12 { d.removeFirst(2) } else if d.hasPrefix("0"), d.count == 11 { d.removeFirst() }
        guard d.count == 10, let first = d.first, "6789".contains(first) else { return nil }
        nationalDigits = d
    }

    public init?(e164: String) {
        guard e164.hasPrefix("+91") else { return nil }
        self.init(indianDigits: String(e164.dropFirst(3)))
    }

    public var e164: String { "+91\(nationalDigits)" }
    public var display: String { "+91 \(nationalDigits.prefix(5)) \(nationalDigits.dropFirst(5))" }
}
```

`OnboardingStore.swift`:

```swift
import Data
import Domain
import Foundation
import Observation

/// One screen: your name, centre name, WhatsApp number (optional). One call makes the centre (create_centre).
@MainActor @Observable public final class OnboardingStore {
    public var displayName: String
    public var centreName = ""
    public var digits = "" { didSet { if digits != oldValue { phoneError = nil } } }
    public private(set) var phoneError: String?
    public private(set) var busy = false
    public var message: String?
    public let signedInAs: String
    private let user: AuthUser
    private let auth: any AuthRepository
    private let centres: any CentreRepository

    public init(user: AuthUser, auth: any AuthRepository, centres: any CentreRepository) {
        self.user = user; self.auth = auth; self.centres = centres
        displayName = user.fullName ?? ""
        signedInAs = user.email ?? "your Apple ID"
    }

    public var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !centreName.trimmingCharacters(in: .whitespaces).isEmpty && !busy
    }

    public func submit() async -> Workspace? {
        guard canSubmit else { return nil }
        var phone: PhoneNumber?
        if !digits.isEmpty {
            guard let p = PhoneNumber(indianDigits: digits) else { phoneError = PhoneNumber.invalidMessage; return nil }
            phone = p
        }
        busy = true; defer { busy = false }
        message = nil
        let draft = CentreDraft(displayName: displayName.trimmingCharacters(in: .whitespaces), centreName: centreName.trimmingCharacters(in: .whitespaces), whatsappNumber: phone?.e164)
        do { return try await centres.createCentre(draft, for: user) } catch {
            message = "Couldn't create your centre. Check your connection and try again."
            return nil
        }
    }

    public func notYou() async { await auth.signOut() }
}
```

Run: `bun check --only=ios` → PASS. Commit on `phase-2/onboarding`: `git checkout -b phase-2/onboarding && git add ios && git commit -m "Domain: the phone number; the onboarding store"`.

### Task 12: Onboarding, to `P2-Onboarding-Dark` and `-Light` (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Onboarding/OnboardingView.swift`
- Modify: `ios/TutorCentralKit/Sources/AppShell/RootView.swift` (the `.needsOnboarding` root)

- [ ] **Step 1: The view**

`OnboardingView(user:)` reads `dependencies` and `session` from the environment and makes its store. Layout on `ground` with `HeroGlow(soft: true)`, `heroTop` top, `pageSide` sides, 24 between groups (`sectionGap` plus `fieldGap`), scrollable so the keyboard never hides the button (`ScrollView` with `.scrollDismissesKeyboard(.interactively)` and the button in a `safeAreaInset(edge: .bottom)`):

- "Welcome" `eyebrow` in `accentText`; "Tell us about your centre" `display`; "Three things, and you're in. Everything can be changed later in Settings." in `body` `text2` (the board draws this line at 16 / 22, one point under `body`; no token is added for one line, and the point is noted in "As built").
- Fields, 16 apart (`rowPaddingHorizontal`): `TextWell(label: "Your name", text: $store.displayName, content: .name)`; `TextWell(label: "Centre name", text: $store.centreName, helper: "Parents see this name on receipts and reminders.", content: .organizationName)`; `PhoneWell(label: "Your WhatsApp number", digits: $store.digits, optional: true, helper: "So a parent can reply to you. You can add your UPI id for fees later.", error: store.phoneError)`.
- Footer: "Open my centre" primary `.sheet`, disabled unless `canSubmit`, loading while busy; under it, centred `caption` `text3`: "Signed in as meera.nair@gmail.com · " and a "Not you?" link in `text2` 600 that calls `notYou()` (the gate then shows sign-in).
- `message` → the toast.

On success: `session.centreCreated(workspace)`. The gate's `.needsOnboarding(user)` line becomes `OnboardingView(user: user)`.

- [ ] **Step 2: Build, photograph, compare, try for real, PR**

```bash
bun check && bun shots onboarding
```

Compare both pictures with the two onboarding boards (the fixture prefills Meera Nair and Bright Minds Tuition, the phone field empty with its placeholder, the centre field focused: set `@FocusState` to the centre field on appear for the fixture only, through `launch == .onboarding`). Then for real against the local stack: sign in with an email code, fill the form, Open my centre: Studio (http://127.0.0.1:54323) shows the centre, the membership and the profile with the name; the app shows the tabs root (a placeholder line until Task 13). Try the two refusals: a short phone number, and airplane mode.

```bash
bun pr-shots phase-2-onboarding .shots/onboarding/*.png
gh pr create --title "Onboarding creates the centre" --body-file -
```

Merge when green and the pictures render.

### Task 13: The five tabs, the later placeholders, deep links, the toast host (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/AppShell/TabsView.swift`, `LaterView.swift`, `DeepLink.swift`, `ToastHost.swift`
- Modify: `RootView.swift` (the `.ready` root, `onOpenURL`, `scenePhase`), `ios/App/TutorCentralApp.swift` (nothing: `onOpenURL` is on the root)
- Test: `ios/TutorCentralKit/Tests/AppShellTests/DeepLinkTests.swift`

**Interfaces:**
- Produces: `TabsView(workspace:)` with `@State selected: AppTab` and one `NavigationStack` per tab (`NavigationPath` per tab in `TabsState`); `LaterView(title: String, symbol: String, line: String, build: String)`; `DeepLink` enum `{ today, student(UUID), fees(month: String?), attendance(date: String?, classID: UUID?), event(UUID), authCallback }` with `init?(url: URL)` and `var tab: AppTab`; `ToastHost` overlay.

- [ ] **Step 1: Failing deep-link test**

```swift
import Foundation
import Testing
@testable import AppShell

struct DeepLinkTests {
    @Test func theFiveLinksOfTheInformationArchitecture() throws {
        let id = UUID()
        #expect(DeepLink(url: URL(string: "tutorcentral://today")!) == .today)
        #expect(DeepLink(url: URL(string: "tutorcentral://student/\(id)")!) == .student(id))
        #expect(DeepLink(url: URL(string: "tutorcentral://fees?month=2026-10")!) == .fees(month: "2026-10"))
        #expect(DeepLink(url: URL(string: "tutorcentral://fees")!) == .fees(month: nil))
        #expect(DeepLink(url: URL(string: "tutorcentral://attendance?date=2026-10-07&class=\(id)")!) == .attendance(date: "2026-10-07", classID: id))
        #expect(DeepLink(url: URL(string: "tutorcentral://event/\(id)")!) == .event(id))
        #expect(DeepLink(url: URL(string: "tutorcentral://auth-callback?code=x")!) == .authCallback)
    }

    @Test func anythingElseIsNil() {
        for s in ["https://example.com/today", "tutorcentral://", "tutorcentral://student/not-a-uuid", "tutorcentral://settings"] {
            #expect(DeepLink(url: URL(string: s)!) == nil, s)
        }
    }

    @Test func eachLinkNamesItsTab() {
        #expect(DeepLink.today.tab == .today && DeepLink.student(UUID()).tab == .students && DeepLink.fees(month: nil).tab == .fees)
        #expect(DeepLink.attendance(date: nil, classID: nil).tab == .attendance && DeepLink.event(UUID()).tab == .more)
    }
}
```

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: Implement**

`DeepLink.swift`: `init?(url:)` requires `url.scheme == "tutorcentral"`, takes `url.host()` as the first segment and `url.pathComponents.dropFirst()` as the rest, parses `URLComponents.queryItems`; `tab` as the test says (`event` → `.more`, `authCallback` → `.today`). Phase 2 routes `today` (select the tab, pop to root) and ignores the rest with a toast "That opens in a later build." (the others' screens do not exist yet); the routing switch is written in full so later phases fill cases, not rewrite.

`TabsView.swift`: `TabView(selection: $selected)` with five `Tab(title, systemImage:, value:)` entries (iOS 18+ API; on iOS 26 the system draws the floating glass bar, `components.md` "Tab bar": `sun.max`, `person.2`, `indianrupeesign`, `checkmark.circle`, `ellipsis`), `.tint(Tokens.accentText.color)`; each tab a `NavigationStack(path:)` whose root is `TodayView` (Task 14) for Today and a `LaterView` for the other four; tapping the active tab pops to its root (`onChange(of: selected)` with the previous value). The glass bar is the system's; the `chrome`, `lineGlass`, `shadowFloat` tokens are what the board drew and what the system's bar shows; no custom bar (guidelines "Native").

`LaterView.swift`, to `P2-Later`: large title (the tab's name) as the navigation title; a `Card(.list)` with 40 × 24 padding, centred: a 56 × 56 tile `accentTint` with the tab's symbol 28 in `accentText`, radius `radiusTile`; title `title3`; the line `subhead` `text2`, max width 280; a neutral `Chip` "Build 0.1 (12)" (`dependencies.bundleVersion`). Copy per tab:

| Tab | Symbol | Title | Line |
|---|---|---|---|
| Students | `person.2` | Students are on the way | This build has sign-in, your profile and the Today screen. Students, classes and the register scan arrive in a later build on TestFlight. |
| Fees | `indianrupeesign` | Fees are on the way | This build has sign-in, your profile and the Today screen. Fees, reminders and receipts arrive in a later build on TestFlight. |
| Attendance | `checkmark.circle` | Attendance is on the way | This build has sign-in, your profile and the Today screen. Marking attendance and its history arrive in a later build on TestFlight. |
| More | `ellipsis` | More is on the way | This build has sign-in, your profile and the Today screen. Schedule, classes, reports and the AI tools arrive in a later build on TestFlight. |
| pushed: Tasks | `checkmark.circle` | Tasks are on the way | This build has sign-in, your profile and the Today screen. Tasks arrive in a later build on TestFlight. |
| pushed: Schedule | `calendar` | Schedule is on the way | This build has sign-in, your profile and the Today screen. The schedule arrives in a later build on TestFlight. |

The pushed variant uses the pushed-screen navigation bar (back chevron, title `headline`) with the same card.

`ToastHost.swift`: an overlay at the bottom of the root, `ToastView` for `toasts.current`, offset above the tab bar by `tabBarInsetBottom + 66 + tileGap` when tabs show, `panel` fade in and out, `transition(.move(edge: .bottom).combined(with: .opacity))`; one at a time.

`RootView`: `.ready(w)` → `TabsView(workspace: w)`; `.onOpenURL { url in if let link = DeepLink(url: url) { route(link) } }`; `.onChange(of: scenePhase) { if $0 == .active { Task { await session.refresh() } } }` (the foreground refresh hook); `ToastHost()` as an overlay of the whole root. `LaunchState.laterStudents` and the other three launch with that tab selected.

Run: `bun check --only=ios` → PASS. Commit on `phase-2/tabs-today`: `git checkout -b phase-2/tabs-today && git add ios && git commit -m "AppShell: the five tabs, the later placeholders, deep links, the toast host"`.

### Task 14: Today, empty, with real counts (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/TodayCounts.swift`, `Greeting.swift`, `DayHeading.swift`
- Create: `ios/TutorCentralKit/Sources/Data/Counts/CountsRepository.swift`, `SupabaseCountsRepository.swift`, `FakeCountsRepository.swift`
- Create: `ios/TutorCentralKit/Sources/Features/Today/TodayStore.swift`, `TodayView.swift`, `TodayActions.swift`
- Modify: `AppShell/Dependencies.swift` (`counts`), `Fixtures.swift`, `TabsView.swift` (Today's root and its actions), `Package.swift` (`TodayTests`), `project.yml`
- Test: `Tests/DomainTests/GreetingTests.swift`, `DayHeadingTests.swift`; `Tests/TodayTests/TodayStoreTests.swift`

**Interfaces:**
- Produces: `TodayCounts { students: Int; due: Money; classesToday: Int }` with `.zero`; `Greeting.text(at date: Date, firstName: String?, calendar:)` → "Good evening, Meera" / "Good evening"; `DayHeading.long(_ date: Date, calendar:)` → "Wednesday 7 October"; `CountsRepository { func todayCounts(centre: UUID, on date: Date) async throws -> TodayCounts }`; `TodayStore` (`@MainActor @Observable`): `heading`, `greeting`, `initials`, `counts: TodayCounts`, `loading: Bool`, `error: String?`, `func load() async`; `TodayActions { openSettings, openTab(AppTab), openLater(title: String) }` (closures AppShell supplies).

- [ ] **Step 1: Failing tests**

`GreetingTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct GreetingTests {
    let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Asia/Kolkata")!; return c }()
    func at(_ hour: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: hour))! }

    @Test func bands() {
        #expect(Greeting.text(at: at(6), firstName: "Meera", calendar: cal) == "Good morning, Meera")
        #expect(Greeting.text(at: at(11), firstName: "Meera", calendar: cal) == "Good morning, Meera")
        #expect(Greeting.text(at: at(12), firstName: "Meera", calendar: cal) == "Good afternoon, Meera")
        #expect(Greeting.text(at: at(17), firstName: "Meera", calendar: cal) == "Good evening, Meera")
        #expect(Greeting.text(at: at(23), firstName: nil, calendar: cal) == "Good evening")
    }
}
```

`DayHeadingTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct DayHeadingTests {
    @Test func longFormForTodayNoYear() {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let d = cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18))!
        #expect(DayHeading.long(d, calendar: cal) == "Wednesday 7 October")
    }
}
```

`TodayStoreTests.swift`:

```swift
import Data
import Domain
import Testing
@testable import Today

@MainActor struct TodayStoreTests {
    @Test func headingGreetingInitialsAndZeroCounts() async {
        let store = TodayStore(workspace: FakeCentreRepository.meeraWorkspace, counts: FakeCountsRepository(), now: { FakeCountsRepository.fixedNow })
        #expect(store.heading == "Wednesday 7 October" && store.greeting == "Good evening, Meera" && store.initials == "MN")
        await store.load()
        #expect(store.counts == .zero && store.error == nil && !store.loading)
    }

    @Test func aCountsFailureKeepsTheLastValuesAndSaysSo() async {
        let counts = FakeCountsRepository(); counts.nextError = URLError(.notConnectedToInternet)
        let store = TodayStore(workspace: FakeCentreRepository.meeraWorkspace, counts: counts, now: { FakeCountsRepository.fixedNow })
        await store.load()
        #expect(store.counts == .zero && store.error == "Couldn't refresh. Check your connection and try again.")
    }
}
```

(`FakeCentreRepository.meeraWorkspace` and `FakeCountsRepository.fixedNow` are the fixtures moved into `Data` so that feature tests, which cannot import `AppShell`, can use them; `AppShell.Fixtures` refers to them.)

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: Implement**

`Greeting.swift`: `hour < 12` morning, `< 17` afternoon, else evening; with `", \(firstName)"` when there is one. `DayHeading.swift`: `Date.FormatStyle` with `.weekday(.wide).day().month(.wide)` in the given calendar and locale `en_IN`; the result for 7 October 2026 must be exactly "Wednesday 7 October" (check the order `en_IN` gives; if it yields "Wednesday, 7 October", build the string from the three parts). `TodayCounts.swift` as the interface.

`SupabaseCountsRepository`: three queries with `count: .exact, head: true`: `students` where `archived_at is null`; `fee_invoices` `select("amount")` where `status = 'due'` summed in Swift (`Money`); `classes` where `archived_at is null` and `meeting_days` contains the weekday number (ISO 1 to 7) of `date` in the calendar `Asia/Kolkata` (`.contains("meeting_days", value: [weekday])`). Every query is scoped by RLS; `centre` is passed for the filter `eq("centre_id", value:)` all the same.

`TodayStore`: computed `heading` and `greeting` from `now()`; `load()` sets `loading` on the first load only (the stale pattern: afterwards values stay and `error` is set on failure); `counts` from the repository.

`TodayView`, to `P2-Today-Empty-Dark` and `-Light`, in a `ScrollView` on `ground`, `pageSide` sides, `pageTop` top, `contentBottom` bottom, `sectionGap` between sections, no large title (the greeting is the title; `navigationBarHidden` on the root):

- Header row: `eyebrow` in `text3` with the heading; `display` greeting (the board draws it at 32 / 36: `display` 34 / 41 is the token; the board wins where a token exists and `display` is that token); right: `IconButton(initials: store.initials, label: "Account") { actions.openSettings() }`.
- Three `StatTile`s in an `HStack(spacing: tileGap)`: `"\(counts.students)"` "Students" → `openTab(.students)`; `counts.due.formatted` "Due" → `openTab(.fees)`; `"\(counts.classesToday)"` "Classes today" → `openLater("Schedule")`. `tone: .zero` when the value is zero, `.due` for a non-zero due amount, else `.plain`.
- `Card(.hero)` "Start here": `eyebrow` in `accentText`; "Add your first students" `title2`; "Type them in one by one, or photograph your paper register and we'll read it." `subhead` `text2`; two buttons in an `HStack(spacing: tileGap)`: "Add a student" primary `.form` with `plus`, "Scan register" secondary `.form` with `viewfinder`; both `openLater("Students")`.
- `SectionHeader("Today", action: ("Schedule", { openLater("Schedule") }))` and a `Card(.list)` holding `EmptyState(symbol: "calendar", title: "No classes yet", line: "Classes you create show here on the days they meet, with one tap to mark attendance.")` laid out as the board's row (symbol left, text right, padding 16).
- `SectionHeader("Tasks", action: ("Add", { openLater("Tasks") }))` and the same with `checkmark.circle`, "Nothing on your list", "Add a task when there's something to remember."
- A refresh error shows as a `footnote` line under the tiles with a quiet Retry (the guidelines' error state); pull to refresh calls `load()` and plays `impactLight` when it completes.

`TabsView`: the Today tab's stack root is `TodayView(store:, actions:)`; `openSettings` pushes `SettingsView` (Task 15; until then a `LaterView` titled "Settings"), `openLater(title)` pushes the matching `LaterView`, `openTab` sets `selected`.

Run: `bun check` → PASS.

- [ ] **Step 3: Photograph, compare, PR**

```bash
for s in today-empty later-students later-fees later-attendance later-more; do bun shots $s; done
```

Compare `today-empty` with its two boards and `later-fees` with `P2-Later`. Then for real against the local stack with the seed (`supabase db reset`): sign in as `meera@example.com` with a code (Mailpit) and see the counts the seed gives (ten students, the seed's due total, the classes meeting on the day): the tiles read real numbers.

```bash
bun pr-shots phase-2-tabs-today .shots/today-empty/*.png .shots/later-*/*.png
gh pr create --title "Five tabs, Today empty with real counts, the later placeholders, deep links, toasts" --body-file -
```

Merge when green and the pictures render.

### Task 15: Settings, minimal, to `P2-Settings` (PR 8)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Settings/SettingsStore.swift`, `SettingsView.swift`
- Modify: `AppShell/TabsView.swift` (push from Today), `Fixtures.swift`, `LaunchState` (`settings` opens Today with Settings pushed), `Package.swift` (`SettingsTests`), `project.yml`
- Test: `Tests/SettingsTests/SettingsStoreTests.swift`

**Interfaces:**
- Produces: `SettingsStore` (`@MainActor @Observable`): `displayName`, `centreName`, `digits`, `phoneError`, `saveState: SaveState` (`.idle`, `.saving`, `.saved`), `message`, `email: String`, `version: String`, `func commitName() async`, `func commitCentre() async`, `func commitPhone() async`, `func signOut() async`, `var onWorkspaceChanged: (Workspace) -> Void`.

- [ ] **Step 1: Failing tests**

```swift
import Data
import Domain
import Testing
@testable import Settings

@MainActor struct SettingsStoreTests {
    func make(_ centres: FakeCentreRepository = FakeCentreRepository(), auth: FakeAuthRepository = FakeAuthRepository(user: FakeAuthRepository.meera)) -> SettingsStore {
        centres.workspace = FakeCentreRepository.meeraWorkspace
        return SettingsStore(workspace: FakeCentreRepository.meeraWorkspace, auth: auth, centres: centres, version: "0.1 (12)")
    }

    @Test func showsTheWorkspaceAndTheAccount() {
        let s = make()
        #expect(s.displayName == "Meera Nair" && s.centreName == "Bright Minds Tuition" && s.digits == "9611299988")
        #expect(s.email == "meera.nair@gmail.com" && s.version == "0.1 (12)" && s.saveState == .idle)
    }

    @Test func committingANameSavesAndMarksSaved() async {
        let centres = FakeCentreRepository()
        let s = make(centres)
        var changed: Workspace?
        s.onWorkspaceChanged = { changed = $0 }
        s.displayName = "Meera"
        await s.commitName()
        #expect(centres.profileUpdates == ["Meera"] && s.saveState == .saved && changed?.profile.displayName == "Meera")
    }

    @Test func anUnchangedCommitDoesNothing() async {
        let centres = FakeCentreRepository()
        let s = make(centres)
        await s.commitCentre()
        #expect(centres.centreUpdates.isEmpty && s.saveState == .idle)
    }

    @Test func anEmptyNameOrCentreIsNotSaved() async {
        let centres = FakeCentreRepository()
        let s = make(centres)
        s.centreName = " "
        await s.commitCentre()
        #expect(centres.centreUpdates.isEmpty && s.message == "A centre needs a name." && s.centreName == "Bright Minds Tuition")
    }

    @Test func aBadPhoneIsRefusedAnEmptyOneClearsIt() async {
        let centres = FakeCentreRepository()
        let s = make(centres)
        s.digits = "12"
        await s.commitPhone()
        #expect(s.phoneError == "Needs 10 digits after +91." && centres.centreUpdates.isEmpty)
        s.digits = ""
        await s.commitPhone()
        #expect(centres.centreUpdates.last?.whatsappNumber == nil && s.saveState == .saved)
    }

    @Test func aFailedSaveKeepsTheTypedValueAndSaysSo() async {
        let centres = FakeCentreRepository()
        let s = make(centres)
        centres.nextError = URLError(.notConnectedToInternet)
        s.centreName = "Bright Minds"
        await s.commitCentre()
        #expect(s.centreName == "Bright Minds" && s.saveState == .idle && s.message == "Couldn't save. Check your connection and try again.")
    }

    @Test func signOutSignsOut() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let s = make(auth: auth)
        await s.signOut()
        #expect(auth.signedOut == 1)
    }
}
```

(`FakeCentreRepository.centreUpdates` is `[(id: UUID, name: String, whatsappNumber: String?)]`, as Task 7 defined.)

Run: `bun check --only=ios` → FAIL.

- [ ] **Step 2: Implement**

`SettingsStore`: holds a private `workspace`; each `commit*` trims, compares with the workspace value, returns if equal; validates (`"A centre needs a name."`, `"Your name can't be empty."`, the phone message); sets `saveState = .saving`, calls the repository, updates `workspace`, calls `onWorkspaceChanged`, sets `.saved`; on error sets `.idle` and `message`; `signOut` calls `auth.signOut()`.

`SettingsView`, to `P2-Settings`, pushed on the Today stack (back chevron, title "Settings" `headline`), on `ground`, `pageSide`, `sectionGap`:

- `SectionHeader("Teaching profile")` whose right side shows, instead of an action, the save mark: "Saving…" `footnote` `text3` or "Saved" with `checkmark` 14 in `footnote` `ok` 600 (nothing when idle). A `Card(.list)` with 16 padding and three fields 14 apart: `TextWell("Your name", onCommit: commitName)`, `TextWell("Centre name", onCommit: commitCentre)`, `PhoneWell("Your WhatsApp number", error: phoneError, onCommit: commitPhone)`.
- `SectionHeader("Coming in later builds")` and a `Card(.list)` at opacity 0.6 with two `SettingRow`s, not tappable: `indianrupeesign` "Parent payments and UPI" trailing "Phase 5" `caption` `text3` 600; `bell` "Reminders and haptics" trailing "Phase 7".
- `SectionHeader("Account")` and a `Card(.list)`: `SettingRow(label: "Signed in as") { Text(email) }` (`subhead` `text2`), `SettingRow(label: "Version") { Text(version) }` monospaced, and a "Sign out" row: `rectangle.portrait.and.arrow.right` 20 and the label in `overdue` 600, the whole row a button.
- Sign out: the Kit `DialogView(title: "Sign out?", body: "You can sign back in with Apple, Google or your email.", action: "Sign out", destructive: true)` over `dim` (`fullScreenCover` with a clear background, or an overlay on the root through `ToastCenter`'s sibling `DialogCenter`: keep it local, an overlay in `SettingsView`), warning haptic on appear; confirming calls `store.signOut()`; the gate then shows sign-in.
- `message` → the toast. `onWorkspaceChanged` → `session.workspaceChanged`.

`LaunchState.settings`: tabs with Today's stack holding Settings. `Fixtures` already give Meera's workspace.

Run: `bun check` → PASS.

- [ ] **Step 3: Photograph, compare, PR**

```bash
bun shots settings
bun pr-shots phase-2-settings .shots/settings/*.png
gh pr create --title "Settings: profile, version, sign out" --body-file -
```

Compare with `P2-Settings` (the fixture shows "Saved"). For real against the local stack: edit the centre name, tap elsewhere, see "Saving…" then "Saved", and in Studio the row changed; sign out, land on sign-in, sign back in, land on the tabs with the new name in the greeting. Merge when green and the picture renders.

### Task 16: The TestFlight lane (PR 9, D24)

**Files:**
- Create: `ios/ExportOptions.plist`; rewrite `.github/workflows/testflight.yml`
- Modify: `ios/project.yml` (nothing for the team: it is passed on the command line)

- [ ] **Step 1: Owner steps, one at a time**

1. **App Store Connect API key.** App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → "+": name "GitHub Actions TestFlight", access **App Manager**; download the `.p8` once (it cannot be downloaded again), note the **Key ID** and the **Issuer ID**. Check: the key is listed.
2. **Secrets and variables.** In the repository settings (or with `gh`):

```bash
gh secret set APP_STORE_CONNECT_KEY_ID
gh secret set APP_STORE_CONNECT_ISSUER_ID
gh secret set APP_STORE_CONNECT_KEY_P8 < AuthKey_XXXX.p8
gh variable set APPLE_TEAM_ID --body "<team id from Task 9 step 1>"
gh variable set SUPABASE_URL --body "https://esowihbxawvoexflekxa.supabase.co"
gh variable set SUPABASE_ANON_KEY --body "<the hosted project's anon (publishable) key>"
```

   Check: `gh secret list` shows three, `gh variable list` shows `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` beside `API_ORIGIN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`. The anon key is public by design (D11); it is a variable, not a secret, so a log can show it without harm.
3. **TestFlight, internal testing.** App Store Connect → the app → TestFlight → Internal Testing → "+" group "Owner", add the owner's Apple ID as a tester. Done before the first upload so the build goes straight to him.

- [ ] **Step 2: The export options and the workflow**

`ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
```

`.github/workflows/testflight.yml`:

```yaml
name: testflight

# The one way a build reaches TestFlight (D24), started by hand: the head of main (or a given commit of main) is
# archived on the Xcode 27 image with cloud signing (the App Store Connect API key stands in for a developer's
# certificate) and uploaded by xcodebuild itself. The build number is this run's number; the version is project.yml's.
# Nothing signs from a local machine. Every action is pinned to a commit (D14).

run-name: testflight ${{ inputs.commit || 'the head of main' }}

on:
  workflow_dispatch:
    inputs:
      commit:
        description: The commit of main to build (full SHA). Empty, the head of main.
        required: false
        default: ""

concurrency:
  group: testflight
  cancel-in-progress: false

permissions:
  contents: read

env:
  BUN_VERSION: 1.3.11

jobs:
  upload:
    name: archive and upload
    runs-on: xcode-27
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0

      - id: commit
        env:
          ASKED: ${{ inputs.commit }}
        run: |
          sha="${ASKED:-$(git rev-parse origin/main)}"
          if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then echo "::error::\"$sha\" is not a whole commit SHA."; exit 1; fi
          if ! git merge-base --is-ancestor "$sha" origin/main 2>/dev/null; then echo "::error::$sha is not a commit of main."; exit 1; fi
          git checkout -q "$sha"
          echo "sha=$sha" >> "$GITHUB_OUTPUT"

      - name: Xcode 27.0
        run: sudo xcode-select -s /Applications/Xcode_27.0.app && xcodebuild -version

      - uses: oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6 # v2.2.0
        with:
          bun-version: ${{ env.BUN_VERSION }}

      - name: Tools
        run: brew install xcodegen

      - run: bun install --frozen-lockfile

      # Production's Supabase (the anon key is public by design, D11).
      - name: Local xcconfig (production values)
        env:
          URL: ${{ vars.SUPABASE_URL }}
          KEY: ${{ vars.SUPABASE_ANON_KEY }}
        run: printf 'SUPABASE_URL = %s\nSUPABASE_ANON_KEY = %s\n' "${URL/\/\//\/$()\/}" "$KEY" > ios/Config/Local.xcconfig

      - run: bun gen

      - name: App Store Connect API key
        env:
          P8: ${{ secrets.APP_STORE_CONNECT_KEY_P8 }}
          KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
        run: |
          mkdir -p ~/private_keys
          printf '%s' "$P8" > ~/private_keys/AuthKey_$KEY_ID.p8
          chmod 600 ~/private_keys/AuthKey_$KEY_ID.p8

      - name: Archive (cloud signing)
        working-directory: ios
        env:
          TEAM: ${{ vars.APPLE_TEAM_ID }}
          KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ISSUER: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        run: |
          set -o pipefail
          xcodebuild archive \
            -project TutorCentral.xcodeproj -scheme TutorCentral -configuration Release \
            -destination 'generic/platform=iOS' -archivePath build/TutorCentral.xcarchive \
            DEVELOPMENT_TEAM="$TEAM" CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER" \
            -allowProvisioningUpdates \
            -authenticationKeyPath "$HOME/private_keys/AuthKey_$KEY_ID.p8" \
            -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER" \
            2>&1 | tee archive.log | grep -E 'error:|warning: .*signing|\*\* ARCHIVE' || true
          grep -q 'ARCHIVE SUCCEEDED' archive.log

      - name: Upload to TestFlight
        working-directory: ios
        env:
          KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ISSUER: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        run: |
          set -o pipefail
          xcodebuild -exportArchive \
            -archivePath build/TutorCentral.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export \
            -allowProvisioningUpdates \
            -authenticationKeyPath "$HOME/private_keys/AuthKey_$KEY_ID.p8" \
            -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER" \
            2>&1 | tee export.log | grep -E 'error:|Upload|EXPORT' || true
          grep -q 'EXPORT SUCCEEDED' export.log

      - name: Summary
        env:
          COMMIT: ${{ steps.commit.outputs.sha }}
        run: |
          version=$(sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' ios/project.yml)
          {
            echo "### TestFlight"
            echo "| | |"; echo "|---|---|"
            echo "| Commit | \`$COMMIT\` |"
            echo "| Build | $version ($GITHUB_RUN_NUMBER) |"
            echo "| Where | App Store Connect → TestFlight → Internal Testing, processing a few minutes |"
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Remove the key
        if: always()
        run: rm -rf ~/private_keys
```

The `xcconfig` line's parameter expansion writes `https:/$()/…` so xcconfig does not read `//` as a comment (the same trick as `Local.xcconfig.example`); check the written file in the log with `cat ios/Config/Local.xcconfig` once (the key is public).

- [ ] **Step 3: Local check, PR, first run**

```bash
bun check   # the workflow is not run locally; the check proves nothing broke
git checkout -b phase-2/testflight
git add ios/ExportOptions.plist .github/workflows/testflight.yml
git commit -m "The TestFlight lane: archive with cloud signing, upload with the App Store Connect API key (D24)"
git push -u origin phase-2/testflight && gh pr create --title "The TestFlight lane (D24)" --body "..."
```

Merge when green. Then:

```bash
gh workflow run testflight && sleep 30 && gh run watch
```

The first run is where reality speaks: a missing capability on the App ID, an export option Xcode 27 wants named differently, a provisioning profile it cannot make. Fix in a follow-up PR on the same branch name with `-2`, never by signing locally. When the run's summary shows the build, the owner opens TestFlight on his iPhone, installs, signs in with Apple (the real thing on a device), lands on onboarding or on Today if his centre exists on the hosted project, and sends a screenshot. That picture goes into the PR's body ("On the owner's phone"), and the phase's acceptance is met.

### Task 17: As built, state, record, resume (documents only, `main`)

- [ ] **Step 1: `plan/phase-02-shell-and-sign-in.md` "As built"**: the PR table (numbers and titles), acceptance checked line by line, deviations and why (the AI tools row; sign-in in `Features/Onboarding`; the two type points on onboarding and Today's greeting; the `lead` token; whatever the first TestFlight run taught; whatever else differed), what remains (custom SMTP before other testers; the legal pages if placeholders; password setting in Settings is Phase 7).
- [ ] **Step 2: `plan/README.md`**: Phase 2 status "Done (session 3, PRs #9 to #17)" (the real numbers); any decision the session took gets its number.
- [ ] **Step 3: `plan/STATE.md`**: last updated; Phase 2 done; open items: remove the taken minors, add custom SMTP, the TestFlight build number, the hosted migration 0002 pushed, the team id and the key's id (not the key).
- [ ] **Step 4: `plan/sessions/003/record.md` and `owner-messages.md`**, as `SESSIONS.md` says.
- [ ] **Step 5: `ios/CLAUDE.md`**: the new test targets, `Fixtures`, the Kit scheme, the entitlement, `CODE_SIGNING_ALLOWED=NO`; `supabase/CLAUDE.md`: migration 0002 is on the hosted project; root `CLAUDE.md` commands: `gh workflow run testflight`.
- [ ] **Step 6: Commit to `main`, push.** Then ask for a reviewer pass on the nine merged pull requests with `superpowers:requesting-code-review`, and record its outcome in the record and `STATE.md` (fixes test-first in a follow-up PR; minors deferred with their files named).

---

## Self-review

- **Spec coverage.** Phase file scope 1 (design system, tokens, components, Kit, the document test): Tasks 1 and 2. Scope 2 (shell: gate, five tabs, stacks, sheets, toasts, deep links, foreground refresh): Tasks 8 and 13. Scope 3 (Apple native, Google web session, email code with resend and cooldown, password when the account has one, errors in words, keychain session): Tasks 6, 9, 10. Scope 4 (onboarding, one call, optional field): Tasks 4, 11, 12. Scope 5 (Today empty, real counts, the AI tools row): Task 14; the row is deferred to Phase 6's board, recorded in the decisions table. Scope 6 (Settings: profile edit, sign out): Task 15. Scope 7 (TestFlight): Task 16. Owner steps 1 to 4 of the phase file: Tasks 9 and 16. Acceptance: every board state has a `LaunchState` and a picture in its PR; sign-in with the three methods is tried against the hosted project by hand (Task 9 step 6, Task 10 step 6), a wrong code's words are tested (Task 10); the Kit shows every component (Task 2); the TestFlight build on the owner's phone (Task 16). Inventory rows: Apple, Google, email code or password, privacy policy link, onboarding, teaching profile: all placed. Spec section 4 "features never import each other": Today reaches Settings through `TodayActions` closures from `AppShell`. The password state's board `P2-Email-Password` was drawn and approved in session 3.
- **Placeholders.** The six row views in Task 2 step 3 are given as signatures with their columns in comments, not full bodies: the Rows table of `components.md` and the Kit-Surfaces board carry every value, and the step says so. `Legal.swift`'s two URLs come from the owner (Task 9 step 1.6). No "TBD", no "handle edge cases".
- **Type consistency.** `SignInFailure` cases are the same in Tasks 5, 6, 9 and 10. `AuthRepository`'s eight methods are what `SupabaseAuthRepository`, `FakeAuthRepository`, `SignInStore` and `EmailSignInStore` use. `CentreRepository.workspace(for:)`, `createCentre(_:for:)`, `updateCentre(id:name:whatsappNumber:)`, `updateProfile(displayName:)` are what `SessionStore`, `OnboardingStore` and `SettingsStore` call. `Workspace` and `CentreDraft` are defined once (Task 7). `FakeCentreRepository.meeraWorkspace` and `FakeCountsRepository.fixedNow` live in `Data` (Task 14 moves them there from `AppShell.Fixtures`, which then forwards); Task 8's tests use `Fixtures.now` and are updated in Task 14 to the `Data` names. `TodayActions` closures match `TabsView`'s wiring. `LaunchState` raw values match `information-architecture.md` and `bun shots` calls. `Tokens` names match `design-tokens.md` plus the four board-derived additions and `lead`.
- **Review Focus.** 1 → Task 9 test `aCancelledSheetLeavesNoMessageAndNothingBusy`. 2 → Task 11 test `prefillsFromTheProviderAndShowsWhoIsSignedIn`. 3 → Task 10 test `wrongAndExpiredCodesHaveTheirOwnLinesAndClearTheDigits`. 4 → Task 8 tests `startsLoadingThenSignedOutWhenTheKeychainIsEmpty` and `aSignedInUserWithoutACentreGoesToOnboarding`. 5 → Task 11 `PhoneNumberTests` and `submitNeedsANameAndACentreAndAValidOptionalPhone`.
