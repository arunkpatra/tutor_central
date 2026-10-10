import Domain
import Foundation

/// The words the artefacts' screens share (components.md "Phase 10 parts" 10.4).
enum ArtefactWords {
    static let aiLine = "AI can make mistakes. Check every question and answer before you share it."
    static let gone = "This sheet isn't here any more."

    /// "Dev, Meher and Nikhil"; "Dev, Meher, Nikhil and 2 more"; "Riya".
    static func names(_ firstNames: [String]) -> String {
        switch firstNames.count {
        case 0: ""
        case 1: firstNames[0]
        case 2, 3: firstNames.dropLast().joined(separator: ", ") + " and " + (firstNames.last ?? "")
        default: firstNames.prefix(3).joined(separator: ", ") + " and \(firstNames.count - 3) more"
        }
    }

    /// "made today, 16:40"; "made Mon 5 Oct, 16:40".
    static func made(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = Day(date, calendar: calendar)
        let when = day == Day(now, calendar: calendar) ? "today" : day.shortWeekdayText
        return "\(when), \(QueuedChange.clock(date, calendar: calendar))"
    }
}
