import Foundation

/// A mark on the student's page (`marks`): a marked mock or a checked paper this phase; school tests from Phase 14.
public struct MarkRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let studentID: UUID
    public let subject: String
    public let test: String
    public let date: Day
    public let score: Int
    public let max: Int
    public let photoPath: String?
    public let schoolItemID: UUID?
    public let artefactID: UUID?
    public let questions: [CheckResult.QuestionMark]?

    public init(
        id: UUID, studentID: UUID, subject: String, test: String, date: Day, score: Int, max: Int, photoPath: String?,
        schoolItemID: UUID?, artefactID: UUID?, questions: [CheckResult.QuestionMark]?
    ) {
        self.id = id
        self.studentID = studentID
        self.subject = subject
        self.test = test
        self.date = date
        self.score = score
        self.max = max
        self.photoPath = photoPath
        self.schoolItemID = schoolItemID
        self.artefactID = artefactID
        self.questions = questions
    }

    /// "14 of 25".
    public var line: String {
        "\(score) of \(max)"
    }

    var percentage: Double {
        max > 0 ? Double(score) * 100 / Double(max) : 0
    }
}

/// A mark before it is written.
public struct NewMark: Hashable, Sendable {
    public let studentID: UUID
    public let subject: String
    public let test: String
    public let date: Day
    public let score: Int
    public let max: Int
    public let photoPath: String?
    public let schoolItemID: UUID?
    public let artefactID: UUID?
    public let questions: [CheckResult.QuestionMark]?

    public init(
        studentID: UUID, subject: String, test: String, date: Day, score: Int, max: Int, photoPath: String? = nil,
        schoolItemID: UUID? = nil, artefactID: UUID? = nil, questions: [CheckResult.QuestionMark]? = nil
    ) {
        self.studentID = studentID
        self.subject = subject
        self.test = test
        self.date = date
        self.score = score
        self.max = max
        self.photoPath = photoPath
        self.schoolItemID = schoolItemID
        self.artefactID = artefactID
        self.questions = questions
    }
}

/// When a mark reads "Below usual" (P10-Student-Record; plan/phase-13-plan.md decision 24).
public enum MarkRules {
    public static let belowUsualPoints = 10.0

    /// Two earlier marks in the subject at least, and this one more than ten points under their mean percentage.
    public static func belowUsual(_ mark: MarkRecord, earlier: [MarkRecord]) -> Bool {
        let before = earlier.filter { $0.subject == mark.subject && $0.date < mark.date && $0.id != mark.id }
        guard before.count >= 2 else { return false }
        let mean = before.map(\.percentage).reduce(0, +) / Double(before.count)
        return mean - mark.percentage > belowUsualPoints
    }
}

/// A row read from a photo of a report card or a marked test (P14-Marks-Confirm), checked by the tutor before a mark is
/// written; a row with no date stays unticked until one is set.
public struct ReadMark: Hashable, Sendable, Codable {
    public var subject: String
    public var test: String
    public var date: Day?
    public var score: Int
    public var max: Int

    public init(subject: String, test: String, date: Day?, score: Int, max: Int) {
        self.subject = subject
        self.test = test
        self.date = date
        self.score = score
        self.max = max
    }
}
