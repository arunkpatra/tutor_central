import Domain
import Foundation

/// What Reports' Progress is worked out from (plan/phase-15-plan.md decision 18): every listed student's chapters and
/// skills, their checks since the span's first day and the sessions of the span's months, read together, one read per
/// table and month.
public struct ProgressReader: Sendable {
    let textbooks: any TextbooksRepository
    let record: any RecordRepository
    let attendance: any AttendanceRepository

    public init(
        textbooks: any TextbooksRepository,
        record: any RecordRepository,
        attendance: any AttendanceRepository
    ) {
        self.textbooks = textbooks
        self.record = record
        self.attendance = attendance
    }

    /// By student; a failed read of any table throws.
    public func read(
        _ students: [Student], span: ProgressSpan, centre: UUID, calendar: Calendar
    ) async throws -> [UUID: ProgressInput] {
        let ids = students.map(\.id)
        let first = span.months[0].start(in: calendar.timeZone)
        async let booksRead = textbooks.books(centre: centre, students: ids)
        async let checksRead = record.checks(centre: centre, students: ids, since: first)
        async let sessionsRead = sessions(span.months, centre: centre)
        let books = try await booksRead
        let checks = try await checksRead
        let sessions = try await sessionsRead
        return Dictionary(uniqueKeysWithValues: students.map { student in
            let book = books[student.id] ?? RecordBook(chapters: [], skills: [])
            return (student.id, ProgressInput(
                student: student, chapters: book.chapters, skills: book.skills,
                checks: checks.filter { $0.studentID == student.id },
                sessions: sessions.filter { $0.marks[student.id] != nil }, span: span, calendar: calendar
            ))
        })
    }

    private func sessions(_ months: [Period], centre: UUID) async throws -> [AttendanceSession] {
        var all: [AttendanceSession] = []
        for month in months {
            all += try await attendance.sessions(centre: centre, month: month)
        }
        return all
    }
}
