import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Today

/// Changing the plan where it appears (P10-Today-Plan-StudentMenu, -Changed, -Change).
@MainActor struct PlanChangeTests {
    func plan(_ plans: FakePlansRepository) async throws -> PlanRecord {
        try #require(try await plans.plan(
            centre: PlanTest.centre,
            classID: PlanTest.evening.id,
            date: PlanTest.wednesday
        ))
    }

    func line(_ store: PlanStore, _ student: UUID) -> PlanLineModel? {
        store.groups.flatMap(\.lines).first { $0.id == student }
    }

    @Test func moveMarksTheStudentsLinesAndTheCardSaysSo() async throws {
        let plans = FakePlansRepository()
        let store = await PlanStoreTests().store(plans: plans)
        let riyasGroup = try #require(line(store, FakeStudentsRepository.riya)?.groupNo)
        await store.move(student: FakeStudentsRepository.riya, to: 1)
        let made = try await plan(plans)
        #expect(made.items(of: FakeStudentsRepository.riya)
            .allSatisfy { $0.groupNo == 1 && $0.movedFrom == riyasGroup })
        #expect(store.groups[0].lines.first { $0.id == FakeStudentsRepository.riya }?.note == .movedFrom(riyasGroup))
        #expect(store.groups[0].line == "Class 5 and 8 Science · 4 students")
        let homework = made.items(of: FakeStudentsRepository.riya).first { $0.kind == .homework }
        #expect(homework?.artefactID == made.artefact(group: 1, kind: .sheet, homework: true)?.id)
        #expect(store.changedNote)
    }

    @Test func skipHomeworkStrikesTheBitAndSaysSkippedToday() async throws {
        let store = await PlanStoreTests().store()
        await store.skipHomework(student: FakeStudentsRepository.nikhil)
        let nikhil = try #require(line(store, FakeStudentsRepository.nikhil))
        #expect(nikhil.note == .skipped("Homework skipped today"))
        #expect(nikhil.rest.first { $0.text == "Homework sheet 1" }?.struck == true)
    }

    @Test func leaveOutRemovesTheStudentsLineFromTheCard() async {
        let store = await PlanStoreTests().store()
        await store.leaveOut(student: FakeStudentsRepository.meher)
        #expect(line(store, FakeStudentsRepository.meher) == nil)
    }

    @Test func aChangeOfflineIsRefusedInWordsAndChangesNothing() async {
        let plans = FakePlansRepository()
        let store = await PlanStoreTests().store(plans: plans)
        store.online = { false }
        await store.skipCheck(student: FakeStudentsRepository.dev)
        #expect(store.message == OfflineRefusal.words(for: .changePlan))
        #expect(line(store, FakeStudentsRepository.dev)?.note == nil)
        #expect(plans.skipped.isEmpty)
    }

    @Test func aChangeThatFailsSaysSoAndKeepsTheLine() async {
        let plans = FakePlansRepository()
        let store = await PlanStoreTests().store(plans: plans)
        plans.nextError = URLError(.badServerResponse)
        await store.skipHomework(student: FakeStudentsRepository.dev)
        #expect(store.message == "Couldn't change the plan. Nothing was changed.")
        #expect(line(store, FakeStudentsRepository.dev)?.note == nil)
    }

    @Test func useTodayMakesThePlanAgainWithTheChoices() async {
        let store = await PlanStoreTests().store()
        await store.useToday(choices: PlanChoices(groups: 2, subjects: [1: "Mathematics"]))
        #expect(store.groups.count == 2)
        #expect(store.groups[0].line.contains("Mathematics"))
    }

    @Test func theSheetStartsFromThePlanAsItIs() async {
        let store = await PlanStoreTests().store()
        let choices = store.changeChoices
        #expect(choices.groups == 3)
        #expect(choices.subjects[1] == "Science")
        #expect(store.subjectsOffered(group: 1).contains("Science"))
        let rows = await store.preview(PlanChoices(groups: 2, subjects: [:]))
        #expect(rows.map(\.title) == ["Group 1 · Class 8", "Group 2 · Class 2 and 5"])
    }

    @Test func keepWritesTheWeekdaysPatternOnTheBatch() async throws {
        let classes = FakeClassesRepository(classes: FakeClassesRepository.withEvening)
        let store = await PlanStoreTests().store(classes: classes)
        await store.keep(choices: PlanChoices(groups: 2, subjects: [1: "Science", 2: "Mathematics"]), for: .wednesday)
        let evening = try #require(classes.classes.first { $0.id == PlanTest.evening.id })
        #expect(evening.planPattern[.wednesday] == PlanPattern(groups: 2, subjects: ["Science", "Mathematics"]))
    }

    @Test func aMoveBeforeTheSheetLandsFollowsTheNewGroup() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(150)
        let plans = FakePlansRepository()
        let store = await PlanStoreTests().store(plans: plans, ai: ai, load: false)
        let load = Task { await store.load() }
        while store.record == nil {
            try await Task.sleep(for: .milliseconds(20))
        }
        await store.move(student: FakeStudentsRepository.riya, to: 1)
        await load.value
        let made = try await plan(plans)
        let homework = made.items(of: FakeStudentsRepository.riya).first { $0.kind == .homework }
        #expect(homework?.artefactID == made.artefact(group: 1, kind: .sheet, homework: true)?.id)
        #expect(store.record?.items(of: FakeStudentsRepository.riya).allSatisfy { $0.groupNo == 1 } == true)
    }

    @Test func makingAgainDropsLateAnswers() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(150)
        let plans = FakePlansRepository()
        let store = await PlanStoreTests().store(plans: plans, ai: ai, load: false)
        let load = Task { await store.load() }
        while store.record == nil {
            try await Task.sleep(for: .milliseconds(20))
        }
        await store.useToday(choices: PlanChoices(groups: 1, subjects: [:]))
        await load.value
        let made = try await plan(plans)
        #expect(made.groups.count == 1)
        #expect(store.groups.count == 1)
        #expect(made.items.allSatisfy { $0.artefactID == nil || made.artefact($0.artefactID) != nil })
    }
}
