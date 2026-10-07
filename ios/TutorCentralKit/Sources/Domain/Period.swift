import Foundation

/// A fee month. Stored as the first day of the month (`fee_invoices.period`).
public struct Period: Hashable, Sendable, Comparable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        precondition((1 ... 12).contains(month), "month out of range")
        self.year = year
        self.month = month
    }

    /// "2026-03-01" → March 2026; any other day of the month is refused.
    public init?(isoDay: String) {
        let parts = isoDay.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, parts[2] == 1, (1 ... 12).contains(parts[1]) else { return nil }
        self.init(year: parts[0], month: parts[1])
    }

    public var isoDay: String { String(format: "%04d-%02d-01", year, month) }

    public var next: Period { month == 12 ? Period(year: year + 1, month: 1) : Period(year: year, month: month + 1) }
    public var previous: Period {
        month == 1 ? Period(year: year - 1, month: 12) : Period(year: year, month: month - 1)
    }

    /// Midnight on the first of the month in the given time zone.
    public func start(in timeZone: TimeZone) -> Date {
        Self.calendar(timeZone).date(from: DateComponents(year: year, month: month, day: 1))!
    }

    public static func containing(_ date: Date, in timeZone: TimeZone) -> Period {
        let parts = calendar(timeZone).dateComponents([.year, .month], from: date)
        return Period(year: parts.year!, month: parts.month!)
    }

    /// "October 2026".
    public var title: String { formatted("MMMM yyyy") }
    /// "Oct 2026".
    public var shortTitle: String { formatted("MMM yyyy") }

    public static func < (lhs: Period, rhs: Period) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    private static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// A formatter per call: `DateFormatter` is not `Sendable`, and nothing mutable is global (D8).
    private func formatted(_ pattern: String) -> String {
        let utc = TimeZone(identifier: "UTC")!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = utc
        formatter.dateFormat = pattern
        return formatter.string(from: start(in: utc))
    }
}
