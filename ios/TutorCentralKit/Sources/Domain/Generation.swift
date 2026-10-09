import Foundation

/// The four things the AI Assistant makes (`ai_kind` without the scan and the check); the raw value is the API's.
public enum GenerationKind: String, Hashable, Sendable, CaseIterable, Codable {
    case paper, homework, worksheet
    case progressNote = "progress_note"

    public var title: String {
        switch self {
        case .paper: "Question paper"
        case .homework: "Homework"
        case .worksheet: "Worksheet"
        case .progressNote: "Progress note"
        }
    }

    /// The SF Symbol of its tool row and history rows.
    public var symbol: String {
        switch self {
        case .paper: "doc.text"
        case .homework: "list.bullet"
        case .worksheet: "pencil.line"
        case .progressNote: "text.bubble"
        }
    }

    /// The tool row's line (P6-Assistant).
    public var line: String {
        switch self {
        case .paper: "Questions with marks, by section, with an answer key"
        case .homework: "A short set of practice questions for a class"
        case .worksheet: "Practice problems, with an answer key for you"
        case .progressNote: "A note to a parent about how their child is doing"
        }
    }

    public var createLabel: String {
        switch self {
        case .paper: "Create the paper"
        case .homework: "Create the homework"
        case .worksheet: "Create the worksheet"
        case .progressNote: "Write the note"
        }
    }

    /// A progress note names a child and their parent, so it needs the centre's consent; papers do not.
    public var needsConsent: Bool {
        self == .progressNote
    }
}

public enum Level: String, Hashable, Sendable, CaseIterable, Codable {
    case easy, medium, hard

    public var title: String {
        rawValue.capitalized
    }
}

public enum Tone: String, Hashable, Sendable, CaseIterable, Codable {
    case warm, plain

    public var title: String {
        rawValue.capitalized
    }
}

public struct PaperForm: Hashable, Sendable, Codable {
    public var classID: UUID?
    public var subject: String
    public var topic: String
    public var level: Level
    public var questions: Int
    public var marks: Int

    public static let questionsRange = 1 ... 50
    public static let marksRange = 5 ... 100

    public init(
        classID: UUID? = nil, subject: String = "", topic: String = "", level: Level = .medium, questions: Int = 10,
        marks: Int = 20
    ) {
        self.classID = classID
        self.subject = subject
        self.topic = topic
        self.level = level
        self.questions = questions
        self.marks = marks
    }
}

public struct HomeworkForm: Hashable, Sendable, Codable {
    public var classID: UUID?
    public var subject: String
    public var topic: String
    public var level: Level
    public var questions: Int

    public static let questionsRange = 1 ... 30

    public init(
        classID: UUID? = nil,
        subject: String = "",
        topic: String = "",
        level: Level = .medium,
        questions: Int = 5
    ) {
        self.classID = classID
        self.subject = subject
        self.topic = topic
        self.level = level
        self.questions = questions
    }
}

public struct WorksheetForm: Hashable, Sendable, Codable {
    public var classID: UUID?
    public var subject: String
    public var topic: String
    public var level: Level
    public var questions: Int
    public var withAnswers: Bool

    public static let questionsRange = 1 ... 40

    public init(
        classID: UUID? = nil, subject: String = "", topic: String = "", level: Level = .medium, questions: Int = 12,
        withAnswers: Bool = true
    ) {
        self.classID = classID
        self.subject = subject
        self.topic = topic
        self.level = level
        self.questions = questions
        self.withAnswers = withAnswers
    }
}

public struct NoteForm: Hashable, Sendable, Codable {
    public var studentID: UUID?
    public var observations: String
    public var tone: Tone

    public static let observationsLimit = 2000

    public init(studentID: UUID? = nil, observations: String = "", tone: Tone = .warm) {
        self.studentID = studentID
        self.observations = observations
        self.tone = tone
    }
}

/// One Create: the kind and its form.
public enum GenerateRequest: Hashable, Sendable, Codable {
    case paper(PaperForm)
    case homework(HomeworkForm)
    case worksheet(WorksheetForm)
    case progressNote(NoteForm)

    public static let topicLimit = 200
    public static let subjectLimit = 80

    public var kind: GenerationKind {
        switch self {
        case .paper: .paper
        case .homework: .homework
        case .worksheet: .worksheet
        case .progressNote: .progressNote
        }
    }

    /// The class a paper, homework or worksheet is for; nil for a note.
    public var classID: UUID? {
        switch self {
        case let .paper(form): form.classID
        case let .homework(form): form.classID
        case let .worksheet(form): form.classID
        case .progressNote: nil
        }
    }

    public var level: Level? {
        switch self {
        case let .paper(form): form.level
        case let .homework(form): form.level
        case let .worksheet(form): form.level
        case .progressNote: nil
        }
    }

    /// Create is enabled: a class chosen, a subject and a topic typed (trimmed, within their limits), or a student
    /// chosen and observations typed (1 to 2000).
    public var isValid: Bool {
        switch self {
        case let .paper(form): Self.isValid(classID: form.classID, subject: form.subject, topic: form.topic)
        case let .homework(form): Self.isValid(classID: form.classID, subject: form.subject, topic: form.topic)
        case let .worksheet(form): Self.isValid(classID: form.classID, subject: form.subject, topic: form.topic)
        case let .progressNote(form):
            form.studentID != nil && Self.within(form.observations, limit: NoteForm.observationsLimit)
        }
    }

    /// The creating card's title: "Writing 10 questions on Quadratic equations", "Writing a note about Hemanth".
    public func creatingLine(studentFirstName: String?) -> String {
        let count: Int
        let topic: String
        switch self {
        case let .paper(form): (count, topic) = (form.questions, form.topic)
        case let .homework(form): (count, topic) = (form.questions, form.topic)
        case let .worksheet(form): (count, topic) = (form.questions, form.topic)
        case .progressNote: return "Writing a note about \(studentFirstName ?? "the student")"
        }
        let questions = count == 1 ? "1 question" : "\(count) questions"
        return "Writing \(questions) on \(topic.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private static func isValid(classID: UUID?, subject: String, topic: String) -> Bool {
        classID != nil && within(subject, limit: subjectLimit) && within(topic, limit: topicLimit)
    }

    private static func within(_ text: String, limit: Int) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.storedCount <= limit
    }
}
