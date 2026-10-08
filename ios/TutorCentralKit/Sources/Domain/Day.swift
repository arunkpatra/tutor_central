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

    public var iso: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

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
    public var text: String {
        formatted("d MMM yyyy")
    }

    /// "4 Oct".
    public var shortText: String {
        formatted("d MMM")
    }

    /// "7 October".
    public var longText: String {
        formatted("d MMMM")
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

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
