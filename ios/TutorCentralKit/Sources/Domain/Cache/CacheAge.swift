import Foundation

/// The offline bar's words (P7-Offline-*): how old the copy on this iPhone is.
public enum CacheAge {
    /// "Offline. Showing what was saved at 14:10." / "… saved yesterday at 18:30." / "… saved on Mon 5 Oct."
    public static func words(savedAt: Date, now: Date, calendar: Calendar) -> String {
        let saved = Day(savedAt, calendar: calendar)
        let today = Day(now, calendar: calendar)
        let when = if saved == today {
            "at \(QueuedChange.clock(savedAt, calendar: calendar))"
        } else if saved == today.adding(days: -1, calendar: calendar) {
            "yesterday at \(QueuedChange.clock(savedAt, calendar: calendar))"
        } else {
            "on \(saved.shortWeekdayText)"
        }
        return "Offline. Showing what was saved \(when)."
    }
}
