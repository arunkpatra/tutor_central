import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// A not-on-track student's caption on Today's plan (P10-Today-NotOnTrack) until the parent is told.
@MainActor struct PlanCaptionTests {
    func store(entries: [MessageEntry] = [], step: NextStep? = nil) async -> PlanStore {
        var seed = FakeStudentsRepository.eveningSeed
        if let index = seed.firstIndex(where: { $0.id == FakeStudentsRepository.dev }) {
            seed[index].trackStatus = .notOnTrack
            seed[index].trackSince = PlanTest.at(7, 18, 32)
            seed[index].nextStep = step
        }
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { PlanTest.at1635 }
        )
        await register.load()
        let plans = FakePlansRepository(
            plans: [FakePlansRepository.boardPlan(changed: false, done: false)],
            artefacts: FakePlansRepository.boardArtefacts
        )
        let store = PlanStore(
            classID: PlanTest.evening.id, workspace: FakeCentreRepository.meeraWorkspace, register: register,
            plans: plans, classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening),
            maker: PlanTest.maker(plans: plans), cache: nil, now: { PlanTest.at1635 }, calendar: DayHeading.india
        )
        store.online = { true }
        store.messages = FakeMessageLogRepository(entries: [FakeStudentsRepository.dev: entries])
        await store.load()
        return store
    }

    func devCaption(_ store: PlanStore) -> String? {
        store.groups.flatMap(\.lines).first { $0.id == FakeStudentsRepository.dev }?.caption
    }

    @Test func aNotOnTrackLineCarriesTheCaptionUntilTheParentIsTold() async {
        #expect(await devCaption(store()) == "Since Wed 7 Oct · tell Ramesh after the class")
        let told = MessageEntry(id: UUID(), kind: .notOnTrack, openedAt: PlanTest.at(7, 18, 40), language: .hindi)
        #expect(await devCaption(store(entries: [told])) == nil)
    }

    @Test func aMessageBeforeTheStatusCameDoesNotCount() async {
        let before = MessageEntry(id: UUID(), kind: .notOnTrack, openedAt: PlanTest.at(5, 18, 0), language: .hindi)
        #expect(await devCaption(store(entries: [before])) == "Since Wed 7 Oct · tell Ramesh after the class")
    }

    @Test func anotherStepHasNoCaption() async {
        #expect(await devCaption(store(step: .stepBack)) == nil)
    }
}
