import Data
import DesignSystem
import Domain
import Foundation
import PDFKit
import Testing
@testable import AITools

@MainActor struct ResultPDFTests {
    @Test func aPaperBecomesAPDFFileNamedAfterIt() throws {
        let result = try #require(GenerationResult.decode(kind: .paper, output: AISamples.paperJSON))
        let url = try PDFMaker.pdf(for: result.pdfSheet(title: "Quadratic equations", key: true))
        #expect(url.lastPathComponent == "Quadratic equations.pdf")
        let data = try Data(contentsOf: url)
        #expect(data.prefix(5) == Data("%PDF-".utf8))
        #expect(data.count > 2000)
    }

    @Test func aTitleThatIsNotAFileNameStillMakesOne() throws {
        let note = GenerationResult.progressNote(AISamples.note)
        let url = try PDFMaker.pdf(for: note.pdfSheet(title: "Hemanth / Oct: note", key: true))
        #expect(url.lastPathComponent == "Hemanth - Oct- note.pdf")
    }

    @Test func aPDFWithoutTheKeyLeavesTheAnswersOut() throws {
        let set = QuestionSetResult(
            title: "Fractions", instructions: nil,
            questions: [.init(number: 1, text: "Add half and a third.", answer: "Five sixths")]
        )
        let result = GenerationResult.worksheet(set)
        let with = try #require(PDFDocument(url: PDFMaker.pdf(for: result.pdfSheet(title: "With", key: true))))
        let without = try #require(PDFDocument(url: PDFMaker.pdf(for: result.pdfSheet(title: "Without", key: false))))
        #expect(with.string?.contains("Five sixths") == true)
        #expect(without.string?.contains("Add half") == true)
        #expect(without.string?.contains("Five sixths") == false)
        #expect(without.string?.contains("Answer key") == false)
    }
}
