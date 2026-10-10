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
        case let .soon(_, minutes): "Next batch · \(TimeUntil.text(minutes: minutes))"
        case let .running(_, end): end.map { "Now · until \($0.text)" } ?? "Now"
        case let .laterToday(_, at): "Next batch · \(at?.text ?? "today")"
        case .tomorrow: "Next batch · tomorrow"
        case .onDay: "No batch today"
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
            if minute >= endMinute {
                continue
            }
            if minute >= startMinute {
                return .running(c, endsAt: c.endTime)
            }
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
            .sorted { lhs, rhs in
                switch (lhs.startTime, rhs.startTime) {
                case let (x?, y?) where x != y: x < y
                case (nil, _?): false
                case (_?, nil): true
                default: lhs.name < rhs.name
                }
            }
    }
}
