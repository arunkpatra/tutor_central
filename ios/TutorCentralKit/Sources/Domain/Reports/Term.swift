import Foundation

/// A school term in whole months (plan/phase-15-plan.md decision 15): the standard calendar's Term 1 June to September
/// and Term 2 October to March; the Karnataka state calendar's June to October and November to April. The months
/// between terms belong to the year before's second term.
public struct Term: Hashable, Sendable {
    public enum Calendar: Hashable, Sendable { case standard, karnataka }

    /// The year the school year starts in (June).
    public let schoolYear: Int
    /// 1 or 2.
    public let number: Int
    public let calendar: Calendar

    public init(schoolYear: Int, number: Int, calendar: Calendar) {
        self.schoolYear = schoolYear
        self.number = number
        self.calendar = calendar
    }

    /// The term a day falls in.
    public static func containing(_ day: Day, calendar: Calendar) -> Term {
        let lastOfOne = calendar == .karnataka ? 10 : 9
        switch day.month {
        case 6 ... lastOfOne: return Term(schoolYear: day.year, number: 1, calendar: calendar)
        case (lastOfOne + 1) ... 12: return Term(schoolYear: day.year, number: 2, calendar: calendar)
        default: return Term(schoolYear: day.year - 1, number: 2, calendar: calendar)
        }
    }

    /// The calendar most boards use (a missing board is not counted); a tie or none is the standard one.
    public static func calendar(for boards: [Board?]) -> Calendar {
        let known = boards.compactMap(\.self)
        let karnataka = known.count { $0 == .karnataka }
        return karnataka > known.count - karnataka ? .karnataka : .standard
    }

    private var span: (first: Period, count: Int) {
        switch (calendar, number) {
        case (.standard, 1): (Period(year: schoolYear, month: 6), 4)
        case (.standard, _): (Period(year: schoolYear, month: 10), 6)
        case (.karnataka, 1): (Period(year: schoolYear, month: 6), 5)
        case (.karnataka, _): (Period(year: schoolYear, month: 11), 6)
        }
    }

    public var months: [Period] {
        let (first, count) = span
        return (1 ..< count).reduce(into: [first]) { months, _ in months.append(months[months.count - 1].next) }
    }

    /// "Term 1 · June to September".
    public var title: String {
        let name = { (period: Period) in Self.monthNames[period.month - 1] }
        return "Term \(number) · \(name(months[0])) to \(name(months[months.count - 1]))"
    }

    private static let monthNames = [
        "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November",
        "December",
    ]

    /// "term-1-2026", for the CSV's file name.
    public var fileStem: String {
        "term-\(number)-\(schoolYear)"
    }

    public var previous: Term {
        number == 2 ? Term(schoolYear: schoolYear, number: 1, calendar: calendar)
            : Term(schoolYear: schoolYear - 1, number: 2, calendar: calendar)
    }

    public var next: Term {
        number == 1 ? Term(schoolYear: schoolYear, number: 2, calendar: calendar)
            : Term(schoolYear: schoolYear + 1, number: 1, calendar: calendar)
    }

    public func hasEnded(_ now: Day) -> Bool {
        now.period > months[months.count - 1]
    }
}
