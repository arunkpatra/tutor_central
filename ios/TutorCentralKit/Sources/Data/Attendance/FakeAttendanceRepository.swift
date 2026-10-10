import Domain
import Foundation
import Supabase

/// The in-memory attendance for tests, previews and `bun shots`: `seed.sql`'s rule (the four weeks before Wednesday
/// 7 October 2026 on each class's meeting days, every fifth mark absent ordered by date and name), a scripted error,
/// a delay, a record of every save.
@MainActor public final class FakeAttendanceRepository: AttendanceRepository {
    /// One call to `save`.
    public struct Save: Hashable, Sendable {
        public let classID: UUID?
        public let date: Day
        public let marks: [UUID: AttendanceStatus]
    }

    public nonisolated static let hemanth = FakeStudentsRepository.seed[4].id

    public nonisolated static let seed: [AttendanceSession] = {
        let calendar = DayHeading.india
        let today = Day(year: 2026, month: 10, day: 7)!
        var rows: [SeedMark] = []
        for offset in (1 ... 27).reversed() {
            let day = today.adding(days: -offset, calendar: calendar)
            for classroom in FakeClassesRepository.seed
                where classroom.meetingDays.contains(day.weekday(in: calendar)) {
                for student in FakeStudentsRepository.seed where student.classID == classroom.id {
                    rows.append(SeedMark(day: day, student: student, classroom: classroom))
                }
            }
        }
        rows.sort { $0.day != $1.day ? $0.day < $1.day : $0.student.name < $1.student.name }
        var sessions: [Day: [UUID: AttendanceSession]] = [:]
        for (index, row) in rows.enumerated() {
            let status: AttendanceStatus = (index + 1) % 5 == 0 ? .absent : .present
            var session = sessions[row.day]?[row.classroom.id] ?? AttendanceSession(
                id: sessionID(row.day, row.classroom), classID: row.classroom.id, date: row.day,
                savedAt: savedAt(row.day), marks: [:]
            )
            session.marks[row.student.id] = status
            sessions[row.day, default: [:]][row.classroom.id] = session
        }
        return sessions.values.flatMap(\.values).sorted { $0.date > $1.date }
    }()

    /// The states after a save: Wednesday 7 October's Class 10 Maths at 18:04, Hemanth absent.
    public nonisolated static let seedWithToday: [AttendanceSession] = {
        let today = Day(year: 2026, month: 10, day: 7)!
        let maths = FakeClassesRepository.maths
        let marks = Dictionary(uniqueKeysWithValues: FakeStudentsRepository.seed.filter { $0.classID == maths.id }
            .map { ($0.id, $0.id == hemanth ? AttendanceStatus.absent : .present) })
        let saved = AttendanceSession(
            id: sessionID(today, maths), classID: maths.id, date: today, savedAt: savedAt(today), marks: marks
        )
        return [saved] + seed
    }()

    /// Wednesday 7 October's Class 10 Maths closed at 18:32, Hemanth absent (P10-Today-AfterClose's moment).
    public nonisolated static let seedWithTodayClosed: [AttendanceSession] = {
        var sessions = seedWithToday
        sessions[0].closedAt = closedAt
        return sessions
    }()

    /// 18:32 on Wednesday 7 October, India: the fixtures' close.
    public nonisolated static let closedAt = DayHeading.india.date(from: DateComponents(
        year: 2026, month: 10, day: 7, hour: 18, minute: 32
    ))!

    /// What PostgREST answers for an expired token.
    public nonisolated static let signedOutError = PostgrestError(code: "PGRST301", message: "JWT expired")

    public var sessions: [AttendanceSession]
    public var nextError: (any Error)?
    /// A failure for the next save only (reads go through): a board's refused save.
    public var saveError: (any Error)?
    /// Every call waits this long first: lets a store show its loading state.
    public var delay: Duration?
    public private(set) var saves: [Save] = []
    public private(set) var closes: [SessionClose] = []
    private let now: () -> Date

    public init(sessions: [AttendanceSession] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.sessions = sessions
        self.now = now
    }

    public func sessions(centre _: UUID, month: Period) async throws -> [AttendanceSession] {
        try await begin()
        return AttendanceStats.sessions(sessions, in: month).sorted { $0.date > $1.date }
    }

    public func save(
        centre _: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]
    ) async throws -> AttendanceSession {
        try await begin()
        if let error = saveError {
            saveError = nil
            throw error
        }
        saves.append(Save(classID: classID, date: date, marks: marks))
        if let index = sessions.firstIndex(where: { $0.date == date && $0.classID == classID }) {
            sessions[index].marks = marks
            sessions[index].savedAt = now()
            return sessions[index]
        }
        let made = AttendanceSession(id: UUID(), classID: classID, date: date, savedAt: now(), marks: marks)
        sessions.append(made)
        return made
    }

    /// The close keeps its attendance as `save` does; the checks, homework and status are only recorded.
    public func close(_ close: SessionClose, centre: UUID) async throws -> UUID {
        let session = try await save(centre: centre, classID: close.classID, date: close.date, marks: close.marks)
        closes.append(close)
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index].closedAt = now()
        }
        return session.id
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }

    /// One mark the seed's rule makes, before it is numbered.
    private struct SeedMark {
        let day: Day
        let student: Student
        let classroom: Classroom
    }

    /// Saved at 18:04 on the day, India.
    private nonisolated static func savedAt(_ day: Day) -> Date {
        DayHeading.india.date(from: DateComponents(
            year: day.year,
            month: day.month,
            day: day.day,
            hour: 18,
            minute: 4
        ))!
    }

    /// A fixed id per class and day, so the fixtures and the boards agree across launches.
    private nonisolated static func sessionID(_ day: Day, _ classroom: Classroom) -> UUID {
        let classNumber = classroom.id.uuidString.last.flatMap { Int(String($0)) } ?? 0
        return UUID(uuidString: String(
            format: "bbbbbbbb-%04d-%02d%02d-0000-%012d", day.year, day.month, day.day, classNumber
        ))!
    }
}
