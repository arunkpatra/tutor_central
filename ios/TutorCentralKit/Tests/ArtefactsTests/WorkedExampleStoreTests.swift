import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// The worked example's screen (P10-WorkedExample): one step at a time, Show all, the slip.
@MainActor struct WorkedExampleStoreTests {
    func store(plans: FakePlansRepository = .evening()) async throws -> WorkedExampleStore {
        let plan = try #require(try await ArtefactTest.plan(plans))
        let id = try #require(plan.artefact(group: 1, kind: .workedExample)?.id)
        let store = await WorkedExampleStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: plans
        )
        await store.load()
        return store
    }

    @Test func stepsShowOneAtATimeThenAll() async throws {
        let store = try await store()
        #expect(store.countText == "1 of 4")
        store.showNext()
        store.showNext()
        #expect(store.countText == "3 of 4")
        #expect(store.canShowNext)
        store.showAll()
        #expect(store.countText == "4 of 4")
        #expect(!store.canShowNext)
        store.showNext()
        #expect(store.countText == "4 of 4")
    }

    @Test func theHeroTheSlipAndTheIntroAreTheBoards() async throws {
        let store = try await store()
        #expect(store.eyebrow == "Balancing equations · Class 8 Science")
        #expect(store.title == "Balance: Fe + O₂ → Fe₂O₃")
        #expect(store.intro == "One step at a time. Say each step aloud before you show the next.")
        #expect(store.slip.hasPrefix("A common slip here:"))
    }

    @Test func anExampleNoLongerHereSaysSo() async {
        let store = await WorkedExampleStore(
            artefactID: UUID(), workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: FakePlansRepository.evening()
        )
        await store.load()
        #expect(store.example == nil)
        #expect(store.loadFailed == "This worked example isn't here any more.")
    }

    @Test func aBriefsExampleShowsWithoutAPlan() {
        let store = WorkedExampleStore(example: AISamples.workedExample)
        #expect(store.title == "Balance: Fe + O₂ → Fe₂O₃")
        #expect(store.countText == "1 of 4")
    }
}
