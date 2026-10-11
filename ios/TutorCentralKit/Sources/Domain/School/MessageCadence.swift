import Foundation

/// At most three suggested messages a week to a parent (docs/spec-v2.md section 8; plan/phase-13-plan.md decision 20;
/// plan/phase-14-plan.md decision 6): the weekly note, Can now do, Test tomorrow and the not-on-track message, Monday
/// to
/// Sunday in the centre's calendar, across the parent's students. The tutor's own sends (a reminder, an absence alert,
/// consent, the forward ask) never count.
public enum MessageCadence {
    public static let perWeek = 3
    public static let suggestedKinds: Set<MessageKind> = [.note, .canDo, .testTomorrow, .notOnTrack]

    /// The parent's suggested messages sent in the week of `now`; the caller passes the entries of that parent's
    /// students. A copy is not a send: it never counts (the note's Copy, plan/phase-14-plan.md decision 3).
    public static func suggested(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> [MessageEntry] {
        let today = Day(now, calendar: calendar)
        let monday = today.adding(days: 1 - today.weekday(in: calendar).rawValue, calendar: calendar)
        let start = monday.date(in: calendar)
        let end = monday.adding(days: 7, calendar: calendar).date(in: calendar)
        return entries.filter {
            suggestedKinds.contains($0.kind) && $0.channel != .copied && $0.openedAt >= start && $0.openedAt < end
        }
    }

    public static func suggestedCount(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Int {
        suggested(entries, now: now, calendar: calendar).count
    }

    public static func canSuggest(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Bool {
        suggestedCount(entries, now: now, calendar: calendar) < perWeek
    }

    /// What happens to a suggested message for a student: sent, held with its reason, or nothing to send to.
    public enum Decision: Hashable, Sendable {
        case send, held(HeldReason), noNumber
    }

    /// No number → nothing to send to; no consent → held for it; the parent's three this week spent → held; else send.
    public static func decision(for student: Student, parentEntries: [MessageEntry], now: Date, calendar: Calendar)
        -> Decision {
        guard student.parentPhone != nil else { return .noNumber }
        guard student.consent != nil else {
            return .held(.consent(parentFirstName: student.parentName.flatMap(firstName)))
        }
        return canSuggest(parentEntries, now: now, calendar: calendar) ? .send : .held(.threeThisWeek)
    }

    /// The row's words (P10-Today-NoteDay, P10-Held).
    public static func heldWords(_ reason: HeldReason) -> String {
        switch reason {
        case let .consent(name): "waits for \(name.map { "\($0)'s" } ?? "the parent's") consent"
        case .threeThisWeek: "held: three messages this week"
        }
    }

    /// The held sheet's footnote, naming the next note day (P10-Held).
    public static func heldFootnote(nextNoteDay: Day) -> String {
        "Three messages this week already. The app suggests at most three a week per parent, so this weekly note waits "
            + "for \(nextNoteDay.weekdayName) the \(ordinal(nextNoteDay.day)) unless you send it now. "
            + "Messages you send yourself are never held."
    }

    private static func firstName(_ name: String) -> String? {
        name.split(separator: " ").first.map(String.init)
    }

    /// "1st", "2nd", "3rd", "11th", "21st".
    private static func ordinal(_ number: Int) -> String {
        let suffix = switch (number % 10, number % 100) {
        case (_, 11 ... 13): "th"
        case (1, _): "st"
        case (2, _): "nd"
        case (3, _): "rd"
        default: "th"
        }
        return "\(number)\(suffix)"
    }
}

/// Why a suggested message waits.
public enum HeldReason: Hashable, Sendable {
    case consent(parentFirstName: String?)
    case threeThisWeek
}
