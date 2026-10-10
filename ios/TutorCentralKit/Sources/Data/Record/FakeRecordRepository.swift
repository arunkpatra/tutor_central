import Domain
import Foundation

/// The in-memory record for tests, previews and `bun shots`: Hemanth's checks (three a class, the trend's pattern) and
/// homework at the seed's Class 10 Maths sessions he came to, a scripted error, every write recorded.
@MainActor public final class FakeRecordRepository: RecordRepository {
    public private(set) var checks: [CheckRecord]
    public private(set) var homework: [HomeworkRecord]
    public private(set) var placements: [PlacementRecord] = []
    public private(set) var statusChanges: [StatusChange] = []
    public var nextError: (any Error)?

    /// One homework status written.
    public struct StatusChange: Hashable, Sendable {
        public let id: UUID
        public let status: HomeworkStatus
    }

    public init(checks: [CheckRecord] = seedChecks, homework: [HomeworkRecord] = seedHomework) {
        self.checks = checks
        self.homework = homework
    }

    public func checks(centre _: UUID, students: [UUID], since: Date) async throws -> [CheckRecord] {
        try begin()
        return checks.filter { students.contains($0.studentID) && $0.at >= since }.sorted { $0.at < $1.at }
    }

    public func homework(centre _: UUID, students: [UUID], since: Date) async throws -> [HomeworkRecord] {
        try begin()
        return homework.filter { students.contains($0.studentID) && $0.givenAt >= since }
            .sorted { $0.givenAt > $1.givenAt }
    }

    public func setHomeworkStatus(id: UUID, _ status: HomeworkStatus) async throws {
        try begin()
        statusChanges.append(StatusChange(id: id, status: status))
        guard let index = homework.firstIndex(where: { $0.id == id }) else { return }
        homework[index].status = status
    }

    public func recordPlacement(_ placement: PlacementRecord, centre _: UUID) async throws {
        try begin()
        placements.append(placement)
        checks += placement.checks.map { check in
            CheckRecord(
                id: UUID(),
                studentID: check.studentID,
                skillID: check.skillID,
                sessionID: nil,
                question: check.question,
                correct: check.correct,
                at: FakeCountsRepository.fixedNow,
                isPlacement: true
            )
        }
    }

    private func begin() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}

public extension FakeRecordRepository {
    /// Right answers of three, oldest session first (the trend's bars).
    nonisolated static let pattern = [3, 2, 3, 1, 2, 3, 2, 2, 3, 1, 2, 3]

    /// The Class 10 Maths sessions of the attendance seed Hemanth came to, the last twelve, oldest first.
    private nonisolated static var hemanthsSessions: [AttendanceSession] {
        let maths = FakeClassesRepository.maths.id
        let hemanth = FakeStudentsRepository.hemanth
        return Array(FakeAttendanceRepository.seed.filter { $0.classID == maths && $0.marks[hemanth] == .present }
            .sorted { $0.date < $1.date }.suffix(pattern.count))
    }

    /// Three checks a session on Hemanth's taught skills, right as the pattern says.
    nonisolated static var seedChecks: [CheckRecord] {
        let skills = FakeTextbooksRepository.seedSkills[FakeStudentsRepository.hemanth, default: []]
            .filter { $0.state != .notStarted }
        let sessions = hemanthsSessions
        let offset = pattern.count - sessions.count
        return sessions.enumerated().flatMap { index, session in
            let right = pattern[index + offset]
            return (0 ..< 3).map { number in
                let skill = skills[(index * 3 + number) % max(skills.count, 1)]
                return CheckRecord(
                    id: UUID(), studentID: FakeStudentsRepository.hemanth, skillID: skill.id, sessionID: session.id,
                    question: "A question on \(skill.name)", correct: number < right,
                    at: session.savedAt.addingTimeInterval(Double(number) * 60), isPlacement: false
                )
            }
        }
    }

    /// Homework given at Hemanth's last four sessions: the newest still given, two not done, one done.
    nonisolated static var seedHomework: [HomeworkRecord] {
        let statuses: [HomeworkStatus] = [.done, .notDone, .notDone, .given]
        return hemanthsSessions.suffix(statuses.count).enumerated().map { index, session in
            HomeworkRecord(
                id: UUID(uuidString: String(format: "dddddddd-0000-0000-0000-%012d", index + 1))!,
                studentID: FakeStudentsRepository.hemanth, sessionID: session.id, givenAt: session.savedAt,
                status: statuses[index]
            )
        }
    }
}

public extension FakeRecordRepository {
    /// The close of `FakeAttendanceRepository.seedWithTodayClosed`: three checks each for four of the five who came,
    /// eight right, and homework given to all five (P10-Today-AfterClose's counts).
    nonisolated static var todaysChecks: [CheckRecord] {
        checks(of: FakeAttendanceRepository.seedWithTodayClosed[0])
    }

    nonisolated static var todaysHomework: [HomeworkRecord] {
        homework(of: FakeAttendanceRepository.seedWithTodayClosed[0])
    }

    /// Three checks each for four of those who came, eight right.
    nonisolated static func checks(of session: AttendanceSession) -> [CheckRecord] {
        let checked = session.marks.filter { $0.value == .present }.map(\.key).sorted { $0.uuidString < $1.uuidString }
            .prefix(4)
        return checked.enumerated().flatMap { index, student in
            (0 ..< 3).map { number in
                CheckRecord(
                    id: UUID(), studentID: student, skillID: UUID(), sessionID: session.id,
                    question: "A question", correct: index * 3 + number < 8,
                    at: FakeAttendanceRepository.closedAt, isPlacement: false
                )
            }
        }
    }

    /// Homework given to each who came.
    nonisolated static func homework(of session: AttendanceSession) -> [HomeworkRecord] {
        session.marks.filter { $0.value == .present }.map(\.key).map { student in
            HomeworkRecord(
                id: UUID(), studentID: student, sessionID: session.id, givenAt: FakeAttendanceRepository.closedAt,
                status: .given
            )
        }
    }
}
