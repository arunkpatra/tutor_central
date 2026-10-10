import Foundation

/// What an artefact is (`artefact_kind`, migration 0010).
public enum ArtefactKind: String, Hashable, Sendable, Codable, CaseIterable {
    case sheet, workedExample = "worked_example", figure, brief, check, placement, mock, note, canDo = "can_do"
    case testTomorrow = "test_tomorrow", gapReport = "gap_report"
}

/// Made by the AI, or the tutor's own (`artefact_source`).
public enum ArtefactSource: String, Hashable, Sendable, Codable { case made, own }

public struct SheetQuestion: Hashable, Sendable, Codable, Identifiable {
    public var id: Int {
        number
    }

    public let number: Int
    public let text: String
    public let answer: String

    public init(number: Int, text: String, answer: String) {
        self.number = number
        self.text = text
        self.answer = answer
    }
}

/// A practice set or a homework sheet (P10-Sheet): the API's question set, with its use.
public struct SheetContent: Hashable, Sendable, Codable {
    public let title: String
    public let instructions: String?
    public let questions: [SheetQuestion]
    public let forHomework: Bool
    public let light: Bool

    public init(title: String, instructions: String?, questions: [SheetQuestion], forHomework: Bool, light: Bool) {
        self.title = title
        self.instructions = instructions
        self.questions = questions
        self.forHomework = forHomework
        self.light = light
    }
}

/// One problem solved one step at a time, and the common slip (P10-WorkedExample).
public struct WorkedExample: Hashable, Sendable, Codable {
    public struct Step: Hashable, Sendable, Codable, Identifiable {
        public var id: String {
            title
        }

        public let title: String
        public let working: String

        public init(title: String, working: String) {
            self.title = title
            self.working = working
        }
    }

    public let problem: String
    public let steps: [Step]
    public let slip: String

    public init(problem: String, steps: [Step], slip: String) {
        self.problem = problem
        self.steps = steps
        self.slip = slip
    }
}

/// A figure's spec and the sentence the tutor says over it (P10-Figure-*).
public struct FigureContent: Hashable, Sendable, Codable {
    public let figure: FigureSpec
    public let caption: String

    public init(figure: FigureSpec, caption: String) {
        self.figure = figure
        self.caption = caption
    }
}

/// The tutor's brief for a chapter (P10-Brief).
public struct Brief: Hashable, Sendable, Codable {
    public struct Mistake: Hashable, Sendable, Codable, Identifiable {
        public var id: String {
            title
        }

        public let title: String
        public let howToCatch: String

        public init(title: String, howToCatch: String) {
            self.title = title
            self.howToCatch = howToCatch
        }
    }

    public let about: String
    public let mistakes: [Mistake]
    public let workedExample: WorkedExample
    public let words: [String]

    public init(about: String, mistakes: [Mistake], workedExample: WorkedExample, words: [String]) {
        self.about = about
        self.mistakes = mistakes
        self.workedExample = workedExample
        self.words = words
    }
}

/// The close's questions made ahead with the plan: the group's, or one student's (a placement among them).
public struct CheckContent: Hashable, Sendable, Codable {
    public struct Question: Hashable, Sendable, Codable {
        public let skillID: UUID
        public let skill: String
        public let question: String
        public let answer: String

        public init(skillID: UUID, skill: String, question: String, answer: String) {
            self.skillID = skillID
            self.skill = skill
            self.question = question
            self.answer = answer
        }
    }

    public let questions: [Question]
    public let placement: Bool

    public init(questions: [Question], placement: Bool) {
        self.questions = questions
        self.placement = placement
    }
}

/// `skillId` so the API's `skill_id` reads through the snake-case strategy (a key nested in `Question` would nest too
/// deep for the lint).
private enum CheckQuestionKeys: String, CodingKey {
    case skillID = "skillId", skill, question, answer
}

public extension CheckContent.Question {
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CheckQuestionKeys.self)
        try self.init(
            skillID: c.decode(UUID.self, forKey: .skillID), skill: c.decode(String.self, forKey: .skill),
            question: c.decode(String.self, forKey: .question), answer: c.decode(String.self, forKey: .answer)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CheckQuestionKeys.self)
        try c.encode(skillID, forKey: .skillID)
        try c.encode(skill, forKey: .skill)
        try c.encode(question, forKey: .question)
        try c.encode(answer, forKey: .answer)
    }
}

/// The tutor's own sheet in place of a made one (P10-Sheet-Own): typed text, or none with the photo's path.
public struct OwnContent: Hashable, Sendable, Codable {
    public let text: String?
    /// "sheet 1".
    public let inPlaceOf: String

