# Phase 4 Attendance, Schedule, Tasks and Today Live Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The daily loop works: Today shows the next class with the time until it starts, marking a class of ten takes two taps when everyone came and three when one did not, an absent child's parent is told on WhatsApp in one tap, the history reads by date and by student, the schedule shows the month with its classes and events, tasks live on Today and under More; every screen built to its approved Phase 4 board in both appearances, proven against the local stack by the runbook (D32), on TestFlight.

**Architecture:** `Domain` gains the value types (`AttendanceStatus`, `AttendanceSession`, `AttendanceDraft`, `CalendarEvent`, `EventDraft`, `TaskItem`) and the pure rules (the next class from meeting days and the clock, "in 25 min" wording, a class's days in a month, attendance percentages, task ordering, the absence message), all tested first. `Data` gains three repositories (attendance, events, tasks) plus the message log, each a protocol with a Supabase implementation and an in-memory fake seeded as `supabase/seed.sql` seeds (the four weeks of attendance by its rule, two events, four tasks), and each read's answer decoded in a test against the shape PostgREST really returns (session 6's Critical). One additive migration (0004) adds `save_attendance`, the one write that touches two tables. `Features/Attendance` holds the mark and history screens, `Features/Schedule` the month and the event form, `Features/Today` the live Today, the tasks store and the Tasks screen; `AppShell` adds the More root, the routes, the deep links `attendance?date=&class=` and `event/<id>`, the status-bar glass on every tab root (U1) and the Phase 4 launch states.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, Observation, Swift Testing, `supabase-swift` 2.55.3 (PostgREST reads with embedded `attendance_marks`, inserts, updates, deletes, one RPC), Postgres (one `security invoker` function with a jsonb argument), Bun tests against local Supabase, XcodeGen, GitHub Actions on `xcode-27` (D22), the simulator runbook (D32).

**Spec:** `docs/spec.md` sections 2, 4 and 5; scope and acceptance in `plan/phase-04-attendance-schedule-today.md`; the boards `docs/design/mockups/P4-*.dc.html` (canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, row 7; the list, the launch states and what the boards settle in `docs/design/information-architecture.md`, "Phase 4 boards"); `design-tokens.md`, `components.md` (the Phase 4 additions: the attendance row's pill, the history rows, the footer button on a root, the status bar on a scrolled root, the percentage hero, the message sheet, the inline add), `guidelines.md`; the Home, Schedule and Attendance rows of `docs/reference/functional-inventory.md`; decisions D1 to D32 in `plan/README.md`; Phase 3's "As built" and the deferred minors in `plan/sessions/006/record.md`; `docs/runbooks/simulator.md` for every hand run; `plan/ui-polish.md` (U1 to U4, all closed by Task 18).

## Global Constraints

- iOS 26.0 minimum, iPhone only (D1), bundle id `in.tutorcentral.app` (D27). Swift language mode 6, `SWIFT_STRICT_CONCURRENCY = complete`, SwiftUI only, Observation (D8). Features never import each other: a feature reaches another feature's screen through closures `AppShell` provides (`TodayActions`, `StudentsActions`, the new `AttendanceActions` and `ScheduleActions`), never an import.
- Style only through `DesignSystem` tokens (D10, D25): no raw colour, size, radius, shadow or duration in a feature view. A board value the document does not name becomes a token in `design-tokens.md` and Swift in the same commit; an anatomy number lives as a named constant on its component (Phase 2's ruling). Every new component gets a SwiftUI preview. The Kit's attendance rows change with `AttendanceRow` (its boards were redrawn with step 0.5), nothing else on the Kit changes.
- Both appearances built and photographed (D13, D23). Every board state is a `LaunchState` whose raw value is the name in `information-architecture.md`'s Phase 4 table; `bun shots <state>` photographs it; every pull request that changes what is seen carries the table `bun pr-shots` prints, for each changed state in both appearances (D7, `CLAUDE.md` rule 2). No board, no screen (rule 1): a state this plan did not foresee is drawn and approved first.
- Copy: sentence case, no exclamation marks, no emoji, no jargon ("class" never "session" on screen; "mark" never "record"); buttons are verbs with an object; errors say what happened and what to do (`guidelines.md`). The copy of every screen is on its board and repeated in the task that builds it; the boards name the student and the parent, never a pronoun.
- Money `₹4,000` (`Money.formatted`); dates `7 Oct`, `Mon 5 Oct`, `Sat 10 Oct 2026`, `Today, 7 October`, `Saturday 10 October`; times 24-hour `17:00`, ranges `17:00–18:00` (en dash); relative `in 25 min`, `in 2 h`, `starts now`; a day column `Wed` over `7 Oct`. The centre's calendar is India (`DayHeading.india`); every Phase 4 rule takes a `Calendar` and the tests pass `DayHeading.india`.
- Database (`supabase/CLAUDE.md`): one migration per change, additive while any installed build uses what it would remove (D26); every new function is `security invoker`, `set search_path = ''`, revokes `public` and `anon`, grants `authenticated`; `supabase gen types typescript --local > types.ts` after the migration; a test in `supabase/tests/`. Migrations reach production only through `gh workflow run deploy` (D26); the TestFlight lane refuses a build while one is pending. No new table: migration 0001 holds `attendance_sessions`, `attendance_marks`, `calendar_events`, `tasks` and `message_log` with every column the phase needs.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`, no bare `@Suite`) in `Tests/DomainTests`, `Tests/DataTests`, `Tests/AppShellTests`, `Tests/TodayTests` and the new `Tests/AttendanceTests` and `Tests/ScheduleTests` (in `Package.swift` and the scheme in `project.yml`). Stores are tested against the fakes. No UI test suites (D15). Every repository read decodes a test fixture copied from what the local stack answers (`curl` as the seed's tutor, pasted into the test), and every write path is run in Swift against the local stack before its pull request merges (`ios/CLAUDE.md`: a throwaway test with an in-memory session, deleted before the commit).
- Hand runs (D32): before the TestFlight build, every write path this phase adds is driven through the screens against the local stack by `docs/runbooks/simulator.md` and confirmed in the database; Task 20 names each run. The screenshots go on the pull request or the phase's issue.
- `bun check` before every commit; code reaches `main` only through a pull request with a green check; documents only go to `main` directly, never mixed with code (D12). Bun only (D16). `supabase-swift` stays the only iOS dependency (D14). A new decision gets its number in `plan/README.md` in the pull request that acts on it.
- Nothing from the reference app is dropped (rule 10): the inventory's Home rows (welcome; tappable tiles; schedule shortcut; tasks with inline add, swipe to complete, optional due date; next class first with the time until it starts and one tap to mark; upcoming events; AI tools row in Phase 6), Schedule rows (month calendar with marked days; the day's classes from meeting days; events add, list, edit, delete) and Attendance rows (date, class or all, all present then exceptions; counts; history by date and by student with a monthly percentage; the absence alert as a logged WhatsApp link) are all placed below. Class and event reminders (notifications) are Phase 7; the attendance export is Phase 5.

## Review Focus

Inputs the spec implies but no board draws, most likely to bite a tutor first. Each has its test in the task named.

1. **The next class must be right across midnight and at the edges of a class:** at 16:35 on a Wednesday it is Class 10 Maths "in 25 min"; at 17:30 it is running ("until 18:00"); at 18:01 it is tomorrow's Class 8 Science; at 23:59 on a Sunday it is Monday's; a class with meeting days but no time is "today" without a countdown; a centre with no classes has none. Test in Task 2 (`NextClassTests`: `theNextClassAcrossTheDay`, `aClassWithoutATimeHasNoCountdown`, `sundayNightLooksToMonday`).
2. **Saving attendance must replace, never duplicate or lose:** saving the same class and day again replaces every mark (a student marked present then absent is absent once); a student added to the class after a save appears present on reopening and is saved on the next save; a student removed from the class keeps their old mark in history; "All students" and a class on the same day are two sessions; saving with no network leaves the toggles as the tutor set them and offers Retry. Tests in Task 5 (`rls.test.ts`: `save_attendance makes the session and replaces its marks`) and Task 10 (`AttendanceStoreTests`: `savingAgainReplacesTheMarks`, `aNewMemberIsPresentOnReopen`, `aFailedSaveKeepsTheMarksAndOffersRetry`).
3. **A percentage must never divide by zero or lie about an unmarked month:** a student with no classes marked this month shows "No classes marked yet", not 0%; a student who joined mid-month is counted from their first mark; the month's summary counts marks, not students. Tests in Task 1 (`AttendanceStatsTests`: `noMarksIsNotZeroPercent`, `theMonthSummaryCountsMarks`).
4. **The absence alert must open WhatsApp with the right parent and log once:** the link is `https://wa.me/<digits>?text=<url-encoded message>` with the parent's number as E.164 digits; a student with no parent number shows the message with the button disabled and "Add the parent's number first"; a second tap after a log says "Told today" and does not log again; the saved screen's "Told" reads from `message_log`. Tests in Task 4 (`AbsenceMessageTests`: `theLinkCarriesTheMessageEncoded`) and Task 10 (`AttendanceStoreTests`: `tellingAParentLogsOnce`, `aStudentWithoutANumberCannotBeTold`).
5. **Tasks and events must survive the day boundary in India:** a task done at 23:30 falls off Today after 24 hours, not at midnight; a task due today reads "Today" and an overdue one "Mon 5 Oct" in `overdue`; an event at 23:30 belongs to its date in India even when UTC says the next day; Coming up on a Sunday includes the next Saturday but not the one after. Tests in Task 3 (`TaskOrderingTests`: `doneTasksStayADay`, `dueWordsAndOverdue`; `EventTests`: `comingUpIsTheNextSevenDays`) and Task 7 (`EventRowTests`: `aDateDecodesAsADayNotAMoment`).

---

## Decisions this plan settles

Small and medium things, decided here and written down. None needs a number in `plan/README.md`.

| Decision |
|---|
| **No new table, one migration.** 0001 holds every column. Migration 0004 adds `save_attendance(p_centre uuid, p_class uuid, p_date date, p_marks jsonb) returns uuid`: upserts the session (`unique nulls not distinct (centre_id, class_id, date)`), deletes the marks of students not in `p_marks`, upserts the rest, returns the session id; two tables in one transaction, so a function, `security invoker`. Everything else is a plain insert, update or delete through RLS. |
| **The absence log is a plain insert** into `message_log` (`kind = 'absence'`, `channel = 'whatsapp_link'`, `opened_at = now()`), made when the tutor taps Open WhatsApp, before the link opens; "Told" is read back by student and day from the month's log rows. |
| **Type names.** `TaskItem` (Swift's `Task` is taken), `CalendarEvent`, `AttendanceSession` (one saved class and day with its marks), `AttendanceDraft` (what the mark screen edits), `AttendanceStatus` (`present`, `absent`), `NextClass` (the rule's answer). |
| **Reads by month.** `sessions(centre:month:)` selects `id, class_id, date, saved_at, attendance_marks(student_id, status)` for `date` within the month, ordered by date descending; the history, the student's month, the student detail and Today ("marked" ticks) all read from it; a session for one class and day is found in that list. The register (students and classes) comes from `ShellState.register`, which AppShell passes to the attendance and schedule stores as `RegisterStore`: no second read of students. |
| **One attendance store for the tab** (`ShellState.attendance`), so a tab switch keeps the date, the class and the unsaved toggles; it is reset on sign-out with the rest. History, the student's month and the schedule make their store per screen. **One tasks store** (`ShellState.tasks`) shared by Today and the Tasks screen. |
| **Everyone starts present.** Opening a class and day with no saved session makes a draft with every active member present; opening a saved one loads its marks, and a member without a mark (joined since) is present. Save sends every member's mark. |
| **The date picker** on the mark screen is the system graphical `DatePicker` in a popover (Phase 3's ruling for the date of birth), limited to today and earlier; the class is a popover menu (as the "+" menu, so its state can be photographed) with All students and each active class, each with its count. |
| **Optimistic where it is safe:** a task's add, done and clear and an event's edit apply first and roll back with a toast and Retry; an attendance save and an event's add and delete wait for the server (the footer button shows loading; a draft shown as saved before the server said so would mislead the tutor). |
| **Today's clock** is `deps.now()` read on load and every minute while Today is on screen (`TimelineView(.everyMinute)` drives the countdown; the rule is pure). Each Today launch state fixes its own clock (`Fixtures.clock(for:)`). |
| **The "Mark attendance" button** on Today's hero, the class detail's "Mark attendance", the Attendance tab and `attendance?date=&class=` all open the mark root with the date and class set (`AttendanceStore.open(classID:date:)`); from Today and the class detail the tab switches to Attendance. |
| **Tasks fall off Today 24 hours after they are done** (design-tokens.md "Numbers in code"); the Tasks screen keeps them until Clear deletes the done ones (one `delete … where done_at is not null`). A task's due date is optional; the inline chip offers the next weekday or No date; the Tasks screen offers the same. |
| **An event's note is at most 500 characters, its title 120** (the column's check). Delete asks with the dialog pattern, nothing typed. |
| **"Coming up"** lists events in the next seven days after today, soonest first, at most five, with "See all" to the schedule when there are more. |
| **The status bar on a scrolled root (U1)** is one modifier `.statusBarGlass()` in DesignSystem applied to the four tab roots that hide the navigation bar (Today, Students, Attendance, More): a top safe-area band of the system's bar material with a `lineGlass` hairline, opacity 0 at rest and 1 once the content has scrolled past 1 pt (`onScrollGeometryChange`). |
| **Tiles share a height (U4):** Today's `HStack` of tiles takes `.fixedSize(horizontal: false, vertical: true)` and each `StatTile` fills its height with the label at the bottom, so "Classes today" wrapping makes all three taller, never one. |
| **The More root is AppShell's** (`MoreView`, as `LaterView` and `TabsView` are): its rows are navigation, not a feature. Reports, the AI tools, Account and Help are later rows (not tappable, the phase named) until their phases; Classes pushes the Classes list on the More stack (the register is shared). |
| **Fixtures.** `FakeAttendanceRepository.seed` is made by the seed's rule in Swift (every fifth mark absent over the four weeks before 7 October 2026, ordered by date and name) plus Wednesday 7 October's Class 10 Maths session saved at 18:04 with Hemanth absent for the states after a save; `FakeEventsRepository.seed` holds the two boards' events; `FakeTasksRepository.seed` the seed's two open tasks and two done ones (6 and 1 October). The message log fake holds Hemanth's absence told on 5 October. |
| **The AI tools row waits for Phase 6's board** (Phase 2's ruling); Today's AI entry is not built here. |
| **TestFlight.** The phase ends with build 0.1.0 (n) after migration 0004 is in production (`gh workflow run deploy`) and the hand runs of Task 20 are done and kept. |

## File structure

```
supabase/
  migrations/20261010000004_save_attendance.sql
  tests/rls.test.ts                                  # + save_attendance (makes, replaces, all-students, refused)
  types.ts                                           # regenerated
ios/
  project.yml                                        # + AttendanceTests, ScheduleTests in the scheme
  TutorCentralKit/Package.swift                      # + AttendanceTests, ScheduleTests
  TutorCentralKit/Sources/Domain/
    AttendanceStatus.swift, AttendanceSession.swift, AttendanceDraft.swift, AttendanceStats.swift
    NextClass.swift, TimeUntil.swift, Occurrences.swift
    CalendarEvent.swift, EventDraft.swift, TaskItem.swift, TaskOrdering.swift, AbsenceMessage.swift
    Day.swift (+ shortWeekdayText "Mon 5 Oct", weekdayLongText "Saturday 10 October", isoWeek helpers)
  TutorCentralKit/Sources/Data/
    Attendance/AttendanceRepository.swift, SupabaseAttendanceRepository.swift, FakeAttendanceRepository.swift, SessionRow.swift
    Messages/MessageLogRepository.swift, SupabaseMessageLogRepository.swift, FakeMessageLogRepository.swift
    Events/EventsRepository.swift, SupabaseEventsRepository.swift, FakeEventsRepository.swift, EventRow.swift
    Tasks/TasksRepository.swift, SupabaseTasksRepository.swift, FakeTasksRepository.swift, TaskRow.swift
  TutorCentralKit/Sources/DesignSystem/Components/
    Rows.swift (AttendanceRow: one pill; + HistoryRow, StudentPercentRow, AbsentStudentRow, EventRow, TaskRow)
    FooterButton.swift (the footer above the tab bar; Saved mark), CountsLine.swift, MonthHeader.swift
    PercentHero.swift, InlineAdd.swift, ScheduleRow.swift (time over end time), StatTile.swift (fills its height, U4)
  TutorCentralKit/Sources/DesignSystem/Modifiers/StatusBarGlass.swift   # U1
  TutorCentralKit/Sources/Features/Attendance/
    AttendanceStore.swift, AttendanceActions.swift, AttendanceView.swift, AttendanceSections.swift, AbsenceAlertSheet.swift
    HistoryStore.swift, HistoryView.swift, StudentMonthStore.swift, StudentMonthView.swift, Attendance.swift (delete the marker)
  TutorCentralKit/Sources/Features/Schedule/
    ScheduleStore.swift, ScheduleActions.swift, ScheduleView.swift, EventFormStore.swift, EventFormSheet.swift, Schedule.swift (delete the marker)
  TutorCentralKit/Sources/Features/Today/
    TodayStore.swift (live), TodayView.swift (live, U1, U4), TodaySections.swift, TasksStore.swift, TasksView.swift, TaskInlineAdd.swift
  TutorCentralKit/Sources/Features/Students/
    StudentDetailView.swift (+ the live attendance section), StudentDetailSections.swift (AttendanceCard), StudentsActions.swift (+ openStudentAttendance)
  TutorCentralKit/Sources/AppShell/
    MoreView.swift (new), TabsView.swift (Attendance and More roots, the routes), TabsState.swift (Route cases, open(.attendance), open(.event)),
    ShellState.swift (attendance, tasks), RootView.swift (the views and actions), RootView+LaunchStates.swift, LaunchState.swift (+24),
    Fixtures.swift (+ clocks, the Phase 4 fakes), Dependencies.swift (attendance, messages, events, tasks), LaterView.swift (- schedule, tasks, markAttendance)
  TutorCentralKit/Tests/DomainTests/
    AttendanceDraftTests.swift, AttendanceStatsTests.swift, NextClassTests.swift, TimeUntilTests.swift, OccurrencesTests.swift,
    EventTests.swift, TaskOrderingTests.swift, AbsenceMessageTests.swift, DayTests.swift (+ the new words)
  TutorCentralKit/Tests/DataTests/
    SessionRowTests.swift, EventRowTests.swift, TaskRowTests.swift, FakeAttendanceRepositoryTests.swift, FakeEventsRepositoryTests.swift, FakeTasksRepositoryTests.swift
  TutorCentralKit/Tests/AttendanceTests/AttendanceStoreTests.swift, HistoryStoreTests.swift, StudentMonthStoreTests.swift
  TutorCentralKit/Tests/ScheduleTests/ScheduleStoreTests.swift, EventFormStoreTests.swift
  TutorCentralKit/Tests/TodayTests/TodayStoreTests.swift (live), TasksStoreTests.swift
  TutorCentralKit/Tests/AppShellTests/TabsStateTests.swift (+ links), LaunchStateTests.swift (+ Phase 4), DeepLinkTests.swift (unchanged)
  TutorCentralKit/Tests/DesignSystemTests/StatusBarGlassTests.swift (the opacity rule)
```

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 to 4 | `phase-4/domain` | Domain: attendance, the next class, events, tasks, the absence message | none |
| 2 | 5 | `phase-4/save-attendance` | Migration 0004: `save_attendance`, proven | none; after merge `gh workflow run deploy` and its summary |
| 3 | 6 to 8 | `phase-4/data` | Data: attendance, message log, events and tasks repositories, the fakes, every answer decoded | none |
| 4 | 9 to 11 | `phase-4/attendance-mark` | The Attendance tab: mark, save, the absent students, the absence alert, a past date | `attendance`, `attendance-class-menu`, `attendance-exceptions`, `attendance-saved`, `attendance-alert`, `attendance-past`, `attendance-empty`, `kit-surfaces`, both appearances |
| 5 | 12, 13 | `phase-4/history` | History by date and by student, a student's month, the detail's attendance section | `history`, `history-by-student`, `history-student`, `history-empty`, `student`, both |
| 6 | 14 to 16 | `phase-4/schedule` | Schedule: the month, a day, events add, edit and delete; the event link | `schedule`, `schedule-day`, `event-new`, `event-edit`, `event-delete-confirm`, both |
| 7 | 17 to 19 | `phase-4/today-live` | Tasks, Today live (U1 to U4), the More root, the Phase 4 states | `today`, `today-evening`, `today-no-class`, `today-adding-task`, `tasks`, `tasks-empty`, `more`, `students`, `today-empty`, both |
| main | 20 | | Deploy, the hand runs, TestFlight; as built, state, record, resume (documents only, D12) | |

---
### Task 1: Domain: attendance status, session, draft and stats; the day's new words (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/AttendanceStatus.swift`, `AttendanceSession.swift`, `AttendanceDraft.swift`, `AttendanceStats.swift`
- Modify: `ios/TutorCentralKit/Sources/Domain/Day.swift` (three words)
- Test: `ios/TutorCentralKit/Tests/DomainTests/AttendanceDraftTests.swift`, `AttendanceStatsTests.swift`, `DayTests.swift`

**Interfaces:**
- Consumes: `Day`, `Student`, `Classroom`, `Period`, `Weekday` (Phase 3).
- Produces:

```swift
public enum AttendanceStatus: String, Hashable, Sendable, Codable { case present, absent }
public struct AttendanceSession: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID; public var classID: UUID?; public var date: Day; public var savedAt: Date
    public var marks: [UUID: AttendanceStatus]           // student id → status
    public init(id:classID:date:savedAt:marks:)
    public var presentCount: Int; public var absentCount: Int
    public var absentStudentIDs: [UUID]                   // in the order given by `sorted(by:)` the caller applies
}
public struct AttendanceDraft: Hashable, Sendable {
    public var date: Day; public var classID: UUID?; public var marks: [UUID: AttendanceStatus]
    public init(date:classID:members:[Student], saved: AttendanceSession?)   // every active member present unless `saved` says absent
    public mutating func toggle(_ studentID: UUID)
    public var presentCount: Int; public var absentCount: Int
    public func absentIDs(ordered members: [Student]) -> [UUID]
    public func isChanged(from saved: AttendanceSession?, members: [Student]) -> Bool
}
public enum AttendanceStats {
    public struct Count: Hashable, Sendable { public let present: Int; public let total: Int; public var percent: Int? /* nil when total is 0 */; public var fraction: Double }
    public static func forStudent(_ id: UUID, in sessions: [AttendanceSession]) -> Count
    public static func forMonth(_ sessions: [AttendanceSession]) -> Count       // counts marks across the sessions
    public static func absences(of id: UUID, in sessions: [AttendanceSession]) -> [AttendanceSession]   // newest first
    public static func sessions(_ all: [AttendanceSession], in month: Period) -> [AttendanceSession]
}
// Day gains:
public var shortWeekdayText: String      // "Mon 5 Oct"
public var weekdayLongText: String       // "Saturday 10 October"
public var period: Period                // the month it is in
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/AttendanceDraftTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct AttendanceDraftTests {
    static let day = Day(year: 2026, month: 10, day: 7)!
    static let maths = UUID()
    static func member(_ name: String, archived: Bool = false) -> Student {
        Student(
            id: UUID(), name: name, classID: maths, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: archived ? Date() : nil, thisMonth: nil
        )
    }

    let members = [member("Akshita Rao"), member("Hemanth Reddy"), member("Riya Sharma")]

    @Test func everyoneStartsPresentAndATapMarksAbsent() {
        var draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members, saved: nil)
        #expect(draft.presentCount == 3 && draft.absentCount == 0 && draft.marks.count == 3)
        draft.toggle(members[1].id)
        #expect(draft.presentCount == 2 && draft.absentCount == 1 && draft.absentIDs(ordered: members) == [members[1].id])
        draft.toggle(members[1].id)
        #expect(draft.absentCount == 0, "a second tap undoes it")
    }

    @Test func aSavedSessionReopensWithItsMarksAndANewMemberPresent() {
        let saved = AttendanceSession(
            id: UUID(), classID: Self.maths, date: Self.day, savedAt: Date(),
            marks: [members[0].id: .present, members[1].id: .absent]
        )
        let draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members, saved: saved)
        #expect(draft.marks[members[1].id] == .absent && draft.marks[members[2].id] == .present, "Riya joined since: present")
        #expect(!draft.isChanged(from: saved, members: members), "nothing touched yet")
        var changed = draft
        changed.toggle(members[0].id)
        #expect(changed.isChanged(from: saved, members: members))
        #expect(draft.isChanged(from: nil, members: members), "a fresh class is always worth saving")
    }

    @Test func archivedMembersAreLeftOut() {
        let gone = Self.member("Old", archived: true)
        let draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members + [gone], saved: nil)
        #expect(draft.marks[gone.id] == nil && draft.presentCount == 3)
    }

    @Test func theSessionCountsItsMarks() {
        let session = AttendanceSession(
            id: UUID(), classID: nil, date: Self.day, savedAt: Date(),
            marks: [members[0].id: .present, members[1].id: .absent, members[2].id: .absent]
        )
        #expect(session.presentCount == 1 && session.absentCount == 2)
        #expect(Set(session.absentStudentIDs) == [members[1].id, members[2].id])
    }
}
```

`Tests/DomainTests/AttendanceStatsTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct AttendanceStatsTests {
    let hemanth = UUID()
    let akshita = UUID()
    func session(_ day: Int, month: Int = 10, _ marks: [UUID: AttendanceStatus]) -> AttendanceSession {
        AttendanceSession(id: UUID(), classID: nil, date: Day(year: 2026, month: month, day: day)!, savedAt: Date(), marks: marks)
    }

    @Test func aStudentsMonthIsPresentOverMarked() {
        let sessions = [
            session(2, [hemanth: .present, akshita: .present]),
            session(5, [hemanth: .absent, akshita: .present]),
            session(7, [hemanth: .present, akshita: .present]),
        ]
        let count = AttendanceStats.forStudent(hemanth, in: sessions)
        #expect(count.present == 2 && count.total == 3 && count.percent == 67)
        #expect(AttendanceStats.absences(of: hemanth, in: sessions).map(\.date.day) == [5], "newest first")
    }

    @Test func noMarksIsNotZeroPercent() {
        let count = AttendanceStats.forStudent(hemanth, in: [session(2, [akshita: .present])])
        #expect(count.total == 0 && count.percent == nil && count.fraction == 0)
    }

    @Test func theMonthSummaryCountsMarks() {
        let sessions = [
            session(2, [hemanth: .present, akshita: .absent]),
            session(5, [hemanth: .absent, akshita: .present]),
            session(28, month: 9, [hemanth: .present]),
        ]
        let october = AttendanceStats.sessions(sessions, in: Period(year: 2026, month: 10))
        #expect(october.count == 2)
        let summary = AttendanceStats.forMonth(october)
        #expect(summary.present == 2 && summary.total == 4 && summary.percent == 50)
    }

    @Test func percentRoundsHalfUp() {
        #expect(AttendanceStats.Count(present: 19, total: 24).percent == 79)
        #expect(AttendanceStats.Count(present: 1, total: 8).percent == 13)
    }
}
```

Add to `Tests/DomainTests/DayTests.swift`:

```swift
    @Test func theWordsThePhaseFourBoardsUse() {
        let saturday = Day(year: 2026, month: 10, day: 10)!
        #expect(saturday.shortWeekdayText == "Sat 10 Oct" && saturday.weekdayLongText == "Saturday 10 October")
        #expect(saturday.period == Period(year: 2026, month: 10))
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `AttendanceDraft`, `AttendanceStats` not found.

- [ ] **Step 3: Implement**

`Domain/AttendanceStatus.swift`:

```swift
/// A mark (`attendance_marks.status`). Late is out of scope (functional-inventory.md).
public enum AttendanceStatus: String, Hashable, Sendable, Codable {
    case present
    case absent
}
```

`Domain/AttendanceSession.swift`:

```swift
import Foundation

/// One saved class and day (`attendance_sessions`) with its marks; `classID` nil is the session for all students.
public struct AttendanceSession: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var classID: UUID?
    public var date: Day
    public var savedAt: Date
    public var marks: [UUID: AttendanceStatus]

    public init(id: UUID, classID: UUID?, date: Day, savedAt: Date, marks: [UUID: AttendanceStatus]) {
        self.id = id
        self.classID = classID
        self.date = date
        self.savedAt = savedAt
        self.marks = marks
    }

    public var presentCount: Int { marks.values.filter { $0 == .present }.count }
    public var absentCount: Int { marks.values.filter { $0 == .absent }.count }
    public var absentStudentIDs: [UUID] { marks.filter { $0.value == .absent }.map(\.key) }
}
```

`Domain/AttendanceDraft.swift`:

```swift
import Foundation

/// What the mark screen edits: a date, a class (nil: all students) and one mark per active member. Everyone starts
/// present; a saved session's marks come first; a member saved without a mark (joined since) is present.
public struct AttendanceDraft: Hashable, Sendable {
    public var date: Day
    public var classID: UUID?
    public var marks: [UUID: AttendanceStatus]

    public init(date: Day, classID: UUID?, members: [Student], saved: AttendanceSession?) {
        self.date = date
        self.classID = classID
        marks = Dictionary(uniqueKeysWithValues: members.filter { !$0.isArchived }.map { ($0.id, saved?.marks[$0.id] ?? .present) })
    }

    public mutating func toggle(_ studentID: UUID) {
        guard let mark = marks[studentID] else { return }
        marks[studentID] = mark == .present ? .absent : .present
    }

    public var presentCount: Int { marks.values.filter { $0 == .present }.count }
    public var absentCount: Int { marks.values.filter { $0 == .absent }.count }

    /// The absent members in the order the list shows them.
    public func absentIDs(ordered members: [Student]) -> [UUID] {
        members.map(\.id).filter { marks[$0] == .absent }
    }

    /// A fresh class is always worth saving; a reopened one only once a mark differs from what was saved.
    public func isChanged(from saved: AttendanceSession?, members: [Student]) -> Bool {
        guard let saved else { return true }
        return members.filter { !$0.isArchived }.contains { marks[$0.id] != (saved.marks[$0.id] ?? .present) }
    }
}
```

`Domain/AttendanceStats.swift`:

```swift
import Foundation

/// Percentages and absences from saved sessions (the history, the student's month, the student detail).
public enum AttendanceStats {
    public struct Count: Hashable, Sendable {
        public let present: Int
        public let total: Int

        public init(present: Int, total: Int) {
            self.present = present
            self.total = total
        }

        /// Nil when nothing is marked: the screen says so instead of 0%.
        public var percent: Int? {
            total == 0 ? nil : Int((Double(present) / Double(total) * 100).rounded())
        }

        public var fraction: Double {
            total == 0 ? 0 : Double(present) / Double(total)
        }
    }

    public static func forStudent(_ id: UUID, in sessions: [AttendanceSession]) -> Count {
        let marks = sessions.compactMap { $0.marks[id] }
        return Count(present: marks.filter { $0 == .present }.count, total: marks.count)
    }

    public static func forMonth(_ sessions: [AttendanceSession]) -> Count {
        Count(present: sessions.map(\.presentCount).reduce(0, +), total: sessions.map(\.marks.count).reduce(0, +))
    }

    /// Newest first.
    public static func absences(of id: UUID, in sessions: [AttendanceSession]) -> [AttendanceSession] {
        sessions.filter { $0.marks[id] == .absent }.sorted { $0.date > $1.date }
    }

    public static func sessions(_ all: [AttendanceSession], in month: Period) -> [AttendanceSession] {
        all.filter { $0.date.period == month }
    }
}
```

`Domain/Day.swift`, add:

```swift
    /// "Mon 5 Oct".
    public var shortWeekdayText: String { formatted("EEE d MMM") }

    /// "Saturday 10 October".
    public var weekdayLongText: String { formatted("EEEE d MMMM") }

    public var period: Period { Period(year: year, month: month) }
```

- [ ] **Step 4: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Domain: attendance status, session, draft and stats; the day's Phase 4 words"
```

### Task 2: Domain: the next class, "in 25 min", a class's days in a month (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/NextClass.swift`, `TimeUntil.swift`, `Occurrences.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/NextClassTests.swift`, `TimeUntilTests.swift`, `OccurrencesTests.swift`

**Interfaces:**
- Consumes: `Classroom`, `Weekday`, `TimeOfDay`, `Day`, `Period`.
- Produces:

```swift
public enum NextClass: Hashable, Sendable {
    case soon(Classroom, startsIn: Int)          // within 90 min of its start (design-tokens.md "Numbers in code"), minutes
    case running(Classroom, endsAt: TimeOfDay?)  // between start and end (or start and start+60 when no end)
    case laterToday(Classroom, at: TimeOfDay?)   // today, more than 90 min away, or today with no time set
    case tomorrow(Classroom)
    case onDay(Classroom, Day)                   // a later day this week or next
    public var classroom: Classroom
    public var eyebrow: String      // "Next class · in 25 min", "Now · until 18:00", "Next class · 17:00", "Next class · tomorrow", "No classes today"
    public var canMark: Bool        // soon or running
    public static func find(in classes: [Classroom], now: Date, calendar: Calendar) -> NextClass?   // nil: no class with meeting days
    public static func classesToday(in classes: [Classroom], on day: Day, calendar: Calendar) -> [Classroom]   // by start time, then name
}
public enum TimeUntil { public static func text(minutes: Int) -> String }   // "starts now" (≤ 0), "in 1 min", "in 25 min", "in 1 h", "in 2 h" (rounded to the nearest half hour as "in 1 h 30 min")
public enum Occurrences { public static func days(of classroom: Classroom, in month: Period, calendar: Calendar) -> [Day] }
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/NextClassTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct NextClassTests {
    static let calendar = DayHeading.india
    static let maths = Classroom(
        id: UUID(), name: "Class 10 Maths", subject: nil, monthlyFee: nil, meetingDays: [.monday, .wednesday, .friday],
        startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 0), archivedAt: nil
    )
    static let science = Classroom(
        id: UUID(), name: "Class 8 Science", subject: nil, monthlyFee: nil, meetingDays: [.tuesday, .thursday],
        startTime: TimeOfDay(hour: 16, minute: 30), endTime: TimeOfDay(hour: 17, minute: 30), archivedAt: nil
    )
    static func at(_ day: Int, _ hour: Int, _ minute: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }
    let classes = [maths, science]

    @Test func theNextClassAcrossTheDay() {
        // Wednesday 7 October 2026.
        #expect(NextClass.find(in: classes, now: Self.at(7, 16, 35), calendar: Self.calendar) == .soon(Self.maths, startsIn: 25))
        #expect(NextClass.find(in: classes, now: Self.at(7, 17, 30), calendar: Self.calendar) == .running(Self.maths, endsAt: TimeOfDay(hour: 18, minute: 0)))
        #expect(NextClass.find(in: classes, now: Self.at(7, 18, 1), calendar: Self.calendar) == .tomorrow(Self.science))
        #expect(NextClass.find(in: classes, now: Self.at(7, 9, 30), calendar: Self.calendar) == .laterToday(Self.maths, at: TimeOfDay(hour: 17, minute: 0)))
        #expect(NextClass.find(in: classes, now: Self.at(7, 15, 30), calendar: Self.calendar) == .soon(Self.maths, startsIn: 90), "90 min is the edge")
        #expect(NextClass.find(in: classes, now: Self.at(7, 15, 29), calendar: Self.calendar) == .laterToday(Self.maths, at: TimeOfDay(hour: 17, minute: 0)))
    }

    @Test func sundayNightLooksToMonday() {
        let sunday = Self.at(11, 23, 59)
        #expect(NextClass.find(in: classes, now: sunday, calendar: Self.calendar) == .tomorrow(Self.maths))
        let saturday = Self.at(10, 9, 30)
        #expect(NextClass.find(in: classes, now: saturday, calendar: Self.calendar) == .onDay(Self.maths, Day(year: 2026, month: 10, day: 12)!))
    }

    @Test func aClassWithoutATimeHasNoCountdown() {
        var loose = Self.maths
        loose.startTime = nil
        loose.endTime = nil
        #expect(NextClass.find(in: [loose], now: Self.at(7, 16, 35), calendar: Self.calendar) == .laterToday(loose, at: nil))
        #expect(NextClass.find(in: [loose], now: Self.at(7, 23, 0), calendar: Self.calendar) == .laterToday(loose, at: nil), "a timeless class is today's until midnight")
        var archived = Self.maths
        archived.archivedAt = Date()
        #expect(NextClass.find(in: [archived], now: Self.at(7, 16, 35), calendar: Self.calendar) == nil)
        #expect(NextClass.find(in: [], now: Self.at(7, 16, 35), calendar: Self.calendar) == nil)
    }

    @Test func theWordsOnTheHero() {
        #expect(NextClass.soon(Self.maths, startsIn: 25).eyebrow == "Next class · in 25 min")
        #expect(NextClass.running(Self.maths, endsAt: TimeOfDay(hour: 18, minute: 0)).eyebrow == "Now · until 18:00")
        #expect(NextClass.running(Self.maths, endsAt: nil).eyebrow == "Now")
        #expect(NextClass.laterToday(Self.maths, at: TimeOfDay(hour: 17, minute: 0)).eyebrow == "Next class · 17:00")
        #expect(NextClass.laterToday(Self.maths, at: nil).eyebrow == "Next class · today")
        #expect(NextClass.tomorrow(Self.science).eyebrow == "Next class · tomorrow")
        #expect(NextClass.onDay(Self.maths, Day(year: 2026, month: 10, day: 12)!).eyebrow == "No classes today")
        #expect(NextClass.soon(Self.maths, startsIn: 25).canMark && NextClass.running(Self.maths, endsAt: nil).canMark)
        #expect(!NextClass.tomorrow(Self.science).canMark && !NextClass.laterToday(Self.maths, at: nil).canMark)
    }

    @Test func todaysClassesByStartTime() {
        var evening = Self.science
        evening.meetingDays = [.wednesday]
        let today = Day(year: 2026, month: 10, day: 7)!
        let list = NextClass.classesToday(in: [Self.maths, evening], on: today, calendar: Self.calendar)
        #expect(list.map(\.name) == ["Class 8 Science", "Class 10 Maths"], "16:30 before 17:00")
        #expect(NextClass.classesToday(in: classes, on: Day(year: 2026, month: 10, day: 10)!, calendar: Self.calendar).isEmpty)
    }
}
```

`Tests/DomainTests/TimeUntilTests.swift`:

```swift
import Testing
@testable import Domain

struct TimeUntilTests {
    @Test func theRelativeWords() {
        #expect(TimeUntil.text(minutes: 0) == "starts now" && TimeUntil.text(minutes: -3) == "starts now")
        #expect(TimeUntil.text(minutes: 1) == "in 1 min" && TimeUntil.text(minutes: 25) == "in 25 min" && TimeUntil.text(minutes: 59) == "in 59 min")
        #expect(TimeUntil.text(minutes: 60) == "in 1 h" && TimeUntil.text(minutes: 90) == "in 1 h 30 min" && TimeUntil.text(minutes: 75) == "in 1 h 15 min")
        #expect(TimeUntil.text(minutes: 120) == "in 2 h")
    }
}
```

`Tests/DomainTests/OccurrencesTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct OccurrencesTests {
    @Test func aClassesDaysInOctober() {
        let days = Occurrences.days(of: NextClassTests.maths, in: Period(year: 2026, month: 10), calendar: DayHeading.india)
        #expect(days.map(\.day) == [2, 5, 7, 9, 12, 14, 16, 19, 21, 23, 26, 28, 30])
        var none = NextClassTests.maths
        none.meetingDays = []
        #expect(Occurrences.days(of: none, in: Period(year: 2026, month: 10), calendar: DayHeading.india).isEmpty)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `NextClass`, `TimeUntil`, `Occurrences` not found.

- [ ] **Step 3: Implement**

`Domain/NextClass.swift`:

```swift
import Foundation

/// The class Today puts first, from the meeting days and the clock (phase file item 6).
public enum NextClass: Hashable, Sendable {
    case soon(Classroom, startsIn: Int)
    case running(Classroom, endsAt: TimeOfDay?)
    case laterToday(Classroom, at: TimeOfDay?)
    case tomorrow(Classroom)
    case onDay(Classroom, Day)

    /// Minutes before a start within which the class is "soon" (design-tokens.md, "Numbers in code").
    public static let soonWindow = 90
    /// A class with a start but no end runs this long.
    public static let defaultLength = 60

    public var classroom: Classroom {
        switch self {
        case let .soon(c, _), let .running(c, _), let .laterToday(c, _), let .tomorrow(c), let .onDay(c, _): c
        }
    }

    public var canMark: Bool {
        switch self {
        case .soon, .running: true
        default: false
        }
    }

    public var eyebrow: String {
        switch self {
        case let .soon(_, minutes): "Next class · \(TimeUntil.text(minutes: minutes))"
        case let .running(_, end): end.map { "Now · until \($0.text)" } ?? "Now"
        case let .laterToday(_, at): "Next class · \(at?.text ?? "today")"
        case .tomorrow: "Next class · tomorrow"
        case .onDay: "No classes today"
        }
    }

    public static func find(in classes: [Classroom], now: Date, calendar: Calendar) -> NextClass? {
        let active = classes.filter { !$0.isArchived && !$0.meetingDays.isEmpty }
        guard !active.isEmpty else { return nil }
        let today = Day(now, calendar: calendar)
        let minute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        // Today's classes, those not yet over first.
        let todays = classesToday(in: active, on: today, calendar: calendar)
        for c in todays {
            guard let start = c.startTime else { return .laterToday(c, at: nil) }
            let startMinute = start.hour * 60 + start.minute
            let endMinute = c.endTime.map { $0.hour * 60 + $0.minute } ?? startMinute + defaultLength
            if minute >= endMinute { continue }
            if minute >= startMinute { return .running(c, endsAt: c.endTime) }
            let until = startMinute - minute
            return until <= soonWindow ? .soon(c, startsIn: until) : .laterToday(c, at: start)
        }
        // The next day with a class, within two weeks.
        for offset in 1 ... 14 {
            let day = today.adding(days: offset, calendar: calendar)
            if let c = classesToday(in: active, on: day, calendar: calendar).first {
                return offset == 1 ? .tomorrow(c) : .onDay(c, day)
            }
        }
        return nil
    }

    /// The classes meeting on `day`, by start time (a class without one last), then name.
    public static func classesToday(in classes: [Classroom], on day: Day, calendar: Calendar) -> [Classroom] {
        let weekday = day.weekday(in: calendar)
        return classes.filter { !$0.isArchived && $0.meetingDays.contains(weekday) }
            .sorted { a, b in
                switch (a.startTime, b.startTime) {
                case let (x?, y?) where x != y: x < y
                case (nil, _?): false
                case (_?, nil): true
                default: a.name < b.name
                }
            }
    }
}
```

`Domain/TimeUntil.swift`:

```swift
/// "in 25 min", "in 1 h 30 min", "starts now" (components.md, Relative).
public enum TimeUntil {
    public static func text(minutes: Int) -> String {
        if minutes <= 0 { return "starts now" }
        if minutes < 60 { return "in \(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "in \(hours) h" : "in \(hours) h \(rest) min"
    }
}
```

`Domain/Occurrences.swift`:

```swift
import Foundation

/// The days a class meets in a month (the schedule's dots; Phase 5's attendance export).
public enum Occurrences {
    public static func days(of classroom: Classroom, in month: Period, calendar: Calendar) -> [Day] {
        guard !classroom.meetingDays.isEmpty,
              let range = calendar.range(of: .day, in: .month, for: month.start(in: calendar.timeZone)) else { return [] }
        return range.compactMap { Day(year: month.year, month: month.month, day: $0) }
            .filter { classroom.meetingDays.contains($0.weekday(in: calendar)) }
    }
}
```

- [ ] **Step 4: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the next class from the meeting days and the clock, the relative words, a class's days in a month"
```

### Task 3: Domain: events and tasks (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/CalendarEvent.swift`, `EventDraft.swift`, `TaskItem.swift`, `TaskOrdering.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/EventTests.swift`, `TaskOrderingTests.swift`

**Interfaces:**
- Produces:

```swift
public struct CalendarEvent: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID; public var title: String; public var date: Day; public var startTime: TimeOfDay?; public var endTime: TimeOfDay?; public var note: String?
    public init(id:title:date:startTime:endTime:note:)
    public var timeRange: String?                 // "11:00–12:00", "11:00", nil
    public var line: String?                      // the note, else the time range (the schedule row's second line)
    public static func comingUp(_ events: [CalendarEvent], after today: Day, days: Int = 7, calendar: Calendar) -> [CalendarEvent]   // tomorrow … today+days, by date then start time
    public static func on(_ day: Day, in events: [CalendarEvent]) -> [CalendarEvent]
}
public struct EventDraft: Hashable, Sendable {
    public var title = "", date: Day, startTime: TimeOfDay?, endTime: TimeOfDay?, note = ""
    public init(date: Day); public init(_ event: CalendarEvent)
    public static let titleLimit = 120, noteLimit = 500
    public enum Problem: Hashable, Sendable { case titleMissing, titleTooLong, noteTooLong, endNotAfterStart; public var message: String }
    public var problems: Set<Problem>; public var isValid: Bool; public var trimmedTitle: String; public var trimmedNote: String?
}
public struct TaskItem: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID; public var title: String; public var dueDate: Day?; public var doneAt: Date?; public let createdAt: Date
    public init(id:title:dueDate:doneAt:createdAt:)
    public var isDone: Bool
    public static let titleLimit = 200
}
public enum TaskOrdering {
    public static func open(_ tasks: [TaskItem]) -> [TaskItem]           // not done: by due date (none last), then created
    public static func done(_ tasks: [TaskItem]) -> [TaskItem]           // done, newest done first
    public static func onToday(_ tasks: [TaskItem], now: Date) -> [TaskItem]   // open, plus done within 24 h (done ones last)
    public static func dueText(_ task: TaskItem, today: Day, calendar: Calendar) -> (text: String, overdue: Bool)?   // "Today", "Tomorrow", "Fri 9 Oct"; overdue when before today and not done; nil when no date or done
    public static func doneText(_ task: TaskItem, calendar: Calendar) -> String?   // "Tue 6 Oct"
    public static let stayOnToday: TimeInterval = 24 * 60 * 60
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DomainTests/EventTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct EventTests {
    static func event(_ title: String, _ day: Int, _ start: (Int, Int)? = (11, 0), end: (Int, Int)? = (12, 0), note: String? = nil) -> CalendarEvent {
        CalendarEvent(
            id: UUID(), title: title, date: Day(year: 2026, month: 10, day: day)!,
            startTime: start.flatMap { TimeOfDay(hour: $0.0, minute: $0.1) }, endTime: end.flatMap { TimeOfDay(hour: $0.0, minute: $0.1) }, note: note
        )
    }

    @Test func theRowsLine() {
        #expect(Self.event("Parents' meeting", 10).timeRange == "11:00–12:00")
        #expect(Self.event("Parents' meeting", 10, note: "Bring the papers.").line == "Bring the papers.")
        #expect(Self.event("Mock test", 17).line == "11:00–12:00")
        #expect(Self.event("Holiday", 20, nil, end: nil).line == nil && Self.event("Holiday", 20, nil, end: nil).timeRange == nil)
    }

    @Test func comingUpIsTheNextSevenDays() {
        let events = [Self.event("Later", 18), Self.event("Mock test", 17, (10, 0)), Self.event("Today's", 10), Self.event("Soon", 11, (9, 0)), Self.event("Also 11", 11, (8, 0))]
        let sunday = Day(year: 2026, month: 10, day: 11)!
        // Sunday 11: Monday 12 to Sunday 18 inclusive is seven days.
        #expect(CalendarEvent.comingUp(events, after: sunday, calendar: DayHeading.india).map(\.title) == ["Mock test", "Later"])
        let saturday = Day(year: 2026, month: 10, day: 10)!
        #expect(CalendarEvent.comingUp(events, after: saturday, calendar: DayHeading.india).map(\.title) == ["Also 11", "Soon", "Mock test"])
        #expect(CalendarEvent.on(saturday, in: events).map(\.title) == ["Today's"])
    }

    @Test func theDraftsRules() {
        var draft = EventDraft(date: Day(year: 2026, month: 10, day: 10)!)
        #expect(draft.problems == [.titleMissing] && EventDraft.Problem.titleMissing.message == "The event needs a title.")
        draft.title = " Parents' meeting "
        #expect(draft.isValid && draft.trimmedTitle == "Parents' meeting" && draft.trimmedNote == nil)
        draft.startTime = TimeOfDay(hour: 12, minute: 0)
        draft.endTime = TimeOfDay(hour: 11, minute: 0)
        #expect(draft.problems == [.endNotAfterStart] && EventDraft.Problem.endNotAfterStart.message == "The event has to end after it starts.")
        draft.endTime = nil
        draft.note = String(repeating: "n", count: 501)
        #expect(draft.problems == [.noteTooLong] && EventDraft.Problem.noteTooLong.message == "Keep the note under 500 characters.")
        draft.note = ""
        draft.title = String(repeating: "t", count: 121)
        #expect(draft.problems == [.titleTooLong] && EventDraft.Problem.titleTooLong.message == "Keep the title under 120 characters.")
        let back = EventDraft(Self.event("Mock test", 17, note: "Hall A"))
        #expect(back.title == "Mock test" && back.date.day == 17 && back.note == "Hall A" && back.startTime?.text == "11:00")
    }
}
```

`Tests/DomainTests/TaskOrderingTests.swift`:

```swift
import Foundation
import Testing
@testable import Domain

struct TaskOrderingTests {
    static let calendar = DayHeading.india
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }
    static func task(_ title: String, due: Int? = nil, doneAt: Date? = nil, created: Date = at(1, 9)) -> TaskItem {
        TaskItem(id: UUID(), title: title, dueDate: due.flatMap { Day(year: 2026, month: 10, day: $0) }, doneAt: doneAt, createdAt: created)
    }

    @Test func openByDueDateThenCreation() {
        let tasks = [Self.task("No date", created: Self.at(2, 9)), Self.task("Chalk", created: Self.at(1, 9)), Self.task("Call", due: 9), Self.task("Print", due: 8)]
        #expect(TaskOrdering.open(tasks).map(\.title) == ["Print", "Call", "Chalk", "No date"])
    }

    @Test func doneTasksStayADay() {
        let now = Self.at(8, 10)
        let justDone = Self.task("Workbooks", doneAt: Self.at(7, 23, 30))
        let oldDone = Self.task("Report", doneAt: Self.at(7, 9))
        let open = Self.task("Chalk")
        #expect(TaskOrdering.onToday([oldDone, justDone, open], now: now).map(\.title) == ["Chalk", "Workbooks"], "done at 23:30 stays past midnight; done 25 h ago is gone")
        #expect(TaskOrdering.done([oldDone, justDone]).map(\.title) == ["Workbooks", "Report"])
    }

    @Test func dueWordsAndOverdue() {
        let today = Day(year: 2026, month: 10, day: 7)!
        #expect(TaskOrdering.dueText(Self.task("A", due: 7), today: today, calendar: Self.calendar)! == (text: "Today", overdue: false))
        #expect(TaskOrdering.dueText(Self.task("B", due: 8), today: today, calendar: Self.calendar)! == (text: "Tomorrow", overdue: false))
        #expect(TaskOrdering.dueText(Self.task("C", due: 9), today: today, calendar: Self.calendar)! == (text: "Fri 9 Oct", overdue: false))
        #expect(TaskOrdering.dueText(Self.task("D", due: 5), today: today, calendar: Self.calendar)! == (text: "Mon 5 Oct", overdue: true))
        #expect(TaskOrdering.dueText(Self.task("E"), today: today, calendar: Self.calendar) == nil)
        #expect(TaskOrdering.dueText(Self.task("F", due: 5, doneAt: Self.at(6, 9)), today: today, calendar: Self.calendar) == nil, "done: the done day shows instead")
        #expect(TaskOrdering.doneText(Self.task("F", doneAt: Self.at(6, 9)), calendar: Self.calendar) == "Tue 6 Oct")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `CalendarEvent`, `EventDraft`, `TaskItem`, `TaskOrdering` not found.

- [ ] **Step 3: Implement**

`Domain/CalendarEvent.swift`:

```swift
import Foundation

/// A thing on the schedule that is not a class (`calendar_events`).
public struct CalendarEvent: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var date: Day
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var note: String?

    public init(id: UUID, title: String, date: Day, startTime: TimeOfDay?, endTime: TimeOfDay?, note: String?) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.note = note
    }

    public var timeRange: String? {
        switch (startTime, endTime) {
        case let (s?, e?): TimeOfDay.range(s, e)
        case let (s?, nil): s.text
        case let (nil, e?): e.text
        case (nil, nil): nil
        }
    }

    /// The row's second line: the note when there is one, else the time.
    public var line: String? { note ?? timeRange }

    /// Tomorrow to `today + days`, by date then start time (a timeless event first on its day).
    public static func comingUp(_ events: [CalendarEvent], after today: Day, days: Int = 7, calendar: Calendar) -> [CalendarEvent] {
        let last = today.adding(days: days, calendar: calendar)
        return events.filter { $0.date > today && $0.date <= last }.sorted(by: before)
    }

    public static func on(_ day: Day, in events: [CalendarEvent]) -> [CalendarEvent] {
        events.filter { $0.date == day }.sorted(by: before)
    }

    private static func before(_ a: CalendarEvent, _ b: CalendarEvent) -> Bool {
        if a.date != b.date { return a.date < b.date }
        switch (a.startTime, b.startTime) {
        case let (x?, y?) where x != y: return x < y
        case (nil, _?): return true
        case (_?, nil): return false
        default: return a.title < b.title
        }
    }
}
```

`Domain/EventDraft.swift`:

```swift
/// What the event form holds and checks (New event, Edit event).
public struct EventDraft: Hashable, Sendable {
    public var title = ""
    public var date: Day
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var note = ""

    public static let titleLimit = 120
    public static let noteLimit = 500

    public enum Problem: Hashable, Sendable {
        case titleMissing, titleTooLong, noteTooLong, endNotAfterStart

        public var message: String {
            switch self {
            case .titleMissing: "The event needs a title."
            case .titleTooLong: "Keep the title under 120 characters."
            case .noteTooLong: "Keep the note under 500 characters."
            case .endNotAfterStart: "The event has to end after it starts."
            }
        }
    }

    public init(date: Day) { self.date = date }

    public init(_ event: CalendarEvent) {
        title = event.title
        date = event.date
        startTime = event.startTime
        endTime = event.endTime
        note = event.note ?? ""
    }

    public var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var trimmedNote: String? {
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? nil : n
    }

    public var problems: Set<Problem> {
        var found = Set<Problem>()
        if trimmedTitle.isEmpty { found.insert(.titleMissing) }
        if trimmedTitle.count > Self.titleLimit { found.insert(.titleTooLong) }
        if (trimmedNote?.count ?? 0) > Self.noteLimit { found.insert(.noteTooLong) }
        if let startTime, let endTime, endTime <= startTime { found.insert(.endNotAfterStart) }
        return found
    }

    public var isValid: Bool { problems.isEmpty }
}
```

`Domain/TaskItem.swift`:

```swift
import Foundation

/// A thing to remember (`tasks`). Named `TaskItem` because Swift's `Task` is taken.
public struct TaskItem: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var dueDate: Day?
    public var doneAt: Date?
    public let createdAt: Date

    public static let titleLimit = 200

    public init(id: UUID, title: String, dueDate: Day?, doneAt: Date?, createdAt: Date) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.doneAt = doneAt
        self.createdAt = createdAt
    }

    public var isDone: Bool { doneAt != nil }
}
```

`Domain/TaskOrdering.swift`:

```swift
import Foundation

