# Phase 3 Students and Classes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The tutor's register in the app: every student with their parent's contact and fee, grouped into classes that know when they meet; search, filter and sort; add, edit, archive, restore and delete a student; create, edit and archive a class; the student detail hub; every screen built to its approved Phase 3 board in both appearances, on TestFlight.

**Architecture:** `Domain` gains the value types (`Student`, `Classroom`, `Weekday`, `TimeOfDay`, `Day`, `Gender`, `MonthFee`) and the pure rules (phone normalisation already exists; fee prefill, meeting summary, this week's meetings, initials, search, filter, sort, draft validation), all tested first. `Data` gains two repositories (students, classes) as protocols with Supabase implementations and in-memory fakes seeded with `supabase/seed.sql`'s ten students and two classes, plus a small JSON disk cache so the register shows at once and refreshes behind. `Features/Students` holds one `RegisterStore` for the whole tab (the lists, the query, optimistic writes), two form stores, and the screens; `AppShell` keeps the store alive across tab switches (as it does Today's), adds the routes and fixtures, and makes `tutorcentral://student/<id>` open the detail. One additive migration (0003) adds `archive_class`, the only multi-row write, with its RLS test. No new table: migration 0001 already holds `students` and `classes` with every column the phase needs.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, `supabase-swift` 2.55.3 (PostgREST reads with an embedded `fee_invoices` filter, updates, one RPC), Postgres (one `security invoker` function), Bun tests against local Supabase, XcodeGen, GitHub Actions on `xcode-27` (D22).

**Spec:** `docs/spec.md` sections 2, 4 and 5; scope and acceptance in `plan/phase-03-students-and-classes.md`; the boards `docs/design/mockups/P3-*.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 6; the list, the launch states and what the boards settle in `docs/design/information-architecture.md`, "Phase 3 boards"); `design-tokens.md`, `components.md` (the Phase 3 additions: search field, filter chip, banner, day picker, menu, picker tiles on a sheet, the member, meeting and checklist rows), `guidelines.md`; the Students and classes rows of `docs/reference/functional-inventory.md`; decisions D1 to D30 in `plan/README.md`; Phase 2's "As built" and the deferred minors in `plan/sessions/004/record.md`.

## Global Constraints

- iOS 26.0 minimum, iPhone only (D1), bundle id `in.tutorcentral.app` (D27). Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation (D8). Features never import each other: `Features/Students` reaches a later-phase screen through closures `AppShell` provides (`StudentsActions`), as Today does with `TodayActions`.
- Style only through `DesignSystem` tokens (D10, D25): no raw colour, size, radius, shadow or duration in a feature view. A board value the document does not name becomes a token in `design-tokens.md` and Swift in the same commit; an anatomy number lives as a named constant on its component (Phase 2's ruling). Every new component gets a SwiftUI preview; the Kit screen stays as its approved boards draw it (decisions below).
- Both appearances built and photographed (D13, D23). Every board state is a `LaunchState` whose raw value is the name in `information-architecture.md`; `bun shots <state>` photographs it; every pull request that changes what is seen carries the table `bun pr-shots` prints, for each changed state in both appearances (D7, `CLAUDE.md` rule 2). No board, no screen (rule 1): a state this plan did not foresee is drawn and approved first.
- Copy: sentence case, no exclamation marks, no emoji, no jargon; buttons are verbs with an object; errors say what happened and what to do (`guidelines.md`). The copy of every screen is on its board and repeated in the task that builds it; the boards name the student, never a pronoun.
- Money is whole rupees formatted `₹1,200` (`Money.formatted`); phones are E.164 in the database and `+91 98765 43210` on screen (`PhoneNumber`); dates `4 Oct`, `14 Mar 2011`, `Today, 7 October`; times 24-hour `17:00`, ranges with an en dash `17:00–18:00` (`components.md`, "Money, phone, date and time"). The centre's calendar is India (`DayHeading.india`).
- Database (`supabase/CLAUDE.md`): one migration per change, additive while any installed build uses what it would remove (D26); every new function is `security invoker`, `set search_path = ''`, revokes `public` and `anon`, grants `authenticated`; `supabase gen types typescript --local > types.ts` after the migration; a test in `supabase/tests/`. Migrations reach production only through `gh workflow run deploy` (D26); the TestFlight lane refuses a build while one is pending.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/AppShellTests` and the new `Tests/StudentsTests` (in `Package.swift` and the scheme in `project.yml`). Stores are tested against the fakes. No UI test suites (D15).
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). Bun only (D16). `supabase-swift` stays the only iOS dependency (D14). A new decision gets its number in `plan/README.md` in the pull request that acts on it.
- Nothing from the reference app is dropped (rule 10): the inventory's Students and classes rows (search; status chips; sort; filter by class; add with the eight fields; the detail hub; edit, archive, delete with a typed confirmation; count without a limit; classes with the six fields; class detail with members and the attendance shortcut; the "+" menu with scan) are all placed below; scan itself is Phase 6 and opens the later board until then.

## Review Focus

Inputs the spec implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **A save that fails (no network, RLS refusal) must leave the register exactly as it was and keep the tutor's typing.** The row added optimistically goes away, a toast says "Couldn't save Riya. Check your connection and try again." with Retry, and nothing is written twice. Test in Task 8 (`RegisterStore`: `aFailedAddRevertsTheRowAndOffersRetry`, `retryWritesOnce`).
2. **Search must find a student by any part of the name or the number however it is typed:** "rao", "SHAH", "98111", "+91 98111", "98111 22233", a trailing space; an empty search shows everyone the filter allows; archived students are found by search but hidden by the All filter. Test in Task 3 (`StudentQueryTests`: `matchesNamesAndNumbersHoweverTyped`, `archivedStudentsAreFoundBySearchAndHiddenByAll`).
3. **Fee prefill must follow the class only while the tutor has not typed a fee:** choosing Class 10 Maths shows ₹1,200 as the placeholder and saves `nil` (the class fee); typing ₹1,500 then changing class keeps ₹1,500; clearing the field returns to the class fee; a student with no class and no fee saves `nil` and the row shows no amount. Test in Task 10 (`StudentFormStoreTests`: `anUntouchedFeeFollowsTheClassATypedOneStays`, `clearingTheFeeReturnsToTheClassFee`).
4. **Deleting a student must take their fees and attendance with them and nothing else;** the typed name must match ignoring case and surrounding spaces ("akshita " confirms "Akshita"), and a two-word first name ("Bir Bikram") is confirmed by its first word. Tests in Task 6 (`rls.test.ts`: `deleting a student cascades to invoices and marks and detaches message_log`) and Task 12 (`DialogTests`: `theTypedNameConfirmsIgnoringCaseAndSpaces`).
5. **Archiving a class must detach its students, not archive them,** so they stay in Students as "No class yet", keep their own fee if they had one, and the class leaves every list, count and Today's "classes today" at once; a deep link to a student who was deleted says so instead of a blank screen. Tests in Task 6 (`rls.test.ts`: `archive_class detaches members and is refused to a non-member`), Task 16 (`RegisterStoreTests`: `archivingAClassDetachesItsMembers`) and Task 12 (`TabsStateTests`: `aLinkToAMissingStudentSaysSo`).

---

## Decisions this plan settles

Small and medium things, decided here and written down. None needs a number in `plan/README.md`; the two that touch the database (`archive_class`; no function for a single multi-row `update`) follow `supabase/CLAUDE.md` as read.

| Decision |
|---|
| **No new table, one migration.** `students` and `classes` (migration 0001) carry every column the phase file names. Migration 0003 adds `archive_class(p_class uuid)`: sets `archived_at` and sets `class_id = null` on its students in one transaction (two statements, so a function, `security invoker`). Adding students to a class is one `update students set class_id = … where id in (…)`: one statement, atomic by itself, no function. Deleting a student is a plain `delete`: the foreign keys cascade to `fee_invoices` and `attendance_marks` and set `message_log.student_id` to null (0001), proven by a new RLS test. |
| **The type is `Classroom`.** `Class` would read as the keyword in every file; the inventory's and the boards' word stays "class" on screen. |
| **Reads with status in one query.** `students(centre:period:)` selects the columns plus `fee_invoices(amount, status, paid_at, paid_method)` with `fee_invoices.period = eq.<first of month>`, so each student carries `thisMonth: MonthFee?` (Phase 5 owns the ledger; Phase 3 reads one month). Archived students are included; the store filters. The register is small (5 to 60 rows): search, filter, sort and member counts run on the device. |
| **One store for the tab.** `RegisterStore` holds students, classes, the query and every write; `ShellState.register` keeps it alive while the tutor is in the centre (as `today`), so a tab switch keeps the list, the search and the scroll. Detail and form screens read it through the environment. |
| **Cache.** `JSONCache<RegisterSnapshot>` in Application Support, one file per centre (`register-<centre id>.json`), written after every successful read or write and read before the first network call, so the list appears at once and the stale pattern (`opacityStale` with the spinner by the count line) covers the refresh. A sign-out leaves the file; a different centre reads its own. |
| **Optimistic writes.** Add, edit, archive, restore, assign and class writes apply to the store first and roll back on failure with a toast that names the student or class and offers Retry; delete waits for the server (the dialog's Delete shows loading) because nothing can be shown optimistically after a cascade. |
| **The row's second line and status** are as `components.md` now says: the class or "No class yet"; the parent's phone while no class exists or when the search matched the number; the fee status from this month's invoice, absent when none exists; a waived invoice reads "Waived" in `text2`. `StudentRow` gains an optional, toneless status for it. |
| **Form rules.** Name required, at most 80 characters (the column's check); parent's name at most 80; fee a whole number of rupees up to ₹1,00,000 ("That's more than ₹1,00,000. Check the amount."); phone through `PhoneNumber` or empty ("Needs 10 digits after +91."); notes at most 2,000 with the counter; date of birth not after today and not before 1950 ("Check the date of birth."); class times: end after start when both are set ("The class has to end after it starts."); meeting days may be empty (a class with no fixed days). Save is disabled until valid and, when editing, until something changed; Cancel with changes asks "Discard changes?" (secondary Keep editing, destructive Discard). |
| **Gender** is stored `female`, `male`, `other` (0001's check) and shown as the board's chips Girl, Boy, Other; tapping the selected chip clears it (the field is optional). |
| **Sort** by name (A to Z, the default) or by fee (highest first, then name), remembered per launch, not persisted. Filter chips show once a class or an archived student exists; "Archived" lists archived students only; "No class" lists active students without a class. |
| **Sheets** are the system's floating sheets (D28): the student form at `.large`, the class form and the add-students sheet at `.medium` with `.large` available; `presentationDragIndicator(.hidden)` because `SheetHeader` draws the grabber. Pushed screens on the Students tab hide the tab bar (`.toolbar(.hidden, for: .tabBar)`, as Settings); the root keeps it. |
| **Later places.** The "+" menu's "Scan paper register", the detail's Fees "See all" and the class detail's "Mark attendance" push `LaterView` with new places `scanRegister` ("Scan register"), `studentFees` ("Fees") and `markAttendance` ("Attendance"), through `StudentsActions`. The detail's Attendance section is the empty-row pattern at `opacityLater` with the board's words until Phase 4. |
| **Deep link** `tutorcentral://student/<id>` now opens the detail on the Students tab (`TabsState.open` returns true for `.student`); a missing id shows the list and a toast "That student is no longer here." |
| **The Kit stays** as its approved boards draw it. The new components (search well, filter chip, day picker, banner, picker and time tiles, member, meeting and checklist rows, notes well) have previews; they appear in the Kit when a Kit board draws them. |
| **Fixtures.** The fakes carry the seed's content with fixed ids (`FakeStudentsRepository.seed`, `FakeClassesRepository.seed`; Akshita Rao and Class 10 Maths have known ids for the detail states), this month's invoices paid on 4 October for the six the seed pays, and the clock `FakeCountsRepository.fixedNow` (Wednesday 7 October 2026, 18:30). `students-few` uses the seed's three students with their own fee (Dev, Riya, Sahil) unassigned and unbilled; `students-empty` nothing. |
| **The scan register entry** (phase file item 2) is the later board until Phase 6, as the inventory row says ("navigates to Phase 6's entry, which shows its coming-later state"). |
| **TestFlight.** The phase ends with build 0.1.0 (n) on the owner's phone after migration 0003 is in production (`gh workflow run deploy`, then `gh workflow run testflight`). |

## File structure

```
docs/design/components.md                          # only if a board value needs a token (none foreseen)
ios/
  project.yml                                      # + StudentsTests in the scheme
  TutorCentralKit/Package.swift                    # + StudentsTests
  TutorCentralKit/Sources/Domain/
    Weekday.swift, TimeOfDay.swift, Day.swift, Gender.swift, NameInitials.swift
    Classroom.swift, ClassroomDraft.swift           # the class, its summary, this week's meetings, the draft and its problems
    Student.swift, StudentDraft.swift, MonthFee.swift   # the student, its fee rule, the month's status, the draft and its problems
    StudentQuery.swift                             # StudentFilter, StudentSort, search, apply, match ranges
    Money.swift (+ init?(typed:), Codable), PhoneNumber.swift (+ Codable), Period.swift (+ Codable)
  TutorCentralKit/Sources/Data/
    Cache/JSONCache.swift
    Students/StudentsRepository.swift, SupabaseStudentsRepository.swift, FakeStudentsRepository.swift, StudentRow.swift
    Classes/ClassesRepository.swift, SupabaseClassesRepository.swift, FakeClassesRepository.swift, ClassroomRow.swift
  TutorCentralKit/Sources/DesignSystem/Components/
    SearchWell.swift, FilterChip.swift, DayPicker.swift, Banner.swift, Tiles.swift (PickerTile, TimeTile), NotesWell.swift
    Rows.swift (StudentRow status optional; + MemberRow, MeetingRow, ChecklistRow), Avatar.swift (+ init(initials:), IconTile size)
  TutorCentralKit/Sources/Features/Students/
    RegisterStore.swift, RegisterCache.swift, StudentsActions.swift
    StudentsView.swift, StudentsListSections.swift   # the root and its pieces (search, chips, classes row, count line, list, empty cards)
    StudentFormStore.swift, StudentFormSheet.swift
    StudentDetailStore.swift, StudentDetailView.swift, ConfirmDialogs.swift
    ClassesView.swift, ClassFormStore.swift, ClassFormSheet.swift, ClassDetailView.swift, AddMembersSheet.swift
    Students.swift (delete the Phase 2 marker)
  TutorCentralKit/Sources/AppShell/
    TabsView.swift (the Students root, the routes), TabsState.swift (Route cases, open(.student)), ShellState.swift (register),
    RootView.swift (the Students views and actions, the fixtures' routes), LaunchState.swift (20 cases), Fixtures.swift,
    LaterView.swift (three places), Dependencies.swift (students, classes, cache directory)
  TutorCentralKit/Tests/DomainTests/
    WeekdayTests.swift, TimeOfDayTests.swift, DayTests.swift, NameInitialsTests.swift, ClassroomTests.swift,
    ClassroomDraftTests.swift, StudentTests.swift, StudentDraftTests.swift, StudentQueryTests.swift, MoneyTests.swift (+ typed)
  TutorCentralKit/Tests/DataTests/
    JSONCacheTests.swift, FakeStudentsRepositoryTests.swift, FakeClassesRepositoryTests.swift, StudentRowTests.swift, ClassroomRowTests.swift
  TutorCentralKit/Tests/StudentsTests/
    RegisterStoreTests.swift, StudentFormStoreTests.swift, StudentDetailStoreTests.swift, ClassFormStoreTests.swift
  TutorCentralKit/Tests/AppShellTests/
    TabsStateTests.swift (new), LaunchStateTests.swift (the 20 states), DeepLinkTests.swift (unchanged)
supabase/
  migrations/20261009000003_archive_class.sql
  tests/rls.test.ts                                 # + archive_class, + delete cascade
  types.ts                                          # regenerated
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 to 3 | `phase-3/domain` | Domain: students, classes, days and times, the register's rules | none |
| 2 | 4, 5 | `phase-3/data` | Data: students and classes repositories, the fakes with the seed, the JSON cache | none |
| 3 | 6 | `phase-3/archive-class` | Migration 0003: `archive_class`; the delete cascade proven | none; after merge `gh workflow run deploy` and its summary |
| 4 | 7 to 9 | `phase-3/students-list` | The Students tab: search, filters, sort, the Classes row, the "+" menu | `students-empty`, `students-few`, `students`, `students-searching`, `students-filtered`, `students-add-menu`, both appearances |
| 5 | 10, 11 | `phase-3/student-form` | New student | `student-new`, `student-new-filled`, `student-new-invalid`, both |
| 6 | 12, 13 | `phase-3/student-detail` | Student detail: parent actions, fees, notes, archive, restore, delete, edit; the deep link | `student`, `student-archived`, `student-archive-confirm`, `student-delete-confirm`, `student-edit`, both |
| 7 | 14 to 17 | `phase-3/classes` | Classes: list, new and edit, detail with this week and the members, add and remove, archive | `classes-empty`, `classes`, `class-new`, `class-edit`, `class-archive-confirm`, `class`, `class-add-members`, both |
| 8 | 18 | `phase-3/polish-minors` | The deferred minors whose files this phase touches | the states they change, if any |
| main | 19 | | TestFlight build; as built, state, record, resume (documents only, D12) | |

Owner steps: none inside the tasks. After PR 7 the executor runs `gh workflow run deploy` (0003 to production, D26) and `gh workflow run testflight`; the owner installs the build and tries the register with real students (Task 19).

---

### Task 1: Domain: days, times, weekdays, gender, initials; `Money` and `PhoneNumber` round-trip (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Weekday.swift`, `TimeOfDay.swift`, `Day.swift`, `Gender.swift`, `NameInitials.swift`
- Modify: `ios/TutorCentralKit/Sources/Domain/Money.swift` (`Codable`, `init?(typed:)`), `PhoneNumber.swift` (`Codable`), `Period.swift` (`Codable`)
- Test: `ios/TutorCentralKit/Tests/DomainTests/WeekdayTests.swift`, `TimeOfDayTests.swift`, `DayTests.swift`, `NameInitialsTests.swift`, `MoneyTests.swift` (append)

**Interfaces:**
- Produces:

```swift
public enum Weekday: Int, CaseIterable, Hashable, Sendable, Comparable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
    public var short: String      // "Mon"
    public var initial: String    // "M"
    public var name: String       // "Monday"
    public init?(date: Date, calendar: Calendar)   // ISO weekday of a date
}
public struct TimeOfDay: Hashable, Sendable, Comparable, Codable {
    public let hour: Int; public let minute: Int
    public init?(hour: Int, minute: Int)
    public init?(iso: String)     // "17:00" or "17:00:00"
    public var iso: String        // "17:00"
    public var text: String       // "17:00"
    public static func range(_ start: TimeOfDay, _ end: TimeOfDay) -> String   // "17:00–18:00" (en dash)
}
public struct Day: Hashable, Sendable, Comparable, Codable {
    public let year: Int; public let month: Int; public let day: Int
    public init?(year: Int, month: Int, day: Int)
    public init?(iso: String)                      // "2011-03-14"
    public init(_ date: Date, calendar: Calendar)  // the calendar day the date falls on
    public var iso: String
    public func date(in calendar: Calendar) -> Date  // midnight
    public func weekday(in calendar: Calendar) -> Weekday
    public func adding(days: Int, calendar: Calendar) -> Day
    public var text: String                        // "14 Mar 2011"
    public var shortText: String                   // "4 Oct" (no year)
    public var longText: String                    // "7 October"
}
public enum Gender: String, CaseIterable, Hashable, Sendable, Codable { case female, male, other; public var label: String /* Girl, Boy, Other */ }
public enum NameInitials { public static func of(_ name: String) -> String }   // "Bir Bikram Singh" → "BB", "Dev" → "D", "" → "?"
extension Money: Codable { public init?(typed: String) }   // "1,500", "₹1500", " 1500 " → 1500; "" or letters → nil
extension PhoneNumber: Codable {}
extension Period: Codable {}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/WeekdayTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct WeekdayTests {
    @Test func namesAndOrder() {
        #expect(Weekday.monday.short == "Mon" && Weekday.sunday.short == "Sun")
        #expect(Weekday.thursday.initial == "T" && Weekday.saturday.name == "Saturday")
        #expect(Weekday.monday < Weekday.sunday)
        #expect(Weekday.allCases.map(\.rawValue) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func fromADateInIndia() {
        // Wednesday 7 October 2026, 18:30 IST; and the same instant is still Wednesday in India after midnight UTC.
        let wednesday = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18, minute: 30))!
        #expect(Weekday(date: wednesday, calendar: DayHeading.india) == .wednesday)
        let sundayLate = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 23, minute: 50))!
        #expect(Weekday(date: sundayLate, calendar: DayHeading.india) == .sunday)
    }
}
```

`Tests/DomainTests/TimeOfDayTests.swift`:

```swift
import Testing
@testable import Domain

struct TimeOfDayTests {
    @Test func parsesTheDatabaseAndTheShortForm() {
        #expect(TimeOfDay(iso: "17:00:00") == TimeOfDay(hour: 17, minute: 0))
        #expect(TimeOfDay(iso: "16:30") == TimeOfDay(hour: 16, minute: 30))
        #expect(TimeOfDay(iso: "24:00") == nil && TimeOfDay(iso: "7pm") == nil && TimeOfDay(hour: 9, minute: 60) == nil)
    }

    @Test func writesTwentyFourHourText() {
        #expect(TimeOfDay(hour: 9, minute: 5)!.text == "09:05" && TimeOfDay(hour: 17, minute: 0)!.iso == "17:00")
        #expect(TimeOfDay.range(TimeOfDay(hour: 17, minute: 0)!, TimeOfDay(hour: 18, minute: 0)!) == "17:00–18:00")
        #expect(TimeOfDay(hour: 16, minute: 30)! < TimeOfDay(hour: 17, minute: 0)!)
    }
}
```

`Tests/DomainTests/DayTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct DayTests {
    @Test func isoRoundTripAndValidation() {
        let day = Day(iso: "2011-03-14")
        #expect(day == Day(year: 2011, month: 3, day: 14) && day?.iso == "2011-03-14")
        #expect(Day(iso: "2011-02-30") == nil && Day(iso: "14/03/2011") == nil && Day(year: 2026, month: 13, day: 1) == nil)
    }

    @Test func textsAsComponentsWritesThem() {
        let day = Day(year: 2011, month: 3, day: 14)!
        #expect(day.text == "14 Mar 2011" && Day(year: 2026, month: 10, day: 4)!.shortText == "4 Oct")
        #expect(Day(year: 2026, month: 10, day: 7)!.longText == "7 October")
    }

    @Test func fromADateAndBackInIndia() {
        let instant = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 23, minute: 50))!
        let day = Day(instant, calendar: DayHeading.india)
        #expect(day == Day(year: 2026, month: 10, day: 7))
        #expect(day.weekday(in: DayHeading.india) == .wednesday)
        #expect(day.adding(days: 2, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 9))
        #expect(day.adding(days: -2, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 5))
        #expect(DayHeading.india.component(.hour, from: day.date(in: DayHeading.india)) == 0)
        #expect(Day(year: 2026, month: 9, day: 30)! < day)
    }
}
```

`Tests/DomainTests/NameInitialsTests.swift`:

```swift
import Testing
@testable import Domain

struct NameInitialsTests {
    @Test func twoLettersFromTheFirstTwoWords() {
        #expect(NameInitials.of("Akshita Rao") == "AR" && NameInitials.of("Bir Bikram Singh") == "BB")
        #expect(NameInitials.of("Dev") == "D" && NameInitials.of("  meera   nair ") == "MN" && NameInitials.of("") == "?")
    }
}
```

Append to `Tests/DomainTests/MoneyTests.swift`:

```swift
    @Test func parsesWhatATutorTypes() {
        #expect(Money(typed: "1,500") == Money(rupees: 1500) && Money(typed: " ₹1200 ") == Money(rupees: 1200))
        #expect(Money(typed: "0") == Money(rupees: 0))
        #expect(Money(typed: "") == nil && Money(typed: "12a") == nil && Money(typed: "1.5") == nil && Money(typed: "-5") == nil)
    }

    @Test func roundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode([Money(rupees: 1200), .zero])
        #expect(try JSONDecoder().decode([Money].self, from: data) == [Money(rupees: 1200), .zero])
        let phone = try JSONDecoder().decode(PhoneNumber.self, from: JSONEncoder().encode(PhoneNumber(e164: "+919799113211")!))
        #expect(phone.e164 == "+919799113211")
        let period = try JSONDecoder().decode(Period.self, from: JSONEncoder().encode(Period(year: 2026, month: 10)))
        #expect(period == Period(year: 2026, month: 10))
    }
```

- [ ] **Step 2: Run the Domain tests to see them fail**

Run: `cd /Users/arunkpatra/codebase/tutor_central && bun check --only=ios`
Expected: FAIL, `Weekday`, `TimeOfDay`, `Day`, `NameInitials`, `Money(typed:)` not found.

- [ ] **Step 3: Implement**

`Domain/Weekday.swift`:

```swift
import Foundation

/// ISO weekdays, Monday 1 to Sunday 7, as `classes.meeting_days` stores them.
public enum Weekday: Int, CaseIterable, Hashable, Sendable, Comparable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    public init?(date: Date, calendar: Calendar) {
        // Calendar's weekday is Sunday 1 … Saturday 7.
        self.init(rawValue: (calendar.component(.weekday, from: date) + 5) % 7 + 1)
    }

    public var name: String {
        switch self {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }

    public var short: String { String(name.prefix(3)) }
    public var initial: String { String(name.prefix(1)) }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}
```

`Domain/TimeOfDay.swift`:

```swift
/// A wall-clock time without a date, as `classes.start_time` stores it; shown 24-hour (components.md).
public struct TimeOfDay: Hashable, Sendable, Comparable, Codable {
    public let hour: Int
    public let minute: Int

    public init?(hour: Int, minute: Int) {
        guard (0 ... 23).contains(hour), (0 ... 59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// "17:00" or Postgres's "17:00:00".
    public init?(iso: String) {
        let parts = iso.split(separator: ":").map(String.init)
        guard (2 ... 3).contains(parts.count), let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        self.init(hour: hour, minute: minute)
    }

    public var iso: String { text }
    public var text: String { String(format: "%02d:%02d", hour, minute) }

    /// "17:00–18:00", with an en dash.
    public static func range(_ start: TimeOfDay, _ end: TimeOfDay) -> String { "\(start.text)–\(end.text)" }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute) }
}
```

`Domain/Day.swift`:

```swift
import Foundation

/// A calendar day without a time: a date of birth, a meeting, a payment day. Dates in a zone become days through the
/// centre's calendar (`DayHeading.india`).
public struct Day: Hashable, Sendable, Comparable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        var components = DateComponents(year: year, month: month, day: day)
        components.calendar = Self.utc
        guard components.isValidDate else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// "2011-03-14".
    public init?(iso: String) {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year!
        month = parts.month!
        day = parts.day!
    }

    public var iso: String { String(format: "%04d-%02d-%02d", year, month, day) }

    public func date(in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    public func weekday(in calendar: Calendar) -> Weekday {
        Weekday(date: date(in: calendar), calendar: calendar)!
    }

    public func adding(days: Int, calendar: Calendar) -> Day {
        Day(calendar.date(byAdding: .day, value: days, to: date(in: calendar))!, calendar: calendar)
    }

    /// "14 Mar 2011".
    public var text: String { formatted("d MMM yyyy") }
    /// "4 Oct".
    public var shortText: String { formatted("d MMM") }
    /// "7 October".
    public var longText: String { formatted("d MMMM") }

    public static func < (lhs: Day, rhs: Day) -> Bool { (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day) }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// A formatter per call: `DateFormatter` is not `Sendable` (D8), as `Period` does.
    private func formatted(_ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = Self.utc.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date(in: Self.utc))
    }
}
```

`Domain/Gender.swift`:

```swift
/// `students.gender`: stored as the column's words, shown as the board's chips.
public enum Gender: String, CaseIterable, Hashable, Sendable, Codable {
    case female, male, other

    public var label: String {
        switch self {
        case .female: "Girl"
        case .male: "Boy"
        case .other: "Other"
        }
    }
}
```

`Domain/NameInitials.swift`:

```swift
/// Up to two letters from the first two words of a name (components.md, Avatar); "?" when there is no name.
public enum NameInitials {
    public static func of(_ name: String) -> String {
        let letters = name.split(whereSeparator: \.isWhitespace).prefix(2).compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}
```

`Domain/Money.swift`, add:

```swift
extension Money: Codable {}

public extension Money {
    /// What a tutor types in a fee field: digits with any ₹, commas and spaces; nothing else.
    init?(typed: String) {
        let kept = typed.filter { !$0.isWhitespace && $0 != "," && $0 != "₹" }
        guard !kept.isEmpty, kept.allSatisfy({ $0.isASCII && $0.isNumber }), let rupees = Int(kept) else { return nil }
        self.init(rupees: rupees)
    }
}
```

`Domain/PhoneNumber.swift`: add `extension PhoneNumber: Codable {}` (it encodes `nationalDigits`; the memberwise synthesis is enough). `Domain/Period.swift`: add `Codable` to the declaration.

- [ ] **Step 4: Run the tests to see them pass; format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git checkout -b phase-3/domain
git add ios/TutorCentralKit
git commit -m "Domain: weekdays, times of day, calendar days, gender, initials; Money parses what is typed and round-trips"
```

### Task 2: Domain: the class, its summary, this week's meetings, the class draft (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Classroom.swift`, `ClassroomDraft.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/ClassroomTests.swift`, `ClassroomDraftTests.swift`

**Interfaces:**
- Consumes: `Weekday`, `TimeOfDay`, `Day`, `Money` (Task 1).
- Produces:

```swift
public struct Classroom: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var subject: String?
    public var monthlyFee: Money?
    public var meetingDays: Set<Weekday>
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var archivedAt: Date?
    public init(id:name:subject:monthlyFee:meetingDays:startTime:endTime:archivedAt:)
    public var isArchived: Bool
    public var daysSummary: String        // "Mon, Wed, Fri" · "Every day" · "No days set"
    public var timeRange: String?         // "17:00–18:00" when both times are set, else the one set, else nil
    public var meetingSummary: String     // "Mon, Wed, Fri · 17:00–18:00" (the days alone when there is no time)
    public func meetings(inWeekOf day: Day, calendar: Calendar) -> [Day]   // Monday to Sunday of that week, the days it meets
}
public struct ClassroomDraft: Hashable, Sendable {
    public var name = "", subject = "", fee: Money? = nil, meetingDays: Set<Weekday> = [], startTime: TimeOfDay? = nil, endTime: TimeOfDay? = nil
    public init(); public init(_ classroom: Classroom)
    public enum Problem: Hashable, Sendable { case nameMissing, nameTooLong, feeTooHigh, endNotAfterStart; public var message: String }
    public var problems: Set<Problem>; public var isValid: Bool
    public var trimmedName: String; public var trimmedSubject: String?   // nil when empty
    public static let feeCeiling = Money(rupees: 100_000)
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/ClassroomTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct ClassroomTests {
    static let maths = Classroom(
        id: UUID(), name: "Class 10 Maths", subject: "Mathematics", monthlyFee: Money(rupees: 1200),
        meetingDays: [.monday, .wednesday, .friday], startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 0),
        archivedAt: nil
    )

    @Test func theSummaryAsTheBoardsWriteIt() {
        #expect(Self.maths.meetingSummary == "Mon, Wed, Fri · 17:00–18:00")
        var noTime = Self.maths
        noTime.startTime = nil
        noTime.endTime = nil
        #expect(noTime.meetingSummary == "Mon, Wed, Fri" && noTime.timeRange == nil)
        var startOnly = Self.maths
        startOnly.endTime = nil
        #expect(startOnly.timeRange == "17:00")
        var daily = Self.maths
        daily.meetingDays = Set(Weekday.allCases)
        #expect(daily.daysSummary == "Every day")
        var none = Self.maths
        none.meetingDays = []
        #expect(none.meetingSummary == "No days set · 17:00–18:00")
    }

    @Test func daysAreListedInWeekOrderHoweverTheSetCame() {
        var c = Self.maths
        c.meetingDays = [.sunday, .tuesday]
        #expect(c.daysSummary == "Tue, Sun")
    }

    @Test func thisWeeksMeetingsFromAWednesday() {
        let wednesday = Day(year: 2026, month: 10, day: 7)!
        let days = Self.maths.meetings(inWeekOf: wednesday, calendar: DayHeading.india)
        #expect(days == [Day(year: 2026, month: 10, day: 5)!, wednesday, Day(year: 2026, month: 10, day: 9)!])
        // The week runs Monday to Sunday: asked on a Sunday, the same week comes back.
        let sunday = Day(year: 2026, month: 10, day: 11)!
        #expect(Self.maths.meetings(inWeekOf: sunday, calendar: DayHeading.india) == days)
        var none = Self.maths
        none.meetingDays = []
        #expect(none.meetings(inWeekOf: wednesday, calendar: DayHeading.india).isEmpty)
    }

    @Test func archivedIsAFlagOnTheDate() {
        #expect(!Self.maths.isArchived)
        var gone = Self.maths
        gone.archivedAt = Date()
        #expect(gone.isArchived)
    }
}
```

`Tests/DomainTests/ClassroomDraftTests.swift`:

```swift
import Testing
@testable import Domain

struct ClassroomDraftTests {
    @Test func aNameIsEnough() {
        var draft = ClassroomDraft()
        #expect(draft.problems == [.nameMissing] && !draft.isValid)
        draft.name = "  Class 9 English "
        #expect(draft.isValid && draft.trimmedName == "Class 9 English" && draft.trimmedSubject == nil)
        draft.subject = " English "
        #expect(draft.trimmedSubject == "English")
    }

    @Test func limitsAndTimesInWords() {
        var draft = ClassroomDraft()
        draft.name = String(repeating: "x", count: 81)
        #expect(draft.problems.contains(.nameTooLong) && ClassroomDraft.Problem.nameTooLong.message == "Keep the name under 80 characters.")
        draft.name = "Class 12 Physics"
        draft.fee = Money(rupees: 100_001)
        #expect(draft.problems == [.feeTooHigh] && ClassroomDraft.Problem.feeTooHigh.message == "That's more than ₹1,00,000. Check the amount.")
        draft.fee = Money(rupees: 1500)
        draft.startTime = TimeOfDay(hour: 18, minute: 0)
        draft.endTime = TimeOfDay(hour: 18, minute: 0)
        #expect(draft.problems == [.endNotAfterStart] && ClassroomDraft.Problem.endNotAfterStart.message == "The class has to end after it starts.")
        draft.endTime = TimeOfDay(hour: 19, minute: 30)
        #expect(draft.isValid)
        draft.startTime = nil
        #expect(draft.isValid, "one time alone is allowed")
    }

    @Test func fromAClassAndBack() {
        let draft = ClassroomDraft(ClassroomTests.maths)
        #expect(draft.name == "Class 10 Maths" && draft.subject == "Mathematics" && draft.fee == Money(rupees: 1200))
        #expect(draft.meetingDays == [.monday, .wednesday, .friday] && draft.startTime?.text == "17:00" && draft.endTime?.text == "18:00")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `Classroom` not found.

- [ ] **Step 3: Implement**

`Domain/Classroom.swift`:

```swift
import Foundation

/// A class the tutor teaches (`classes`): its name, subject, fee, and when it meets. "Class" is the word on screen;
/// the type is `Classroom` so it never reads as the keyword.
public struct Classroom: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var subject: String?
    public var monthlyFee: Money?
    public var meetingDays: Set<Weekday>
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var archivedAt: Date?

    public init(
        id: UUID, name: String, subject: String?, monthlyFee: Money?, meetingDays: Set<Weekday>,
        startTime: TimeOfDay?, endTime: TimeOfDay?, archivedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.monthlyFee = monthlyFee
        self.meetingDays = meetingDays
        self.startTime = startTime
        self.endTime = endTime
        self.archivedAt = archivedAt
    }

    public var isArchived: Bool { archivedAt != nil }

    /// "Mon, Wed, Fri"; "Every day"; "No days set".
    public var daysSummary: String {
        if meetingDays.count == Weekday.allCases.count { return "Every day" }
        if meetingDays.isEmpty { return "No days set" }
        return meetingDays.sorted().map(\.short).joined(separator: ", ")
    }

    /// "17:00–18:00"; the one time that is set; nil when neither is.
    public var timeRange: String? {
        switch (startTime, endTime) {
        case let (start?, end?): TimeOfDay.range(start, end)
        case let (start?, nil): start.text
        case let (nil, end?): end.text
        case (nil, nil): nil
        }
    }

    /// "Mon, Wed, Fri · 17:00–18:00" (the class row, the class detail header).
    public var meetingSummary: String {
        [daysSummary, timeRange].compactMap { $0 }.joined(separator: " · ")
    }

    /// The days this class meets in the Monday-to-Sunday week that holds `day`, in order.
    public func meetings(inWeekOf day: Day, calendar: Calendar) -> [Day] {
        let monday = day.adding(days: -(day.weekday(in: calendar).rawValue - 1), calendar: calendar)
        return (0 ..< 7).map { monday.adding(days: $0, calendar: calendar) }
            .filter { meetingDays.contains($0.weekday(in: calendar)) }
    }
}
```

`Domain/ClassroomDraft.swift`:

```swift
/// What the class form holds and checks before it saves (the New class and Edit class boards).
public struct ClassroomDraft: Hashable, Sendable {
    public var name = ""
    public var subject = ""
    public var fee: Money?
    public var meetingDays: Set<Weekday> = []
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?

    public static let nameLimit = 80
    public static let feeCeiling = Money(rupees: 100_000)

    public enum Problem: Hashable, Sendable {
        case nameMissing, nameTooLong, feeTooHigh, endNotAfterStart

        public var message: String {
            switch self {
            case .nameMissing: "A class needs a name."
            case .nameTooLong: "Keep the name under 80 characters."
            case .feeTooHigh: "That's more than ₹1,00,000. Check the amount."
            case .endNotAfterStart: "The class has to end after it starts."
            }
        }
    }

    public init() {}

    public init(_ classroom: Classroom) {
        name = classroom.name
        subject = classroom.subject ?? ""
        fee = classroom.monthlyFee
        meetingDays = classroom.meetingDays
        startTime = classroom.startTime
        endTime = classroom.endTime
    }

    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var trimmedSubject: String? {
        let s = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    public var problems: Set<Problem> {
        var found = Set<Problem>()
        if trimmedName.isEmpty { found.insert(.nameMissing) }
        if trimmedName.count > Self.nameLimit { found.insert(.nameTooLong) }
        if let fee, fee > Self.feeCeiling { found.insert(.feeTooHigh) }
        if let startTime, let endTime, endTime <= startTime { found.insert(.endNotAfterStart) }
        return found
    }

    public var isValid: Bool { problems.isEmpty }
}
```

- [ ] **Step 4: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the class, its meeting summary and this week's meetings, the class draft and its problems"
```

### Task 3: Domain: the student, this month's fee, the student draft, the register's query (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Student.swift`, `MonthFee.swift`, `StudentDraft.swift`, `StudentQuery.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/StudentTests.swift`, `StudentDraftTests.swift`, `StudentQueryTests.swift`

**Interfaces:**
- Consumes: Tasks 1 and 2; `PhoneNumber` (Phase 2).
- Produces:

```swift
public struct MonthFee: Hashable, Sendable, Codable {
    public enum Status: String, Hashable, Sendable, Codable { case due, paid, waived }
    public enum PaidMethod: String, Hashable, Sendable, Codable { case upi, cash, other; public var label: String /* "UPI", "cash", "other" */ }
    public let amount: Money; public let status: Status; public let paidOn: Day?; public let paidMethod: PaidMethod?
    public init(amount:status:paidOn:paidMethod:)
}
public enum FeeMark: Hashable, Sendable { case paid(on: Day), due, waived; public var text: String }   // "Paid 4 Oct", "Due", "Waived"
public struct Student: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name, classID: UUID?, monthlyFee: Money?, parentName: String?, parentPhone: PhoneNumber?, dateOfBirth: Day?, gender: Gender?, notes: String?, archivedAt: Date?
    public var thisMonth: MonthFee?
    public init(id:name:classID:monthlyFee:parentName:parentPhone:dateOfBirth:gender:notes:archivedAt:thisMonth:)
    public var isArchived: Bool
    public var initials: String
    public var firstName: String                         // "Bir Bikram Singh" → "Bir"
    public func fee(in classroom: Classroom?) -> Money?  // own fee, else the class's, else nil
    public var feeMark: FeeMark?                         // from thisMonth
}
public struct StudentDraft: Hashable, Sendable {
    public var name = "", classID: UUID? = nil, fee: Money? = nil, parentName = "", parentDigits = "", dateOfBirth: Day? = nil, gender: Gender? = nil, notes = ""
    public init(); public init(_ student: Student)
    public enum Problem: Hashable, Sendable { case nameMissing, nameTooLong, parentNameTooLong, feeTooHigh, phoneInvalid, notesTooLong, birthDateOut; public var message: String }
    public func problems(today: Day) -> Set<Problem>; public func isValid(today: Day) -> Bool
    public var trimmedName: String; public var trimmedParentName: String?; public var trimmedNotes: String?; public var parentPhone: PhoneNumber?
    public static let nameLimit = 80, notesLimit = 2000, feeCeiling = Money(rupees: 100_000), earliestBirthYear = 1950
}
public enum StudentSort: String, CaseIterable, Hashable, Sendable { case name, fee; public var label: String }   // "Name", "Fee"
public enum StudentFilter: Hashable, Sendable { case all, classroom(UUID), unassigned, archived }
public enum StudentQuery {
    public static func apply(_ students: [Student], classes: [Classroom], search: String, filter: StudentFilter, sort: StudentSort) -> [Student]
    public static func matches(_ student: Student, search: String) -> Bool
    public static func matchRange(in text: String, search: String) -> Range<String.Index>?
    public static func matchesPhone(_ student: Student, search: String) -> Bool
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/StudentTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct StudentTests {
    static func student(_ name: String, fee: Money? = nil, classID: UUID? = nil, thisMonth: MonthFee? = nil, archived: Bool = false) -> Student {
        Student(
            id: UUID(), name: name, classID: classID, monthlyFee: fee, parentName: "Parent", parentPhone: PhoneNumber(e164: "+919799113211"),
            dateOfBirth: nil, gender: nil, notes: nil, archivedAt: archived ? Date() : nil, thisMonth: thisMonth
        )
    }

    @Test func theFeeIsTheirOwnElseTheClassesElseNothing() {
        let maths = ClassroomTests.maths
        #expect(Self.student("Akshita Rao").fee(in: maths) == Money(rupees: 1200))
        #expect(Self.student("Riya Sharma", fee: Money(rupees: 1500)).fee(in: maths) == Money(rupees: 1500))
        #expect(Self.student("Sahil Verma").fee(in: nil) == nil)
        #expect(Self.student("Sahil Verma", fee: Money(rupees: 800)).fee(in: nil) == Money(rupees: 800))
    }

    @Test func thisMonthsMarkInTheBoardsWords() {
        let paid = MonthFee(amount: Money(rupees: 1200), status: .paid, paidOn: Day(year: 2026, month: 10, day: 4), paidMethod: .upi)
        #expect(Self.student("A", thisMonth: paid).feeMark == .paid(on: Day(year: 2026, month: 10, day: 4)!))
        #expect(FeeMark.paid(on: Day(year: 2026, month: 10, day: 4)!).text == "Paid 4 Oct")
        #expect(Self.student("B", thisMonth: MonthFee(amount: .zero, status: .due, paidOn: nil)).feeMark?.text == "Due")
        #expect(Self.student("C", thisMonth: MonthFee(amount: .zero, status: .waived, paidOn: nil)).feeMark?.text == "Waived")
        #expect(Self.student("D").feeMark == nil)
    }

    @Test func initialsAndFirstName() {
        #expect(Self.student("Bir Bikram Singh").initials == "BB" && Self.student("Bir Bikram Singh").firstName == "Bir")
        #expect(Self.student("Dev").firstName == "Dev" && Self.student("Akshita Rao").isArchived == false)
    }
}
```

`Tests/DomainTests/StudentDraftTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct StudentDraftTests {
    let today = Day(year: 2026, month: 10, day: 7)!

    @Test func aNameIsEnoughAndEverythingElseIsOptional() {
        var draft = StudentDraft()
        #expect(draft.problems(today: today) == [.nameMissing] && StudentDraft.Problem.nameMissing.message == "The student needs a name.")
        draft.name = " Riya Sharma "
        #expect(draft.isValid(today: today) && draft.trimmedName == "Riya Sharma")
        #expect(draft.trimmedParentName == nil && draft.trimmedNotes == nil && draft.parentPhone == nil)
    }

    @Test func thePhoneGoesThroughPhoneNumberOrIsRefusedInWords() {
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        draft.parentDigits = "98111 2223"
        #expect(draft.problems(today: today) == [.phoneInvalid] && StudentDraft.Problem.phoneInvalid.message == "Needs 10 digits after +91.")
        draft.parentDigits = "098111 22233"
        #expect(draft.isValid(today: today) && draft.parentPhone?.e164 == "+919811122233")
    }

    @Test func limitsInWords() {
        var draft = StudentDraft()
        draft.name = String(repeating: "a", count: 81)
        draft.parentName = String(repeating: "b", count: 81)
        draft.notes = String(repeating: "c", count: 2001)
        draft.fee = Money(rupees: 100_001)
        draft.dateOfBirth = Day(year: 2026, month: 10, day: 8)
        #expect(draft.problems(today: today) == [.nameTooLong, .parentNameTooLong, .notesTooLong, .feeTooHigh, .birthDateOut])
        #expect(StudentDraft.Problem.notesTooLong.message == "Keep the notes under 2,000 characters.")
        #expect(StudentDraft.Problem.birthDateOut.message == "Check the date of birth.")
        draft.dateOfBirth = Day(year: 1949, month: 12, day: 31)
        #expect(draft.problems(today: today).contains(.birthDateOut))
        draft.dateOfBirth = Day(year: 2011, month: 3, day: 14)
        #expect(!draft.problems(today: today).contains(.birthDateOut))
    }

    @Test func fromAStudentAndBack() {
        var student = StudentTests.student("Akshita Rao", classID: ClassroomTests.maths.id)
        student.gender = .female
        student.notes = "Board exam in March."
        let draft = StudentDraft(student)
        #expect(draft.name == "Akshita Rao" && draft.classID == ClassroomTests.maths.id && draft.fee == nil)
        #expect(draft.parentName == "Parent" && draft.parentDigits == "9799113211" && draft.gender == .female && draft.notes == "Board exam in March.")
    }
}
```

`Tests/DomainTests/StudentQueryTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct StudentQueryTests {
    let maths = ClassroomTests.maths
    let science = Classroom(id: UUID(), name: "Class 8 Science", subject: "Science", monthlyFee: Money(rupees: 1000), meetingDays: [.tuesday, .thursday], startTime: nil, endTime: nil, archivedAt: nil)
    var students: [Student] {
        [
            StudentTests.student("Riya Sharma", fee: Money(rupees: 1500), classID: maths.id),
            StudentTests.student("Akshita Rao", classID: maths.id),
            StudentTests.student("Dev Kumar", classID: science.id),
            StudentTests.student("Sahil Verma", fee: Money(rupees: 800)),
            StudentTests.student("Old Student", classID: maths.id, archived: true),
        ]
    }
    func names(_ list: [Student]) -> [String] { list.map(\.name) }

    @Test func allIsActiveStudentsByName() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .name)
        #expect(names(out) == ["Akshita Rao", "Dev Kumar", "Riya Sharma", "Sahil Verma"])
    }

    @Test func feeSortIsHighestFirstUsingTheClassFeeThenName() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .fee)
        #expect(names(out) == ["Riya Sharma", "Akshita Rao", "Dev Kumar", "Sahil Verma"])
    }

    @Test func filtersByClassUnassignedAndArchived() {
        #expect(names(StudentQuery.apply(students, classes: [maths, science], search: "", filter: .classroom(science.id), sort: .name)) == ["Dev Kumar"])
        #expect(names(StudentQuery.apply(students, classes: [maths, science], search: "", filter: .unassigned, sort: .name)) == ["Sahil Verma"])
        #expect(names(StudentQuery.apply(students, classes: [maths, science], search: "", filter: .archived, sort: .name)) == ["Old Student"])
    }

    @Test func matchesNamesAndNumbersHoweverTyped() {
        let riya = students[0]
        for query in ["rao", "SHA", "sharma ", "98111", "+91 98111", "98111 22233", "9811122233"] {
            let hit = StudentQuery.matches(riya, search: query) || StudentQuery.matches(students[1], search: query)
            #expect(hit, "\(query)")
        }
        #expect(StudentQuery.matchesPhone(riya, search: "98111") == false, "Riya's parent in this fixture is +91 97991 13211")
        #expect(StudentQuery.matchesPhone(riya, search: "97991 13211"))
        #expect(!StudentQuery.matches(riya, search: "xyz"))
        let range = StudentQuery.matchRange(in: "Akshita Rao", search: "SH")
        #expect(range.map { String("Akshita Rao"[$0]) } == "sh")
        #expect(StudentQuery.matchRange(in: "Akshita Rao", search: "") == nil)
    }

    @Test func archivedStudentsAreFoundBySearchAndHiddenByAll() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "old", filter: .all, sort: .name)
        #expect(names(out) == ["Old Student"], "a search looks everywhere, in every class and the archive")
        let none = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .name)
        #expect(!names(none).contains("Old Student"))
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `Student`, `MonthFee`, `StudentDraft`, `StudentQuery` not found.

- [ ] **Step 3: Implement**

`Domain/MonthFee.swift`:

```swift
/// One month's invoice for a student (`fee_invoices` for the current period), as the register reads it; Phase 5 owns
/// the ledger.
public struct MonthFee: Hashable, Sendable, Codable {
    public enum Status: String, Hashable, Sendable, Codable { case due, paid, waived }

    public enum PaidMethod: String, Hashable, Sendable, Codable {
        case upi, cash, other

        public var label: String {
            switch self {
            case .upi: "UPI"
            case .cash: "cash"
            case .other: "other"
            }
        }
    }

    public let amount: Money
    public let status: Status
    public let paidOn: Day?
    public let paidMethod: PaidMethod?

    public init(amount: Money, status: Status, paidOn: Day?, paidMethod: PaidMethod? = nil) {
        self.amount = amount
        self.status = status
        self.paidOn = paidOn
        self.paidMethod = paidMethod
    }
}

/// The word under a student's fee in a row: "Paid 4 Oct" (ok), "Due" (due), "Waived" (neutral).
public enum FeeMark: Hashable, Sendable {
    case paid(on: Day)
    case due
    case waived

    public var text: String {
        switch self {
        case let .paid(day): "Paid \(day.shortText)"
        case .due: "Due"
        case .waived: "Waived"
        }
    }
}
```

`Domain/Student.swift`:

```swift
import Foundation

/// A student of the centre (`students`), with this month's invoice when there is one.
public struct Student: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var classID: UUID?
    /// nil means "the class fee" (`fee(in:)`).
    public var monthlyFee: Money?
    public var parentName: String?
    public var parentPhone: PhoneNumber?
    public var dateOfBirth: Day?
    public var gender: Gender?
    public var notes: String?
    public var archivedAt: Date?
    public var thisMonth: MonthFee?

    public init(
        id: UUID, name: String, classID: UUID?, monthlyFee: Money?, parentName: String?, parentPhone: PhoneNumber?,
        dateOfBirth: Day?, gender: Gender?, notes: String?, archivedAt: Date?, thisMonth: MonthFee?
    ) {
        self.id = id
        self.name = name
        self.classID = classID
        self.monthlyFee = monthlyFee
        self.parentName = parentName
        self.parentPhone = parentPhone
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.notes = notes
        self.archivedAt = archivedAt
        self.thisMonth = thisMonth
    }

    public var isArchived: Bool { archivedAt != nil }
    public var initials: String { NameInitials.of(name) }
    public var firstName: String { name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name }

    /// Their own fee, else the class's (the fee prefill rule), else nothing.
    public func fee(in classroom: Classroom?) -> Money? { monthlyFee ?? classroom?.monthlyFee }

    public var feeMark: FeeMark? {
        guard let thisMonth else { return nil }
        switch thisMonth.status {
        case .paid: return thisMonth.paidOn.map { .paid(on: $0) } ?? .due
        case .due: return .due
        case .waived: return .waived
        }
    }
}
```

`Domain/StudentDraft.swift`:

```swift
/// What the student form holds and checks (New student and Edit student boards). The phone is kept as the typed
/// national digits; `parentPhone` is the normalised number or nil.
public struct StudentDraft: Hashable, Sendable {
    public var name = ""
    public var classID: UUID?
    public var fee: Money?
    public var parentName = ""
    public var parentDigits = ""
    public var dateOfBirth: Day?
    public var gender: Gender?
    public var notes = ""

    public static let nameLimit = 80
    public static let notesLimit = 2000
    public static let feeCeiling = Money(rupees: 100_000)
    public static let earliestBirthYear = 1950

    public enum Problem: Hashable, Sendable {
        case nameMissing, nameTooLong, parentNameTooLong, feeTooHigh, phoneInvalid, notesTooLong, birthDateOut

        public var message: String {
            switch self {
            case .nameMissing: "The student needs a name."
            case .nameTooLong: "Keep the name under 80 characters."
            case .parentNameTooLong: "Keep the parent's name under 80 characters."
            case .feeTooHigh: "That's more than ₹1,00,000. Check the amount."
            case .phoneInvalid: PhoneNumber.invalidMessage
            case .notesTooLong: "Keep the notes under 2,000 characters."
            case .birthDateOut: "Check the date of birth."
            }
        }
    }

    public init() {}

    public init(_ student: Student) {
        name = student.name
        classID = student.classID
        fee = student.monthlyFee
        parentName = student.parentName ?? ""
        parentDigits = student.parentPhone?.nationalDigits ?? ""
        dateOfBirth = student.dateOfBirth
        gender = student.gender
        notes = student.notes ?? ""
    }

    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var trimmedParentName: String? { Self.nilIfEmpty(parentName) }
    public var trimmedNotes: String? { Self.nilIfEmpty(notes) }
    public var parentPhone: PhoneNumber? { PhoneNumber(indianDigits: parentDigits) }

    public func problems(today: Day) -> Set<Problem> {
        var found = Set<Problem>()
        if trimmedName.isEmpty { found.insert(.nameMissing) }
        if trimmedName.count > Self.nameLimit { found.insert(.nameTooLong) }
        if (trimmedParentName?.count ?? 0) > Self.nameLimit { found.insert(.parentNameTooLong) }
        if let fee, fee > Self.feeCeiling { found.insert(.feeTooHigh) }
        if !parentDigits.trimmingCharacters(in: .whitespaces).isEmpty, parentPhone == nil { found.insert(.phoneInvalid) }
        if (trimmedNotes?.count ?? 0) > Self.notesLimit { found.insert(.notesTooLong) }
        if let dateOfBirth, dateOfBirth > today || dateOfBirth.year < Self.earliestBirthYear { found.insert(.birthDateOut) }
        return found
    }

    public func isValid(today: Day) -> Bool { problems(today: today).isEmpty }

    private static func nilIfEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
```

`Domain/StudentQuery.swift`:

```swift
import Foundation

public enum StudentSort: String, CaseIterable, Hashable, Sendable {
    case name, fee

    public var label: String {
        switch self {
        case .name: "Name"
        case .fee: "Fee"
        }
    }
}

public enum StudentFilter: Hashable, Sendable {
    case all
    case classroom(UUID)
    case unassigned
    case archived
}

/// The register as the Students list shows it: a search over names and numbers across everyone, then the filter (All
/// hides the archived), then the sort.
public enum StudentQuery {
    public static func apply(
        _ students: [Student], classes: [Classroom], search: String, filter: StudentFilter, sort: StudentSort
    ) -> [Student] {
        let byID = Dictionary(uniqueKeysWithValues: classes.map { ($0.id, $0) })
        let searching = !normalised(search).isEmpty
        let kept = students.filter { student in
            if searching { return matches(student, search: search) }
            switch filter {
            case .all: return !student.isArchived
            case let .classroom(id): return !student.isArchived && student.classID == id
            case .unassigned: return !student.isArchived && student.classID == nil
            case .archived: return student.isArchived
            }
        }
        return kept.sorted { a, b in
            switch sort {
            case .name: return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .fee:
                let fa = a.fee(in: a.classID.flatMap { byID[$0] }) ?? .zero
                let fb = b.fee(in: b.classID.flatMap { byID[$0] }) ?? .zero
                return fa != fb ? fa > fb : a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        }
    }

    public static func matches(_ student: Student, search: String) -> Bool {
        matchRange(in: student.name, search: search) != nil || matchesPhone(student, search: search)
    }

    /// The typed digits (any +91, 0, spaces dropped) as a substring of the parent's national number.
    public static func matchesPhone(_ student: Student, search: String) -> Bool {
        let digits = search.filter { $0.isASCII && $0.isNumber }
        guard digits.count >= 3, let phone = student.parentPhone else { return false }
        var wanted = Substring(digits)
        if wanted.hasPrefix("91"), wanted.count > 10 { wanted = wanted.dropFirst(2) }
        if wanted.hasPrefix("0"), wanted.count > 10 { wanted = wanted.dropFirst() }
        return phone.nationalDigits.contains(wanted)
    }

    /// Where the search sits in the text, case and accents ignored, so the row can colour the letters that matched.
    public static func matchRange(in text: String, search: String) -> Range<String.Index>? {
        let query = normalised(search)
        guard !query.isEmpty else { return nil }
        return text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive])
    }

    private static func normalised(_ search: String) -> String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

- [ ] **Step 4: Run, format, lint, commit, open the pull request**

Run: `bun check`
Expected: green (the db step runs only when local Supabase is up; start it with `cd supabase && supabase start` so the whole check runs before the PR).

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the student, this month's fee, the student draft, the register's search, filter and sort"
git push -u origin phase-3/domain
gh pr create --title "Domain: students, classes, days and times, the register's rules" --body "$(cat <<'EOF'
Phase 3, PR 1 (plan/phase-03-plan.md, Tasks 1 to 3). Value types for the register (student, class, weekday, time of day, calendar day, gender, this month's fee) and the pure rules the phase file lists under "Domain rules, tested": fee prefill, meeting summary, this week's meetings, initials, search by name or number, filter, sort, draft validation in the tutor's words. No screen changes; nothing is seen.

Checked: `bun check` green; every rule has a Swift Testing test in DomainTests.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Merge when the check is green (no pictures: nothing is seen).

### Task 4: Data: the students and classes repositories, Supabase and fakes seeded from `seed.sql` (PR 2)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Students/StudentsRepository.swift`, `SupabaseStudentsRepository.swift`, `FakeStudentsRepository.swift`, `StudentRow.swift`
- Create: `ios/TutorCentralKit/Sources/Data/Classes/ClassesRepository.swift`, `SupabaseClassesRepository.swift`, `FakeClassesRepository.swift`, `ClassroomRow.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/StudentRowTests.swift`, `ClassroomRowTests.swift`, `FakeStudentsRepositoryTests.swift`, `FakeClassesRepositoryTests.swift`

**Interfaces:**
- Consumes: `Student`, `StudentDraft`, `MonthFee`, `Classroom`, `ClassroomDraft`, `Period`, `Day`, `PhoneNumber`, `Money` (Tasks 1 to 3); `SupabaseClient` (Phase 2's factory); `DayHeading.india`.
- Produces:

```swift
public protocol StudentsRepository: Sendable {
    /// Every student of the centre, archived included, each with this month's invoice (amount, status, paid day and method) when there is one.
    func students(centre: UUID, period: Period) async throws -> [Student]
    func create(_ draft: StudentDraft, centre: UUID) async throws -> Student
    func update(id: UUID, with draft: StudentDraft) async throws -> Student
    func setArchived(id: UUID, _ archived: Bool) async throws
    func delete(id: UUID) async throws
    /// One statement: these students move to the class (nil: to no class).
    func assign(studentIDs: [UUID], toClass classID: UUID?, centre: UUID) async throws
}
public protocol ClassesRepository: Sendable {
    func classes(centre: UUID) async throws -> [Classroom]      // archived included, by name
    func create(_ draft: ClassroomDraft, centre: UUID) async throws -> Classroom
    func update(id: UUID, with draft: ClassroomDraft) async throws -> Classroom
    func archive(id: UUID) async throws                          // archive_class (Task 6)
}
@MainActor public final class FakeStudentsRepository: StudentsRepository {
    public var students: [Student]; public var nextError: (any Error)?; public var delay: Duration?
    public private(set) var created: [StudentDraft], updated: [UUID], archivedCalls: [(UUID, Bool)], deleted: [UUID], assigned: [([UUID], UUID?)]
    public nonisolated static let seed: [Student]        // the ten of seed.sql, this month's invoices (six paid on 4 Oct 2026)
    public nonisolated static let few: [Student]         // Dev, Riya, Sahil: own fee, no class, no invoice
    public nonisolated static let akshita: UUID          // seed[0]
    public init(students: [Student] = [])
}
@MainActor public final class FakeClassesRepository: ClassesRepository {
    public var classes: [Classroom]; public var nextError: (any Error)?
    public private(set) var created: [ClassroomDraft], updated: [UUID], archived: [UUID]
    public nonisolated static let maths: Classroom, science: Classroom   // ids 3333…3331 and …3332 as seed.sql
    public nonisolated static let seed: [Classroom]
    public init(classes: [Classroom] = [])
}
struct StudentRow: Decodable { … func student(calendar: Calendar) -> Student }      // internal, tested with fixture JSON
struct ClassroomRow: Decodable { … var classroom: Classroom }
```

- [ ] **Step 1: Write the failing row-decoding tests**

`Tests/DataTests/StudentRowTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct StudentRowTests {
    static let json = """
    [{"id":"aaaaaaaa-0000-0000-0000-000000000001","name":"Akshita Rao","class_id":"33333333-3333-3333-3333-333333333331",
      "monthly_fee":null,"parent_name":"Priya Rao","parent_phone":"+919799113211","date_of_birth":null,"gender":null,
      "notes":null,"archived_at":null,"fee_invoices":[{"amount":1200,"status":"paid","paid_at":"2026-10-04T13:00:00+00:00","paid_method":"upi"}]},
     {"id":"aaaaaaaa-0000-0000-0000-000000000009","name":"Riya Sharma","class_id":"33333333-3333-3333-3333-333333333331",
      "monthly_fee":1500,"parent_name":"Neha Sharma","parent_phone":"+919811122233","date_of_birth":"2011-03-14","gender":"female",
      "notes":"Board exam in March.","archived_at":"2026-10-07T12:00:00+00:00","fee_invoices":[]}]
    """.data(using: .utf8)!

    @Test func decodesPostgRESTRowsIntoStudents() throws {
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: Self.json)
        let akshita = rows[0].student(calendar: DayHeading.india)
        #expect(akshita.name == "Akshita Rao" && akshita.monthlyFee == nil && akshita.parentPhone?.display == "+91 97991 13211")
        #expect(akshita.thisMonth == MonthFee(amount: Money(rupees: 1200), status: .paid, paidOn: Day(year: 2026, month: 10, day: 4), paidMethod: .upi))
        let riya = rows[1].student(calendar: DayHeading.india)
        #expect(riya.monthlyFee == Money(rupees: 1500) && riya.dateOfBirth == Day(year: 2011, month: 3, day: 14) && riya.gender == .female)
        #expect(riya.isArchived && riya.thisMonth == nil && riya.notes == "Board exam in March.")
    }

    @Test func aPaymentLateInTheEveningIsStillThatDayInIndia() throws {
        // 20:30 UTC on 4 October is 02:00 on 5 October in India.
        let json = Self.json.replacingOccurrences(of: "2026-10-04T13:00:00+00:00", with: "2026-10-04T20:30:00+00:00")
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: json)
        #expect(rows[0].student(calendar: DayHeading.india).thisMonth?.paidOn == Day(year: 2026, month: 10, day: 5))
    }
}

private extension Data {
    func replacingOccurrences(of a: String, with b: String) -> Data {
        String(decoding: self, as: UTF8.self).replacingOccurrences(of: a, with: b).data(using: .utf8)!
    }
}
```

`Tests/DataTests/ClassroomRowTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct ClassroomRowTests {
    @Test func decodesMeetingDaysAndTimes() throws {
        let json = """
        [{"id":"33333333-3333-3333-3333-333333333331","name":"Class 10 Maths","subject":"Mathematics","monthly_fee":1200,
          "meeting_days":[1,3,5],"start_time":"17:00:00","end_time":"18:00:00","archived_at":null}]
        """.data(using: .utf8)!
        let rows = try SupabaseClassesRepository.decoder.decode([ClassroomRow].self, from: json)
        let maths = rows[0].classroom
        #expect(maths.meetingDays == [.monday, .wednesday, .friday] && maths.meetingSummary == "Mon, Wed, Fri · 17:00–18:00")
        #expect(maths.monthlyFee == Money(rupees: 1200) && !maths.isArchived)
    }
}
```

`Tests/DataTests/FakeStudentsRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeStudentsRepositoryTests {
    @Test func theSeedIsTheTenOfSeedSQL() async throws {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let all = try await fake.students(centre: UUID(), period: Period(year: 2026, month: 10))
        #expect(all.count == 10 && all.map(\.name).sorted().first == "Akshita Rao")
        #expect(all.filter { $0.thisMonth?.status == .paid }.count == 6 && all.filter { $0.thisMonth?.status == .due }.count == 4)
        #expect(all.first { $0.name == "Sahil Verma" }?.classID == nil && all.first { $0.name == "Riya Sharma" }?.monthlyFee == Money(rupees: 1500))
        #expect(FakeStudentsRepository.few.count == 3 && FakeStudentsRepository.few.allSatisfy { $0.classID == nil && $0.thisMonth == nil })
    }

    @Test func writesChangeTheListAndAreRecorded() async throws {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.few)
        var draft = StudentDraft()
        draft.name = "Akshita Rao"
        draft.parentDigits = "9799113211"
        let made = try await fake.create(draft, centre: UUID())
        #expect(made.name == "Akshita Rao" && made.parentPhone?.e164 == "+919799113211" && fake.students.count == 4 && fake.created == [draft])
        draft.name = "Akshita R"
        let changed = try await fake.update(id: made.id, with: draft)
        #expect(changed.name == "Akshita R" && fake.students.first { $0.id == made.id }?.name == "Akshita R")
        try await fake.setArchived(id: made.id, true)
        #expect(fake.students.first { $0.id == made.id }?.isArchived == true)
        try await fake.assign(studentIDs: [made.id], toClass: FakeClassesRepository.maths.id, centre: UUID())
        #expect(fake.students.first { $0.id == made.id }?.classID == FakeClassesRepository.maths.id)
        try await fake.delete(id: made.id)
        #expect(fake.students.count == 3 && fake.deleted == [made.id])
    }

    @Test func aScriptedErrorFiresOnce() async {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        fake.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await fake.setArchived(id: FakeStudentsRepository.akshita, true) }
        await #expect(throws: Never.self) { try await fake.setArchived(id: FakeStudentsRepository.akshita, true) }
    }
}
```

`Tests/DataTests/FakeClassesRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeClassesRepositoryTests {
    @Test func theSeedIsTheTwoOfSeedSQLAndWritesAreRecorded() async throws {
        let fake = FakeClassesRepository(classes: FakeClassesRepository.seed)
        let all = try await fake.classes(centre: UUID())
        #expect(all.map(\.name) == ["Class 10 Maths", "Class 8 Science"])
        #expect(all[1].meetingSummary == "Tue, Thu · 16:30–17:30" && all[1].monthlyFee == Money(rupees: 1000))
        var draft = ClassroomDraft()
        draft.name = "Class 12 Physics"
        draft.meetingDays = [.tuesday, .thursday, .saturday]
        let made = try await fake.create(draft, centre: UUID())
        #expect(made.name == "Class 12 Physics" && fake.classes.count == 3 && fake.created == [draft])
        try await fake.archive(id: made.id)
        #expect(fake.classes.first { $0.id == made.id }?.isArchived == true && fake.archived == [made.id])
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, the repositories do not exist.

- [ ] **Step 3: Implement the protocols and the rows**

`Data/Students/StudentsRepository.swift` and `Data/Classes/ClassesRepository.swift`: the two protocols above, with the doc comments.

`Data/Students/StudentRow.swift`:

```swift
import Domain
import Foundation

/// A `students` row with this month's invoice embedded (`fee_invoices(amount, status, paid_at)` filtered by period).
struct StudentRow: Decodable {
    struct Invoice: Decodable {
        let amount: Int
        let status: String
        let paidAt: Date?
        let paidMethod: String?
    }

    let id: UUID
    let name: String
    let classId: UUID?
    let monthlyFee: Int?
    let parentName: String?
    let parentPhone: String?
    let dateOfBirth: String?
    let gender: String?
    let notes: String?
    let archivedAt: Date?
    let feeInvoices: [Invoice]

    func student(calendar: Calendar) -> Student {
        Student(
            id: id,
            name: name,
            classID: classId,
            monthlyFee: monthlyFee.map(Money.init(rupees:)),
            parentName: parentName,
            parentPhone: parentPhone.flatMap(PhoneNumber.init(e164:)),
            dateOfBirth: dateOfBirth.flatMap(Day.init(iso:)),
            gender: gender.flatMap(Gender.init(rawValue:)),
            notes: notes,
            archivedAt: archivedAt,
            thisMonth: feeInvoices.first.flatMap { invoice in
                MonthFee.Status(rawValue: invoice.status).map {
                    MonthFee(amount: Money(rupees: invoice.amount), status: $0, paidOn: invoice.paidAt.map { Day($0, calendar: calendar) }, paidMethod: invoice.paidMethod.flatMap(MonthFee.PaidMethod.init(rawValue:)))
                }
            }
        )
    }
}
```

`Data/Classes/ClassroomRow.swift`:

```swift
import Domain
import Foundation

struct ClassroomRow: Decodable {
    let id: UUID
    let name: String
    let subject: String?
    let monthlyFee: Int?
    let meetingDays: [Int]
    let startTime: String?
    let endTime: String?
    let archivedAt: Date?

    var classroom: Classroom {
        Classroom(
            id: id, name: name, subject: subject, monthlyFee: monthlyFee.map(Money.init(rupees:)),
            meetingDays: Set(meetingDays.compactMap(Weekday.init(rawValue:))),
            startTime: startTime.flatMap(TimeOfDay.init(iso:)), endTime: endTime.flatMap(TimeOfDay.init(iso:)),
            archivedAt: archivedAt
        )
    }
}
```

Both decode with a shared decoder: `keyDecodingStrategy = .convertFromSnakeCase` and a date strategy that accepts PostgREST's timestamps with or without fractional seconds (`ISO8601DateFormatter` with `.withInternetDateTime` then `.withFractionalSeconds`). Put it on each repository as `static let decoder: JSONDecoder` (the tests name `SupabaseStudentsRepository.decoder` and `SupabaseClassesRepository.decoder`); the two share one private function `PostgREST.decoder()` in `Data/Students/StudentRow.swift`'s file or a small `Data/PostgRESTDecoder.swift`.

- [ ] **Step 4: Implement the Supabase repositories**

`Data/Students/SupabaseStudentsRepository.swift`:

```swift
import Domain
import Foundation
import Supabase

/// The register through PostgREST: RLS scopes everything to the member's centre; the centre id is still sent so an
/// index serves the read.
public final class SupabaseStudentsRepository: StudentsRepository {
    private let client: SupabaseClient
    private let calendar: Calendar
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, name, class_id, monthly_fee, parent_name, parent_phone, date_of_birth, gender, notes, archived_at"

    public init(client: SupabaseClient, calendar: Calendar = DayHeading.india) {
        self.client = client
        self.calendar = calendar
    }

    public func students(centre: UUID, period: Period) async throws -> [Student] {
        let response = try await client.from("students")
            .select("\(Self.columns), fee_invoices(amount, status, paid_at, paid_method)")
            .eq("centre_id", value: centre)
            .eq("fee_invoices.period", value: period.isoDay)
            .order("name")
            .execute()
        return try Self.decoder.decode([StudentRow].self, from: response.data).map { $0.student(calendar: calendar) }
    }

    public func create(_ draft: StudentDraft, centre: UUID) async throws -> Student {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("students").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    public func update(id: UUID, with draft: StudentDraft) async throws -> Student {
        let response = try await client.from("students").update(Self.values(draft)).eq("id", value: id).select(Self.columns).single().execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    public func setArchived(id: UUID, _ archived: Bool) async throws {
        let value: AnyJSON = archived ? .string(ISO8601DateFormatter().string(from: Date())) : .null
        try await client.from("students").update(["archived_at": value]).eq("id", value: id).execute()
    }

    public func delete(id: UUID) async throws {
        try await client.from("students").delete().eq("id", value: id).execute()
    }

    public func assign(studentIDs: [UUID], toClass classID: UUID?, centre: UUID) async throws {
        guard !studentIDs.isEmpty else { return }
        try await client.from("students")
            .update(["class_id": classID.map { AnyJSON.string($0.uuidString) } ?? .null])
            .eq("centre_id", value: centre)
            .in("id", values: studentIDs.map(\.uuidString))
            .execute()
    }

    /// Every column the form owns, nulls included, so an edit clears what the tutor cleared.
    static func values(_ draft: StudentDraft) -> [String: AnyJSON] {
        [
            "name": .string(draft.trimmedName),
            "class_id": draft.classID.map { .string($0.uuidString) } ?? .null,
            "monthly_fee": draft.fee.map { .integer($0.rupees) } ?? .null,
            "parent_name": draft.trimmedParentName.map(AnyJSON.string) ?? .null,
            "parent_phone": draft.parentPhone.map { .string($0.e164) } ?? .null,
            "date_of_birth": draft.dateOfBirth.map { .string($0.iso) } ?? .null,
            "gender": draft.gender.map { .string($0.rawValue) } ?? .null,
            "notes": draft.trimmedNotes.map(AnyJSON.string) ?? .null,
        ]
    }
}
```

Note: the embedded `fee_invoices` rows for a student without this month's invoice come back as `[]`, never as a missing key, because the row is selected through the student; the student stays in the result (no `!inner`). `StudentRow.Invoice.paidAt` decodes PostgREST's `timestamptz` text through the decoder's date strategy; `archived_at` likewise.

`Data/Classes/SupabaseClassesRepository.swift`:

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseClassesRepository: ClassesRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, name, subject, monthly_fee, meeting_days, start_time, end_time, archived_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func classes(centre: UUID) async throws -> [Classroom] {
        let response = try await client.from("classes").select(Self.columns).eq("centre_id", value: centre).order("name").execute()
        return try Self.decoder.decode([ClassroomRow].self, from: response.data).map(\.classroom)
    }

    public func create(_ draft: ClassroomDraft, centre: UUID) async throws -> Classroom {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("classes").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(ClassroomRow.self, from: response.data).classroom
    }

    public func update(id: UUID, with draft: ClassroomDraft) async throws -> Classroom {
        let response = try await client.from("classes").update(Self.values(draft)).eq("id", value: id).select(Self.columns).single().execute()
        return try Self.decoder.decode(ClassroomRow.self, from: response.data).classroom
    }

    public func archive(id: UUID) async throws {
        try await client.rpc("archive_class", params: ["p_class": AnyJSON.string(id.uuidString)]).execute()
    }

    static func values(_ draft: ClassroomDraft) -> [String: AnyJSON] {
        [
            "name": .string(draft.trimmedName),
            "subject": draft.trimmedSubject.map(AnyJSON.string) ?? .null,
            "monthly_fee": draft.fee.map { .integer($0.rupees) } ?? .null,
            "meeting_days": .array(draft.meetingDays.sorted().map { .integer($0.rawValue) }),
            "start_time": draft.startTime.map { .string($0.iso) } ?? .null,
            "end_time": draft.endTime.map { .string($0.iso) } ?? .null,
        ]
    }
}
```

`Data/PostgRESTDecoder.swift`:

```swift
import Foundation

/// PostgREST writes snake_case keys and timestamps with or without fractional seconds.
enum PostgRESTDecoder {
    static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let plain = ISO8601DateFormatter()
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: text) ?? plain.date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "not a timestamp: \(text)"))
        }
        return decoder
    }
}
```

- [ ] **Step 5: Implement the fakes with the seed**

`Data/Students/FakeStudentsRepository.swift`: a `@MainActor final class` as the interface says; each write throws `nextError` once (the `takeError()` pattern of `FakeCentreRepository`), sleeps `delay` when set, then mutates `students` and records the call. `create` makes `Student(id: UUID(), …)` from the draft (`trimmedName`, `classID`, `fee`, `trimmedParentName`, `parentPhone`, `dateOfBirth`, `gender`, `trimmedNotes`, `archivedAt: nil`, `thisMonth: nil`); `update` applies the same fields to the stored student, keeping `thisMonth` and `archivedAt`; `setArchived` sets `archivedAt` to `FakeCountsRepository.fixedNow` or nil; `assign` sets `classID` on the given ids; `delete` removes.

The seed, with fixed ids so the fixtures can name them (`aaaaaaaa-0000-0000-0000-0000000000NN`, NN 01 to 10 in the order below) and the paid day `Day(year: 2026, month: 10, day: 4)`, `paidMethod: .upi` (as `seed.sql` pays):

| NN | Name | Class | Own fee | Parent | Phone | This month |
|---|---|---|---|---|---|---|
| 01 | Akshita Rao | maths | – | Priya Rao | +919799113211 | ₹1,200 paid |
| 02 | Ananya Iyer | maths | – | Suresh Iyer | +917903092566 | ₹1,200 paid |
| 03 | Bir Bikram Singh | maths | – | Harjeet Singh | +917899487677 | ₹1,200 paid |
| 04 | Dev Kumar | science | ₹1,000 | Ramesh Kumar | +919884843831 | ₹1,000 due |
| 05 | Hemanth Reddy | maths | – | Lakshmi Reddy | +919380260871 | ₹1,200 due |
| 06 | Lakshmi Menon | maths | – | Anil Menon | +919972873953 | ₹1,200 paid |
| 07 | Meher Shah | science | – | Kavita Shah | +919176590665 | ₹1,000 paid |
| 08 | Nikhil Das | science | – | Arup Das | +919830012345 | ₹1,000 due |
| 09 | Riya Sharma | maths | ₹1,500 | Neha Sharma | +919811122233 | ₹1,500 paid |
| 10 | Sahil Verma | – | ₹800 | Deepak Verma | +919900011122 | ₹800 due |

`few` is Dev, Riya and Sahil with the same ids, `classID: nil`, `thisMonth: nil`. `akshita` is the id of 01.

`Data/Classes/FakeClassesRepository.swift`: likewise; `maths` = `Classroom(id: 33333333-3333-3333-3333-333333333331, name: "Class 10 Maths", subject: "Mathematics", monthlyFee: 1200, meetingDays: [.monday, .wednesday, .friday], startTime: 17:00, endTime: 18:00, archivedAt: nil)`, `science` = `…3332, "Class 8 Science", "Science", 1000, [.tuesday, .thursday], 16:30, 17:30`. `archive` sets `archivedAt` and (as the function does) is followed by the store detaching the members; the fake itself only marks the class.

- [ ] **Step 6: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git checkout -b phase-3/data
git add ios/TutorCentralKit
git commit -m "Data: students and classes repositories through PostgREST, the fakes seeded as seed.sql"
```

### Task 5: Data: the JSON cache (PR 2)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Cache/JSONCache.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/JSONCacheTests.swift`

**Interfaces:**
- Produces:

```swift
/// One Codable value in one file under Application Support/TutorCentral (or the directory given), so a list shows at
/// once on the next launch while the network refreshes it. Dates as ISO 8601.
public struct JSONCache<Value: Codable & Sendable>: Sendable {
    public init(name: String, directory: URL? = nil)   // nil: Application Support/TutorCentral
    public var url: URL
    public func load() -> Value?                        // nil when missing or unreadable (never throws: a cache is a convenience)
    public func save(_ value: Value) throws             // creates the directory, writes atomically
    public func remove()
}
```

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Data

struct JSONCacheTests {
    struct Note: Codable, Equatable, Sendable { let text: String; let at: Date }

    @Test func savesLoadsAndRemoves() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = JSONCache<[Note]>(name: "notes", directory: dir)
        #expect(cache.load() == nil)
        let notes = [Note(text: "a", at: Date(timeIntervalSince1970: 1_000_000))]
        try cache.save(notes)
        #expect(cache.load() == notes && cache.url.lastPathComponent == "notes.json")
        cache.remove()
        #expect(cache.load() == nil)
    }

    @Test func aCorruptFileReadsAsNothing() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = JSONCache<[Note]>(name: "bad", directory: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "not json".data(using: .utf8)!.write(to: cache.url)
        #expect(cache.load() == nil)
    }
}
```

- [ ] **Step 2: Run to see it fail; implement**

```swift
import Foundation

public struct JSONCache<Value: Codable & Sendable>: Sendable {
    public let url: URL

    public init(name: String, directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        url = base.appendingPathComponent("\(name).json")
    }

    public func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? Self.decoder.decode(Value.self, from: data)
    }

    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.encoder.encode(value).write(to: url, options: .atomic)
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}
```

- [ ] **Step 3: Run, format, lint, commit, open the pull request**

Run: `bun check`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Data: a JSON cache so the register shows at once and refreshes behind"
git push -u origin phase-3/data
gh pr create --title "Data: students and classes repositories, the fakes with the seed, the JSON cache" --body "$(cat <<'EOF'
Phase 3, PR 2 (Tasks 4 and 5). The two repositories as protocols with PostgREST implementations (one read per list, this month's invoice embedded; writes as column maps so an edit clears what the tutor cleared; one RPC for archive_class, which PR 3 adds) and in-memory fakes carrying seed.sql's ten students and two classes with fixed ids for the fixtures. A JSON cache for the stale pattern. Nothing seen.

Checked: `bun check` green; row decoding tested with PostgREST-shaped JSON (a payment at 20:30 UTC is the next day in India); the fakes and the cache tested.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Merge when green.

### Task 6: Migration 0003: `archive_class`; the delete cascade proven (PR 3)

**Files:**
- Create: `supabase/migrations/20261009000003_archive_class.sql`
- Modify: `supabase/tests/rls.test.ts` (two tests, placed before "only the owner can delete the centre"), `supabase/types.ts` (regenerated)

**Interfaces:**
- Produces: `public.archive_class(p_class uuid) returns void`, `security invoker`: marks the class archived (idempotent) and sets `class_id = null` on its students; raises `42501` when the caller cannot see the class.

- [ ] **Step 1: Write the failing tests** (insert before the `only the owner can delete the centre` test, which empties centre A)

```ts
test("archive_class detaches members and is refused to a non-member", async () => {
  const cls = await a.from("classes").insert({ centre_id: centreA, name: "To archive", monthly_fee: 900 }).select("id").single();
  expect(cls.error).toBeNull();
  const kept = await a.from("students").insert({ centre_id: centreA, name: "Keeps own fee", class_id: cls.data!.id, monthly_fee: 700 }).select("id").single();
  const plain = await a.from("students").insert({ centre_id: centreA, name: "On class fee", class_id: cls.data!.id }).select("id").single();
  expect((await b.rpc("archive_class", { p_class: cls.data!.id })).error).not.toBeNull();
  expect((await a.rpc("archive_class", { p_class: cls.data!.id })).error).toBeNull();
  const after = await a.from("classes").select("archived_at").eq("id", cls.data!.id).single();
  expect(after.data!.archived_at).not.toBeNull();
  const members = await a.from("students").select("name, class_id, monthly_fee, archived_at").in("id", [kept.data!.id, plain.data!.id]).order("name");
  expect(members.data).toEqual([
    { name: "Keeps own fee", class_id: null, monthly_fee: 700, archived_at: null },
    { name: "On class fee", class_id: null, monthly_fee: null, archived_at: null },
  ]);
  expect((await a.rpc("archive_class", { p_class: cls.data!.id })).error).toBeNull(); // idempotent
});

test("deleting a student cascades to invoices and marks and detaches message_log", async () => {
  const s = await a.from("students").insert({ centre_id: centreA, name: "Leaving", monthly_fee: 500 }).select("id").single();
  const session = await a.from("attendance_sessions").insert({ centre_id: centreA, date: "2026-10-06" }).select("id").single();
  expect((await a.from("fee_invoices").insert({ centre_id: centreA, student_id: s.data!.id, period: "2026-07-01", amount: 500 })).error).toBeNull();
  expect((await a.from("attendance_marks").insert({ centre_id: centreA, session_id: session.data!.id, student_id: s.data!.id, status: "present" })).error).toBeNull();
  const log = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "reminder" }).select("id").single();
  expect((await a.from("students").delete().eq("id", s.data!.id)).error).toBeNull();
  expect((await a.from("fee_invoices").select("id").eq("student_id", s.data!.id)).data).toEqual([]);
  expect((await a.from("attendance_marks").select("id").eq("student_id", s.data!.id)).data).toEqual([]);
  expect((await a.from("message_log").select("student_id").eq("id", log.data!.id)).data).toEqual([{ student_id: null }]);
  expect((await a.from("attendance_sessions").select("id").eq("id", session.data!.id)).data?.length).toBe(1);
});
```

- [ ] **Step 2: Run to see them fail**

Run: `cd supabase && supabase start && bun check --only=db` (from the repo root)
Expected: FAIL, `archive_class` does not exist.

- [ ] **Step 3: The migration**

`supabase/migrations/20261009000003_archive_class.sql`:

```sql
-- Archive a class (Phase 3): it leaves every list and count; its students stay, with no class. Two statements in one
-- transaction, so a function; security invoker, so RLS decides what the caller may touch.

create function public.archive_class(p_class uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare cid uuid;
begin
  update public.classes set archived_at = coalesce(archived_at, now()) where id = p_class returning centre_id into cid;
  if cid is null then raise exception 'no such class' using errcode = '42501'; end if;
  update public.students set class_id = null where centre_id = cid and class_id = p_class;
end $$;

revoke all on function public.archive_class(uuid) from public, anon;
grant execute on function public.archive_class(uuid) to authenticated;
```

Then: `cd supabase && supabase db reset && supabase gen types typescript --local > types.ts`.

- [ ] **Step 4: Run, commit, open the pull request; after merge, deploy**

Run: `bun check`
Expected: green, including `db` (the catalogue test finds the function granted to `authenticated` only).

```bash
git checkout -b phase-3/archive-class
git add supabase
git commit -m "Migration 0003: archive_class detaches a class's students; the delete cascade proven"
git push -u origin phase-3/archive-class
gh pr create --title "Migration 0003: archive_class; the delete cascade proven" --body "$(cat <<'EOF'
Phase 3, PR 3 (Task 6). One additive migration: archive_class(p_class) marks the class archived and sets its students' class_id to null in one transaction (security invoker; public and anon revoked, authenticated granted). Two RLS tests: a non-member is refused and members are detached keeping their own fee; deleting a student cascades to invoices and marks and detaches message_log. types.ts regenerated.

Checked: `bun check` green with the db step against the local stack.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

After merge: `gh workflow run deploy`, then `gh run watch` the run; the summary shows `20261009000003_archive_class.sql` pending then applied and nothing after; `/health` reports the merged commit. Record the run in `STATE.md` at Task 19. The TestFlight lane refuses a build until this has run (D26).

### Task 7: DesignSystem: the Phase 3 components (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Components/SearchWell.swift`, `FilterChip.swift`, `DayPicker.swift`, `Banner.swift`, `Tiles.swift`, `NotesWell.swift`
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/Rows.swift` (`StudentRow`; `MemberRow`, `MeetingRow`, `ChecklistRow`), `Avatar.swift` (`Avatar(initials:size:)`, `IconTile(symbol:size:)`), `IconButton.swift` (`IconButtonLook`)

Every value is in `components.md` (the Phase 3 additions) or an anatomy constant named on the component, as Phase 2 ruled; no new token is foreseen. Each component gets a `#Preview` in both appearances; the Kit screen is not changed (decisions table).

**Interfaces:**
- Produces:

```swift
/// The system search field as the boards draw it: a well 44 high, magnifyingglass 18 text3, the placeholder in text3,
/// the clear mark when there is text, and a quiet Cancel to the right while searching.
public struct SearchWell: View {
    public init(text: Binding<String>, placeholder: String, isSearching: Binding<Bool>, showsFocus: Bool = false)
    static var height: CGFloat { 44 }
}
/// Off: a neutral chip. On: accentTint fill, accentText 700. Padding 0 12. Selection haptic.
public struct FilterChip: View { public init(_ label: String, isOn: Bool, action: @escaping () -> Void) }
/// Seven round toggles 40 spread across the width; the caller passes the days (DesignSystem does not know Domain).
public struct DayPicker: View {
    public struct Item: Identifiable, Hashable, Sendable { public let id: Int; public let initial: String; public let name: String; public init(id:initial:name:) }
    public init(items: [Item], selection: Binding<Set<Int>>)
    static var size: CGFloat { 40 }
}
/// One line of state under a header: surface2, radius 12, padding 8 14, footnote text2 with a symbol 14 (the offline bar's pattern).
public struct Banner: View { public init(symbol: String, text: String) }
/// A tile on a sheet: surface2 fill, line border, radiusControl, 46 high, padding 0 14, label body left, `trailing` right.
public struct TileRow<Trailing: View>: View { public init(label: String, labelTone: ColorToken = Tokens.text, @ViewBuilder trailing: () -> Trailing) }
/// The picker tile: a TileRow whose trailing is the value in accentText bodyStrong with chevron.up.chevron.down.
public struct PickerTile: View { public init(label: String, value: String, action: @escaping () -> Void) }
/// A multiline well: TextEditor at least 96 high, the counter "47 of 2,000" in caption text3 at the bottom right.
public struct NotesWell: View { public init(label: String, text: Binding<String>, placeholder: String, limit: Int, error: String? = nil) }

// Rows.swift
public struct StudentRow: View {
    /// `nameMatch` colours the letters a search matched in accentText. `status` is nil when the month has no invoice;
    /// a nil tone is text2 (Waived).
    public init(initials: String, name: String, nameMatch: Range<String.Index>? = nil, detail: String, fee: String?,
                status: (tone: StatusTone?, text: String)? = nil, action: (() -> Void)? = nil)
}
/// Member (class detail): avatar 40; name; parent phone; trailing "Class fee" footnote text2, or the student's own fee in numberRow; chevron.
public struct MemberRow: View { public init(initials: String, name: String, phone: String, fee: String?, action: @escaping () -> Void) }
/// Meeting (class detail): the day (time, text2, width 46) · the date (rowTitle) · the time range (footnote text2); today's row on surface2 with its day in accentText 700.
public struct MeetingRow: View { public init(day: String, title: String, time: String?, isToday: Bool) }
/// Checklist (add students): avatar 40; name; detail; a checkbox 24 on the right; the whole row toggles.
public struct ChecklistRow: View { public init(initials: String, name: String, detail: String, isOn: Binding<Bool>) }

// Avatar.swift
public struct Avatar: View { public init(initials: String, size: CGFloat = 40); public init(name: String, size: CGFloat = 40) /* keeps delegating to initials(of:) */ }
public struct IconTile: View { public init(symbol: String, size: Size = .row); public enum Size { case row /* 40, radius 12 */, header /* 56, radiusTile */ } }

// IconButton.swift
/// The look of an icon button without the Button, for a Menu or popover anchor that needs the same 40 round surface.
public struct IconButtonLook: View { public init(symbol: String) }
```

- [ ] **Step 1: Build each component to its words** (there is no logic to test first; the views are proven by the screenshots of Tasks 9 to 17 against the boards)

`SearchWell`: `Well`-like frame of its own (46 is a field; this is 44: `Self.height`), `Tokens.well` fill, `Tokens.line` border (`Tokens.accent` and `haloFocus` when focused or `showsFocus`), `radiusControl`, `shadowWell`; `HStack(spacing: Tokens.inline)` of `Image(systemName: "magnifyingglass")` at `Tokens.iconSmall` in `text3`, the `TextField` in `body` with the placeholder in `text3`, `.submitLabel(.search)`, `.autocorrectionDisabled()`, `.textInputAutocapitalization(.never)`, `@FocusState`; when `!text.isEmpty` a clear mark (`xmark.circle.fill`, `iconInline`, `text3`, label "Clear") that empties the text; outside the well, when `isSearching`, a `Button("Cancel")` `.buttonStyle(.quiet)` that clears the text, drops focus and sets `isSearching = false`. `isSearching` becomes true on focus or when text is typed; the view sets it, the owner reads it to collapse the title.

`FilterChip`: `Button(label, action:)` with `Chip`'s height 28 and radius, padding `0 12` (`Self.padding = 12`), `Tokens.chipLabel` when on else `Tokens.chipNeutralLabel`, colours as the interface says, `.pressable()`, `Haptic.play(.selection)` in the action, `.accessibilityAddTraits(isOn ? .isSelected : [])`.

`DayPicker`: `HStack { ForEach(items) { item in Button(item.initial) … } }` with `.frame(maxWidth: .infinity)` spacers so seven 40-point discs spread across the content width; on: `Tokens.accent` fill, `Tokens.textOnAccent`, `Tokens.segmentActive`; off: `Tokens.surface2` fill, `Tokens.lineStrong` stroke, `Tokens.text2`, `Tokens.segment`; `accessibilityLabel(item.name)`, `.isSelected` trait when on; selection haptic.

`Banner`: as the interface; `radius` 12 is an anatomy constant (`Self.radius`), the symbol at 14 (`Self.symbolSize`), text `Tokens.footnote` in `text2`.

`TileRow`, `PickerTile`: `TileRow` is `HStack { Text(label).typeStyle(Tokens.body).foregroundStyle(labelTone.color); Spacer(); trailing }` padded `0 14` (`Tokens.cardPaddingCompact`), `frame(height: Well<EmptyView>.height)`, `Tokens.surface2` background in `radiusControl`, `Tokens.line` stroke. `PickerTile` wraps it in a `Button` whose trailing is `Text(value).typeStyle(Tokens.bodyStrong).foregroundStyle(Tokens.accentText.color)` plus `Image(systemName: "chevron.up.chevron.down")` at `iconInline`; `.pressable()`; `accessibilityValue(value)`.

`NotesWell`: `Well(label:…, error:, focused:, height: nil)` holding a `ZStack(alignment: .bottomTrailing)` of a `TextEditor` (`.scrollContentBackground(.hidden)`, `Tokens.body`, min height `Self.minHeight = 96`, bottom padding `Self.counterInset = 28`) with the placeholder drawn in `text3` when empty, and the counter `Text("\(text.count.formatted()) of \(limit.formatted())")` in `Tokens.caption` `text3` (the `formatted()` gives "2,000"; the number locale is the device's: `en_IN` on the owner's phone also writes "2,000").

`Rows.swift`: `StudentRow` as the interface, keeping `ListRow`, `RowTitles` (give `RowTitles` an optional `titleMatch: Range<String.Index>?` that renders the title as an `AttributedString` with `Tokens.accentText` over the range); the trailing column shows `fee` in `numberRow` and, under it, `status.text` in `captionStrong` coloured `status.tone?.color ?? Tokens.text2`; when `fee` is nil nothing is drawn on the right but the chevron. `MemberRow`, `MeetingRow`, `ChecklistRow` as the interface: `MeetingRow` uses `Tokens.time` for the day at width 46 (`Self.dayWidth`), `Tokens.rowTitle` for the title, `Tokens.footnote` `text2` for the time, and when `isToday` a `Tokens.surface2` background with the day in `accentText` and `segmentActive` weight; `ChecklistRow` is a `Button` toggling `isOn` with `Checkbox` drawn non-interactively on the right and `accessibilityAddTraits(.isToggle)`.

`Avatar(initials:size:)`: the existing body takes the initials from the new initializer; `Avatar(name:)` calls `Self.initials(of:)` then the new one. `IconTile(symbol:size:)`: `.row` is 40 with radius 12 (today's values), `.header` is 56 with `Tokens.radiusTile` and the symbol at 28 (`EmptyState.symbolSize`'s value; name it `Self.headerSymbol = 28`).

`IconButtonLook`: the 40 round `surface2`/`buttonFill` disc with `lineStrong` border and `shadowButton`, the symbol 20 in `text`, that `IconButton` already draws; `IconButton` uses it inside its `Button`.

- [ ] **Step 2: Build, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green (the Kit screenshots are unchanged: nothing in the Kit uses the new views).

```bash
git checkout -b phase-3/students-list
git add ios/TutorCentralKit
git commit -m "DesignSystem: the search well, filter chip, day picker, banner, tiles, notes well, member, meeting and checklist rows"
```

### Task 8: Features/Students: `RegisterStore`, its cache and actions (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/RegisterStore.swift`, `RegisterCache.swift`, `StudentsActions.swift`
- Delete: `ios/TutorCentralKit/Sources/Features/Students/Students.swift` (the Phase 2 marker)
- Modify: `ios/TutorCentralKit/Package.swift` (`StudentsTests`), `ios/project.yml` (the scheme)
- Test: `ios/TutorCentralKit/Tests/StudentsTests/RegisterStoreTests.swift`

**Interfaces:**
- Consumes: `StudentsRepository`, `ClassesRepository`, the fakes (Task 4); `JSONCache` (Task 5); `StudentQuery`, `StudentFilter`, `StudentSort`, `Period`, `Day` (Tasks 1 to 3).
- Produces:

```swift
/// What the Students tab remembers while the tutor works in one centre: the register, the query and every write.
@MainActor @Observable public final class RegisterStore {
    public init(workspace: Workspace, students: any StudentsRepository, classes: any ClassesRepository,
                cache: RegisterCache?, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
    public private(set) var students: [Student]          // everyone, archived included
    public private(set) var classes: [Classroom]         // archived included
    public private(set) var loading: Bool                // the first load with nothing cached (skeleton)
    public private(set) var refreshing: Bool             // a refresh over cached rows (stale pattern)
    public private(set) var error: String?               // "Couldn't refresh. Check your connection and try again."
    public var message: String?                          // one line for a toast, consumed by the view
    public private(set) var canRetry: Bool               // the last failed write can be retried
    public var search: String; public var filter: StudentFilter; public var sort: StudentSort
    public var period: Period                            // this month, from the clock
    public var today: Day
    public var visible: [Student]                        // StudentQuery.apply
    public var activeStudents: [Student]; public var activeClasses: [Classroom]
    public var showsFilters: Bool                        // a class or an archived student exists
    public var isSearching: Bool                         // search is not blank
    public var countLine: String                         // "10 students" · "3 in Class 8 Science" · "1 with no class" · "2 archived" · "3 of 10 match"
    public func classroom(_ id: UUID?) -> Classroom?
    public func student(_ id: UUID) -> Student?
    public func members(of classID: UUID) -> [Student]   // active, by name
    public var unassigned: [Student]                     // active, no class, by name
    public func rowDetail(for student: Student) -> String   // the class, "No class yet", or the parent's phone (no classes yet, or the search matched it)
    public func load() async                             // cache first, then the network
    public func refresh() async
    @discardableResult public func addStudent(_ draft: StudentDraft) async -> Student?
    public func updateStudent(_ id: UUID, with draft: StudentDraft) async -> Bool
    public func setArchived(_ id: UUID, _ archived: Bool) async
    public func deleteStudent(_ id: UUID) async -> Bool
    public func assign(_ ids: [UUID], to classID: UUID?) async
    @discardableResult public func addClass(_ draft: ClassroomDraft) async -> Classroom?
    public func updateClass(_ id: UUID, with draft: ClassroomDraft) async -> Bool
    public func archiveClass(_ id: UUID) async
    public func retryLast() async
}
public struct RegisterSnapshot: Codable, Sendable { public var students: [Student]; public var classes: [Classroom]; public var period: Period }
public typealias RegisterCache = JSONCache<RegisterSnapshot>
public extension RegisterCache { static func forCentre(_ id: UUID, directory: URL? = nil) -> RegisterCache }   // "register-<id>"
/// Where the Students tab's buttons lead when the screen is another feature's; AppShell supplies them.
public struct StudentsActions {
    public init(openScanRegister: @escaping () -> Void, openStudentFees: @escaping (UUID) -> Void, openMarkAttendance: @escaping (UUID) -> Void)
}
```

- [ ] **Step 1: Add the test target**

`Package.swift`: `.testTarget(name: "StudentsTests", dependencies: ["Students"])`. `project.yml`, scheme `TutorCentral` → `test.targets`: `- package: TutorCentralKit/StudentsTests`. `bun gen`.

- [ ] **Step 2: Write the failing tests**

`Tests/StudentsTests/RegisterStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct RegisterStoreTests {
    let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
    let classes = FakeClassesRepository(classes: FakeClassesRepository.seed)

    func make(cache: RegisterCache? = nil) -> RegisterStore {
        RegisterStore(workspace: FakeCentreRepository.meeraWorkspace, students: students, classes: classes, cache: cache, now: { FakeCountsRepository.fixedNow })
    }

    func tempCache() -> RegisterCache {
        RegisterCache.forCentre(FakeCentreRepository.meeraWorkspace.centre.id, directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @Test func loadsTheRegisterAndCountsIt() async {
        let store = make()
        await store.load()
        #expect(store.students.count == 10 && store.classes.count == 2 && !store.loading && store.error == nil)
        #expect(store.visible.map(\.name).first == "Akshita Rao" && store.countLine == "10 students" && store.showsFilters)
        #expect(store.period == Period(year: 2026, month: 10) && store.today == Day(year: 2026, month: 10, day: 7))
    }

    @Test func theQueryDrivesTheListAndTheCountLine() async {
        let store = make()
        await store.load()
        store.filter = .classroom(FakeClassesRepository.science.id)
        #expect(store.visible.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"] && store.countLine == "3 in Class 8 Science")
        store.filter = .unassigned
        #expect(store.visible.map(\.name) == ["Sahil Verma"] && store.countLine == "1 with no class")
        store.filter = .all
        store.search = "sh"
        #expect(store.visible.map(\.name) == ["Akshita Rao", "Meher Shah", "Riya Sharma"] && store.countLine == "3 of 10 match" && store.isSearching)
        store.search = ""
        store.sort = .fee
        #expect(store.visible.first?.name == "Riya Sharma")
    }

    @Test func rowDetailIsTheClassThenThePhoneWhenItMatched() async {
        let store = make()
        await store.load()
        let akshita = store.student(FakeStudentsRepository.akshita)!
        #expect(store.rowDetail(for: akshita) == "Class 10 Maths")
        store.search = "97991"
        #expect(store.rowDetail(for: akshita) == "+91 97991 13211")
        let sahil = store.students.first { $0.name == "Sahil Verma" }!
        store.search = ""
        #expect(store.rowDetail(for: sahil) == "No class yet")
    }

    @Test func withNoClassesTheRowShowsThePhoneAndNoFilters() async {
        students.students = FakeStudentsRepository.few
        classes.classes = []
        let store = make()
        await store.load()
        #expect(!store.showsFilters && store.rowDetail(for: store.students[0]) == store.students[0].parentPhone!.display)
        #expect(store.countLine == "3 students")
    }

    @Test func theCacheShowsFirstThenTheNetworkReplacesIt() async throws {
        let cache = tempCache()
        var old = FakeStudentsRepository.few
        old[0].name = "Cached Dev"
        try cache.save(RegisterSnapshot(students: old, classes: [], period: Period(year: 2026, month: 10)))
        students.delay = .milliseconds(200)
        let store = make(cache: cache)
        let load = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(store.students.first?.name == "Cached Dev" && store.refreshing && !store.loading)
        await load.value
        #expect(store.students.count == 10 && !store.refreshing && cache.load()?.students.count == 10)
    }

    @Test func aCachedSnapshotFromAnotherMonthDropsItsFeeMarks() async throws {
        let cache = tempCache()
        try cache.save(RegisterSnapshot(students: FakeStudentsRepository.seed, classes: FakeClassesRepository.seed, period: Period(year: 2026, month: 9)))
        students.nextError = URLError(.notConnectedToInternet)
        let store = make(cache: cache)
        await store.load()
        #expect(store.students.allSatisfy { $0.thisMonth == nil } && store.error == "Couldn't refresh. Check your connection and try again.")
    }

    @Test func aFailedRefreshKeepsTheRowsAndSaysSo() async {
        let store = make()
        await store.load()
        students.nextError = URLError(.notConnectedToInternet)
        await store.refresh()
        #expect(store.students.count == 10 && store.error == "Couldn't refresh. Check your connection and try again.")
        await store.refresh()
        #expect(store.error == nil)
    }

    @Test func addingAStudentIsOptimisticAndTheServersRowReplacesIt() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Zara Khan"
        draft.classID = FakeClassesRepository.maths.id
        students.delay = .milliseconds(100)
        let add = Task { await store.addStudent(draft) }
        try? await Task.sleep(for: .milliseconds(20))
        #expect(store.students.count == 11 && store.visible.last?.name == "Zara Khan")
        let made = await add.value
        #expect(made != nil && store.students.count == 11 && store.students.contains { $0.id == made!.id } && students.created == [draft])
    }

    @Test func aFailedAddRevertsTheRowAndOffersRetry() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        students.nextError = URLError(.notConnectedToInternet)
        let made = await store.addStudent(draft)
        #expect(made == nil && store.students.count == 10)
        #expect(store.message == "Couldn't save Riya. Check your connection and try again." && store.canRetry)
    }

    @Test func retryWritesOnce() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        students.nextError = URLError(.notConnectedToInternet)
        await store.addStudent(draft)
        await store.retryLast()
        #expect(store.students.count == 11 && students.created.count == 2 && !store.canRetry && store.message == nil)
        await store.retryLast()
        #expect(students.created.count == 2, "nothing to retry twice")
    }

    @Test func editArchiveRestoreAndDeleteFollowTheRepository() async {
        let store = make()
        await store.load()
        var draft = StudentDraft(store.student(FakeStudentsRepository.akshita)!)
        draft.notes = "Board exam in March."
        #expect(await store.updateStudent(FakeStudentsRepository.akshita, with: draft))
        #expect(store.student(FakeStudentsRepository.akshita)?.notes == "Board exam in March.")
        await store.setArchived(FakeStudentsRepository.akshita, true)
        #expect(store.student(FakeStudentsRepository.akshita)?.isArchived == true && store.visible.count == 9 && store.countLine == "9 students")
        store.filter = .archived
        #expect(store.visible.map(\.name) == ["Akshita Rao"] && store.countLine == "1 archived")
        await store.setArchived(FakeStudentsRepository.akshita, false)
        #expect(store.student(FakeStudentsRepository.akshita)?.isArchived == false)
        store.filter = .all
        #expect(await store.deleteStudent(FakeStudentsRepository.akshita))
        #expect(store.student(FakeStudentsRepository.akshita) == nil && students.deleted == [FakeStudentsRepository.akshita])
    }

    @Test func aFailedEditRollsBackAndAFailedDeleteKeepsTheStudent() async {
        let store = make()
        await store.load()
        students.nextError = URLError(.notConnectedToInternet)
        var draft = StudentDraft(store.student(FakeStudentsRepository.akshita)!)
        draft.name = "Akshita R"
        #expect(await store.updateStudent(FakeStudentsRepository.akshita, with: draft) == false)
        #expect(store.student(FakeStudentsRepository.akshita)?.name == "Akshita Rao" && store.message == "Couldn't save Akshita. Check your connection and try again.")
        students.nextError = URLError(.notConnectedToInternet)
        #expect(await store.deleteStudent(FakeStudentsRepository.akshita) == false)
        #expect(store.student(FakeStudentsRepository.akshita) != nil && store.message == "Couldn't delete Akshita. Check your connection and try again.")
    }

    @Test func classesAreAddedEditedAndMembersAssigned() async {
        let store = make()
        await store.load()
        var draft = ClassroomDraft()
        draft.name = "Class 12 Physics"
        let made = await store.addClass(draft)
        #expect(made != nil && store.activeClasses.count == 3)
        let sahil = store.students.first { $0.name == "Sahil Verma" }!
        await store.assign([sahil.id], to: made!.id)
        #expect(store.members(of: made!.id).map(\.name) == ["Sahil Verma"] && store.unassigned.isEmpty)
        draft.fee = Money(rupees: 1500)
        #expect(await store.updateClass(made!.id, with: draft))
        #expect(store.classroom(made!.id)?.monthlyFee == Money(rupees: 1500))
    }

    @Test func archivingAClassDetachesItsMembers() async {
        let store = make()
        await store.load()
        await store.archiveClass(FakeClassesRepository.science.id)
        #expect(store.classroom(FakeClassesRepository.science.id)?.isArchived == true && store.activeClasses.count == 1)
        #expect(store.unassigned.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das", "Sahil Verma"])
        #expect(store.students.first { $0.name == "Dev Kumar" }?.monthlyFee == Money(rupees: 1000), "an own fee stays")
        #expect(classes.archived == [FakeClassesRepository.science.id])
    }

    @Test func writesUpdateTheCache() async throws {
        let cache = tempCache()
        let store = make(cache: cache)
        await store.load()
        await store.setArchived(FakeStudentsRepository.akshita, true)
        #expect(cache.load()?.students.first { $0.id == FakeStudentsRepository.akshita }?.isArchived == true)
    }
}
```

- [ ] **Step 3: Run to see them fail**

Run: `bun gen && bun check --only=ios`
Expected: FAIL, `RegisterStore` not found.

- [ ] **Step 4: Implement**

`Features/Students/RegisterCache.swift`:

```swift
import Data
import Domain
import Foundation

/// What the cache holds: the register as last read, with the month its fee marks belong to.
public struct RegisterSnapshot: Codable, Sendable {
    public var students: [Student]
    public var classes: [Classroom]
    public var period: Period

    public init(students: [Student], classes: [Classroom], period: Period) {
        self.students = students
        self.classes = classes
        self.period = period
    }
}

public typealias RegisterCache = JSONCache<RegisterSnapshot>

public extension RegisterCache {
    static func forCentre(_ id: UUID, directory: URL? = nil) -> RegisterCache {
        RegisterCache(name: "register-\(id.uuidString.lowercased())", directory: directory)
    }
}
```

`Features/Students/StudentsActions.swift`: the struct of the interface with three stored closures (internal `let`s, public init).

`Features/Students/RegisterStore.swift`:

```swift
import Data
import Domain
import Foundation
import Observation

@MainActor @Observable public final class RegisterStore {
    public private(set) var students: [Student] = []
    public private(set) var classes: [Classroom] = []
    public private(set) var loading = false
    public private(set) var refreshing = false
    public private(set) var error: String?
    public var message: String?
    public private(set) var canRetry = false
    public var search = ""
    public var filter: StudentFilter = .all
    public var sort: StudentSort = .name

    private let workspace: Workspace
    private let studentsRepository: any StudentsRepository
    private let classesRepository: any ClassesRepository
    private let cache: RegisterCache?
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var loaded = false
    private var lastFailed: (@MainActor () async -> Void)?

    public init(
        workspace: Workspace, students: any StudentsRepository, classes: any ClassesRepository,
        cache: RegisterCache?, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        studentsRepository = students
        classesRepository = classes
        self.cache = cache
        self.now = now
        self.calendar = calendar
    }

    public var period: Period { Period.containing(now(), in: calendar.timeZone) }
    public var today: Day { Day(now(), calendar: calendar) }
    public var isSearching: Bool { !search.trimmingCharacters(in: .whitespaces).isEmpty }
    public var activeStudents: [Student] { students.filter { !$0.isArchived } }
    public var activeClasses: [Classroom] { classes.filter { !$0.isArchived } }
    public var showsFilters: Bool { !activeClasses.isEmpty || students.contains(where: \.isArchived) }
    public var visible: [Student] { StudentQuery.apply(students, classes: classes, search: search, filter: filter, sort: sort) }
    public var unassigned: [Student] { StudentQuery.apply(students, classes: classes, search: "", filter: .unassigned, sort: .name) }

    public var countLine: String {
        let shown = visible.count
        if isSearching { return "\(shown) of \(students.count) match" }
        switch filter {
        case .all: return "\(shown) \(shown == 1 ? "student" : "students")"
        case let .classroom(id): return "\(shown) in \(classroom(id)?.name ?? "the class")"
        case .unassigned: return "\(shown) with no class"
        case .archived: return "\(shown) archived"
        }
    }

    public func classroom(_ id: UUID?) -> Classroom? { id.flatMap { id in classes.first { $0.id == id } } }
    public func student(_ id: UUID) -> Student? { students.first { $0.id == id } }
    public func members(of classID: UUID) -> [Student] {
        StudentQuery.apply(students, classes: classes, search: "", filter: .classroom(classID), sort: .name)
    }

    public func rowDetail(for student: Student) -> String {
        if let phone = student.parentPhone, activeClasses.isEmpty || (isSearching && StudentQuery.matchesPhone(student, search: search)) {
            return phone.display
        }
        return classroom(student.classID)?.name ?? "No class yet"
    }

    // MARK: Reads

    public func load() async {
        if !loaded, let snapshot = cache?.load() {
            classes = snapshot.classes
            students = snapshot.period == period ? snapshot.students : snapshot.students.map { var s = $0; s.thisMonth = nil; return s }
            loaded = true
        }
        if !loaded { loading = true } else { refreshing = true }
        defer { loading = false; refreshing = false }
        await fetch()
    }

    public func refresh() async {
        refreshing = true
        defer { refreshing = false }
        await fetch()
    }

    private func fetch() async {
        do {
            async let s = studentsRepository.students(centre: workspace.centre.id, period: period)
            async let c = classesRepository.classes(centre: workspace.centre.id)
            (students, classes) = try await (s, c)
            error = nil
            loaded = true
            persist()
        } catch {
            self.error = "Couldn't refresh. Check your connection and try again."
        }
    }

    private func persist() {
        try? cache?.save(RegisterSnapshot(students: students, classes: classes, period: period))
    }

    // MARK: Writes

    @discardableResult public func addStudent(_ draft: StudentDraft) async -> Student? {
        let placeholder = Student(
            id: UUID(), name: draft.trimmedName, classID: draft.classID, monthlyFee: draft.fee, parentName: draft.trimmedParentName,
            parentPhone: draft.parentPhone, dateOfBirth: draft.dateOfBirth, gender: draft.gender, notes: draft.trimmedNotes, archivedAt: nil, thisMonth: nil
        )
        students.append(placeholder)
        do {
            let made = try await studentsRepository.create(draft, centre: workspace.centre.id)
            replace(placeholder.id, with: made)
            succeeded()
            return made
        } catch {
            students.removeAll { $0.id == placeholder.id }
            failed("Couldn't save \(firstWord(draft.trimmedName)). Check your connection and try again.") { [weak self] in await self?.addStudent(draft) }
            return nil
        }
    }

    public func updateStudent(_ id: UUID, with draft: StudentDraft) async -> Bool {
        guard let before = student(id) else { return false }
        var optimistic = before
        optimistic.name = draft.trimmedName
        optimistic.classID = draft.classID
        optimistic.monthlyFee = draft.fee
        optimistic.parentName = draft.trimmedParentName
        optimistic.parentPhone = draft.parentPhone
        optimistic.dateOfBirth = draft.dateOfBirth
        optimistic.gender = draft.gender
        optimistic.notes = draft.trimmedNotes
        replace(id, with: optimistic)
        do {
            var saved = try await studentsRepository.update(id: id, with: draft)
            saved.thisMonth = before.thisMonth
            replace(id, with: saved)
            succeeded()
            return true
        } catch {
            replace(id, with: before)
            failed("Couldn't save \(before.firstName). Check your connection and try again.") { [weak self] in _ = await self?.updateStudent(id, with: draft) }
            return false
        }
    }

    public func setArchived(_ id: UUID, _ archived: Bool) async {
        guard let before = student(id) else { return }
        var optimistic = before
        optimistic.archivedAt = archived ? now() : nil
        replace(id, with: optimistic)
        do {
            try await studentsRepository.setArchived(id: id, archived)
            succeeded()
        } catch {
            replace(id, with: before)
            failed("Couldn't \(archived ? "archive" : "restore") \(before.firstName). Check your connection and try again.") { [weak self] in await self?.setArchived(id, archived) }
        }
    }

    /// Not optimistic: nothing can be shown after a cascade until the server has done it.
    public func deleteStudent(_ id: UUID) async -> Bool {
        guard let before = student(id) else { return false }
        do {
            try await studentsRepository.delete(id: id)
            students.removeAll { $0.id == id }
            succeeded()
            return true
        } catch {
            failed("Couldn't delete \(before.firstName). Check your connection and try again.") { [weak self] in _ = await self?.deleteStudent(id) }
            return false
        }
    }

    public func assign(_ ids: [UUID], to classID: UUID?) async {
        let before = students
        for id in ids { if var s = student(id) { s.classID = classID; replace(id, with: s) } }
        do {
            try await studentsRepository.assign(studentIDs: ids, toClass: classID, centre: workspace.centre.id)
            succeeded()
        } catch {
            students = before
            let what = ids.count == 1 ? (before.first { $0.id == ids[0] }?.firstName ?? "the student") : "the students"
            failed("Couldn't move \(what). Check your connection and try again.") { [weak self] in await self?.assign(ids, to: classID) }
        }
    }

    @discardableResult public func addClass(_ draft: ClassroomDraft) async -> Classroom? {
        let placeholder = Classroom(
            id: UUID(), name: draft.trimmedName, subject: draft.trimmedSubject, monthlyFee: draft.fee, meetingDays: draft.meetingDays,
            startTime: draft.startTime, endTime: draft.endTime, archivedAt: nil
        )
        classes.append(placeholder)
        do {
            let made = try await classesRepository.create(draft, centre: workspace.centre.id)
            classes.removeAll { $0.id == placeholder.id }
            classes.append(made)
            classes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            succeeded()
            return made
        } catch {
            classes.removeAll { $0.id == placeholder.id }
            failed("Couldn't save \(draft.trimmedName). Check your connection and try again.") { [weak self] in await self?.addClass(draft) }
            return nil
        }
    }

    public func updateClass(_ id: UUID, with draft: ClassroomDraft) async -> Bool {
        guard let index = classes.firstIndex(where: { $0.id == id }) else { return false }
        let before = classes[index]
        var optimistic = before
        optimistic.name = draft.trimmedName
        optimistic.subject = draft.trimmedSubject
        optimistic.monthlyFee = draft.fee
        optimistic.meetingDays = draft.meetingDays
        optimistic.startTime = draft.startTime
        optimistic.endTime = draft.endTime
        classes[index] = optimistic
        do {
            classes[index] = try await classesRepository.update(id: id, with: draft)
            succeeded()
            return true
        } catch {
            classes[index] = before
            failed("Couldn't save \(before.name). Check your connection and try again.") { [weak self] in _ = await self?.updateClass(id, with: draft) }
            return false
        }
    }

    public func archiveClass(_ id: UUID) async {
        guard let index = classes.firstIndex(where: { $0.id == id }) else { return }
        let beforeClasses = classes
        let beforeStudents = students
        classes[index].archivedAt = now()
        for s in students where s.classID == id { var moved = s; moved.classID = nil; replace(s.id, with: moved) }
        do {
            try await classesRepository.archive(id: id)
            succeeded()
        } catch {
            classes = beforeClasses
            students = beforeStudents
            failed("Couldn't archive \(beforeClasses[index].name). Check your connection and try again.") { [weak self] in await self?.archiveClass(id) }
        }
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    private func replace(_ id: UUID, with student: Student) {
        if let index = students.firstIndex(where: { $0.id == id }) { students[index] = student } else { students.append(student) }
    }

    private func succeeded() {
        lastFailed = nil
        canRetry = false
        persist()
    }

    private func failed(_ text: String, retry: @escaping @MainActor () async -> Void) {
        message = text
        lastFailed = retry
        canRetry = true
    }

    private func firstWord(_ name: String) -> String { name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name }
}
```

- [ ] **Step 5: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios
git commit -m "Students: the register store with its query, cache and optimistic writes, tested against the fakes"
```

### Task 9: The Students tab: list, search, filters, sort, the Classes row, the "+" menu; AppShell wiring and fixtures (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/StudentsView.swift`, `StudentsListSections.swift`
- Modify: `ios/TutorCentralKit/Sources/AppShell/TabsView.swift`, `TabsState.swift`, `ShellState.swift`, `RootView.swift`, `LaunchState.swift`, `Fixtures.swift`, `Dependencies.swift`, `LaterView.swift`
- Test: `ios/TutorCentralKit/Tests/AppShellTests/LaunchStateTests.swift` (the new states), `TabsStateTests.swift` (new)

**Interfaces:**
- Consumes: `RegisterStore`, `StudentsActions` (Task 8); the components (Task 7); `LaterView`, `TabsState`, `Fixtures` (Phase 2).
- Produces:

```swift
// Features/Students
public struct StudentsView: View {
    /// `boardState` names a launch state whose look the view sets up (the search focused, the menu open, a filter chosen).
    public init(store: RegisterStore, actions: StudentsActions, navigation: StudentsNavigation, boardState: StudentsBoardState? = nil)
}
public enum StudentsBoardState: Sendable { case searching, filteredToScience, addMenu }
/// Pushes on the Students tab, provided by AppShell (the feature does not own the stack).
public struct StudentsNavigation {
    public init(openStudent: @escaping (UUID) -> Void, openClasses: @escaping () -> Void, openClass: @escaping (UUID) -> Void)
}
// AppShell
enum Route: Hashable { case later(LaterPlace), settings, student(UUID), classes, classroom(UUID) }
enum LaterPlace { … case scanRegister, studentFees, markAttendance }
public enum LaunchState { … case studentsEmpty = "students-empty", studentsFew = "students-few", students, studentsSearching = "students-searching", studentsFiltered = "students-filtered", studentsAddMenu = "students-add-menu" }
public struct Dependencies { …; public let students: any StudentsRepository; public let classes: any ClassesRepository; public let cacheDirectory: URL? /* nil: no register cache (fixtures) */ }
final class ShellState { …; var register: RegisterStore? }
```

- [ ] **Step 1: Failing tests**

Append to `Tests/AppShellTests/LaunchStateTests.swift`:

```swift
    @MainActor @Test func theStudentsStatesStartReadyOnTheStudentsTabWithTheirRegister() async throws {
        for state in [LaunchState.studentsEmpty, .studentsFew, .students, .studentsSearching, .studentsFiltered, .studentsAddMenu] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students)
        }
        let deps = Fixtures.dependencies(for: .students)
        let all = try await deps.students.students(centre: Fixtures.meeraWorkspace.centre.id, period: Period(year: 2026, month: 10))
        #expect(all.count == 10 && deps.cacheDirectory == nil)
        let few = try await Fixtures.dependencies(for: .studentsFew).students.students(centre: Fixtures.meeraWorkspace.centre.id, period: Period(year: 2026, month: 10))
        #expect(few.count == 3 && (try await Fixtures.dependencies(for: .studentsFew).classes.classes(centre: Fixtures.meeraWorkspace.centre.id)).isEmpty)
        let none = try await Fixtures.dependencies(for: .studentsEmpty).students.students(centre: Fixtures.meeraWorkspace.centre.id, period: Period(year: 2026, month: 10))
        #expect(none.isEmpty)
    }
```

`Tests/AppShellTests/TabsStateTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct TabsStateTests {
    @Test func pushingAndPoppingOnTheStudentsTab() {
        let tabs = TabsState(selected: .students)
        tabs.push(.classes)
        tabs.push(.classroom(UUID()))
        #expect(tabs.paths[.students]?.count == 2)
        tabs.select(.students)
        #expect(tabs.paths[.students] == [])
    }
}
```

- [ ] **Step 2: Run to see them fail; then AppShell**

Run: `bun check --only=ios`
Expected: FAIL, the states and routes do not exist.

`Dependencies.swift`: add `students`, `classes` (Supabase in `live()`, with `SupabaseStudentsRepository(client:)`, `SupabaseClassesRepository(client:)`) and `cacheDirectory: URL?` (`nil` in `live()` means the default Application Support directory inside `RegisterCache.forCentre`; keep a second flag `cachesRegister: Bool`, true in `live()`, false in fixtures, so the fakes never write a file).

`LaunchState.swift`: the six cases. `Fixtures.swift`: `studentsEmpty` → `FakeStudentsRepository()` and `FakeClassesRepository()`; `studentsFew` → `.few` and no classes; the other four → `.seed` and `.seed`; every Students state is `.ready(meeraWorkspace)`; `Fixtures.dependencies` passes them and `cachesRegister: false`. `RootView.tab(for:)` returns `.students` for the six.

`LaterView.swift`: `LaterPlace` gains `scanRegister` (title "Scan register", symbol `doc.viewfinder`, heading "Scan register is on the way", line rest "Photographing your paper register and reading it arrives"), `studentFees` ("Fees", `indianrupeesign`, "Fees are on the way", "The fee ledger, reminders and receipts arrive"), `markAttendance` ("Attendance", `checkmark.circle`, "Attendance is on the way", "Marking attendance and its history arrive"). The opening sentence becomes "This build has sign-in, your profile, Today and the register." for every place.

`TabsState.swift`: `Route` gains `.student(UUID)`, `.classes`, `.classroom(UUID)`; `open(_:)` returns `true` for `.student(id)` and pushes `.student(id)` after clearing the stack (the view says "That student is no longer here." when the id is unknown, Task 13).

`ShellState.swift`: `var register: RegisterStore?`, reset with the rest.

`TabsView.swift`: a `students: () -> Students` root closure like `today`; `navigationDestination(for: Route.self)` gains the three cases, each built by a closure RootView passes (`studentDetail: (UUID) -> StudentDetail`, `classes: () -> Classes`, `classroom: (UUID) -> ClassDetail`); until Tasks 13 and 17 exist, RootView passes `LaterView(place: .tab(.students), …)` for the three so the routes compile and nothing undrawn is shown (a tap on a row before Task 13 lands shows the later card; PR 4's pictures never show it).

`RootView.swift`: `studentsView` builds or reuses `shell.register` (`RegisterStore(workspace:, students: deps.students, classes: deps.classes, cache: deps.cachesRegister ? .forCentre(workspace.centre.id) : nil, now: deps.now)`), and passes `StudentsActions(openScanRegister: { shell.tabs.push(.later(.scanRegister)) }, openStudentFees: { _ in shell.tabs.push(.later(.studentFees)) }, openMarkAttendance: { _ in shell.tabs.push(.later(.markAttendance)) })`, `StudentsNavigation(openStudent: { shell.tabs.push(.student($0)) }, openClasses: { shell.tabs.push(.classes) }, openClass: { shell.tabs.push(.classroom($0)) })` and `boardState` from the launch state (`.studentsSearching → .searching`, `.studentsFiltered → .filteredToScience`, `.studentsAddMenu → .addMenu`). The toast for the store's `message` is wired in the view (`onChange(of: store.message)` → `toasts.show(message, action: store.canRetry ? ("Retry", { Task { await store.retryLast() } }) : nil)` then clears it), the same way Settings does.

- [ ] **Step 3: The root view, to its six boards**

`StudentsView.swift`: a `ScrollView` with `VStack(alignment: .leading, spacing: Tokens.sectionGap)` padded `pageSide`, top `pageTop − safe area` (as Today), bottom `contentBottom`; `.toolbar(.hidden, for: .navigationBar)`; `.background(Tokens.ground.color)`; `.refreshable { await store.refresh(); Haptic.play(.impactLight) }`; `.task { await store.load() }`; `.scrollDismissesKeyboard(.interactively)`.

Pieces, in `StudentsListSections.swift`, each a small view taking the store:

1. **Title row.** While not searching: `Text("Students").typeStyle(Tokens.display)` and, right, the "+" anchor: a `Button { showsMenu = true } label: { IconButtonLook(symbol: "plus") }` with `.accessibilityLabel("Add")` and `.popover(isPresented: $showsMenu, arrowEdge: .top) { addMenu.presentationCompactAdaptation(.popover) }`. While searching: the inline title row of the board (`Text("Students").typeStyle(Tokens.headline)` centred, 44 high) and no "+".
2. **Add menu** (the popover's content, to `P3-Students-AddMenu`): three rows 46 high, label `body` left and symbol 20 right, divided by `lineGlass`, width 260 (`Self.menuWidth`), on the popover's own glass: "Add a student" (`person.badge.plus`) → `showsNewStudent = true` (Task 11; until then the row is present and does nothing visible beyond closing the popover), "Scan paper register" (`doc.viewfinder`) → `actions.openScanRegister()`, "Create a class" (`book.closed`) → `showsNewClass = true` (Task 15). The `addMenu` state opens the popover `onAppear`.
3. **Search and filters** (hidden on `students-empty`): `SearchWell(text: $store.search, placeholder: "Search by name or phone", isSearching: $searching, showsFocus: boardState == .searching)`; under it, when `store.showsFilters && !searching`, the chip row in a horizontal `ScrollView(.horizontal, showsIndicators: false)` padded `−pageSide` on both sides and `pageSide` inside (so it runs to the screen edge, components.md): `FilterChip("All", isOn: store.filter == .all)`, one per `store.activeClasses` by name (`.classroom(id)`), `FilterChip("No class", …)` (`.unassigned`), `FilterChip("Archived", …)` (`.archived`, shown only when an archived student exists).
4. **Classes row** (hidden while searching, and on `students-empty` and `students-few` where the Classes empty card takes its place): `Card(.compact)` holding `ClassRow`-like content with `IconTile(symbol: "book.closed")`, title "Classes", subtitle the active class names joined by " · ", trailing the count in `footnote` `text2`, chevron; `navigation.openClasses()`.
5. **Count line**: `SectionHeader(store.countLine, action: searching ? nil : (store.sort.label, { showsSort = true }))` where the action shows a `Menu`-free confirmation: the sort is a system `Menu` anchored on the quiet button with two `Button`s ("Name", "Fee") marking the current with a checkmark; since the sort menu has no board state it uses the system `Menu` as is.
6. **The list**: `Card { ForEach(store.visible) { student in StudentRow(initials: student.initials, name: student.name, nameMatch: StudentQuery.matchRange(in: student.name, search: store.search), detail: store.rowDetail(for: student), fee: student.fee(in: store.classroom(student.classID))?.formatted, status: mark(student)) { navigation.openStudent(student.id) } ; divider } }` where `mark` maps `FeeMark` → `(.ok, "Paid 4 Oct")`, `(.due, "Due")`, `(nil, "Waived")`. While `store.loading` (nothing cached) the card holds three `SkeletonRow`s instead; while `store.refreshing` the count line carries `RefreshSpinner()` and the card is at `Tokens.opacityStale`; `store.error` shows the footnote line with Retry under the count line (as Today).
7. **Searching extras** (to `P3-Students-Searching`): under the list, the footnote `text3` "Matches names and phone numbers, in every class and the archive."; when nothing matches, an `EmptyState(symbol: "magnifyingglass", title: "No one matches", line: "Try another part of the name or the number.")`.
8. **Filtered extras** (to `P3-Students-Filtered`): when `filter` is a class, under the card a row with the class's `meetingSummary` plus " · ₹1,000 a month" in `footnote` `text3` and a quiet "Open class" → `navigation.openClass(id)`.
9. **Empty** (to `P3-Students-Empty`, when `store.students.isEmpty && !store.loading`): `Card { EmptyState(symbol: "person.2", title: "No students yet", line: "Add them one by one, or photograph your paper register and we'll read it.") }` with the two buttons under the line as the board draws (a `HStack` of `Button("Add a student").buttonStyle(.primary())` and `Button("Scan register").buttonStyle(.secondary())`, plain labels, the owner's tweak); then the Classes section: `SectionHeader("Classes")`, `Card { EmptyRow(symbol: "book.closed", title: "No classes yet", line: "Group students into classes to take attendance and set one fee for all.") }`, `Button("Create a class").buttonStyle(.secondary())` left-aligned.
10. **Few** (to `P3-Students-Few`, when there are students but no active class): the search, the count line and the list as in 5 and 6 (the row detail is the phone, `rowDetail`), then the same Classes section as 9.

Copy on the boards is the copy in code. The `boardState` only pre-sets: `.searching` → `store.search = "sh"`, `searching = true`; `.filteredToScience` → `store.filter = .classroom(FakeClassesRepository.science.id)`, `store.sort = .fee`; `.addMenu` → the popover open.

- [ ] **Step 4: Build, photograph, compare with the boards**

Run: `bun check --only=format,lint,ios`, then

```bash
for s in students-empty students-few students students-searching students-filtered students-add-menu; do bun shots $s; done
```

Open each `.shots/<state>/<state>-dark.png` and `-light.png` beside its board (`docs/design/mockups/P3-Students-*.dc.html`): the title, search, chips, Classes row, count line, rows (one line each, the fee and status right), the tab bar with Students active; the popover's three rows for `students-add-menu`; "3 of 10 match" with the letters coloured for `students-searching`; "3 in Class 8 Science" with the Open class line for `students-filtered`. Fix what differs; a value the boards use that no token names becomes a token (document and Swift together) before the PR.

- [ ] **Step 5: Commit, pull request with the pictures**

```bash
git add ios
git commit -m "The Students tab: list, search, filters, sort, the Classes row, the add menu; routes, fixtures and six launch states"
git push -u origin phase-3/students-list
bun pr-shots phase-3-students-list .shots/students-empty/*.png .shots/students-few/*.png .shots/students/*.png .shots/students-searching/*.png .shots/students-filtered/*.png .shots/students-add-menu/*.png
gh pr create --title "The Students tab: search, filters, sort, the Classes row, the add menu" --body "$(cat <<'EOF'
Phase 3, PR 4 (Tasks 7 to 9). The DesignSystem additions the Phase 3 boards draw (search well, filter chip, day picker, banner, tiles, notes well, member, meeting and checklist rows). The register store: students and classes from the repositories, the JSON cache first, the query (search over names and numbers, filter, sort), optimistic writes with rollback and Retry. The Students root to its six boards; routes for the detail, classes and class detail (their screens come in PRs 6 and 7); the six launch states.

Checked: `bun check` green; RegisterStore tested against the fakes (cache first, failed add reverts and offers Retry, retry writes once); the pictures below against P3-Students-*.

<the table bun pr-shots printed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Merge when green and the pictures show on the PR page (rule 2 says they do; fetch one with the token only if in doubt).

### Task 10: The student form store (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/StudentFormStore.swift`
- Test: `ios/TutorCentralKit/Tests/StudentsTests/StudentFormStoreTests.swift`

**Interfaces:**
- Consumes: `StudentDraft`, `Student`, `Classroom`, `Money`, `PhoneNumber`, `Day`, `Gender` (Tasks 1 to 3).
- Produces:

```swift
/// The New student and Edit student sheets' state: text as typed, the fee rule, the problems in words, Save's enabling.
@MainActor @Observable public final class StudentFormStore {
    public enum Mode: Sendable { case new, edit(Student) }
    public init(mode: Mode, classes: [Classroom], today: Day)
    public let mode: Mode; public let classes: [Classroom]          // active classes, by name
    public var name, parentName, digits, notes: String
    public var classID: UUID?
    public var feeText: String                                       // "" means the class fee
    public var hasBirthDate: Bool; public var birthDate: Day
    public var gender: Gender?
    public var title: String                                         // "New student" / "Edit student"
    public var classLabel: String                                    // "No class" / the class name
    public var feePlaceholder: String                                // "0", or the class fee as "1,200"
    public var feeHelper: String                                     // the board's three lines (below)
    public var feeError: String?                                     // "Type a whole number of rupees." / feeTooHigh
    public var nameError, parentNameError, notesError, birthDateError: String?   // from the draft's problems, after the field was touched
    public private(set) var phoneError: String?                      // set by commitPhone(), cleared on typing
    public var notesCount: Int
    public var draft: StudentDraft
    public var isChanged: Bool                                        // against the student being edited (always true for a non-empty new form)
    public var canSave: Bool                                          // valid and (new or changed)
    public func select(classID: UUID?)
    public func commitPhone()
    public func toggle(_ gender: Gender)                              // tapping the selected chip clears it
    public static func text(_ money: Money) -> String                 // 1500 → "1,500"; 100000 → "1,00,000"
}
```

The fee helper, verbatim from the boards: with no class and no fee, "Pick a class to use its fee, or type one here."; with a class and no fee typed, "Using the class fee, ₹1,200. Type an amount to set one for this student."; with a fee typed and a class, "The class fee is ₹1,200. This student pays this amount instead."; with a fee typed and no class, "This student's own fee."

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct StudentFormStoreTests {
    let today = Day(year: 2026, month: 10, day: 7)!
    let classes = FakeClassesRepository.seed

    @Test func aNewFormStartsEmptyWithSaveDisabled() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        #expect(form.title == "New student" && form.classLabel == "No class" && form.feePlaceholder == "0" && !form.canSave)
        #expect(form.feeHelper == "Pick a class to use its fee, or type one here." && form.notesCount == 0)
        form.name = "Riya Sharma"
        #expect(form.canSave && form.draft.trimmedName == "Riya Sharma" && form.draft.fee == nil)
    }

    @Test func anUntouchedFeeFollowsTheClassATypedOneStays() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.select(classID: FakeClassesRepository.maths.id)
        #expect(form.feePlaceholder == "1,200" && form.feeText == "" && form.draft.fee == nil)
        #expect(form.feeHelper == "Using the class fee, ₹1,200. Type an amount to set one for this student.")
        form.feeText = "1,500"
        #expect(form.draft.fee == Money(rupees: 1500) && form.feeHelper == "The class fee is ₹1,200. This student pays this amount instead.")
        form.select(classID: FakeClassesRepository.science.id)
        #expect(form.feeText == "1,500" && form.draft.fee == Money(rupees: 1500), "a typed fee stays when the class changes")
        form.select(classID: nil)
        #expect(form.feeHelper == "This student's own fee.")
    }

    @Test func clearingTheFeeReturnsToTheClassFee() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.select(classID: FakeClassesRepository.maths.id)
        form.feeText = "1,500"
        form.feeText = ""
        #expect(form.draft.fee == nil && form.feePlaceholder == "1,200")
        form.feeText = "12a"
        #expect(form.feeError == "Type a whole number of rupees." && !form.canSave)
        form.feeText = "1,00,001"
        #expect(form.feeError == "That's more than ₹1,00,000. Check the amount." && !form.canSave)
    }

    @Test func thePhoneIsCheckedOnCommitAndClearedOnTyping() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.digits = "981112223"
        form.commitPhone()
        #expect(form.phoneError == "Needs 10 digits after +91." && !form.canSave)
        form.digits = "9811122233"
        #expect(form.phoneError == nil && form.canSave && form.draft.parentPhone?.e164 == "+919811122233")
    }

    @Test func birthDateAndGenderAreOptionalToggles() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        #expect(form.draft.dateOfBirth == nil && form.draft.gender == nil)
        form.hasBirthDate = true
        form.birthDate = Day(year: 2011, month: 3, day: 14)!
        form.toggle(.female)
        #expect(form.draft.dateOfBirth == Day(year: 2011, month: 3, day: 14) && form.draft.gender == .female)
        form.toggle(.female)
        #expect(form.draft.gender == nil)
        form.birthDate = Day(year: 2026, month: 10, day: 8)!
        #expect(form.birthDateError == "Check the date of birth." && !form.canSave)
        form.hasBirthDate = false
        #expect(form.draft.dateOfBirth == nil && form.canSave)
    }

    @Test func editingStartsFromTheStudentAndSavesOnlyWhenSomethingChanged() {
        let akshita = FakeStudentsRepository.seed[0]
        let form = StudentFormStore(mode: .edit(akshita), classes: classes, today: today)
        #expect(form.title == "Edit student" && form.name == "Akshita Rao" && form.classLabel == "Class 10 Maths")
        #expect(form.feeText == "" && form.feePlaceholder == "1,200" && form.digits == "9799113211" && form.parentName == "Priya Rao")
        #expect(!form.isChanged && !form.canSave)
        form.notes = "Board exam in March."
        #expect(form.isChanged && form.canSave && form.notesCount == 20)
        form.notes = ""
        #expect(!form.canSave)
        let riya = FakeStudentsRepository.seed[8]
        #expect(StudentFormStore(mode: .edit(riya), classes: classes, today: today).feeText == "1,500")
        #expect(StudentFormStore.text(Money(rupees: 100_000)) == "1,00,000")
    }

    @Test func limitsAreSaidUnderTheirFields() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = String(repeating: "a", count: 81)
        #expect(form.nameError == "Keep the name under 80 characters.")
        form.name = "Riya"
        form.notes = String(repeating: "n", count: 2001)
        #expect(form.notesError == "Keep the notes under 2,000 characters." && !form.canSave)
    }
}
```

- [ ] **Step 2: Run to see them fail; implement**

Run: `bun check --only=ios` → FAIL, `StudentFormStore` not found.

```swift
import Domain
import Foundation
import Observation

@MainActor @Observable public final class StudentFormStore {
    public enum Mode: Sendable {
        case new
        case edit(Student)
    }

    public let mode: Mode
    public let classes: [Classroom]
    private let today: Day
    private let original: StudentDraft?

    public var name = ""
    public var parentName = ""
    public var digits = "" {
        didSet { if digits != oldValue { phoneError = nil } }
    }
    public var notes = ""
    public var classID: UUID?
    public var feeText = ""
    public var hasBirthDate = false
    public var birthDate: Day
    public var gender: Gender?
    public private(set) var phoneError: String?

    public init(mode: Mode, classes: [Classroom], today: Day) {
        self.mode = mode
        self.classes = classes.filter { !$0.isArchived }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.today = today
        birthDate = Day(year: today.year - 12, month: today.month, day: min(today.day, 28))!
        if case let .edit(student) = mode {
            let draft = StudentDraft(student)
            original = draft
            name = draft.name
            parentName = draft.parentName
            digits = draft.parentDigits
            notes = draft.notes
            classID = draft.classID
            feeText = draft.fee.map(Self.text) ?? ""
            hasBirthDate = draft.dateOfBirth != nil
            birthDate = draft.dateOfBirth ?? birthDate
            gender = draft.gender
        } else {
            original = nil
        }
    }

    public var title: String { if case .edit = mode { "Edit student" } else { "New student" } }
    public var classroom: Classroom? { classID.flatMap { id in classes.first { $0.id == id } } }
    public var classLabel: String { classroom?.name ?? "No class" }
    public var classFee: Money? { classroom?.monthlyFee }
    public var feePlaceholder: String { classFee.map(Self.text) ?? "0" }
    public var typedFee: Money? { Money(typed: feeText) }
    public var notesCount: Int { notes.count }

    public var feeHelper: String {
        switch (classFee, feeText.isEmpty) {
        case (nil, true): "Pick a class to use its fee, or type one here."
        case let (fee?, true): "Using the class fee, \(fee.formatted). Type an amount to set one for this student."
        case let (fee?, false): "The class fee is \(fee.formatted). This student pays this amount instead."
        case (nil, false): "This student's own fee."
        }
    }

    public var feeError: String? {
        if !feeText.isEmpty, typedFee == nil { return "Type a whole number of rupees." }
        return problems.contains(.feeTooHigh) ? StudentDraft.Problem.feeTooHigh.message : nil
    }

    public var nameError: String? { message(.nameTooLong) }
    public var parentNameError: String? { message(.parentNameTooLong) }
    public var notesError: String? { message(.notesTooLong) }
    public var birthDateError: String? { message(.birthDateOut) }

    public var draft: StudentDraft {
        var draft = StudentDraft()
        draft.name = name
        draft.classID = classID
        draft.fee = typedFee
        draft.parentName = parentName
        draft.parentDigits = digits
        draft.dateOfBirth = hasBirthDate ? birthDate : nil
        draft.gender = gender
        draft.notes = notes
        return draft
    }

    public var isChanged: Bool { original.map { $0 != draft } ?? true }

    public var canSave: Bool {
        problems.isEmpty && feeError == nil && phoneError == nil && isChanged && (feeText.isEmpty || typedFee != nil)
    }

    public func select(classID: UUID?) { self.classID = classID }

    public func commitPhone() {
        phoneError = problems.contains(.phoneInvalid) ? StudentDraft.Problem.phoneInvalid.message : nil
    }

    public func toggle(_ gender: Gender) { self.gender = self.gender == gender ? nil : gender }

    /// 1500 → "1,500"; 100000 → "1,00,000": the field shows the Indian grouping without the sign.
    public static func text(_ money: Money) -> String {
        money.rupees.formatted(.number.locale(Locale(identifier: "en_IN")).grouping(.automatic))
    }

    private var problems: Set<StudentDraft.Problem> { draft.problems(today: today) }
    private func message(_ problem: StudentDraft.Problem) -> String? { problems.contains(problem) ? problem.message : nil }
}
```

- [ ] **Step 3: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios` → green.

```bash
git checkout -b phase-3/student-form
git add ios
git commit -m "Students: the student form store, the fee rule and the problems in words"
```

### Task 11: The New student sheet, to `P3-NewStudent-Empty`, `-Filled`, `-Invalid` (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/StudentFormSheet.swift`
- Modify: `StudentsView.swift` (presents it from the menu and the empty card), `AppShell/LaunchState.swift`, `Fixtures.swift`, `RootView.swift` (three states)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (the three states start ready on the Students tab)

**Interfaces:**
- Consumes: `StudentFormStore` (Task 10), `RegisterStore.addStudent` / `updateStudent` (Task 8), `SheetHeader`, `TextWell`, `PhoneWell`, `NotesWell`, `TileRow`, `PickerTile`, `FilterChip`, `Switch`, `DialogView`.
- Produces:

```swift
public struct StudentFormSheet: View {
    /// `fixture` fills the board's sample; `showsFocus` draws the name focused without the keyboard.
    public init(store: StudentFormStore, showsFocus: Bool = false, onSave: @escaping (StudentDraft) async -> Bool, onClose: @escaping () -> Void)
}
public enum StudentsBoardState { …, newStudentEmpty, newStudentFilled, newStudentInvalid }
public enum LaunchState { …, studentNew = "student-new", studentNewFilled = "student-new-filled", studentNewInvalid = "student-new-invalid" }
```

- [ ] **Step 1: The sheet**

A `NavigationStack`-free `VStack(spacing: 0)`: `SheetHeader(title: store.title, cancel: ("Cancel", cancel), save: .init("Save", enabled: store.canSave && !saving, run: save))` padded `pageSide`; then a `ScrollView` of the fields in a `VStack(spacing: Tokens.rowPaddingHorizontal)` (16, the boards' gap) padded `pageSide`, `.scrollDismissesKeyboard(.interactively)`:

1. `TextWell(label: "Name", text: $store.name, placeholder: "The student's full name", error: store.nameError, content: .name, showsFocus: showsFocus, autofocus: !showsFocus && isNew)`.
2. `Menu { Button("No class") { store.select(classID: nil) }; ForEach(store.classes) { c in Button(c.name) { store.select(classID: c.id) } } } label: { PickerTile(label: "Class", value: store.classLabel) {} }` (the tile's own action is empty; the Menu owns the tap; `accessibilityLabel("Class, \(store.classLabel)")`).
3. `TextWell(label: "Monthly fee", text: $store.feeText, placeholder: store.feePlaceholder, helper: store.feeHelper, error: store.feeError, prefix: "₹", suffix: "per month", numeric: true, keyboard: .numberPad, capitalisation: .never)`.
4. `TextWell(label: "Parent's name", text: $store.parentName, placeholder: "Who you call about this student", error: store.parentNameError, content: .name)`.
5. `PhoneWell(label: "Parent's WhatsApp number", digits: $store.digits, error: store.phoneError, onCommit: store.commitPhone)`.
6. `TileRow(label: "Date of birth") { HStack(spacing: Tokens.rowPaddingDense) { if store.hasBirthDate { DatePicker("Date of birth", selection: dateBinding, in: range, displayedComponents: .date).labelsHidden().tint(Tokens.accentText.color) }; Switch(isOn: $store.hasBirthDate, label: "Add a date of birth") } }` where `dateBinding` converts `store.birthDate` to and from a `Date` through `DayHeading.india`, and `range` is 1950-01-01 … today; the compact `DatePicker` is the system's control (components.md: "opens the system date picker"); under the tile, `FieldMessage(error)` when `store.birthDateError` is set.
7. A label row "Gender" with "(optional)" in `text3` (the `Well` label style), then `HStack(spacing: Tokens.inline) { ForEach(Gender.allCases) { g in FilterChip(g.label, isOn: store.gender == g) { store.toggle(g) } } }`.
8. `NotesWell(label: "Notes", text: $store.notes, placeholder: "School, board, pickup, anything to remember", limit: StudentDraft.notesLimit, error: store.notesError)`.

`save()`: `saving = true`; `if await onSave(store.draft) { onClose() }`; `saving = false` (a failed save keeps the sheet and the typing; the toast comes from the register store through the parent). `cancel()`: when `store.isChanged`, show `DialogView(title: "Discard changes?", message: "What you typed here goes away.", cancel: "Keep editing", action: "Discard", destructive: true, confirmName: nil)` in the sheet's overlay over `Tokens.dim`; else `onClose()`. `.interactiveDismissDisabled(store.isChanged)` and `.presentationDetents([.large])`, `.presentationDragIndicator(.hidden)` on the presenter.

`StudentsView` presents it: `.sheet(isPresented: $showsNewStudent) { StudentFormSheet(store: StudentFormStore(mode: .new, classes: store.activeClasses, today: store.today), showsFocus: boardState == .newStudentEmpty, onSave: { await store.addStudent($0) != nil }, onClose: { showsNewStudent = false }) }`; the empty card's "Add a student" and the menu's row set `showsNewStudent`.

The board fixtures: `.newStudentEmpty` opens the sheet empty with the name focused; `.newStudentFilled` opens it with Riya Sharma, Class 10 Maths, fee "1,500", Neha Sharma, "9811122233", birth date 14 Mar 2011 on, Girl, notes "Board exam in March. Prefers the evening batch." (Save enabled); `.newStudentInvalid` the same with digits "981112223" and `commitPhone()` called (Save disabled, the error under the field). The form store for a fixture is made by `StudentsView` from a `static func fixture(_:classes:today:) -> StudentFormStore` on `StudentFormSheet`.

- [ ] **Step 2: Launch states and fixtures**

`LaunchState`: the three cases; `Fixtures.initialState` → `.ready(meeraWorkspace)` and `.seed` data; `RootView.tab(for:)` → `.students`; the board state mapping (`studentNew → .newStudentEmpty` …). Append to `LaunchStateTests`: the three states start ready on the Students tab (same shape as Task 9's test).

- [ ] **Step 3: Build, photograph, compare, try for real**

Run: `bun check --only=format,lint,ios`, then `bun shots student-new && bun shots student-new-filled && bun shots student-new-invalid`. Compare with `P3-NewStudent-*`: the header, the eight fields in order, the helper lines, the placeholder fee, the error line, Save's state. Then against the local stack (`cd supabase && supabase start`, sign in as `meera@example.com` / `tutor-local-1` in the simulator): add a student with a class and no fee, see the row with the class fee; add one with a fee; cancel with changes and see "Discard changes?".

- [ ] **Step 4: Commit, pull request with the pictures**

```bash
git add ios
git commit -m "New student: the form sheet to its three boards, from the add menu and the empty card"
git push -u origin phase-3/student-form
bun pr-shots phase-3-student-form .shots/student-new/*.png .shots/student-new-filled/*.png .shots/student-new-invalid/*.png
gh pr create --title "New student: the form to its boards" --body "$(cat <<'EOF'
Phase 3, PR 5 (Tasks 10 and 11). The student form store (fee follows the class until a fee is typed; problems in the tutor's words; Save until valid and changed) and the New student sheet to P3-NewStudent-Empty, -Filled and -Invalid, presented from the add menu and the empty card. Edit student reuses the same sheet from the detail (PR 6).

Checked: `bun check` green; the form store tested; tried against the local stack; the pictures below.

<the table bun pr-shots printed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Task 12: The student detail store; the dialog's typed name (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/StudentDetailStore.swift`
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/Dialog.swift` (`DialogView.confirms(typed:name:)`)
- Test: `ios/TutorCentralKit/Tests/StudentsTests/StudentDetailStoreTests.swift`, `Tests/DesignSystemTests/DialogTests.swift`, `Tests/AppShellTests/TabsStateTests.swift` (the link)

**Interfaces:**
- Consumes: `RegisterStore` (Task 8), `Student`, `Classroom`, `MonthFee`, `Period`.
- Produces:

```swift
@MainActor @Observable public final class StudentDetailStore {
    public init(id: UUID, register: RegisterStore)
    public var student: Student?                 // nil when the id is unknown (a stale deep link)
    public var classroom: Classroom?
    public var feeLine: String                   // "₹1,200 a month, the class fee" · "₹1,500 a month" · "No fee set yet"
    public var monthTitle: String                // "October 2026"
    public var monthLine: String                 // "Paid by UPI on 4 Oct" · "Due" · "Waived" · "No fee for this month yet"
    public var monthAmount: String?              // "₹1,200" when there is an invoice
    public var monthMark: (tone: StatusTone?, text: String)?   // ("ok","Paid"), ("due","Due"), (nil,"Waived")
    public var archivedLine: String?             // "Archived: off the list and today's counts. Fees and attendance history are kept." when archived
    public var archivedChip: String?             // "Archived 7 Oct"
    public var notesLine: String?                // the notes, nil when none
    public var callURL: URL?                     // tel:+919799113211
    public var whatsAppURL: URL?                 // https://wa.me/919799113211
    public static let missingMessage = "That student is no longer here."
    public func archive() async; public func restore() async; public func delete() async -> Bool
}
// DesignSystem
public extension DialogView { static func confirms(typed: String, name: String) -> Bool }   // trimmed, case-insensitive
```

- [ ] **Step 1: Failing tests**

`Tests/StudentsTests/StudentDetailStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct StudentDetailStoreTests {
    func register() async -> RegisterStore {
        let store = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func theLinesOfTheBoard() async {
        let detail = StudentDetailStore(id: FakeStudentsRepository.akshita, register: await register())
        #expect(detail.student?.name == "Akshita Rao" && detail.classroom?.name == "Class 10 Maths")
        #expect(detail.feeLine == "₹1,200 a month, the class fee" && detail.monthTitle == "October 2026")
        #expect(detail.monthLine == "Paid by UPI on 4 Oct" && detail.monthAmount == "₹1,200" && detail.monthMark?.text == "Paid")
        #expect(detail.archivedLine == nil && detail.notesLine == nil)
        #expect(detail.callURL?.absoluteString == "tel:+919799113211" && detail.whatsAppURL?.absoluteString == "https://wa.me/919799113211")
    }

    @Test func ownFeeDueAndNoInvoiceReadRight() async {
        let register = await register()
        let riya = register.students.first { $0.name == "Riya Sharma" }!
        #expect(StudentDetailStore(id: riya.id, register: register).feeLine == "₹1,500 a month")
        let dev = register.students.first { $0.name == "Dev Kumar" }!
        let devDetail = StudentDetailStore(id: dev.id, register: register)
        #expect(devDetail.monthLine == "Due" && devDetail.monthMark?.text == "Due")
        var draft = StudentDraft(dev)
        draft.fee = nil
        draft.classID = nil
        _ = await register.updateStudent(dev.id, with: draft)
        #expect(StudentDetailStore(id: dev.id, register: register).feeLine == "No fee set yet")
    }

    @Test func archiveRestoreAndDeleteGoThroughTheRegister() async {
        let register = await register()
        let detail = StudentDetailStore(id: FakeStudentsRepository.akshita, register: register)
        await detail.archive()
        #expect(detail.student?.isArchived == true && detail.archivedChip == "Archived 7 Oct" && detail.archivedLine != nil)
        await detail.restore()
        #expect(detail.student?.isArchived == false && detail.archivedChip == nil)
        #expect(await detail.delete())
        #expect(detail.student == nil && register.student(FakeStudentsRepository.akshita) == nil)
    }

    @Test func aLinkToAMissingStudentSaysSo() async {
        let detail = StudentDetailStore(id: UUID(), register: await register())
        #expect(detail.student == nil && StudentDetailStore.missingMessage == "That student is no longer here.")
    }
}
```

`Tests/DesignSystemTests/DialogTests.swift`:

```swift
import Testing
@testable import DesignSystem

struct DialogTests {
    @Test func theTypedNameConfirmsIgnoringCaseAndSpaces() {
        #expect(DialogView.confirms(typed: "akshita ", name: "Akshita"))
        #expect(DialogView.confirms(typed: "BIR", name: "Bir"))
        #expect(!DialogView.confirms(typed: "Aksh", name: "Akshita") && !DialogView.confirms(typed: "", name: "Akshita"))
    }
}
```

Append to `Tests/AppShellTests/TabsStateTests.swift`:

```swift
    @Test func aStudentLinkOpensTheDetailOnTheStudentsTab() {
        let tabs = TabsState(selected: .today)
        let id = UUID()
        #expect(tabs.open(.student(id)))
        #expect(tabs.selected == .students && tabs.paths[.students] == [.student(id)])
        #expect(!tabs.open(.fees(month: nil)))
    }
```

- [ ] **Step 2: Run to see them fail; implement**

`DialogView`: `static func confirms(typed: String, name: String) -> Bool { typed.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(name) == .orderedSame }`; `confirmed` uses it.

`StudentDetailStore.swift`:

```swift
import DesignSystem
import Domain
import Foundation
import Observation

@MainActor @Observable public final class StudentDetailStore {
    public static let missingMessage = "That student is no longer here."
    private let id: UUID
    private let register: RegisterStore

    public init(id: UUID, register: RegisterStore) {
        self.id = id
        self.register = register
    }

    public var student: Student? { register.student(id) }
    public var classroom: Classroom? { register.classroom(student?.classID) }

    public var feeLine: String {
        guard let student else { return "" }
        if let own = student.monthlyFee { return "\(own.formatted) a month" }
        if let fee = classroom?.monthlyFee { return "\(fee.formatted) a month, the class fee" }
        return "No fee set yet"
    }

    public var monthTitle: String { register.period.title }
    public var monthAmount: String? { student?.thisMonth?.amount.formatted }

    public var monthLine: String {
        guard let fee = student?.thisMonth else { return "No fee for this month yet" }
        switch fee.status {
        case .paid: return "Paid\(fee.paidMethod.map { " by \($0.label)" } ?? "")\(fee.paidOn.map { " on \($0.shortText)" } ?? "")"
        case .due: return "Due"
        case .waived: return "Waived"
        }
    }

    public var monthMark: (tone: StatusTone?, text: String)? {
        switch student?.thisMonth?.status {
        case .paid: (.ok, "Paid")
        case .due: (.due, "Due")
        case .waived: (nil, "Waived")
        case nil: nil
        }
    }

    public var archivedChip: String? { student?.archivedAt.map { "Archived \(Day($0, calendar: DayHeading.india).shortText)" } }
    public var archivedLine: String? {
        student?.isArchived == true ? "Archived: off the list and today's counts. Fees and attendance history are kept." : nil
    }
    public var notesLine: String? { student?.notes }
    public var callURL: URL? { student?.parentPhone.flatMap { URL(string: "tel:\($0.e164)") } }
    public var whatsAppURL: URL? { student?.parentPhone.flatMap { URL(string: "https://wa.me/\($0.e164.dropFirst())") } }

    public func archive() async { await register.setArchived(id, true) }
    public func restore() async { await register.setArchived(id, false) }
    public func delete() async -> Bool { await register.deleteStudent(id) }
}
```

`MonthFee.paidMethod` (Task 3) and `paid_method` in the select and the row (Task 4) are what the "Paid by UPI" line reads.

- [ ] **Step 3: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios` → green.

```bash
git checkout -b phase-3/student-detail
git add ios
git commit -m "Students: the detail store; the dialog confirms a typed name ignoring case and spaces; a student link opens the detail"
```

### Task 13: Student detail to `P3-StudentDetail`, `-Light`, `-Archived`; the confirmations; edit; the deep link (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/StudentDetailView.swift`, `ConfirmDialogs.swift`
- Modify: `AppShell/RootView.swift` (the route builds the view; the four states), `LaunchState.swift`, `Fixtures.swift`, `TabsView.swift` (the `.student` destination)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (the states push the route)

**Interfaces:**
- Consumes: `StudentDetailStore` (Task 12), `StudentFormSheet` + `StudentFormStore(mode: .edit)` (Tasks 10, 11), `StudentsActions`, `DialogView`, `Banner`, `Avatar`, `Chip`, `Card`, `SectionHeader`, `EmptyRow`.
- Produces:

```swift
public struct StudentDetailView: View {
    public init(store: StudentDetailStore, register: RegisterStore, actions: StudentsActions, navigation: StudentsNavigation,
                boardState: StudentDetailBoardState? = nil, onMessage: @escaping (String) -> Void)
}
public enum StudentDetailBoardState: Sendable { case archiveConfirm, deleteConfirm, edit }
public enum LaunchState { …, student, studentArchived = "student-archived", studentArchiveConfirm = "student-archive-confirm", studentDeleteConfirm = "student-delete-confirm", studentEdit = "student-edit" }
```

- [ ] **Step 1: The view, to the boards**

Layout as Settings (a `ScrollView`, `pageSide`, `pageTop − safe area`, `contentBottom`; `.toolbar(.hidden, for: .navigationBar)`; `.toolbar(.hidden, for: .tabBar)`; `.background(Tokens.ground.color)`):

1. **Navigation**: `IconButton(symbol: "chevron.left", label: "Back") { dismiss() }`, the name in `headline` centred, `Button("Edit") { showsEdit = true }.buttonStyle(.quiet)` right.
2. **Header**: `Avatar(initials: student.initials, size: 56)`; the name in `title1`; under it a wrapping `HStack`: when archived, `Chip(.neutral(store.archivedChip!))` with the `archivebox` symbol (give `Chip.Kind.neutral` an optional `symbol:`); the class as `Chip(.neutral(name))` wrapped in a `Button` → `navigation.openClass(id)` when there is a class; then `store.feeLine` in `footnote` `text2`.
3. **Archived banner** (only when archived): `Banner(symbol: "archivebox", text: store.archivedLine!)`.
4. **Parent card**: `Card(.compact)` with the parent's name in `rowTitle` over "Parent" in `footnote` `text2` on the left and the phone (`display`) in `subhead` `text2` on the right; under them `HStack(spacing: Tokens.tileGap)` of `Button { open(store.callURL) } label: { Label("Call", systemImage: "phone") }.buttonStyle(.secondary())` and `Button { open(store.whatsAppURL) } label: { Label("WhatsApp", systemImage: "message") }.buttonStyle(.primary())` with `.environment(\.buttonIconSize, Tokens.iconSmall)`; both disabled when there is no number (the card then reads "No parent contact yet" in the empty-row pattern with the quiet "Add" → edit). `open` uses `UIApplication.shared.open` through SwiftUI's `openURL` environment.
5. **Fees**: `SectionHeader("Fees", action: ("See all", { actions.openStudentFees(id) }))`; `Card` with one row: `store.monthTitle` in `rowTitle` over `store.monthLine` in `footnote` `text2`; right, `store.monthAmount` in `numberRow` and `Chip(.status(tone, text, symbol: "checkmark"), compact: true)` when `monthMark` has a tone, `Chip(.neutral("Waived"), compact: true)` when it does not, nothing when nil.
6. **Attendance**: `SectionHeader("Attendance")`; `Card { EmptyRow(symbol: "checkmark.circle", title: "Attendance comes in the next build", line: "This month's presence and each absence will show here.") }.opacity(Tokens.opacityLater)`.
7. **Notes**: `SectionHeader("Notes", action: ("Edit", { showsEdit = true }))`; `Card` with the notes in `body` (padding `rowPadding`) or `EmptyRow(symbol: "doc.text", title: "No notes yet", line: "School, board, pickup: anything to remember about \(student.firstName).")`.
8. **Buttons**: active: `Button { confirming = .archive } label: { Label("Archive", systemImage: "archivebox") }.buttonStyle(.secondary())` and `Button { confirming = .delete } label: { Label("Delete", systemImage: "trash") }.buttonStyle(.destructive())`; archived: `Button { Task { await store.restore() } } label: { Label("Restore", systemImage: "arrow.counterclockwise") }.buttonStyle(.primary())` and the same Delete; `.environment(\.buttonIconSize, Tokens.iconSmall)`.

`ConfirmDialogs.swift`: two `DialogView`s drawn in the view's `.overlay` over `Tokens.dim` (the Settings pattern), both `Haptic.play(.warning)` through `DialogView.onAppear`:
- Archive: title "Archive \(name)?", message "\(first) leaves the list and today's counts. Fees and attendance history stay, and you can restore from the Archived filter any time.", Cancel, "Archive" (primary, `destructive: false`), action `Task { await store.archive() }` then close.
- Delete: title "Delete \(name)?", message "Everything about \(first) goes too: the fees and the attendance history. This cannot be undone. Type the first name to confirm.", `confirmName: student.firstName`, "Delete" (destructive, solid); action `Task { if await store.delete() { dismiss() } }` with the dialog's Delete showing loading meanwhile (`DialogView` gains `loading: Bool` that the destructive button passes to its style as Phase 2's primary does).

Edit: `.sheet(isPresented: $showsEdit) { StudentFormSheet(store: StudentFormStore(mode: .edit(student), classes: register.activeClasses, today: register.today), onSave: { await register.updateStudent(id, with: $0) }, onClose: { showsEdit = false }) }`.

Missing student: `.onAppear { if store.student == nil { onMessage(StudentDetailStore.missingMessage); dismiss() } }`; the body draws nothing in that case.

Board states: `.archiveConfirm` and `.deleteConfirm` open their dialog on appear; `.edit` opens the edit sheet.

- [ ] **Step 2: AppShell**

`TabsView`'s `.student(id)` destination builds `StudentDetailView(store: StudentDetailStore(id: id, register: register), register: register, actions:, navigation:, boardState:, onMessage: { toasts.show($0) })` through a closure from `RootView` (which owns `shell.register`). `LaunchState`: the five cases; `Fixtures.initialState` → `.ready(meeraWorkspace)` with `.seed`; `RootView.init` pushes `.student(FakeStudentsRepository.akshita)` on the Students tab for the five (as it pushes `.settings` for `settings`) and `.studentArchived`'s fixture starts with Akshita archived on 7 October (`Fixtures` mutates the fake's student before handing the dependencies over); the board states map `studentArchiveConfirm → .archiveConfirm`, `studentDeleteConfirm → .deleteConfirm`, `studentEdit → .edit`. Append to `LaunchStateTests`: the five states are ready on the Students tab and `RootView.initialRoutes(for:)` (a new static helper the init uses) is `[.student(FakeStudentsRepository.akshita)]` for each.

- [ ] **Step 3: Build, photograph, compare, try for real**

Run: `bun check --only=format,lint,ios`, then `for s in student student-archived student-archive-confirm student-delete-confirm student-edit; do bun shots $s; done`. Compare with `P3-StudentDetail`, `-Light` (the `student` state's light picture), `-Archived`, `P3-Archive-Confirm`, `P3-Delete-Confirm`, `P3-EditStudent`. Against the local stack: open a student, call and WhatsApp buttons open their apps (the simulator shows the system's "cannot open" for tel:; WhatsApp opens Safari to wa.me), archive and restore, delete with the typed name, edit and see the row change without a reload; `xcrun simctl openurl booted "tutorcentral://student/<id>"` opens the detail; a random id shows the toast.

- [ ] **Step 4: Commit, pull request with the pictures**

```bash
git add ios
git commit -m "Student detail: parent actions, this month's fee, notes, archive and restore, the typed delete, edit; the student deep link"
git push -u origin phase-3/student-detail
bun pr-shots phase-3-student-detail .shots/student/*.png .shots/student-archived/*.png .shots/student-archive-confirm/*.png .shots/student-delete-confirm/*.png .shots/student-edit/*.png
gh pr create --title "Student detail: the hub, archive, restore, delete, edit; the deep link" --body "$(cat <<'EOF'
Phase 3, PR 6 (Tasks 12 and 13). The student detail to P3-StudentDetail (dark and light), the archived state with Restore, the archive confirmation (primary: reversible) and the typed delete (ignoring case and spaces), Edit through the same form sheet (P3-EditStudent, Save disabled until something changes), the Attendance section as the later row until Phase 4, Fees "See all" to the later board until Phase 5. tutorcentral://student/<id> opens the detail; a missing student says so.

Checked: `bun check` green; the detail store and the dialog's name match tested; tried against the local stack including the deep link; the pictures below.

<the table bun pr-shots printed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Task 14: The class form store (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/ClassFormStore.swift`
- Test: `ios/TutorCentralKit/Tests/StudentsTests/ClassFormStoreTests.swift`

**Interfaces:**
- Consumes: `ClassroomDraft`, `Classroom`, `Weekday`, `TimeOfDay`, `Money` (Tasks 1, 2); `DayPicker.Item` (Task 7); `StudentFormStore.text` (Task 10).
- Produces:

```swift
@MainActor @Observable public final class ClassFormStore {
    public enum Mode: Sendable { case new, edit(Classroom) }
    public init(mode: Mode)
    public let mode: Mode
    public var name, subject, feeText: String
    public var days: Set<Weekday>
    public var startTime, endTime: TimeOfDay?
    public var title: String                          // "New class" / "Edit class"
    public var feeHelper: String                      // new: "Students you add to this class start at this fee." · edit: "Changing it changes the fee of every student on the class fee, from next month's bill."
    public var feeError, nameError, timeError: String?
    public var everyDay: Bool { get set }             // all seven on; setting false clears them
    public var summary: String                        // "Tue, Thu, Sat · 18:00–19:30" (the draft as a Classroom would say it)
    public var dayItems: [DayPicker.Item]             // seven, ids 1 to 7
    public var daySelection: Set<Int> { get set }     // the DayPicker binding
    public var draft: ClassroomDraft; public var isChanged: Bool; public var canSave: Bool
    public func setStart(_ time: TimeOfDay?); public func setEnd(_ time: TimeOfDay?)   // nil clears
    public static let defaultStart = TimeOfDay(hour: 17, minute: 0)!   // the first tap on "Not set"; the end defaults to an hour later
}
```

- [ ] **Step 1: Failing tests**

```swift
import Data
import Domain
import Testing
@testable import Students

@MainActor struct ClassFormStoreTests {
    @Test func aNewClassNeedsOnlyAName() {
        let form = ClassFormStore(mode: .new)
        #expect(form.title == "New class" && !form.canSave && form.summary == "No days set" && form.feeHelper == "Students you add to this class start at this fee.")
        form.name = "Class 12 Physics"
        #expect(form.canSave && form.draft.trimmedName == "Class 12 Physics" && form.draft.meetingDays.isEmpty)
    }

    @Test func daysTimesAndTheSummary() {
        let form = ClassFormStore(mode: .new)
        form.name = "Class 12 Physics"
        form.daySelection = [2, 4, 6]
        #expect(form.days == [.tuesday, .thursday, .saturday] && form.summary == "Tue, Thu, Sat")
        form.setStart(TimeOfDay(hour: 18, minute: 0))
        #expect(form.endTime == TimeOfDay(hour: 19, minute: 0), "the end defaults to an hour after the start")
        form.setEnd(TimeOfDay(hour: 19, minute: 30))
        #expect(form.summary == "Tue, Thu, Sat · 18:00–19:30" && form.canSave)
        form.setEnd(TimeOfDay(hour: 17, minute: 0))
        #expect(form.timeError == "The class has to end after it starts." && !form.canSave)
        form.setStart(nil)
        #expect(form.timeError == nil && form.canSave && form.endTime == nil, "clearing the start clears the end")
        form.everyDay = true
        #expect(form.days.count == 7 && form.summary == "Every day")
        form.everyDay = false
        #expect(form.days.isEmpty && form.dayItems.map(\.initial) == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func theFeeIsCheckedInWords() {
        let form = ClassFormStore(mode: .new)
        form.name = "Class 12 Physics"
        form.feeText = "15oo"
        #expect(form.feeError == "Type a whole number of rupees." && !form.canSave)
        form.feeText = "1,500"
        #expect(form.feeError == nil && form.draft.fee == Money(rupees: 1500) && form.canSave)
    }

    @Test func editingStartsFromTheClassAndSavesOnlyWhenChanged() {
        let form = ClassFormStore(mode: .edit(FakeClassesRepository.maths))
        #expect(form.title == "Edit class" && form.name == "Class 10 Maths" && form.subject == "Mathematics" && form.feeText == "1,200")
        #expect(form.days == [.monday, .wednesday, .friday] && form.summary == "Mon, Wed, Fri · 17:00–18:00" && !form.canSave)
        #expect(form.feeHelper == "Changing it changes the fee of every student on the class fee, from next month's bill.")
        form.daySelection.insert(6)
        #expect(form.isChanged && form.canSave)
    }
}
```

- [ ] **Step 2: Run to see them fail; implement**

```swift
import DesignSystem
import Domain
import Foundation
import Observation

@MainActor @Observable public final class ClassFormStore {
    public enum Mode: Sendable {
        case new
        case edit(Classroom)
    }

    public static let defaultStart = TimeOfDay(hour: 17, minute: 0)!
    public let mode: Mode
    private let original: ClassroomDraft?
    public var name = ""
    public var subject = ""
    public var feeText = ""
    public var days: Set<Weekday> = []
    public private(set) var startTime: TimeOfDay?
    public private(set) var endTime: TimeOfDay?

    public init(mode: Mode) {
        self.mode = mode
        if case let .edit(classroom) = mode {
            let draft = ClassroomDraft(classroom)
            original = draft
            name = draft.name
            subject = draft.subject
            feeText = draft.fee.map(StudentFormStore.text) ?? ""
            days = draft.meetingDays
            startTime = draft.startTime
            endTime = draft.endTime
        } else {
            original = nil
        }
    }

    public var title: String { if case .edit = mode { "Edit class" } else { "New class" } }

    public var feeHelper: String {
        if case .edit = mode { "Changing it changes the fee of every student on the class fee, from next month's bill." }
        else { "Students you add to this class start at this fee." }
    }

    public var everyDay: Bool {
        get { days.count == Weekday.allCases.count }
        set { days = newValue ? Set(Weekday.allCases) : [] }
    }

    public var dayItems: [DayPicker.Item] { Weekday.allCases.map { DayPicker.Item(id: $0.rawValue, initial: $0.initial, name: $0.name) } }

    public var daySelection: Set<Int> {
        get { Set(days.map(\.rawValue)) }
        set { days = Set(newValue.compactMap(Weekday.init(rawValue:))) }
    }

    public var draft: ClassroomDraft {
        var draft = ClassroomDraft()
        draft.name = name
        draft.subject = subject
        draft.fee = Money(typed: feeText)
        draft.meetingDays = days
        draft.startTime = startTime
        draft.endTime = endTime
        return draft
    }

    public var summary: String {
        Classroom(id: UUID(), name: name, subject: nil, monthlyFee: nil, meetingDays: days, startTime: startTime, endTime: endTime, archivedAt: nil).meetingSummary
    }

    public var feeError: String? {
        if !feeText.isEmpty, Money(typed: feeText) == nil { return "Type a whole number of rupees." }
        return draft.problems.contains(.feeTooHigh) ? ClassroomDraft.Problem.feeTooHigh.message : nil
    }

    public var nameError: String? { draft.problems.contains(.nameTooLong) ? ClassroomDraft.Problem.nameTooLong.message : nil }
    public var timeError: String? { draft.problems.contains(.endNotAfterStart) ? ClassroomDraft.Problem.endNotAfterStart.message : nil }
    public var isChanged: Bool { original.map { $0 != draft } ?? true }
    public var canSave: Bool { draft.isValid && feeError == nil && isChanged }

    public func setStart(_ time: TimeOfDay?) {
        startTime = time
        if let time, endTime == nil { endTime = TimeOfDay(hour: min(time.hour + 1, 23), minute: time.minute) }
        if time == nil { endTime = nil }
    }

    public func setEnd(_ time: TimeOfDay?) { endTime = time }
}
```

- [ ] **Step 3: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios` → green.

```bash
git checkout -b phase-3/classes
git add ios
git commit -m "Students: the class form store, days, times and the summary"
```

### Task 15: Classes list and the class form sheet, to `P3-Classes-Empty`, `P3-Classes-List`, `P3-NewClass`, `P3-EditClass` (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/ClassesView.swift`, `ClassFormSheet.swift`
- Modify: `StudentsView.swift` (the Classes row and "Create a class" push and present), `StudentsNavigation` (`showUnassigned`), `AppShell/TabsView.swift` (the `.classes` destination), `LaunchState.swift`, `Fixtures.swift`, `RootView.swift`

**Interfaces:**
- Consumes: `RegisterStore` (Task 8), `ClassFormStore` (Task 14), `ClassRow` (Phase 2's component, its subtitle now the summary without the fee), `DayPicker`, `TileRow`, `FilterChip`, `SheetHeader`, `DialogView`.
- Produces:

```swift
public struct ClassesView: View {
    public init(register: RegisterStore, navigation: StudentsNavigation, boardState: ClassesBoardState? = nil)
}
public enum ClassesBoardState: Sendable { case newClass }
public struct ClassFormSheet: View {
    /// `onArchive` is given only when editing; it shows the Archive class button and its confirmation.
    public init(store: ClassFormStore, membersCount: Int = 0, showsFocus: Bool = false, onSave: @escaping (ClassroomDraft) async -> Bool,
                onArchive: (() async -> Void)? = nil, onClose: @escaping () -> Void)
}
public struct StudentsNavigation { …, showUnassigned: @escaping () -> Void }   // pops to the root with the "No class" filter
public enum LaunchState { …, classesEmpty = "classes-empty", classes, classNew = "class-new", classEdit = "class-edit", classArchiveConfirm = "class-archive-confirm" }
```

- [ ] **Step 1: The Classes screen**

Pushed; hides the tab bar; the navigation row: back, "Classes" in `headline`, `IconButton(symbol: "plus", label: "Create a class") { showsNew = true }`.

- When there is no active class: `Card { EmptyState(symbol: "book.closed", title: "No classes yet", line: "Classes you add appear here with their meeting days and fee. A class takes attendance in one go and gives new students their fee.", action: .init("Create a class", emphasis: .primary) { showsNew = true }) }`.
- Else: `SectionHeader("\(n) classes")` (singular "1 class"), `Card { ForEach(register.activeClasses) { c in ClassRow(name: c.name, summary: c.meetingSummary, members: register.members(of: c.id).count) { navigation.openClass(c.id) } } }`; then, when `register.unassigned` is not empty, `SectionHeader("Not in a class")`, `Card(.compact)` with `IconTile(symbol: "person.crop.circle.badge.questionmark")`, "\(n) student(s)" in `rowTitle`, the names joined by ", " in `footnote` `text2` (`lineLimit(1)`), chevron → `navigation.showUnassigned()`; under it the footnote `text3` "A student without a class is counted and billed on their own fee; attendance is taken by class."
- Archived classes are not listed (the decisions table; there is no board for them and no restore in this phase).

The sheet: `.sheet(isPresented: $showsNew) { ClassFormSheet(store: ClassFormStore(mode: .new), showsFocus: boardState == .newClass, onSave: { await register.addClass($0) != nil }, onClose: { showsNew = false }).presentationDetents([.medium, .large]).presentationDragIndicator(.hidden) }`. `StudentsView`'s Classes row pushes `.classes` through `navigation.openClasses()`; its "Create a class" buttons present the same sheet from the root.

- [ ] **Step 2: The class form sheet, to `P3-NewClass` and `P3-EditClass`**

`SheetHeader(title: store.title, cancel: ("Cancel", cancel), save: .init("Save", enabled: store.canSave && !saving, run: save))`, then the fields 16 apart:

1. `TextWell(label: "Name", text: $store.name, placeholder: "Class 9 English, Evening batch…", error: store.nameError, content: nil, showsFocus: showsFocus)`.
2. `TextWell(label: "Subject", text: $store.subject, placeholder: "Mathematics, Science…", optional: true)`.
3. `TextWell(label: "Monthly fee", text: $store.feeText, placeholder: "0", helper: store.feeHelper, error: store.feeError, prefix: "₹", suffix: "per month", numeric: true, keyboard: .numberPad, capitalisation: .never)`.
4. A row: the label "Meets on" (`footnote` `text2`) and, right, `FilterChip("Every day", isOn: store.everyDay) { store.everyDay.toggle() }`; under it `DayPicker(items: store.dayItems, selection: $store.daySelection)`.
5. The label "Time" with "(optional)"; `HStack(spacing: Tokens.tileGap)` of two tiles: `TileRow(label: "Starts", labelTone: Tokens.text2) { timeControl(store.startTime, set: store.setStart) }` and the same for "Ends" with `store.setEnd`; `timeControl` shows, when nil, `Button("Not set") { set(ClassFormStore.defaultStart) }.buttonStyle(.quiet)` and, when set, a compact `DatePicker("", selection: binding, displayedComponents: .hourAndMinute).labelsHidden().tint(Tokens.accentText.color)` (the system's time picker); a quiet "Clear times" under the tiles when either is set; `FieldMessage(store.timeError!)` when set; then `Text(store.summary).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)`.
6. Editing only: `Button { confirmingArchive = true } label: { Label("Archive class", systemImage: "archivebox") }.buttonStyle(.destructive())` and the centred footnote `text3` "Its students stay in Students with no class. Attendance history is kept."

The archive confirmation is the dialog pattern (the same component and words shape as `P3-Archive-Confirm`), drawn in the sheet's overlay: title "Archive \(name)?", message "\(membersCount) students stay in Students with no class. Attendance history is kept. The class leaves every list." (singular "1 student stays"), Cancel, "Archive" (primary); on Archive, `await onArchive()` then the sheet and the class detail close. `Cancel` with changes asks "Discard changes?" as the student form does. The `class-archive-confirm` state opens the edit sheet and the dialog (a picture for the PR, the pattern's words with the class's).

- [ ] **Step 3: Launch states and fixtures**

`classesEmpty` (the few fixture, no classes; pushes `.classes`), `classes` (seed; pushes `.classes`), `classNew` (seed; pushes `.classes` with `boardState: .newClass` and the fixture store filled: Class 12 Physics, Physics, "1,500", Tue Thu Sat, 18:00 to 19:30, the name not focused: the board draws it plain), `classEdit` and `classArchiveConfirm` (seed; push `.classroom(maths)` with the edit sheet open, and the dialog for the second; the class detail route is Task 16: for this task, the two states push `.classes` and present the edit sheet from a `ClassesBoardState.editMaths` / `.archiveMaths` so the picture can be taken; Task 16 moves them to the detail route). Append to `LaunchStateTests`.

- [ ] **Step 4: Build, photograph, compare**

`bun shots classes-empty`, `classes`, `class-new`, `class-edit`, `class-archive-confirm`; compare with `P3-Classes-Empty`, `P3-Classes-List`, `P3-NewClass`, `P3-EditClass`. Commit:

```bash
git add ios
git commit -m "Classes: the list, the empty state, the new and edit class sheet with Archive class"
```

### Task 16: Class detail and the add-students sheet, to `P3-ClassDetail` and `P3-ClassDetail-AddMembers` (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Students/ClassDetailView.swift`, `AddMembersSheet.swift`
- Modify: `AppShell/TabsView.swift` (the `.classroom` destination), `LaunchState.swift`, `Fixtures.swift`, `RootView.swift`
- Test: `Tests/StudentsTests/RegisterStoreTests.swift` (`archivingAClassDetachesItsMembers` is already there from Task 8; add `removingAMemberLeavesThemWithNoClass`)

**Interfaces:**
- Consumes: `RegisterStore.members(of:)`, `assign`, `archiveClass`, `updateClass` (Task 8); `Classroom.meetings(inWeekOf:calendar:)` (Task 2); `ClassFormSheet` (Task 15); `MeetingRow`, `MemberRow`, `ChecklistRow`, `IconTile(.header)`, `EmptyRow`, `EmptyState`.
- Produces:

```swift
public struct ClassDetailView: View {
    public init(id: UUID, register: RegisterStore, actions: StudentsActions, navigation: StudentsNavigation, boardState: ClassDetailBoardState? = nil, onMessage: @escaping (String) -> Void)
}
public enum ClassDetailBoardState: Sendable { case addMembers, edit, archiveConfirm }
public struct AddMembersSheet: View { public init(classroom: Classroom, candidates: [Student], classNames: (UUID?) -> String, preselected: Set<UUID> = [], onAdd: @escaping ([UUID]) async -> Void, onClose: @escaping () -> Void) }
public enum LaunchState { …, classDetail = "class", classAddMembers = "class-add-members" }
```

- [ ] **Step 1: Failing test** (append to `RegisterStoreTests`)

```swift
    @Test func removingAMemberLeavesThemWithNoClass() async {
        let store = make()
        await store.load()
        let dev = store.students.first { $0.name == "Dev Kumar" }!
        await store.assign([dev.id], to: nil)
        #expect(store.student(dev.id)?.classID == nil && store.members(of: FakeClassesRepository.science.id).count == 2 && students.assigned.last?.1 == nil)
    }
```

- [ ] **Step 2: The class detail**

Pushed, tab bar hidden. Navigation: back, the class name in `headline`, "Edit" (quiet) → the edit sheet (`ClassFormSheet(store: ClassFormStore(mode: .edit(classroom)), membersCount: members.count, onSave: { await register.updateClass(id, with: $0) }, onArchive: { await register.archiveClass(id); dismiss() }, onClose:)`).

1. **Header**: `IconTile(symbol: "book.closed", size: .header)`; the name in `title1`; under it `[subject, meetingSummary, fee.map { "\($0.formatted) a month" }].compactMap { $0 }.joined(" · ")` in `footnote` `text2`.
2. **This week**: `SectionHeader("This week", action: ("Mark attendance", { actions.openMarkAttendance(id) }))`; `Card { ForEach(meetings) { day in MeetingRow(day: day.weekday(in: calendar).short, title: day == register.today ? "Today, \(day.longText)" : day.longText, time: classroom.timeRange, isToday: day == register.today) } }` with `meetings = classroom.meetings(inWeekOf: register.today, calendar: DayHeading.india)`; when empty, `EmptyRow(symbol: "calendar", title: "No fixed days yet", line: "Set the days it meets in Edit to see the week here.")`.
3. **Members**: `SectionHeader("\(members.count) students", action: ("Add", { showsAdd = true }))` ("1 student"); `Card { ForEach(members) { s in MemberRow(initials: s.initials, name: s.name, phone: s.parentPhone?.display ?? "No number yet", fee: s.monthlyFee?.formatted) { navigation.openStudent(s.id) }.contextMenu { Button("Remove from class", systemImage: "person.badge.minus", role: .destructive) { Task { await register.assign([s.id], to: nil) } } } } }`; when empty, `EmptyRow(symbol: "person.2", title: "No students yet", line: "Add students from the register, or pick this class when you add one.")`. Removal is the row's context menu and the student's own Edit (class → No class); the list is a card, not a `List`, so there is no swipe action; `information-architecture.md` is corrected at Task 19.

Board states: `.addMembers` opens the sheet with Sahil Verma preselected; `.edit`, `.archiveConfirm` open the edit sheet (and the dialog), replacing Task 15's interim placement of `classEdit` and `classArchiveConfirm`.

- [ ] **Step 3: The add-students sheet, to `P3-ClassDetail-AddMembers`**

`SheetHeader(title: "Add to \(classroom.name)", cancel: ("Cancel", onClose))`; a `ScrollView` with a `Card` whose fill is `surface2` (a card inside a sheet: give `Card.Kind` a `.onSheet` case, `surface2` fill, `line` border, no shadow) holding `ChecklistRow(initials:, name:, detail: classNames(s.classID), isOn: binding(s.id))` for every candidate (`register.activeStudents` not in the class, by name; `classNames` gives the class name or "No class yet"); under it the footnote `text3` "A student moved from another class keeps a fee of their own; otherwise this class's fee applies from next month."; when there are no candidates, `EmptyState(symbol: "person.2", title: "Everyone is in this class", line: "Add a student from the Students tab first.")`. The footer `Button(label).buttonStyle(.primary(.sheet, loading: adding)).disabled(selected.isEmpty)` with the label "Add 1 student" / "Add 3 students" / "Add students" when none selected; on tap `await onAdd(Array(selected))` then `onClose()`. Detents `.medium, .large`.

- [ ] **Step 4: Launch states, build, photograph, compare, try for real**

`classDetail` and `classAddMembers` push `.classroom(FakeClassesRepository.maths.id)`; `classEdit` and `classArchiveConfirm` move here. Append to `LaunchStateTests`. `bun shots class`, `class-add-members`, and again `class-edit`, `class-archive-confirm`; compare with `P3-ClassDetail`, `P3-ClassDetail-AddMembers`, `P3-EditClass`. Against the local stack: create a class, add Sahil to it, remove him through the row's menu, archive the class and see Dev, Meher and Nikhil as "No class yet" with Dev's ₹1,000 kept, Today's "Classes today" following.

```bash
git add ios
git commit -m "Class detail: this week's meetings, the members with add and remove, edit and archive"
```

### Task 17: Classes pull request (PR 7)

- [ ] **Step 1: The pull request with the pictures**

```bash
bun check
git push -u origin phase-3/classes
bun pr-shots phase-3-classes .shots/classes-empty/*.png .shots/classes/*.png .shots/class-new/*.png .shots/class-edit/*.png .shots/class-archive-confirm/*.png .shots/class/*.png .shots/class-add-members/*.png
gh pr create --title "Classes: list, new and edit, detail with this week and the members, add and remove, archive" --body "$(cat <<'EOF'
Phase 3, PR 7 (Tasks 14 to 17). The Classes list (and its empty state, and the "Not in a class" row), the class form (days, optional times, the summary; Archive class at the bottom of Edit with its confirmation), the class detail (this week's meetings from the meeting days with today marked; the members with Add as a checklist sheet and Remove from the row's menu; Mark attendance to the later board until Phase 4). Archiving a class detaches its students through archive_class (migration 0003).

Checked: `bun check` green; the class form store and the register's class writes tested; tried against the local stack; the pictures below.

<the table bun pr-shots printed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Merge when green and the pictures show.

### Task 18: The deferred minors whose files this phase touches (PR 8)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/Fields.swift` (`PhoneWell.typed`), `CodeField.swift`, `Modifiers/Shadowed.swift`, `Modifiers/Haptics.swift` callers in `Features/Students` and `Features/Settings`
- Test: `Tests/DesignSystemTests/PhoneWellTests.swift`, `ShadowTokenTests.swift` (new)

From `plan/sessions/004/record.md`, "Deferred minors", the ones whose files Phase 3 works in:

- [ ] **Step 1: ASCII digits only in the phone and code fields.** Failing test in `PhoneWellTests`: `PhoneWell.typed("९८७६५४३२१०").digits == ""` and `PhoneWell.typed("98765½").digits == "98765"`; a pasted "+91 96112 99988" gives `"9611299988"` and a pasted "0091 96112 99988" the same (the group space is re-inserted once). Implement in `PhoneWell.typed(_:)` with `PhoneNumber(indianDigits:)` doing the prefix work and `$0.isASCII && $0.isNumber` for the filter; the same filter in `CodeField`.
- [ ] **Step 2: Shadows parsed once per token.** Failing test in `ShadowTokenTests`: `ShadowToken.parsed` for `Tokens.shadowRaised` returns the same array on two calls and never re-parses (count the parses through an internal counter under `#if DEBUG`). Implement a `static let` cache keyed by the token's name in `Shadowed.swift`, so a list of sixty rows does not parse CSS sixty times a frame.
- [ ] **Step 3: The haptics table.** `Haptic.play(.success)` after a student or class is saved (the register store's `succeeded()` is a store; the view plays it in `onChange` of a new `lastSavedAt` the store sets), and `Haptic.play(.error)` when a failure toast shows (in `StudentsView`'s `onChange(of: store.message)` and Settings' equivalent). No test: UIKit feedback generators have no observable state; say so in the PR.
- [ ] **Step 4: Run, commit, pull request**

```bash
bun check
git checkout -b phase-3/polish-minors
git add ios
git commit -m "Deferred minors: ASCII digits only in phone and code fields, shadows parsed once per token, the success and error haptics"
git push -u origin phase-3/polish-minors
gh pr create --title "Deferred minors: digits, shadow parsing, haptics" --body "Phase 3, PR 8 (Task 18): the Phase 2 review's minors whose files this phase works in. Nothing seen changes (the phone field's digits and the shadows draw the same); no pictures.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

### Task 19: Deploy, TestFlight, as built, state, record, resume (documents only, `main`)

- [ ] **Step 1: Production.** Migration 0003 went up after PR 3 (`gh workflow run deploy`); run it again now so the API carries the merged head's commit (D21) and the summary shows nothing pending. Then `gh workflow run testflight`; build 0.1.0 (n) uploads; the owner installs it and adds real students and a class. Record the build number and the run in `STATE.md`.
- [ ] **Step 2: `plan/phase-03-students-and-classes.md` "As built"**: the PR table with the real numbers, the acceptance checked line by line (every board state photographed; add, edit, move, archive, restore, delete a student and a class with the list following without a reload; the seed's ten and two on a fresh sign-in to the local stack; the Domain tests), the deviations and why (`Classroom`; the popover for the "+" menu; no swipe to remove; archived classes unlisted; the class archive confirmation state; waived in text2; whatever the build taught), what remains (the attendance section, Fees "See all", Mark attendance and Scan register until their phases; the class restore if ever wanted).
- [ ] **Step 3: `docs/design/`**: `information-architecture.md`: the "+" menu is a popover with the board's rows (the system draws the glass); removal from a class is the row's context menu, not a swipe; add `class-archive-confirm` to the launch states; `components.md` Menu paragraph likewise. A value that became a token during the build is already in `design-tokens.md` by the PR that needed it.
- [ ] **Step 4: `plan/README.md`**: Phase 3 "Done (session N, PRs #a to #b)"; any decision the build took gets its number. `plan/STATE.md`: last updated; Phase 3 done; the build on TestFlight; migrations 0001 to 0003 in production; open items (the Phase 2 minors not taken; the owner's UI polish pass; Phase 0 step 0.5 next).
- [ ] **Step 5: `plan/sessions/00N/record.md` and `owner-messages.md`**, as `SESSIONS.md` says; `ios/CLAUDE.md`: the new test target, the register cache file, the popover ruling; `supabase/CLAUDE.md`: 0003 is on the hosted project.
- [ ] **Step 6: Commit to `main`, push.** Then ask for a reviewer pass on the eight merged pull requests with `superpowers:requesting-code-review` and record its outcome in the record and `STATE.md` (fixes test-first in a follow-up PR; minors deferred with their files named), as Phase 2 did.

---

## Self-review

- **Spec coverage.** Phase file scope 1 (list: search by name or phone, filter by class and status, sort by name or fee, empty, few, many states, pull to refresh, counts): Tasks 3, 8, 9. Scope 2 ("+" menu: add, scan → Phase 6's later state, create a class): Task 9 (the popover), Task 15 (the class sheet). Scope 3 (new and edit student with the eight fields, phone E.164 with +91 and formatting as typed, Save disabled until valid): Tasks 10, 11, 13. Scope 4 (detail: header with avatar and class, parent actions in one row, fees now, attendance in Phase 4, notes, edit, archive, restore, delete typed): Tasks 12, 13. Scope 5 (classes list with counts and summary; new and edit with the six fields and "every day"; detail with members add and remove, the week's meetings, mark attendance shortcut; archive): Tasks 14 to 17. Scope 6 (domain rules tested: phone, fee prefill, meeting summary, initials, sort and filter): Tasks 1 to 3 (phone normalisation is Phase 2's `PhoneNumber`, exercised again in `StudentDraftTests`). Scope 7 (repositories with cache; optimistic create and update; archive as soft delete): Tasks 4, 5, 8. Acceptance: pictures in every screen PR (Tasks 9, 11, 13, 15 to 17); add, edit, move, archive, restore, delete for students and classes with the list following (Task 8's tests and the hand runs in Tasks 11, 13, 16); the seed on a fresh sign-in (the Supabase repositories read what `seed.sql` wrote; the hand run in Task 11); Domain tests for every rule (Tasks 1 to 3). Inventory rows: all placed (Global Constraints, last line). `docs/spec.md` section 4: reads through cache then view (Task 8's `load()`), optimistic writes reverted with a toast (Task 8), one `@Observable` store per screen with repositories through initialisers (Tasks 8, 10, 12, 14), features never import each other (`StudentsActions`, `StudentsNavigation`).
- **Placeholders.** The views (Tasks 9, 11, 13, 15, 16) are given as their pieces with the exact components, tokens, copy and wiring rather than full SwiftUI bodies, as Phase 2's plan gave its screens; every number is a token or a named anatomy constant and every word is on a board. No "TBD", no "handle edge cases"; the one untested step (Task 18 step 3, haptics) says why.
- **Type consistency.** `MonthFee` is declared in Task 3 with `amount`, `status`, `paidOn` and `paidMethod: PaidMethod?` (the detail's "Paid by UPI on 4 Oct", Task 12); Task 4's `StudentRow.Invoice` decodes `paid_method` and the select names it. `Classroom.meetings(inWeekOf:calendar:)` (Task 2) is what Task 16 calls. `RegisterStore`'s methods (Task 8) are what Tasks 9, 11 to 16 call: `addStudent`, `updateStudent`, `setArchived`, `deleteStudent`, `assign`, `addClass`, `updateClass`, `archiveClass`, `retryLast`, `members(of:)`, `unassigned`, `rowDetail(for:)`, `countLine`, `period`, `today`. `StudentFormStore.text` (Task 10) is reused by `ClassFormStore` (Task 14). `StudentsNavigation` gains `showUnassigned` in Task 15; Task 9 declares the first three closures. `LaunchState` raw values match the table in `information-architecture.md` (`student-edit` is photographed in PR 6 with the detail, where its sheet opens from; `class-archive-confirm` is added to the table at Task 19). `DialogView.confirms(typed:name:)` (Task 12) is what the delete dialog uses (Task 13). `Card.Kind.onSheet` (Task 16) is a DesignSystem addition made in PR 7, with its preview.
- **Review Focus.** 1 → Task 8 `aFailedAddRevertsTheRowAndOffersRetry`, `retryWritesOnce`. 2 → Task 3 `matchesNamesAndNumbersHoweverTyped`, `archivedStudentsAreFoundBySearchAndHiddenByAll`. 3 → Task 10 `anUntouchedFeeFollowsTheClassATypedOneStays`, `clearingTheFeeReturnsToTheClassFee`. 4 → Task 6 `deleting a student cascades…` and Task 12 `DialogTests.theTypedNameConfirmsIgnoringCaseAndSpaces` (the dialog owns the comparison, so the test sits with it). 5 → Task 6 `archive_class detaches members…`, Task 8 `archivingAClassDetachesItsMembers`, Task 12 `aLinkToAMissingStudentSaysSo` and `TabsStateTests.aStudentLinkOpensTheDetailOnTheStudentsTab`.
