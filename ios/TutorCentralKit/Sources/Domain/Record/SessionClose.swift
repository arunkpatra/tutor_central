import Foundation

/// The close of a class (docs/spec-v2.md section 6): who came, the checks tapped, the homework given and each student's
/// tracking status, the skill states that moved and the plan's lines done, written in one call by `close_session`
/// (migrations 0010, 0017, 0019).
/// Attendance alone is a close. `Codable`, so a close made offline waits in the queue (plan decision 18).
public struct SessionClose: Hashable, Sendable, Codable {
    public struct Check: Hashable, Sendable, Codable {
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

    public struct Homework: Hashable, Sendable, Codable {
        public let studentID: UUID
        /// The sheet given; none when the close runs without a plan.
        public let artefactID: UUID?

        public init(studentID: UUID, artefactID: UUID?) {
            self.studentID = studentID
            self.artefactID = artefactID
        }
    }

    public struct Track: Hashable, Sendable, Codable {
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
    public let states: [SkillStateChange]
    /// The plan's lines the tutor ticked (`plan_items.done_at` through `close_session`'s `p_done`); none without a
    /// plan.
    public let done: [UUID]

    public init(
        classID: UUID?,
        date: Day,
        marks: [UUID: AttendanceStatus],
        checks: [Check],
        homework: [Homework],
        track: [UUID: Track],
        states: [SkillStateChange] = [],
        done: [UUID] = []
    ) {
        self.classID = classID
        self.date = date
        self.marks = marks
        self.checks = checks
        self.homework = homework
        self.track = track
        self.states = states
        self.done = done
    }

    /// A close kept in the queue by build 20 has no done lines.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            classID: c.decodeIfPresent(UUID.self, forKey: .classID),
            date: c.decode(Day.self, forKey: .date),
            marks: c.decode([UUID: AttendanceStatus].self, forKey: .marks),
            checks: c.decode([Check].self, forKey: .checks),
            homework: c.decode([Homework].self, forKey: .homework),
            track: c.decode([UUID: Track].self, forKey: .track),
            states: c.decodeIfPresent([SkillStateChange].self, forKey: .states) ?? [],
            done: c.decodeIfPresent([UUID].self, forKey: .done) ?? []
        )
    }
}
