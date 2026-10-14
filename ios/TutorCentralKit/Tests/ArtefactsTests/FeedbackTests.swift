import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// D107: making something again asks why, and the reason goes to the writer and is kept beside the old generation; Use
/// my own is kept as a replacement (P21-Brief-Again, P21-Mock-Again; the sheet's own menu).
@MainActor struct FeedbackTests {
    static let briefID = UUID(uuidString: "abababab-0000-0000-0001-000000000005")!

    @Test func theBriefsReasonGoesToTheWriterAndIsKeptOnTheOldGeneration() async {
        let ai = FakeAIRepository(), recorder = FakeFeedbackRecorder()
        let store = await BriefStore(
            artefactID: Self.briefID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: FakePlansRepository.evening(), ai: ai,
            now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        store.feedback = recorder
        await store.load()
        let old = store.artefact?.generationID
        await store.makeAgain(.simplerWords)
        #expect(ai.briefReasons.last == "Simpler words")
        #expect(recorder.recorded == [Feedback.again(old ?? UUID(), reason: "Simpler words")])
        #expect(store.artefact?.regeneratedFrom == Self.briefID && store.againReason == nil)
    }

    @Test func aBriefMadeTheFirstTimeOrAgainWithoutAReasonKeepsNoFeedback() async {
        let recorder = FakeFeedbackRecorder()
        let store = await BriefStore(
            artefactID: Self.briefID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: FakePlansRepository.evening(), ai: FakeAIRepository(),
            now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        store.feedback = recorder
        await store.load()
        await store.makeAgain()
        #expect(recorder.recorded.isEmpty)
    }

    @Test func theMocksReasonGoesToTheWriterAndIsKept() async {
        let ai = FakeAIRepository(), recorder = FakeFeedbackRecorder()
        let store = await MockStore(
            artefactID: FakePlansRepository.boardMockID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: FakePlansRepository(artefacts: [FakePlansRepository.boardMock]),
            ai: ai, schoolItems: nil, schools: nil, now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        store.feedback = recorder
        await store.load()
        #expect(await store.again(.closerToSchool))
        #expect(ai.mockCalls.last?.reason == "Closer to the school's papers")
        #expect(recorder.recorded.map(\.kind) == [.again] && recorder.recorded.first?
            .reason == "Closer to the school's papers")
        #expect(recorder.recorded.first?.generation == FakePlansRepository.boardMock.generationID)
    }

    @Test func theSheetsReasonAndTheTutorsOwnSheetAreKept() async throws {
        let recorder = FakeFeedbackRecorder()
        let store = try await SheetStoreTests().store()
        store.feedback = recorder
        await store.makeAgain(.harder)
        #expect(recorder.recorded.map(\.kind) == [.again] && recorder.recorded.first?.reason == "harder")
        await store.useOwn(text: "1. Balance Fe + O2")
        #expect(recorder.recorded.map(\.kind) == [.again, .replace])
        #expect(recorder.recorded.last?.revised == .text("1. Balance Fe + O2"))
    }

    @Test func eachReasonsLineIsTheBoards() {
        #expect(BriefReason.moreOnMistakes
            .line == "A brief with more on the mistakes is on its way. This one stays until it arrives.")
        #expect(MockReason.closerToSchool
            .line == "A mock closer to the school's papers is on its way. This one stays until it arrives.")
    }
}
