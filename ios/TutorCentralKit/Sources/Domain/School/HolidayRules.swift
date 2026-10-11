import Foundation

/// A holiday takes its students out of the day's plan (plan/phase-13-plan.md decision 17).
public enum HolidayRules {
    /// A holiday covers its first to its last day, both included; one with no end, its one day.
    public static func covers(_ item: SchoolItem, _ day: Day) -> Bool {
        item.kind == .holiday && item.date <= day && day <= item.lastDay
    }

    public static func onHoliday(_ student: Student, on day: Day, items: [SchoolItem], students _: [Student]) -> Bool {
        items.contains { covers($0, day) && SchoolItemRules.reaches($0, student) }
    }

    /// The batch's meeting days the holiday covers.
    public static func batchDays(_ item: SchoolItem, batch: Classroom, calendar: Calendar) -> [Day] {
        guard item.kind == .holiday else { return [] }
        let count = max(0, item.date.days(to: item.lastDay))
        return (0 ... count).map { item.date.adding(days: $0, calendar: calendar) }
            .filter { batch.meetingDays.contains($0.weekday(in: calendar)) }
    }

    /// "Mon 19, Tue 20 and Wed 21 Oct · Evening batch", one line per batch that meets on a covered day; empty when
    /// none.
    public static func coveredLine(_ item: SchoolItem, batches: [Classroom], calendar: Calendar) -> String {
        batches.compactMap { batch -> String? in
            let days = batchDays(item, batch: batch, calendar: calendar)
            guard !days.isEmpty else { return nil }
            let words = days.enumerated().map { index, day in
                let lastOfMonth = index == days.count - 1 || days[index + 1].month != day.month
                return lastOfMonth ? "\(day.weekdayDayText) \(day.shortMonthText)" : day.weekdayDayText
            }
            return "\(listed(words)) · \(batch.name)"
        }.joined(separator: "\n")
    }

    /// "a", "a and b", "a, b and c".
    static func listed(_ words: [String]) -> String {
        guard let last = words.last, words.count > 1 else { return words.first ?? "" }
        return "\(words.dropLast().joined(separator: ", ")) and \(last)"
    }
}
