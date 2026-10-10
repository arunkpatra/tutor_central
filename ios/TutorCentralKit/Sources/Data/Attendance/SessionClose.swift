import Domain
import Foundation

/// The close of a class (docs/spec-v2.md section 6): who came, the checks tapped, the homework given and each student's
/// tracking status, written in one call by `close_session` (migration 0010). Attendance alone is a close.
public struct SessionClose: Hashable, Sendable {
    public struct Check: Hashable, Sendable {
        public let studentID: UUID
        public let skillID: UUID
        public let question: String
        public let correct: Bool
        /// One of the placement's questions (a student with no checks yet).
        public let isPlacement: Bool

        public init(studentID: UUID, skillID: UUID, question: String, correct: Bool, isPlacement: Bool) {
            self.studentID = studentID
            self.skillID = skillID
            self.question = question
            self.correct = correct
            self.isPlacement = isPlacement
        }
    }

    public struct Homework: Hashable, Sendable {
        public let studentID: UUID
        /// The sheet given; none when the close runs without a plan.
        public let artefactID: UUID?

        public init(studentID: UUID, artefactID: UUID?) {
            self.studentID = studentID
            self.artefactID = artefactID
        }
    }

    public struct Track: Hashable, Sendable {
        public let status: TrackStatus
        public let reasons: [String]

        public init(status: TrackStatus, reasons: [String]) {
            self.status = status
            self.reasons = reasons
        }
    }

    public let classID: UUID?
    public let date: Day
    public let marks: [UUID: AttendanceStatus]
    public let checks: [Check]
    public let homework: [Homework]
    public let track: [UUID: Track]

    public init(
        classID: UUID?,
        date: Day,
        marks: [UUID: AttendanceStatus],
        checks: [Check],
        homework: [Homework],
        track: [UUID: Track]
    ) {
        self.classID = classID
        self.date = date
        self.marks = marks
        self.checks = checks
        self.homework = homework
        self.track = track
    }
}
