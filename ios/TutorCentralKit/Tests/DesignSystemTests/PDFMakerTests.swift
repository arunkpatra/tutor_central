import Foundation
import PDFKit
import Testing
@testable import DesignSystem

/// The PDF of a sheet (spec section 7): A4, the app's type, light; the key last, and only when asked.
@MainActor struct PDFMakerTests {
    func text(_ url: URL) throws -> String {
        try #require(PDFDocument(url: url)?.string)
    }

    @Test func aSheetWithAKeyPrintsTheKeyLast() throws {
        let sheet = PDFSheet(
            title: "Balancing equations · sheet 1", instructions: "Show your working.",
            blocks: [
                .section(title: nil, lines: [PDFLine(number: 1, text: "Balance H₂ + O₂ → H₂O", marks: nil)]),
                .key([PDFLine(number: 1, text: "2H₂ + O₂ → 2H₂O", marks: nil)]),
            ]
        )
        let printed = try text(PDFMaker.pdf(for: sheet))
        let balance = try #require(printed.range(of: "Balance"))
        let key = try #require(printed.range(of: "Answer key"))
        #expect(balance.lowerBound < key.lowerBound)
    }

    @Test func aSheetWithoutAKeyHasNone() throws {
        let lines = [PDFLine(number: 1, text: "q", marks: nil)]
        let sheet = PDFSheet(title: "T", instructions: nil, blocks: [.section(title: nil, lines: lines)])
        #expect(try !text(PDFMaker.pdf(for: sheet)).contains("Answer key"))
    }

    @Test func theFileNameDropsSlashesAndColons() {
        #expect(PDFMaker.fileName("Group 1: Science/Chemistry") == "Group 1- Science-Chemistry")
    }
}

struct ArtefactPartsTests {
    @Test func theBoardCountReads() {
        #expect(BoardView.countText(number: 3, of: 8) == "3 of 8")
    }

    @Test func aStepToComeShowsItsTitleOnly() {
        #expect(StepRow.showsWorking(shown: false, working: "w") == false)
        #expect(StepRow.showsWorking(shown: true, working: "w") == true)
        #expect(StepRow.showsWorking(shown: true, working: nil) == false)
    }
}