/// How tasks are listed (phase file item 6): open by due date, done tasks fall off Today after a day.
public enum TaskOrdering {
    public static let stayOnToday: TimeInterval = 24 * 60 * 60

    public static func open(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { !$0.isDone }.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (x?, y?) where x != y: x < y
            case (nil, _?): false
            case (_?, nil): true
            default: a.createdAt < b.createdAt
            }
        }
    }

    public static func done(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter(\.isDone).sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    public static func onToday(_ tasks: [TaskItem], now: Date) -> [TaskItem] {
        open(tasks) + done(tasks).filter { now.timeIntervalSince($0.doneAt ?? .distantPast) < stayOnToday }
    }

    public static func dueText(_ task: TaskItem, today: Day, calendar: Calendar) -> (text: String, overdue: Bool)? {
        guard let due = task.dueDate, !task.isDone else { return nil }
        if due == today { return ("Today", false) }
        if due == today.adding(days: 1, calendar: calendar) { return ("Tomorrow", false) }
        return (due.shortWeekdayText, due < today)
    }

    public static func doneText(_ task: TaskItem, calendar: Calendar) -> String? {
        task.doneAt.map { Day($0, calendar: calendar).shortWeekdayText }
    }
}
```

- [ ] **Step 4: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Domain: calendar events and their draft, tasks and their ordering"
```

