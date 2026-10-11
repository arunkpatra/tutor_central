import Foundation

/// Whom Make's material is for (P10-Make-For): a student, one of today's groups, a batch, or a class level on its own.
public enum MakeTarget: Hashable, Sendable {
    case student(UUID), group(plan: UUID, number: Int), batch(UUID), classLevel(ClassLevel)
}

extension MakeTarget: Codable {
    private enum Keys: String, CodingKey { case kind, id, plan, number, level }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(String.self, forKey: .kind) {
        case "student": self = try .student(c.decode(UUID.self, forKey: .id))
        case "group": self = try .group(
                plan: c.decode(UUID.self, forKey: .plan),
                number: c.decode(Int.self, forKey: .number)
            )
        case "batch": self = try .batch(c.decode(UUID.self, forKey: .id))
        default: self = try .classLevel(c.decode(ClassLevel.self, forKey: .level))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .student(id):
            try c.encode("student", forKey: .kind)
            try c.encode(id, forKey: .id)
        case let .group(plan, number):
            try c.encode("group", forKey: .kind)
            try c.encode(plan, forKey: .plan)
            try c.encode(number, forKey: .number)
        case let .batch(id):
            try c.encode("batch", forKey: .kind)
            try c.encode(id, forKey: .id)
        case let .classLevel(level):
            try c.encode("class", forKey: .kind)
            try c.encode(level, forKey: .level)
        }
    }
}

/// The target's words, kept in a Make artefact's content as `made_for`: the screen's eyebrow with no plan ("For Dev ·
/// Class 8 Science · Balancing equations") and Recent's line ("Group 1").
public struct MakeFor: Hashable, Sendable, Codable {
    public let target: MakeTarget
    /// "For Dev", "Group 1", "Evening batch", "Class 8".
    public let title: String
    /// "Class 8 Science · Balancing equations", "Class 8 · Science", "Science".
    public let line: String

    public init(target: MakeTarget, title: String, line: String) {
        self.target = target
        self.title = title
        self.line = line
    }

    public var eyebrow: String {
        line.isEmpty ? title : "\(title) · \(line)"
    }

    /// The `made_for` key of an artefact's content as `keep_artefact` wrote it; nil when it has none.
    public static func read(fromContent json: Data) -> MakeFor? {
        guard let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let made = object[contentKey],
              let data = try? JSONSerialization.data(withJSONObject: made) else { return nil }
        return try? JSONDecoder().decode(MakeFor.self, from: data)
    }

    static let contentKey = "made_for"
}

public extension ArtefactContent {
    /// The content with `made_for` beside the kind's own keys (the kind's decoder ignores it).
    func encoded(madeFor: MakeFor?) throws -> Data {
        let content = try encoded()
        guard let madeFor,
              var object = try JSONSerialization.jsonObject(with: content) as? [String: Any] else { return content }
        object[MakeFor.contentKey] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(madeFor))
        return try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
    }
}
