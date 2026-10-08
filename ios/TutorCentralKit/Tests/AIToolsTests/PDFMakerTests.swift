import Data
import Domain
import Foundation
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
}
