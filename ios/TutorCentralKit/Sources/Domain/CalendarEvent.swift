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
        case let (start?, end?): TimeOfDay.range(start, end)
        case let (start?, nil): start.text
        case let (nil, end?): end.text
        case (nil, nil): nil
        }
    }

    /// The row's second line: the note when there is one, else the time.
    public var line: String? {
        note ?? timeRange
    }

    /// Tomorrow to `today + days`, by date then start time (a timeless event first on its day).
    public static func comingUp(
        _ events: [CalendarEvent],
        after today: Day,
        days: Int = 7,
        calendar: Calendar
    ) -> [CalendarEvent] {
        let last = today.adding(days: days, calendar: calendar)
        return events.filter { $0.date > today && $0.date <= last }.sorted(by: before)
    }

    public static func on(_ day: Day, in events: [CalendarEvent]) -> [CalendarEvent] {
        events.filter { $0.date == day }.sorted(by: before)
    }

    private static func before(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        switch (lhs.startTime, rhs.startTime) {
        case let (x?, y?) where x != y: return x < y
        case (nil, _?): return true
        case (_?, nil): return false
        default: return lhs.title < rhs.title
        }
    }
}
