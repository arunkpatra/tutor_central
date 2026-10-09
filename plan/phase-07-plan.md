# Phase 7 Settings, Account, Notifications, Offline and Release Candidate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything around the product is finished to its approved Phase 7 boards: Settings that save as you go with the appearance, haptics and reminders choices; an Account screen with a password, sign out and a deletion that really deletes (the auth user and everything the cascades reach, Apple told to forget the app); local reminders for classes, events and unpaid fees that open their deep links; every list readable from its cache offline with an honest bar, three writes that queue and replay with the tutor told when one fails; Dynamic Type, VoiceOver and reduced motion on every screen; the release checklist and a 1.0 release candidate on TestFlight's external group.

**Architecture:** One additive migration (0008, `delete_account()`, the second `security definer` function, D37) with an RLS test. The API gains one route, `POST /account/revoke-apple`, which turns a fresh Apple authorization code into tokens and revokes them with a client secret signed by Node's own `crypto` (no new dependency); everything else stays the app talking to Supabase. `Domain` gains the pure rules: the reminder planner, the write queue's value type and its replay order, the cache-age words, the password and confirmation rules. `Data` gains the auth additions (methods, a password, deletion), connectivity (`NWPathMonitor` behind a protocol), the notification centre behind a protocol, a cached-read helper over `JSONCache`, and the change queue with its runner. `Features/Settings` grows into Settings in full, Account, the password sheet, Delete account, Teacher reminders, Help and Pending changes; Attendance and Fees hand their three offline writes to the queue; every root reads its cache first. `AppShell` wires the routes, the offline bar and the sync banners on every tab root, the reminder scheduler (foreground and after edits), the notification delegate that opens a deep link, sign-out and deletion wiping the phone, 35 launch states, and the release pieces (the launch screen, version 1.0.0, `docs/release.md`).

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, `supabase-swift` 2.55.3, UserNotifications (`UNUserNotificationCenter`, calendar triggers, the delegate behind a wrapper), Network (`NWPathMonitor`), AuthenticationServices (`ASAuthorizationController` for the Apple confirmation), `UIApplicationDelegateAdaptor` (the one UIKit entry, for the notification delegate, with its reason in the file); Hono 4.13.13 on Vercel, Node `crypto` for the ES256 client secret, `fetch` to `appleid.apple.com`; Bun tests with `app.request`; the Supabase CLI and `bun test` for RLS; XcodeGen; GitHub Actions (`check`, `deploy`, `testflight`); the simulator runbook (D32).

**Spec:** scope and acceptance in `plan/phase-07-settings-and-hardening.md`; the boards `docs/design/mockups/P7-*.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 10; the list, the launch states and what the boards settle in `docs/design/information-architecture.md`, "Phase 7 boards"); `design-tokens.md` ("Numbers in code", the Phase 7 paragraph); `components.md` ("Phase 7 parts" and its texts); `guidelines.md` ("States every screen has", "Accessibility"); the Account, Settings and notification rows of `docs/reference/functional-inventory.md`; `docs/spec.md` sections 4 (writes offline), 5 (`delete_centre`) and 7; decisions D1 to D36 in `plan/README.md`; Phase 6's "As built" and the rulings in `plan/sessions/013/record.md`; `docs/runbooks/simulator.md` for every hand run; `docs/testing/device-tests.md` for what the tester runs; `plan/ui-polish.md` (U6, U7, U9, U16, U24 are Phase 8's, with Phase 6's minors 1, 6 and 7: the owner, 2026-10-09); the owner's choice of 2026-10-09: option A (a `security definer` `delete_account()`) plus Apple token revocation through the API.

## Global Constraints

- iOS 26.0 minimum, iPhone only (D1), bundle id `in.tutorcentral.app` (D27). Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation (D8). Features never import each other: Settings reaches the register through Domain's `Register` (D33) for the delete screen's counts; Attendance and Fees reach the queue through Data's `ChangeQueueing` protocol; AppShell owns the replay, the scheduler and the banners. UIKit only behind a wrapper with the reason in the file: `NotificationDelegate` (`UNUserNotificationCenterDelegate` is a class protocol SwiftUI cannot adopt) and `AppDelegate` (the delegate must be set before the app finishes launching).
- The lint's shapes (sessions 11 and 13): no tuple of three or more members (a struct with named fields); at most six parameters to a function (an initialiser may take more; else a struct with an `init`); files under 400 lines (a store over it splits into `+Extension.swift` files; a test struct over 250 lines splits into a second file); lines under 120 columns; no force-unwrap in a test (`try #require(...)`); `@MainActor` on the fakes and the stores; a pure `static func` on a view is `nonisolated`; no one-letter names; `!x.isEmpty` for `count > 0`.
- Concurrency in tests (session 11): an `async let` in a `@MainActor` test does not start until the test suspends: start work in a `Task` and give it 20 ms (`try await Task.sleep(for: .milliseconds(20))`) before asserting the in-flight state; a scripted error set before a store's first read is used up by that read: set it after setup.
- A call or write the tutor can leave runs in a task its store owns, refused while one runs; Cancel and Back cancel it and a late answer is dropped (`DeleteAccountStore`, the queue runner, the scheduler). Words meant for a screen that has gone are returned to the caller (the replay's toasts are AppShell's, shown on whichever tab is open).
- Every error says what is true: the offline words ("You're offline …", "nothing was saved") only when the connectivity monitor says offline or the transport error is `URLError.notConnectedToInternet`/`.networkConnectionLost`; a timeout is "took too long"; a 401 is "Sign in again"; a refused replay names its reason. Task 18 reviews every error string in the app against this.
- Style only through `DesignSystem` tokens (D10, D25): no raw colour, size, radius, shadow or duration in a feature view; a board value the document does not name becomes a token in `design-tokens.md` and Swift in the same commit; an anatomy number lives as a named constant on its component. Every new component gets a SwiftUI preview.
- Both appearances built and photographed (D13, D23). Every board state is a `LaunchState` whose raw value is the name in `information-architecture.md`'s Phase 7 table (35 states); `bun shots <state>` photographs it; every pull request that changes what is seen carries the table `bun pr-shots` prints, for each changed state in both appearances (D7, rule 2). No board, no screen (rule 1): a state this plan did not foresee is drawn and approved first. Where a board shows a figure the fixtures cannot produce, the screen follows the data (the owner, 2026-10-08).
- Copy: sentence case, no exclamation marks, no emoji, no jargon; buttons are verbs with an object; errors say what happened and what to do. The copy of every screen is on its board and in `components.md` ("Phase 7 parts", "The texts"), word for word.
- Secrets (D11): the Sign in with Apple key (`.p8`) only in Vercel's environment (`APPLE_SIGNIN_KEY`, with `APPLE_KEY_ID` and `APPLE_TEAM_ID`) and `api/.env.local`; the app holds no key; the API never holds the service-role key: `delete_account()` runs as the signed-in user's own call, the database decides.
- Database (`supabase/CLAUDE.md`): one additive migration (D26), `20261014000008_delete_account.sql`; `security definer` (the exception, D37) with `set search_path = ''`, `auth.uid()` checked, grants `authenticated` only; `supabase gen types typescript --local > types.ts` after it; an RLS test proves the cascade, the refusal of anonymous, and the other user untouched. It reaches production only through `deploy.yml`, before the API; the TestFlight lane refuses a build while it is pending.
- The API (`api/CLAUDE.md`): `src/index.ts` stays the only entry importing `"hono"`; relative imports end in `.js`; the new route behind `requireUser`; inputs are zod schemas in `src/schemas.ts`; tests with `app.request`, no network (a fake Apple client), `bun run check` green; no new dependency (the client secret is signed with Node's `crypto`, which Vercel's Node runtime has).
- Local settings (haptics, appearance, reminders) live in `UserDefaults` on this iPhone, never on the server (the boards say "This iPhone"); the register cache, the lists' caches, the queue file, the QR image and these defaults are removed on sign-out and after deletion.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/AppShellTests`, `Tests/SettingsTests`, `Tests/AttendanceTests`, `Tests/FeesTests`, `Tests/TodayTests`. Stores are tested against the fakes; the scheduler against `FakeNotificationCenter`; the queue's replay against the repository fakes with scripted errors. No UI test suites (D15). Every new repository write (`setPassword`, `delete_account`, `profiles.has_password`) is run in Swift against the local stack before its pull request merges (a throwaway test with an in-memory session, deleted before the commit).
- Hand runs (D32): before the TestFlight build, every write path this phase adds or changes is driven through the screens against the local stack (and the local API for the Apple route, which the simulator cannot complete: the fake Apple client answers there) by `docs/runbooks/simulator.md` and confirmed in the database; Task 22 names each run. Offline runs stop the gateway (`docker stop supabase_kong_tutor_central`); reminders are proven with a class that starts in 16 minutes; Dynamic Type through `xcrun simctl ui booted content_size`.
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). New decisions get their numbers in `plan/README.md` in the pull request that acts on them: D37 (the second `security definer` function), D38 (Apple revocation through the API), D39 (what works offline and what queues), D40 (sign-out and deletion wipe the phone; caches written with complete file protection).
- Nothing from the reference app is dropped (rule 10): the inventory's Account rows (email and sign out; delete account permanently with a typed confirmation and a server-side cascade; privacy policy and terms), the Settings rows (teaching profile; parent messages as WhatsApp only; teacher reminders with their status, the three switches and refresh; haptic feedback; saved marks instead of a Save button) are all placed below.

## Review Focus

Inputs the scope implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **A queued change never runs for the wrong person or centre:** the queue file is named by the centre id, sign-out and deletion delete it, and a replay reads the file of the signed-in centre only; a change made in centre A is never sent after a tutor signs into centre B on the same phone. Tests in Task 7 (`ChangeQueueTests`: `aQueueIsKeptPerCentre`, `wipeRemovesTheFile`) and Task 16 (`AppShellTests/SignOutTests`: `signOutWipesTheCachesAndTheQueue`).
2. **Order survives being online:** while the queue holds a waiting change of a kind, a new write of that kind made online goes through the queue too (appended, then the runner flushes), so an older attendance save can never overtake a newer one; a second save of the same class and day replaces the first in the queue. Tests in Task 6 (`PendingChangesTests`: `aSecondSaveOfTheSameClassAndDayReplacesTheFirst`) and Task 7 (`ChangeQueueTests`: `aWriteWhileChangesWaitJoinsTheQueueInOrder`).
3. **A replay that cannot be sent is told apart from one that must wait:** a transport failure (offline, a timeout) keeps the change waiting and stops the run; a 401 keeps it waiting and the banner says "Sign in again"; the server refusing the row (the student or class gone, `PGRST116`, a 42501) marks it failed with its reason, and the run continues with the next change. Tests in Task 7 (`ChangeQueueTests`: `anOfflineErrorStopsTheRunAndKeepsTheChange`, `aRefusedRowIsFailedAndTheRestStillGo`, `aSignedOutErrorKeepsTheChangeAndSaysSo`).
4. **Deletion is safe to retry at every step:** Apple revoked but `delete_account()` failed leaves the tutor signed in with the field kept and Retry doing both steps again (a second authorization gives a fresh code); the auth user deleted but the local sign-out failing still ends in the sign-in landing with the caches wiped; a deleted user's cached session at the next launch is a sign-out, never a crash. Tests in Task 12 (`DeleteAccountStoreTests`: `aFailedDeleteAfterAppleKeepsTheTutorSignedInAndRetries`, `aLocalSignOutFailureStillEndsSignedOut`) and Task 16 (`SessionStoreTests`: `aDeletedUsersSessionBecomesSignedOut`).
5. **Reminders fit iOS's limit and never fire in the past:** the planner drops fire times before now, keeps at most 60 of the soonest (iOS holds 64 pending), gives a class with no start time no reminder, schedules the fee reminder only when a fee is still due, and the same input plans the same ids so a refresh replaces rather than doubles. Tests in Task 4 (`ReminderPlannerTests`: `pastAndUntimedMeetingsAreSkipped`, `atMostSixtySoonestAreKept`, `theFeeReminderNeedsADueFee`, `idsAreStableAcrossRuns`).

---

## Decisions this plan settles

Small and medium things, decided here and written down. Four need a number in `plan/README.md` in the pull request that acts on them.

