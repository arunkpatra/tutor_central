import Data
import Domain
import Foundation
import PDFKit
import Testing
@testable import AITools

@MainActor struct PDFMakerTests {
    @Test func aPaperBecomesAPDFFileNamedAfterIt() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: AISamples.paperJSON))
        let url = try PDFMaker.pdf(for: result, title: "Quadratic equations")
        #expect(url.lastPathComponent == "Quadratic equations.pdf")
        let data = try Data(contentsOf: url)
        #expect(data.prefix(5) == Data("%PDF-".utf8))
        #expect(data.count > 2000)
    }

    @Test func aTitleThatIsNotAFileNameStillMakesOne() throws {
        let url = try PDFMaker.pdf(for: .progressNote(AISamples.note), title: "Hemanth / Oct: note")
        #expect(url.lastPathComponent == "Hemanth - Oct- note.pdf")
    }

    @Test func aPDFWithoutTheKeyLeavesTheAnswersOut() throws {
        let set = QuestionSetResult(
            title: "Fractions", instructions: nil,
            questions: [.init(number: 1, text: "Add half and a third.", answer: "Five sixths")]
        )
        let with = try #require(PDFDocument(url: PDFMaker.pdf(for: .worksheet(set), title: "With")))
        let without = try #require(PDFDocument(url: PDFMaker.pdf(for: .worksheet(set), title: "Without", key: false)))
        #expect(with.string?.contains("Five sixths") == true)
        #expect(without.string?.contains("Add half") == true)
        #expect(without.string?.contains("Five sixths") == false)
        #expect(without.string?.contains("Answer key") == false)
    }
}
