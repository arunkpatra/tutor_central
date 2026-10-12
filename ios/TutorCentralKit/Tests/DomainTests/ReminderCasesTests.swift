import Foundation
import Testing
@testable import Domain

/// The shared reminder cases (D80; plan/phase-18-plan.md Task 7): `ReminderPlanner.plan`'s reminders for an input, so
/// the
/// server's reminder plan (api/src/reminders/planner.ts) says and times them as the phone did. The settings carry the
/// account's names (`reminder_settings`: `min15`, `day_before`); kinds are the outbox's (`class`, `event`, `fees`).
struct ReminderCaseFile: Codable {
    var cases: [ReminderCase]
}

struct ReminderCase: Codable {
    struct Settings: Codable {
        var classOn = true
        var classMinutes = 60
        var eventsOn = true
        var eventLead = "hour1"
        var feesOn = true
        var feesDay = 5
    }

    struct ClassJSON: Codable {
        var id: String
        var name: String
        var days: [Int]
        var start: String?
        var end: String?
    }

    struct EventJSON: Codable {
        var id: String
        var title: String
        var date: String
        var start: String?
        var end: String?
        var note: String?
    }

    struct FeesJSON: Codable {
        var count: Int
        /// Rupees.
        var total: Int
    }

    struct Input: Codable {
        var now: String
        var settings: Settings
        var classes: [ClassJSON]
        var memberCounts: [String: Int]
        var events: [EventJSON]
        var dueFees: FeesJSON?
    }

    struct ReminderJSON: Codable, Equatable {
        var id: String
        var kind: String
        var title: String
        var body: String
        var at: String
        var link: String
        var subject: String
    }

    var name: String
    var input: Input
    var expected: [ReminderJSON]
}

private let file = CaseJSON.read("reminder-cases", as: ReminderCaseFile.self)

private func plan(_ input: ReminderCase.Input) throws -> [ReminderCase.ReminderJSON] {
    var settings = ReminderSettings()
    settings.classOn = input.settings.classOn
    settings.classMinutesBefore = input.settings.classMinutes
    settings.eventOn = input.settings.eventsOn
    settings.eventLead = switch input.settings.eventLead {
    case "min15": .minutes15
    case "min30": .minutes30
    case "day_before": .dayBefore18
    default: .hour1
    }
    settings.feesOn = input.settings.feesOn
    settings.feesDay = input.settings.feesDay
    let classes = try input.classes.map {
        try Classroom(
            id: CaseJSON.uuid($0.id), name: $0.name, subject: nil, monthlyFee: nil,
            meetingDays: CaseJSON.weekdays($0.days),
            startTime: CaseJSON.time($0.start), endTime: CaseJSON.time($0.end), archivedAt: nil
        )
    }
    let events = try input.events.map {
        try CalendarEvent(
            id: CaseJSON.uuid($0.id), title: $0.title, date: CaseJSON.day($0.date), startTime: CaseJSON.time($0.start),
            endTime: CaseJSON.time($0.end), note: $0.note
        )
    }
    var counts: [UUID: Int] = [:]
    for (key, count) in input.memberCounts {
        try counts[CaseJSON.uuid(key)] = count
    }
    let reminders = try ReminderPlanner.plan(
        ReminderInput(
            classes: classes, memberCounts: counts, events: events,
            dueFees: input.dueFees.map { DueFees(count: $0.count, total: Money(rupees: $0.total)) }, settings: settings
        ),
        now: CaseJSON.instant(input.now), calendar: DayHeading.india
    )
    return reminders.map { reminder in
        let kind = switch reminder.kind {
        case .classMeeting: "class"
        case .event: "event"
        case .fees: "fees"
        }
        return .init(
            id: reminder.id, kind: kind, title: reminder.title, body: reminder.body, at: CaseJSON.iso(reminder.fireAt),
            link: reminder.link, subject: reminder.subject
        )
    }
}

/// The reminder scenarios: the ten of ReminderPlannerTests as data, and the edges the server meets.
private struct ReminderCaseScenarios {
    let maths = "c0000000-0000-4000-8000-000000000101"
    let science = "c0000000-0000-4000-8000-000000000102"
    let meeting = "e0000000-0000-4000-8000-000000000201"
    let open = "e0000000-0000-4000-8000-000000000202"

    func classes(start: String? = "17:00") -> [ReminderCase.ClassJSON] {
        [.init(id: maths, name: "Class 10 Maths", days: [1, 3, 5], start: start, end: start == nil ? nil : "18:30")]
    }

    func input(
        _ now: String, settings: ReminderCase.Settings = .init(), classes: [ReminderCase.ClassJSON]? = nil,
        counts: [String: Int]? = nil, events: [ReminderCase.EventJSON] = [], fees: ReminderCase.FeesJSON? = nil
    ) -> ReminderCase.Input {
        .init(
            now: now, settings: settings, classes: classes ?? self.classes(), memberCounts: counts ?? [maths: 4],
            events: events, dueFees: fees
        )
    }

    func event(
        start: String? = "18:00",
        end: String? = "19:00",
        note: String? = "Bring the report cards\nand pens"
    ) -> ReminderCase.EventJSON {
        .init(id: meeting, title: "Parents meeting", date: "2026-10-09", start: start, end: end, note: note)
    }

    func all() -> [(name: String, input: ReminderCase.Input)] {
        meetings() + events() + fees() + switches()
    }

    func settings(_ change: (inout ReminderCase.Settings) -> Void) -> ReminderCase.Settings {
        var settings = ReminderCase.Settings()
        change(&settings)
        return settings
    }