| Decision |
|---|
| **D37 (PR 1):** `public.delete_account()` is the second `security definer` function beside `is_member`: it deletes `auth.users` where `id = auth.uid()` (the role that owns it may; the caller may not), and 0001's cascades remove the centre, its rows, the membership, the profile and the identities. Proven on the local stack on 2026-10-09 (every count 0 after one call as the seed's tutor). The reason is in the migration file. No service-role key anywhere (D11). |
| **D38 (PR 2):** Apple's token is revoked through our API: the app asks Apple for a fresh authorization at deletion (`ASAuthorizationController`, which doubles as "confirm it's you"), sends the authorization code to `POST /account/revoke-apple`, and the API exchanges it (`/auth/token`) and revokes the refresh token (`/auth/revoke`) with a client secret it signs with the Sign in with Apple key (ES256, Node `crypto`, no dependency). Revocation runs before `delete_account()`: a failure there leaves the account whole and the tutor signed in. Google and email need nothing. |
| **D39 (PR 6):** Offline, three writes queue and replay: an attendance save, Mark paid, and the absence alert's log. Everything else is refused on Save with its words and the form kept; Remind, Generate, the AI tools and Undo on a server-written fee are disabled offline. Replay is in the order made, one at a time, each on its own; last write wins per row (the phone's write overwrites the server's row: `save_attendance` replaces the marks it sends; Mark paid updates the invoice); a change the server refuses is failed with its reason and stays until discarded. Undo on a queued Mark paid removes it from the queue (nothing was written). |
| **D40 (PR 4):** Sign-out and deletion wipe the phone: the register cache, the lists' caches, the queue, the QR image, the reminder settings, the pending notifications and the appearance and haptics defaults. Every cache file is written with `.completeUntilFirstUserAuthentication` (the Phase 3 open call, closed). |
| **Cached reads** are a store-level `CachedRead<Value>` over `JSONCache` with the time it was saved, keyed per centre: Today's counts and sessions, Fees' month (invoices, due-before, logs), Attendance's saved session for the day and History's month, Schedule's events, Tasks, AI History. Reports and a student's fees stay live reads and show the "nothing saved" card offline (month-wide reads the tutor makes online; two more caches with no board). The register's cache stays as it is. |
| **The offline bar and the sync banners are AppShell's,** placed by each root view under its title through a `statusLine` view parameter (the Banner pattern), so Features need no connectivity of their own; the words come from `CacheAge.words`. The bar shows when the monitor says offline, or when a root's refresh failed with a transport error while the monitor still said online (a captive network). |
| **Replay runs** when connectivity returns, on foreground, after a sign-in, and when the tutor taps Send again; one run at a time; a run stops at the first transport failure. The banners: "Back online. Sending N saved changes…" on the open root, the toast "N saved changes sent." (AppShell's toasts, on whichever screen is open), "N saved change(s) couldn't be sent." on every root until the failed changes are discarded or sent. |
| **Reminders** are planned by `ReminderPlanner` (Domain) from the register's active classes, the next 14 days' events and this month's due count, with `ReminderSettings` from `UserDefaults`; `ReminderScheduler` (AppShell) replaces every pending notification with the plan on foreground, after a class, event or fee write (the stores' existing `onChanged` hooks) and after the settings change; ids are stable per thing and time. The system's ask is made from the Turn on reminders button only. Refused: the screen reads `UNAuthorizationStatus.denied` and offers `UIApplication.openNotificationSettingsURLString`. |
| **A notification tap** reaches `NotificationDelegate.didReceive`, which hands the link's URL to the same `DeepLink` path `onOpenURL` uses (`shell.tabs.open`), after the session is ready; a tap before sign-in waits and runs once. |
| **Settings** keeps one store for the profile (as built) and gains `AppearanceSetting`, `HapticsSetting` and the reminder summary; the Teacher reminders, Account, Help and Pending changes rows push their screens on the same stack. The Appearance segmented control writes `Appearance.storageKey` at once (`RootView` already reads it). |
| **The password** is set with `auth.update(user: UserAttributes(password:))` (no current password: Supabase's secure password change is off); 8 characters or more; `profiles.has_password` is set true in the same store action so the sign-in sheet can offer it (the inventory). "Change password" is the same sheet retitled. |
| **The Apple row** on Account comes from `user.identities` (`provider == "apple"`), Google likewise; Email code is always on. Nothing connects a new provider in this build (no board). |
| **Deletion's counts** (10 students, 2 classes) come from the shared register (`Register.activeStudents`, `activeClasses`); with no register loaded, the notice reads "Your students with their fees and attendance, your classes, …" without numbers. |
| **The launch screen** is `UILaunchScreen` with `UIColorName` `LaunchGround` (#131110, one appearance) and `UIImageName` `LaunchBook` (the icon's book at 88 pt, marigold): static, always dark. Version `MARKETING_VERSION` 1.0.0; the build number stays the run number. `ITSAppUsesNonExemptEncryption` false in Info.plist (no custom cryptography; HTTPS only), so TestFlight asks no export question. |
| **Help's Email** opens `mailto:hello@tutorcentral.in?subject=Tutor Central 1.0 (14), iPhone` through `openURL`; with no Mail account the system says so. The four answers are the board's. |
| **The register cache on sign-out** (the open call from Phase 3): removed, with D40. **Google's mark** (the open call): the hardening task replaces the hand-drawn "G" with Google's official sign-in logo asset from Google's identity guidelines (an SVG in the asset catalogue, the button otherwise unchanged), offered to the owner in Task 18; not taken without his word. |
| **Phase 8 before Beta App Review:** TestFlight's external group needs a privacy policy URL and the app already links `tutorcentral.in/privacy` and `/terms`; the release candidate's Beta App Review submission (Task 23) waits for those pages. Everything up to the internal build proceeds. |

## File structure

```
supabase/migrations/20261014000008_delete_account.sql     delete_account(), security definer (D37), grants
supabase/tests/rls.test.ts                                 + 2 tests (cascade and refusal; the other user untouched)
supabase/types.ts                                          regenerated

api/src/apple.ts                                           AppleClient (exchange, revoke), clientSecret(), appleHttp(fetch)
api/src/apple-fake.ts                                      fakeApple(script) for tests and local runs
api/src/routes/account.ts                                  POST /account/revoke-apple
api/src/schemas.ts                                         + RevokeAppleInput
api/src/env.ts                                             + APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_SIGNIN_KEY
api/src/make-app.ts, index.ts                              the route, the client at boot (APPLE_FAKE=1 locally)
api/test/apple.test.ts, account.test.ts                    the secret's signature; the route's answers

ios/TutorCentralKit/Sources/Domain/
  Reminders/ReminderSettings.swift                         the switches and leads, Codable, defaults
  Reminders/Reminder.swift                                 id, title, body, fireAt, link
  Reminders/ReminderPlanner.swift                          plan(classes:events:dueFees:settings:now:calendar:)
  Queue/QueuedChange.swift                                 kind, madeAt, state, words
  Queue/PendingChanges.swift                               append/replace, remove, fail, inOrder, summary
  Cache/CacheAge.swift                                     words(savedAt:now:calendar:)
  Account/AccountRules.swift                               PasswordRule, DeletionConfirmation, SignInProvider
ios/TutorCentralKit/Sources/Data/
  Auth/AuthRepository.swift (+ fakes, Supabase)            signInMethods(), setPassword(_:), deleteAccount()
  Centres/CentreRepository.swift (+ fakes, Supabase)       setHasPassword()
  Account/AccountRepository.swift, FakeAccountRepository   revokeApple(code:)  (APIClient conforms)
  Network/Connectivity.swift                               ConnectivityMonitor, PathMonitor, FakeConnectivity
  Cache/CachedRead.swift                                   CachedValue<Value>, CachedRead<Value>, FileProtection
  Cache/Wipe.swift                                         Wipe.everything(centre:) removes files and defaults
  Queue/ChangeQueue.swift                                  ChangeQueueing, ChangeQueue (file-backed, per centre)
  Queue/QueueRunner.swift                                  replay through the repositories; RunOutcome
  Notifications/NotificationCenterClient.swift             the protocol, NotificationPermission, FakeNotificationCenter
  Notifications/UNClient.swift                             UNUserNotificationCenter behind it
  Notifications/NotificationDelegate.swift                 the delegate (UIKit reason), hands the link on
ios/TutorCentralKit/Sources/DesignSystem/Components/
  SettingRows.swift                                        SettingRow with a line, SegmentedRow, TileRow, MethodRow, DestructiveRow
  StatusLine.swift                                         the Banner tones used by Phase 7 (spinner, action, chevron)
  WheelPopover.swift                                       the wheel in the menu glass
  DisclosureRow.swift                                      Help's rows
  PendingRow.swift                                         a queued change
  Modifiers/ReducedMotion.swift                            transitions off when asked
ios/TutorCentralKit/Sources/Features/Settings/
  SettingsStore.swift (+Local.swift)                       the profile as built; appearance, haptics, the summaries
  SettingsView.swift (+Sections.swift)                     P7-Settings
  Account/AccountStore.swift, AccountView.swift            P7-Account, sign out
  Account/PasswordSheet.swift                              P7-Account-Password
  Account/DeleteAccountStore.swift, DeleteAccountView.swift, AppleReauthorizer.swift   P7-Delete
  Reminders/RemindersStore.swift, RemindersView.swift      P7-Reminders
  Help/HelpView.swift                                      P7-Help
  Pending/PendingChangesStore.swift, PendingChangesView.swift   P7-Pending
ios/TutorCentralKit/Sources/Features/Attendance/AttendanceStore.swift   save through the queue when offline
ios/TutorCentralKit/Sources/Features/Fees/FeesStore+Writes.swift        markPaid through the queue when offline
ios/TutorCentralKit/Sources/Features/*/…Store.swift                     CachedRead on Today, Fees, History, Schedule, Tasks, AI history
ios/TutorCentralKit/Sources/AppShell/
  RootView+Settings.swift                                  the Settings stack's screens
  RootView+Offline.swift                                   the status lines, the runner, the banners and toasts
  ReminderScheduler.swift                                  plan and replace, when
  AppDelegate.swift                                        UIApplicationDelegateAdaptor host for the delegate (reason)
  LaunchState.swift, Fixtures+Phase7.swift, RootView+LaunchStates.swift   35 states
ios/App/TutorCentralApp.swift, Info.plist, Assets.xcassets   the delegate adaptor, the launch screen, version 1.0.0
docs/release.md                                            the release checklist
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-7/db` | Database: `delete_account()` (D37), the RLS tests, types | none |
| 2 | 2, 3 | `phase-7/api` | The API: Apple token revocation with a signed client secret (D38), the fake, the route, tests | none |
| main | | | `gh workflow run deploy` after PR 2: the Apple key is in Vercel first (Task 22, step 1) | |
| 3 | 4, 5, 6 | `phase-7/domain` | Domain: the reminder planner, the pending changes, the cache age, the account rules | none |
| 4 | 7, 8, 9, 10 | `phase-7/data` | Data: auth additions, connectivity, cached reads with file protection, the change queue and its runner, the notification centre, the wipe (D40); the write proofs | none |
| 5 | 11, 12, 13 | `phase-7/settings-account` | Settings in full, Account, the password sheet, sign out, Delete account; More's rows | `settings`, `settings-end`, `settings-save-failed`, `account`, `account-password`, `account-password-failed`, `account-password-saved`, `account-sign-out`, `account-sign-out-pending`, `delete-account`, `delete-account-typed`, `delete-account-deleting`, `delete-account-failed`, `signin-deleted`, `more`, both appearances |
| 6 | 14, 15, 16 | `phase-7/offline` | Offline: cached reads on every root, the bar, the three queued writes, replay, the banners, Pending changes; sign-out wipes (D39, D40) | `offline-today`, `offline-students`, `offline-fees`, `offline-no-cache`, `offline-write-refused`, `offline-attendance-saved`, `offline-fee-marked`, `sync-sending`, `sync-sent`, `sync-failed`, `pending`, `pending-discard`, both |
| 7 | 17 | `phase-7/reminders` | Teacher reminders, the scheduler, the notification delegate, Help | `reminders-not-asked`, `reminders`, `reminders-all-off`, `reminders-refused`, `reminders-day-picker`, `help`, `help-answer`, both |
| 8 | 18, 19, 20 | `phase-7/hardening` | Hardening: Dynamic Type, VoiceOver, reduced motion, the Kit in both appearances, error wording, older screens' keyboard, the launch screen, version 1.0.0, `docs/release.md` | the tab roots and forms at `accessibility-extra-large`, `kit*`, both |
| main | 21, 22, 23 | | The hand runs, TestFlight, the owner's steps, the tester, the documents (D12) | |

---

### Task 1: The database: `delete_account()`, the RLS tests, the types (PR 1)

**Files:**
- Create: `supabase/migrations/20261014000008_delete_account.sql`
- Modify: `supabase/tests/rls.test.ts` (two tests after `only the owner can delete the centre, and it cascades`), `supabase/types.ts` (regenerated), `supabase/CLAUDE.md` (the `security definer` rule names both functions)

**Interfaces:**
- Consumes: `auth.users`, the `on delete cascade` foreign keys of migration 0001 (`centres.owner_id`, `centre_members.user_id`, `profiles.user_id`; every centre table to `centres`).
- Produces: `public.delete_account() returns void`, callable by `authenticated` only; raises `sign in first` (42501) when `auth.uid()` is null. The app (Task 7) calls it by `rpc`.

- [ ] **Step 1: Write the failing tests** (appended to `supabase/tests/rls.test.ts` after the delete-centre test; user C is made here because A's centre is gone by then):

```ts
test("delete_account removes the user, their centre and every row the cascade reaches; another user is untouched", async () => {
  const c = await userClient(l, `rls-del-${stamp}@example.com`);
  const d = await userClient(l, `rls-keep-${stamp}@example.com`);
  const centreC = (await c.rpc("create_centre", { p_name: "Centre C", p_whatsapp: null })).data as string;
  const centreD = (await d.rpc("create_centre", { p_name: "Centre D", p_whatsapp: null })).data as string;
  await c.from("students").insert({ centre_id: centreC, name: "Gone Soon" });
  await d.from("students").insert({ centre_id: centreD, name: "Stays" });
  const userC = (await c.auth.getUser()).data.user?.id as string;
  expect((await c.rpc("delete_account")).error).toBeNull();
  const sql = new SQL(l.db);
  try {
    const users = await sql`select count(*)::int as n from auth.users where id = ${userC}`;
    expect(users[0].n).toBe(0);
    const identities = await sql`select count(*)::int as n from auth.identities where user_id = ${userC}`;
    expect(identities[0].n).toBe(0);
    for (const table of [...CENTRE_TABLES, "centre_members"]) {
      const rows = await sql`select count(*)::int as n from public.${sql(table)} where centre_id = ${centreC}`;
      expect({ table, n: rows[0].n }).toEqual({ table, n: 0 });
    }
    expect((await sql`select count(*)::int as n from public.centres where id = ${centreC}`)[0].n).toBe(0);
    expect((await sql`select count(*)::int as n from public.profiles where user_id = ${userC}`)[0].n).toBe(0);
  } finally {
    await sql.close();
  }
  expect((await d.from("students").select("name").eq("centre_id", centreD)).data).toEqual([{ name: "Stays" }]);
});

test("anonymous cannot call delete_account, and a deleted user's token deletes nothing more", async () => {
  expect((await anonClient(l).rpc("delete_account")).error).not.toBeNull();
});
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd supabase && supabase db reset && bun test tests`
Expected: FAIL on `delete_account` ("Could not find the function public.delete_account").

- [ ] **Step 3: Write the migration**

```sql
-- Account deletion (Phase 7, D37): the signed-in user deletes themselves. The second security definer function beside
-- is_member: deleting from auth.users needs the owner's rights, and only auth.uid() may be deleted. 0001's cascades take
-- the centre, every centre table, the membership, the profile and the identities. Proven on the local stack 2026-10-09.
create function public.delete_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode = '42501'; end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd supabase && supabase db reset && bun test tests && supabase gen types typescript --local > types.ts`
Expected: PASS, every test; `types.ts` lists `delete_account` under `Functions`.

- [ ] **Step 5: `supabase/CLAUDE.md`:** change "`is_member` is the only `security definer`" to "`is_member` and `delete_account` are the only `security definer` functions (D37)". Add D37 to `plan/README.md` (the decisions table above, dated 2026-10-09).

- [ ] **Step 6: `bun check`, commit, pull request, merge**

```bash
git checkout -b phase-7/db && bun check && git add supabase plan/README.md && git commit -m "Database: delete_account() (D37), the RLS tests, types"
```

### Task 2: The API: the Apple client, the client secret, the fake (PR 2)

**Files:**
- Create: `api/src/apple.ts`, `api/src/apple-fake.ts`, `api/test/apple.test.ts`
- Modify: `api/src/env.ts` (three names), `api/.env.example`

**Interfaces:**
- Produces: `type AppleClient = { revokeAuthorization(code: string): Promise<void> }` throwing `AppleFailure` with `reason: "refused" | "unreachable"`; `clientSecret(key: AppleKey, now: Date): string`; `appleHttp(key: AppleKey, fetchImpl?: typeof fetch): AppleClient`; `fakeApple(script: { refuse?: boolean; unreachable?: boolean }): AppleClient` recording `revoked: string[]`.
- `type AppleKey = { teamId: string; keyId: string; privateKeyPem: string; clientId: "in.tutorcentral.app" }`.

- [ ] **Step 1: Write the failing tests** (`api/test/apple.test.ts`):

```ts
import { expect, test } from "bun:test";
import { createPublicKey, generateKeyPairSync, verify } from "node:crypto";
import { appleHttp, AppleFailure, clientSecret } from "../src/apple.js";
import { fakeApple } from "../src/apple-fake.js";

const { privateKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
const key = { teamId: "Y7SW6436RD", keyId: "ABC123DEFG", privateKeyPem: pem, clientId: "in.tutorcentral.app" as const };

function decode(part: string) {
  return JSON.parse(Buffer.from(part, "base64url").toString());
}

test("the client secret is an ES256 JWT Apple will accept: the header, the claims, a signature the public key verifies", () => {
  const now = new Date("2026-10-09T10:00:00Z");
  const jwt = clientSecret(key, now);
  const [header, payload, signature] = jwt.split(".");
  expect(decode(header)).toEqual({ alg: "ES256", kid: "ABC123DEFG" });
  expect(decode(payload)).toEqual({
    iss: "Y7SW6436RD", iat: 1791626400, exp: 1791626400 + 300, aud: "https://appleid.apple.com", sub: "in.tutorcentral.app",
  });
  const ok = verify("sha256", Buffer.from(`${header}.${payload}`), { key: createPublicKey(privateKey), dsaEncoding: "ieee-p1363" },
    Buffer.from(signature, "base64url"));
  expect(ok).toBe(true);
});

test("revokeAuthorization exchanges the code, then revokes the refresh token, as form posts", async () => {
  const calls: { url: string; body: string }[] = [];
  const fetchImpl: typeof fetch = async (input, init) => {
    const url = String(input);
    calls.push({ url, body: String(init?.body) });
    if (url.endsWith("/auth/token")) return new Response(JSON.stringify({ refresh_token: "r-1", access_token: "a-1" }), { status: 200 });
    return new Response("", { status: 200 });
  };
  await appleHttp(key, fetchImpl).revokeAuthorization("code-1");
  expect(calls.map((c) => c.url)).toEqual(["https://appleid.apple.com/auth/token", "https://appleid.apple.com/auth/revoke"]);
  const token = new URLSearchParams(calls[0].body);
  expect(token.get("grant_type")).toBe("authorization_code");
  expect(token.get("code")).toBe("code-1");
  expect(token.get("client_id")).toBe("in.tutorcentral.app");
  expect(token.get("client_secret")?.split(".").length).toBe(3);
  const revoke = new URLSearchParams(calls[1].body);
  expect(revoke.get("token")).toBe("r-1");
  expect(revoke.get("token_type_hint")).toBe("refresh_token");
});

test("a code Apple refuses is 'refused'; a network failure is 'unreachable'", async () => {
  const refusing: typeof fetch = async () => new Response(JSON.stringify({ error: "invalid_grant" }), { status: 400 });
  await expect(appleHttp(key, refusing).revokeAuthorization("bad")).rejects.toMatchObject({ reason: "refused" } satisfies Partial<AppleFailure>);
  const down: typeof fetch = async () => { throw new TypeError("fetch failed"); };
  await expect(appleHttp(key, down).revokeAuthorization("x")).rejects.toMatchObject({ reason: "unreachable" });
});

test("the fake records what it revoked and can refuse", async () => {
  const apple = fakeApple({});
  await apple.revokeAuthorization("c");
  expect(apple.revoked).toEqual(["c"]);
  await expect(fakeApple({ refuse: true }).revokeAuthorization("c")).rejects.toMatchObject({ reason: "refused" });
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd api && bun test test/apple.test.ts`
Expected: FAIL, "Cannot find module '../src/apple.js'".

- [ ] **Step 3: Write `api/src/apple.ts`**

```ts
import { createPrivateKey, sign } from "node:crypto";

export type AppleKey = { teamId: string; keyId: string; privateKeyPem: string; clientId: "in.tutorcentral.app" };
export type AppleClient = { revokeAuthorization(code: string): Promise<void> };

export class AppleFailure extends Error {
  constructor(public readonly reason: "refused" | "unreachable") {
    super(reason);
    this.name = "AppleFailure";
  }
}

const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");

/** The client secret Apple's token and revoke endpoints take: an ES256 JWT signed with the Sign in with Apple key,
 *  good for five minutes (Apple allows up to six months; a short one leaks less if it ever did). */
export function clientSecret(key: AppleKey, now: Date): string {
  const iat = Math.floor(now.getTime() / 1000);
  const header = b64({ alg: "ES256", kid: key.keyId });
  const payload = b64({ iss: key.teamId, iat, exp: iat + 300, aud: "https://appleid.apple.com", sub: key.clientId });
  const signature = sign("sha256", Buffer.from(`${header}.${payload}`), {
    key: createPrivateKey(key.privateKeyPem), dsaEncoding: "ieee-p1363",
  });
  return `${header}.${payload}.${signature.toString("base64url")}`;
}

/** Exchange the app's fresh authorization code for tokens, then revoke the refresh token: Apple's requirement for an
 *  app that deletes accounts (D38). A refused code is the caller's problem (a stale or reused code); a network failure
 *  is ours. */
export function appleHttp(key: AppleKey, fetchImpl: typeof fetch = fetch): AppleClient {
  const post = async (path: string, form: Record<string, string>) => {
    try {
      return await fetchImpl(`https://appleid.apple.com${path}`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams(form).toString(),
      });
    } catch {
      throw new AppleFailure("unreachable");
    }
  };
  return {
    async revokeAuthorization(code) {
      const secret = clientSecret(key, new Date());
      const token = await post("/auth/token", { grant_type: "authorization_code", code, client_id: key.clientId, client_secret: secret });
      if (!token.ok) throw new AppleFailure("refused");
      const { refresh_token } = (await token.json()) as { refresh_token?: string };
      if (!refresh_token) throw new AppleFailure("refused");
      const revoke = await post("/auth/revoke", { client_id: key.clientId, client_secret: secret, token: refresh_token, token_type_hint: "refresh_token" });
      if (!revoke.ok) throw new AppleFailure("refused");
    },
  };
}
```

`api/src/apple-fake.ts`:

```ts
import { type AppleClient, AppleFailure } from "./apple.js";

export type AppleScript = { refuse?: boolean; unreachable?: boolean };

/** Tests and local runs (APPLE_FAKE=1): no network, a record of every code. */
export function fakeApple(script: AppleScript): AppleClient & { revoked: string[] } {
  const revoked: string[] = [];
  return {
    revoked,
    async revokeAuthorization(code) {
      if (script.unreachable) throw new AppleFailure("unreachable");
      if (script.refuse) throw new AppleFailure("refused");
      revoked.push(code);
    },
  };
}
```

`api/src/env.ts`: the union gains `"APPLE_TEAM_ID" | "APPLE_KEY_ID" | "APPLE_SIGNIN_KEY"`. `api/.env.example` lists the three with the comment "the Sign in with Apple key (.p8), its id and the team id; APPLE_FAKE=1 skips Apple locally". The `.p8` is stored in Vercel with its newlines as `\n`; `index.ts` turns `\\n` back into newlines before use.

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd api && bun test test/apple.test.ts`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git checkout -b phase-7/api && git add api && git commit -m "API: the Apple client, the signed client secret, the fake"
```

### Task 3: The API: `POST /account/revoke-apple`, the entry, the tests (PR 2)

**Files:**
- Create: `api/src/routes/account.ts`, `api/test/account.test.ts`
- Modify: `api/src/schemas.ts` (`RevokeAppleInput`), `api/src/make-app.ts` (`Deps.apple`, the route), `api/src/index.ts` (the client at boot), `api/test/auth.test.ts` (the fake in `deps`), `api/test/entry.test.ts` (the three variables set in the spawn, as the others are)

**Interfaces:**
- Consumes: `AppleClient` (Task 2), `makeRequireUser` (`auth.ts`).
- Produces: `POST /account/revoke-apple` with body `{ "code": string }` (1 to 2000 characters): `204` on success; `400 { error }` for a bad body or a refused code (`"Apple didn't accept the confirmation. Try again."`); `401` without a live user; `502 { error: "Apple didn't answer. Try again in a minute." }` when unreachable. The app (Task 7) maps 400 to `AccountFailure.appleRefused`, 502 to `.appleUnreachable`.

- [ ] **Step 1: Write the failing tests** (`api/test/account.test.ts`):

```ts
import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

function appWith(apple = fakeApple({})) {
  return makeApp({ verify: async (t) => (t === "good" ? { id: "u1" } : null), claude: fakeClaude({}), db: fakeDb(), apple });
}
const post = (app: ReturnType<typeof makeApp>, body: unknown, token = "good") =>
  app.request("/account/revoke-apple", {
    method: "POST", body: JSON.stringify(body), headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
  });

