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
