import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// A figure's screen (P10-Figure-*): the skill and class, the template's name, the captions, the AI line, Print.
@MainActor struct FigureStoreTests {
    func store(_ kind: FigureSpec.Kind, content: FigureContent? = nil) async -> FigureStore {
        let plans = FakePlansRepository.figure(kind, content: content)
        let store = await FigureStore(
            artefactID: FakePlansRepository.figureID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: plans
        )
        await store.load()
        return store
    }

    @Test func theFigureScreenReadsTheSkillTheCaptionsAndTheAiLine() async {
        let store = await store(.fractionBar)
        #expect(store.eyebrow == "Fractions as parts of a whole · Class 5 Mathematics")
        #expect(store.title == "Fraction bar")
        #expect(store.line == "Drawn by the app from the skill. Tap to show it large.")
        #expect(store.caption == "The parts sum to the whole: a bar the app refuses to draw otherwise.")
        #expect(store.checked == "4 equal parts, 3 shaded: 3/4.")
        #expect(store.aiLine
            == "Figures are drawn by the app, never pictures made up by the AI, so every label is right.")
    }

    @Test func aSpecThatFailsIsNotDrawnAndSaysSo() async {
        let store = await store(.foodChain, content: FigureContent(figure: .foodChain(links: ["Grass"]), caption: ""))
        #expect(store.figure == nil)
        #expect(store.loadFailed == "This figure can't be drawn.")
    }

    @Test func aFigureNoLongerHereSaysSo() async {
        let store = await FigureStore(
            artefactID: UUID(), workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: FakePlansRepository.figure(.triangle)
        )
        await store.load()
        #expect(store.loadFailed == "This figure isn't here any more.")
    }

    @Test func eachBoardsSkillAndClassReadFromItsPlan() async {
        #expect(await store(.numberLine).eyebrow == "Adding on a number line · Class 1 Mathematics")
        #expect(await store(.labelledCell).eyebrow == "The plant cell · Class 8 Science")
        #expect(await store(.foodChain).eyebrow == "Food chains · Class 6 Science")
    }
}
