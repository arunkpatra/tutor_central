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
}
