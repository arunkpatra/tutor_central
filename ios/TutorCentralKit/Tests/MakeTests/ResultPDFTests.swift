import Data
import DesignSystem
import Domain
import Foundation
import PDFKit
import Testing
@testable import Make

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

    // Phase 21 decision 9: Share on a V1 result takes the server's file (`pdfs/<centre>/gen-<id>.pdf`) when it can be
    // had,
    // else the phone draws its own (D93's wait).

    func paper() throws -> Generation {
        try #require(FakeAIHistoryRepository.seed.first { $0.kind == .paper })
    }

    func server(wait: Duration = .seconds(5), download: @escaping ServerFiles.Download) -> ServerPDF {
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let files = ServerFiles(
            centre: centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString),
            download: download
        )
        return ServerPDF(files: files, centre: centre, wait: wait)
    }

    @Test func shareTakesTheServersFileOnceItIsOnTheIPhone() async throws {
        let paper = try paper()
        let shared = try #require(await ResultPDF.file(
            for: paper,
            title: "Quadratic equations",
            server: server { _, path in
                Data(path.utf8)
            }
        ))
        let centre = FakeCentreRepository.meeraWorkspace.centre.id.uuidString.lowercased()
        #expect(try String(contentsOf: shared, encoding: .utf8) ==
            "\(centre)/gen-\(paper.id.uuidString.lowercased()).pdf")
        #expect(shared.lastPathComponent == "Quadratic equations.pdf")
    }

    @Test func shareDrawsOnThePhoneWhileTheFileIsNotThereAndTheWaitPasses() async throws {
        let paper = try paper()
        let stalled = server(wait: .milliseconds(200)) { _, _ in
            try await Task.sleep(for: .seconds(60))
            return Data("server".utf8)
        }
        let clock = ContinuousClock()
        var shared: URL?
        let took = await clock.measure { shared = await ResultPDF.file(
            for: paper,
            title: "Quadratic equations",
            server: stalled
        ) }
        #expect(took < .seconds(2))
        #expect(try Data(contentsOf: #require(shared)).starts(with: Data("%PDF".utf8)))
        // A note has no server file: the phone draws it at once.
        let note = try #require(FakeAIHistoryRepository.seed.first { $0.kind == .progressNote })
        let drawn = try #require(await ResultPDF.file(for: note, title: "Hemanth", server: stalled))
        #expect(try Data(contentsOf: drawn).starts(with: Data("%PDF".utf8)))
    }
}
