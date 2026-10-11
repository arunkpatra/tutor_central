import Domain
import Foundation

/// The page's School section (Phase 13, P10-Student-End).
public extension StudentDetailStore {
    /// One of the student's next items (P10-Student-End): the day column, the title, the date and the portions.
    struct SchoolLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let day: String
        public let date: String
        public let title: String
        public let line: String
        public let kind: SchoolItemKind
    }

    /// The student's next five items by date, a running holiday included.
    var schoolRows: [SchoolLine] {
        guard let student else { return [] }
        let today = Day(now(), calendar: DayHeading.india)
        return SchoolItemRules.upcoming(for: student, items: items, students: register.activeStudents, today: today)
            .prefix(5)
            .map { item in
                let dates = if item.kind == .holiday, let end = item.endDate, end > item.date {
                    "\(end.month == item.date.month ? item.date.weekdayDayText : item.date.shortWeekdayText) to "
                        + end.shortWeekdayText
                } else {
                    item.date.shortWeekdayText
                }
                return SchoolLine(
                    id: item.id, day: String(item.date.shortWeekdayText.prefix(3)), date: item.date.shortText,
                    title: item.title, line: [dates, item.portions].compactMap(\.self).joined(separator: " · "),
                    kind: item.kind
                )
            }
    }
}
