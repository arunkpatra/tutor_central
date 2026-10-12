import Domain
import Foundation

/// The Export section's words (P18-Export-*): the card's title and line for each state, and the footnote under it.
public extension ExportStore {
    private var first: String {
        register.student(studentID)?.firstName ?? "the student"
    }

    private var pronouns: StudentDetailStore.Pronouns {
        StudentDetailStore.pronouns(register.student(studentID)?.gender)
    }

    var title: String {
        switch state {
        case .ask: "Everything about \(first)"
        case .making: "Making the file"
        case .ready: "Ready to share"
        case .failed: "Couldn't make the file"
        }
    }

    var line: String {
        switch state {
        case .ask:
            "\(pronouns.possessive.capitalized) details, attendance, fees, record, marks, and the notes and messages "
                + "made about \(pronouns.object), in one PDF."
        case let .making(askedAt):
            "Asked at \(QueuedChange.clock(askedAt, calendar: DayHeading.india)). Usually ready in a minute; you can "
                + "leave this page."
        case let .ready(file):
            "Made \(made(file.madeAt)) · PDF, \(file.pages == 1 ? "1 page" : "\(file.pages) pages")"
        case .failed:
            "Nothing was shared. Try again in a minute."
        }
    }

    var footnote: String {
        let forParent = "For \(pronouns.possessive) parent, when they ask what you keep about \(pronouns.object)."
        return switch state {
        case .ask: forParent + " Usually ready in a minute; you can leave this page."
        case .making, .failed: forParent
        case .ready: "Kept for 7 days, then removed from Tutor Central. Make it again whenever you need it."
        }
    }

    /// "today at 16:03", "Mon 12 Oct at 16:03".
    private func made(_ date: Date) -> String {
        let calendar = DayHeading.india
        let day = Day(date, calendar: calendar)
        let when = day == Day(now(), calendar: calendar) ? "today" : day.shortWeekdayText
        return "\(when) at \(QueuedChange.clock(date, calendar: calendar))"
    }
}
