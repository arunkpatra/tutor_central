import Foundation
@testable import Domain

/// What the shared case files have in common (D80; the budget, the reminders, the note week): fixed ids as lowercase
/// UUIDs, days "YYYY-MM-DD", instants ISO 8601 in India's offset, written sorted so the file is the same each time.
enum CaseJSON {
    enum Bad: Error { case value(String) }

    static func id(_ uuid: UUID) -> String {
        uuid.uuidString.lowercased()
    }

    static func uuid(_ text: String) throws -> UUID {
        guard let value = UUID(uuidString: text) else { throw Bad.value(text) }
        return value
    }

    static func day(_ text: String) throws -> Day {
        guard let value = Day(iso: text) else { throw Bad.value(text) }
        return value
    }

    static func instant(_ text: String) throws -> Date {
        guard let value = ISO8601DateFormatter().date(from: text) else { throw Bad.value(text) }
        return value
    }

    /// "2026-11-02T16:30:00+05:30".
    static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = DayHeading.india.timeZone
        return formatter.string(from: date)
    }

    static func time(_ text: String?) throws -> TimeOfDay? {
        guard let text else { return nil }
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, let time = TimeOfDay(hour: parts[0], minute: parts[1]) else { throw Bad.value(text) }
        return time
    }

    static func weekdays(_ days: [Int]) throws -> Set<Weekday> {
        try Set(days.map { day in
            guard let weekday = Weekday(rawValue: day) else { throw Bad.value("\(day)") }
            return weekday
        })
    }

    /// The case file a test target carries (`Cases/<name>.json`, copied there by `bun contract`).
    static func read<T: Decodable>(_ name: String, as _: T.Type) -> T? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Cases"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Writes a case file to the path the environment names.
    static func write(_ value: some Encodable, to variable: String) throws {
        guard let path = ProcessInfo.processInfo.environment[variable] else { throw Bad.value(variable) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(value).write(to: URL(fileURLWithPath: path))
    }
}
