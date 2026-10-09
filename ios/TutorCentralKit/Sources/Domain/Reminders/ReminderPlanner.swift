import Foundation

/// Plans the tutor's reminders (P7-Reminders): before each class meeting, before each event, and once for the
/// month's unpaid fees. Pure: the scheduler (AppShell) hands the plan to the notification centre.
public enum ReminderPlanner {
    /// How far ahead meetings and events are planned.
    public static let days = 14
    /// iOS keeps 64 pending notifications; the soonest 60 are planned.
    public static let limit = 60

    /// Every reminder from `now` over the next 14 days, soonest first, at most 60; ids stable for the same input.
    public static func plan(_ input: ReminderInput, now: Date, calendar: Calendar) -> [Reminder] {
        let today = Day(now, calendar: calendar)
        let window = (0 ..< days).map { today.adding(days: $0, calendar: calendar) }
        var plan: [Reminder] = []
        if input.settings.classOn {
            plan += window.flatMap { day in
                input.classes.compactMap { meeting(of: $0, on: day, input: input, calendar: calendar) }
            }
        }
        if input.settings.eventOn {
            let inWindow = input.events.filter { window.contains($0.date) }
            plan += inWindow.compactMap { event(for: $0, lead: input.settings.eventLead, calendar: calendar) }
        }
        if input.settings.feesOn, let due = input.dueFees {
            plan.append(fees(due, day: input.settings.feesDay, now: now, calendar: calendar))
        }
        return Array(
            plan.filter { $0.fireAt > now }
                .sorted { ($0.fireAt, $0.id) < ($1.fireAt, $1.id) }
                .prefix(limit)
        )
    }

    private static func meeting(of room: Classroom, on day: Day, input: ReminderInput, calendar: Calendar)
        -> Reminder? {
        guard room.meetingDays.contains(day.weekday(in: calendar)), let start = room.startTime,
              let starts = time(start, on: day, calendar: calendar) else { return nil }
        let lead = input.settings.classMinutesBefore
        let students = input.memberCounts[room.id] ?? 0
        let studentsText = "\(students) \(students == 1 ? "student" : "students")"
        let id = room.id.uuidString.lowercased()
        return Reminder(
            id: "class-\(id)-\(day.iso)", kind: .classMeeting,
            title: "\(room.name) at \(start.text)",
            body: "In \(minutesText(lead)) · \(studentsText). Tap to mark attendance.",
            fireAt: starts.addingTimeInterval(-Double(lead) * 60),
            link: "tutorcentral://attendance?date=\(day.iso)&class=\(id)", subject: room.name
        )
    }

    private static func event(for event: CalendarEvent, lead: ReminderSettings.EventLead, calendar: Calendar)
        -> Reminder? {
        let when: String = switch (event.startTime, event.endTime) {
        case let (start?, end?): "\(event.date.shortWeekdayText), \(TimeOfDay.range(start, end))"
        case let (start?, nil): "\(event.date.shortWeekdayText), \(start.text)"
        case (nil, _): event.date.shortWeekdayText
        }
        let note = event.note?.split(separator: "\n").first.map(String.init)?.trimmingCharacters(in: .whitespaces)
        let joined = [when, note].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
        let body = joined.hasSuffix(".") ? joined : joined + "."
        let fire: Date?
        let title: String
        switch (lead.minutes, event.startTime) {
        case (nil, _):
            fire = time(
                TimeOfDay(hour: 18, minute: 0),
                on: event.date.adding(days: -1, calendar: calendar),
                calendar: calendar
            )
            title = "\(event.title) tomorrow"
        case let (minutes?, start?):
            fire = time(start, on: event.date, calendar: calendar)?.addingTimeInterval(-Double(minutes) * 60)
            title = "\(event.title) in \(minutesText(minutes))"
        case (_?, nil):
            fire = time(TimeOfDay(hour: 9, minute: 0), on: event.date, calendar: calendar)
            title = "\(event.title) today"
        }
        guard let fire else { return nil }
        return Reminder(
            id: "event-\(event.id.uuidString.lowercased())", kind: .event, title: title, body: body, fireAt: fire,
            link: "tutorcentral://event/\(event.id.uuidString.lowercased())", subject: event.title
        )
    }

    private static func fees(_ due: DueFees, day: Int, now: Date, calendar: Calendar) -> Reminder {
        let this = Period(year: calendar.component(.year, from: now), month: calendar.component(.month, from: now))
        let nine = { (period: Period) in
            calendar.date(from: DateComponents(year: period.year, month: period.month, day: day, hour: 9)) ?? now
        }
        let period = nine(this) > now ? this : this.next
        return Reminder(
            id: "fees-\(period.isoMonth)", kind: .fees,
            title: "\(due.count) \(due.count == 1 ? "fee" : "fees") still due for \(period.monthName)",
            body: "\(due.total.formatted) to collect. Tap to remind parents.",
            fireAt: nine(period),
            link: "tutorcentral://fees?month=\(period.isoMonth)", subject: "Fees still due"
        )
    }

    /// "15 minutes", "1 hour".
    private static func minutesText(_ minutes: Int) -> String {
        minutes == 60 ? "1 hour" : "\(minutes) minutes"
    }

    private static func time(_ time: TimeOfDay?, on day: Day, calendar: Calendar) -> Date? {
        guard let time else { return nil }
        return calendar.date(from: DateComponents(
            year: day.year, month: day.month, day: day.day, hour: time.hour, minute: time.minute
        ))
    }
}
