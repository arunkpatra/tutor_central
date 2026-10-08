import Foundation

/// The suggested marks for a checked answer sheet; the tutor's edits are kept on each question.
public struct CheckResult: Hashable, Sendable, Codable {
    public struct QuestionMark: Hashable, Sendable, Codable, Identifiable {
        public let number: Int
        public let text: String
        public let note: String
        public var marks: Int
        public let of: Int
        /// The suggested mark, once the tutor has changed it.
        public var changedFrom: Int?

        public var id: Int {
            number
        }

        public init(number: Int, text: String, note: String, marks: Int, of: Int, changedFrom: Int?) {
            self.number = number
            self.text = text
            self.note = note
            self.marks = marks
            self.of = of
            self.changedFrom = changedFrom
        }
    }

    public var questions: [QuestionMark]
    public let summary: String

    public init(questions: [QuestionMark], summary: String) {
        self.questions = questions
        self.summary = summary
    }

    public var total: Int {
        questions.reduce(0) { $0 + $1.marks }
    }

    public var outOf: Int {
        questions.reduce(0) { $0 + $1.of }
    }

    public var fraction: Double {
        outOf == 0 ? 0 : Double(total) / Double(outOf)
    }

    /// As it arrives from the API: a mark above its maximum comes down to it and its note says so; below 0 is 0.
    public static func clamped(_ raw: CheckResult) -> CheckResult {
        var result = raw
        result.questions = raw.questions.map { question in
            guard question.marks > question.of || question.marks < 0 else { return question }
            let over = question.marks > question.of
            return QuestionMark(
                number: question.number, text: question.text,
                note: over ? "\(question.note) (was \(question.marks), over the question's marks)" : question.note,
                marks: over ? question.of : 0, of: question.of, changedFrom: nil
            )
        }
        return result
    }
}

/// The tutor changing a mark (P6-Check-MarkPicker).
public enum MarkEdit {
    /// Within 0 to the question's marks; the suggestion is remembered once and forgotten when set back to it.
    public static func set(_ result: CheckResult, question number: Int, to marks: Int) -> CheckResult {
        guard let index = result.questions.firstIndex(where: { $0.number == number }) else { return result }
        var edited = result
        var question = edited.questions[index]
        let original = question.changedFrom ?? question.marks
        question.marks = min(max(0, marks), question.of)
        question.changedFrom = question.marks == original ? nil : original
        edited.questions[index] = question
        return edited
    }

    /// "Save to Hemanth's notes", or with the total once any mark has changed.
    public static func saveLabel(_ result: CheckResult, studentFirstName: String) -> String {
        let changed = result.questions.contains { $0.changedFrom != nil }
        let what = changed ? "Save \(result.total) of \(result.outOf)" : "Save"
        return "\(what) to \(studentFirstName)'s notes"
    }
}

/// Where the marking scheme comes from: a paper the centre created, or the tutor's own text.
public enum SchemeSource: Hashable, Sendable {
    case paper(generationID: UUID)
    case typed(String)

    public static let typedLimit = 4000

    public var isValid: Bool {
        switch self {
        case .paper: return true
        case let .typed(text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && trimmed.count <= Self.typedLimit
        }
    }
}
