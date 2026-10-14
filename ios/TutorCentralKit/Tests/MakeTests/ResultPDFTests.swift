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

    /// Hand run 9: a result shown before its PDF job has run takes the server's file once the job has made it, while
    /// the
    /// screen is up.
    @Test func aFreshResultTakesTheServersFileOnceItIsMade() async throws {
        let paper = try paper()
        let made = Made()
        let later = server(wait: .milliseconds(100)) { _, path in
            guard await made.yes else { throw URLError(.fileDoesNotExist) }
            return Data(path.utf8)
        }
        #expect(await ResultPDF.serverLater(
            for: paper,
            title: "Quadratic equations",
            server: later,
            tries: 1,
            every: .milliseconds(10)
        ) == nil)
        await made.make()
        let shared = try #require(await ResultPDF.serverLater(
            for: paper, title: "Quadratic equations", server: later, tries: 3, every: .milliseconds(10)
        ))
        #expect(try String(contentsOf: shared, encoding: .utf8)
            .hasSuffix("gen-\(paper.id.uuidString.lowercased()).pdf"))
        // A note has no server file: nothing is asked again.
        let note = try #require(FakeAIHistoryRepository.seed.first { $0.kind == .progressNote })
        #expect(await ResultPDF.serverLater(
            for: note,
            title: "Hemanth",
            server: later,
            tries: 3,
            every: .milliseconds(10)
        ) == nil)
    }

    /// The review of Phase 21 (R-app-4): after Create again, Share never hands out the last result's file; while the
    /// new
    /// one's PDF is had, Share waits, and only a PDF that could not be had for this result says so.
    @Test func shareOffersOnlyThisResultsFile() {
        let old = UUID(), new = UUID(), file = URL(filePath: "/tmp/old.pdf")
        #expect(ResultPDF.share(file: (old, file), tried: old, for: old) == .ready(file))
        #expect(ResultPDF.share(file: (old, file), tried: old, for: new) == .preparing)
        #expect(ResultPDF.share(file: nil, tried: new, for: new) == .failed)
        #expect(ResultPDF.share(file: nil, tried: nil, for: new) == .preparing)
    }
}

/// Whether the server's PDF has been made yet.
private actor Made {
    var yes = false
    func make() {
        yes = true
    }
}
