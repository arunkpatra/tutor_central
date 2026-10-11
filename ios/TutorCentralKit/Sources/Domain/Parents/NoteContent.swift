import Foundation

/// A weekly note or a can-now-do as the app keeps it (`artefacts`, kinds `note` and `can_do`, a student and no plan;
/// plan/phase-14-plan.md decision 1): the message in the parent's language, the English beside it (none for English),
/// the week's Monday, the facts it was written from and the call that made it.
public struct NoteContent: Hashable, Sendable, Codable {
    /// One line of "What it says" (P10-Note): Taught, Got right, To practise, Coming; Can now do, At home, Next.
    public struct FactRow: Hashable, Sendable, Codable {
        public let label: String
        public let fact: String
        public let symbol: String

        public init(label: String, fact: String, symbol: String) {
            self.label = label
            self.fact = fact
            self.symbol = symbol
        }
    }

    public var message: String
    public let english: String?
    public let language: MessageLanguage
    public let weekMonday: Day
    public let facts: [FactRow]
    public let generationID: UUID?

    public init(
        message: String, english: String?, language: MessageLanguage, weekMonday: Day, facts: [FactRow],
        generationID: UUID?
    ) {
        self.message = message
        self.english = english
        self.language = language
        self.weekMonday = weekMonday
        self.facts = facts
        self.generationID = generationID
    }

    private enum CodingKeys: String, CodingKey {
        case message, english, language, weekMonday, facts
        case generationID = "generationId"
    }

    /// The week's Monday is written as an ISO day ("2026-10-05"), as the database writes a day.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let monday = try c.decode(String.self, forKey: .weekMonday)
        guard let day = Day(iso: monday) else {
            throw DecodingError.dataCorruptedError(forKey: .weekMonday, in: c, debugDescription: "not a day: \(monday)")
        }
        try self.init(
            message: c.decode(String.self, forKey: .message),
            english: c.decodeIfPresent(String.self, forKey: .english),
            language: c.decode(MessageLanguage.self, forKey: .language),
            weekMonday: day,
            facts: c.decodeIfPresent([FactRow].self, forKey: .facts) ?? [],
            generationID: c.decodeIfPresent(UUID.self, forKey: .generationID)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(message, forKey: .message)
        try c.encodeIfPresent(english, forKey: .english)
        try c.encode(language, forKey: .language)
        try c.encode(weekMonday.iso, forKey: .weekMonday)
        try c.encode(facts, forKey: .facts)
        try c.encodeIfPresent(generationID, forKey: .generationID)
    }
}
