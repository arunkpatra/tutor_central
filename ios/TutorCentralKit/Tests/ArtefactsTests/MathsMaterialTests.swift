import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Artefacts

/// Phase 20's material (P20-Sheet-To5, -From6, -WorkedExample, -Mock): the formulae kept in the text as LaTeX, the
/// heroes as Phase 10 words them.
@MainActor struct MathsMaterialTests {
    func sheet(_ id: UUID) async -> SheetStore {
        let store = await SheetStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: FakePlansRepository.eveningMaths(), ai: FakeAIRepository(), photos: FakePhotoStore(),
            now: { ArtefactTest.at1640 },
            calendar: DayHeading.india
        )
        await store.load()
        return store
    }

    @Test func theOlderSheetKeepsItsEquations() async {
        let store = await sheet(FakePlansRepository.mathsSheetFrom6)
        #expect(store.eyebrow == "Group 1 · Class 8 Maths · Linear equations")
        #expect(store.title == "Equations in one variable · sheet 1")
        #expect(store.line == "6 questions · for Dev, Meher and Nikhil · made today, 16:40")
        #expect(store.sheet?.questions[1].text == "Solve $\\frac{x}{4} - 2 = 1$.")
        #expect(store.sheet?.instructions == "Solve for x")
    }

    @Test func theYoungerSheetKeepsItsFractions() async {
        let store = await sheet(FakePlansRepository.mathsSheetTo5)
        #expect(store.eyebrow == "Group 2 · Class 5 Maths · Fractions")
        #expect(store.sheet?.questions[2].text == "$\\frac{1}{4} + \\frac{1}{4} =$ ?")
    }

    @Test func theWorkedExampleShowsItsProblemAsTheTitle() async {
        let store = await WorkedExampleStore(
            artefactID: FakePlansRepository.mathsExample, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: FakePlansRepository.eveningMaths()
        )
        await store.load()
        #expect(store.title == "Solve $\\frac{x}{4} - 2 = 1$")
        #expect(store.eyebrow == "Equations in one variable · Class 8 Maths")
        #expect(store.example?.steps.count == 4)
    }

    @Test func thePhonesPdfOfASheetWithMathsIsDrawn() async throws {
        let store = await sheet(FakePlansRepository.mathsSheetFrom6)
        let url = try PDFMaker.pdf(for: store.pdfSheet)
        #expect(try Data(contentsOf: url).starts(with: Data("%PDF".utf8)))
    }
}
