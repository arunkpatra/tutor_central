import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// The tutor's brief (P10-Brief): its four parts, Copy as text, Share as PDF, Make it again.
@MainActor struct BriefStoreTests {
    static let briefID = UUID(uuidString: "abababab-0000-0000-0001-000000000005")!

    func store(plans: FakePlansRepository = .evening(), ai: FakeAIRepository = FakeAIRepository()) async
        -> BriefStore {
        let store = await BriefStore(
            artefactID: Self.briefID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: plans, ai: ai, now: { ArtefactTest.at1640 },
            calendar: DayHeading.india
        )
        await store.load()
        return store
    }

    @Test func theBriefReadsItsFourPartsAndCopiesAsText() async {
        let store = await store()
        #expect(store.eyebrow == "Class 8 Science · Chemical reactions")
        #expect(store.title == "Your brief")
        #expect(store.line == "Five minutes to read before the class · made today, 16:40")
        #expect(store.brief?.mistakes.count == 3)
        #expect(store.brief?.words.count == 3)
        #expect(store.exampleLine == "Four steps · the slip to watch for")
        #expect(store.copyText.hasPrefix("Your brief · Class 8 Science · Chemical reactions"))
        #expect(store.copyText.contains("What the chapter is about"))
        #expect(store.copyText.contains("Three common mistakes"))
        #expect(store.copyText.contains("1. Changing the small numbers inside a formula"))
        #expect(store.copyText.contains("The worked example to use"))
        #expect(store.copyText.contains("Words to say"))
    }

    @Test func thePdfHasTheFourPartsAsText() async {
        let store = await store()
        #expect(store.pdfSheet.title == "Your brief · Class 8 Science · Chemical reactions")
        #expect(store.pdfSheet.blocks.count == 4)
    }

    @Test func makeAgainReplacesTheBriefInThePlan() async throws {
        let plans = FakePlansRepository.evening(), ai = FakeAIRepository()
        let store = await store(plans: plans, ai: ai)
        await store.makeAgain()
        #expect(ai.briefs.last == "Chemical reactions")
        #expect(store.artefact?.id != Self.briefID)
        #expect(store.artefact?.regeneratedFrom == Self.briefID)
        let plan = try #require(try await ArtefactTest.plan(plans))
        #expect(plan.items.first { $0.kind == .brief }?.artefactID == store.artefact?.id)
        #expect(!store.making)
    }

    @Test func makeAgainOfflineIsRefusedInWords() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai)
        store.online = { false }
        await store.makeAgain()
        #expect(ai.briefs.isEmpty)
        #expect(store.message == OfflineRefusal.words(for: .regenerate))
        #expect(store.artefact?.id == Self.briefID)
    }

    @Test func aFailedMakeAgainKeepsTheBrief() async {
        let ai = FakeAIRepository()
        ai.scriptByKind[.brief] = .failure(.service)
        let store = await store(ai: ai)
        await store.makeAgain()
        #expect(store.message == "Couldn't make it again. The brief you have is still here.")
        #expect(store.artefact?.id == Self.briefID)
    }
}
