import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answers on 2026-10-08: a bulk insert of two students, the delete of both, a notes update and its
/// undo.
struct StudentWriteRowTests {
    static let inserted = Data("""
    [{"id":"304ba383-7481-4c35-96bd-6e63a1b0d3f2","name":"Aarav Mehta",\
    "class_id":"33333333-3333-3333-3333-333333333331","monthly_fee":null,"parent_name":null,\
    "parent_phone":"+919876543210","date_of_birth":null,"gender":null,"notes":null,"archived_at":null}, \
     {"id":"36ce1230-3997-432e-9794-0bb245212cb6","name":"Kavya Nair",\
    "class_id":"33333333-3333-3333-3333-333333333331",\
    "monthly_fee":1200,"parent_name":null,"parent_phone":null,"date_of_birth":null,"gender":null,"notes":null,\
    "archived_at":null}]
    """.utf8)
    static let deleted = Data("""
    [{"id":"304ba383-7481-4c35-96bd-6e63a1b0d3f2"}, \
     {"id":"36ce1230-3997-432e-9794-0bb245212cb6"}]
    """.utf8)
    static let notes = Data("""
    [{"id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533",\
    "notes":"7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted."}]
    """.utf8)
    static let notesCleared = Data("""
    [{"id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533","notes":null}]
    """.utf8)

    @Test func decodesTheInsertedStudentsInOrder() throws {
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: Self.inserted)
        let students = rows.map { $0.student(calendar: DayHeading.india) }
        #expect(students.map(\.name) == ["Aarav Mehta", "Kavya Nair"])
        #expect(students[0].parentPhone?.e164 == "+919876543210" && students[0].monthlyFee == nil)
        #expect(students[1].parentPhone == nil && students[1].monthlyFee == Money(rupees: 1200))
        let ids = try SupabaseStudentsRepository.decoder.decode([IDRow].self, from: Self.deleted).map(\.id)
        #expect(ids.count == 2 && ids.first == UUID(uuidString: "304ba383-7481-4c35-96bd-6e63a1b0d3f2"))
    }

    @Test func decodesANotesUpdateAndItsUndo() throws {
        let row = try #require(try SupabaseStudentsRepository.decoder.decode([NotesRow].self, from: Self.notes).first)
        #expect(row.notes?.hasPrefix("7 Oct · Quadratic equations · 15 of 20") == true)
        let cleared = try #require(try SupabaseStudentsRepository.decoder.decode(
            [NotesRow].self,
            from: Self.notesCleared
        )
        .first)
        #expect(cleared.notes == nil)
    }
}
