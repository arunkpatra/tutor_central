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

    func input(
        _ settings: ReminderSettings = ReminderSettings(), events: [CalendarEvent] = [], dueFees: DueFees? = nil
    ) -> ReminderInput {
        ReminderInput(
            classes: [maths], memberCounts: [maths.id: 6], events: events, dueFees: dueFees, settings: settings
        )
    }

    @Test func aClassRemindsBeforeEachMeetingOfTheNextFourteenDays() {
        let plan = ReminderPlanner.plan(input(), now: at(7, 16, 35), calendar: calendar) // Wed 7 Oct
        let classes = plan.filter { $0.kind == .classMeeting }
        #expect(classes.first?.fireAt == at(7, 16, 45))
        #expect(classes.first?.title == "Class 10 Maths at 17:00" && classes.first?.subject == "Class 10 Maths")
        #expect(classes.first?.body == "In 15 minutes · 6 students. Tap to mark attendance.")
        let link = "tutorcentral://attendance?date=2026-10-07&class=\(maths.id.uuidString.lowercased())"
        #expect(classes.first?.link == link)
        #expect(classes.count == 6) // Wed 7, Fri 9, Mon 12, Wed 14, Fri 16, Mon 19 (Wed 21 is day 15)
    }

    @Test func anHourLeadAndOneStudentReadAsTheyShould() {
        var settings = ReminderSettings()
        settings.classMinutesBefore = 60
        let one = ReminderInput(
            classes: [maths], memberCounts: [maths.id: 1], events: [], dueFees: nil, settings: settings
        )
        let first = ReminderPlanner.plan(one, now: at(7, 9), calendar: calendar).first
        #expect(first?.body == "In 1 hour · 1 student. Tap to mark attendance." && first?.fireAt == at(7, 16))
    }

    @Test func pastAndUntimedMeetingsAreSkipped() {
        let late = ReminderPlanner.plan(input(), now: at(7, 16, 50), calendar: calendar)
        #expect(late.first { $0.kind == .classMeeting }?.fireAt == at(9, 16, 45))
        var untimed = maths
        untimed.startTime = nil
        let none = ReminderInput(
            classes: [untimed], memberCounts: [:], events: [], dueFees: nil, settings: ReminderSettings()
        )
        #expect(ReminderPlanner.plan(none, now: at(7, 9), calendar: calendar).isEmpty)
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
        #expect(event.body == "Sat 10 Oct, 11:00–12:00 · Class 10 parents." && event.subject == "Parents' meeting")
        #expect(event.link == "tutorcentral://event/\(meeting.id.uuidString.lowercased())")
        settings.eventLead = .dayBefore18
        let eve = ReminderPlanner.plan(input(settings, events: [meeting]), now: at(7, 9), calendar: calendar)
        let evening = try #require(eve.first { $0.kind == .event })
        #expect(evening.fireAt == at(9, 18) && evening.title == "Parents' meeting tomorrow")
    }

    @Test func anUntimedEventRemindsAtNineThatDay() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 10))
        let open = CalendarEvent(
            id: UUID(), title: "Open day", date: day, startTime: nil, endTime: nil, note: nil
        )
        let plan = ReminderPlanner.plan(input(events: [open]), now: at(7, 9), calendar: calendar)
        let event = try #require(plan.first { $0.kind == .event })
        #expect(event.fireAt == at(10, 9) && event.title == "Open day today" && event.body == "Sat 10 Oct.")
    }

    @Test func theFeeReminderNeedsADueFee() {
        let none = ReminderPlanner.plan(input(), now: at(1, 9), calendar: calendar)
        #expect(none.filter { $0.kind == .fees }.isEmpty)
        let due = DueFees(count: 4, total: Money(rupees: 4000))
        let some = ReminderPlanner.plan(input(dueFees: due), now: at(1, 9), calendar: calendar)
        let fees = some.filter { $0.kind == .fees }
        #expect(fees.map(\.fireAt) == [at(5, 9)])
        #expect(fees.first?.title == "4 fees still due for October")
        #expect(fees.first?.body == "₹4,000 to collect. Tap to remind parents.")
        #expect(fees.first?.link == "tutorcentral://fees?month=2026-10" && fees.first?.subject == "Fees still due")
        let one = DueFees(count: 1, total: Money(rupees: 800))
        let past = ReminderPlanner.plan(input(dueFees: one), now: at(6, 9), calendar: calendar)
        let next = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 9))
        let november = past.first { $0.kind == .fees }
        #expect(november?.fireAt == next && november?.title == "1 fee still due for November")
        #expect(november?.id == "fees-2026-11")
    }

    @Test func switchesOffDropTheirKind() {
        var settings = ReminderSettings()
        settings.classOn = false
        settings.feesOn = false
        let due = DueFees(count: 4, total: Money(rupees: 4000))
        let plan = ReminderPlanner.plan(input(settings, dueFees: due), now: at(7, 9), calendar: calendar)
        #expect(plan.isEmpty)
    }

    @Test func atMostSixtySoonestAreKept() {
        let classes = (0 ..< 6).map { _ in
            Classroom(
                id: UUID(), name: "Daily", subject: nil, monthlyFee: nil, meetingDays: Set(Weekday.allCases),
                startTime: TimeOfDay(hour: 8, minute: 0), endTime: nil, archivedAt: nil
            )
        } // 6 classes × 14 days = 84 meetings
        let input = ReminderInput(
            classes: classes, memberCounts: [:], events: [], dueFees: nil, settings: ReminderSettings()
        )
        let plan = ReminderPlanner.plan(input, now: at(7, 7), calendar: calendar)
        #expect(plan.count == ReminderPlanner.limit)
        #expect(plan == plan.sorted { $0.fireAt < $1.fireAt })
    }

    @Test func idsAreStableAcrossRuns() {
        let first = ReminderPlanner.plan(input(), now: at(7, 9), calendar: calendar).map(\.id)
        let second = ReminderPlanner.plan(input(), now: at(7, 9, 30), calendar: calendar).map(\.id)
        #expect(first == second && first.first == "class-\(maths.id.uuidString.lowercased())-2026-10-07")
    }

    @Test func theSettingsRoundTripWithTheirDefaults() throws {
        let defaults = ReminderSettings()
        #expect(defaults.classMinutesBefore == 15 && defaults.eventLead == .hour1 && defaults.feesDay == 5)
        let data = try JSONEncoder().encode(defaults)
        #expect(try JSONDecoder().decode(ReminderSettings.self, from: data) == defaults)
    }
}
