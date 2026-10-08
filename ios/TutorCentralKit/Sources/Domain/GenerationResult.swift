import Foundation

/// A question paper as the API returns it (api/src/schemas.ts, PaperOutput).
public struct PaperResult: Hashable, Sendable, Codable {
    public struct Section: Hashable, Sendable, Codable, Identifiable {
        public let title: String
        public let marksEach: Int
        public let questions: [Question]

        public var id: String {
            title
        }

        public init(title: String, marksEach: Int, questions: [Question]) {
            self.title = title
            self.marksEach = marksEach
            self.questions = questions
        }
    }

    public struct Question: Hashable, Sendable, Codable, Identifiable {
        public let number: Int
        public let text: String
        public let marks: Int
        public let answer: String

        public var id: Int {
            number
        }

        public init(number: Int, text: String, marks: Int, answer: String) {
            self.number = number
            self.text = text
            self.marks = marks
            self.answer = answer
        }
    }

    public let title: String
    public let sections: [Section]

    public init(title: String, sections: [Section]) {
        self.title = title
        self.sections = sections
    }

    public var questions: [Question] {
        sections.flatMap(\.questions)
    }

    public var questionCount: Int {
        questions.count
    }

    public var totalMarks: Int {
        questions.reduce(0) { $0 + $1.marks }
    }
}

/// Homework or a worksheet (QuestionSetOutput): questions with answers, no marks.
public struct QuestionSetResult: Hashable, Sendable, Codable {
    public struct Question: Hashable, Sendable, Codable, Identifiable {
        public let number: Int
        public let text: String
        public let answer: String

        public var id: Int {
            number
        }

        public init(number: Int, text: String, answer: String) {
            self.number = number
            self.text = text
            self.answer = answer
        }
    }

    public let title: String
    public let instructions: String?
    public let questions: [Question]

    public init(title: String, instructions: String?, questions: [Question]) {
        self.title = title
        self.instructions = instructions
        self.questions = questions
    }
}

public struct NoteResult: Hashable, Sendable, Codable {
    public let note: String

    public init(note: String) {
        self.note = note
    }
}

/// What a generation made, by kind.
public enum GenerationResult: Hashable, Sendable {
    case paper(PaperResult)
    case homework(QuestionSetResult)
    case worksheet(QuestionSetResult)
    case progressNote(NoteResult)

    /// The API's output JSON by kind; nil when it does not parse or is empty where the API never answers empty (a row
    /// written by a newer build, or a broken one).
    public static func decode(kind: GenerationKind, output: String) -> GenerationResult? {
        let data = Data(output.utf8)
        let decoder = JSONDecoder()
        switch kind {
        case .paper:
            guard let paper = try? decoder.decode(PaperResult.self, from: data), !paper.sections.isEmpty,
                  paper.sections.allSatisfy({ !$0.questions.isEmpty }) else { return nil }
            return .paper(paper)
        case .homework, .worksheet:
            guard let set = try? decoder.decode(QuestionSetResult.self, from: data), !set.questions.isEmpty else {
                return nil
            }
            return kind == .homework ? .homework(set) : .worksheet(set)
        case .progressNote:
            guard let note = try? decoder.decode(NoteResult.self, from: data), !note.note.isEmpty else { return nil }
            return .progressNote(note)
        }
    }

    /// The paper's title; a note's is "Progress note" (its screen names the student).
    public var title: String {
        switch self {
        case let .paper(paper): paper.title
        case let .homework(set), let .worksheet(set): set.title
        case .progressNote: GenerationKind.progressNote.title
        }
    }

    public var questionCount: Int? {
        switch self {
        case let .paper(paper): paper.questionCount
        case let .homework(set), let .worksheet(set): set.questions.count
        case .progressNote: nil
        }
    }
}

/// One result of the AI Assistant: from this session's call or read back from `ai_generations`.
public struct Generation: Hashable, Sendable, Identifiable {
    public let id: UUID
    public let kind: GenerationKind
    public let createdAt: Date
    /// The form it was made from; nil when the stored input no longer reads as one.
    public let request: GenerateRequest?
    public let result: GenerationResult

    public init(id: UUID, kind: GenerationKind, createdAt: Date, request: GenerateRequest?, result: GenerationResult) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.request = request
        self.result = result
    }

    /// The student a note is about.
    public var studentID: UUID? {
        guard case let .progressNote(form)? = request else { return nil }
        return form.studentID
    }

    /// "Quadratic equations" or, for a note, the student's name (else "Progress note").
    public func title(studentName: (UUID) -> String?) -> String {
        guard kind == .progressNote else { return result.title }
        return studentID.flatMap(studentName) ?? result.title
    }

    /// "Question paper · Class 10 Maths · Tue 6 Oct". `className` is asked for the form's class, or for a note the
    /// student's id (the register answers either); nil reads "No class".
    public func line(className: (UUID?) -> String?, calendar: Calendar) -> String {
        let about = kind == .progressNote ? studentID : request?.classID
        let day = Day(createdAt, calendar: calendar)
        return "\(kind.title) · \(className(about) ?? "No class") · \(day.shortWeekdayText)"
    }

    /// The hero's line: "10 questions · 20 marks · Medium · created today, 18:32"; a note "Warm · written Tue 6 Oct,
    /// 18:32".
    public func heroLine(today: Day, calendar: Calendar) -> String {
        let day = Day(createdAt, calendar: calendar)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm"
        let when = "\(day == today ? "today" : day.shortWeekdayText), \(formatter.string(from: createdAt))"
        var parts: [String] = []
        if let count = result.questionCount {
            parts.append(count == 1 ? "1 question" : "\(count) questions")
        }
        if case let .paper(paper) = result {
            parts.append(paper.totalMarks == 1 ? "1 mark" : "\(paper.totalMarks) marks")
        }
        if let level = request?.level {
            parts.append(level.title)
        }
        if case let .progressNote(form)? = request {
            parts.append(form.tone.title)
        }
        parts.append(kind == .progressNote ? "written \(when)" : "created \(when)")
        return parts.joined(separator: " · ")
    }
}
