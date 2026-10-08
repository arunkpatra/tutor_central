import Foundation
import Testing
@testable import Domain

struct StudentNoteTests {
    @Test func theNoteLineAppendsOrRefuses() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let result = CheckResult(
            questions: [.init(number: 1, text: "q", note: "n", marks: 15, of: 20, changedFrom: nil)],
            summary: "Sign errors in Q4 and Q6; Q7 not attempted."
        )
        let line = StudentNoteLine.make(day: day, title: "Quadratic equations", result: result)
        #expect(line == "7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted.")
        #expect(StudentNoteLine.toast(studentFirstName: "Hemanth", title: "Quadratic equations", result: result)
            == "Saved to Hemanth's notes: 15 of 20 on Quadratic equations.")
        #expect(NotesAppend.append(line, to: nil) == line)
        #expect(NotesAppend.append(line, to: "Shy in class.") == "Shy in class.\n" + line)
        #expect(NotesAppend.append(line, to: "Ends with a newline\n") == "Ends with a newline\n" + line)
        let full = String(repeating: "x", count: 2000 - line.count)
        #expect(NotesAppend.append(line, to: full) == nil, "one more character than the limit")
        #expect(NotesAppend.append(line, to: String(full.dropLast())) != nil)
        #expect(NotesAppend.overflow(studentFirstName: "Hemanth")
            == "Hemanth's notes are full. Share the marks instead, or shorten the notes first.")
    }
}