    public init(text: String?, inPlaceOf: String) {
        self.text = text
        self.inPlaceOf = inPlaceOf
    }
}

/// An artefact's `content` (jsonb), decoded by its kind. A kind this build does not know, or content that does not fit,
/// is `.other`: the row shows its title and nothing fails.
public enum ArtefactContent: Hashable, Sendable {
    case sheet(SheetContent), workedExample(WorkedExample), figure(FigureContent), brief(Brief), check(CheckContent)
    case own(OwnContent), other

    /// The content as the API and `keep_artefact` write it (snake-case keys).
    public static func decode(
        kind: ArtefactKind,
        json: Data,
        source: ArtefactSource = .made
    ) throws -> ArtefactContent {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            if source == .own {
                return try .own(decoder.decode(OwnContent.self, from: json))
            }
            switch kind {
            case .sheet: return try .sheet(decoder.decode(SheetContent.self, from: json))
            case .workedExample: return try .workedExample(decoder.decode(WorkedExample.self, from: json))
            case .figure: return try .figure(decoder.decode(FigureContent.self, from: json))
            case .brief: return try .brief(decoder.decode(Brief.self, from: json))
            case .check, .placement: return try .check(decoder.decode(CheckContent.self, from: json))
            default: return .other
            }
        } catch is DecodingError {
            return .other
        }
    }

    /// The content in the snake-case keys `keep_artefact` writes.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys
        switch self {
        case let .sheet(value): return try encoder.encode(value)
        case let .workedExample(value): return try encoder.encode(value)
        case let .figure(value): return try encoder.encode(value)
        case let .brief(value): return try encoder.encode(value)
        case let .check(value): return try encoder.encode(value)
        case let .own(value): return try encoder.encode(value)
        case .other: return Data("{}".utf8)
        }
    }
}

/// The plan's copy on the iPhone keeps the content tagged by its case.
extension ArtefactContent: Codable {
    private enum Keys: String, CodingKey { case sheet, workedExample, figure, brief, check, own, other }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        if let value = try c.decodeIfPresent(SheetContent.self, forKey: .sheet) {
            self = .sheet(value)
        } else if let value = try c.decodeIfPresent(WorkedExample.self, forKey: .workedExample) {
            self = .workedExample(value)
        } else if let value = try c.decodeIfPresent(FigureContent.self, forKey: .figure) {
            self = .figure(value)
        } else if let value = try c.decodeIfPresent(Brief.self, forKey: .brief) {
            self = .brief(value)
        } else if let value = try c.decodeIfPresent(CheckContent.self, forKey: .check) {
            self = .check(value)
        } else if let value = try c.decodeIfPresent(OwnContent.self, forKey: .own) {
            self = .own(value)
        } else {
            self = .other
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .sheet(value): try c.encode(value, forKey: .sheet)
        case let .workedExample(value): try c.encode(value, forKey: .workedExample)
        case let .figure(value): try c.encode(value, forKey: .figure)
        case let .brief(value): try c.encode(value, forKey: .brief)
        case let .check(value): try c.encode(value, forKey: .check)
        case let .own(value): try c.encode(value, forKey: .own)
        case .other: try c.encode(true, forKey: .other)
        }
    }
}

/// Material made for the plan, or the tutor's own (`artefacts`).
public struct Artefact: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let kind: ArtefactKind
    public let source: ArtefactSource
    public let title: String
    public let content: ArtefactContent
    public let photoPath: String?
    public let studentID: UUID?
    public let planID: UUID?
    public let regeneratedFrom: UUID?
    public let madeAt: Date

    public init(
        id: UUID, kind: ArtefactKind, source: ArtefactSource, title: String, content: ArtefactContent,
        photoPath: String?, studentID: UUID?, planID: UUID?, regeneratedFrom: UUID?, madeAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.source = source
        self.title = title
        self.content = content
        self.photoPath = photoPath
        self.studentID = studentID
        self.planID = planID
        self.regeneratedFrom = regeneratedFrom
        self.madeAt = madeAt
    }

    /// "8 questions", "4 steps", nil. "8 questions · for Dev, Meher and Nikhil · made today, 16:40" needs the names:
    /// the screen adds them.
    public var countLine: String? {
        Self.countLine(for: content)
    }

    public static func countLine(for content: ArtefactContent) -> String? {
        switch content {
        case let .sheet(sheet): counted(sheet.questions.count, "question")
        case let .workedExample(example): counted(example.steps.count, "step")
        case let .check(checks): counted(checks.questions.count, "question")
        default: nil
        }
    }

    private static func counted(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }
}
