import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// Make it again with a reason (P10-Sheet-Regenerate, -Regenerating; plan decision 12).
@MainActor struct SheetAgainTests {
    @Test func makeAgainReplacesTheSheetInThePlanAndKeepsTheOld() async throws {
        let plans = FakePlansRepository.evening(), ai = FakeAIRepository()
        let store = try await SheetStoreTests().store(plans: plans, ai: ai)
        let old = try #require(store.artefact?.id)
        await store.makeAgain(.easier)
        #expect(ai.reasons.last == "easier")
        #expect(store.artefact?.id != old)
        #expect(store.artefact?.regeneratedFrom == old)
        let plan = try #require(try await ArtefactTest.plan(plans))
        #expect(plan.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy {
            $0.artefactID == store.artefact?.id
        })
        #expect(try await plans.artefact(id: old, centre: ArtefactTest.centre) != nil)
        #expect(store.again == .idle)
    }

    @Test func whileMakingTheOldStaysAndTheLineSaysWhat() async throws {
        let ai = FakeAIRepository()
        ai.delay = .seconds(2)
        let store = try await SheetStoreTests().store(ai: ai)
        let task = Task { await store.makeAgain(.shorter) }
        try await Task.sleep(for: .milliseconds(200))
        #expect(store.again == .making(.shorter))
        #expect(store.regeneratingLine == "A shorter sheet is on its way. This one stays until it arrives.")
        #expect(store.sheet != nil)
        task.cancel()
    }

    @Test func aFailedRegenerateKeepsTheOld() async throws {
        let ai = FakeAIRepository()
        ai.scriptByKind[.sheet] = .failure(.service)
        let store = try await SheetStoreTests().store(ai: ai)
        let old = store.artefact?.id
        await store.makeAgain(.harder)
        #expect(store.artefact?.id == old)
        #expect(store.message == "Couldn't make it again. The sheet you have is still here.")
        #expect(store.again == .idle)
    }

    @Test func regenerateOfflineIsRefusedInWords() async throws {
        let ai = FakeAIRepository()
        let store = try await SheetStoreTests().store(ai: ai)
        store.online = { false }
        await store.makeAgain(.moreSums)
        #expect(store.message == OfflineRefusal.words(for: .regenerate))
        #expect(ai.sheets.isEmpty)
    }

    @Test func theTutorsOwnWordsGoInTheReason() async throws {
        let ai = FakeAIRepository()
        let store = try await SheetStoreTests().store(ai: ai)
        await store.makeAgain(.own("Only equations with oxygen"))
        #expect(ai.reasons.last == "Only equations with oxygen")
    }
}
