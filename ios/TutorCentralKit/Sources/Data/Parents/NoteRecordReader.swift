import Domain
import Foundation

/// The record a parent's note is written from, read for a set of students since a day (Phase 14): each student's book,
/// their checks and marks, the sessions of the months the span touches and the school's items, read together. Today's
/// note day and the note screen both read through it, so they see the same week.
public struct NoteRecordReader: Sendable {
    let textbooks: any TextbooksRepository
    let record: any RecordRepository
    let attendance: any AttendanceRepository
    let schoolItems: (any SchoolItemsRepository)?

    public init(
        textbooks: any TextbooksRepository, record: any RecordRepository, attendance: any AttendanceRepository,
        schoolItems: (any SchoolItemsRepository)?
    ) {
        self.textbooks = textbooks
        self.record = record
        self.attendance = attendance
        self.schoolItems = schoolItems
    }

    /// By student; a failed read of a book, the checks, the marks or the sessions throws (the school's items are
    /// optional).
    public func read(
        _ students: [Student], centre: UUID, from first: Day, to last: Day, calendar: Calendar
    ) async throws -> [UUID: NoteRecord] {
        let ids = students.map(\.id)
        async let checksRead = record.checks(centre: centre, students: ids, since: first.date(in: calendar))
        async let marksRead = record.marks(centre: centre, students: ids)
        async let sessionsRead = sessions(from: first, to: last, centre: centre)
        async let itemsRead = try? schoolItems?.items(centre: centre)
        let books = try await books(ids)
        let checks = try await checksRead
        let marks = try await marksRead
        let sessions = try await sessionsRead
        let items = await itemsRead ?? []
        var records: [UUID: NoteRecord] = [:]
        for student in students {
            let book = books[student.id] ?? Book()
            records[student.id] = NoteRecord(
                student: student, chapters: book.chapters, skills: book.skills,
                checks: checks.filter { $0.studentID == student.id }, sessions: sessions,
                marks: marks.filter { $0.studentID == student.id }, items: items
            )
        }
        return records
    }

    struct Book: Sendable {
        var chapters: [Chapter] = []
        var skills: [Skill] = []
    }

    private func books(_ ids: [UUID]) async throws -> [UUID: Book] {
        try await withThrowingTaskGroup(of: (UUID, Book).self) { group in
            for id in ids {
                group.addTask { [textbooks] in
                    async let chapters = textbooks.chapters(student: id)
                    async let skills = textbooks.skills(student: id)
                    return try await (id, Book(chapters: chapters, skills: skills))
                }
            }
            var books: [UUID: Book] = [:]
            for try await (id, book) in group {
                books[id] = book
            }
            return books
        }
    }

    /// The sessions of the months from `first` to `last`.
    private func sessions(from first: Day, to last: Day, centre: UUID) async throws -> [AttendanceSession] {
        var periods = [first.period]
        if last.period != first.period {
            periods.append(last.period)
        }
        var all: [AttendanceSession] = []
        for period in periods {
            all += try await attendance.sessions(centre: centre, month: period)
        }
        return all
    }
}
