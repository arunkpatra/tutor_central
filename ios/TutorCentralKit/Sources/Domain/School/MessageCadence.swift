import Foundation

/// At most three suggested messages a week to a parent (docs/spec-v2.md section 8; plan/phase-13-plan.md decision 20):
/// the weekly note, Can now do and Test tomorrow, Monday to Sunday in the centre's calendar, across the parent's
/// students. The tutor's own sends (a reminder, an absence alert, consent, the forward ask) never count.
public enum MessageCadence {
    public static let perWeek = 3
    public static let suggestedKinds: Set<MessageKind> = [.note, .canDo, .testTomorrow]

    /// The parent's suggested messages in the week of `now`; the caller passes the entries of that parent's students.
    public static func suggestedCount(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Int {
        let today = Day(now, calendar: calendar)
        let monday = today.adding(days: 1 - today.weekday(in: calendar).rawValue, calendar: calendar)
        let start = monday.date(in: calendar)
        let end = monday.adding(days: 7, calendar: calendar).date(in: calendar)
        return entries.filter { suggestedKinds.contains($0.kind) && $0.openedAt >= start && $0.openedAt < end }.count
    }

    public static func canSuggest(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Bool {
        suggestedCount(entries, now: now, calendar: calendar) < perWeek
    }
}
