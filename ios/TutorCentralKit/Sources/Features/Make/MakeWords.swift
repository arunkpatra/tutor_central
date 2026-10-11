import Domain
import Foundation

/// Make something's words (P10-Make, components.md 10.7).
enum MakeWords {
    static let homeLead = "Anything the plan makes, made on its own: for a student, a group, a class or just a topic. "
        + "You check it before it reaches anyone."
    static let emptyTitle = "Nothing made yet"
    static let emptyLine = "Sheets, examples, figures, mocks, notes and papers you make appear here, ready to open "
        + "again."
    static let historyFailed = "Couldn't load History. Check your connection and try again."

    /// The kind as Recent's line names it.
    static func kindTitle(_ kind: ArtefactKind) -> String {
        switch kind {
        case .sheet: "Sheet"
        case .workedExample: "Worked example"
        case .figure: "Figure"
        case .brief: "Brief"
        case .mock: "Mock"
        case .note, .canDo: "Note"
        default: "Material"
        }
    }

    /// The row's symbol: the kind's row on the home.
    static func symbol(_ kind: ArtefactKind) -> String {
        MakeKind.allCases.first { $0.artefactKind == kind }?.symbol ?? "doc.text"
    }

    /// "today, 16:40"; "Mon 5 Oct, 16:40".
    static func when(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = Day(date, calendar: calendar)
        let name = day == Day(now, calendar: calendar) ? "today" : day.shortWeekdayText
        return "\(name), \(QueuedChange.clock(date, calendar: calendar))"
    }
}
