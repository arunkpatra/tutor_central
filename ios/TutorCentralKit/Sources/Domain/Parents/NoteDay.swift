import Foundation

/// The day and time a batch's weekly notes are read and sent (`classes.note_weekday`, `note_time`; P10-NoteDay-Change).
/// Sunday 18:00 unless the batch sets another (plan/phase-14-plan.md decision 4).
public struct NoteDay: Hashable, Sendable, Codable {
    public let weekday: Weekday
    public let time: TimeOfDay

    public init(weekday: Weekday, time: TimeOfDay) {
        self.weekday = weekday
        self.time = time
    }

    public static let `default` = NoteDay(weekday: .sunday, time: TimeOfDay(hour: 18, minute: 0)!)

    /// The wheel's five choices (P10-NoteDay-Change).
    public static let choices: [NoteDay] = [
        NoteDay(weekday: .friday, time: TimeOfDay(hour: 18, minute: 0)!),
        NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0)!),
        .default,
        NoteDay(weekday: .sunday, time: TimeOfDay(hour: 20, minute: 0)!),
        NoteDay(weekday: .monday, time: TimeOfDay(hour: 8, minute: 0)!),
    ]

    /// "Sunday 18:00".
    public var title: String {
        "\(weekday.name) \(time.text)"
    }

    /// True from the note time on the note weekday to the end of the following day: a tutor who misses the evening sees
    /// the notes the next day.
    public func isOn(at now: Date, calendar: Calendar) -> Bool {
        let today = Day(now, calendar: calendar)
        if today.weekday(in: calendar) == weekday {
            return !isBeforeTime(now, calendar: calendar)
        }
        return today.adding(days: -1, calendar: calendar).weekday(in: calendar) == weekday
    }

    /// The note day a note belongs to: the latest note weekday at or before `now`, today only once its time has come.
    public func noteDay(for now: Date, calendar: Calendar) -> Day {
        let today = Day(now, calendar: calendar)
        let back = (today.weekday(in: calendar).rawValue - weekday.rawValue + 7) % 7
        if back == 0, isBeforeTime(now, calendar: calendar) {
            return today.adding(days: -7, calendar: calendar)
        }
        return today.adding(days: -back, calendar: calendar)
    }

    /// The week a note covers, ending on the note day: from the Monday before it (a Monday note day covers the six
    /// days before it), never more than seven days.
    public static func week(ending noteDay: Day, calendar: Calendar) -> ClosedRange<Day> {
        let dayBefore = noteDay.adding(days: -1, calendar: calendar)
        let monday = dayBefore.adding(days: -(dayBefore.weekday(in: calendar).rawValue - 1), calendar: calendar)
        return max(monday, noteDay.adding(days: -6, calendar: calendar)) ... noteDay
    }

    private func isBeforeTime(_ now: Date, calendar: Calendar) -> Bool {
        let parts = calendar.dateComponents([.hour, .minute], from: now)
        return TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0).map { $0 < time } ?? false
    }
}

public extension Classroom {
    /// The batch's note day, Sunday 18:00 when none is set.
    var effectiveNoteDay: NoteDay {
        noteDay ?? .default
    }
}
