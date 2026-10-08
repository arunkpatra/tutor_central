import Domain
import Foundation

/// The in-memory message log for tests, previews and `bun shots`: Hemanth's parent told on Monday 5 October, a
/// scripted error, a record of every log.
@MainActor public final class FakeMessageLogRepository: MessageLogRepository {
    /// Hemanth's parent told on Monday 5 October at 18:10 (P4-Attendance-Mark-PastDate, P4-History-Student).
    public nonisolated static let seed = [
        AbsenceLog(
            studentID: FakeAttendanceRepository.hemanth,
            openedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 18, minute: 10))!,
            aboutDate: Day(year: 2026, month: 10, day: 5)
        ),
    ]

    /// Dev reminded on Tuesday 6 October about October; Nikhil on Wednesday 30 September about September
    /// (P5-Fees-All, P5-Fees-Overdue).
    public nonisolated static let feeSeed = [
        FeeLog(
            studentID: FakeStudentsRepository.id(4), kind: .reminder,
            openedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 10, minute: 15))!,
            month: Period(year: 2026, month: 10)
        ),
        FeeLog(
            studentID: FakeStudentsRepository.id(8), kind: .reminder,
            openedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 18))!,
            month: Period(year: 2026, month: 9)
        ),
    ]

    public var logs: [AbsenceLog]
    public var feeLogs: [FeeLog]
    public var nextError: (any Error)?
    public private(set) var logged: [UUID] = []
    public private(set) var feeLogged: [FeeLog] = []
    public private(set) var progressLogs: [UUID] = []
    private let now: () -> Date

    public init(
        logs: [AbsenceLog] = [], feeLogs: [FeeLog] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }
    ) {
        self.logs = logs
        self.feeLogs = feeLogs
        self.now = now
    }

    public func absences(centre _: UUID, month: Period) async throws -> [AbsenceLog] {
        try takeError()
        return logs.filter { $0.day(in: DayHeading.india).period == month }
            .sorted { $0.openedAt > $1.openedAt }
    }

    public func logAbsence(centre _: UUID, studentID: UUID, about: Day) async throws -> AbsenceLog {
        try takeError()
        logged.append(studentID)
        let made = AbsenceLog(studentID: studentID, openedAt: now(), aboutDate: about)
        logs.append(made)
        return made
    }

    public func feeLogs(centre _: UUID, month: Period) async throws -> [FeeLog] {
        try takeError()
        return feeLogs.filter { $0.month == month }.sorted { $0.openedAt > $1.openedAt }
    }

    public func feeLogs(centre _: UUID, student: UUID) async throws -> [FeeLog] {
        try takeError()
        return feeLogs.filter { $0.studentID == student }.sorted { $0.openedAt > $1.openedAt }
    }

    public func logFee(centre _: UUID, studentID: UUID, kind: FeeLog.Kind, month: Period) async throws -> FeeLog {
        try takeError()
        let made = FeeLog(studentID: studentID, kind: kind, openedAt: now(), month: month)
        feeLogged.append(made)
        feeLogs.append(made)
        return made
    }

    public func logProgress(centre _: UUID, studentID: UUID) async throws -> Date {
        try takeError()
        progressLogs.append(studentID)
        return now()
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
