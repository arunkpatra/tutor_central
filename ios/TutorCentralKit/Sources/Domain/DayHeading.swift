import Foundation

/// Dates as components.md writes them.
public enum DayHeading {
    /// "Wednesday 7 October": Today's eyebrow, no year.
    public static func long(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
            .locale(Locale(identifier: "en_GB"))
        style = style.weekday(.wide)
        let weekday = date.formatted(style)
        let day = calendar.component(.day, from: date)
        let month = date.formatted(Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
            .locale(Locale(identifier: "en_GB")).month(.wide))
        return "\(weekday) \(day) \(month)"
    }

    /// The centre's calendar: India (D2).
    public static let india: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar
    }()
}
