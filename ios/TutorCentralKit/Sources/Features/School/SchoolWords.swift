import DesignSystem
import Domain
import Foundation

/// The School screens' words and the Kit's kinds for the Domain's items (DesignSystem knows no Domain types).
enum SchoolWords {
    static func kind(_ kind: SchoolItemKind) -> KindChipKind {
        switch kind {
        case .exam: .exam
        case .homework: .homework
        case .notice: .notice
        case .holiday: .holiday
        }
    }

    static func dot(_ kind: SchoolItemKind) -> CalendarDot {
        switch kind {
        case .exam: .exam
        case .homework: .homework
        case .notice: .notice
        case .holiday: .holiday
        }
    }

    /// "Fri" over "16 Oct".
    static func dayColumn(_ day: Day) -> (day: String, date: String) {
        (String(day.shortWeekdayText.prefix(3)), day.shortText)
    }

    static let pasteNothing = "Nothing to paste. Copy the school's message first."
    static let emptyTitle = "Nothing from a school yet"
    static let emptyLine = "Tests, homework, notices and holidays appear here, by student, once a school's message "
        + "or a photo of it reaches Tutor Central."
    static let emptyFootnote = "From WhatsApp, share the school's message to Tutor Central. From Photos, share a "
        + "timetable or a circular. You check each item before it is kept."
}

extension SchoolWords {
    /// Who an item is for, as the fact line and the page read it ("Class 8 at Vidya Niketan · Dev, Meher, Nikhil").
    static func audience(_ audience: ItemAudience?, students: [Student], schools: [School]) -> String? {
        guard let audience else { return nil }
        let probe = SchoolItem(
            id: UUID(), kind: .notice, audience: audience, title: "", subject: nil, date: Day(
                year: 2026,
                month: 1,
                day: 1
            )!,
            endDate: nil, portions: nil, sourceText: nil, photoPath: nil, source: .typed, receivedAt: .now,
            confirmedAt: nil
        )
        return SchoolItemRules.audienceLine(probe, students: students, schools: schools)
    }

    /// The date fact's label: Due for homework, Dates for a holiday, else Date.
    static func dateLabel(_ kind: SchoolItemKind) -> String {
        switch kind {
        case .homework: "Due"
        case .holiday: "Dates"
        case .exam, .notice: "Date"
        }
    }

    /// "Fri 16 Oct · in 9 days" for an exam; "Mon 19 to Wed 21 Oct" for a holiday; else the day.
    static func dateValue(kind: SchoolItemKind, date: Day, end: Day?, today: Day) -> String {
        switch kind {
        case .exam:
            return [date.shortWeekdayText, SchoolItemRules.countdown(from: today, to: date)].compactMap(\.self)
                .joined(separator: " · ")
        case .holiday:
            guard let end, end > date else { return date.shortWeekdayText }
            let from = end.month == date.month ? date.weekdayDayText : date.shortWeekdayText
            return "\(from) to \(end.shortWeekdayText)"
        case .homework, .notice:
            return date.shortWeekdayText
        }
    }

    static let readingTitle = "Reading what the school sent"
    static let readingLine = "Usually under a minute. Tests, homework, notices and holidays are picked out for you to "
        + "check."
    static let readingFootnote = "Each item read appears here for you to check. Nothing is kept until you tap "
        + "Add."
    static let readFootnote = "Open an item to change who it is for, the date or the portions. Nothing is kept until "
        + "you tap Add."
}
