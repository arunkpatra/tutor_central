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

    public var short: String {
        String(name.prefix(3))
    }

    public var initial: String {
        String(name.prefix(1))
    }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
