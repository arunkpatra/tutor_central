import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Artefacts

/// A sheet's screen (P10-Sheet, -Key, -Board).
@MainActor struct SheetStoreTests {
    func store(
        plans: FakePlansRepository = .evening(), ai: FakeAIRepository = FakeAIRepository(),
        photos: FakePhotoStore = FakePhotoStore(), artefact: UUID? = nil
    ) async throws -> SheetStore {
        let plan = try #require(try await ArtefactTest.plan(plans))
        let id = try artefact ?? #require(plan.artefact(group: 1, kind: .sheet, homework: true)?.id)
        let store = await SheetStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: plans, ai: ai, photos: photos, now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        await store.load()
        return store
    }

    @Test func theHeroNamesTheGroupTheClassAndWhoItIsFor() async throws {
        let store = try await store()
        #expect(store.eyebrow == "Group 1 · Class 8 Science · Chemical reactions")
        #expect(store.title == "Balancing equations · sheet 1")
        #expect(store.line == "8 questions · for Dev, Meher and Nikhil · made today, 16:40")
    }

    @Test func theKeyIsLeftOutOfThePdfUnlessTheKeyFormShows() async throws {
        let store = try await store()
        let hasKey = { store.pdfSheet.blocks.contains {
            if case .key = $0 {
                true
            } else {
                false
            }
        } }
        #expect(!hasKey())
        store.form = .key
        #expect(hasKey())
    }

    @Test func theBoardWalksTheQuestions() async throws {
        let store = try await store()
        store.form = .board
        store.boardIndex = 2
        #expect(store.boardQuestion?.number == 3)
        #expect(store.boardCount == "3 of 8")
        store.boardShowsKey = true
        #expect(store.boardAnswer == store.sheet?.questions[2].answer)
        store.nextQuestion()
        #expect(store.boardIndex == 3)
    }

    @Test func anArtefactThatIsGoneSaysSoInItsPlace() async throws {
        let store = try await store(artefact: UUID())
        #expect(store.loadFailed == "This sheet isn't here any more.")
    }

    @Test func aStudentsOwnSheetNamesTheStudent() async throws {
        let plans = FakePlansRepository.evening()
        let content = SheetContent(title: "Fractions", instructions: nil, questions: [], forHomework: true, light: true)
        let riyas = try await plans.keep(
            NewArtefact(
                kind: .sheet, source: .made, title: "Fractions · sheet 1", content: .sheet(content), photoPath: nil,
                generationID: nil, regeneratedFrom: nil
            ),
            to: ArtefactLink(
                plan: FakePlansRepository.planID, group: 2, student: FakeStudentsRepository.riya, itemKind: .homework
            ),
            centre: ArtefactTest.centre
        )
        let store = try await store(plans: plans, artefact: riyas.id)
        #expect(store.line.contains("for Riya"))
    }
}