### Task 4: Domain: the absence message and its WhatsApp link (PR 1)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/AbsenceMessage.swift`
- Test: `ios/TutorCentralKit/Tests/DomainTests/AbsenceMessageTests.swift`

**Interfaces:**
- Produces:

```swift
public enum AbsenceMessage {
    public static func text(parentName: String?, studentName: String, className: String?, day: Day, today: Day, tutorName: String?, centreName: String) -> String
    public static func whatsAppURL(phone: PhoneNumber, text: String) -> URL     // https://wa.me/<digits>?text=<encoded>
}
```

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Domain

struct AbsenceMessageTests {
    let day = Day(year: 2026, month: 10, day: 7)!

    @Test func theMessageAsTheBoardWritesIt() {
        let text = AbsenceMessage.text(
            parentName: "Lakshmi Reddy", studentName: "Hemanth Reddy", className: "Class 10 Maths", day: day, today: day,
            tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
        #expect(text == """
        Hello Lakshmi, Hemanth was absent from Class 10 Maths today, Wednesday 7 October. Please let me know if everything is all right.

        Meera Nair
        Bright Minds Tuition
        """)
    }

    @Test func withoutAParentNameAClassOrATutorName() {
        let past = Day(year: 2026, month: 10, day: 5)!
        let text = AbsenceMessage.text(parentName: nil, studentName: "Sahil Verma", className: nil, day: past, today: day, tutorName: nil, centreName: "Bright Minds Tuition")
        #expect(text == """
        Hello, Sahil was absent from class on Monday 5 October. Please let me know if everything is all right.

        Bright Minds Tuition
        """)
    }

    @Test func theLinkCarriesTheMessageEncoded() throws {
        let phone = try #require(PhoneNumber(e164: "+919380260871"))
        let url = AbsenceMessage.whatsAppURL(phone: phone, text: "Hello Lakshmi, Hemanth & co.")
        #expect(url.absoluteString == "https://wa.me/919380260871?text=Hello%20Lakshmi%2C%20Hemanth%20%26%20co.")
    }
}
```

- [ ] **Step 2: Run to see it fail**

Run: `bun check --only=ios`
Expected: FAIL, `AbsenceMessage` not found.

- [ ] **Step 3: Implement**

```swift
import Foundation

/// The parent-facing text behind "Tell parent" (P4-Absence-Alert; guidelines.md, Copy: plain and polite, names the
/// child) and the WhatsApp link that carries it (D3).
public enum AbsenceMessage {
    public static func text(
        parentName: String?, studentName: String, className: String?, day: Day, today: Day, tutorName: String?, centreName: String
    ) -> String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let what = className.map { "absent from \($0)" } ?? "absent from class"
        let when = day == today ? "today, \(day.weekdayLongText)" : "on \(day.weekdayLongText)"
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        return "\(greeting) \(child) was \(what) \(when). Please let me know if everything is all right.\n\n\(signature)"
    }

    public static func whatsAppURL(phone: PhoneNumber, text: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wa.me"
        components.path = "/\(phone.e164.dropFirst())"
        components.queryItems = [URLQueryItem(name: "text", value: text)]
        // URLComponents leaves "&" and "," alone in a query value; WhatsApp needs them escaped.
        components.percentEncodedQuery = "text=" + (text.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? "")
        return components.url!
    }
}
```

- [ ] **Step 4: Run, format, lint, commit; open PR 1**

Run: `bun check`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the absence message and its WhatsApp link"
git push -u origin phase-4/domain
gh pr create --title "Domain: attendance, the next class, events, tasks, the absence message" --body "..."
```

Merge when the check is green (no pictures: nothing on screen changes).

### Task 5: Migration 0004: `save_attendance`, proven (PR 2)

**Files:**
- Create: `supabase/migrations/20261010000004_save_attendance.sql`
- Modify: `supabase/tests/rls.test.ts` (four tests), `supabase/types.ts` (regenerated)

**Interfaces:**
- Produces: `save_attendance(p_centre uuid, p_class uuid, p_date date, p_marks jsonb) returns uuid`, `p_marks` a JSON object `{"<student id>": "present" | "absent", …}`; the session id. `p_class` null is the session for all students.

- [ ] **Step 1: Write the failing tests**

Add to `supabase/tests/rls.test.ts`, before the `delete_centre` test (which empties the centre):

```ts
test("save_attendance makes the session and replaces its marks", async () => {
  const s1 = await a.from("students").insert({ centre_id: centreA, name: "Mark One" }).select("id").single();
  const s2 = await a.from("students").insert({ centre_id: centreA, name: "Mark Two" }).select("id").single();
  const cls = await a.from("classes").insert({ centre_id: centreA, name: "Marked class" }).select("id").single();
  const first = await a.rpc("save_attendance", {
    p_centre: centreA, p_class: cls.data!.id, p_date: "2026-10-07",
    p_marks: { [s1.data!.id]: "present", [s2.data!.id]: "absent" },
  });
  expect(first.error).toBeNull();
  const marks = await a.from("attendance_marks").select("student_id, status").eq("session_id", first.data as string).order("status");
  expect(marks.data).toEqual([{ student_id: s2.data!.id, status: "absent" }, { student_id: s1.data!.id, status: "present" }]);
  // Saving again replaces: Two is now present and One is no longer in the class.
  const second = await a.rpc("save_attendance", { p_centre: centreA, p_class: cls.data!.id, p_date: "2026-10-07", p_marks: { [s2.data!.id]: "present" } });
  expect(second.data).toBe(first.data);
  const after = await a.from("attendance_marks").select("student_id, status").eq("session_id", first.data as string);
  expect(after.data).toEqual([{ student_id: s2.data!.id, status: "present" }]);
  const session = await a.from("attendance_sessions").select("saved_at, created_at").eq("id", first.data as string).single();
  expect(new Date(session.data!.saved_at).getTime()).toBeGreaterThan(new Date(session.data!.created_at).getTime());
});

test("save_attendance keeps all-students and a class apart on one day", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  const everyone = await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-07", p_marks: { [s.data!.id]: "absent" } });
  expect(everyone.error).toBeNull();
  const sessions = await a.from("attendance_sessions").select("class_id").eq("centre_id", centreA).eq("date", "2026-10-07");
  expect(sessions.data?.length).toBe(2);
  const again = await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-07", p_marks: {} });
  expect(again.data).toBe(everyone.data);
  expect((await a.from("attendance_marks").select("id").eq("session_id", everyone.data as string)).data).toEqual([]);
});

test("save_attendance refuses a non-member, another centre's student and a bad mark", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  expect((await b.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [s.data!.id]: "present" } })).error).not.toBeNull();
  const theirs = await b.from("students").select("id").eq("name", "B's student").single();
  expect((await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [theirs.data!.id]: "present" } })).error).not.toBeNull();
  expect((await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [s.data!.id]: "late" } })).error).not.toBeNull();
  expect((await a.from("attendance_sessions").select("id").eq("centre_id", centreA).eq("date", "2026-10-08")).data).toEqual([], "a refused save leaves no session");
});

test("an absence can be logged and read back by student and day", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  const log = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "absence" }).select("id, opened_at, channel").single();
  expect(log.error).toBeNull();
  expect(log.data!.channel).toBe("whatsapp_link");
  const read = await a.from("message_log").select("student_id, kind, opened_at").eq("centre_id", centreA).eq("kind", "absence").gte("opened_at", "2026-01-01");
  expect(read.data?.length).toBe(1);
});
```

- [ ] **Step 2: Run to see them fail**

Run: `cd supabase && bun test tests`
Expected: FAIL, `function public.save_attendance … does not exist`.

- [ ] **Step 3: Write the migration**

`supabase/migrations/20261010000004_save_attendance.sql`:

```sql
-- Save a class's attendance for a day (Phase 4): the session is made or found, its marks replaced by p_marks
-- ({"<student id>": "present" | "absent"}), saved_at moved. Two tables in one transaction, so a function; security
-- invoker, so RLS decides what the caller may touch (a student of another centre fails the composite foreign key).
-- p_class null is the session for all students; the unique index (nulls not distinct) keeps one per day.

create function public.save_attendance(p_centre uuid, p_class uuid, p_date date, p_marks jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_marks) <> 'object' then raise exception 'marks must be an object' using errcode = '22023'; end if;
  insert into public.attendance_sessions (centre_id, class_id, date)
  values (p_centre, p_class, p_date)
  on conflict (centre_id, class_id, date) do update set saved_at = now()
  returning id into sid;
  delete from public.attendance_marks m
  where m.session_id = sid and not (p_marks ? m.student_id::text);
  insert into public.attendance_marks (centre_id, session_id, student_id, status)
  select p_centre, sid, key::uuid, value::public.attendance_status
  from jsonb_each_text(p_marks)
  on conflict (session_id, student_id) do update set status = excluded.status;
  return sid;
end $$;

revoke all on function public.save_attendance(uuid, uuid, date, jsonb) from public, anon;
grant execute on function public.save_attendance(uuid, uuid, date, jsonb) to authenticated;
```

Then: `cd supabase && supabase db reset && supabase gen types typescript --local > types.ts`.

- [ ] **Step 4: Run the tests and the check, commit; open PR 2; deploy**

Run: `bun check --only=db` (the catalogue test probes the new function's grants).
Expected: green.

```bash
git add supabase
git commit -m "Migration 0004: save_attendance makes a session and replaces its marks in one transaction; the absence log read back"
git push -u origin phase-4/save-attendance
gh pr create --title "Migration 0004: save_attendance" --body "..."
```

After the merge: `gh workflow run deploy`, then watch the run; its summary shows 0004 pending then applied (D26). Record the run id in Task 20's state update.

### Task 6: Data: the attendance repository and the message log, the fakes, every answer decoded (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Attendance/AttendanceRepository.swift`, `SupabaseAttendanceRepository.swift`, `FakeAttendanceRepository.swift`, `SessionRow.swift`; `Data/Messages/MessageLogRepository.swift`, `SupabaseMessageLogRepository.swift`, `FakeMessageLogRepository.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/SessionRowTests.swift`, `FakeAttendanceRepositoryTests.swift`

**Interfaces:**
- Consumes: Task 1's types; `PostgRESTDecoder`; `FakeStudentsRepository.seed`, `FakeClassesRepository.seed`, `FakeCountsRepository.fixedNow`.
- Produces:

```swift
public protocol AttendanceRepository: Sendable {
    /// Every session of the month with its marks, newest first.
    func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession]
    /// `save_attendance`; returns the session as saved (id, savedAt from the server).
    func save(centre: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]) async throws -> AttendanceSession
}
public struct AbsenceLog: Hashable, Sendable, Codable { public let studentID: UUID; public let openedAt: Date }
public protocol MessageLogRepository: Sendable {
    func absences(centre: UUID, month: Period) async throws -> [AbsenceLog]
    func logAbsence(centre: UUID, studentID: UUID) async throws -> AbsenceLog
}
@MainActor public final class FakeAttendanceRepository: AttendanceRepository {
    public nonisolated static let seed: [AttendanceSession]           // the seed rule, 10 Sep to 6 Oct 2026
    public nonisolated static let seedWithToday: [AttendanceSession]  // + Wed 7 Oct Class 10 Maths at 18:04, Hemanth absent
    public nonisolated static let hemanth: UUID                       // FakeStudentsRepository's id for Hemanth Reddy (5)
    public var sessions: [AttendanceSession]; public var nextError: (any Error)?; public var delay: Duration?
    public private(set) var saves: [(classID: UUID?, date: Day, marks: [UUID: AttendanceStatus])]
    public init(sessions: [AttendanceSession] = [])
}
@MainActor public final class FakeMessageLogRepository: MessageLogRepository {
    public nonisolated static let seed: [AbsenceLog]   // Hemanth told on Mon 5 Oct 18:10
    public var logs: [AbsenceLog]; public var nextError: (any Error)?; public private(set) var logged: [UUID]
    public init(logs: [AbsenceLog] = [])
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/SessionRowTests.swift`. The fixture is what the local stack answers to
`GET /rest/v1/attendance_sessions?select=id,class_id,date,saved_at,attendance_marks(student_id,status)&centre_id=eq.<id>&date=gte.2026-10-01&date=lte.2026-10-31&order=date.desc` as the seed's tutor; the RPC fixture is what `POST /rest/v1/rpc/save_attendance` answers (a bare uuid string). Run both with curl before writing, paste the real text:

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct SessionRowTests {
    static let json = Data("""
    [{"id":"5b1c0c2e-2a62-4b4e-9f3f-7d2f1c3a0001","class_id":"33333333-3333-3333-3333-333333333331","date":"2026-10-05",
      "saved_at":"2026-10-05T12:34:56.123456+00:00",
      "attendance_marks":[{"student_id":"aaaaaaaa-0000-0000-0000-000000000001","status":"present"},
                          {"student_id":"aaaaaaaa-0000-0000-0000-000000000005","status":"absent"}]},
     {"id":"5b1c0c2e-2a62-4b4e-9f3f-7d2f1c3a0002","class_id":null,"date":"2026-10-02","saved_at":"2026-10-02T12:00:00+00:00",
      "attendance_marks":[]}]
    """.utf8)

    @Test func decodesSessionsWithTheirMarks() throws {
        let rows = try SupabaseAttendanceRepository.decoder.decode([SessionRow].self, from: Self.json)
        let sessions = rows.map(\.session)
        #expect(sessions[0].date == Day(year: 2026, month: 10, day: 5) && sessions[0].classID?.uuidString.lowercased() == "33333333-3333-3333-3333-333333333331")
        #expect(sessions[0].marks[UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000005")!] == .absent && sessions[0].presentCount == 1)
        #expect(sessions[1].classID == nil && sessions[1].marks.isEmpty)
    }

    @Test func theRpcAnswersABareUuid() throws {
        // What PostgREST returns for a function returning uuid: a JSON string.
        let data = Data("\"5b1c0c2e-2a62-4b4e-9f3f-7d2f1c3a0001\"".utf8)
        let id = try SupabaseAttendanceRepository.decoder.decode(UUID.self, from: data)
        #expect(id.uuidString.lowercased() == "5b1c0c2e-2a62-4b4e-9f3f-7d2f1c3a0001")
    }

    @Test func marksEncodeAsTheFunctionWants() throws {
        let hemanth = UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000005")!
        let json = SupabaseAttendanceRepository.marksJSON([hemanth: .absent])
        #expect(json == .object([hemanth.uuidString.lowercased(): .string("absent")]))
    }
}
```

`Tests/DataTests/FakeAttendanceRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeAttendanceRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func theSeedFollowsTheSeedRule() async throws {
        let repo = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let october = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.map(\.date.day) == [6, 5, 2, 1], "newest first; nothing on the 7th before a save")
        let fifth = try #require(october.first { $0.date.day == 5 })
        #expect(fifth.classID == FakeClassesRepository.maths.id && fifth.presentCount == 5 && fifth.absentStudentIDs == [FakeAttendanceRepository.hemanth])
        let september = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 9))
        #expect(september.count == 15)
        let withToday = try await FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday).sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(withToday.first?.date.day == 7 && withToday.first?.absentStudentIDs == [FakeAttendanceRepository.hemanth])
    }

    @Test func savingMakesOrReplacesASession() async throws {
        let repo = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let day = Day(year: 2026, month: 10, day: 7)!
        let akshita = FakeStudentsRepository.akshita
        let saved = try await repo.save(centre: centre, classID: FakeClassesRepository.maths.id, date: day, marks: [akshita: .absent])
        #expect(saved.date == day && saved.marks == [akshita: .absent] && repo.saves.count == 1)
        let again = try await repo.save(centre: centre, classID: FakeClassesRepository.maths.id, date: day, marks: [akshita: .present])
        #expect(again.id == saved.id && again.marks == [akshita: .present] && again.savedAt >= saved.savedAt)
        let october = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.filter { $0.date == day }.count == 1)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.save(centre: centre, classID: nil, date: day, marks: [:]) }
    }

    @Test func theMessageLogRemembersWhoWasTold() async throws {
        let log = FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)
        let october = try await log.absences(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.map(\.studentID) == [FakeAttendanceRepository.hemanth])
        let made = try await log.logAbsence(centre: centre, studentID: FakeStudentsRepository.akshita)
        #expect(made.studentID == FakeStudentsRepository.akshita && log.logged == [FakeStudentsRepository.akshita])
        #expect(try await log.absences(centre: centre, month: Period(year: 2026, month: 10)).count == 2)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `SessionRow`, `FakeAttendanceRepository` not found.

- [ ] **Step 3: Implement**

`Data/Attendance/AttendanceRepository.swift`:

```swift
import Domain
import Foundation

/// Saved attendance. RLS keeps every call inside the member's centre.
public protocol AttendanceRepository: Sendable {
    /// Every session of the month with its marks, newest first.
    func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession]
    /// `save_attendance` (migration 0004): the session is made or found and its marks replaced.
    func save(centre: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]) async throws -> AttendanceSession
}
```

`Data/Attendance/SessionRow.swift`:

```swift
import Domain
import Foundation

/// An `attendance_sessions` row with its marks embedded.
struct SessionRow: Decodable {
    struct Mark: Decodable {
        let studentId: UUID
        let status: String
    }

    let id: UUID
    let classId: UUID?
    let date: String
    let savedAt: Date
    let attendanceMarks: [Mark]

    var session: AttendanceSession {
        AttendanceSession(
            id: id, classID: classId, date: Day(iso: date) ?? Day(year: 1970, month: 1, day: 1)!, savedAt: savedAt,
            marks: Dictionary(uniqueKeysWithValues: attendanceMarks.compactMap { mark in
                AttendanceStatus(rawValue: mark.status).map { (mark.studentId, $0) }
            })
        )
    }
}
```

`Data/Attendance/SupabaseAttendanceRepository.swift`:

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseAttendanceRepository: AttendanceRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, class_id, date, saved_at, attendance_marks(student_id, status)"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession] {
        let response = try await client.from("attendance_sessions")
            .select(Self.columns)
            .eq("centre_id", value: centre)
            .gte("date", value: month.isoDay)
            .lte("date", value: month.next.previousDayISO)
            .order("date", ascending: false)
            .execute()
        return try Self.decoder.decode([SessionRow].self, from: response.data).map(\.session)
    }

    public func save(centre: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]) async throws -> AttendanceSession {
        let response = try await client.rpc("save_attendance", params: [
            "p_centre": AnyJSON.string(centre.uuidString),
            "p_class": classID.map { .string($0.uuidString) } ?? .null,
            "p_date": .string(date.iso),
            "p_marks": Self.marksJSON(marks),
        ]).execute()
        let id = try Self.decoder.decode(UUID.self, from: response.data)
        // The row as saved: its saved_at is the server's clock.
        let row = try await client.from("attendance_sessions").select(Self.columns).eq("id", value: id).single().execute()
        return try Self.decoder.decode(SessionRow.self, from: row.data).session
    }

    static func marksJSON(_ marks: [UUID: AttendanceStatus]) -> AnyJSON {
        .object(Dictionary(uniqueKeysWithValues: marks.map { ($0.key.uuidString.lowercased(), AnyJSON.string($0.value.rawValue)) }))
    }
}
```

`Period` gains in Domain (same PR, test in `PeriodTests`: `previousDayISO` of November 2026 is `"2026-10-31"`):

```swift
    /// The ISO day before this month starts: the last day of the previous month.
    public var previousDayISO: String {
        let utc = TimeZone(identifier: "UTC")!
        let last = Self.calendar(utc).date(byAdding: .day, value: -1, to: start(in: utc))!
        return Day(last, calendar: Self.calendar(utc)).iso
    }
```

`Data/Attendance/FakeAttendanceRepository.swift`:

```swift
import Domain
import Foundation

/// The in-memory attendance for tests, previews and `bun shots`: `seed.sql`'s rule (the four weeks before Wednesday
/// 7 October 2026 on each class's meeting days, every fifth mark absent ordered by date and name), a scripted error,
/// a delay, a record of every save.
@MainActor public final class FakeAttendanceRepository: AttendanceRepository {
    public nonisolated static let hemanth = FakeStudentsRepository.seed[4].id

    public nonisolated static let seed: [AttendanceSession] = {
        let calendar = DayHeading.india
        let today = Day(year: 2026, month: 10, day: 7)!
        var rows: [(day: Day, student: Student, classroom: Classroom)] = []
        for offset in (1 ... 27).reversed() {
            let day = today.adding(days: -offset, calendar: calendar)
            for classroom in FakeClassesRepository.seed where classroom.meetingDays.contains(day.weekday(in: calendar)) {
                for student in FakeStudentsRepository.seed where student.classID == classroom.id {
                    rows.append((day, student, classroom))
                }
            }
        }
        rows.sort { ($0.day, $0.student.name) < ($1.day, $1.student.name) }
        var sessions: [Day: [UUID: AttendanceSession]] = [:]
        for (index, row) in rows.enumerated() {
            let status: AttendanceStatus = (index + 1) % 5 == 0 ? .absent : .present
            var session = sessions[row.day]?[row.classroom.id] ?? AttendanceSession(
                id: sessionID(row.day, row.classroom), classID: row.classroom.id, date: row.day,
                savedAt: calendar.date(from: DateComponents(year: row.day.year, month: row.day.month, day: row.day.day, hour: 18, minute: 4))!,
                marks: [:]
            )
            session.marks[row.student.id] = status
            sessions[row.day, default: [:]][row.classroom.id] = session
        }
        return sessions.values.flatMap(\.values).sorted { $0.date > $1.date }
    }()

    /// The states after a save: Wednesday 7 October's Class 10 Maths at 18:04, Hemanth absent.
    public nonisolated static let seedWithToday: [AttendanceSession] = {
        let today = Day(year: 2026, month: 10, day: 7)!
        let maths = FakeClassesRepository.maths
        let marks = Dictionary(uniqueKeysWithValues: FakeStudentsRepository.seed.filter { $0.classID == maths.id }
            .map { ($0.id, $0.id == hemanth ? AttendanceStatus.absent : .present) })
        let saved = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18, minute: 4))!
        return [AttendanceSession(id: sessionID(today, maths), classID: maths.id, date: today, savedAt: saved, marks: marks)] + seed
    }()

    public var sessions: [AttendanceSession]
    public var nextError: (any Error)?
    public var delay: Duration?
    public private(set) var saves: [(classID: UUID?, date: Day, marks: [UUID: AttendanceStatus])] = []
    private let now: () -> Date

    public init(sessions: [AttendanceSession] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.sessions = sessions
        self.now = now
    }

    public func sessions(centre _: UUID, month: Period) async throws -> [AttendanceSession] {
        try await begin()
        return AttendanceStats.sessions(sessions, in: month).sorted { $0.date > $1.date }
    }

    public func save(centre _: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]) async throws -> AttendanceSession {
        try await begin()
        saves.append((classID, date, marks))
        if let index = sessions.firstIndex(where: { $0.date == date && $0.classID == classID }) {
            sessions[index].marks = marks
            sessions[index].savedAt = now()
            return sessions[index]
        }
        let made = AttendanceSession(id: UUID(), classID: classID, date: date, savedAt: now(), marks: marks)
        sessions.append(made)
        return made
    }

    private func begin() async throws {
        if let delay { try? await Task.sleep(for: delay) }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }

    /// A fixed id per class and day, so the fixtures and the boards agree across launches.
    private nonisolated static func sessionID(_ day: Day, _ classroom: Classroom) -> UUID {
        UUID(uuidString: String(format: "bbbbbbbb-%04d-%02d%02d-0000-%012d", day.year, day.month, day.day, classroom.id.uuidString.last.map { Int(String($0)) ?? 0 } ?? 0))!
    }
}
```

`Data/Messages/MessageLogRepository.swift`, `SupabaseMessageLogRepository.swift`, `FakeMessageLogRepository.swift`:

```swift
import Domain
import Foundation

/// One opened WhatsApp link (`message_log`, D3): who it was about and when.
public struct AbsenceLog: Hashable, Sendable, Codable {
    public let studentID: UUID
    public let openedAt: Date

    public init(studentID: UUID, openedAt: Date) {
        self.studentID = studentID
        self.openedAt = openedAt
    }
}

public protocol MessageLogRepository: Sendable {
    /// The absence alerts opened in the month, newest first.
    func absences(centre: UUID, month: Period) async throws -> [AbsenceLog]
    func logAbsence(centre: UUID, studentID: UUID) async throws -> AbsenceLog
}
```

```swift
import Domain
import Foundation
import Supabase

public final class SupabaseMessageLogRepository: MessageLogRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func absences(centre: UUID, month: Period) async throws -> [AbsenceLog] {
        let timeZone = DayHeading.india.timeZone
        let response = try await client.from("message_log")
            .select("student_id, opened_at")
            .eq("centre_id", value: centre)
            .eq("kind", value: "absence")
            .gte("opened_at", value: ISO8601DateFormatter().string(from: month.start(in: timeZone)))
            .lt("opened_at", value: ISO8601DateFormatter().string(from: month.next.start(in: timeZone)))
            .order("opened_at", ascending: false)
            .execute()
        return try Self.decoder.decode([LogRow].self, from: response.data).map(\.log)
    }

    public func logAbsence(centre: UUID, studentID: UUID) async throws -> AbsenceLog {
        let response = try await client.from("message_log")
            .insert(["centre_id": AnyJSON.string(centre.uuidString), "student_id": .string(studentID.uuidString), "kind": .string("absence")])
            .select("student_id, opened_at").single().execute()
        return try Self.decoder.decode(LogRow.self, from: response.data).log
    }
}

/// A `message_log` row: `student_id` is nullable (a deleted student's log stays), so a row without one is skipped
/// by the caller through `log` being nil-free here only when the id is present.
struct LogRow: Decodable {
    let studentId: UUID?
    let openedAt: Date

    var log: AbsenceLog {
        AbsenceLog(studentID: studentId ?? UUID(uuid: UUID_NULL), openedAt: openedAt)
    }
}
```

Add to `SessionRowTests` a test `aLogRowDecodes` with the real insert answer (`{"student_id":"…","opened_at":"2026-10-07T12:33:10.5+00:00"}`) and the read answer (an array, one row with `"student_id":null`), and make `absences` drop null-student rows (`filter { $0.studentId != nil }` before mapping; then `LogRow.log` can take a non-optional id: make `log` return `AbsenceLog?` and `compactMap` it).

```swift
import Domain
import Foundation

@MainActor public final class FakeMessageLogRepository: MessageLogRepository {
    /// Hemanth's parent told on Monday 5 October at 18:10 (P4-Attendance-Mark-PastDate, P4-History-Student).
    public nonisolated static let seed = [
        AbsenceLog(
            studentID: FakeAttendanceRepository.hemanth,
            openedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 18, minute: 10))!
        ),
    ]

    public var logs: [AbsenceLog]
    public var nextError: (any Error)?
    public private(set) var logged: [UUID] = []
    private let now: () -> Date

    public init(logs: [AbsenceLog] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.logs = logs
        self.now = now
    }

    public func absences(centre _: UUID, month: Period) async throws -> [AbsenceLog] {
        try takeError()
        return logs.filter { Day($0.openedAt, calendar: DayHeading.india).period == month }.sorted { $0.openedAt > $1.openedAt }
    }

    public func logAbsence(centre _: UUID, studentID: UUID) async throws -> AbsenceLog {
        try takeError()
        logged.append(studentID)
        let made = AbsenceLog(studentID: studentID, openedAt: now())
        logs.append(made)
        return made
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
```

- [ ] **Step 4: Prove the write path against the local stack in Swift**

With the local stack up and reset, a throwaway test in `DataTests` (not committed): make a `SupabaseClient` from `supabase status -o env` with an in-memory session storage, sign in as `meera@example.com` / `tutor-local-1`, read `sessions(centre:month:)` for October 2026 and `#expect` four sessions, `save(…)` Class 10 Maths for 2026-10-07 with Hemanth absent and `#expect` the answer's marks, save again with everyone present and `#expect` the same id, `logAbsence` and `absences` back. Delete the test; `supabase db reset`.

- [ ] **Step 5: Run, format, lint, commit**

Run: `bun check --only=format,lint,ios`
Expected: green.

```bash
git add ios/TutorCentralKit
git commit -m "Data: the attendance repository and the message log, Supabase and fakes seeded by the seed's rule, every answer decoded"
```

### Task 7: Data: the events repository (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Events/EventsRepository.swift`, `SupabaseEventsRepository.swift`, `FakeEventsRepository.swift`, `EventRow.swift`
- Test: `ios/TutorCentralKit/Tests/DataTests/EventRowTests.swift`, `FakeEventsRepositoryTests.swift`

**Interfaces:**

```swift
public protocol EventsRepository: Sendable {
    /// Events from `from` to `to` inclusive, by date then start time.
    func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent]
    func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent
    func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent
    func delete(id: UUID) async throws
}
@MainActor public final class FakeEventsRepository: EventsRepository {
    public nonisolated static let parentsMeeting: CalendarEvent   // Sat 10 Oct 11:00–12:00, note "Class 10 parents. Bring the September test papers."
    public nonisolated static let mockTest: CalendarEvent         // Sat 17 Oct 10:00–12:00, no note
    public nonisolated static let seed: [CalendarEvent]
    public var events: [CalendarEvent]; public var nextError: (any Error)?; public var delay: Duration?
    public private(set) var created: [EventDraft], updated: [UUID], deleted: [UUID]
    public init(events: [CalendarEvent] = [])
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/EventRowTests.swift` (the fixture from `GET /rest/v1/calendar_events?select=id,title,date,start_time,end_time,note&centre_id=eq.<id>&date=gte.2026-10-01&date=lte.2026-10-31&order=date,start_time` after inserting the two events with curl; paste the real answer):

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct EventRowTests {
    static let json = Data("""
    [{"id":"6c2d1d3f-3b73-4c5f-8a4a-8e3a2d4b0001","title":"Parents' meeting","date":"2026-10-10","start_time":"11:00:00","end_time":"12:00:00",
      "note":"Class 10 parents. Bring the September test papers."},
     {"id":"6c2d1d3f-3b73-4c5f-8a4a-8e3a2d4b0002","title":"Mock test, Class 10","date":"2026-10-17","start_time":"10:00:00","end_time":"12:00:00","note":null},
     {"id":"6c2d1d3f-3b73-4c5f-8a4a-8e3a2d4b0003","title":"Holiday","date":"2026-10-20","start_time":null,"end_time":null,"note":null}]
    """.utf8)

    @Test func decodesEvents() throws {
        let events = try SupabaseEventsRepository.decoder.decode([EventRow].self, from: Self.json).map(\.event)
        #expect(events[0].title == "Parents' meeting" && events[0].date == Day(year: 2026, month: 10, day: 10) && events[0].timeRange == "11:00–12:00")
        #expect(events[1].note == nil && events[2].startTime == nil && events[2].line == nil)
    }

    @Test func aDateDecodesAsADayNotAMoment() throws {
        // A date column is a day in India whatever the device's zone: no Date, no midnight shift.
        let events = try SupabaseEventsRepository.decoder.decode([EventRow].self, from: Self.json).map(\.event)
        #expect(events[0].date.iso == "2026-10-10")
    }

    @Test func theDraftWritesEveryColumn() {
        var draft = EventDraft(date: Day(year: 2026, month: 10, day: 10)!)
        draft.title = " Parents' meeting "
        draft.startTime = TimeOfDay(hour: 11, minute: 0)
        let values = SupabaseEventsRepository.values(draft)
        #expect(values["title"] == .string("Parents' meeting") && values["date"] == .string("2026-10-10"))
        #expect(values["start_time"] == .string("11:00") && values["end_time"] == .null && values["note"] == .null)
    }
}
```

`Tests/DataTests/FakeEventsRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeEventsRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func readsWritesAndDeletes() async throws {
        let repo = FakeEventsRepository(events: FakeEventsRepository.seed)
        let october = try await repo.events(centre: centre, from: Day(year: 2026, month: 10, day: 1)!, to: Day(year: 2026, month: 10, day: 31)!)
        #expect(october.map(\.title) == ["Parents' meeting", "Mock test, Class 10"])
        var draft = EventDraft(date: Day(year: 2026, month: 10, day: 20)!)
        draft.title = "Holiday"
        let made = try await repo.create(draft, centre: centre)
        #expect(made.title == "Holiday" && repo.created.count == 1)
        draft.title = "Diwali holiday"
        let changed = try await repo.update(id: made.id, with: draft)
        #expect(changed.title == "Diwali holiday" && changed.id == made.id)
        try await repo.delete(id: made.id)
        #expect(repo.deleted == [made.id] && repo.events.count == 2)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.delete(id: FakeEventsRepository.mockTest.id) }
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `EventRow`, `FakeEventsRepository` not found.

- [ ] **Step 3: Implement**

```swift
// Data/Events/EventsRepository.swift
import Domain
import Foundation

public protocol EventsRepository: Sendable {
    func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent]
    func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent
    func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent
    func delete(id: UUID) async throws
}

// Data/Events/EventRow.swift
import Domain
import Foundation

struct EventRow: Decodable {
    let id: UUID
    let title: String
    let date: String
    let startTime: String?
    let endTime: String?
    let note: String?

    var event: CalendarEvent {
        CalendarEvent(
            id: id, title: title, date: Day(iso: date) ?? Day(year: 1970, month: 1, day: 1)!,
            startTime: startTime.flatMap(TimeOfDay.init(iso:)), endTime: endTime.flatMap(TimeOfDay.init(iso:)), note: note
        )
    }
}

// Data/Events/SupabaseEventsRepository.swift
import Domain
import Foundation
import Supabase

public final class SupabaseEventsRepository: EventsRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, title, date, start_time, end_time, note"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent] {
        let response = try await client.from("calendar_events").select(Self.columns)
            .eq("centre_id", value: centre).gte("date", value: from.iso).lte("date", value: to.iso)
            .order("date").order("start_time", nullsFirst: true).execute()
        return try Self.decoder.decode([EventRow].self, from: response.data).map(\.event)
    }

    public func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("calendar_events").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(EventRow.self, from: response.data).event
    }

    public func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent {
        let response = try await client.from("calendar_events").update(Self.values(draft)).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(EventRow.self, from: response.data).event
    }

    public func delete(id: UUID) async throws {
        try await client.from("calendar_events").delete().eq("id", value: id).execute()
    }

    static func values(_ draft: EventDraft) -> [String: AnyJSON] {
        [
            "title": .string(draft.trimmedTitle),
            "date": .string(draft.date.iso),
            "start_time": draft.startTime.map { .string($0.iso) } ?? .null,
            "end_time": draft.endTime.map { .string($0.iso) } ?? .null,
            "note": draft.trimmedNote.map(AnyJSON.string) ?? .null,
        ]
    }
}

// Data/Events/FakeEventsRepository.swift
import Domain
import Foundation

@MainActor public final class FakeEventsRepository: EventsRepository {
    public nonisolated static let parentsMeeting = CalendarEvent(
        id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000001")!, title: "Parents' meeting",
        date: Day(year: 2026, month: 10, day: 10)!, startTime: TimeOfDay(hour: 11, minute: 0), endTime: TimeOfDay(hour: 12, minute: 0),
        note: "Class 10 parents. Bring the September test papers."
    )
    public nonisolated static let mockTest = CalendarEvent(
        id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000002")!, title: "Mock test, Class 10",
        date: Day(year: 2026, month: 10, day: 17)!, startTime: TimeOfDay(hour: 10, minute: 0), endTime: TimeOfDay(hour: 12, minute: 0), note: nil
    )
    public nonisolated static let seed = [parentsMeeting, mockTest]

    public var events: [CalendarEvent]
    public var nextError: (any Error)?
    public var delay: Duration?
    public private(set) var created: [EventDraft] = []
    public private(set) var updated: [UUID] = []
    public private(set) var deleted: [UUID] = []

    public init(events: [CalendarEvent] = []) {
        self.events = events
    }

    public func events(centre _: UUID, from: Day, to: Day) async throws -> [CalendarEvent] {
        try await begin()
        return events.filter { $0.date >= from && $0.date <= to }.sorted { a, b in
            a.date != b.date ? a.date < b.date : (a.startTime ?? TimeOfDay(hour: 0, minute: 0)!) < (b.startTime ?? TimeOfDay(hour: 0, minute: 0)!)
        }
    }

    public func create(_ draft: EventDraft, centre _: UUID) async throws -> CalendarEvent {
        try await begin()
        created.append(draft)
        let made = CalendarEvent(id: UUID(), title: draft.trimmedTitle, date: draft.date, startTime: draft.startTime, endTime: draft.endTime, note: draft.trimmedNote)
        events.append(made)
        return made
    }

    public func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent {
        try await begin()
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        updated.append(id)
        events[index] = CalendarEvent(id: id, title: draft.trimmedTitle, date: draft.date, startTime: draft.startTime, endTime: draft.endTime, note: draft.trimmedNote)
        return events[index]
    }

    public func delete(id: UUID) async throws {
        try await begin()
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        deleted.append(id)
        events.remove(at: index)
    }

    private func begin() async throws {
        if let delay { try? await Task.sleep(for: delay) }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
```

- [ ] **Step 4: Prove the write path against the local stack in Swift** (as Task 6 step 4: create, read, update, delete an event as the seed's tutor; delete the test).

- [ ] **Step 5: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios/TutorCentralKit
git commit -m "Data: the events repository, Supabase and fake, the answer decoded"
```

### Task 8: Data: the tasks repository; `Dependencies` (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/Tasks/TasksRepository.swift`, `SupabaseTasksRepository.swift`, `FakeTasksRepository.swift`, `TaskRow.swift`
- Modify: `ios/TutorCentralKit/Sources/AppShell/Dependencies.swift` (four repositories), `Fixtures.swift` (the fakes, seeded), `RootView.swift` (`live()` only through `Dependencies.live`)
- Test: `ios/TutorCentralKit/Tests/DataTests/TaskRowTests.swift`, `FakeTasksRepositoryTests.swift`; `Tests/AppShellTests/LaunchStateTests.swift` keeps passing (every state has a fixture)

**Interfaces:**

```swift
public protocol TasksRepository: Sendable {
    /// Every task, open and done.
    func tasks(centre: UUID) async throws -> [TaskItem]
    func create(title: String, dueDate: Day?, centre: UUID) async throws -> TaskItem
    func setDone(id: UUID, _ done: Bool) async throws -> TaskItem
    /// Deletes the done ones; returns how many.
    func clearDone(centre: UUID) async throws -> Int
}
@MainActor public final class FakeTasksRepository: TasksRepository {
    public nonisolated static let seed: [TaskItem]   // "Call Dev's father about Saturday" due Fri 9 Oct, "Buy chalk and dusters", done: "Order Class 8 workbooks" (Tue 6 Oct 10:00), "Send September report to parents" (Thu 1 Oct 19:00)
    public var tasks: [TaskItem]; public var nextError: (any Error)?; public var delay: Duration?
    public private(set) var created: [(String, Day?)], doneCalls: [(UUID, Bool)], cleared: Int
    public init(tasks: [TaskItem] = [])
}
// Dependencies gains: attendance: any AttendanceRepository, messages: any MessageLogRepository, events: any EventsRepository, tasks: any TasksRepository
```

- [ ] **Step 1: Write the failing tests**

`Tests/DataTests/TaskRowTests.swift` (the fixture from `GET /rest/v1/tasks?select=id,title,due_date,done_at,created_at&centre_id=eq.<id>&order=created_at`; paste the real answer):

```swift
import Domain
import Foundation
import Testing
@testable import Data

struct TaskRowTests {
    static let json = Data("""
    [{"id":"7d3e2e4a-4c84-4d6a-9b5b-9f4b3e5c0001","title":"Buy chalk and dusters","due_date":null,"done_at":null,"created_at":"2026-10-08T06:12:03.482611+00:00"},
     {"id":"7d3e2e4a-4c84-4d6a-9b5b-9f4b3e5c0002","title":"Call Dev's father about Saturday","due_date":"2026-10-10","done_at":"2026-10-08T07:00:00+00:00","created_at":"2026-10-08T06:12:03.482611+00:00"}]
    """.utf8)

    @Test func decodesTasks() throws {
        let tasks = try SupabaseTasksRepository.decoder.decode([TaskRow].self, from: Self.json).map(\.task)
        #expect(tasks[0].title == "Buy chalk and dusters" && tasks[0].dueDate == nil && !tasks[0].isDone)
        #expect(tasks[1].dueDate == Day(year: 2026, month: 10, day: 10) && tasks[1].isDone)
    }

    @Test func aDoneAnswerWithoutCreatedAtStillDecodes() throws {
        // An update selects the same columns; this guards the select list against a narrower one.
        let json = Data("""
        {"id":"7d3e2e4a-4c84-4d6a-9b5b-9f4b3e5c0001","title":"Buy chalk and dusters","due_date":null,"done_at":"2026-10-08T07:00:00+00:00","created_at":"2026-10-08T06:12:03+00:00"}
        """.utf8)
        #expect(try SupabaseTasksRepository.decoder.decode(TaskRow.self, from: json).task.isDone)
    }
}
```

`Tests/DataTests/FakeTasksRepositoryTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeTasksRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func theSeedAndTheWrites() async throws {
        let repo = FakeTasksRepository(tasks: FakeTasksRepository.seed)
        let all = try await repo.tasks(centre: centre)
        #expect(all.count == 4 && all.filter(\.isDone).count == 2)
        let made = try await repo.create(title: "Print worksheets for Class 8", dueDate: Day(year: 2026, month: 10, day: 9), centre: centre)
        #expect(made.title == "Print worksheets for Class 8" && made.dueDate?.day == 9 && !made.isDone)
        let done = try await repo.setDone(id: made.id, true)
        #expect(done.isDone && repo.doneCalls.count == 1)
        let undone = try await repo.setDone(id: made.id, false)
        #expect(!undone.isDone)
        #expect(try await repo.clearDone(centre: centre) == 2)
        #expect(try await repo.tasks(centre: centre).count == 3 && repo.cleared == 1)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `TaskRow`, `FakeTasksRepository` not found.

- [ ] **Step 3: Implement**

```swift
// Data/Tasks/TasksRepository.swift
import Domain
import Foundation

public protocol TasksRepository: Sendable {
    func tasks(centre: UUID) async throws -> [TaskItem]
    func create(title: String, dueDate: Day?, centre: UUID) async throws -> TaskItem
    func setDone(id: UUID, _ done: Bool) async throws -> TaskItem
    func clearDone(centre: UUID) async throws -> Int
}

// Data/Tasks/TaskRow.swift
import Domain
import Foundation

struct TaskRow: Decodable {
    let id: UUID
    let title: String
    let dueDate: String?
    let doneAt: Date?
    let createdAt: Date

    var task: TaskItem {
        TaskItem(id: id, title: title, dueDate: dueDate.flatMap(Day.init(iso:)), doneAt: doneAt, createdAt: createdAt)
    }
}

// Data/Tasks/SupabaseTasksRepository.swift
import Domain
import Foundation
import Supabase

public final class SupabaseTasksRepository: TasksRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, title, due_date, done_at, created_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func tasks(centre: UUID) async throws -> [TaskItem] {
        let response = try await client.from("tasks").select(Self.columns).eq("centre_id", value: centre).order("created_at").execute()
        return try Self.decoder.decode([TaskRow].self, from: response.data).map(\.task)
    }

    public func create(title: String, dueDate: Day?, centre: UUID) async throws -> TaskItem {
        let values: [String: AnyJSON] = [
            "centre_id": .string(centre.uuidString), "title": .string(title),
            "due_date": dueDate.map { .string($0.iso) } ?? .null,
        ]
        let response = try await client.from("tasks").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(TaskRow.self, from: response.data).task
    }

    public func setDone(id: UUID, _ done: Bool) async throws -> TaskItem {
        let value: AnyJSON = done ? .string(ISO8601DateFormatter().string(from: Date())) : .null
        let response = try await client.from("tasks").update(["done_at": value]).eq("id", value: id).select(Self.columns).single().execute()
        return try Self.decoder.decode(TaskRow.self, from: response.data).task
    }

    public func clearDone(centre: UUID) async throws -> Int {
        let response = try await client.from("tasks").delete().eq("centre_id", value: centre).not("done_at", operator: .is, value: "null")
            .select("id").execute()
        return try Self.decoder.decode([IDRow].self, from: response.data).count
    }
}

private struct IDRow: Decodable {
    let id: UUID
}

// Data/Tasks/FakeTasksRepository.swift
import Domain
import Foundation

@MainActor public final class FakeTasksRepository: TasksRepository {
    public nonisolated static let seed: [TaskItem] = {
        let calendar = DayHeading.india
        func at(_ day: Int, _ hour: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))! }
        func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "dddddddd-0000-0000-0000-%012d", n))! }
        return [
            TaskItem(id: id(1), title: "Call Dev's father about Saturday", dueDate: Day(year: 2026, month: 10, day: 9), doneAt: nil, createdAt: at(5, 9)),
            TaskItem(id: id(2), title: "Buy chalk and dusters", dueDate: nil, doneAt: nil, createdAt: at(5, 10)),
            TaskItem(id: id(3), title: "Order Class 8 workbooks", dueDate: Day(year: 2026, month: 10, day: 6), doneAt: at(6, 10), createdAt: at(1, 9)),
            TaskItem(id: id(4), title: "Send September report to parents", dueDate: Day(year: 2026, month: 10, day: 1), doneAt: at(1, 19), createdAt: at(1, 8)),
        ]
    }()

    public var tasks: [TaskItem]
    public var nextError: (any Error)?
    public var delay: Duration?
    public private(set) var created: [(String, Day?)] = []
    public private(set) var doneCalls: [(UUID, Bool)] = []
    public private(set) var cleared = 0
    private let now: () -> Date

    public init(tasks: [TaskItem] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.tasks = tasks
        self.now = now
    }

    public func tasks(centre _: UUID) async throws -> [TaskItem] {
        try await begin()
        return tasks
    }

    public func create(title: String, dueDate: Day?, centre _: UUID) async throws -> TaskItem {
        try await begin()
        created.append((title, dueDate))
        let made = TaskItem(id: UUID(), title: title, dueDate: dueDate, doneAt: nil, createdAt: now())
        tasks.append(made)
        return made
    }

    public func setDone(id: UUID, _ done: Bool) async throws -> TaskItem {
        try await begin()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        doneCalls.append((id, done))
        tasks[index].doneAt = done ? now() : nil
        return tasks[index]
    }

    public func clearDone(centre _: UUID) async throws -> Int {
        try await begin()
        cleared += 1
        let count = tasks.filter(\.isDone).count
        tasks.removeAll(where: \.isDone)
        return count
    }

    private func begin() async throws {
        if let delay { try? await Task.sleep(for: delay) }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
```

`AppShell/Dependencies.swift`: add `attendance`, `messages`, `events`, `tasks` to the struct, the initialiser and `live()` (`SupabaseAttendanceRepository(client:)`, `SupabaseMessageLogRepository(client:)`, `SupabaseEventsRepository(client:)`, `SupabaseTasksRepository(client:)`). `AppShell/Fixtures.swift`: `dependencies(for:)` passes `FakeAttendanceRepository(sessions: attendance(for: state))`, `FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)`, `FakeEventsRepository(events: FakeEventsRepository.seed)`, `FakeTasksRepository(tasks: FakeTasksRepository.seed)`, where `attendance(for:)` returns `FakeAttendanceRepository.seed` for every state in this PR (Task 11 adds `seedWithToday` for the after-save states). Every existing test target still compiles: `Dependencies.init` is only called from `Dependencies.live` and `Fixtures`.

- [ ] **Step 4: Prove the write path against the local stack in Swift** (create, done, undone, clear, as the seed's tutor; delete the test), then run, format, lint, commit; open PR 3

```bash
bun check
git add ios/TutorCentralKit
git commit -m "Data: the tasks repository, Supabase and fake; the four Phase 4 repositories in Dependencies and the fixtures"
git push -u origin phase-4/data
gh pr create --title "Data: attendance, message log, events and tasks repositories, the fakes, every answer decoded" --body "..."
```

Merge when green (no pictures).

### Task 9: DesignSystem: the Phase 4 components (PR 4)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/Rows.swift` (`AttendanceRow`: one pill; `HistoryRow`, `StudentPercentRow`, `AbsentStudentRow`, `EventRow`, `TaskRow` new), `Kit/KitSurfaces.swift` (the two attendance rows take the new signature)
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Components/FooterButton.swift`, `CountsLine.swift`, `MonthHeader.swift`, `PercentHero.swift`, `InlineAdd.swift`, `ScheduleRow.swift`; `Modifiers/StatusBarGlass.swift`
- Test: `ios/TutorCentralKit/Tests/DesignSystemTests/StatusBarGlassTests.swift`, `CountsLineTests.swift`

**Interfaces (components.md, Phase 4):**

```swift
public struct AttendanceRow: View { public init(name: String, present: Bool, toggle: @escaping () -> Void) }   // the whole row is the toggle; pill 96 × 40 radius 13: Present ok/okInk, Absent overdue/overdueInk; selection haptic
public struct HistoryRow: View { public init(day: String, date: String, title: String, line: String, lineTone: StatusTone? = nil, trailing: String? = nil, action: @escaping () -> Void) }   // day over date in a 46 column; trailing "1 absent" in overdue 600; chevron
public struct StudentPercentRow: View { public init(name: String, fraction: Double, percent: String, count: String, action: @escaping () -> Void) }   // avatar, name over a ProgressBar, percent numberRow over count caption, chevron
public struct AbsentStudentRow<Trailing: View>: View { public init(name: String, line: String, @ViewBuilder trailing: () -> Trailing) }   // avatar, name, parent line; `TellParentButton(action:)` or `ToldMark(text:)`
public struct TellParentButton: View { public init(enabled: Bool = true, action: @escaping () -> Void) }   // secondary 36 high, radius 13, whatsapp glyph (`message` symbol), "Tell parent"
public struct ToldMark: View { public init(_ text: String) }   // ok tick 14 and the text in footnote 600 ok
public struct EventRow: View { public init(start: String, end: String?, title: String, line: String?, action: @escaping () -> Void) }   // start over end in the 46 column
public struct ScheduleRow: View { public init(start: String, end: String?, title: String, line: String, lineTone: StatusTone? = nil, marked: Bool, action: @escaping () -> Void) }   // a class on the schedule and on Today: tick in ok when marked, else chevron
public struct TaskRow: View { public init(title: String, done: Bool, trailing: String?, trailingTone: StatusTone? = nil, toggle: @escaping () -> Void, swipeDone: Bool = true) }   // CheckMark 24, title struck through when done, trailing due or done day footnote text3 (overdue in overdue)
public struct FooterButton<Content: View>: View { public init(@ViewBuilder content: () -> Content) }   // the ground band above the tab bar holding a primary 50 or the SavedMark; applied with `.safeAreaInset(edge: .bottom)`
public struct SavedMark: View { public init(_ text: String = "Saved") }   // okTint fill, ok text with a tick, 50 high, radiusControl
public struct CountsLine: View { public init(present: Int, absent: Int); public static func text(present: Int, absent: Int) -> (present: String, absent: String) }   // "6 present", "0 absent"
public struct MonthHeader: View { public init(title: String, previous: @escaping () -> Void, next: @escaping () -> Void) }   // headline, two 32 round accentText chevron buttons 18
public struct PercentHero: View { public init(eyebrow: String, percent: String?, fraction: Double, line: String) }   // percent nil draws "No classes marked yet" in title2 instead of numberHero
public struct InlineAdd: View { public init(text: Binding<String>, placeholder: String, focused: Bool, dueChips: [(label: String, on: Bool, pick: () -> Void)], add: (enabled: Bool, run: () -> Void)) }   // the well with plus, the chip row, quiet Add 700
public extension View { func statusBarGlass() -> some View }   // U1: a top safe-area band of the system's bar material and a lineGlass hairline, opacity from `StatusBarGlass.opacity(forOffset:)` (0 at ≤ 0, 1 at ≥ 1)
```

- [ ] **Step 1: Write the failing tests**

`Tests/DesignSystemTests/StatusBarGlassTests.swift`:

```swift
import Testing
@testable import DesignSystem

struct StatusBarGlassTests {
    @Test func theGlassShowsOnceTheContentHasScrolled() {
        #expect(StatusBarGlass.opacity(forOffset: 0) == 0 && StatusBarGlass.opacity(forOffset: -20) == 0)
        #expect(StatusBarGlass.opacity(forOffset: 1) == 1 && StatusBarGlass.opacity(forOffset: 300) == 1)
        #expect(StatusBarGlass.opacity(forOffset: 0.5) == 0.5, "a short fade between")
    }
}
```

`Tests/DesignSystemTests/CountsLineTests.swift`:

```swift
import Testing
@testable import DesignSystem

struct CountsLineTests {
    @Test func theWords() {
        #expect(CountsLine.text(present: 6, absent: 0) == (present: "6 present", absent: "0 absent"))
        #expect(CountsLine.text(present: 1, absent: 1) == (present: "1 present", absent: "1 absent"))
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `StatusBarGlass`, `CountsLine` not found.

- [ ] **Step 3: Implement**

`Modifiers/StatusBarGlass.swift`:

```swift
import SwiftUI

/// U1: a tab root with a hidden navigation bar draws the system's glass under the status bar once its content has
/// scrolled, so content never runs bare under the clock (components.md, "Status bar on a scrolled root").
public enum StatusBarGlass {
    /// 0 at rest, 1 once the content has moved a point; a short fade between.
    public static func opacity(forOffset offset: CGFloat) -> Double {
        Double(min(max(offset, 0), 1))
    }
}

private struct StatusBarGlassModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { offset = $0 }
            .overlay(alignment: .top) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.bar)
                        .overlay(alignment: .bottom) { Rectangle().fill(Tokens.lineGlass.color).frame(height: Tokens.hairline) }
                        .frame(height: geometry.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                        .opacity(StatusBarGlass.opacity(forOffset: offset))
                        .allowsHitTesting(false)
                }
            }
    }
}

public extension View {
    /// On the `ScrollView` of a tab root.
    func statusBarGlass() -> some View {
        modifier(StatusBarGlassModifier())
    }
}
```

`Rows.swift`, `AttendanceRow` replaced:

```swift
/// The whole row toggles; the pill says the state: Present (ok fill, okInk) or Absent (overdue fill, overdueInk),
/// 96 × 40, radius 13, segmentActive. Selection haptic. (components.md, Attendance row, Phase 4.)
public struct AttendanceRow: View {
    let name: String
    let present: Bool
    let toggle: () -> Void
    static var pillSize: CGSize {
        CGSize(width: 96, height: 40)
    }

    public init(name: String, present: Bool, toggle: @escaping () -> Void) {
        self.name = name
        self.present = present
        self.toggle = toggle
    }

    public var body: some View {
        Button {
            toggle()
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.rowPaddingDense) {
                Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(present ? "Present" : "Absent")
                    .typeStyle(Tokens.segmentActive)
                    .foregroundStyle((present ? Tokens.okInk : Tokens.overdueInk).color)
                    .frame(width: Self.pillSize.width, height: Self.pillSize.height)
                    .background((present ? Tokens.ok : Tokens.overdue).color, in: .rect(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous))
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .pressable()
        .accessibilityLabel(name)
        .accessibilityValue(present ? "Present" : "Absent")
        .accessibilityAddTraits(.isToggle)
    }
}
```

`KitSurfaces.swift`: the two rows become `AttendanceRow(name: "Hemanth", present: hemanth) { hemanth.toggle() }` and `AttendanceRow(name: "Lakshmi", present: lakshmi) { lakshmi.toggle() }` with `@State private var hemanth = true`, `lakshmi = false` (the `Bool?` states go).

The other rows, each as the board draws it, all in `Rows.swift` with the padding, type and tone tokens named in the interface list (anatomy constants `dayColumnWidth` 46 on `HistoryRow` and `ScheduleRow`, `TellParentButton.height` 36, `SavedMark.height` 50); `FooterButton` is `content.padding(.horizontal, Tokens.pageSide).padding(.top, Tokens.rowPaddingDense).padding(.bottom, Tokens.rowPaddingDense).background(Tokens.ground.color)`; `MonthHeader` an `HStack` with `Text(title).typeStyle(Tokens.headline)` and two `Button`s of `Image(systemName: "chevron.left" / "chevron.right").font(.system(size: Tokens.iconSmall, weight: .semibold)).foregroundStyle(Tokens.accentText.color).frame(width: MonthHeader.buttonSize, height: MonthHeader.buttonSize)` (32), labels "Previous month" and "Next month"; `PercentHero` a `Card(.hero)` holding `Eyebrow`, then `HStack(alignment: .firstTextBaseline)` of `Text(percent).typeStyle(Tokens.numberHero)` and `Text("present").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)` (or `Text("No classes marked yet").typeStyle(Tokens.title2)` when nil), `ProgressBar(fraction:)`, `Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)`; `InlineAdd` a `VStack` of `TextWell`-styled field (`Well` with `plus` in text3 when empty and `showsFocus: focused`), the chip row (`FilterChip` per due chip), `Spacer`, `Button("Add").buttonStyle(.quiet(emphasised: true)).disabled(!add.enabled)`. Every new component gets a `#Preview` in both appearances.

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios/TutorCentralKit
git commit -m "DesignSystem: the attendance pill row, the history, event, schedule and task rows, the footer, the month header, the percent hero, the inline add, the status-bar glass"
```

### Task 10: `AttendanceStore`: open, toggle, save, tell the parent (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Attendance/AttendanceStore.swift`, `AttendanceActions.swift`
- Delete: `ios/TutorCentralKit/Sources/Features/Attendance/Attendance.swift` (the Phase 2 marker)
- Modify: `ios/TutorCentralKit/Package.swift`, `ios/project.yml` (`AttendanceTests`)
- Test: `ios/TutorCentralKit/Tests/AttendanceTests/AttendanceStoreTests.swift`

**Interfaces:**
- Consumes: `AttendanceRepository`, `MessageLogRepository` (Task 6), `RegisterStore` (Phase 3: `activeStudents`, `activeClasses`, `members(of:)`, `student(_:)`, `classroom(_:)`, `loadIfNeeded()`, `today`), `AttendanceDraft`, `AbsenceMessage`.
- Produces:

```swift
@MainActor @Observable public final class AttendanceStore {
    public enum Phase: Hashable, Sendable { case fresh, saved(at: Date), reopened(savedAt: Date), saving }
    public private(set) var draft: AttendanceDraft
    public private(set) var saved: AttendanceSession?            // the session for the chosen class and day, if any
    public private(set) var phase: Phase
    public private(set) var loading: Bool; public private(set) var error: String?
    public var message: String?; public private(set) var canRetry: Bool; public private(set) var lastSavedAt: Date?
    public var members: [Student]                                 // active, by name; everyone when classID is nil
    public var classOptions: [(id: UUID?, name: String, count: Int)]   // All students first
    public var className: String                                  // "Class 10 Maths" / "All students"
    public var dateText: String                                   // "Today, 7 Oct" / "Mon 5 Oct"
    public var hasStudents: Bool                                  // the empty state when false
    public var canSave: Bool                                      // fresh: always; reopened/saved: once changed; never while saving
    public var saveLabel: String                                  // "Save attendance" / "Save changes"
    public var banner: (symbol: String, text: String, ok: Bool)?  // after a save, or a reopened day
    public var absentRows: [(student: Student, line: String, told: String?)]   // from `saved`, not the draft
    public func open(classID: UUID?, date: Day) async            // loads the month, finds the session, makes the draft
    public func load() async                                      // first open: today and the first active class (All students when none)
    public func toggle(_ studentID: UUID)
    public func save() async -> Bool
    public func retryLast() async
    public func alert(for studentID: UUID) -> AbsenceAlert?        // nil when no parent number
    public func tell(_ studentID: UUID) async -> URL?             // logs, then the WhatsApp link; nil on failure (toast)
    public init(workspace: Workspace, register: RegisterStore, attendance: any AttendanceRepository, messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
public struct AbsenceAlert: Hashable, Sendable { public let student: Student; public let parentLine: String; public let text: String; public let url: URL? }
public struct AttendanceActions { let openStudents: () -> Void; let openHistory: () -> Void; public init(openStudents:openHistory:) }
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Attendance

@MainActor struct AttendanceStoreTests {
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
    let messages = FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)
    let today = Day(year: 2026, month: 10, day: 7)!
    let maths = FakeClassesRepository.maths.id
    let hemanth = FakeAttendanceRepository.hemanth

    func make() async -> AttendanceStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance, messages: messages,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func opensTodayOnTheFirstClassWithEveryonePresent() async {
        let store = await make()
        #expect(store.draft.date == today && store.draft.classID == maths && store.className == "Class 10 Maths")
        #expect(store.members.map(\.name).first == "Akshita Rao" && store.members.count == 6 && store.draft.presentCount == 6)
        #expect(store.phase == .fresh && store.canSave && store.saveLabel == "Save attendance" && store.banner == nil)
        #expect(store.dateText == "Today, 7 Oct" && store.classOptions.map(\.name) == ["All students", "Class 10 Maths", "Class 8 Science"])
        #expect(store.classOptions.map(\.count) == [10, 6, 3] && store.hasStudents)
    }

    @Test func savingWritesEveryMemberAndShowsTheAbsentOnes() async {
        let store = await make()
        store.toggle(hemanth)
        #expect(store.draft.absentCount == 1)
        #expect(await store.save())
        #expect(attendance.saves.count == 1 && attendance.saves[0].marks.count == 6 && attendance.saves[0].marks[hemanth] == .absent)
        guard case .saved = store.phase else { Issue.record("not saved"); return }
        #expect(store.banner?.ok == true && store.banner?.text.hasPrefix("Saved at 18:30") == true)
        #expect(store.absentRows.map(\.student.name) == ["Hemanth Reddy"] && store.absentRows[0].line == "Lakshmi Reddy · +91 93802 60871")
        #expect(store.absentRows[0].told == nil && !store.canSave && store.lastSavedAt != nil)
    }

    @Test func savingAgainReplacesTheMarks() async {
        let store = await make()
        store.toggle(hemanth)
        _ = await store.save()
        store.toggle(hemanth)
        #expect(store.canSave && store.saveLabel == "Save changes")
        _ = await store.save()
        #expect(attendance.saves.count == 2 && attendance.saves[1].marks[hemanth] == .present)
        #expect(attendance.sessions.filter { $0.date == today && $0.classID == maths }.count == 1 && store.absentRows.isEmpty)
    }

    @Test func aPastDayReopensWithItsMarksAndWhoWasTold() async {
        let store = await make()
        await store.open(classID: maths, date: Day(year: 2026, month: 10, day: 5)!)
        guard case .reopened = store.phase else { Issue.record("not reopened"); return }
        #expect(store.draft.marks[hemanth] == .absent && store.draft.presentCount == 5 && !store.canSave)
        #expect(store.banner?.text == "Marked on Mon 5 Oct at 18:04. Saving again replaces it." && store.banner?.ok == false)
        #expect(store.absentRows[0].told == "Told Mon 5 Oct" && store.dateText == "Mon 5 Oct")
    }

    @Test func aNewMemberIsPresentOnReopen() async {
        let store = await make()
        var sessions = attendance.sessions
        let index = sessions.firstIndex { $0.date.day == 5 && $0.classID == maths }!
        sessions[index].marks[FakeStudentsRepository.akshita] = nil
        attendance.sessions = sessions
        await store.open(classID: maths, date: Day(year: 2026, month: 10, day: 5)!)
        #expect(store.draft.marks[FakeStudentsRepository.akshita] == .present && store.members.count == 6)
        #expect(!store.canSave, "a member without a mark is present, which is not a change the tutor made")
    }

    @Test func allStudentsIsItsOwnSession() async {
        let store = await make()
        await store.open(classID: nil, date: today)
        #expect(store.members.count == 10 && store.className == "All students" && store.draft.classID == nil)
        _ = await store.save()
        #expect(attendance.saves.last?.classID == nil && attendance.saves.last?.marks.count == 10)
    }

    @Test func aFailedSaveKeepsTheMarksAndOffersRetry() async {
        let store = await make()
        store.toggle(hemanth)
        attendance.nextError = URLError(.notConnectedToInternet)
        #expect(await store.save() == false)
        #expect(store.draft.marks[hemanth] == .absent && store.phase == .fresh && store.canSave)
        #expect(store.message == "Couldn't save attendance. Check your connection and try again." && store.canRetry)
        await store.retryLast()
        #expect(attendance.saves.count == 1, "the failed attempt never reached the fake; the retry did")
        guard case .saved = store.phase else { Issue.record("not saved after retry"); return }
    }

    @Test func tellingAParentLogsOnce() async throws {
        let store = await make()
        store.toggle(hemanth)
        _ = await store.save()
        let alert = try #require(store.alert(for: hemanth))
        #expect(alert.text.hasPrefix("Hello Lakshmi, Hemanth was absent from Class 10 Maths today, Wednesday 7 October."))
        #expect(alert.url?.host() == "wa.me" && alert.parentLine == "Lakshmi Reddy · +91 93802 60871")
        let url = await store.tell(hemanth)
        #expect(url == alert.url && messages.logged == [hemanth] && store.absentRows[0].told == "Told today")
        #expect(store.alert(for: hemanth) == nil, "told: the row shows the mark, not the button")
    }

    @Test func aStudentWithoutANumberCannotBeTold() async {
        let store = await make()
        await store.open(classID: nil, date: today)
        var students = FakeStudentsRepository.seed
        students[9].parentPhone = nil   // Sahil Verma
        let sahil = students[9].id
        // The register is shared: change it as a refresh would.
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let noNumber = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance, messages: messages,
            now: { FakeCountsRepository.fixedNow }
        )
        await noNumber.open(classID: nil, date: today)
        noNumber.toggle(sahil)
        _ = await noNumber.save()
        let alert = noNumber.alert(for: sahil)
        #expect(alert?.url == nil && alert?.parentLine == "Add the parent's number first")
        #expect(await noNumber.tell(sahil) == nil && messages.logged.isEmpty)
    }

    @Test func noStudentsIsTheEmptyState() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(),
            cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance, messages: messages, now: { FakeCountsRepository.fixedNow })
        await store.load()
        #expect(!store.hasStudents && store.members.isEmpty && store.draft.classID == nil)
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `AttendanceStore` not found (after `AttendanceTests` is in `Package.swift` and `project.yml`: `.testTarget(name: "AttendanceTests", dependencies: ["Attendance"])`, `- package: TutorCentralKit/AttendanceTests`).

- [ ] **Step 3: Implement**

`Features/Attendance/AttendanceStore.swift`:

```swift
import Data
import Domain
import Foundation
import Observation

/// The mark screen (P4-Attendance-Mark-*): a date, a class, one mark per member, Save, then the absent students and
/// their alerts. One per centre (`ShellState.attendance`), so a tab switch keeps the unsaved toggles.
@MainActor @Observable public final class AttendanceStore {
    public enum Phase: Hashable, Sendable {
        case fresh
        case saved(at: Date)
        case reopened(savedAt: Date)
        case saving
    }

    public private(set) var draft: AttendanceDraft
    public private(set) var saved: AttendanceSession?
    public private(set) var phase: Phase = .fresh
    public private(set) var loading = false
    public private(set) var error: String?
    public var message: String?
    public private(set) var canRetry = false
    public private(set) var lastSavedAt: Date?
    private var sessions: [AttendanceSession] = []
    private var told: [AbsenceLog] = []
    private var loadedMonth: Period?
    private var lastFailed: (@MainActor () async -> Void)?
    private let workspace: Workspace
    private let register: RegisterStore
    private let attendance: any AttendanceRepository
    private let messages: any MessageLogRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        workspace: Workspace, register: RegisterStore, attendance: any AttendanceRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.attendance = attendance
        self.messages = messages
        self.now = now
        self.calendar = calendar
        draft = AttendanceDraft(date: Day(now(), calendar: calendar), classID: nil, members: [], saved: nil)
    }

    private var today: Day { Day(now(), calendar: calendar) }

    public var members: [Student] {
        let list = draft.classID.map { register.members(of: $0) } ?? register.activeStudents
        return list.filter { !$0.isArchived }
    }

    public var classOptions: [(id: UUID?, name: String, count: Int)] {
        [(nil, "All students", register.activeStudents.count)]
            + register.activeClasses.map { ($0.id, $0.name, register.members(of: $0.id).count) }
    }

    public var className: String { draft.classID.flatMap { register.classroom($0)?.name } ?? "All students" }

    public var dateText: String { draft.date == today ? "Today, \(draft.date.shortText)" : draft.date.shortWeekdayText }

    public var hasStudents: Bool { !register.activeStudents.isEmpty }

    public var canSave: Bool {
        guard phase != .saving, !members.isEmpty else { return false }
        return draft.isChanged(from: saved, members: members)
    }

    public var saveLabel: String { saved == nil ? "Save attendance" : "Save changes" }

    public var banner: (symbol: String, text: String, ok: Bool)? {
        switch phase {
        case let .saved(at): ("checkmark.circle", "Saved at \(TimeOfDay(hour: calendar.component(.hour, from: at), minute: calendar.component(.minute, from: at))!.text). Tap a name to change a mark, then save again.", true)
        case let .reopened(savedAt): ("clock", "Marked on \(draft.date.shortWeekdayText) at \(TimeOfDay(hour: calendar.component(.hour, from: savedAt), minute: calendar.component(.minute, from: savedAt))!.text). Saving again replaces it.", false)
        case .fresh, .saving: nil
        }
    }

    /// The absent students of the saved session, in list order, with the parent and whether they were told that day.
    public var absentRows: [(student: Student, line: String, told: String?)] {
        guard let saved else { return [] }
        return members.filter { saved.marks[$0.id] == .absent }.map { student in
            let line = [student.parentName, student.parentPhone?.display].compactMap(\.self).joined(separator: " · ")
            let toldDay = told.first { $0.studentID == student.id && Day($0.openedAt, calendar: calendar) == saved.date }
                .map { Day($0.openedAt, calendar: calendar) }
            let toldText = toldDay.map { $0 == today ? "Told today" : "Told \($0.shortWeekdayText)" }
            return (student, line.isEmpty ? "No parent details yet" : line, toldText)
        }
    }

    public func load() async {
        await register.loadIfNeeded()
        await open(classID: register.activeClasses.first?.id, date: today)
    }

    public func open(classID: UUID?, date: Day) async {
        await register.loadIfNeeded()
        if loadedMonth != date.period {
            loading = true
            defer { loading = false }
            do {
                async let read = attendance.sessions(centre: workspace.centre.id, month: date.period)
                async let logs = messages.absences(centre: workspace.centre.id, month: date.period)
                (sessions, told) = try await (read, logs)
                loadedMonth = date.period
                error = nil
            } catch {
                self.error = "Couldn't load attendance. Check your connection and try again."
            }
        }
        saved = sessions.first { $0.date == date && $0.classID == classID }
        let list = (classID.map { register.members(of: $0) } ?? register.activeStudents).filter { !$0.isArchived }
        draft = AttendanceDraft(date: date, classID: classID, members: list, saved: saved)
        phase = saved.map { .reopened(savedAt: $0.savedAt) } ?? .fresh
    }

    public func toggle(_ studentID: UUID) {
        draft.toggle(studentID)
        if case .saved = phase { phase = .reopened(savedAt: saved?.savedAt ?? now()) }
    }

    @discardableResult public func save() async -> Bool {
        guard canSave else { return false }
        let before = phase
        phase = .saving
        do {
            let session = try await attendance.save(centre: workspace.centre.id, classID: draft.classID, date: draft.date, marks: draft.marks)
            saved = session
            sessions.removeAll { $0.id == session.id || ($0.date == session.date && $0.classID == session.classID) }
            sessions.insert(session, at: 0)
            phase = .saved(at: session.savedAt)
            lastSavedAt = now()
            lastFailed = nil
            canRetry = false
            return true
        } catch {
            phase = before
            message = "Couldn't save attendance. Check your connection and try again."
            canRetry = true
            lastFailed = { [weak self] in await self?.save() }
            return false
        }
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    public func alert(for studentID: UUID) -> AbsenceAlert? {
        guard let saved, let student = register.student(studentID), saved.marks[studentID] == .absent,
              absentRows.first(where: { $0.student.id == studentID })?.told == nil else { return nil }
        let text = AbsenceMessage.text(
            parentName: student.parentName, studentName: student.name, className: draft.classID.flatMap { register.classroom($0)?.name },
            day: saved.date, today: today, tutorName: workspace.profile.displayName, centreName: workspace.centre.name
        )
        let line = student.parentPhone.map { [student.parentName, $0.display].compactMap(\.self).joined(separator: " · ") }
        return AbsenceAlert(student: student, parentLine: line ?? "Add the parent's number first", text: text,
                            url: student.parentPhone.map { AbsenceMessage.whatsAppURL(phone: $0, text: text) })
    }

    /// Logs the alert, then hands back the link to open. Nil (with a toast) when it could not be logged.
    public func tell(_ studentID: UUID) async -> URL? {
        guard let alert = alert(for: studentID), let url = alert.url else { return nil }
        do {
            told.insert(try await messages.logAbsence(centre: workspace.centre.id, studentID: studentID), at: 0)
            lastSavedAt = now()
            return url
        } catch {
            message = "Couldn't note the message. Check your connection and try again."
            canRetry = false
            return nil
        }
    }
}

public struct AbsenceAlert: Hashable, Sendable {
    public let student: Student
    public let parentLine: String
    public let text: String
    public let url: URL?
}
```

`Features/Attendance/AttendanceActions.swift`:

```swift
/// Where the Attendance tab's buttons lead when the screen is another feature's; AppShell supplies them.
public struct AttendanceActions {
    let openStudents: () -> Void
    let openHistory: () -> Void

    public init(openStudents: @escaping () -> Void, openHistory: @escaping () -> Void) {
        self.openStudents = openStudents
        self.openHistory = openHistory
    }
}
```

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios
git commit -m "Attendance: the store: open a class and day, toggle, save through save_attendance, the absent students and their alerts"
```

### Task 11: The Attendance tab: mark, saved, past date, the class menu, the alert sheet, empty; the launch states (PR 4)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Attendance/AttendanceView.swift`, `AttendanceSections.swift`, `AbsenceAlertSheet.swift`
- Modify: `AppShell/ShellState.swift` (`attendance`), `TabsView.swift` (the Attendance root), `TabsState.swift` (`open(.attendance)`), `RootView.swift` (`attendanceView`, `attendanceStore(for:)`, `studentsActions.openMarkAttendance` opens the tab), `RootView+LaunchStates.swift`, `LaunchState.swift` (7 cases), `Fixtures.swift` (`seedWithToday` for `attendance-saved`, `-alert`, `-past`; an empty register for `attendance-empty`), `LaterView.swift` (`markAttendance` removed), `Features/Students/ClassDetailView.swift` (unchanged: it calls `actions.openMarkAttendance(id)`), `docs/design/information-architecture.md` only if a state name must change
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (`theAttendanceStatesOpenTheTab`), `TabsStateTests.swift` (`anAttendanceLinkOpensTheTab`)

**Interfaces:**

```swift
public enum AttendanceBoardState: Sendable { case classMenu, oneAbsent, saved, alert }   // what a launch state sets up
public struct AttendanceView: View { public init(store: AttendanceStore, actions: AttendanceActions, boardState: AttendanceBoardState? = nil) }
// LaunchState: attendance, attendanceClassMenu = "attendance-class-menu", attendanceExceptions = "attendance-exceptions", attendanceSaved = "attendance-saved", attendanceAlert = "attendance-alert", attendancePast = "attendance-past", attendanceEmpty = "attendance-empty"
// TabsState.open(.attendance(date:classID:)) → true: selects the tab, clears its stack; RootView tells the store `open(classID:date:)` when the link carries them
```

- [ ] **Step 1: Write the failing tests**

Add to `LaunchStateTests`:

```swift
    @MainActor @Test func theAttendanceStatesOpenTheTab() async throws {
        let states: [LaunchState] = [.attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaved, .attendanceAlert, .attendancePast, .attendanceEmpty]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace) && RootView.tab(for: state) == .attendance)
        }
        #expect(RootView.attendanceBoardState(.attendanceClassMenu) == .classMenu && RootView.attendanceBoardState(.attendanceAlert) == .alert)
        let centre = Fixtures.meeraWorkspace.centre.id
        let saved = try await Fixtures.dependencies(for: .attendanceSaved).attendance.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(saved.first?.date == Day(year: 2026, month: 10, day: 7))
        let fresh = try await Fixtures.dependencies(for: .attendance).attendance.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(fresh.first?.date == Day(year: 2026, month: 10, day: 6))
        #expect(try await Fixtures.dependencies(for: .attendanceEmpty).students.students(centre: centre, period: Period(year: 2026, month: 10)).isEmpty)
    }
```

Add to `TabsStateTests`:

```swift
    @Test func anAttendanceLinkOpensTheTab() {
        let tabs = TabsState(selected: .today)
        tabs.push(.settings)
        #expect(tabs.open(.attendance(date: "2026-10-05", classID: nil)))
        #expect(tabs.selected == .attendance && tabs.paths[.attendance] == [])
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, the cases and `attendanceBoardState` not found.

- [ ] **Step 3: Implement**

`AttendanceView` (to P4-Attendance-Mark-Fresh, -Exceptions, -Saved, -PastDate, -ClassMenu, -Empty, in both appearances), its pieces in `AttendanceSections.swift`:

- The `ScrollView` with `.statusBarGlass()` (the modifier from Task 9), `.background(Tokens.ground.color)`, `.toolbar(.hidden, for: .navigationBar)`, `.padding(.top, max(0, Tokens.pageTop - topInset))`, `.padding(.bottom, Tokens.contentBottom)` and `.safeAreaInset(edge: .bottom) { footer }` so the list clears the footer.
- Title row: `Text("Attendance").typeStyle(Tokens.display)` with `Button("History") { actions.openHistory() }.buttonStyle(.quiet)` on the right (hidden with the empty state).
- The pickers card (`Card(.list)`, `radiusTile`): `PickerRow`-style rows 50 high with the label `body` left and the value in `accentText` `bodyStrong` with `chevron.up.chevron.down` right: Date opens a `.popover` holding a graphical `DatePicker` (`in: ...today`, India's calendar, as the date of birth in Phase 3) that calls `store.open(classID: store.draft.classID, date:)`; Class opens a `.popover` (`.presentationCompactAdaptation(.popover)`) 260 wide holding `store.classOptions` as rows 46 high (label `body`, the count in `subhead` `text3`, a `checkmark` in `accentText` on the chosen one), each calling `store.open(classID:date:)`; `boardState == .classMenu` opens it on appear.
- The hint `Text("Everyone starts present. Tap anyone who did not come, then save.").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)` while `phase == .fresh`; else the `Banner`-styled line from `store.banner` (`ok` text colour when `ok`, `text2` otherwise; a `Banner` variant with a tone, add `tone:` to `Banner`).
- The absent section when `store.absentRows` is not empty: `SectionHeader("\(count) absent")` and a `Card` of `AbsentStudentRow`s with `TellParentButton { alert = store.alert(for:) }` or `ToldMark(told)`.
- The members section: `HStack` of `SectionHeader("\(members.count) students")` and `CountsLine(present:absent:)`, then a `Card` of `AttendanceRow(name:present:toggle:)` divided; `EmptyRow` inside when the class has no members ("No students in this class", "Add students to the class from its page.").
- The footer: `FooterButton { … }` holding, by phase: `Button(store.saveLabel) { Task { await store.save() } }.buttonStyle(.primary(size: .card, loading: store.phase == .saving)).disabled(!store.canSave)` or, when `.saved` and nothing changed, `SavedMark()`.
- The empty state (`!store.hasStudents`): one `Card` with `EmptyState(symbol: "checkmark.circle", title: "No students yet", line: "Add your students and their classes first. Marking who came then takes two taps.", action: .init("Go to Students") { actions.openStudents() })` (the secondary button, no icon: the owner's rule for empty cards).
- The alert: `.sheet(item: $alert) { AbsenceAlertSheet(alert:onOpen:onClose:) }`, the sheet at `.medium` with `.large` available (`presentationDragIndicator(.hidden)`, `presentationCornerRadius(Tokens.radiusSheet)`, `presentationBackground(Tokens.surface1.color)`): `SheetHeader(title: "Tell the parent", cancel: ("Cancel", close))`, `Avatar(name:, size: 56)` beside `Text("\(firstName) was absent \(dayWords)")` in `title3` and the parent line in `subhead` `text2`, "Message" label and the text in a `Well`-styled block (`body`, padding `cardPaddingCompact`), the footnote "Opens WhatsApp with the message ready to send. We note the date in \(firstName)'s record.", then `Button { Task { if let url = await store.tell(id) { openURL(url); close() } } } label: { Label("Open WhatsApp", systemImage: "message") }.buttonStyle(.primary(size: .sheet)).disabled(alert.url == nil)` in the footer. `boardState == .alert` opens it for Hemanth on appear; `.oneAbsent` toggles Hemanth; `.saved` saves on appear (the fixture already holds the saved session, so the store opens `reopened`; the board state then sets `phase = .saved(at: savedAt)` through a `markSavedForBoard()` on the store, `#if DEBUG`-free, documented as the board state's hook).
- Haptics: `.onChange(of: store.lastSavedAt) { Haptic.play(.success) }`; `store.message` goes to the toast through `onMessage` as the Students root does (`toasts.show(message, action: store.canRetry ? retry : nil)`).

`AppShell`: `ShellState.attendance: AttendanceStore?` (`@ObservationIgnored`, reset with the rest); `RootView.attendanceStore(for:)` as `register(for:)`; `attendanceView` builds `AttendanceView(store:actions: AttendanceActions(openStudents: { shell.tabs.select(.students) }, openHistory: { shell.tabs.push(.history) }), boardState:)` and `.task { await store.load() }` once; `Route.history` exists from this task (its screen arrives in Task 13; until then it pushes `LaterView(place: .history)`, a new `LaterPlace` removed in Task 13); `studentsActions.openMarkAttendance` becomes `{ id in Task { await shell.attendance(for: workspace).open(classID: id, date: today) }; shell.tabs.select(.attendance) }`; `TabsState.open(.attendance)` returns true and `RootView.onOpenURL` calls `open(classID:date:)` with the link's values (a date that does not parse opens today); `TabsView` takes an `attendance: () -> Attendance` root. `Fixtures.attendance(for:)`: `seedWithToday` for `attendanceSaved`, `attendanceAlert`, `attendancePast`, `history*`, `today-evening` (Task 19); `seed` otherwise. `LaterView`'s `markAttendance` and the tab's later root go.

- [ ] **Step 4: Run, photograph, commit; open PR 4**

```bash
bun check
for s in attendance attendance-class-menu attendance-exceptions attendance-saved attendance-alert attendance-past attendance-empty kit-surfaces; do bun shots $s; done
bun pr-shots phase-4-attendance .shots/*/*.png
git add ios
git commit -m "Attendance: the mark screen, the class menu, saved with the absent students, the absence alert, a past date, empty; the Kit's rows"
git push -u origin phase-4/attendance-mark
gh pr create --title "The Attendance tab: mark, save, the absent students, the absence alert, a past date" --body "<the pr-shots table>"
```

Compare each picture with its board before merging; merge when green.

### Task 12: `HistoryStore` and `StudentMonthStore` (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Attendance/HistoryStore.swift`, `StudentMonthStore.swift`
- Test: `ios/TutorCentralKit/Tests/AttendanceTests/HistoryStoreTests.swift`, `StudentMonthStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class HistoryStore {
    public enum View: Hashable, Sendable { case byDate, byStudent }
    public var view: View; public private(set) var month: Period; public private(set) var sessions: [AttendanceSession]
    public private(set) var loading: Bool; public private(set) var error: String?
    public var monthTitle: String                                   // "October 2026"
    public var summary: (title: String, fraction: Double, percent: String, count: String)?   // "5 classes marked", 0.79, "79%", "19 of 24 present"; nil when none
    public var dateRows: [(session: AttendanceSession, day: String, date: String, title: String, line: String, absent: String?)]
    public var studentRows: [(student: Student, fraction: Double, percent: String, count: String)]   // active students with a mark this month, by name; "Lowest first" sorts by fraction then name
    public var sortLowestFirst: Bool
    public func load() async; public func previousMonth() async; public func nextMonth() async
    public init(workspace: Workspace, register: RegisterStore, attendance: any AttendanceRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
@MainActor @Observable public final class StudentMonthStore {
    public let studentID: UUID
    public private(set) var month: Period; public private(set) var loading: Bool; public private(set) var error: String?
    public var name: String; public var monthTitle: String
    public var hero: (eyebrow: String, percent: String?, fraction: Double, line: String)   // "OCTOBER 2026" (the view uppercases), "67%", 0.67, "2 of 3 classes · 1 absence"
    public var absences: [(session: AttendanceSession, day: String, date: String, title: String, line: String, lineTone: StatusTone?)]   // "Parent told on Mon 5 Oct" in ok, else the class's time range
    public var earlier: [(month: Period, title: String, line: String)]   // the previous month only ("September", "8 of 11 present · 3 absences"); more by the chevrons
    public func load() async; public func previousMonth() async; public func nextMonth() async
    public init(studentID: UUID, workspace: Workspace, register: RegisterStore, attendance: any AttendanceRepository, messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
```

- [ ] **Step 1: Write the failing tests**

`HistoryStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Attendance

@MainActor struct HistoryStoreTests {
    func make(_ sessions: [AttendanceSession] = FakeAttendanceRepository.seedWithToday) async -> HistoryStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = HistoryStore(workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: FakeAttendanceRepository(sessions: sessions), now: { FakeCountsRepository.fixedNow })
        await store.load()
        return store
    }

    @Test func octoberByDateAsTheBoardDrawsIt() async throws {
        let store = await make()
        #expect(store.monthTitle == "October 2026" && store.view == .byDate)
        let summary = try #require(store.summary)
        #expect(summary.title == "5 classes marked" && summary.percent == "79%" && summary.count == "19 of 24 present")
        #expect(store.dateRows.map(\.date) == ["7 Oct", "6 Oct", "5 Oct", "2 Oct", "1 Oct"] && store.dateRows.map(\.day).first == "Wed")
        #expect(store.dateRows[0].title == "Class 10 Maths" && store.dateRows[0].line == "5 of 6 present" && store.dateRows[0].absent == "1 absent")
    }

    @Test func byStudentWithPercentagesAndLowestFirst() async {
        let store = await make()
        store.view = .byStudent
        #expect(store.studentRows.map(\.student.name).prefix(2) == ["Akshita Rao", "Ananya Iyer"] && store.studentRows.count == 9)
        let hemanth = store.studentRows.first { $0.student.id == FakeAttendanceRepository.hemanth }
        #expect(hemanth?.percent == "67%" && hemanth?.count == "2 of 3")
        store.sortLowestFirst = true
        #expect(store.studentRows.first?.student.name == "Nikhil Das" && store.studentRows.first?.percent == "0%")
    }

    @Test func theMonthsMoveAndAnEmptyMonthSaysSo() async {
        let store = await make()
        await store.previousMonth()
        #expect(store.monthTitle == "September 2026" && store.summary?.title == "15 classes marked")
        await store.nextMonth()
        await store.nextMonth()
        #expect(store.monthTitle == "November 2026" && store.summary == nil && store.dateRows.isEmpty && store.studentRows.isEmpty)
    }
}
```

`StudentMonthStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Attendance

@MainActor struct StudentMonthStoreTests {
    @Test func hemanthsOctober() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = StudentMonthStore(
            studentID: FakeAttendanceRepository.hemanth, workspace: FakeCentreRepository.meeraWorkspace, register: register,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday), messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        #expect(store.name == "Hemanth Reddy" && store.monthTitle == "October 2026")
        #expect(store.hero.percent == "33%" && store.hero.line == "1 of 3 classes · 2 absences" && store.hero.eyebrow == "October 2026")
        #expect(store.absences.map(\.date) == ["7 Oct", "5 Oct"], "newest first; the seed's rule and the saved 7th")
        #expect(store.absences[0].line == "17:00–18:00" && store.absences[0].lineTone == nil)
        #expect(store.absences[1].line == "Parent told on Mon 5 Oct" && store.absences[1].lineTone == .ok)
        #expect(store.earlier.first?.title == "September" && store.earlier.first?.line == "8 of 11 present · 3 absences")
        await store.nextMonth()
        #expect(store.hero.percent == nil && store.hero.line == "Nothing marked in November yet")
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `HistoryStore`, `StudentMonthStore` not found.

- [ ] **Step 3: Implement**

`HistoryStore`: holds `month` (from `now()`), reads `attendance.sessions(centre:month:)` on `load()` and after each month move (loading flag; the stale pattern keeps the old rows at `opacityStale` while a month loads; an error keeps the last rows and says "Couldn't load attendance. Check your connection and try again."). `summary` from `AttendanceStats.forMonth`: `"\(sessions.count) classes marked"` (1: "1 class marked"), `percent.map { "\($0)%" }`, `"\(present) of \(total) present"`; nil when `sessions` is empty. `dateRows` map each session: `day = session.date.shortWeekdayText.prefix(3)`, `date = session.date.shortText`, `title = register.classroom(session.classID)?.name ?? "All students"`, `line = "\(presentCount) of \(marks.count) present"`, `absent = absentCount == 0 ? nil : "\(absentCount) absent"`. `studentRows`: `register.activeStudents` mapped with `AttendanceStats.forStudent`, keeping those with `total > 0`, sorted by name or, with `sortLowestFirst`, by `fraction` then name; `percent = "\(count.percent ?? 0)%"`, `count = "\(present) of \(total)"`.

`StudentMonthStore`: reads sessions and absence logs for `month`; `hero`: eyebrow `month.title`, `percent` from `AttendanceStats.forStudent`, line `"\(present) of \(total) classes · \(absences) absence(s)"` (0: "No absences"), or when `total == 0`: percent nil and line `"Nothing marked in \(month.monthName) yet"` (`Period.monthName` = `formatted("MMMM")`, add it with a `PeriodTests` line). `absences` from `AttendanceStats.absences(of:in:)` with `line = told(on: session.date) ? "Parent told on \(day.shortWeekdayText)" : classroom?.timeRange ?? "All students"`, tone `.ok` when told. `earlier`: the previous month's sessions read in the same `load()` (a second `sessions(centre:month: month.previous)` call), one row with `month.previous.monthName` and its line, omitted when that month has no mark for the student.

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios
git commit -m "Attendance: the history store by date and by student, a student's month"
```

### Task 13: History and a student's month on screen; the student detail's attendance section (PR 5)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Attendance/HistoryView.swift`, `StudentMonthView.swift`
- Modify: `Features/Students/StudentDetailView.swift` (the attendance section live), `StudentDetailSections.swift` (`AttendanceCard`), `StudentDetailStore.swift` (`attendanceLine`, reading sessions), `StudentsActions.swift` (`openStudentAttendance`), `AppShell/TabsState.swift` (`Route.history`, `.historyStudent(UUID)`), `TabsView.swift`, `RootView.swift`, `RootView+LaunchStates.swift`, `LaunchState.swift` (4 cases), `Fixtures.swift`, `LaterView.swift` (`history` removed)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (`theHistoryStatesPushOnTheAttendanceTab`), `Tests/StudentsTests/StudentDetailStoreTests.swift` (`theAttendanceSectionReadsTheMonth`)

**Interfaces:**

```swift
public struct HistoryView: View { public init(store: HistoryStore, openSession: @escaping (AttendanceSession) -> Void, openStudent: @escaping (UUID) -> Void, boardState: HistoryBoardState? = nil) }
public enum HistoryBoardState: Sendable { case byStudent }
public struct StudentMonthView: View { public init(store: StudentMonthStore, openSession: @escaping (AttendanceSession) -> Void) }
// StudentDetailStore gains: public var attendanceCard: (title: String, fraction: Double, line: String, percent: String)? and func loadAttendance() async (reads this month's sessions through an injected `any AttendanceRepository`)
// LaunchState: history, historyByStudent = "history-by-student", historyStudent = "history-student", historyEmpty = "history-empty"
```

- [ ] **Step 1: Write the failing tests**

Add to `LaunchStateTests`:

```swift
    @MainActor @Test func theHistoryStatesPushOnTheAttendanceTab() {
        for state in [LaunchState.history, .historyByStudent, .historyEmpty] {
            #expect(RootView.tab(for: state) == .attendance && RootView.initialRoutes(for: state) == [.history])
        }
        #expect(RootView.initialRoutes(for: .historyStudent) == [.history, .historyStudent(FakeAttendanceRepository.hemanth)])
        #expect(RootView.historyBoardState(.historyByStudent) == .byStudent && RootView.historyBoardState(.history) == nil)
    }
```

Add to `StudentDetailStoreTests` (the store now takes `attendance:`):

```swift
    @Test func theAttendanceSectionReadsTheMonth() async throws {
        let store = await make(attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday))
        await store.loadAttendance()
        let card = try #require(store.attendanceCard)
        #expect(card.title == "October 2026" && card.percent == "100%" && card.line == "3 of 3 classes · no absences")
        let none = await make(attendance: FakeAttendanceRepository())
        await none.loadAttendance()
        #expect(none.attendanceCard == nil, "nothing marked: the empty row says so")
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL.

- [ ] **Step 3: Implement**

`HistoryView` (P4-History-ByDate, -ByStudent, -Empty): pushed on the Attendance tab, tab bar hidden, the inline navigation row as Phase 3's screens (`IconButton(symbol: "chevron.left")`, title "History"); `Segmented(options: [(.byDate, "By date"), (.byStudent, "By student")], selection: $store.view)`; `MonthHeader(title: store.monthTitle, previous:next:)`; by date: a `Card(.list, radiusTile)` holding the summary row (`rowTitle` title over a `ProgressBar`, the percent `numberRow` over the count `caption` right) then `SectionHeader("Classes")` and a `Card` of `HistoryRow`s (`action: openSession(session)`, which AppShell turns into `attendance.open(classID:date:)` and a pop to the root); by student: `SectionHeader("\(n) students", action: ("Lowest first" / "By name", toggle))` and a `Card` of `StudentPercentRow`s (`action: openStudent(id)` pushes `.historyStudent(id)`); empty month: a `Card` with `EmptyRow(symbol: "checkmark.circle", title: "Nothing marked yet", line: "Classes you mark show here by date and by student, with each month's percentage.")`. The stale pattern on month change (`opacityStale` while loading).

`StudentMonthView` (P4-History-Student): the navigation row with the student's name, `MonthHeader`, `PercentHero(eyebrow:percent:fraction:line:)`, `SectionHeader("\(n) absence(s)")` with a `Card` of `HistoryRow`s (title the class, line and tone from the store; `EmptyRow("No absences this month", …)` when none), `SectionHeader("Earlier")` with a `Card` of one `HistoryRow(day: "Sep", date: "2026", …)` when `earlier` has a row.

The student detail (P4-StudentDetail-Attendance): `StudentDetailStore` gains `attendance: any AttendanceRepository` through its initialiser (RootView passes `deps.attendance`) and `attendanceCard` from this month's sessions (`register.period`); `AttendanceCard` replaces the later row: `SectionHeader("Attendance", action: ("See all", { actions.openStudentAttendance(id) }))` and a `Card` row with the month `rowTitle` over `ProgressBar(fraction:)` and the line `footnote` `text2`, the percent `numberRow` on the right; when `attendanceCard == nil`, `EmptyRow(symbol: "checkmark.circle", title: "Nothing marked yet", line: "Mark \(firstName)'s class from the Attendance tab to see this month here.")`. `StudentsActions.openStudentAttendance: (UUID) -> Void` pushes `.historyStudent(id)` on the current tab (the Students tab's stack can hold it: add the route to `TabsView`'s destinations for every tab). `Route.history` and `.historyStudent` build `HistoryView` / `StudentMonthView` with stores made per screen (`HistoryStore(workspace:register:attendance:now:)`, `StudentMonthStore(...)`).

`Fixtures`: `historyEmpty` gets `FakeAttendanceRepository()` (no sessions); the other history states `seedWithToday`.

- [ ] **Step 4: Run, photograph, commit; open PR 5**

```bash
bun check
for s in history history-by-student history-student history-empty student; do bun shots $s; done
bun pr-shots phase-4-history .shots/*/*.png
git add ios
git commit -m "Attendance: history by date and by student, a student's month; the student detail's attendance section live"
git push -u origin phase-4/history
gh pr create --title "History by date and by student, a student's month, the detail's attendance section" --body "<the pr-shots table>"
```

### Task 14: `ScheduleStore` and `EventFormStore` (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Schedule/ScheduleStore.swift`, `EventFormStore.swift`, `ScheduleActions.swift`
- Delete: `ios/TutorCentralKit/Sources/Features/Schedule/Schedule.swift` (the marker)
- Modify: `Package.swift`, `project.yml` (`ScheduleTests`)
- Test: `ios/TutorCentralKit/Tests/ScheduleTests/ScheduleStoreTests.swift`, `EventFormStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class ScheduleStore {
    public private(set) var month: Period; public var selected: Day; public private(set) var events: [CalendarEvent]   // the month's
    public private(set) var sessions: [AttendanceSession]; public private(set) var loading: Bool; public private(set) var error: String?
    public var message: String?; public private(set) var canRetry: Bool; public private(set) var lastSavedAt: Date?
    public var monthTitle: String; public var today: Day
    public var markedDays: Set<Day>                                   // class occurrences and event days this month
    public var dayTitle: String                                       // "Today, 7 October" / "Saturday 10 October"
    public var classRows: [(classroom: Classroom, start: String, end: String?, line: String, lineTone: StatusTone?, marked: Bool)]   // "5 of 6 present" ok when a session exists, else "Mon, Wed, Fri · 6 students"
    public var eventRows: [(event: CalendarEvent, start: String, end: String?, line: String?)]   // start "11:00" or "All day"
    public var noClassLine: String?                                   // "No classes meet on Saturdays." when the day has none
    public var comingUp: [(event: CalendarEvent, day: String, line: String)]   // only when `selected == today`: "Sat 10", "11:00–12:00 · Class 10 parents" (the note's first clause up to the first full stop, else the time)
    public func load() async; public func select(_ day: Day) async; public func previousMonth() async; public func nextMonth() async
    public func add(_ draft: EventDraft) async -> CalendarEvent?; public func update(_ id: UUID, with draft: EventDraft) async -> Bool; public func delete(_ id: UUID) async -> Bool; public func retryLast() async
    public init(workspace: Workspace, register: RegisterStore, events: any EventsRepository, attendance: any AttendanceRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
@MainActor @Observable public final class EventFormStore: Identifiable {
    public enum Mode: Sendable { case new(Day), edit(CalendarEvent) }
    public let mode: Mode; public var title: String; public var date: Day; public private(set) var startTime: TimeOfDay?; public private(set) var endTime: TimeOfDay?; public var note: String
    public var heading: String   // "New event" / "Edit event"
    public var draft: EventDraft; public var isChanged: Bool; public var canSave: Bool; public var timeError: String?
    public func setStart(_ time: TimeOfDay?); public func setEnd(_ time: TimeOfDay?)   // an end without a start takes start + 1 h, as the class form
    public init(mode: Mode)
}
public struct ScheduleActions { let openClass: (UUID) -> Void; public init(openClass:) }
```

- [ ] **Step 1: Write the failing tests**

`ScheduleStoreTests.swift`:

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Schedule

@MainActor struct ScheduleStoreTests {
    let events = FakeEventsRepository(events: FakeEventsRepository.seed)

    func make() async -> ScheduleStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = ScheduleStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, events: events,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday), now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func octoberWithTodayChosen() async {
        let store = await make()
        #expect(store.monthTitle == "October 2026" && store.selected == store.today && store.dayTitle == "Today, 7 October")
        #expect(store.markedDays.contains(Day(year: 2026, month: 10, day: 10)!) && store.markedDays.contains(Day(year: 2026, month: 10, day: 8)!))
        #expect(!store.markedDays.contains(Day(year: 2026, month: 10, day: 11)!), "a Sunday with nothing")
        #expect(store.classRows.map(\.classroom.name) == ["Class 10 Maths"] && store.classRows[0].line == "5 of 6 present" && store.classRows[0].marked)
        #expect(store.classRows[0].start == "17:00" && store.classRows[0].end == "18:00")
        #expect(store.comingUp.map(\.day) == ["Sat 10", "Sat 17"] && store.comingUp[0].line == "11:00–12:00 · Class 10 parents")
        #expect(store.eventRows.isEmpty && store.noClassLine == nil)
    }

    @Test func aSaturdayWithAnEventAndNoClass() async {
        let store = await make()
        await store.select(Day(year: 2026, month: 10, day: 10)!)
        #expect(store.dayTitle == "Saturday 10 October" && store.classRows.isEmpty && store.noClassLine == "No classes meet on Saturdays.")
        #expect(store.eventRows.map(\.event.title) == ["Parents' meeting"] && store.eventRows[0].start == "11:00" && store.eventRows[0].line == "Class 10 parents. Bring the September test papers.")
        #expect(store.comingUp.isEmpty, "coming up shows only with today chosen")
    }

    @Test func anUnmarkedClassShowsItsSummary() async {
        let store = await make()
        await store.select(Day(year: 2026, month: 10, day: 8)!)
        #expect(store.classRows[0].classroom.name == "Class 8 Science" && store.classRows[0].line == "Tue, Thu · 3 students" && !store.classRows[0].marked)
    }

    @Test func addEditDeleteWithRollback() async throws {
        let store = await make()
        var draft = EventDraft(date: Day(year: 2026, month: 10, day: 20)!)
        draft.title = "Holiday"
        let made = try #require(await store.add(draft))
        #expect(store.events.contains { $0.id == made.id } && store.markedDays.contains(made.date) && store.lastSavedAt != nil)
        draft.title = "Diwali holiday"
        #expect(await store.update(made.id, with: draft) && store.events.first { $0.id == made.id }?.title == "Diwali holiday")
        events.nextError = URLError(.notConnectedToInternet)
        draft.title = "Lost"
        #expect(await store.update(made.id, with: draft) == false)
        #expect(store.events.first { $0.id == made.id }?.title == "Diwali holiday" && store.message == "Couldn't save the event. Check your connection and try again." && store.canRetry)
        #expect(await store.delete(made.id) && !store.events.contains { $0.id == made.id })
        events.nextError = URLError(.notConnectedToInternet)
        #expect(await store.delete(FakeEventsRepository.mockTest.id) == false && store.events.count == 2, "a delete waits for the server")
    }

    @Test func theMonthsMove() async {
        let store = await make()
        await store.nextMonth()
        #expect(store.monthTitle == "November 2026" && store.selected == Day(year: 2026, month: 11, day: 1) && store.events.isEmpty)
        await store.previousMonth()
        #expect(store.monthTitle == "October 2026" && store.selected == store.today, "back in today's month, today is chosen again")
    }
}
```

`EventFormStoreTests.swift`:

```swift
import Domain
import Foundation
import Testing
@testable import Schedule

@MainActor struct EventFormStoreTests {
    @Test func aNewEventNeedsATitleAndKeepsItsTimesInOrder() {
        let store = EventFormStore(mode: .new(Day(year: 2026, month: 10, day: 10)!))
        #expect(store.heading == "New event" && !store.canSave && store.isChanged == false)
        store.title = "Parents' meeting"
        #expect(store.canSave && store.isChanged)
        store.setEnd(TimeOfDay(hour: 12, minute: 0))
        #expect(store.startTime == TimeOfDay(hour: 11, minute: 0), "an end alone takes a start an hour before")
        store.setStart(TimeOfDay(hour: 12, minute: 30))
        #expect(!store.canSave && store.timeError == "The event has to end after it starts.")
        store.setEnd(nil)
        #expect(store.canSave && store.timeError == nil)
    }

    @Test func editingIsSaveableOnlyOnceChanged() {
        let store = EventFormStore(mode: .edit(FakeEventsRepositorySeed.parentsMeeting))
        #expect(store.heading == "Edit event" && store.title == "Parents' meeting" && !store.canSave && !store.isChanged)
        store.note = "Bring the papers."
        #expect(store.canSave && store.draft.trimmedNote == "Bring the papers.")
    }
}
```

(`FakeEventsRepositorySeed` is a typo guard: use `FakeEventsRepository.parentsMeeting` with `import Data`.)

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL.

- [ ] **Step 3: Implement**

`ScheduleStore`: `month = Period.containing(now(), in: calendar.timeZone)`, `selected = today`; `load()` and the month moves read `events.events(centre:from:to:)` for the month's first to last day (`Day(iso: month.isoDay)`, `Day(iso: month.next.previousDayISO)`) and `attendance.sessions(centre:month:)` together (`async let`), with the stale pattern and the error line "Couldn't load the schedule. Check your connection and try again."; `select(_:)` sets `selected` and, when the day is in another month, moves the month first; `previousMonth`/`nextMonth` select the first of the month, or today when the month is today's. `markedDays` = the union of `Occurrences.days(of:in:calendar:)` for `register.activeClasses` and `events.map(\.date)`. `classRows` from `NextClass.classesToday(in: register.activeClasses, on: selected, calendar:)`: `start = startTime?.text ?? "No time"`, `end = endTime?.text`, a session for the class and day gives `line = "\(presentCount) of \(marks.count) present"` in `.ok` and `marked = true`, else `line = "\(daysSummary) · \(members.count) students"`. `eventRows` from `CalendarEvent.on(selected, in: events)`: `start = startTime?.text ?? "All day"`, `line = event.line`. `noClassLine` when `classRows.isEmpty`: `"No classes meet on \(selected.weekdayLongText.split(separator: " ")[0])s."`. `comingUp` from `CalendarEvent.comingUp(events, after: today, calendar:)` (`day = date.shortWeekdayText` without the month: `"\(prefix 3) \(date.day)"`), `line = [timeRange, note's first clause].compactMap.joined(" · ")`. Writes as `RegisterStore`'s: `add` waits (the sheet shows loading), `update` is optimistic with rollback, `delete` waits; failures set `message` ("Couldn't save the event…" / "Couldn't delete the event…") and `lastFailed` for `retryLast`.

`EventFormStore`: as `ClassFormStore` (times through `setStart`/`setEnd` with the hour-before rule and `EventDraft.Problem.endNotAfterStart.message` as `timeError`), `draft` built from the fields, `isChanged` against the original draft when editing (always true when new and the title is not empty), `canSave = draft.isValid && isChanged`.

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios
git commit -m "Schedule: the month store with its marked days, the day's classes and events, coming up, event writes; the event form store"
```

### Task 15: Schedule on screen: the month, a day, the event sheet, delete; Today's Schedule action; the event link (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Schedule/ScheduleView.swift`, `EventFormSheet.swift`
- Modify: `AppShell/TabsState.swift` (`Route.schedule`, `.event(UUID)` opens Edit event over the schedule; `open(.event)` returns true on the More tab), `TabsView.swift`, `RootView.swift` (`scheduleView`, Today's `openLater(.schedule)` becomes `push(.schedule)`), `RootView+LaunchStates.swift`, `LaunchState.swift` (5 cases), `Fixtures.swift`, `LaterView.swift` (`schedule` removed), `DesignSystem/Components/CalendarMonth.swift` (takes `Day`s and a `Calendar`: `init(month: Period, today: Day, selected: Binding<Day>, marked: Set<Day>, calendar:)` beside the existing `Date` initialisers; the week initialiser stays for the Kit)
- Test: `Tests/AppShellTests/LaunchStateTests.swift` (`theScheduleStatesPushOnTheMoreTab`), `TabsStateTests.swift` (`anEventLinkOpensItOnTheMoreTab`), `Tests/DesignSystemTests/CalendarMonthTests.swift` (`octoberStartsOnAThursday`: `CalendarMonth.monthDays` for October 2026 has three leading nils and 31 days)

**Interfaces:**

```swift
public enum ScheduleBoardState: Sendable { case saturday, newEvent, editEvent, deleteConfirm }
public struct ScheduleView: View { public init(store: ScheduleStore, actions: ScheduleActions, boardState: ScheduleBoardState? = nil, openEvent: UUID? = nil) }
public struct EventFormSheet: View { public init(store: EventFormStore, showsFocus: Bool = false, autofocus: Bool = false, confirmsDelete: Bool = false, onSave: @escaping (EventDraft) async -> Bool, onDelete: (() async -> Bool)? = nil, onClose: @escaping () -> Void) }
// LaunchState: schedule, scheduleDay = "schedule-day", eventNew = "event-new", eventEdit = "event-edit", eventDeleteConfirm = "event-delete-confirm"
```

- [ ] **Step 1: Write the failing tests**

```swift
    // LaunchStateTests
    @MainActor @Test func theScheduleStatesPushOnTheMoreTab() {
        for state in [LaunchState.schedule, .scheduleDay, .eventNew, .eventEdit, .eventDeleteConfirm] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace) && RootView.tab(for: state) == .more)
            #expect(RootView.initialRoutes(for: state) == [.schedule])
        }
        #expect(RootView.scheduleBoardState(.scheduleDay) == .saturday && RootView.scheduleBoardState(.eventDeleteConfirm) == .deleteConfirm && RootView.scheduleBoardState(.schedule) == nil)
    }

    // TabsStateTests
    @Test func anEventLinkOpensItOnTheMoreTab() {
        let tabs = TabsState(selected: .today)
        let id = UUID()
        #expect(tabs.open(.event(id)))
        #expect(tabs.selected == .more && tabs.paths[.more] == [.schedule, .event(id)])
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL.

- [ ] **Step 3: Implement**

`ScheduleView` (P4-Schedule-Month, -Day): pushed (from More in Task 19, from Today's "Schedule" now), tab bar hidden, the navigation row with "Schedule" and `IconButton(symbol: "plus", label: "Add an event") { adding = EventFormStore(mode: .new(store.selected)) }`; the calendar `Card` (`padding(.top, Tokens.rowPaddingDense)`, `.horizontal, Tokens.cardPaddingCompact`, `.bottom, Tokens.tileGap`) holding `MonthHeader(title: store.monthTitle, previous:next:)` and `CalendarMonth(month: store.month, today: store.today, selected: Binding(get: { store.selected }, set: { day in Task { await store.select(day) } }), marked: store.markedDays, calendar: DayHeading.india)`; `SectionHeader(store.dayTitle, action: selected == today ? nil : ("Add event", add))` and a `Card` of `ScheduleRow`s for the classes (`action: actions.openClass(id)`) then `EventRow`s (`action: editing = EventFormStore(mode: .edit(event))`); `Text(noClassLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)` when set; when today is chosen, `SectionHeader("Coming up")` and a `Card` of `EventRow(start: day, …)` rows (`EmptyRow("Nothing coming up", "Events you add show here for the next seven days.")` when none). Sheets: `.sheet(item: $adding)` and `.sheet(item: $editing)` with `EventFormSheet` at the content's height (as `ClassFormSheet`: `fixedSize`, `onGeometryChange`, `.presentationDetents([.height(height)])`), `onSave: { await store.add($0) != nil }` / `{ await store.update(id, with: $0) }`, `onDelete: { await store.delete(id) }` for editing. `EventFormSheet` (P4-Event-New, -Edit, -Delete-Confirm): `SheetHeader(title: store.heading, cancel: ("Cancel", cancel), save: .init("Save", enabled: store.canSave && !saving, run: save))`; `TextWell(label: "Title", text: $store.title, placeholder: "What is it", showsFocus:, autofocus:)`; "Date" label over `PickerTile(label: "Day", value: store.date.text, action: datePopover)` (the graphical date picker in a popover, any date); "Time (optional)" over two `TileRow`s Starts and Ends with `PickerValue(startTime?.text ?? "Not set")` opening the 24-hour wheel popover with Clear (Phase 3's `TimeTile`), the `FieldMessage(timeError)` under them; `NotesWell(label: "Note (optional)", text: $store.note, placeholder: "Anything to remember", limit: EventDraft.noteLimit)`; when editing, `Button { dialog = .delete } label: { Label("Delete event", systemImage: "trash") }.buttonStyle(.destructive())` at the bottom; the dialog `DialogView(title: "Delete this event?", message: "\(title) on \(date.shortWeekdayText) leaves the schedule. Classes are not affected.", action: "Delete", destructive: true, loading: deleting, onCancel:onAction:)` drawn over `dim` inside the sheet as `ClassFormSheet` draws its archive dialog; Cancel with changes asks "Discard changes?" (Keep editing / Discard) as the other forms. Board states: `saturday` selects 10 October; `newEvent` opens the sheet filled with Parents' meeting on the 10th (a `prefill` on `EventFormStore` for the board, as the student form's filled state); `editEvent` opens Edit for `FakeEventsRepository.parentsMeeting`; `deleteConfirm` opens Edit with the dialog up; `openEvent` (the deep link) opens Edit for that id once the events are loaded, or shows the toast "That event is no longer here." and stays on the month.

`CalendarMonth`: add the `Day`-based initialiser (converting through `calendar`), keep the existing ones; `monthDays` unchanged.

`TabsView`: `Route.schedule` builds `scheduleView(openEvent: nil)`, `Route.event(id)` builds `scheduleView(openEvent: id)`; both on every tab's stack. `TabsState.open(.event(id))` selects More and sets `[.schedule, .event(id)]`. `RootView.todayView`'s `openLater(.schedule)` becomes `shell.tabs.push(.schedule)` (the enum case `LaterTarget.schedule` goes; `TodayActions` gains `openSchedule`).

- [ ] **Step 4: Run, photograph, commit; open PR 6**

```bash
bun check
for s in schedule schedule-day event-new event-edit event-delete-confirm; do bun shots $s; done
bun pr-shots phase-4-schedule .shots/*/*.png
git add ios
git commit -m "Schedule: the month with its marked days, a chosen day, new and edit event, delete; the event link; Today's Schedule opens it"
git push -u origin phase-4/schedule
gh pr create --title "Schedule: the month, a day, events add, edit and delete; the event link" --body "<the pr-shots table>"
```

### Task 16: Prove the event write path against the local stack in Swift (PR 6, before merge)

- [ ] **Step 1:** With the stack up, a throwaway `ScheduleTests` test with a live `SupabaseClient` and the seed's tutor: `ScheduleStore.add` a draft, `update` it, `delete` it; `#expect` each answer and `docker exec supabase_db_tutor_central psql -U postgres -c "select title, date, start_time from calendar_events order by updated_at desc limit 3"` between steps. Delete the test; `supabase db reset`.
- [ ] **Step 2:** Merge PR 6 when green and the pictures match their boards.

### Task 17: `TasksStore`, the Tasks screen, the inline add (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Features/Today/TasksStore.swift`, `TasksView.swift`, `TaskInlineAdd.swift`
- Modify: `AppShell/ShellState.swift` (`tasks`), `TabsState.swift` (`Route.tasks`), `TabsView.swift`, `RootView.swift` (`tasksStore(for:)`, `tasksView`), `LaterView.swift` (`tasks` removed), `LaunchState.swift` (`tasks`, `tasksEmpty = "tasks-empty"`), `Fixtures.swift`
- Test: `ios/TutorCentralKit/Tests/TodayTests/TasksStoreTests.swift`; `LaunchStateTests` (`theTasksStatesPushOnTheMoreTab`)

**Interfaces:**

```swift
@MainActor @Observable public final class TasksStore {
    public private(set) var tasks: [TaskItem]; public private(set) var loading: Bool; public private(set) var error: String?
    public var message: String?; public private(set) var canRetry: Bool; public private(set) var lastSavedAt: Date?
    public var newTitle: String; public var newDue: Day?; public var adding: Bool          // the inline add's state (shared by Today and the Tasks screen)
    public var open: [TaskItem]; public var done: [TaskItem]; public var onToday: [TaskItem]
    public var openTitle: String                                                            // "2 to do" / "1 to do" / "Nothing to do"
    public var dueChips: [(label: String, day: Day?)]                                       // [("Fri 9 Oct", next weekday), ("No date", nil)]; "Tomorrow" when the next weekday is tomorrow
    public func trailing(for task: TaskItem) -> (text: String, tone: StatusTone?)?          // due words (overdue in .overdue) or the done day
    public var canAdd: Bool                                                                 // a trimmed title, at most 200
    public func load() async; public func add() async -> Bool; public func cancelAdd(); public func setDone(_ id: UUID, _ done: Bool) async; public func clearDone() async; public func retryLast() async
    public init(workspace: Workspace, tasks: any TasksRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
public struct TasksView: View { public init(store: TasksStore, boardState: TasksBoardState? = nil) }   // the screen under More
public enum TasksBoardState: Sendable { case adding }
public struct TaskInlineAdd: View { public init(store: TasksStore, showsFocus: Bool, autofocus: Bool) }   // InlineAdd bound to the store; Add commits, the section's Cancel cancels
```

- [ ] **Step 1: Write the failing tests**

```swift
import Data
import Domain
import Foundation
import Testing
@testable import Today

@MainActor struct TasksStoreTests {
    let repo = FakeTasksRepository(tasks: FakeTasksRepository.seed)
    func make() async -> TasksStore {
        let store = TasksStore(workspace: FakeCentreRepository.meeraWorkspace, tasks: repo, now: { FakeCountsRepository.fixedNow })
        await store.load()
        return store
    }

    @Test func theListsAsTheBoardsDrawThem() async {
        let store = await make()
        #expect(store.open.map(\.title) == ["Call Dev's father about Saturday", "Buy chalk and dusters"] && store.openTitle == "2 to do")
        #expect(store.done.map(\.title) == ["Order Class 8 workbooks", "Send September report to parents"])
        #expect(store.onToday.map(\.title) == ["Call Dev's father about Saturday", "Buy chalk and dusters"], "done on the 6th and 1st: off Today by the 7th")
        #expect(store.trailing(for: store.open[0])! == (text: "Fri 9 Oct", tone: nil) && store.trailing(for: store.open[1]) == nil)
        #expect(store.trailing(for: store.done[0])! == (text: "Tue 6 Oct", tone: nil))
        #expect(store.dueChips.map(\.label) == ["Tomorrow", "No date"], "Wednesday's next weekday is Thursday")
    }

    @Test func addingIsOptimisticAndRollsBack() async {
        let store = await make()
        store.adding = true
        store.newTitle = "  Print worksheets for Class 8 "
        store.newDue = Day(year: 2026, month: 10, day: 9)
        #expect(store.canAdd)
        #expect(await store.add())
        #expect(store.open.last?.title == "Print worksheets for Class 8" && repo.created.count == 1 && !store.adding && store.newTitle.isEmpty)
        store.adding = true
        store.newTitle = "Lost one"
        repo.nextError = URLError(.notConnectedToInternet)
        #expect(await store.add() == false)
        #expect(!store.open.contains { $0.title == "Lost one" } && store.message == "Couldn't add the task. Check your connection and try again." && store.canRetry)
        #expect(store.newTitle == "Lost one" && store.adding, "the typing stays")
        await store.retryLast()
        #expect(store.open.contains { $0.title == "Lost one" } && repo.created.count == 2)
    }

    @Test func doneAndClear() async {
        let store = await make()
        let chalk = store.open[1]
        await store.setDone(chalk.id, true)
        #expect(store.done.first?.id == chalk.id && store.onToday.last?.id == chalk.id, "just done: still on Today, at the end")
        await store.setDone(chalk.id, false)
        #expect(store.open.contains { $0.id == chalk.id })
        await store.clearDone()
        #expect(store.done.isEmpty && repo.cleared == 1 && store.tasks.count == 2)
        repo.nextError = URLError(.notConnectedToInternet)
        await store.setDone(chalk.id, true)
        #expect(!store.open.first { $0.id == chalk.id }!.isDone && store.message == "Couldn't update the task. Check your connection and try again.")
    }

    @Test func overdueReadsInTheOverdueTone() async {
        let store = await make()
        store.newTitle = "Late"
        store.newDue = Day(year: 2026, month: 10, day: 5)
        _ = await store.add()
        #expect(store.open.first?.title == "Late" && store.trailing(for: store.open[0])! == (text: "Mon 5 Oct", tone: .overdue))
    }
}
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL, `TasksStore` not found.

- [ ] **Step 3: Implement**

`TasksStore`: `load()` reads `tasks.tasks(centre:)` (loading flag, "Couldn't load your tasks. Check your connection and try again." on failure). `open = TaskOrdering.open(tasks)`, `done = TaskOrdering.done(tasks)`, `onToday = TaskOrdering.onToday(tasks, now: now())`. `dueChips`: the next weekday after today (`adding: 1 … 3` days until `weekday` is Monday to Friday) labelled "Tomorrow" when it is tomorrow else `shortWeekdayText`, then "No date"; `newDue` defaults to nil (No date on). `add()` trims the title, appends a placeholder (`createdAt: now()`), calls `tasks.create(title:dueDate:centre:)`, replaces the placeholder, clears the field and `adding`; on failure removes the placeholder, keeps the field, sets `message` and `lastFailed`. `setDone` flips `doneAt` optimistically (`now()` / nil), calls `tasks.setDone`, replaces with the answer, rolls back with "Couldn't update the task…". `clearDone` removes the done ones optimistically, calls `clearDone`, restores on failure with "Couldn't clear the done tasks…". Success sets `lastSavedAt` (the view plays `.success`).

`TasksView` (P4-Tasks, -Empty): pushed on More, tab bar hidden, navigation row "Tasks"; `TaskInlineAdd(store:showsFocus:autofocus:)` at the top (on this screen the well is always shown; its chip row and Add appear while `adding`, which a tap on the well sets); `SectionHeader(store.openTitle)` and a `Card` of `TaskRow`s (`toggle: setDone(id, true)`, swipe trailing "Done" with `checkmark`, the row in a `List`-free `Card`: use `.swipeActions` is unavailable outside `List`, so the row's `contextMenu` offers "Mark done" and the checkbox is the main control; `guidelines.md`'s "swipe actions have a visible alternative" is met by the checkbox); when open is empty and done is empty, one `Card` with `EmptyRow(symbol: "checkmark.circle", title: "Nothing on your list", line: "Add a task when there's something to remember. Done tasks stay here until you clear them.")`; `SectionHeader("Done", action: ("Clear", clearDone))` and a `Card` of done `TaskRow`s (`toggle: setDone(id, false)`), shown only when there are done tasks.

`TaskInlineAdd`: `InlineAdd(text: $store.newTitle, placeholder: "Add a task", focused:, dueChips: store.dueChips.map { chip in (chip.label, store.newDue == chip.day, { store.newDue = chip.day }) }, add: (store.canAdd, { Task { await store.add() } }))`.

`ShellState.tasks: TasksStore?` (`@ObservationIgnored`, reset with the rest); `RootView.tasksStore(for:)`; `Route.tasks` on every tab's stack (More pushes it; Today's "Add" does not push, it opens the inline field). `Fixtures`: `tasksEmpty` gets `FakeTasksRepository()`.

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios
git commit -m "Tasks: the store, the Tasks screen under More, the inline add"
```

### Task 18: Today live: the next class, today's classes, coming up, tasks; U1 to U4 (PR 7)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Features/Today/TodayStore.swift`, `TodayView.swift`; create `TodaySections.swift`
- Modify: `DesignSystem/Components/StatTile.swift` (fills its height, U4), `AppShell/RootView.swift` (`todayView` with the four repositories and the actions), `Features/Today/TodayActions.swift` (`openSchedule`, `openMarkAttendance(UUID)`, `openClass(UUID)`, `openEvent(UUID)`; `openLater` goes), `LaunchState.swift` (`today`, `todayEvening = "today-evening"`, `todayNoClass = "today-no-class"`, `todayAddingTask = "today-adding-task"`), `Fixtures.swift` (`clock(for:)`), `Features/Students/StudentsView.swift`, `Features/Attendance/AttendanceView.swift`, `AppShell/MoreView.swift` (Task 19) all take `.statusBarGlass()`
- Test: `ios/TutorCentralKit/Tests/TodayTests/TodayStoreTests.swift` (rewritten for the live store)

**Interfaces:**

```swift
@MainActor @Observable public final class TodayStore {
    // kept: heading, greeting, initials, counts, loading, error, workspaceChanged(_:), load()
    public private(set) var nextClass: NextClass?
    public var hero: (eyebrow: String, accent: Bool, title: String, line: String, canMark: Bool)?   // nil when the centre has no class with days ("Start here" stays for an empty register: see below)
    public var todayRows: [(classroom: Classroom?, event: CalendarEvent?, start: String, end: String?, title: String, line: String, lineTone: StatusTone?, marked: Bool)]
    public var comingUp: [(event: CalendarEvent, day: String, line: String)]
    public var showsStartHere: Bool                       // no students and no classes: Phase 2's card stays (the empty register's first step), else never
    public func tick(_ now: Date)                         // the minute clock: recomputes nextClass
    public init(workspace: Workspace, counts: any CountsRepository, register: RegisterStore, attendance: any AttendanceRepository, events: any EventsRepository, tasks: TasksStore, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india)
}
```

- [ ] **Step 1: Write the failing tests**

`TodayStoreTests.swift`, rewritten (keep the three Phase 2 tests, adjusted for the new initialiser; add):

```swift
    static func clock(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func makeLive(now: Date, sessions: [AttendanceSession] = FakeAttendanceRepository.seed) async -> TodayStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        let tasks = TasksStore(workspace: FakeCentreRepository.meeraWorkspace, tasks: FakeTasksRepository(tasks: FakeTasksRepository.seed), now: { now })
        let store = TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace, counts: FakeCountsRepository(counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)),
            register: register, attendance: FakeAttendanceRepository(sessions: sessions), events: FakeEventsRepository(events: FakeEventsRepository.seed), tasks: tasks, now: { now }
        )
        await store.load()
        return store
    }

    @Test func aClassSoon() async throws {
        let store = await makeLive(now: Self.clock(7, 16, 35))
        #expect(store.greeting == "Good afternoon, Meera" && store.heading == "Wednesday 7 October")
        let hero = try #require(store.hero)
        #expect(hero.eyebrow == "Next class · in 25 min" && hero.accent && hero.title == "Class 10 Maths" && hero.line == "17:00–18:00 · 6 students" && hero.canMark)
        #expect(store.todayRows.map(\.title) == ["Class 10 Maths"] && store.todayRows[0].line == "Mon, Wed, Fri · 6 students" && !store.todayRows[0].marked)
        #expect(store.comingUp.map(\.day) == ["Sat 10"] && store.comingUp[0].line == "11:00–12:00 · Class 10 parents")
        #expect(!store.showsStartHere)
    }

    @Test func theEveningAfterTheClass() async throws {
        let store = await makeLive(now: Self.clock(7, 19, 30), sessions: FakeAttendanceRepository.seedWithToday)
        let hero = try #require(store.hero)
        #expect(store.greeting == "Good evening, Meera" && hero.eyebrow == "Next class · tomorrow" && !hero.accent && hero.title == "Class 8 Science")
        #expect(hero.line == "Thu 8 Oct · 16:30–17:30 · 3 students" && !hero.canMark)
        #expect(store.todayRows[0].line == "5 of 6 present" && store.todayRows[0].lineTone == .ok && store.todayRows[0].marked)
    }

    @Test func aSaturdayWithNoClass() async throws {
        let store = await makeLive(now: Self.clock(10, 9, 30))
        let hero = try #require(store.hero)
        #expect(store.greeting == "Good morning, Meera" && hero.eyebrow == "No classes today" && hero.title == "Next class on Monday" && hero.line == "Class 10 Maths · Mon 12 Oct · 17:00–18:00")
        #expect(store.todayRows.map(\.title) == ["Parents' meeting"] && store.todayRows[0].start == "11:00" && store.todayRows[0].end == "12:00")
        #expect(store.comingUp.map(\.day) == ["Sat 17"])
    }

    @Test func theClockTicksTheCountdown() async {
        let store = await makeLive(now: Self.clock(7, 16, 35))
        store.tick(Self.clock(7, 16, 50))
        #expect(store.hero?.eyebrow == "Next class · in 10 min")
        store.tick(Self.clock(7, 17, 0))
        #expect(store.hero?.eyebrow == "Now · until 18:00")
    }

    @Test func anEmptyRegisterKeepsStartHere() async {
        let register = RegisterStore(workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(), cache: nil, now: { FakeCountsRepository.fixedNow })
        await register.load()
        let tasks = TasksStore(workspace: FakeCentreRepository.meeraWorkspace, tasks: FakeTasksRepository(), now: { FakeCountsRepository.fixedNow })
        let store = TodayStore(workspace: FakeCentreRepository.meeraWorkspace, counts: FakeCountsRepository(), register: register, attendance: FakeAttendanceRepository(), events: FakeEventsRepository(), tasks: tasks, now: { FakeCountsRepository.fixedNow })
        await store.load()
        #expect(store.showsStartHere && store.hero == nil && store.todayRows.isEmpty)
    }
```

- [ ] **Step 2: Run to see them fail**

Run: `bun check --only=ios`
Expected: FAIL.

- [ ] **Step 3: Implement**

`TodayStore.load()`: `async let` the counts, `register.loadIfNeeded()`, this month's sessions, the events from today to today + 7, and `tasks.load()`; then `tick(now())`. `tick(_:)`: `nextClass = NextClass.find(in: register.activeClasses, now:, calendar:)`. `hero` from `nextClass`: `.soon`/`.running`: eyebrow from the rule, accent true, title the class name, line `"\(timeRange) · \(members) students"`, canMark true; `.laterToday`: accent false, canMark false; `.tomorrow(c)`: title the class, line `"\(tomorrow.shortWeekdayText) · \(timeRange) · \(n) students"`; `.onDay(c, day)`: title `"Next class on \(weekday name)"`, line `"\(c.name) · \(day.shortWeekdayText) · \(timeRange)"`; nil when `nextClass` is nil. `todayRows`: today's classes (`NextClass.classesToday`) as in the schedule store (marked from the sessions), then today's events (`CalendarEvent.on`). `comingUp` as the schedule store's. `showsStartHere = register.activeStudents.isEmpty && register.activeClasses.isEmpty && register.loaded` (expose `loaded` on `RegisterStore` as `public private(set)`).

`TodayView` (P4-Today-Soon dark and light, -Evening, -NoClass, -AddingTask; `today-empty` keeps P2's board for the empty register): the header unchanged; the tiles `HStack(spacing: Tokens.tileGap) { … }.fixedSize(horizontal: false, vertical: true)` with `StatTile`'s `VStack` taking `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)` and the label pinned at the bottom by a `Spacer(minLength: 0)` between value and label (U4); `startHere` only when `store.showsStartHere` (U2); the hero `Card(.hero)` with `Eyebrow(hero.eyebrow, accent: hero.accent, strong: hero.accent)`, `Text(title).typeStyle(Tokens.title2)`, `Text(line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color).monospacedDigit()`, and when `canMark` a `Button { actions.openMarkAttendance(classID) } label: { Label("Mark attendance", systemImage: "checkmark.circle") }.buttonStyle(.primary(size: .card))`; `section("Today", action: ("Schedule", actions.openSchedule))` with a `Card` of `ScheduleRow`s (classes → `actions.openClass`) and `EventRow`s (→ `actions.openEvent`), or `EmptyRow(symbol: "calendar", title: "Nothing today", line: "No classes meet today and there are no events.")` (U3: the row and the tile now agree); `section("Coming up")` only when `comingUp` is not empty; `section("Tasks", action: adding ? ("Cancel", cancel) : ("Add", startAdding))` with a `Card` holding `TaskInlineAdd` as its first row while `tasks.adding` and the `onToday` `TaskRow`s, or `EmptyRow("Nothing on your list", "Add a task when there's something to remember.")`. `TimelineView(.everyMinute) { context in … }` wraps the hero and the Today section and calls `store.tick(context.date)` through `.onChange(of: context.date)` (`launch != nil` fixes the clock, so the fixtures never tick past their moment: `tick` is skipped when `deps.now` is fixed, which `Fixtures` signals with `Dependencies.fixedClock: Bool`). The `ScrollView` takes `.statusBarGlass()` (U1); so do `StudentsView`, `AttendanceView` and `MoreView`. The toast for `tasks.message` as the other stores'.

`Fixtures.clock(for:)`: `today`, `todayAddingTask` → 16:35 on 7 October; `todayEvening` → 19:30 (with `seedWithToday`); `todayNoClass` → 09:30 on 10 October; everything else `FakeCountsRepository.fixedNow`. `Fixtures.dependencies(for:)` passes `now: { clock(for: state) }` and `fixedClock: true`. The `todayAddingTask` board state sets `tasks.adding = true`, `newTitle = "Print worksheets for Class 8"`, `newDue = Fri 9 Oct`, and scrolls the Tasks section to the top (`ScrollViewReader` with an id on the Coming up section; the glass then shows).

- [ ] **Step 4: Run, format, lint, commit**

```bash
bun check --only=format,lint,ios
git add ios
git commit -m "Today live: the next class with its countdown, today's classes and events, coming up, tasks inline; the status bar on glass (U1), Start here only for an empty register (U2, U3), tiles share a height (U4)"
```

### Task 19: The More root; the Phase 4 states photographed (PR 7)

**Files:**
- Create: `ios/TutorCentralKit/Sources/AppShell/MoreView.swift`
- Modify: `TabsView.swift` (the More root), `RootView.swift`, `RootView+LaunchStates.swift`, `LaunchState.swift` (`more`), `LaterView.swift` (`.tab(.more)` goes; `.tab(.fees)` stays), `docs/design/information-architecture.md` (only if a state name must change)
- Test: `LaunchStateTests` (`theMoreStateOpensTheTab`, and `everyBoardStateHasAFixture` keeps covering the 24 new cases)

- [ ] **Step 1: Write the failing test**

```swift
    @MainActor @Test func theMoreAndTodayStatesStartReady() {
        for state in [LaunchState.more, .today, .todayEvening, .todayNoClass, .todayAddingTask, .tasks, .tasksEmpty] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
        }
        #expect(RootView.tab(for: .more) == .more && RootView.initialRoutes(for: .tasks) == [.tasks] && RootView.tab(for: .tasks) == .more)
        #expect(RootView.tab(for: .today) == nil, "Today is the default tab")
        #expect(Fixtures.clock(for: .todayNoClass) == DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 9, minute: 30)))
    }
```

- [ ] **Step 2: Run to see it fail**, then

- [ ] **Step 3: Implement**

`MoreView` (P4-More dark and light): `ScrollView` with `.statusBarGlass()`, `Text("More").typeStyle(Tokens.display)`, three sections of `SectionHeader` and `Card`: Organise (`SettingRow(symbol: "calendar", label: "Schedule") { push(.schedule) }`, `SettingRow(symbol: "checkmark.circle", label: "Tasks") { push(.tasks) }`, `SettingRow(symbol: "book.closed", label: "Classes") { push(.classes) }`, `LaterRow(symbol: "chart.bar", label: "Reports", phase: "Phase 5")`), Create (`LaterRow`s: `sparkles` "AI Assistant", `doc.text.magnifyingglass` "Check a paper", `doc.viewfinder` "Scan register", all "Phase 6"), App (`SettingRow(symbol: "gearshape", label: "Settings") { push(.settings) }`, `LaterRow(symbol: "person.crop.circle", label: "Account", phase: "Phase 7")`, `LaterRow(symbol: "questionmark.circle", label: "Help", phase: "Phase 7")`). `LaterRow` is `SettingRow` with `trailing: { Text(phase).typeStyle(Tokens.captionStrong).foregroundStyle(Tokens.text3.color) }` and no action, at `Tokens.opacityLater` (P2-Settings's pattern; add it to `Rows.swift` as `LaterRow`). The tab bar stays. `Route.classes` and `.classroom` on the More stack use the shared register (`TabsView` already builds them per tab).

- [ ] **Step 4: Run, photograph everything this PR changes, commit; open PR 7**

```bash
bun check
for s in today today-evening today-no-class today-adding-task tasks tasks-empty more students today-empty; do bun shots $s; done
bun pr-shots phase-4-today-live .shots/*/*.png
git add ios
git commit -m "The More root; the Phase 4 launch states; Students and Attendance roots on the status-bar glass"
git push -u origin phase-4/today-live
gh pr create --title "Tasks, Today live (U1 to U4), the More root" --body "<the pr-shots table>"
```

Before merging, prove the task write path against the local stack in Swift (add, done, clear, as Task 8 step 4). Merge when green and the pictures match the boards; `plan/ui-polish.md` moves U1 to U4 to "Done" with this pull request's number in the documents commit of Task 20.

### Task 20: Deploy, the hand runs, TestFlight; the documents (main)

- [ ] **Step 1: Production.** `gh workflow run deploy` (0004 went up after PR 2; the run summary must say nothing is pending). Then `git checkout main && git pull`.
- [ ] **Step 2: The hand runs (D32),** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed, signed in as Meera, every write confirmed in the database, every screenshot kept in `.shots/run/` and attached to the phase's issue (open one: "Phase 4 hand run"):

| Run | Through the screens | Confirm |
|---|---|---|
| Mark fresh | Attendance tab: Class 10 Maths today, tap Hemanth (Absent), Save attendance | `select date, class_id, saved_at from attendance_sessions order by saved_at desc limit 1`; `select status, count(*) from attendance_marks where session_id = … group by status` → 5 present, 1 absent |
| Correct and save again | Tap Hemanth (Present), Save changes | the same session id; 6 present; `saved_at` moved |
| All students | Class → All students, Save attendance | a second session for the day with `class_id` null and 10 marks |
| Past date | Date → Mon 5 Oct (the seed's), the banner, tap Bir Bikram, Save changes | the seed's session now has Bir absent |
| Tell parent | Back on today with Hemanth absent: Tell parent, Open WhatsApp (the simulator has no WhatsApp: the link opens Safari or nothing; the row then reads Told today) | `select kind, student_id, opened_at from message_log order by opened_at desc limit 1` → absence, Hemanth |
| History | History: by date, by student (Lowest first), Hemanth's month, back | reads only |
| Event | More → Schedule: "+", New event "Parents' meeting" Sat 10 Oct 11:00–12:00 with the note, Save; open it, change the note, Save; open it, Delete event, Delete | `select title, date, start_time, end_time, note from calendar_events` after each step; empty at the end |
| Task | Today: Add, "Print worksheets for Class 8", Fri 9 Oct, Add; tick it done; More → Tasks: Clear | `select title, due_date, done_at from tasks order by created_at desc limit 1` after each step; the row gone at the end |
| Links | `xcrun simctl openurl booted "tutorcentral://attendance?date=2026-10-05&class=<maths id>"`; `tutorcentral://event/<an event id>` | the screens open as the IA says |

- [ ] **Step 3: TestFlight.** `gh workflow run testflight`; the build number from the run; the owner installs it.
- [ ] **Step 4: Documents (D12), one commit to `main`:** `plan/phase-04-attendance-schedule-today.md` "As built" (the PR table, acceptance line by line, deviations and why, what remains); `plan/README.md` (Phase 4 done; any decision the build numbered); `plan/STATE.md`; `plan/ui-polish.md` (U1 to U4 to Done with PR 7; anything seen in passing added to Open); `docs/design/components.md` and `information-architecture.md` where the build corrected a board's words; `ios/CLAUDE.md` rules learned; `plan/sessions/009/record.md` and `owner-messages.md`; then ask for a reviewer pass on the seven merged pull requests with `superpowers:requesting-code-review` and record its outcome.

---

## Self-review

- **Spec coverage.** Phase file scope 1 (mark: date today or past, class or all, everyone present, tap to mark absent, counts, save, a saved class reopens, the absence alert per absent student from the saved session, each logged): Tasks 1, 4, 5, 6, 10, 11. Scope 2 (history by date with counts opening a session; by student with the monthly percentage and the absences; the student detail reads from here): Tasks 1, 12, 13. Scope 3 (month grid with marks; the day's classes from meeting days with times; the day's events; add, edit, delete an event with title, date, start and end, note): Tasks 2, 3, 7, 14, 15. Scope 4 (inline add on Today; done by tap, the swipe's visible alternative being the checkbox; optional due date; done tasks fall off after a day; a Tasks screen under More): Tasks 3, 8, 17, 18. Scope 5 (greeting by time of day: Phase 2's `Greeting`; tiles with real counts, tappable: Phase 2, kept; next class with the time until it starts and Mark attendance; today's classes; upcoming events for the week, as "Coming up", the next seven days; tasks; the AI tools row: Phase 6's board, as Phase 2 ruled): Tasks 2, 18. Scope 6 (next class from meeting days and the clock; occurrences in a month; percentage; "time until" wording; task ordering): Tasks 1 to 3, every rule tested. Acceptance: pictures in PRs 4 to 7; two taps all present (open the tab, Save) and three with one absent (Task 11's layout: Save in the footer, never a scroll); the alert opens WhatsApp with the right parent (Task 4's link, Task 10's `tell`); the next class across midnight and on a day with no class (Task 2's `sundayNightLooksToMonday`, `aSaturdayWithNoClass` in Task 18); domain tests cover item 6. Inventory rows: all placed (Global Constraints, last line). U1 to U4: Task 18 (U1 across the four roots, U2, U3, U4). D32: Task 20's table names every write path.
- **Placeholders.** The views (Tasks 11, 13, 15, 17 to 19) are given as their pieces with the exact components, tokens, copy and wiring, as the Phase 3 plan gave its screens; every number is a token or a named anatomy constant and every word is on a board. Task 12 corrects its own fixture numbers in the text rather than leaving a wrong expectation. No "TBD", no "handle edge cases".
- **Type consistency.** `AttendanceSession.marks: [UUID: AttendanceStatus]` (Task 1) is what `SessionRow` (Task 6), `AttendanceDraft` (Task 1) and `AttendanceStore` (Task 10) use; `AttendanceRepository.save` returns the session (Task 6) and `AttendanceStore.save` stores it. `NextClass.find(in:now:calendar:)` and `classesToday` (Task 2) are what `TodayStore` (Task 18) and `ScheduleStore` (Task 14) call. `CalendarEvent.comingUp(_:after:days:calendar:)` and `on(_:in:)` (Task 3) serve both stores. `TaskOrdering.onToday(_:now:)` (Task 3) is `TasksStore.onToday` (Task 17). `AbsenceMessage.text(parentName:studentName:className:day:today:tutorName:centreName:)` and `whatsAppURL(phone:text:)` (Task 4) are what `AttendanceStore.alert(for:)` calls (Task 10). `Period.previousDayISO` (Task 6) and `monthName` (Task 12) are added where first used, with tests. `RegisterStore.loaded` becomes public in Task 18. `LaunchState` raw values match `information-architecture.md`'s Phase 4 table; `today-empty` keeps Phase 2's board for an empty register (`showsStartHere`). The `AttendanceRow` signature changes in Task 9 and the Kit follows in the same commit. `TodayActions` loses `openLater` in Task 18 (Task 15 already rerouted `.schedule`; `.tasks` and `.students` end with Task 18).
- **Review Focus.** 1 → Task 2 `theNextClassAcrossTheDay`, `aClassWithoutATimeHasNoCountdown`, `sundayNightLooksToMonday`. 2 → Task 5 `save_attendance makes the session and replaces its marks`, `keeps all-students and a class apart`; Task 10 `savingAgainReplacesTheMarks`, `aNewMemberIsPresentOnReopen`, `allStudentsIsItsOwnSession`, `aFailedSaveKeepsTheMarksAndOffersRetry`. 3 → Task 1 `noMarksIsNotZeroPercent`, `theMonthSummaryCountsMarks`; Task 12's November expectations. 4 → Task 4 `theLinkCarriesTheMessageEncoded`; Task 10 `tellingAParentLogsOnce`, `aStudentWithoutANumberCannotBeTold`. 5 → Task 3 `doneTasksStayADay`, `dueWordsAndOverdue`, `comingUpIsTheNextSevenDays`; Task 7 `aDateDecodesAsADayNotAMoment`.
