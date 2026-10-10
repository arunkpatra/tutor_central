import Foundation

/// The batch's kept pattern for a weekday (`classes.plan_pattern`, "Keep this for Wednesdays"): the group count and
/// each group's subject, in group order.
public struct PlanPattern: Hashable, Sendable, Codable {
    public let groups: Int
    public let subjects: [String]

    public init(groups: Int, subjects: [String]) {
        self.groups = groups
        self.subjects = subjects
    }

    /// `{"3": {"groups": 2, "subjects": [...]}}`, keyed by the ISO weekday (1 Monday to 7 Sunday), as the column holds
    /// it.
    public static func encode(_ patterns: [Weekday: PlanPattern]) throws -> Data {
        let keyed = Dictionary(uniqueKeysWithValues: patterns.map { (String($0.key.rawValue), $0.value) })
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(keyed)
    }

    /// The column read back; a key that is not a weekday is left out.
    public static func decode(_ data: Data) throws -> [Weekday: PlanPattern] {
        let keyed = try JSONDecoder().decode([String: PlanPattern].self, from: data)
        return keyed.reduce(into: [:]) { patterns, entry in
            if let raw = Int(entry.key), let day = Weekday(rawValue: raw) {
                patterns[day] = entry.value
            }
        }
    }
}