test("a good code is revoked and answers 204", async () => {
  const apple = fakeApple({});
  const r = await post(appWith(apple), { code: "c.abc" });
  expect(r.status).toBe(204);
  expect(apple.revoked).toEqual(["c.abc"]);
});

test("no token → 401; a missing or empty code → 400 with the issue", async () => {
  expect((await post(appWith(), { code: "c" }, "nope")).status).toBe(401);
  const r = await post(appWith(), {});
  expect(r.status).toBe(400);
  expect(((await r.json()) as { error: string }).error).toContain("code");
});

test("a code Apple refuses → 400 in words; Apple unreachable → 502 in words", async () => {
  const refused = await post(appWith(fakeApple({ refuse: true })), { code: "stale" });
  expect(refused.status).toBe(400);
  expect(await refused.json()).toEqual({ error: "Apple didn't accept the confirmation. Try again." });
  const down = await post(appWith(fakeApple({ unreachable: true })), { code: "c" });
  expect(down.status).toBe(502);
  expect(await down.json()).toEqual({ error: "Apple didn't answer. Try again in a minute." });
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd api && bun test test/account.test.ts`
Expected: FAIL, 404 "no such route" (and a type error on `apple` in `Deps`).

- [ ] **Step 3: Write the schema, the route, the wiring**

`src/schemas.ts`:

```ts
export const RevokeAppleInput = z.object({ code: z.string().min(1).max(2000) });
```

`src/routes/account.ts`:

```ts
import { Hono } from "hono";
import { type AppleClient, AppleFailure } from "../apple.js";
import type { Vars } from "../auth.js";
import { RevokeAppleInput } from "../schemas.js";

/** Account routes (D38): the app sends a fresh Apple authorization code before it deletes the account; Apple is told
 *  to forget the app. The deletion itself is the database's (delete_account, D37), never the API's. */
export function accountRoutes(apple: AppleClient) {
  const r = new Hono<Vars>();
  r.post("/revoke-apple", async (c) => {
    const parsed = RevokeAppleInput.safeParse(await c.req.json().catch(() => ({})));
    if (!parsed.success) return c.json({ error: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ") }, 400);
    try {
      await apple.revokeAuthorization(parsed.data.code);
    } catch (e) {
      if (e instanceof AppleFailure && e.reason === "refused") return c.json({ error: "Apple didn't accept the confirmation. Try again." }, 400);
      return c.json({ error: "Apple didn't answer. Try again in a minute." }, 502);
    }
    return c.body(null, 204);
  });
  return r;
}
```

`src/make-app.ts`: `Deps` gains `apple: AppleClient`; after the AI routes: `app.use("/account/*", makeRequireUser(deps.verify)); app.route("/account", accountRoutes(deps.apple));`.

`src/index.ts`: `const apple = process.env.APPLE_FAKE === "1" ? fakeApple({}) : appleHttp({ teamId: env("APPLE_TEAM_ID"), keyId: env("APPLE_KEY_ID"), privateKeyPem: env("APPLE_SIGNIN_KEY").replace(/\\n/g, "\n"), clientId: "in.tutorcentral.app" });` and `apple` in `makeApp`. A deployment without the three variables fails to boot, as one without the Anthropic key does (the smoke says so).

`test/auth.test.ts` and `test/entry.test.ts`: `apple: fakeApple({})` in `deps`; the entry test's spawn env gains `APPLE_FAKE: "1"`.

- [ ] **Step 4: Run every API test and the type check**

Run: `cd api && bun run check`
Expected: PASS (tsc clean; every test).

- [ ] **Step 5: Add D38 to `plan/README.md`; `bun check`; commit; pull request; merge.** Then the deploy (Task 22, step 2) once the owner has put the key in Vercel (step 1).

```bash
git add api plan/README.md && git commit -m "API: POST /account/revoke-apple (D38): a fresh Apple code revoked with a signed client secret"
```

### Task 4: Domain: the reminder settings and the planner (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Reminders/ReminderSettings.swift`, `Reminder.swift`, `ReminderPlanner.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/ReminderPlannerTests.swift`

**Interfaces:**
- Consumes: `Classroom` (`meetingDays: Set<Weekday>`, `startTime: TimeOfDay?`, `archivedAt`), `CalendarEvent` (`date: Day`, `startTime: TimeOfDay?`), `Day`, `TimeOfDay`, `Weekday(date:calendar:)`, `Period`.
- Produces:

```swift
public struct ReminderSettings: Hashable, Sendable, Codable {
    public enum EventLead: String, CaseIterable, Hashable, Sendable, Codable { case minutes15, minutes30, hour1, dayBefore18 }
    public static let classLeads = [5, 10, 15, 30, 60]
    public static let feeDays = Array(1 ... 28)
    public var classOn = true
    public var classMinutesBefore = 15
    public var eventOn = true
    public var eventLead: EventLead = .hour1
    public var feesOn = true
    public var feesDay = 5
    public init() {}
    public var anyOn: Bool { classOn || eventOn || feesOn }
}

public struct Reminder: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable { case classMeeting, event, fees }
    public let id: String          // "class-<uuid>-2026-10-07", "event-<uuid>", "fees-2026-10"
    public let kind: Kind
    public let title: String
    public let body: String
    public let fireAt: Date
    public let link: String        // "tutorcentral://attendance?date=2026-10-07&class=<uuid>", "tutorcentral://event/<uuid>", "tutorcentral://fees?month=2026-10"
}

public struct ReminderInput: Sendable {
    public let classes: [Classroom]          // the active ones (callers filter archived)
    public let memberCounts: [UUID: Int]     // students per class, for the body
    public let events: [CalendarEvent]
    public let dueFees: (count: Int, total: Money)?   // this month's fees still due, nil when none
    public let settings: ReminderSettings
    public init(classes:memberCounts:events:dueFees:settings:)
}

public enum ReminderPlanner {
    public static let days = 14
    public static let limit = 60
    /// Every reminder from `now` over the next 14 days, soonest first, at most 60; ids stable for the same input.
    public static func plan(_ input: ReminderInput, now: Date, calendar: Calendar) -> [Reminder]
}
```

The bodies: a class "Class 10 Maths at 17:00" / "In 15 minutes · 6 students. Tap to mark attendance." ("In 1 hour" for 60; "1 student"); an event "Parents' meeting in 1 hour" / "Sat 10 Oct, 11:00–12:00 · <note's first line>" (no note: the day and time alone; an event with no start time: "Parents' meeting tomorrow" at 18:00 the day before for `.dayBefore18`, else at 09:00 that day with "today"); fees "4 fees still due for October" / "₹4,000 to collect. Tap to remind parents." ("1 fee still due"). The fee reminder fires at 09:00 on `feesDay` of this month if that is still ahead, else of next month (its month in the link and title). A meeting whose fire time is before `now` is skipped. More than 60: the soonest 60 kept.

- [ ] **Step 1: Write the failing tests**

```swift
import Domain
import Foundation
import Testing

struct ReminderPlannerTests {
    let calendar = DayHeading.india
    let maths = Classroom(
        id: UUID(), name: "Class 10 Maths", subject: "Mathematics", monthlyFee: nil,
        meetingDays: [.monday, .wednesday, .friday], startTime: TimeOfDay(hour: 17, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0), archivedAt: nil
    )

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? Date()
    }

    func input(_ settings: ReminderSettings = ReminderSettings(), events: [CalendarEvent] = [],
               dueFees: (count: Int, total: Money)? = nil) -> ReminderInput {
        ReminderInput(classes: [maths], memberCounts: [maths.id: 6], events: events, dueFees: dueFees, settings: settings)
    }

    @Test func aClassRemindsBeforeEachMeetingOfTheNextFourteenDays() {
        let plan = ReminderPlanner.plan(input(), now: at(7, 16, 35), calendar: calendar)   // Wed 7 Oct
        let classes = plan.filter { $0.kind == .classMeeting }
        #expect(classes.first?.fireAt == at(7, 16, 45))
        #expect(classes.first?.title == "Class 10 Maths at 17:00")
        #expect(classes.first?.body == "In 15 minutes · 6 students. Tap to mark attendance.")
        #expect(classes.first?.link == "tutorcentral://attendance?date=2026-10-07&class=\(maths.id.uuidString.lowercased())")
        #expect(classes.count == 6)   // Wed 7, Fri 9, Mon 12, Wed 14, Fri 16, Mon 19 (Wed 21 is day 15)
    }

    @Test func pastAndUntimedMeetingsAreSkipped() throws {
        let late = ReminderPlanner.plan(input(), now: at(7, 16, 50), calendar: calendar)
        #expect(late.first { $0.kind == .classMeeting }?.fireAt == at(9, 16, 45))
        var untimed = maths
        untimed.startTime = nil
        let none = ReminderInput(classes: [untimed], memberCounts: [:], events: [], dueFees: nil, settings: ReminderSettings())
        #expect(ReminderPlanner.plan(none, now: at(7, 9), calendar: calendar).filter { $0.kind == .classMeeting }.isEmpty)
    }

    @Test func anEventRemindsByItsLead() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 10))
        let meeting = CalendarEvent(
            id: UUID(), title: "Parents' meeting", date: day, startTime: TimeOfDay(hour: 11, minute: 0),
            endTime: TimeOfDay(hour: 12, minute: 0), note: "Class 10 parents"
        )
        var settings = ReminderSettings()
        settings.eventLead = .hour1
        let plan = ReminderPlanner.plan(input(settings, events: [meeting]), now: at(7, 9), calendar: calendar)
        let event = try #require(plan.first { $0.kind == .event })
        #expect(event.fireAt == at(10, 10) && event.title == "Parents' meeting in 1 hour")
        #expect(event.body == "Sat 10 Oct, 11:00–12:00 · Class 10 parents")
        #expect(event.link == "tutorcentral://event/\(meeting.id.uuidString.lowercased())")
        settings.eventLead = .dayBefore18
        let eve = ReminderPlanner.plan(input(settings, events: [meeting]), now: at(7, 9), calendar: calendar)
        #expect(eve.first { $0.kind == .event }?.fireAt == at(9, 18))
    }

    @Test func theFeeReminderNeedsADueFee() {
        let none = ReminderPlanner.plan(input(), now: at(1, 9), calendar: calendar)
        #expect(none.filter { $0.kind == .fees }.isEmpty)
        let some = ReminderPlanner.plan(input(dueFees: (4, Money(rupees: 4000))), now: at(1, 9), calendar: calendar)
        let fees = some.filter { $0.kind == .fees }
        #expect(fees.map(\.fireAt) == [at(5, 9)])
        #expect(fees.first?.title == "4 fees still due for October" && fees.first?.body == "₹4,000 to collect. Tap to remind parents.")
        #expect(fees.first?.link == "tutorcentral://fees?month=2026-10")
        let past = ReminderPlanner.plan(input(dueFees: (1, Money(rupees: 800))), now: at(6, 9), calendar: calendar)
        #expect(past.first { $0.kind == .fees }?.fireAt == calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 9)))
    }

    @Test func switchesOffDropTheirKind() {
        var settings = ReminderSettings()
        settings.classOn = false
        settings.feesOn = false
        let plan = ReminderPlanner.plan(input(settings, dueFees: (4, Money(rupees: 4000))), now: at(7, 9), calendar: calendar)
        #expect(plan.isEmpty)
    }

    @Test func atMostSixtySoonestAreKept() {
        let daily = Classroom(
            id: UUID(), name: "Daily", subject: nil, monthlyFee: nil, meetingDays: Set(Weekday.allCases),
            startTime: TimeOfDay(hour: 8, minute: 0), endTime: nil, archivedAt: nil
        )
        let classes = (0 ..< 6).map { _ in daily }   // 6 classes × 14 days = 84 meetings
        let input = ReminderInput(classes: classes, memberCounts: [:], events: [], dueFees: nil, settings: ReminderSettings())
        let plan = ReminderPlanner.plan(input, now: at(7, 7), calendar: calendar)
        #expect(plan.count == ReminderPlanner.limit)
        #expect(plan == plan.sorted { $0.fireAt < $1.fireAt })
    }

    @Test func idsAreStableAcrossRuns() {
        let first = ReminderPlanner.plan(input(), now: at(7, 9), calendar: calendar).map(\.id)
        let second = ReminderPlanner.plan(input(), now: at(7, 9, 30), calendar: calendar).map(\.id)
        #expect(first == second && first.first == "class-\(maths.id.uuidString.lowercased())-2026-10-07")
    }
}
```

(`Money(rupees:)` is Domain's existing initialiser; if its name differs, use the one `MoneyTests` uses.)

- [ ] **Step 2: Run them to see them fail**

Run: `bun check --only=ios` (or `xcodebuild test -only-testing:DomainTests/ReminderPlannerTests …` from `ios/`)
Expected: FAIL to compile ("cannot find 'ReminderPlanner'").

- [ ] **Step 3: Write the three files.** `ReminderPlanner.plan`: for each day offset 0 ..< 14, the `Day` and its `Weekday`; for each class whose `meetingDays` has it and `startTime` is set, `fireAt = day's date at startTime − classMinutesBefore`; keep when `fireAt > now`. Events: those with `date` in the window; the fire time by lead (`dayBefore18`: the day before at 18:00; a timed event: start − lead; an untimed event with a short lead: 09:00 that day); keep when `> now`. Fees: when `feesOn` and `dueFees != nil`: the 09:00 of `feesDay` this month if `> now`, else next month's. Sort by `fireAt`, then `id`; `prefix(limit)`. Dates through `calendar.date(from:)` with the day's components; `Day` to components through its `year`, `month`, `day`. The id strings as the tests say; months as `Period.isoMonth` ("2026-10"; add it to `Period` if absent).

- [ ] **Step 4: Run the tests to see them pass**

Run: `bun check --only=ios`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git checkout -b phase-7/domain && git add ios && git commit -m "Domain: the reminder settings and the planner"
```

### Task 5: Domain: the pending changes (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Queue/QueuedChange.swift`, `PendingChanges.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/PendingChangesTests.swift`

**Interfaces:**
- Produces:

```swift
public struct QueuedChange: Hashable, Sendable, Codable, Identifiable {
    public enum Kind: Hashable, Sendable, Codable {
        case attendance(classID: UUID?, className: String, date: Day, marks: [UUID: AttendanceStatus], present: Int, total: Int)
        case markPaid(invoiceID: UUID, studentName: String, month: Period, amount: Money, method: MonthFee.PaidMethod, paidAt: Date)
        case absenceLog(studentID: UUID, studentName: String, about: Day)
    }
    public enum State: Hashable, Sendable, Codable { case waiting, failed(reason: String) }
    public let id: UUID
    public let kind: Kind
    public let madeAt: Date
    public var state: State
    public init(id: UUID = UUID(), kind: Kind, madeAt: Date, state: State = .waiting)
    /// "Attendance · Class 10 Maths" / "Fee · Dev Kumar" / "Absence alert · Hemanth Reddy"
    public var title: String
    /// "Wed 7 Oct · 5 of 6 present · 17:05" / "₹1,000 by UPI on 7 Oct · 17:12" / "Wed 7 Oct · WhatsApp opened at 17:06"
    public func line(calendar: Calendar) -> String
    /// For the sign-out dialog: "attendance for Class 10 Maths", "Dev's fee", "Hemanth's absence alert"
    public var shortName: String
}

public struct PendingChanges: Hashable, Sendable, Codable {
    public private(set) var changes: [QueuedChange] = []
    public init(changes: [QueuedChange] = [])
    /// Appends; an attendance save for the same class and day replaces the earlier one in its place (last write wins
    /// on the phone too); a Mark paid for the same invoice replaces the earlier one.
    public mutating func add(_ change: QueuedChange)
    public mutating func remove(id: UUID)
    public mutating func fail(id: UUID, reason: String)
    public mutating func retryAll()                       // failed → waiting
    public var inOrder: [QueuedChange]                    // by madeAt, waiting only
    public var waitingCount: Int
    public var failedCount: Int
    public var isEmpty: Bool
    /// "2 saved changes haven't reached the server yet: attendance for Class 10 Maths and Dev's fee."
    public var signOutWarning: String?
    public func has(kind: QueuedChange.Kind.Case) -> Bool  // whether a write of that kind must join the queue
}
```

(`QueuedChange.Kind.Case` is a small `enum Case { case attendance, markPaid, absenceLog }` with `var case: Case` on `Kind`.)

- [ ] **Step 1: Write the failing tests**

```swift
import Domain
import Foundation
import Testing

struct PendingChangesTests {
    let calendar = DayHeading.india
    let maths = UUID()
    let dev = UUID()
    func day(_ d: Int) throws -> Day { try #require(Day(year: 2026, month: 10, day: d)) }
    func at(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: hour, minute: minute)) ?? Date()
    }
    func attendance(_ d: Int, present: Int, at: Date) throws -> QueuedChange {
        try QueuedChange(kind: .attendance(classID: maths, className: "Class 10 Maths", date: day(d), marks: [:], present: present, total: 6), madeAt: at)
    }
    func fee(at: Date) -> QueuedChange {
        QueuedChange(kind: .markPaid(invoiceID: dev, studentName: "Dev Kumar", month: Period(year: 2026, month: 10), amount: Money(rupees: 1000), method: .upi, paidAt: at), madeAt: at)
    }

    @Test func aSecondSaveOfTheSameClassAndDayReplacesTheFirst() throws {
        var pending = PendingChanges()
        pending.add(try attendance(7, present: 5, at: at(17, 5)))
        pending.add(fee(at: at(17, 12)))
        pending.add(try attendance(7, present: 6, at: at(17, 20)))
        #expect(pending.changes.count == 2)
        #expect(pending.inOrder.map(\.title) == ["Attendance · Class 10 Maths", "Fee · Dev Kumar"])
        #expect(pending.inOrder.first?.madeAt == at(17, 5))   // keeps its place in the order, carries the newer marks
        if case let .attendance(_, _, _, _, present, _) = pending.inOrder.first?.kind { #expect(present == 6) } else { Issue.record("not attendance") }
        pending.add(try attendance(8, present: 6, at: at(18, 0)))
        #expect(pending.changes.count == 3)
    }

    @Test func failedChangesLeaveTheOrderAndComeBackOnRetry() throws {
        var pending = PendingChanges()
        let fee = fee(at: at(17, 12))
        pending.add(try attendance(7, present: 5, at: at(17, 5)))
        pending.add(fee)
        pending.fail(id: fee.id, reason: "Dev Kumar is no longer in the register, so his fee can't be marked. Keep it here or discard it.")
        #expect(pending.inOrder.count == 1 && pending.failedCount == 1 && pending.waitingCount == 1)
        pending.retryAll()
        #expect(pending.inOrder.count == 2 && pending.failedCount == 0)
        pending.remove(id: fee.id)
        #expect(pending.changes.count == 1 && pending.has(kind: .markPaid) == false && pending.has(kind: .attendance))
    }

    @Test func theLinesAndTheWarningReadAsTheBoardsDo() throws {
        var pending = PendingChanges()
        let saved = try attendance(7, present: 5, at: at(17, 5))
        pending.add(saved)
        pending.add(fee(at: at(17, 12)))
        #expect(saved.line(calendar: calendar) == "Wed 7 Oct · 5 of 6 present · 17:05")
        #expect(fee(at: at(17, 12)).line(calendar: calendar) == "₹1,000 by UPI on 7 Oct · 17:12")
        #expect(pending.signOutWarning == "2 saved changes haven't reached the server yet: attendance for Class 10 Maths and Dev's fee.")
        #expect(PendingChanges().signOutWarning == nil)
        let one = PendingChanges(changes: [saved])
        #expect(one.signOutWarning == "1 saved change hasn't reached the server yet: attendance for Class 10 Maths.")
    }

    @Test func itRoundTripsAsJSON() throws {
        var pending = PendingChanges()
        pending.add(try attendance(7, present: 5, at: at(17, 5)))
        let data = try JSONEncoder().encode(pending)
        #expect(try JSONDecoder().decode(PendingChanges.self, from: data) == pending)
    }
}
```

- [ ] **Step 2: Run to see them fail** (compile error). **Step 3: Write the two files** as the interfaces say; `shortName` uses the student's first name (`Student.firstName`'s rule: the text before the first space) with "'s fee" / "'s absence alert"; the warning joins names with ", " and " and ". **Step 4: Run to see them pass.** **Step 5: Commit** "Domain: the pending changes and their order".

### Task 6: Domain: the cache age, the account rules (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Cache/CacheAge.swift`, `Domain/Account/AccountRules.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/CacheAgeTests.swift`, `AccountRulesTests.swift`

**Interfaces:**
- Produces: `enum CacheAge { static func words(savedAt: Date, now: Date, calendar: Calendar) -> String }` ("Offline. Showing what was saved at 14:10." / "… saved yesterday at 18:30." / "… saved on Mon 5 Oct."); `enum PasswordRule { static let minimum = 8; static func isAcceptable(_ password: String) -> Bool }`; `enum DeletionConfirmation { static func matches(typed: String, centreName: String) -> Bool }` (trimmed, case-insensitive, whitespace runs folded); `enum SignInProvider: String, Hashable, Sendable, Codable { case apple, google, email }` with `var label: String` ("Apple", "Google", "Email code").

- [ ] **Step 1: Write the failing tests**

```swift
import Domain
import Foundation
import Testing

struct CacheAgeTests {
    let calendar = DayHeading.india
    func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? Date()
    }

    @Test func todayYesterdayAndEarlier() {
        let now = at(7, 16, 35)
        #expect(CacheAge.words(savedAt: at(7, 14, 10), now: now, calendar: calendar) == "Offline. Showing what was saved at 14:10.")
        #expect(CacheAge.words(savedAt: at(6, 18, 30), now: now, calendar: calendar) == "Offline. Showing what was saved yesterday at 18:30.")
        #expect(CacheAge.words(savedAt: at(5, 9, 0), now: now, calendar: calendar) == "Offline. Showing what was saved on Mon 5 Oct.")
    }
}

struct AccountRulesTests {
    @Test func aPasswordNeedsEightCharacters() {
        #expect(!PasswordRule.isAcceptable("short7!") && PasswordRule.isAcceptable("brightminds2026"))
    }

    @Test func theTypedCentreNameMatchesLoosely() {
        #expect(DeletionConfirmation.matches(typed: "  bright minds  tuition ", centreName: "Bright Minds Tuition"))
        #expect(!DeletionConfirmation.matches(typed: "Bright Minds", centreName: "Bright Minds Tuition"))
    }

    @Test func providersHaveTheirLabels() {
        #expect(SignInProvider.apple.label == "Apple" && SignInProvider.email.label == "Email code")
    }
}
```

- [ ] **Step 2 to 5:** fail, write, pass, commit "Domain: the cache age, the password and deletion rules". Then `bun check`, push, pull request 3, merge.

### Task 7: Data: the auth additions, the account route's client, the wipe (PR 4)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Data/Auth/AuthRepository.swift`, `SupabaseAuthRepository.swift`, `FakeAuthRepository.swift`; `Data/Centres/CentreRepository.swift`, `SupabaseCentreRepository.swift`, `FakeCentreRepository.swift`; `Data/AI/APIClient.swift` (conforms to `AccountRepository`), `Data/AI/APIFailure.swift` (two cases)
- Create: `Data/Account/AccountRepository.swift`, `FakeAccountRepository.swift`, `Data/Cache/Wipe.swift`
- Test: `Tests/DataTests/AuthAdditionsTests.swift`, `Tests/DataTests/WipeTests.swift`

**Interfaces:**
- Produces, on `AuthRepository`:

```swift
/// The providers the signed-in user has (`user.identities`), for Account's methods card; email means the code.
func signInMethods() async -> [SignInProvider]
/// `auth.update(user: UserAttributes(password:))`; throws `AccountFailure`.
func setPassword(_ password: String) async throws(AccountFailure)
/// `delete_account()` (D37) as the signed-in user, then the local session ended whatever the answer of the second step.
func deleteAccount() async throws(AccountFailure)
```

- `public enum AccountFailure: Error, Hashable, Sendable { case offline, signedOut, weakPassword, appleRefused, appleUnreachable, server(String); public var message: String }` with the words: offline "You're offline. Connect and try again."; signedOut "Your sign-in has ended. Sign in again."; weakPassword "Choose a password that's harder to guess."; appleRefused "Apple didn't accept the confirmation. Try again."; appleUnreachable "Apple didn't answer. Try again in a minute."; server(words) the words.
- `CentreRepository.setHasPassword() async throws` (`profiles.has_password = true` for `auth.uid()`); the fake records `hasPasswordSet: Int`.
- `public protocol AccountRepository: Sendable { func revokeApple(code: String) async throws(AccountFailure) }`; `APIClient` conforms (`POST /account/revoke-apple`, 400 → `.appleRefused`, 502 → `.appleUnreachable`, 401 → `.signedOut`, transport → `.offline`); `FakeAccountRepository` (`@MainActor`, `revoked: [String]`, `nextFailure: AccountFailure?`).
- `FakeAuthRepository` gains `methods: [SignInProvider] = [.apple, .email]`, `passwords: [String]`, `deleted: Int`, `nextAccountFailure: AccountFailure?`; `deleteAccount()` emits nil (signed out) after the delete.
- `public enum Wipe { public static func everything(centre: UUID, directory: URL? = nil, defaults: UserDefaults = .standard) }`: removes `register-<centre>.json`, `cache-<centre>-*.json`, `queue-<centre>.json`, `upi-qr-<centre>.png` under Application Support/TutorCentral (or `directory`), and the defaults `haptics`, `appearance`, `reminders`, `reminders.asked`. Pending notifications are the notification client's (Task 10); the caller removes them.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing

@MainActor struct AuthAdditionsTests {
    @Test func theFakeReportsMethodsSetsAPasswordAndDeletes() async throws {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        #expect(await auth.signInMethods() == [.apple, .email])
        try await auth.setPassword("brightminds2026")
        #expect(auth.passwords == ["brightminds2026"])
        var seen: [AuthUser?] = []
        let stream = auth.changes()
        let listening = Task { for await user in stream { seen.append(user); if user == nil { break } } }
        try await auth.deleteAccount()
        await listening.value
        #expect(auth.deleted == 1 && seen == [nil] && auth.user == nil)
    }

    @Test func aScriptedFailureIsThrownOnce() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        auth.nextAccountFailure = .weakPassword
        await #expect(throws: AccountFailure.weakPassword) { try await auth.setPassword("x") }
        await #expect(throws: Never.self) { try await auth.setPassword("brightminds2026") }
    }

    @Test func theWordsSayWhatHappened() {
        #expect(AccountFailure.appleRefused.message == "Apple didn't accept the confirmation. Try again.")
        #expect(AccountFailure.offline.message == "You're offline. Connect and try again.")
    }
}

struct WipeTests {
    @Test func everythingOfTheCentreGoesAndNothingElse() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wipe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let mine = UUID()
        let other = UUID()
        for name in ["register-\(mine.uuidString.lowercased()).json", "cache-\(mine.uuidString.lowercased())-fees-2026-10.json",
                     "queue-\(mine.uuidString.lowercased()).json", "upi-qr-\(mine.uuidString.lowercased()).png",
                     "register-\(other.uuidString.lowercased()).json"] {
            try Data("x".utf8).write(to: dir.appendingPathComponent(name))
        }
        let defaults = try #require(UserDefaults(suiteName: "wipe-\(UUID().uuidString)"))
        defaults.set(false, forKey: "haptics")
        defaults.set("light", forKey: "appearance")
        Wipe.everything(centre: mine, directory: dir, defaults: defaults)
        let left = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(left == ["register-\(other.uuidString.lowercased()).json"])
        #expect(defaults.object(forKey: "haptics") == nil && defaults.object(forKey: "appearance") == nil)
    }
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Write the code.** `SupabaseAuthRepository.signInMethods`: `auth.currentSession?.user.identities?.compactMap { SignInProvider(rawValue: $0.provider) } ?? []` (Supabase names them `apple`, `google`, `email`), de-duplicated in that order. `setPassword`: `try await auth.update(user: UserAttributes(password: password))`; a `weak_password` error code maps to `.weakPassword` (`AuthErrorMapping` gains the case), `URLError` to `.offline`, a 401 to `.signedOut`. `deleteAccount`: `try await client.rpc("delete_account").execute()` wrapped the same way; then `try? await auth.signOut(scope: .local)` in a `defer`-like second step that runs whether the first threw or not only when the first succeeded; the repository needs the `SupabaseClient`, not only `AuthClient` (change its stored property). `SupabaseCentreRepository.setHasPassword`: `from("profiles").update(["has_password": .bool(true)]).eq("user_id", value: userID)`. `APIClient.revokeApple`: `post("/account/revoke-apple", body: ["code": code])` with the status mapping in `failure(status:body:)` extended for the account route (`AccountFailure` from `APIFailure`: offline, signedOut, 400 → appleRefused, 502 → appleUnreachable, else server).

- [ ] **Step 4: Run to see them pass.** **Step 5: The write proofs** (a throwaway test in `DataTests` with a live client against the local stack, as `ios/CLAUDE.md` asks, deleted before the commit): sign in as the seed's tutor, `setPassword("tutor-local-2")`, sign out, sign in with the new password (works), `setHasPassword()` then `select has_password from profiles` is true; make a second user with the Supabase admin API through `supabase/tests/client.ts`'s pattern (or the seed's tutor after `supabase db reset`), `deleteAccount()`, then `select count(*) from auth.users where id = …` is 0 and `currentUser()` is nil. Record the outcome in the pull request. `supabase db reset` after.

- [ ] **Step 6: Commit** "Data: sign-in methods, a password, delete_account, the Apple route's client, the wipe".

### Task 8: Data: connectivity and cached reads with file protection (PR 4)

**Files:**
- Create: `Data/Network/Connectivity.swift`, `Data/Cache/CachedRead.swift`
- Modify: `Data/Cache/JSONCache.swift` (writes with `.completeUntilFirstUserAuthentication`), `Data/Cache/QRImageStore.swift` (already complete protection; unchanged)
- Test: `Tests/DataTests/CachedReadTests.swift`, `Tests/DataTests/ConnectivityTests.swift`

**Interfaces:**
- Produces:

```swift
public protocol ConnectivityMonitor: Sendable {
    /// The last known state; true until the first path update says otherwise.
    var isOnline: Bool { get async }
    /// Every change after the current state.
    func changes() -> AsyncStream<Bool>
}
/// NWPathMonitor on its own queue; `status == .satisfied` is online.
public final class PathMonitor: ConnectivityMonitor { public init() }
@MainActor public final class FakeConnectivity: ConnectivityMonitor { public init(online: Bool = true); public func set(online: Bool) }

public struct CachedValue<Value: Codable & Sendable>: Codable, Sendable { public let value: Value; public let savedAt: Date }
/// One list's copy on this iPhone: Application Support/TutorCentral/cache-<centre>-<key>.json.
public struct CachedRead<Value: Codable & Sendable>: Sendable {
    public init(centre: UUID, key: String, directory: URL? = nil)
    public func load() -> CachedValue<Value>?
    public func keep(_ value: Value, at: Date)   // never throws: a cache is a convenience
    public func remove()
}
/// Whether a thrown error means the network, not the server: URLError's notConnectedToInternet, networkConnectionLost,
/// cannotFindHost, cannotConnectToHost, timedOut, dnsLookupFailed, and supabase-swift's wrappers of them.
public enum TransportError { public static func isOffline(_ error: any Error) -> Bool }
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Foundation
import Testing

struct CachedReadTests {
    @Test func keepsLoadsAndRemovesOneValueWithItsTime() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cache-\(UUID().uuidString)", isDirectory: true)
        let centre = UUID()
        let read = CachedRead<[String]>(centre: centre, key: "fees-2026-10", directory: dir)
        #expect(read.load() == nil)
        let at = Date(timeIntervalSince1970: 1_791_626_400)
        read.keep(["Dev Kumar"], at: at)
        #expect(read.load()?.value == ["Dev Kumar"] && read.load()?.savedAt == at)
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(names == ["cache-\(centre.uuidString.lowercased())-fees-2026-10.json"])
        read.remove()
        #expect(read.load() == nil)
    }

    @Test func offlineErrorsAreToldFromTheRest() {
        #expect(TransportError.isOffline(URLError(.notConnectedToInternet)))
        #expect(TransportError.isOffline(URLError(.timedOut)))
        #expect(!TransportError.isOffline(URLError(.badServerResponse)))
        struct Other: Error {}
        #expect(!TransportError.isOffline(Other()))
    }
}

@MainActor struct ConnectivityTests {
    @Test func theFakeAnnouncesChanges() async {
        let monitor = FakeConnectivity(online: true)
        #expect(await monitor.isOnline)
        let stream = monitor.changes()
        let first = Task { await stream.first { _ in true } }
        try? await Task.sleep(for: .milliseconds(20))
        monitor.set(online: false)
        #expect(await first.value == false)
        #expect(await monitor.isOnline == false)
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass. `JSONCache.save` writes with `[.atomic, .completeFileProtectionUntilFirstUserAuthentication]` (D40); `CachedRead` is a `JSONCache<CachedValue<Value>>` named `cache-<centre>-<key>`. `PathMonitor` keeps the last `NWPath.Status` in a `Mutex` and yields changes through an `AsyncStream` as `FakeAuthRepository.Listeners` does. **Step 5: Commit** "Data: connectivity, cached reads, file protection".

### Task 9: Data: the change queue and its runner (PR 4)

**Files:**
- Create: `Data/Queue/ChangeQueue.swift`, `Data/Queue/QueueRunner.swift`
- Test: `Tests/DataTests/ChangeQueueTests.swift`, `Tests/DataTests/QueueRunnerTests.swift`

**Interfaces:**
- Consumes: `PendingChanges`, `QueuedChange` (Task 5); `AttendanceRepository.save`, `FeesRepository.markPaid`, `MessageLogRepository.logAbsence`; `TransportError.isOffline` (Task 8); `JSONCache`.
- Produces:

```swift
/// What Attendance and Fees see: a write they could not make now goes in; what is waiting is shown.
@MainActor public protocol ChangeQueueing: AnyObject {
    var pending: PendingChanges { get }
    func add(_ change: QueuedChange)
    func remove(id: UUID)
}

/// The queue of one centre, kept in Application Support/TutorCentral/queue-<centre>.json after every change.
@MainActor @Observable public final class ChangeQueue: ChangeQueueing {
    public private(set) var pending: PendingChanges
    public init(centre: UUID, directory: URL? = nil)   // loads the file
    public func add(_ change: QueuedChange)
    public func remove(id: UUID)
    public func fail(id: UUID, reason: String)
    public func retryAll()
    public func wipe()                                  // the file too
}

public enum RunOutcome: Hashable, Sendable {
    /// `sent` were sent; `failed` were refused by the server (now failed in the queue); nothing waits.
    case done(sent: Int, failed: Int)
    /// The transport failed at `sent` sends; the rest still wait.
    case offline(sent: Int)
    /// A 401: the rest wait until the tutor signs in again.
    case signedOut(sent: Int)
}

@MainActor public final class QueueRunner {
    public init(queue: ChangeQueue, centre: UUID, attendance: any AttendanceRepository, fees: any FeesRepository,
                messages: any MessageLogRepository)
    /// Sends every waiting change in order, one at a time; refused while a run is in progress (answers nil).
    public func run() async -> RunOutcome?
    public private(set) var running: Bool
    /// The reason a refused change carries: the student or class gone ("Dev Kumar is no longer in the register, so his
    /// fee can't be marked. Keep it here or discard it."; "Class 10 Maths is no longer here, so this attendance can't be
    /// saved."), else the server's words ("The server refused it: <words>").
    static func reason(for change: QueuedChange, error: any Error) -> String
}
```

A "refused" error is a `PostgrestError` whose code is `PGRST116` (no row for the update) or `23503` (a foreign key: the student or class is gone) or `42501`; a transport error (`TransportError.isOffline`) stops the run; an auth error (`AuthError` with a 401, or `PostgrestError` code `PGRST301`) stops it as signed out; any other error is refused with the server's words.

- [ ] **Step 1: Write the failing tests** (`ChangeQueueTests` on the file and the protocol; `QueueRunnerTests` on the order and the outcomes, against the fakes, whose scripted errors are `nextError`; the fakes gain `nextErrors: [any Error]` consumed one per call so a run of three can fail on the second):

```swift
import Data
import Domain
import Foundation
import Testing

@MainActor struct ChangeQueueTests {
    func dir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("queue-\(UUID().uuidString)", isDirectory: true)
    }
    func fee(_ name: String = "Dev Kumar") -> QueuedChange {
        QueuedChange(kind: .markPaid(invoiceID: UUID(), studentName: name, month: Period(year: 2026, month: 10),
                                     amount: Money(rupees: 1000), method: .upi, paidAt: Date()), madeAt: Date())
    }

    @Test func aQueueIsKeptPerCentreAndSurvivesARelaunch() {
        let folder = dir()
        let centre = UUID()
        let queue = ChangeQueue(centre: centre, directory: folder)
        queue.add(fee())
        #expect(ChangeQueue(centre: centre, directory: folder).pending.changes.count == 1)
        #expect(ChangeQueue(centre: UUID(), directory: folder).pending.isEmpty)
    }

    @Test func wipeRemovesTheFile() throws {
        let folder = dir()
        let centre = UUID()
        let queue = ChangeQueue(centre: centre, directory: folder)
        queue.add(fee())
        queue.wipe()
        #expect(queue.pending.isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }
}

@MainActor struct QueueRunnerTests {
    let attendance = FakeAttendanceRepository()
    let fees = FakeFeesRepository()
    let messages = FakeMessageLogRepository()
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    func make(_ changes: [QueuedChange]) -> (ChangeQueue, QueueRunner) {
        let queue = ChangeQueue(centre: centre, directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        for change in changes { queue.add(change) }
        return (queue, QueueRunner(queue: queue, centre: centre, attendance: attendance, fees: fees, messages: messages))
    }
    func save(at: Date) throws -> QueuedChange {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        return QueuedChange(kind: .attendance(classID: nil, className: "All students", date: day, marks: [:], present: 6, total: 6), madeAt: at)
    }
    func paid(_ id: UUID, at: Date) -> QueuedChange {
        QueuedChange(kind: .markPaid(invoiceID: id, studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
                                     amount: Money(rupees: 1000), method: .upi, paidAt: at), madeAt: at)
    }

    @Test func changesAreSentInTheOrderMadeAndLeaveTheQueue() async throws {
        let invoice = try #require(fees.invoices.first?.id)
        let (queue, runner) = make([try save(at: Date(timeIntervalSince1970: 1)), paid(invoice, at: Date(timeIntervalSince1970: 2))])
        #expect(await runner.run() == .done(sent: 2, failed: 0))
        #expect(queue.pending.isEmpty && attendance.saves.count == 1 && fees.paid == [invoice])
    }

    @Test func anOfflineErrorStopsTheRunAndKeepsTheChange() async throws {
        let invoice = try #require(fees.invoices.first?.id)
        let (queue, runner) = make([try save(at: Date(timeIntervalSince1970: 1)), paid(invoice, at: Date(timeIntervalSince1970: 2))])
        attendance.nextError = URLError(.notConnectedToInternet)
        #expect(await runner.run() == .offline(sent: 0))
        #expect(queue.pending.waitingCount == 2 && fees.paid.isEmpty)
    }

    @Test func aRefusedRowIsFailedAndTheRestStillGo() async throws {
        let (queue, runner) = make([paid(UUID(), at: Date(timeIntervalSince1970: 1)), try save(at: Date(timeIntervalSince1970: 2))])
        // The fake answers "no such invoice" for an unknown id, as PostgREST's single() does.
        #expect(await runner.run() == .done(sent: 1, failed: 1))
        #expect(queue.pending.failedCount == 1 && queue.pending.waitingCount == 0 && attendance.saves.count == 1)
        let failed = try #require(queue.pending.changes.first { $0.state != .waiting })
        #expect(failed.state == .failed(reason: "Dev Kumar is no longer in the register, so his fee can't be marked. Keep it here or discard it."))
    }

    @Test func aSignedOutErrorKeepsTheChangeAndSaysSo() async throws {
        let (queue, runner) = make([try save(at: Date())])
        attendance.nextError = FakeAttendanceRepository.signedOutError
        #expect(await runner.run() == .signedOut(sent: 0))
        #expect(queue.pending.waitingCount == 1)
    }

    @Test func aSecondRunWhileOneRunsIsRefused() async throws {
        let (_, runner) = make([try save(at: Date())])
        attendance.delay = .milliseconds(100)
        let first = Task { await runner.run() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(await runner.run() == nil)
        #expect(await first.value == .done(sent: 1, failed: 0))
    }
}
```

(`FakeAttendanceRepository.saves`, `delay`, `signedOutError` and `FakeFeesRepository`'s "no such invoice" answer are added in this task; `FakeFeesRepository.rewrite` already throws for an unknown id, make that error the runner reads as refused.)

- [ ] **Step 2 to 4:** fail, write, pass. The runner: `for change in queue.pending.inOrder` (a snapshot), send by kind; on success `queue.remove(id:)`; on error classify; `done` when the loop ends. **Step 5: Add D39 and D40 to `plan/README.md`; commit** "Data: the change queue and its runner (D39, D40)".

### Task 10: Data: the notification centre behind a protocol, the delegate (PR 4)

**Files:**
- Create: `Data/Notifications/NotificationCenterClient.swift`, `UNClient.swift`, `NotificationDelegate.swift`
- Test: `Tests/DataTests/NotificationClientTests.swift`

**Interfaces:**
- Produces:

```swift
public enum NotificationPermission: Hashable, Sendable { case notAsked, allowed, refused }

public protocol NotificationCenterClient: Sendable {
    func permission() async -> NotificationPermission
    /// The system's ask; true when allowed. Only ever called from Turn on reminders.
    func requestPermission() async -> Bool
    /// Replaces every pending reminder of ours with these (removePendingNotificationRequests for ids not in the plan,
    /// add for the rest, so an unchanged one keeps its place).
    func replace(with reminders: [Reminder]) async
    func pending() async -> [Reminder]
    func removeAll() async
}

/// UNUserNotificationCenter: a calendar trigger from `fireAt`'s components (no repeat), the link in `userInfo["link"]`,
/// the id as the request's identifier.
public final class UNClient: NotificationCenterClient { public init() }

@MainActor public final class FakeNotificationCenter: NotificationCenterClient {
    public var permissionAnswer: NotificationPermission
    public var allowOnAsk: Bool
    public private(set) var asked: Int
    public private(set) var scheduled: [Reminder]
    public private(set) var replacements: Int
    public init(permission: NotificationPermission = .notAsked, allowOnAsk: Bool = true)
}

/// UNUserNotificationCenterDelegate behind a class: SwiftUI has no way to receive a tapped notification (D8, UIKit with
/// its reason). `onOpen` gets the link's URL once the app has a handler; a tap before that is kept and delivered once.
public final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared: NotificationDelegate
    @MainActor public var onOpen: ((URL) -> Void)?   // set by RootView; a kept URL is delivered on set
    /// In the foreground the banner shows (`.banner, .sound`), the same as on the lock screen.
}
```

- [ ] **Step 1: Write the failing tests** (the fake and `Reminder` → `UNNotificationRequest` mapping, which `UNClient` exposes as `static func request(for: Reminder, calendar: Calendar) -> UNNotificationRequest`):

```swift
import Data
import Domain
import Foundation
import Testing
import UserNotifications

@MainActor struct NotificationClientTests {
    let reminder = Reminder(
        id: "class-x-2026-10-07", kind: .classMeeting, title: "Class 10 Maths at 17:00",
        body: "In 15 minutes · 6 students. Tap to mark attendance.",
        fireAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 45)) ?? Date(),
        link: "tutorcentral://attendance?date=2026-10-07&class=x"
    )

    @Test func theFakeRecordsTheAskAndThePlan() async {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        #expect(await center.permission() == .notAsked)
        #expect(await center.requestPermission())
        #expect(center.asked == 1 && (await center.permission()) == .allowed)
        await center.replace(with: [reminder])
        #expect(await center.pending() == [reminder] && center.replacements == 1)
        await center.removeAll()
        #expect(await center.pending().isEmpty)
    }

    @Test func aRequestCarriesTheTimeTheWordsAndTheLink() throws {
        let request = UNClient.request(for: reminder, calendar: DayHeading.india)
        #expect(request.identifier == "class-x-2026-10-07")
        #expect(request.content.title == "Class 10 Maths at 17:00" && request.content.body == reminder.body)
        #expect(request.content.userInfo["link"] as? String == reminder.link)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == 16 && trigger.dateComponents.minute == 45 && trigger.dateComponents.day == 7)
        #expect(!trigger.repeats)
    }

    @Test func aTapBeforeTheHandlerIsDeliveredOnce() {
        let delegate = NotificationDelegate()
        let url = URL(string: "tutorcentral://today")
        delegate.open(URL(string: "tutorcentral://today"))
        var opened: [URL] = []
        delegate.onOpen = { opened.append($0) }
        #expect(opened.map(\.absoluteString) == [url?.absoluteString])
        delegate.onOpen = { opened.append($0) }
        #expect(opened.count == 1)
    }
}
```

(`NotificationDelegate.open(_:)` is the internal method `didReceive` calls with the link; the test target needs `@testable import Data` for it.)

- [ ] **Step 2 to 4:** fail, write, pass. `Reminder` gains `Codable` for the fake's `pending()` and the record; `UNClient.permission()` maps `.notDetermined` → `.notAsked`, `.authorized`/`.provisional`/`.ephemeral` → `.allowed`, `.denied` → `.refused`; `requestPermission` asks `[.alert, .sound, .badge]`. **Step 5: Commit** "Data: the notification centre behind a protocol, the delegate". Then `bun check`, push, pull request 4, merge.

### Task 11: DesignSystem: the Phase 7 parts; Settings in full (PR 5)

**Files:**
- Create: `DesignSystem/Components/SettingRows.swift` (`SettingRow` with a `line:` initialiser, `SegmentedRow`, `TileRow`, `MethodRow`, `DestructiveRow`), `StatusLine.swift`, `WheelPopover.swift`, `DisclosureRow.swift`, `PendingRow.swift`; `Features/Settings/SettingsStore+Local.swift`, `SettingsView+Sections.swift`
- Modify: `DesignSystem/Components/SaveMark.swift` (a "Saving" state with the spinner), `Features/Settings/SettingsStore.swift`, `SettingsView.swift`, `AppShell/RootView+Today.swift` (the Settings wiring moves to `RootView+Settings.swift`), `AppShell/TabsView.swift` and `TabsState.swift` (routes `.account`, `.deleteAccount`, `.reminders`, `.help`, `.pendingChanges`), `AppShell/MoreView.swift` (Account and Help live)
- Test: `Tests/SettingsTests/SettingsLocalTests.swift`, `Tests/DesignSystemTests/Phase7PartsTests.swift` (the parts' anatomy constants against the boards' numbers, as the Kit tests do)

**Interfaces:**
- Consumes: `Appearance` (AppShell's enum moves to DesignSystem as `AppearanceChoice` so Settings can offer it without importing AppShell: `case dark, light, system`, `storageKey "appearance"`, `label` "Dark", "Light", "Match iPhone"; AppShell's `Appearance` becomes a typealias), `Haptic.storageKey`, `ReminderSettings` and `NotificationPermission` for the summary row, `ChangeQueueing.pending.changes.count` for the Pending changes row.
- Produces on `SettingsStore`: `var appearance: AppearanceChoice` (writes the default on set), `var haptics: Bool` (writes `Haptic.storageKey`), `let reminderState: String` ("On", "Off", "Not allowed", "Not set up": from the permission and `ReminderSettings.anyOn`), `var pendingCount: Int`, `let legal: (privacy: URL, terms: URL)` passed in; the Settings sections to P7-Settings: Teaching profile (as built), Parents, This iPhone, Account, About.
- `SettingsView` takes `SettingsActions { openPayments, openReminders, openAccount, openHelp, openPendingChanges, openURL }`.
- The parts, as `components.md` "Phase 7 parts" describes them, each with its SwiftUI preview and named constants: `SegmentedRow(label:symbol:options:selection:)`, `TileRow(label:value:symbol:action:)`, `MethodRow(provider:value:tone:action:)`, `DestructiveRow(symbol:label:chevron:action:)`, `StatusLine(text:symbol:tone:spinner:action:chevron:)`, `WheelPopover(eyebrow:values:selection:)`, `DisclosureRow(question:answer:isOpen:toggle:)`, `PendingRow(change:calendar:onDiscard:)`.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct SettingsLocalTests {
    func make(defaults: UserDefaults) -> SettingsStore {
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        return SettingsStore(
            workspace: FakeCentreRepository.meeraWorkspace, auth: FakeAuthRepository(user: FakeAuthRepository.meera),
            centres: centres, version: "1.0 (14)", defaults: defaults,
            reminders: ReminderSummary(permission: .allowed, settings: ReminderSettings()), pendingCount: 0
        )
    }

    @Test func appearanceAndHapticsWriteTheDefaultsAtOnce() throws {
        let defaults = try #require(UserDefaults(suiteName: "settings-\(UUID().uuidString)"))
        let store = make(defaults: defaults)
        #expect(store.appearance == .dark && store.haptics == true)
        store.appearance = .light
        store.haptics = false
        #expect(defaults.string(forKey: AppearanceChoice.storageKey) == "light")
        #expect(defaults.bool(forKey: Haptic.storageKey) == false)
    }

    @Test func theRemindersRowSaysWhereTheyStand() {
        #expect(ReminderSummary(permission: .notAsked, settings: ReminderSettings()).value == "Not set up")
        #expect(ReminderSummary(permission: .refused, settings: ReminderSettings()).value == "Not allowed")
        #expect(ReminderSummary(permission: .allowed, settings: ReminderSettings()).value == "On")
        var off = ReminderSettings()
        off.classOn = false
        off.eventOn = false
        off.feesOn = false
        #expect(ReminderSummary(permission: .allowed, settings: off).value == "Off")
    }

    @Test func thePendingRowReadsNoneOrTheCount() {
        #expect(SettingsStore.pendingValue(0) == "None" && SettingsStore.pendingValue(2) == "2")
    }

    @Test func aFailedSaveNamesTheField() async {
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        let store = make(defaults: .standard)
        centres.nextError = URLError(.notConnectedToInternet)
        store.centreName = "Bright Minds Tuition Centre"
        await store.commitCentre()
        #expect(store.message == "Couldn't save the centre's name. Check your connection and try again.")
        #expect(store.centreName == "Bright Minds Tuition Centre" && store.saveState == .idle)
    }
}
```

(`SettingsStore.commitCentre` and the others change their failure words to name the field: "your name", "the centre's name", "your WhatsApp number"; the fake used by `make` must be the one scripted, so give `make` the `centres` parameter as the existing tests do.)

- [ ] **Step 2 to 4:** fail, write, pass. The views: `SettingsView` to P7-Settings and P7-Settings-End (the screen scrolls; U24's status-bar glass on this pushed screen is part of Task 18); the Saved mark shows "Saving" while a write runs; the Appearance control writes at once with the selection haptic; the Version row is plain; Privacy policy and Terms of use open through `openURL` with the trailing `arrow.up.right`. `MoreView`: Account and Help as `SettingRow`s pushing `.account` and `.help`. `RootView+Settings.swift` builds the Settings stack's screens (Settings, Payments, Reminders, Account, Delete account, Help, Pending changes) from `shell.tabs` routes.

- [ ] **Step 5: Launch states** `settings` (re-shot), `settings-end` (the view scrolled by a `boardState`), `settings-save-failed` (the fixture's centre repository failing once, the toast shown on appear with the field's name, the typed value longer), `more` (re-shot). `bun shots` each, both appearances. **Commit** "Settings in full: parents, this iPhone, account, about; More's rows; the Phase 7 parts".

### Task 12: Account, the password sheet, sign out (PR 5)

**Files:**
- Create: `Features/Settings/Account/AccountStore.swift`, `AccountView.swift`, `PasswordSheet.swift`, `PasswordStore.swift`
- Modify: `AppShell/RootView+Settings.swift` (the Account screen, sign-out through `session.signOut()` after the wipe), `AppShell/SessionStore.swift` (`signOut()` wipes first: `Wipe.everything(centre:)`, the notification client's `removeAll()`, `shell.queue?.wipe()`)
- Test: `Tests/SettingsTests/AccountStoreTests.swift`, `PasswordStoreTests.swift`, `Tests/AppShellTests/SignOutTests.swift`

**Interfaces:**
- `AccountStore(workspace:auth:centres:queue:)`: `let name: String`, `let email: String`, `let initials: String`, `private(set) var methods: [SignInProvider]` (loaded by `load()`), `private(set) var hasPassword: Bool` (from `workspace.profile.hasPassword`: `Profile` gains `hasPassword: Bool`, read from `profiles.has_password` by `SupabaseCentreRepository.workspace(for:)`), `var confirmingSignOut: Bool`, `var signOutWarning: String?` (from `queue.pending.signOutWarning`), `func signOut() async`, `func passwordSet()` (flips `hasPassword`, the toast's words to the caller: "Password set. Use it with your email next time you sign in.").
- `PasswordStore(auth:centres:)`: `var password: String`, `var canSubmit: Bool` (`PasswordRule.isAcceptable`), `private(set) var busy: Bool`, `private(set) var error: String?`, `func submit() async -> Bool` (sets the password, then `setHasPassword()`; a failure's words from `AccountFailure.message`, the field kept), `var title: String` ("Set a password" / "Change password", from `hasPassword`).
- `AccountView(store:actions:boardState:)` to P7-Account: the hero, the methods card (`MethodRow`s: Apple "Connected" in `ok` when `methods` has it, Google likewise, Email code "On", Password "Not set" / "Set" with the chevron), the footnote, the Sign out card (`DestructiveRow`), the Delete section with its footnote; the sign-out dialog (`DialogView`, destructive "Sign out"; with a warning the body is the warning plus "Connect first and they go on their own." and the action reads "Sign out anyway"). `PasswordSheet` (a floating sheet, D28, content height) keeps its `PasswordStore` in `@State`.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct AccountStoreTests {
    func make(queue: ChangeQueue? = nil, auth: FakeAuthRepository = FakeAuthRepository(user: FakeAuthRepository.meera)) -> AccountStore {
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        let q = queue ?? ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id,
                                     directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        return AccountStore(workspace: FakeCentreRepository.meeraWorkspace, auth: auth, centres: centres, queue: q)
    }

    @Test func showsTheTutorAndTheirMethods() async {
        let store = make()
        await store.load()
        #expect(store.name == "Meera Nair" && store.email == "meera.nair@gmail.com" && store.initials == "MN")
        #expect(store.methods == [.apple, .email] && store.hasPassword == false)
    }

    @Test func signOutWarnsWhenChangesWait() throws {
        let queue = ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id,
                                directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        queue.add(QueuedChange(kind: .attendance(classID: nil, className: "Class 10 Maths", date: day, marks: [:], present: 5, total: 6), madeAt: Date()))
        let store = make(queue: queue)
        #expect(store.signOutWarning == "1 saved change hasn't reached the server yet: attendance for Class 10 Maths.")
        #expect(make().signOutWarning == nil)
    }

    @Test func signOutEndsTheSession() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = make(auth: auth)
        await store.signOut()
        #expect(auth.signedOut == 1)
    }
}

@MainActor struct PasswordStoreTests {
    @Test func submitIsRefusedUnderEightCharactersAndSetsThePasswordAndTheFlag() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        let store = PasswordStore(auth: auth, centres: centres, hasPassword: false)
        store.password = "short"
        #expect(!store.canSubmit && store.title == "Set a password")
        store.password = "brightminds2026"
        #expect(store.canSubmit)
        #expect(await store.submit())
        #expect(auth.passwords == ["brightminds2026"] && centres.hasPasswordSet == 1 && store.error == nil)
    }

    @Test func aFailureKeepsThePasswordAndSaysWhy() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = PasswordStore(auth: auth, centres: FakeCentreRepository(), hasPassword: true)
        store.password = "brightminds2026"
        auth.nextAccountFailure = .offline
        #expect(await store.submit() == false)
        #expect(store.password == "brightminds2026" && store.error == "Couldn't set the password. Check your connection and try again.")
        #expect(store.title == "Change password")
    }
}
```

`Tests/AppShellTests/SignOutTests.swift`:

```swift
import AppShell
import Data
import Domain
import Foundation
import Testing

@MainActor struct SignOutTests {
    @Test func signOutWipesTheCachesAndTheQueue() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("signout-\(UUID().uuidString)", isDirectory: true)
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let queue = ChangeQueue(centre: centre, directory: dir)
        queue.add(QueuedChange(kind: .absenceLog(studentID: UUID(), studentName: "Hemanth Reddy", about: try #require(Day(year: 2026, month: 10, day: 7))), madeAt: Date()))
        CachedRead<[String]>(centre: centre, key: "tasks", directory: dir).keep(["x"], at: Date())
        let notifications = FakeNotificationCenter(permission: .allowed)
        await notifications.replace(with: [Reminder(id: "fees-2026-10", kind: .fees, title: "t", body: "b", fireAt: Date(), link: "tutorcentral://fees")])
        let session = SessionStore(deps: Fixtures.dependencies(for: .today), initial: .ready(FakeCentreRepository.meeraWorkspace))
        await session.signOut(wiping: SignOutWipe(centre: centre, directory: dir, queue: queue, notifications: notifications))
        #expect(session.state == .signedOut)
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path).isEmpty)
        #expect(queue.pending.isEmpty && (await notifications.pending()).isEmpty)
    }
}
```

(`SessionStore.signOut(wiping:)` takes a `SignOutWipe` struct holding what to clear; the existing `signOut()` becomes the one AppShell calls with the live wipe.)

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Launch states** `account`, `account-password`, `account-password-failed`, `account-password-saved`, `account-sign-out`, `account-sign-out-pending`; shots both appearances. **Commit** "Account: the methods, a password, sign out that wipes the phone (D40)".

### Task 13: Delete account: the Apple confirmation, the deletion, what follows (PR 5)

**Files:**
- Create: `Features/Settings/Account/DeleteAccountStore.swift`, `DeleteAccountView.swift`, `AppleReauthorizer.swift`
- Modify: `AppShell/RootView+Settings.swift` (the screen; on `.done` the wipe and `session.deleted()`), `AppShell/SessionStore.swift` (`deleted()` → `.signedOut(afterDeletion: true)`: the sign-in landing's banner; `State.signedOut` gains an associated `afterDeletion: Bool`, false everywhere else), `Features/Onboarding/SignIn/SignInView.swift` (the "deleted" banner under the lead when asked)
- Test: `Tests/SettingsTests/DeleteAccountStoreTests.swift`, `Tests/AppShellTests/SessionStoreTests.swift` (one test added)

**Interfaces:**
- `AppleReauthorizer`: `@MainActor final class` wrapping `ASAuthorizationController` with a continuation: `func authorizationCode() async throws(AccountFailure) -> String` (a cancelled sheet throws `.cancelled`, added to `AccountFailure` with no message; a refused one `.appleRefused`). The request asks no scopes.
- `DeleteAccountStore(workspace:register:auth:account:queue:reauthorize:)` where `reauthorize: () async throws(AccountFailure) -> String` is the Apple step (the reauthorizer's method in the app, a closure in tests) and `needsApple: Bool` is whether `methods` has `.apple`:
  - `var typed: String`, `var canDelete: Bool` (`DeletionConfirmation.matches` and not busy), `private(set) var phase: Phase` (`.idle`, `.confirmingWithApple`, `.deleting`, `.failed(String)`, `.done`), `let notices: [String]` (the three lines; the counts from the register; the Apple line only when `needsApple`), `func delete() async`, `func cancel()` (Back while deleting: the task is cancelled; a late answer is dropped), `let centreName: String`.
  - `delete()`: refused while a run is in progress; `phase = .confirmingWithApple` → `reauthorize()` → `account.revokeApple(code:)` → `phase = .deleting` → `auth.deleteAccount()` → `queue.wipe()` → `.done`. A failure at any step before `deleteAccount` succeeded: `.failed(words)`, the tutor still signed in; `.cancelled` from Apple: back to `.idle` silently.
- `DeleteAccountView(store:actions:boardState:)` to P7-Delete: the intro hero (`IntroHero` with the `overdue` tile), the notices card, the error row above the field when failed, the typed field, the solid destructive button (loading while confirming or deleting), the footnote by phase.
- `SignInView` shows `StatusLine("Your account and Bright Minds Tuition's records were deleted.", .ok)` under the lead when `afterDeletion` (the name passed in from the session before the wipe).

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import Settings

@MainActor struct DeleteAccountStoreTests {
    let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
    let account = FakeAccountRepository()

    func make(apple: Bool = true, reauthorize: @escaping () async throws(AccountFailure) -> String = { "code-1" }) -> DeleteAccountStore {
        auth.methods = apple ? [.apple, .email] : [.email]
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(),
            cache: nil, now: { Date() }
        )
        let queue = ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id,
                                directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        return DeleteAccountStore(workspace: FakeCentreRepository.meeraWorkspace, register: register, auth: auth,
                                  account: account, queue: queue, reauthorize: reauthorize)
    }

    @Test func theButtonWaitsForTheCentresNameAndTheNoticesCountTheRegister() async {
        let store = make()
        await store.load()
        #expect(!store.canDelete)
        store.typed = "bright minds tuition"
        #expect(store.canDelete)
        #expect(store.notices.first == "10 students with their fees and attendance, 2 classes, your events, tasks, notes and everything created with AI.")
        #expect(store.notices.count == 3 && store.needsApple)
        let email = make(apple: false)
        await email.load()
        #expect(email.notices.count == 2 && !email.needsApple)
    }

    @Test func deleteConfirmsWithAppleRevokesThenDeletesThenIsDone() async {
        let store = make()
        await store.load()
        store.typed = "Bright Minds Tuition"
        await store.delete()
        #expect(account.revoked == ["code-1"] && auth.deleted == 1 && store.phase == .done)
    }

    @Test func aFailedDeleteAfterAppleKeepsTheTutorSignedInAndRetries() async {
        let store = make()
        await store.load()
        store.typed = "Bright Minds Tuition"
        auth.nextAccountFailure = .offline
        await store.delete()
        #expect(store.phase == .failed("Couldn't delete your account. Check your connection and try again. Nothing was removed; you are still signed in."))
        #expect(store.typed == "Bright Minds Tuition" && auth.user != nil && account.revoked == ["code-1"])
        await store.delete()
        #expect(account.revoked == ["code-1", "code-1"] && auth.deleted == 1 && store.phase == .done)
    }

    @Test func appleCancelledGoesBackQuietlyAndAppleRefusedSaysSo() async {
        let cancelled = make(reauthorize: { throw AccountFailure.cancelled })
        await cancelled.load()
        cancelled.typed = "Bright Minds Tuition"
        await cancelled.delete()
        #expect(cancelled.phase == .idle && auth.deleted == 0)
        let refused = make()
        await refused.load()
        refused.typed = "Bright Minds Tuition"
        account.nextFailure = .appleRefused
        await refused.delete()
        #expect(refused.phase == .failed("Apple didn't accept the confirmation. Try again."))
    }

    @Test func aLocalSignOutFailureStillEndsSignedOut() async {
        // The fake's deleteAccount ends the local session itself; the store's done phase does not depend on signOut.
        let store = make(apple: false)
        await store.load()
        store.typed = "Bright Minds Tuition"
        await store.delete()
        #expect(store.phase == .done && auth.user == nil)
    }
}
```

`SessionStoreTests` gains:

```swift
@Test func aDeletedUsersSessionBecomesSignedOut() async {
    let deps = Fixtures.dependencies(for: .signin)
    let session = SessionStore(deps: deps, initial: .loading)
    guard let auth = deps.auth as? FakeAuthRepository else { Issue.record("not the fake"); return }
    auth.user = FakeAuthRepository.meera
    await session.start()
    auth.emit(nil)   // Supabase's refresh of a deleted user's token fails and announces a sign-out
    try? await Task.sleep(for: .milliseconds(20))
    #expect(session.state == .signedOut(afterDeletion: false))
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Launch states** `delete-account`, `delete-account-typed`, `delete-account-deleting` (the fixture's reauthorize never answers), `delete-account-failed`, `signin-deleted`; shots. **Step 6:** the Delete account write proof in the simulator against the local stack (Task 22's run 5) before merging PR 5. **Commit** "Delete account: Apple confirmed, the account deleted, the phone wiped, the landing says so". Then `bun check`, push, pull request 5 with its pictures, merge.

### Task 14: Offline reads: every root from its cache, the bar with its age (PR 6)

**Files:**
- Modify: `Features/Today/TodayStore.swift` (+`TodayStore+Cache.swift`), `Features/Fees/FeesStore.swift`, `Features/Attendance/AttendanceStore.swift`, `HistoryStore.swift`, `Features/Schedule/ScheduleStore.swift`, `Features/Today/TasksStore.swift`, `Features/AITools/AIStore.swift` (history), each taking an optional `CachedRead` of its list; the root views (`TodayView`, `StudentsView`, `FeesView`, `AttendanceView`, `HistoryView`, `ScheduleView`, `TasksView`, `HistoryView` (AI)) taking `statusLine: StatusLineModel?` drawn under the title; `AppShell/Dependencies.swift` (`connectivity: any ConnectivityMonitor`, `cachesLists: Bool`), `AppShell/Fixtures.swift` (fakes: `FakeConnectivity`, `cachesLists: false`)
- Create: `AppShell/RootView+Offline.swift` (`statusLine(for:)` from the monitor and a root's `savedAt`), `DesignSystem/Components/StatusLine.swift` already exists (Task 11); `StatusLineModel` (text, symbol, tone, spinner, action, chevron) in DesignSystem
- Test: `Tests/TodayTests/TodayCacheTests.swift`, `Tests/FeesTests/FeesCacheTests.swift`, `Tests/AppShellTests/StatusLineTests.swift`

**Interfaces:**
- Each store: `public private(set) var savedAt: Date?` (the cache's time when the screen shows a cached value and the refresh has not replaced it), `public private(set) var offlineRead: Bool` (the last refresh failed with a transport error). The pattern in `load()`: before the network, `if let cached = cache?.load() { apply(cached.value); savedAt = cached.savedAt; loaded = true }`; after a successful read `cache?.keep(value, at: now()); savedAt = nil; offlineRead = false`; on failure `offlineRead = TransportError.isOffline(error)` and the words: with a cached value shown, the error line is not shown (the bar says it); with nothing cached, the existing error line and Retry (`offline-no-cache` shows the empty card instead when the monitor says offline).
- Keys: `today-counts` (`TodayCounts` + the month's sessions + the week's events as one `TodaySnapshot`), `fees-<yyyy-MM>` (`FeesSnapshot`: invoices, dueBefore, logs), `attendance-today` (the day's saved session, by class), `history-<yyyy-MM>`, `events` (14 days), `tasks`, `ai-history`.
- `RootView.statusLine(for root: RootKind) -> StatusLineModel?`: offline (the monitor, or the root's `offlineRead`) → `.offline(savedAt:)` ("Offline. Showing what was saved at 14:10." via `CacheAge.words`; "Offline. Nothing saved on this iPhone yet." with no `savedAt`); the runner's state wins over it (Task 16).

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

@MainActor struct TodayCacheTests {
    func dir() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("today-\(UUID().uuidString)", isDirectory: true) }

    @Test func aCachedScreenShowsAtOnceWithItsTimeAndIsReplacedByTheNetwork() async {
        let folder = dir()
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let savedAt = Date(timeIntervalSince1970: 1_791_626_400)
        CachedRead<TodaySnapshot>(centre: centre, key: "today", directory: folder)
            .keep(TodaySnapshot(counts: TodayCounts(students: 9, feesDue: Money(rupees: 3000), classesToday: 1), sessions: [], events: []), at: savedAt)
        let counts = FakeCountsRepository()
        let store = TodayStore.forTests(counts: counts, cacheDirectory: folder)
        store.showCached()
        #expect(store.counts.students == 9 && store.savedAt == savedAt)
        await store.load()
        #expect(store.counts == counts.counts && store.savedAt == nil && store.offlineRead == false)
        #expect(CachedRead<TodaySnapshot>(centre: centre, key: "today", directory: folder).load()?.value.counts == counts.counts)
    }

    @Test func anOfflineRefreshKeepsTheCachedValueAndSaysOffline() async {
        let folder = dir()
        let counts = FakeCountsRepository()
        let store = TodayStore.forTests(counts: counts, cacheDirectory: folder)
        await store.load()   // fills the cache
        counts.nextError = URLError(.notConnectedToInternet)
        let again = TodayStore.forTests(counts: counts, cacheDirectory: folder)
        again.showCached()
        await again.load()
        #expect(again.counts == counts.counts && again.savedAt != nil && again.offlineRead && again.error == nil)
    }
}
```

(`TodayStore.forTests` is a test-only factory in the test target, as `TodayStoreTests` already builds the store; `showCached()` is the first thing `TodayView.task` calls before `load()`. `FeesCacheTests` is the same shape on `FeesStore.open(month:)` with the key `fees-2026-10`.)

`StatusLineTests`:

```swift
import AppShell
import Data
import Domain
import Foundation
import Testing

struct StatusLineTests {
    let calendar = DayHeading.india
    @Test func offlineWordsNameTheCacheOrItsAbsence() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()
        let saved = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 14, minute: 10)) ?? Date()
        #expect(StatusLineModel.offline(savedAt: saved, now: now, calendar: calendar).text == "Offline. Showing what was saved at 14:10.")
        #expect(StatusLineModel.offline(savedAt: nil, now: now, calendar: calendar).text == "Offline. Nothing saved on this iPhone yet.")
        #expect(StatusLineModel.sending(3).text == "Back online. Sending 3 saved changes…" && StatusLineModel.sending(3).spinner)
        #expect(StatusLineModel.failed(1).text == "1 saved change couldn't be sent." && StatusLineModel.failed(2).text == "2 saved changes couldn't be sent.")
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass. The root views draw `StatusLine` from the model between the title and the content (P7-Offline-Today, -Students, -Fees); `StudentsView` uses the register's existing cache age (`RegisterStore` gains `savedAt` the same way). `offline-no-cache`: Fees with the monitor offline and no cache shows `EmptyRow("Nothing saved here yet", …, Try again)` in the ledger card. Offline, `FeesView` disables Remind, Generate and the AI rows (`Create with AI` on Today) at the disabled opacity; `StudentsView`'s "+" stays live.

- [ ] **Step 5: Launch states** `offline-today`, `offline-students`, `offline-fees`, `offline-no-cache` (the fixtures: `FakeConnectivity(online: false)` and a cache written by the fixture at 14:10 of the board day into a temporary directory the fixture names). **Commit** "Offline reads: every root from its cache, the bar with its age".

### Task 15: The three queued writes: attendance, Mark paid, the absence alert's log; writes refused offline (PR 6)

**Files:**
- Modify: `Features/Attendance/AttendanceStore.swift` (`save()` and the alert's log through the queue when offline or when the queue holds that kind), `AttendanceView.swift` (the footer's "Saved on this iPhone" mark and the `due` banner from `phase == .savedHere(at:)`), `Features/Fees/FeesStore+Writes.swift` (`markPaid` through the queue; `undoPaid` of a queued one removes it), `FeesSections.swift` (the row's "kept here" line), the form stores that refuse offline: `Students/StudentFormStore`, `ClassFormStore`, `Schedule/EventFormStore`, `Today/TasksStore` (add), `Settings/SettingsStore`, `PaymentsStore` (each `guard online else { message = <refused words>; return }` before the write, with the words from `OfflineRefusal.words(for:)` in Domain: "You're offline. Adding a student needs a connection; nothing was saved." and the like)
- Create: `Domain/Queue/OfflineRefusal.swift`
- Test: `Tests/AttendanceTests/AttendanceQueueTests.swift`, `Tests/FeesTests/FeesQueueTests.swift`, `Tests/StudentsTests/OfflineRefusalTests.swift`

**Interfaces:**
- The stores take `queue: any ChangeQueueing` and `online: @escaping @Sendable () async -> Bool` (AppShell passes the monitor's `isOnline`).
- `AttendanceStore.Phase` gains `.savedHere(at: Date)`; `save()`: when `!online()` or `queue.pending.has(kind: .attendance)`, builds the `QueuedChange` (the class name from the register, present and total from the draft), `queue.add`, `phase = .savedHere(at: now())`, `saved` set from the draft so the screen reads as saved; the banner "Saved on this iPhone at 17:05. It reaches the server when you're back online." (tone `due`, `clock`); the footer mark "Saved on this iPhone" in the `due` tone. The alert's `openWhatsApp(for:)`: offline, the log goes to the queue (`.absenceLog`) and the URL is still returned.
- `FeesStore.markPaid`: when offline or the queue holds `.markPaid`, `queue.add(.markPaid(...))`, the invoice replaced locally with a paid copy (`FeeInvoice` with `status .paid`, `paidAt`, `paidMethod`) and marked in `keptHere: Set<UUID>`, the toast "Dev's fee marked paid here. It's sent when you're back online." with Undo; `undoPaid` of an id in `keptHere` removes the change and restores the row without a server call; the row's line "Paid by UPI on 7 Oct · Kept on this iPhone until you're online" in `due`. The receipt sheet is not offered offline (WhatsApp would open but the log cannot queue a receipt in this build: the toast says sent later).
- `OfflineRefusal.words(for: Write) -> String` with `enum Write { case addStudent, editStudent, addClass, editClass, addEvent, editEvent, addTask, editSettings, editPayments, generateFees, waiveFee, remind, note }`.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct AttendanceQueueTests {
    func make(online: Bool, queue: ChangeQueue) -> AttendanceStore {
        AttendanceStore.forTests(queue: queue, online: { online })
    }
    func queue() -> ChangeQueue {
        ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id,
                    directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @Test func offlineASaveIsKeptHereAndTheScreenReadsSaved() async {
        let q = queue()
        let store = make(online: false, queue: q)
        await store.load()
        store.toggle(store.rows.first?.student.id ?? UUID())
        #expect(await store.save())
        #expect(q.pending.waitingCount == 1)
        if case .savedHere = store.phase {} else { Issue.record("not savedHere: \(store.phase)") }
        #expect(store.bannerText?.hasPrefix("Saved on this iPhone at ") == true)
    }

    @Test func onlineButWithASaveWaitingTheNewSaveJoinsTheQueue() async throws {
        let q = queue()
        let day = try #require(Day(year: 2026, month: 10, day: 6))
        q.add(QueuedChange(kind: .attendance(classID: nil, className: "All students", date: day, marks: [:], present: 6, total: 6), madeAt: Date()))
        let store = make(online: true, queue: q)
        await store.load()
        store.toggle(store.rows.first?.student.id ?? UUID())
        #expect(await store.save())
        #expect(q.pending.waitingCount == 2)
    }

    @Test func offlineTellParentStillOpensWhatsAppAndQueuesTheLog() async {
        let q = queue()
        let store = make(online: false, queue: q)
        await store.load()
        let absent = store.rows.first?.student.id ?? UUID()
        store.toggle(absent)
        _ = await store.save()
        let url = await store.openWhatsApp(for: absent)
        #expect(url != nil && q.pending.changes.contains { if case .absenceLog = $0.kind { true } else { false } })
    }
}
```

```swift
import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct FeesQueueTests {
    @Test func offlineMarkPaidIsKeptHereAndUndoRemovesIt() async throws {
        let q = ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id,
                            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let fees = FakeFeesRepository()
        let store = FeesStore.forTests(fees: fees, queue: q, online: { false })
        await store.load()
        let due = try #require(store.invoices.first { $0.status == .due })
        #expect(await store.markPaid(due.id, method: .upi, on: store.today))
        #expect(fees.paid.isEmpty && q.pending.waitingCount == 1)
        #expect(store.invoice(due.id)?.status == .paid && store.keptHere.contains(due.id))
        #expect(store.undo?.text == "\(store.firstName(of: due))'s fee marked paid here. It's sent when you're back online.")
        #expect(await store.undoPaid(due.id))
        #expect(q.pending.isEmpty && store.invoice(due.id)?.status == .due && fees.undone.isEmpty)
    }
}
```

```swift
import Domain
import Testing

struct OfflineRefusalTests {
    @Test func everyRefusedWriteIsNamed() {
        #expect(OfflineRefusal.words(for: .addStudent) == "You're offline. Adding a student needs a connection; nothing was saved.")
        #expect(OfflineRefusal.words(for: .generateFees) == "You're offline. Creating the month's fees needs a connection; nothing was created.")
        #expect(OfflineRefusal.words(for: .remind) == "You're offline. Reminders need a connection to be noted on the fee.")
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass (`AttendanceStore.forTests` and `FeesStore.forTests` are test-target factories as the existing tests build them, with the register fake). **Step 5: Launch states** `offline-write-refused` (the student sheet filled, the toast shown by the fixture on appear), `offline-attendance-saved`, `offline-fee-marked`; shots. **Commit** "Offline writes: attendance, Mark paid and the absence alert queue; everything else is refused in words (D39)".

### Task 16: AppShell: the runner's banners and toasts, Pending changes (PR 6)

**Files:**
- Create: `Features/Settings/Pending/PendingChangesStore.swift`, `PendingChangesView.swift`; `AppShell/RootView+Offline.swift` (the runner on `ShellState`, `shell.queue`, `shell.runner`, when it runs, `runState`, the toasts)
- Modify: `AppShell/ShellState.swift` (`queue: ChangeQueue?`, `runner: QueueRunner?`, `runState: RunState` (`.idle`, `.sending(Int)`, `.failed(Int)`, `.signedOut`)), `RootView.swift` (`.task` observing `connectivity.changes()`; `scenePhase == .active` runs; `session.signedIn` runs), `RootView+Settings.swift` (the Pending changes screen), `TabsView.swift` (the Settings row count)
- Test: `Tests/SettingsTests/PendingChangesStoreTests.swift`, `Tests/AppShellTests/RunStateTests.swift`

**Interfaces:**
- `ShellState.runState` feeds `statusLine(for:)` (Task 14) on every root: `.sending(n)` → `StatusLineModel.sending(n)`; `.failed(n)` → `.failed(n)` with the chevron pushing `.pendingChanges`; `.signedOut` → "Sign in again to send your saved changes." (tone `due`), until the next sign-in; `.idle` → the offline line or nothing.
- `RootView.runQueue(reason:)`: `guard let runner = shell.runner, await deps.connectivity.isOnline, !runner.queue.pending.inOrder.isEmpty`; `runState = .sending(count)`; `let outcome = await runner.run()`; `.done(sent, failed)`: a toast "N saved changes sent." ("1 saved change sent.") when `sent > 0`, `runState = failed > 0 ? .failed(failed) : .idle`; `.offline(sent)`: the toast for `sent` if any, `runState = .idle` (the offline line returns); `.signedOut`: `runState = .signedOut`. The failed state recomputes from `queue.pending.failedCount` whenever the queue changes (a discard clears it).
- `PendingChangesStore(queue:runner:calendar:)`: `var rows: [QueuedChange]` (all, in the order made, waiting and failed), `func discard(id:)` (after the dialog), `func sendAgain() async -> RunOutcome?` (`queue.retryAll()` then `runner.run()`), `var confirmingDiscard: UUID?`, `func discardWords(for:) -> (title: String, body: String)` ("Discard this change?", "Dev's October fee stays as the server has it: due. The mark you made here is lost." / "Attendance for Class 10 Maths on Wed 7 Oct stays as the server has it. What you marked here is lost." / "The absence alert for Hemanth isn't noted on his page.").
- `PendingChangesView(store:boardState:)` to P7-Pending: the footnote under the nav row, the card of `PendingRow`s, the footer band with Send again (disabled while sending or when nothing is failed or waiting) and the footnote; empty (everything sent): pops back by the caller with the toast.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct PendingChangesStoreTests {
    func make() throws -> (ChangeQueue, QueueRunner, PendingChangesStore) {
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let queue = ChangeQueue(centre: centre, directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let fees = FakeFeesRepository()
        let runner = QueueRunner(queue: queue, centre: centre, attendance: FakeAttendanceRepository(), fees: fees, messages: FakeMessageLogRepository())
        let gone = QueuedChange(kind: .markPaid(invoiceID: UUID(), studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
                                                amount: Money(rupees: 1000), method: .upi, paidAt: Date()), madeAt: Date())
        queue.add(gone)
        queue.fail(id: gone.id, reason: "Dev Kumar is no longer in the register, so his fee can't be marked. Keep it here or discard it.")
        return (queue, runner, PendingChangesStore(queue: queue, runner: runner, calendar: DayHeading.india))
    }

    @Test func rowsShowEveryChangeWithItsStateAndDiscardRemovesOne() throws {
        let (queue, _, store) = try make()
        #expect(store.rows.count == 1 && store.rows.first?.state != .waiting)
        let id = try #require(store.rows.first?.id)
        #expect(store.discardWords(for: id).body == "Dev's October fee stays as the server has it: due. The mark you made here is lost.")
        store.discard(id: id)
        #expect(queue.pending.isEmpty && store.rows.isEmpty)
    }

    @Test func sendAgainRetriesTheFailedOnes() async throws {
        let (queue, _, store) = try make()
        let outcome = await store.sendAgain()
        // The invoice is unknown to the fake, so it is refused again and stays failed.
        #expect(outcome == .done(sent: 0, failed: 1) && queue.pending.failedCount == 1)
    }
}
```

```swift
import AppShell
import Data
import Testing

struct RunStateTests {
    @Test func theOutcomeBecomesTheStateAndTheToast() {
        #expect(RunState.after(.done(sent: 3, failed: 0)) == .idle)
        #expect(RunState.after(.done(sent: 1, failed: 2)) == .failed(2))
        #expect(RunState.after(.offline(sent: 1)) == .idle)
        #expect(RunState.after(.signedOut(sent: 0)) == .signedOut)
        #expect(RunState.toast(for: .done(sent: 3, failed: 0)) == "3 saved changes sent.")
        #expect(RunState.toast(for: .done(sent: 1, failed: 1)) == "1 saved change sent.")
        #expect(RunState.toast(for: .done(sent: 0, failed: 1)) == nil)
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Launch states** `sync-sending` (the fixture's runner held by a delay), `sync-sent` (the toast on appear), `sync-failed`, `pending`, `pending-discard`; shots. **Step 6:** the offline hand runs (Task 22, runs 7 to 10) before merging. **Commit** "Back online: sending, sent, a failure; Pending changes with Discard and Send again". Then `bun check`, push, pull request 6, merge.

### Task 17: Teacher reminders, the scheduler, the notification delegate, Help (PR 7)

**Files:**
- Create: `Features/Settings/Reminders/RemindersStore.swift`, `RemindersView.swift` (+`RemindersView+Cards.swift`), `Features/Settings/Help/HelpView.swift`, `AppShell/ReminderScheduler.swift`, `AppShell/AppDelegate.swift`, `Data/Notifications/ReminderSettingsStore.swift` (the `UserDefaults` JSON under `reminders`; `reminders.asked` when the system was asked)
- Modify: `ios/App/TutorCentralApp.swift` (`@UIApplicationDelegateAdaptor(AppDelegate.self)`), `AppShell/RootView.swift` (`NotificationDelegate.shared.onOpen` → the `DeepLink` path; the scheduler on foreground, after sign-in and when the stores' `onChanged` hooks fire), `AppShell/Dependencies.swift` (`notifications: any NotificationCenterClient`), `AppShell/Fixtures.swift`
- Test: `Tests/SettingsTests/RemindersStoreTests.swift`, `Tests/AppShellTests/ReminderSchedulerTests.swift`

**Interfaces:**
- `ReminderSettingsStore` (Data): `func load() -> ReminderSettings`, `func save(_:)`, `var asked: Bool { get set }`; a `UserDefaults` suite in tests.
- `RemindersStore(notifications:settingsStore:plan:)` where `plan: @escaping @Sendable () async -> [Reminder]` is the scheduler's plan for "Next:" and the count: `private(set) var permission: NotificationPermission`, `var settings: ReminderSettings` (saved on every change, then `onChanged()` so the scheduler replaces), `private(set) var scheduled: [Reminder]`, `var banner: BannerWords` (the four texts of the board from the permission and `settings.anyOn`: `.on(next:)`, `.allOff`, `.refused`, `.notAsked` (no banner)), `func turnOn() async` (asks; allowed → `permission = .allowed`, the first plan; refused → `.refused`), `func refresh() async`, `var onThisPhone: (count: String, through: String)` ("14 reminders set" / "No reminders set" / "Nothing set", "through Fri 23 Oct"), `func openSettings()` through the actions (`UIApplication.openNotificationSettingsURLString`).
- `RemindersView(store:actions:boardState:)` to P7-Reminders-*: not asked (the intro hero, Turn on reminders, the footnote, the three switch rows dimmed), on (the `ok` line, the three cards with `SwitchRow` and `TileRow`s, the On this iPhone card with Refresh, the footnote), all off, refused (the `due` line with Open Settings, the cards dimmed), the day picker (`WheelPopover` from the tile, 1st to 28th), the minutes and hours pickers (`WheelPopover` of `ReminderSettings.classLeads` as "5 min" … "1 hour", and the event leads).
- `ReminderScheduler` (AppShell, `@MainActor`): `init(notifications:settingsStore:register:events:fees:now:calendar:)`; `func replan(workspace:) async -> [Reminder]` (reads `register.activeClasses` and member counts from `register.activeStudents`, the events of the next 14 days, this month's invoices for the due count and total; plans; `notifications.replace(with:)` only when the permission is allowed; answers the plan); refused while one runs (a second call waits for the first and answers its plan). Called by RootView on `scenePhase == .active` once the session is ready, after `session.signedIn`, after any `onFeesChanged`, `onEventsChanged`, `onClassesChanged` (the existing hooks), and by the Reminders screen's `onChanged`.
- `AppDelegate` (`UIResponder, UIApplicationDelegate`): in `didFinishLaunchingWithOptions` sets `UNUserNotificationCenter.current().delegate = NotificationDelegate.shared` (the reason in the file: the delegate must exist before the first notification response is delivered, which can be the launch itself).
- `HelpView(version:actions:boardState:)` to P7-Help: the hero, Email (the `mailto:` through `openURL` with the subject "Tutor Central 1.0 (14), iPhone"), the footnote, the four `DisclosureRow`s (one open at a time, `@State`), the version line.

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct RemindersStoreTests {
    func make(_ center: FakeNotificationCenter, settings: ReminderSettings = ReminderSettings(), plan: [Reminder] = []) throws -> RemindersStore {
        let defaults = try #require(UserDefaults(suiteName: "reminders-\(UUID().uuidString)"))
        let store = ReminderSettingsStore(defaults: defaults)
        store.save(settings)
        return RemindersStore(notifications: center, settingsStore: store, plan: { plan })
    }
    let next = Reminder(id: "class-x-2026-10-07", kind: .classMeeting, title: "Class 10 Maths at 17:00", body: "b",
                        fireAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 45)) ?? Date(),
                        link: "tutorcentral://attendance")

    @Test func beforeTheAskThereIsNoBannerAndTurnOnAsksOnce() async throws {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        let store = try make(center, plan: [next])
        await store.load()
        #expect(store.permission == .notAsked && store.banner == nil)
        await store.turnOn()
        #expect(center.asked == 1 && store.permission == .allowed && center.replacements == 1)
        #expect(store.banner == .on(next: "Class 10 Maths, today at 16:45"))
    }

    @Test func refusedShowsOpenSettingsAndKeepsTheSwitches() async throws {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: false)
        let store = try make(center)
        await store.load()
        await store.turnOn()
        #expect(store.permission == .refused && store.banner == .refused && store.settings.classOn)
        #expect(store.onThisPhone.count == "Nothing set")
    }

    @Test func allOffSaysSoAndAChangeIsSavedAndReplanned() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        var off = ReminderSettings()
        off.classOn = false
        off.eventOn = false
        off.feesOn = false
        let store = try make(center, settings: off)
        await store.load()
        #expect(store.banner == .allOff && store.onThisPhone.count == "No reminders set")
        var changed = 0
        store.onChanged = { changed += 1 }
        store.settings.feesDay = 10
        #expect(changed == 1)
    }

    @Test func theCountAndTheLastDayReadAsTheBoard() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let later = Reminder(id: "fees-2026-10", kind: .fees, title: "t", body: "b",
                             fireAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 9)) ?? Date(), link: "l")
        let store = try make(center, plan: [next, later])
        await store.load()
        #expect(store.onThisPhone.count == "2 reminders set" && store.onThisPhone.through == "through Fri 23 Oct")
    }
}
```

```swift
import AppShell
import Data
import Domain
import Foundation
import Students
import Testing

@MainActor struct ReminderSchedulerTests {
    @Test func replanReadsTheRegisterTheEventsAndTheDueFeesAndReplacesWhenAllowed() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let defaults = try #require(UserDefaults(suiteName: "sched-\(UUID().uuidString)"))
        let workspace = FakeCentreRepository.meeraWorkspace
        let register = RegisterStore(workspace: workspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(), cache: nil, now: { Date() })
        let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 9)) ?? Date()
        let scheduler = ReminderScheduler(
            notifications: center, settingsStore: ReminderSettingsStore(defaults: defaults), register: register,
            events: FakeEventsRepository(), fees: FakeFeesRepository(), now: { now }, calendar: DayHeading.india
        )
        let plan = await scheduler.replan(workspace: workspace)
        #expect(!plan.isEmpty && center.replacements == 1 && (await center.pending()) == plan)
        #expect(plan.contains { $0.kind == .classMeeting } && plan.contains { $0.kind == .fees })
    }

    @Test func nothingIsScheduledWithoutThePermission() async throws {
        let center = FakeNotificationCenter(permission: .notAsked)
        let defaults = try #require(UserDefaults(suiteName: "sched-\(UUID().uuidString)"))
        let workspace = FakeCentreRepository.meeraWorkspace
        let register = RegisterStore(workspace: workspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(), cache: nil, now: { Date() })
        let scheduler = ReminderScheduler(
            notifications: center, settingsStore: ReminderSettingsStore(defaults: defaults), register: register,
            events: FakeEventsRepository(), fees: FakeFeesRepository(), now: { Date() }, calendar: DayHeading.india
        )
        _ = await scheduler.replan(workspace: workspace)
        #expect(center.replacements == 0)
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: The link from a tap:** `RootView` sets `NotificationDelegate.shared.onOpen = { url in openLink(url) }` in its `.task`, where `openLink` is the body of the existing `onOpenURL` closure, moved into a method; a tap while signed out is kept by the delegate and delivered once `session.isReady` (the delegate keeps one URL; RootView sets `onOpen` again when the session becomes ready). **Step 6: Launch states** `reminders-not-asked`, `reminders`, `reminders-all-off`, `reminders-refused`, `reminders-day-picker`, `help`, `help-answer`; shots. **Step 7:** the reminder hand run (Task 22, run 6) before merging. **Commit** "Teacher reminders, the scheduler, the notification delegate, Help". Then `bun check`, push, pull request 7, merge.

### Task 18: Hardening: Dynamic Type, VoiceOver, reduced motion, the Kit, error wording, older screens (PR 8)

**Files:**
- Create: `DesignSystem/Modifiers/ReducedMotion.swift`, `docs/design/accessibility-pass.md` (the record of this pass: each screen at `accessibility-extra-large`, what reflowed, what was fixed)
- Modify: every root and form view found wanting by the pass (expected: `StatTile` rows → `ViewThatFits` stacking at AX sizes; the attendance pill row → the pill under the name at AX sizes; the Fees row's two buttons → one under the other; `MoneyPair` → stacked; the tab labels (the system's); `DialogView` buttons stacked at AX sizes); `Pressable.swift`, `Toast.swift`, `Skeleton.swift`, `MoneyPair.swift`'s number roll (`contentTransition` off under reduced motion); rows missing `accessibilityElement(children: .combine)` or a label (the pass lists them); `Keyboard.dismiss()` before a toast on the Phase 3 to 5 sheets (U9's cause: the sheets' Save puts the keyboard away first; the toast draws above the sheet's bottom); the error strings the review changes
- Test: `Tests/DesignSystemTests/ReducedMotionTests.swift` (the modifier reads the environment and the durations collapse to zero), `Tests/DomainTests/ErrorWordsTests.swift` (every error string in the app, collected into one `ErrorWords` table in Domain, is reviewed against the rule: an offline sentence only for offline, "nothing was saved/used up" only where true; the test pins the table's count and the two rules)

**Interfaces:**
- `View.reducedMotionAware()`: the app's own transitions (`pressable`, toasts in and out, the skeleton's breathe, `numericText`) become instant when `accessibilityReduceMotion` is on; the system's own (sheets, pushes) follow the device.
- `enum ErrorWords` (Domain): every user-facing failure string of the app as a `static let`, grouped by feature, each with a doc comment naming when it shows; the features reference these instead of literals (a mechanical move; the strings do not change except those the review corrects, listed in the pull request).

- [ ] **Step 1: The Dynamic Type pass.** From a Debug build on the fakes: `xcrun simctl ui booted content_size accessibility-extra-large` (and `extra-extra-extra-large`), then `bun shots` for `today`, `students`, `student`, `student-new-filled`, `fees`, `fees-mark-paid`, `attendance`, `attendance-saved`, `history`, `schedule`, `event-new`, `tasks`, `more`, `settings`, `account`, `delete-account`, `reminders`, `help`, `pending`, `ai-assistant`, `ai-paper`, `ai-result-paper`, `check-result`, `scan-review`, `signin`, `signin-email`, `onboarding` into `.shots/ax/`; look at each; list in `docs/design/accessibility-pass.md` what truncates, overlaps or clips. Reset with `xcrun simctl ui booted content_size large`.
- [ ] **Step 2: Fix each finding** with the reflow the guidelines ask for (rows grow; a trailing value wraps under its title; two buttons stack; nothing truncates but a trailing value). Re-shoot the fixed states at the AX size and at the default (nothing may change at the default: compare with the merged `pr-shots` pictures). Both appearances.
- [ ] **Step 3: VoiceOver labels.** `grep -rn "Image(systemName:" ios/TutorCentralKit/Sources/Features ios/TutorCentralKit/Sources/DesignSystem` and check each sits in a labelled control or is `accessibilityHidden(true)`; every `IconButton` has its label (it takes one); rows with several texts get `accessibilityElement(children: .combine)`; a status chip's word is in its label; the attendance pill reads "Present, button, toggles to absent". The simulator cannot speak: the tester's D1 does. Write the list of changed controls in `accessibility-pass.md`.
- [ ] **Step 4: Reduced motion.** `ReducedMotionTests` first (`ReducedMotion.duration(_ token: Duration, reduce: Bool) -> Duration` answers `.zero` when reduced), then the modifier and its use in the four places; check in the simulator with `xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionEnabled -bool true` (then the app relaunched; the screenshot shows no skeleton breathing and the toast at rest at once).
- [ ] **Step 5: The Kit in both appearances.** `bun shots kit`, `kit-fields`, `kit-surfaces`, `kit-patterns`, `kit-dialog` (both); compare with `Kit-Controls-*`, `Kit-Surfaces-*`; add the Phase 7 parts to the Kit's patterns section (`KitSurfaces` gains the status lines, the method row, the destructive row, the pending row, the wheel popover) and re-shoot. Differences from the boards are fixed or, when the board is wrong, written down in `components.md`'s "As built".
- [ ] **Step 6: Error wording.** `ErrorWordsTests` first: a test that `ErrorWords.all` has one entry per feature failure (the count the move produced) and that no entry outside `ErrorWords.offline` contains "offline" or "connection" while promising nothing was saved unless its name ends in `Refused` (the offline refusals). Then move every literal to the table; correct the ones the review finds (expected: Settings' "Couldn't save." now names the field (Task 11); the AI tools' "Nothing was used up" only on the offline and the 4xx paths, not the timeout (already, #62); the Phase 5 "Couldn't undo. X's fee stays paid." stays). The table in the pull request.
- [ ] **Step 7: Older screens' keyboards and toasts** (hardening's "look for the same"): on every sheet with a field, Save calls `Keyboard.dismiss()` before its write so a failure toast is seen (U9's cause); the toast host on a sheet sits above the sheet's bottom inset. The polish slice (U6, U7, U9's board, U16, U24) and Phase 6's minors 1, 6 and 7 are Phase 8's, not this phase's (the owner, 2026-10-09): this step fixes only the keyboard-before-toast cause on the older sheets and takes nothing from the list.
- [ ] **Step 8: Google's mark** (the owner's call, offered): replace the hand-drawn "G" on the sign-in landing with Google's official sign-in logo (the SVG "G" from Google's identity guidelines, in the asset catalogue, 20 pt, unchanged button) when the owner says so; the landing re-shot in both appearances.
- [ ] **Step 9: Commit** "Hardening: Dynamic Type, VoiceOver, reduced motion, the Kit, error words" with the pictures: each changed state at the default size and at `accessibility-extra-large`, both appearances.

### Task 19: The launch screen, the icon in place, version 1.0.0 (PR 8)

**Files:**
- Modify: `ios/App/Info.plist` (`UILaunchScreen` → `{ UIColorName: LaunchGround, UIImageName: LaunchBook, UIImageRespectsSafeAreaInsets: false }`, `ITSAppUsesNonExemptEncryption: false`), `ios/App/Assets.xcassets` (`LaunchGround.colorset` #131110 for any appearance; `LaunchBook.imageset` the book from `docs/design/mockups/AppIcon.svg` at 88 pt in #FFAB38, as a PDF or 1x/2x/3x PNGs), `ios/project.yml` (`MARKETING_VERSION: "1.0.0"`), `tools/check/steps.ts` if the smoke test reads the version
- Test: `ios/SmokeTests` (the launch smoke already runs; the version read from the bundle equals "1.0.0" in `SettingsStore` through `Dependencies.live`: a test in `AppShellTests` on `Dependencies.version(from:)` given a dictionary)

- [ ] **Step 1:** the test `Dependencies.version(from: ["CFBundleShortVersionString": "1.0.0", "CFBundleVersion": "14"]) == "1.0.0 (14)"` (a small pure function the live initialiser uses); the Settings and Help rows show it. **Step 2:** the assets and the plist; `bun gen`; the simulator's launch shows the dark ground and the book (a screenshot taken 100 ms after `simctl launch` with the app terminated first: `xcrun simctl terminate booted in.tutorcentral.app; xcrun simctl launch booted in.tutorcentral.app & sleep 0.15; xcrun simctl io booted screenshot .shots/launch.png`); the home screen screenshot after `xcrun simctl io booted screenshot` with the app closed shows the icon with its label (no launch state: the picture goes in the pull request as `launch` and `home`). **Step 3: Commit** "The launch screen, version 1.0.0, no export question".

### Task 20: `docs/release.md`, the release checklist (PR 8)

**Files:**
- Create: `docs/release.md`

- [ ] **Step 1: Write the checklist**, each line a box: `main` green and every PR of the phase merged; no migration pending (`gh workflow run deploy`'s summary); the API's `/health` commit is `main`'s head; `bun check --fresh` green locally; the D32 hand run of every write path done and its screenshots on the phase's issue; `MARKETING_VERSION` set; `gh workflow run testflight` and the build number noted; the internal group installed it; the tester's `docs/testing/device-tests.md` lines for this build all Pass (or each Fail has its fix merged and a new build); App Store Connect: the app's privacy policy URL (`https://tutorcentral.in/privacy`, Phase 8 live), the test information and feedback email (`hello@tutorcentral.in`), the external group made and the build added, Beta App Review submitted and approved; release notes written in this file under "1.0 (build N)" (what a tester sees new: Settings, Account with a password and deletion, reminders, offline, Dynamic Type and VoiceOver); `STATE.md` updated with the build and the group. The rollback line: the previous build stays in the group; expire the bad one in App Store Connect.
- [ ] **Step 2: Commit** "docs/release.md: the release checklist"; `bun check`; push; pull request 8 with the hardening pictures; merge.

### Task 21: The deploy and the TestFlight builds (main)

- [ ] **Step 1 (after PR 2, with the owner's step 1 done):** `gh workflow run deploy`; the summary shows 0008 pending, pushed, nothing after; the API smoke green (`/health` the commit; `/ai/generate` 401). Record the run id in `STATE.md`'s Production. The route is checked by hand once: `curl -X POST "$API_ORIGIN/account/revoke-apple" -H "Authorization: Bearer <a live token>" -d '{"code":"x"}'` answers 400 "Apple didn't accept the confirmation. Try again." (Apple refuses a made-up code; the signed secret was accepted far enough to get that answer; a 502 would mean the key is wrong: check `APPLE_KEY_ID` and the `.p8`'s newlines).
- [ ] **Step 2 (after PR 8):** `gh workflow run testflight`; the build number from the run; the owner installs it from the internal group. This is the release candidate; the tester runs `docs/testing/device-tests.md` on it.

### Task 22: The hand runs (D32) and the owner's steps

**The owner's steps, one message at a time, each checked before the next:**

1. The Sign in with Apple key: developer.apple.com → Certificates, Identifiers & Profiles → Keys → "+" → name "tutor-central-signin", tick Sign in with Apple, Configure → the primary App ID `in.tutorcentral.app` → Register → Download the `.p8` (once). Check: the key's id (ten characters) is shown on the key's page.
2. Into Vercel: project `tutor-central-api` → Settings → Environment Variables: `APPLE_TEAM_ID` = `Y7SW6436RD`, `APPLE_KEY_ID` = the id, `APPLE_SIGNIN_KEY` = the `.p8`'s whole text (with its `-----BEGIN PRIVATE KEY-----` lines; Vercel keeps the newlines), Production and Preview, Sensitive. And the same three into `api/.env.local` (the `.p8` text with `\n` for its newlines, on one line). Check: `cd api && bun run dev` boots; `curl -X POST localhost:3000/account/revoke-apple` without a token answers 401. Do not paste the key in chat.
3. The deploy (Task 21, step 1). Check: the run's summary and the curl above.
4. After PR 8, the TestFlight build (Task 21, step 2). Check: the build in App Store Connect's TestFlight tab, the internal group has it, the phone installs it.
5. App Store Connect → the app → App Information → Privacy Policy URL `https://tutorcentral.in/privacy` (needs Phase 8's page live; until then this step waits and the rest proceed); TestFlight → Test Information: the beta description (`docs/release.md`'s release notes), the feedback email `hello@tutorcentral.in`, the sign-in instructions for the reviewer (a test email code works; say so); → External Testing → "+" group "Tutors" → add the build → Submit for review. Check: "Waiting for Review", then "Approved" within a day or two; invite the tester by email.
6. Hand the tester `docs/testing/device-tests.md` (D1 to D7 added by this plan) and the build number; their log comes back into that file (a documents commit).

**The hand runs,** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed, signed in as Meera, every write confirmed in the database, every screenshot kept in `.shots/run/` and attached to the phase's issue ("Phase 7 hand run"); the local API runs with `APPLE_FAKE=1 AI_FAKE=1` (no money, no Apple):

| Run | Before merging | Through the screens | Confirm |
|---|---|---|---|
| 1 Settings saves | PR 5 | More → Settings → change the centre's name → tap away (Saved) → Appearance Light (the app turns light) → Dark → Haptic feedback off → on → Back | `select name from centres`; `xcrun simctl spawn booted defaults read in.tutorcentral.app` shows `appearance` and `haptics` |
| 2 A failed save | PR 5 | Stop the gateway (`docker stop supabase_kong_tutor_central`) → change your name → tap away → the toast names the field, no mark → `docker start` → change it again → Saved | `profiles.display_name` holds the second value only |
| 3 Password | PR 5 | Settings → Account → Password → type 5 characters (the button stays off) → 15 → Set password → the toast; Sign out → Continue with email → Use my password instead → the new password → Today | `select has_password from profiles` is true; the auth log shows `/token` 200 with `grant_type=password` |
| 4 Sign out wipes | PR 5 | With a cached register (open Students once) and a queued change (run 8 first, or skip): Sign out → the dialog (the warning when a change waits) → Sign out | `ls` the app's Application Support/TutorCentral: no `register-*`, `cache-*`, `queue-*`, `upi-qr-*`; `defaults read` has no `haptics` |
| 5 Delete account | PR 5 | Sign in again → Settings → Account → Delete account permanently → type a wrong name (the button stays off) → the centre's name → Delete my account (the email account: no Apple step) → the sign-in landing with the banner → Continue with email → a code (Mailpit :54324) → onboarding | `select count(*) from auth.users where email = 'meera@example.com'` is 0; every centre table has no row for the old centre; the new sign-in's user id differs. Then `supabase db reset` |
| 6 A reminder fires | PR 7 | Sign in → Students → Classes → add "Test class" meeting today at the time 16 minutes from now → More → Settings → Teacher reminders → Turn on reminders → Allow → the line reads "Next: Test class, today at …" → press Home (the Simulator tool's `button HOME`) → wait → the banner → tap it → Attendance for Test class today | the screenshots of the banner and of the attendance screen; `xcrun simctl push` is not used (these are local notifications, the real path) |
| 7 Offline reads | PR 6 | Open Today, Students, Fees, Attendance, History, Schedule, Tasks, AI History once online → stop the gateway → kill and relaunch the app → each root shows its cache and the bar with its time; Reports shows the "nothing saved" card | the cache files under Application Support/TutorCentral |
| 8 Offline writes | PR 6 | Gateway stopped: Students → "+" → a student → Save → the refused toast; Attendance → mark Hemanth absent → Save → "Saved on this iPhone" → Tell parent → Open WhatsApp (nothing opens; the sheet closes); Fees → Dev → Mark paid → the toast "kept here" → Undo → Mark paid again | `queue-<centre>.json` holds two changes and a log; `students` unchanged |
| 9 Back online | PR 6 | `docker start supabase_kong_tutor_central` → within 20 s the banner "Sending 3 saved changes…" then the toast "3 saved changes sent." | `attendance_marks` for today, `fee_invoices` Dev paid, `message_log` one `absence` row; the queue file empty |
| 10 A failed send | PR 6 | Gateway stopped → Fees → Nikhil → Mark paid → (psql) `delete from students where name = 'Nikhil Das'` → `docker start` → the banner "1 saved change couldn't be sent." → tap → Pending changes: the failed row and its reason → Discard → the dialog → Discard → the banner gone; Settings' Pending changes reads None | `fee_invoices` has no row for Nikhil (cascaded with him); nothing else changed |
| 11 Dynamic Type | PR 8 | `xcrun simctl ui booted content_size accessibility-extra-large` → Today, Students, a student, Fees, Attendance, Settings, Account, Reminders at that size → `large` again | the screenshots beside Task 18's |
| 12 Reduced motion | PR 8 | `defaults write com.apple.Accessibility ReduceMotionEnabled -bool true` in the simulator → relaunch → a toast appears at once; the skeleton does not breathe → off again | screenshots |
| 13 Launch | PR 8 | Terminate; launch; the first frame | the screenshot of the launch screen |

### Task 23: The tester's device tests and the documents (main)

- [ ] **Step 1: `docs/testing/device-tests.md`** gains the Phase 7 section (D1 to D7) in the same documents commit as this plan (done by the planning session; the build session keeps it current: a test the simulator can now cover is removed).
- [ ] **Step 2: Documents (D12), one commit to `main` when the phase ends:** `plan/phase-07-settings-and-hardening.md` "As built"; `plan/README.md` (Phase 7 done; D37 to D40 already numbered); `plan/STATE.md` (production: migration 0008, the API commit with the Apple variables, the build and the external group); `plan/ui-polish.md` (anything seen; U-items taken moved to Done); `docs/design/components.md` and `information-architecture.md` where the build corrected a board's words; `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` rules learned (the two `security definer` functions; `APPLE_FAKE`; the queue and the caches on sign-out; the delegate); `plan/sessions/015/record.md` and `owner-messages.md`; then a reviewer pass on the eight merged pull requests with `superpowers:requesting-code-review`, its outcome recorded, its Important findings fixed with a test that failed first before the TestFlight build of Task 21 step 2 (the review runs before the release candidate, as Phase 6 did).

---

## Self-review

- **Spec coverage.** Phase file scope 1 (Settings: the profile, payments, parent messages as WhatsApp only, teacher reminders with the permission state and the three switches and refresh, haptics, about with version and build, the privacy and terms links, saved marks): Tasks 11 and 17. Scope 2 (Account: email, sign-in methods, set or change a password, sign out, delete permanently with a typed confirmation that deletes on the server and signs out): Tasks 1, 2, 3, 7, 12, 13. Scope 3 (local notifications: class reminders before each meeting, event reminders, the unpaid-fee reminder on a chosen day; scheduled on the device, refreshed on foreground and after edits; each opening its deep link): Tasks 4, 10, 17. Scope 4 (cached reads for every list, honest offline states, a queued-write layer for attendance marks and mark-paid that replays on reconnect with last write wins per row and the tutor told when a replay fails): Tasks 5, 8, 9, 14, 15, 16 (Reports and a student's fees: the decisions table says why they show the nothing-saved card). Scope 5 (Dynamic Type everywhere, VoiceOver labels, reduced motion, the Kit in both appearances, launch time and scrolling on the oldest iPhone, error wording, `docs/release.md`): Tasks 18, 20, the tester's D4. Scope 6 (version 1.0, a CI build, the external group, release notes): Tasks 19, 20, 21, 22's owner steps. Acceptance: pictures in PRs 5 to 8; reminders fire in the simulator (run 6) and on the tester's phone (D2); deleting removes every row and a second sign-in starts at onboarding (run 5, the RLS test); attendance marked offline arrives on reconnect (runs 8 and 9, D3); the checklist and the build (Tasks 20, 21). Inventory rows: all placed (Global Constraints, last line). D32: Task 22's table names every write path. The open owner calls (the register cache on sign-out; Google's mark): the decisions table. Phase 6's lessons: the lint's shapes (Global Constraints); a leaveable call in its store's task (`DeleteAccountStore`, the runner, the scheduler); words for a gone screen returned to the caller (the runner's toasts are AppShell's); every error true to what happened (Task 18, step 6); keyboards away before a toast (Task 18, step 7); a sheet's store in `@State` (`PasswordSheet`); `supabase db reset` ends the session (run 5 signs out first).
- **Placeholders.** Every test is written; every screen is named by its board and its parts; the words are the boards'. The one open input is the owner's: Phase 8's privacy page before Beta App Review (Task 22, step 5), said as such.
- **Type consistency.** `ReminderSettings`, `Reminder`, `ReminderInput`, `ReminderPlanner` (Task 4) are what `ReminderScheduler` and `RemindersStore` (Task 17) and `NotificationCenterClient` (Task 10) use; `QueuedChange`, `PendingChanges` (Task 5) are what `ChangeQueue`, `QueueRunner`, `RunOutcome` (Task 9), the Attendance and Fees stores (Task 15), `PendingChangesStore` and `RunState` (Task 16) and `AccountStore.signOutWarning` (Task 12) use; `CachedRead`, `TransportError`, `ConnectivityMonitor` (Task 8) are what the stores (Task 14) and the runner (Task 9) use; `AccountFailure`, `signInMethods`, `setPassword`, `deleteAccount`, `AccountRepository.revokeApple`, `Wipe` (Task 7) are what `PasswordStore`, `AccountStore`, `DeleteAccountStore` (Tasks 12, 13) and `SessionStore.signOut(wiping:)` use; `SignInProvider`, `PasswordRule`, `DeletionConfirmation`, `CacheAge` (Task 6) are used by Tasks 7, 12, 13, 14; `StatusLineModel` (Task 14) is what `RunState` (Task 16) feeds; the API's `AppleClient`, `AppleFailure` (Task 2) are what the route (Task 3) and `index.ts` use; `LaunchState` raw values match `information-architecture.md`'s Phase 7 table (35 states; `settings` and `more` are re-shot).
- **Review Focus.** 1 → Task 9 `aQueueIsKeptPerCentreAndSurvivesARelaunch`, `wipeRemovesTheFile`; Task 12 `signOutWipesTheCachesAndTheQueue`. 2 → Task 5 `aSecondSaveOfTheSameClassAndDayReplacesTheFirst`; Task 15 `onlineButWithASaveWaitingTheNewSaveJoinsTheQueue`; Task 9 `changesAreSentInTheOrderMadeAndLeaveTheQueue`. 3 → Task 9 `anOfflineErrorStopsTheRunAndKeepsTheChange`, `aRefusedRowIsFailedAndTheRestStillGo`, `aSignedOutErrorKeepsTheChangeAndSaysSo`. 4 → Task 13 `aFailedDeleteAfterAppleKeepsTheTutorSignedInAndRetries`, `aLocalSignOutFailureStillEndsSignedOut`, `aDeletedUsersSessionBecomesSignedOut`. 5 → Task 4 `pastAndUntimedMeetingsAreSkipped`, `atMostSixtySoonestAreKept`, `theFeeReminderNeedsADueFee`, `idsAreStableAcrossRuns`.
- **The polish list and the minors.** U6, U7, U9, U16 and U24 and Phase 6's minors 1 (retain cycles), 6 (the trunk-0 phone) and 7 (graphemes and code points) go to Phase 8 (the owner, 2026-10-09, on approving this plan); this phase takes none of them. Seen while planning, for `plan/ui-polish.md` if the owner wants it: the receipt sheet is not offered after an offline Mark paid (no log can queue a receipt); Reports and a student's fees have no cache.
