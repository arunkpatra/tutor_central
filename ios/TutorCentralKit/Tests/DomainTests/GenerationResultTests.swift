import Foundation
import Testing
@testable import Domain

struct GenerationResultTests {
    static let paperJSON = """
    {"title":"Quadratic equations","sections":[{"title":"Section A","marksEach":1,"questions":[{"number":1,\
    "text":"Which of the following is a quadratic equation in x?","marks":1,"answer":"(a)"},{"number":2,\
    "text":"Write the discriminant of 2x² − 4x + 3 = 0.","marks":1,"answer":"−8"}]},{"title":"Section C",\
    "marksEach":4,"questions":[{"number":9,"text":"A train travels 360 km…","marks":4,"answer":"40 km/h"}]}]}
    """
    static let noteJSON = #"{"note":"Hello Lakshmi, a quick note on Hemanth's progress."}"#
    static let sixOct = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 18, minute: 32))
        ?? .distantPast
    static let maths = UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID()

    @Test func decodesEachKindAndRefusesTheWrongShape() throws {
        let paper = try #require(GenerationResult.decode(kind: .paper, output: Self.paperJSON))
        guard case let .paper(result) = paper else {
            Issue.record("not a paper")
            return
        }
        #expect(result.title == "Quadratic equations" && result.questionCount == 3 && result.totalMarks == 6)
        #expect(result.sections.map(\.title) == ["Section A", "Section C"])
        let note = try #require(GenerationResult.decode(kind: .progressNote, output: Self.noteJSON))
        #expect(note.title == "Progress note")
        #expect(GenerationResult.decode(kind: .paper, output: Self.noteJSON) == nil)
        #expect(GenerationResult.decode(kind: .homework, output: "{not json") == nil)
    }

    @Test func aGenerationHasItsTitleLineAndHeroLine() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: Self.paperJSON))
        let form = PaperForm(classID: Self.maths, subject: "Mathematics", topic: "Quadratic equations")
        let generation = Generation(
            id: UUID(),
            kind: .paper,
            createdAt: Self.sixOct,
            request: .paper(form),
            result: result
        )
        #expect(generation.title(studentName: { _ in nil }) == "Quadratic equations")
        let line = generation.line(className: { $0 == Self.maths ? "Class 10 Maths" : nil }, calendar: DayHeading.india)
        #expect(line == "Question paper · Class 10 Maths · Tue 6 Oct")
        let seventh = try #require(Day(year: 2026, month: 10, day: 7))
        #expect(generation.heroLine(today: seventh, calendar: DayHeading.india)
            == "3 questions · 6 marks · Medium · created Tue 6 Oct, 18:32")
        let sixth = try #require(Day(year: 2026, month: 10, day: 6))
        #expect(generation.heroLine(today: sixth, calendar: DayHeading.india)
            == "3 questions · 6 marks · Medium · created today, 18:32")
        let noteForm = NoteForm(studentID: Self.maths, observations: "x", tone: .warm)
        let note = Generation(
            id: UUID(), kind: .progressNote, createdAt: Self.sixOct, request: .progressNote(noteForm),
            result: .progressNote(NoteResult(note: "n"))
        )
        #expect(note.title(studentName: { _ in "Hemanth Reddy" }) == "Hemanth Reddy")
        #expect(note.line(className: { _ in "Class 10 Maths" }, calendar: DayHeading.india)
            == "Progress note · Class 10 Maths · Tue 6 Oct")
        let orphan = Generation(
            id: UUID(), kind: .homework, createdAt: Self.sixOct, request: nil,
            result: .homework(QuestionSetResult(title: "Fractions", instructions: nil, questions: []))
        )
        #expect(orphan.line(className: { _ in nil }, calendar: DayHeading.india) == "Homework · No class · Tue 6 Oct")
    }
}
