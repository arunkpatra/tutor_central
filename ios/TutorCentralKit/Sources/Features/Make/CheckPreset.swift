import Domain
import Foundation

/// What a mock's Mark from a photo opens Check a paper with (plan/phase-13-plan.md decision 13): the student, the
/// mock's
/// key, and where the mark is written.
public struct CheckPreset: Hashable, Sendable {
    public let studentID: UUID
    public let scheme: SchemeSource
    public let mark: MarkTarget

    public init(studentID: UUID, scheme: SchemeSource, mark: MarkTarget) {
        self.studentID = studentID
        self.scheme = scheme
        self.mark = mark
    }
}

/// The mark a saved check writes: the subject, the test's name, the exam and the mock it belongs to.
public struct MarkTarget: Hashable, Sendable {
    public let subject: String
    public let test: String
    public let schoolItemID: UUID?
    public let artefactID: UUID?

    public init(subject: String, test: String, schoolItemID: UUID?, artefactID: UUID?) {
        self.subject = subject
        self.test = test
        self.schoolItemID = schoolItemID
        self.artefactID = artefactID
    }
}
