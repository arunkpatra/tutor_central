import Foundation
import Testing
@testable import Domain

/// D48: lengths are counted as Postgres's char_length counts them (Unicode scalars), so Hindi or Tamil text the app
/// accepts is never refused by the save (Phase 6's minor 7).
struct StringLengthTests {
    @Test func theStoredCountIsWhatPostgresCounts() {
        // char_length counts code points: a conjunct is several, an emoji with a joiner more still.
        #expect("क्षत्रिय".storedCount == 8 && "क्षत्रिय".count == 3)
        #expect("👩‍🏫".storedCount == 3 && "👩‍🏫".count == 1)
        #expect("Riya".storedCount == 4)
    }

    @Test func everyLimitUsesTheStoredCount() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        var student = StudentDraft()
        student.name = "Riya"
        student.notes = String(repeating: "क्ष", count: 700) // 2,100 scalars, 700 graphemes
        #expect(student.problems(today: day).contains(.notesTooLong))
        student.notes = ""
        student.name = String(repeating: "क्ष", count: 30) // 90 scalars
        #expect(student.problems(today: day).contains(.nameTooLong))

        var event = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 10)))
        event.title = "x"
        event.note = String(repeating: "क्ष", count: 170) // 510 scalars
        #expect(event.problems.contains(.noteTooLong))

        #expect(!SchemeSource.typed(String(repeating: "क्ष", count: 1400)).isValid)
        #expect(!GenerateRequest.progressNote(NoteForm(
            studentID: UUID(), observations: String(repeating: "क्ष", count: 700), tone: .warm
        )).isValid)
        #expect(NotesAppend.append(String(repeating: "क्ष", count: 10), to: String(repeating: "a", count: 1975)) == nil)
    }
}