    func meetings() -> [(name: String, input: ReminderCase.Input)] {
        let many = (1 ... 6).map {
            ReminderCase.ClassJSON(
                id: String(format: "c0000000-0000-4000-8000-%012d", 300 + $0), name: "Batch \($0)",
                days: [1, 2, 3, 4, 5, 6, 7], start: String(format: "%02d:00", 8 + $0), end: nil
            )
        }
        let evening = ReminderCase.ClassJSON(
            id: science,
            name: "Evening batch",
            days: [2, 4],
            start: "18:00",
            end: "19:30"
        )
        let same = [
            ReminderCase.ClassJSON(id: science, name: "B batch", days: [3], start: "17:00", end: nil),
            ReminderCase.ClassJSON(id: maths, name: "A batch", days: [3], start: "17:00", end: nil),
        ]
        let lead15 = settings { $0.classMinutes = 15 }
        return [
            ("a class reminds before each meeting of the next fourteen days", input("2026-10-07T16:35:00+05:30")),
            (
                "a fifteen-minute lead and one student",
                input("2026-10-07T09:00:00+05:30", settings: lead15, counts: [maths: 1])
            ),
            ("a meeting already begun is skipped", input("2026-10-07T16:50:00+05:30")),
            ("an untimed batch has no reminder", input("2026-10-07T09:00:00+05:30", classes: classes(start: nil))),
            ("two batches interleave, soonest first", input(
                "2026-10-07T09:00:00+05:30", classes: classes() + [evening], counts: [maths: 4, science: 2]
            )),
            (
                "more than sixty are cut to the soonest sixty",
                input("2026-10-07T07:00:00+05:30", classes: many, counts: [:])
            ),
            ("a reminder due at the same minute keeps its id order", input(
                "2026-10-07T09:00:00+05:30", classes: same, counts: [maths: 3, science: 3]
            )),
        ]
    }

    func events() -> [(name: String, input: ReminderCase.Input)] {
        let day = settings { $0.eventLead = "day_before" }
        let min30 = settings { $0.eventLead = "min30" }
        let openDay = ReminderCase.EventJSON(
            id: open, title: "Open day", date: "2026-10-10", start: nil, end: nil, note: "Doors at 10."
        )
        let sports = ReminderCase.EventJSON(id: open, title: "Sports day", date: "2026-10-30", start: "09:00")
        return [
            (
                "an event an hour before its start, with the note's first line",
                input("2026-10-07T09:00:00+05:30", events: [event()])
            ),
            ("an event the day before at 18:00", input("2026-10-07T09:00:00+05:30", settings: day, events: [event()])),
            ("an event thirty minutes before, with a start and no end", input(
                "2026-10-07T09:00:00+05:30", settings: min30, events: [event(end: nil, note: nil)]
            )),
            ("an untimed event reminds at nine that day", input("2026-10-07T09:00:00+05:30", events: [openDay])),
            ("an event outside the fourteen days is left out", input("2026-10-07T09:00:00+05:30", events: [sports])),
        ]
    }

    func fees() -> [(name: String, input: ReminderCase.Input)] {
        let tenth = settings { $0.feesDay = 10 }
        return [
            ("no fee due, no fee reminder", input("2026-10-01T09:00:00+05:30")),
            (
                "fees due remind on the 5th at nine",
                input("2026-10-01T09:00:00+05:30", fees: .init(count: 4, total: 4000))
            ),
            ("the fee day already past this month names next month", input(
                "2026-10-06T09:00:00+05:30", fees: .init(count: 1, total: 800)
            )),
            (
                "a fee day of the 10th",
                input("2026-10-01T09:00:00+05:30", settings: tenth, fees: .init(count: 2, total: 1500))
            ),
        ]
    }

    func switches() -> [(name: String, input: ReminderCase.Input)] {
        let off = settings {
            $0.classOn = false
            $0.feesOn = false
        }
        let allOff = settings {
            $0.classOn = false
            $0.eventsOn = false
            $0.feesOn = false
        }
        let due = ReminderCase.FeesJSON(count: 4, total: 4000)
        return [
            (
                "switches off drop their kind",
                input("2026-10-07T09:00:00+05:30", settings: off, events: [event()], fees: due)
            ),
            ("every switch off plans nothing", input(
                "2026-10-07T09:00:00+05:30", settings: allOff, events: [event()], fees: due
            )),
        ]
    }
}

@Test func theReminderCaseFileIsHereAndHoldsEveryScenario() throws {
    let file = try #require(file)
    #expect(file.cases.map(\.name) == ReminderCaseScenarios().all().map(\.name))
}

@Test(arguments: (file?.cases ?? []).map(\.name))
func everyReminderCaseIsWhatThePlannerPlans(name: String) throws {
    let item = try #require(file?.cases.first { $0.name == name })
    #expect(try plan(item.input) == item.expected, "\(name)")
}

/// Writes the case file: `TEST_RUNNER_TC_WRITE_REMINDER_CASES=<path> xcodebuild test
/// -only-testing:DomainTests/writeTheReminderCases`, then `bun contract`.
@Test(.enabled(if: ProcessInfo.processInfo.environment["TC_WRITE_REMINDER_CASES"] != nil))
func writeTheReminderCases() throws {
    let cases = try ReminderCaseScenarios().all().map {
        try ReminderCase(name: $0.name, input: $0.input, expected: plan($0.input))
    }
    try CaseJSON.write(ReminderCaseFile(cases: cases), to: "TC_WRITE_REMINDER_CASES")
}
