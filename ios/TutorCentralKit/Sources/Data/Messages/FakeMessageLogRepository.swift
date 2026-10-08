import Domain
import Foundation

/// The in-memory message log for tests, previews and `bun shots`: Hemanth's parent told on Monday 5 October, a
/// scripted error, a record of every log.
@MainActor public final class FakeMessageLogRepository: MessageLogRepository {
    /// Hemanth's parent told on Monday 5 October at 18:10 (P4-Attendance-Mark-PastDate, P4-History-Student).
    public nonisolated static let seed = [
        AbsenceLog(
            studentID: FakeAttendanceRepository.hemanth,
            openedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 18, minute: 10))!
        ),
    ]

    public var logs: [AbsenceLog]
    public var nextError: (any Error)?
    public private(set) var logged: [UUID] = []
    private let now: () -> Date

    public init(logs: [AbsenceLog] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.logs = logs
        self.now = now
    }

    public func absences(centre _: UUID, month: Period) async throws -> [AbsenceLog] {
        try takeError()
        return logs.filter { Day($0.openedAt, calendar: DayHeading.india).period == month }
            .sorted { $0.openedAt > $1.openedAt }
    }

    public func logAbsence(centre _: UUID, studentID: UUID) async throws -> AbsenceLog {
        try takeError()
        logged.append(studentID)
        let made = AbsenceLog(studentID: studentID, openedAt: now())
        logs.append(made)
        return made
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
