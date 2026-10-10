import Domain
import Foundation

/// The words the artefacts' screens share (components.md "Phase 10 parts" 10.4).
enum ArtefactWords {
    static let aiLine = "AI can make mistakes. Check every question and answer before you share it."
    static let gone = "This sheet isn't here any more."

    /// "Class 8 Science"; a ladder's group, whose subject is its chapter, "Class 2"; nil when neither is known. The
    /// classes are the members'; a group whose members are not in the register, the plan's.
    @MainActor static func classSubject(_ group: PlanGroup, register: any Register) -> String? {
        let members = Array(Set(group.memberIDs.compactMap { register.student($0)?.classLevel })).sorted()
        let levels = members.isEmpty ? group.classLevels.sorted() : members
        let classes = levels.map(\.title).joined(separator: " and ")
        let words = [classes.isEmpty ? nil : classes, group.subject == group.chapter ? nil : group.subject]
            .compactMap(\.self).joined(separator: " ")
        return words.isEmpty ? nil : words
    }

    /// "Four steps"; past nine, "12 steps".
    static func steps(_ count: Int) -> String {
        let words = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        let number = (1 ... words.count).contains(count) ? words[count - 1] : "\(count)"
        return "\(number) \(count == 1 ? "step" : "steps")"
    }

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
