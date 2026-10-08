/// A wall-clock time without a date, as `classes.start_time` stores it; shown 24-hour (components.md).
public struct TimeOfDay: Hashable, Sendable, Comparable, Codable {
    public let hour: Int
    public let minute: Int

    public init?(hour: Int, minute: Int) {
        guard (0 ... 23).contains(hour), (0 ... 59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// "17:00" or Postgres's "17:00:00".
    public init?(iso: String) {
        let parts = iso.split(separator: ":").map(String.init)
        guard (2 ... 3).contains(parts.count), let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        self.init(hour: hour, minute: minute)
    }

    public var iso: String {
        text
    }

    public var text: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// "17:00–18:00", with an en dash.
    public static func range(_ start: TimeOfDay, _ end: TimeOfDay) -> String {
        "\(start.text)–\(end.text)"
    }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}
