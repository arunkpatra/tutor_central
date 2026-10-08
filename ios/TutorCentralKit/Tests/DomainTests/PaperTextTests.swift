import Foundation
import Testing
@testable import Domain

struct PaperTextTests {
    @Test func aPaperReadsAsPlainTextWithTheKeyLast() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: GenerationResultTests.paperJSON))
        let text = PaperText.plain(result)
        let first = "1. Which of the following is a quadratic equation in x? (1 mark)\n"
        #expect(text.hasPrefix("Quadratic equations\n\nSection A (1 mark each)\n" + first))
        #expect(text.contains("\nSection C (4 marks each)\n9. A train travels 360 km… (4 marks)\n"))
        #expect(text.hasSuffix("\nAnswer key\n1. (a)\n2. −8\n9. 40 km/h"))
        #expect(PaperText.plain(.progressNote(NoteResult(note: "Hello Lakshmi."))) == "Hello Lakshmi.")
        let set = QuestionSetResult(
            title: "Fractions", instructions: "Show your working.",
            questions: [.init(number: 1, text: "Add ½ and ⅓.", answer: "⅚")]
        )
        #expect(PaperText
            .plain(.homework(set)) == "Fractions\n\nShow your working.\n\n1. Add ½ and ⅓.\n\nAnswer key\n1. ⅚")
    }

    @Test func aWorksheetWhoseKeyIsOffLeavesTheKeyOut() {
        let set = QuestionSetResult(
            title: "Fractions", instructions: nil, questions: [.init(number: 1, text: "Add ½ and ⅓.", answer: "⅚")]
        )
        let off = Generation(
            id: UUID(), kind: .worksheet, createdAt: Date(),
            request: .worksheet(WorksheetForm(withAnswers: false)), result: .worksheet(set)
        )
        let on = Generation(
            id: UUID(), kind: .worksheet, createdAt: Date(), request: .worksheet(WorksheetForm()),
            result: .worksheet(set)
        )
        let unknown = Generation(id: UUID(), kind: .worksheet, createdAt: Date(), request: nil, result: .worksheet(set))
        #expect(!off.printsKey && on.printsKey && unknown.printsKey)
        #expect(PaperText.plain(.worksheet(set), key: false) == "Fractions\n\n1. Add ½ and ⅓.")
        #expect(PaperText.plain(.worksheet(set)).hasSuffix("Answer key\n1. ⅚"))
    }
}
