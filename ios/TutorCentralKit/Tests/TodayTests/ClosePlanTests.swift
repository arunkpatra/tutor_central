import Data
import Domain
import Foundation
import Testing
@testable import Today

/// The close from the plan (P10-Close; plan Tasks 20 and 22): its checks with no call, its checklist, the lines done,
/// the sheet given, offline from the copy.
@MainActor struct ClosePlanTests {
    let tests = CloseStoreTests()
    static let centre = FakeCentreRepository.meeraWorkspace.centre.id

    func student(_ store: CloseStore, _ id: UUID) -> CloseStudent? {
        store.students.first { $0.id == id }
    }

    @Test func aCloseFromThePlanTakesItsChecksAndMakesNoCall() async {
        let ai = FakeAIRepository()
        let store = await tests.store(ai: ai, plans: .evening())
        #expect(ai.checkCalls.isEmpty && ai.placementCalls.isEmpty)
        guard case let .rows(rows)? = student(store, FakeStudentsRepository.dev)?.checks else {
            Issue.record("no rows")
            return
        }
        #expect(rows.map(\.skill) == ["Balancing equations", "Types of reactions", "Chemical change"])
        guard case let .placement(subjects)? = student(store, FakeStudentsRepository.riya)?.checks else {
            Issue.record("no placement")
            return
        }
        #expect(subjects.map(\.title) == ["Mathematics"] && subjects[0].rows.count == 5)
        #expect(store.hasPlan)
    }

    @Test func theChecklistHasACardPerGroupWithItsLines() async {
        let store = await tests.store(plans: .evening())
        #expect(store.checklist.map(\.title)
            == ["Group 1 · Chemical reactions", "Group 2 · Parts and wholes", "Group 3 · Reading"])
        #expect(store.checklist[0].rows.map(\.text) == [
            "Catch up: missed Mon and Fri · then Balancing equations (Nikhil)",
            "Teach again: Balancing equations, with the worked example (Dev)",
            "Teach: Types of reactions (Meher)", "Teach: Balancing equations (Nikhil)", "Practise set 1",
            "Check 3", "Homework sheet 1",
        ])
        #expect(store.countText(for: 1) == "0 of 7")
        store.toggle(line: store.checklist[0].rows[1].id, in: 1)
        #expect(store.countText(for: 1) == "1 of 7")
        store.toggle(line: store.checklist[0].rows[1].id, in: 1)
        #expect(store.countText(for: 1) == "0 of 7")
    }

    @Test func doneWritesTheTickedLinesAndTheSheetGiven() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let plans = FakePlansRepository.evening()
        let store = await tests.store(attendance: attendance, plans: plans)
        let practise = try #require(store.checklist[0].rows.first { $0.text == "Practise set 1" })
        store.toggle(line: practise.id, in: 1)
        #expect(await store.done())
        let close = try #require(attendance.closes.last)
        #expect(Set(close.done) == Set(practise.itemIDs) && close.done.count == 3)
        let plan = try #require(try await plans.plan(id: FakePlansRepository.planID, centre: Self.centre))
        let sheet = plan.artefact(group: 1, kind: .sheet, homework: true)?.id
        #expect(close.homework.first { $0.studentID == FakeStudentsRepository.dev }?.artefactID == sheet)
        let dev = try #require(student(store, FakeStudentsRepository.dev))
        #expect(store.homeworkLabel(dev) == "Homework given · sheet 1")
    }

    @Test func aTapOnAPlanCheckMovesTheStudentsOwnSkill() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await tests.store(attendance: attendance, plans: .evening())
        let meher = try #require(store.students.firstIndex { $0.id == FakeStudentsRepository.meher })
        store.tap(meher, 0, right: true)
        #expect(await store.done())
        let check = try #require(attendance.closes.last?.checks.first { $0.studentID == FakeStudentsRepository.meher })
        let own = FakeTextbooksRepository.evening().skillsByStudent[FakeStudentsRepository.meher] ?? []
        #expect(own.contains { $0.id == check.skillID && $0.name == "Balancing equations" })
    }

    @Test func aStudentLeftOutClosesWithAttendanceAlone() async throws {
        let plans = FakePlansRepository.evening()
        try await plans.leaveOut(
            student: FakeStudentsRepository.meher,
            plan: FakePlansRepository.planID,
            centre: Self.centre
        )
        let store = await tests.store(plans: plans)
        let meher = try #require(student(store, FakeStudentsRepository.meher))
        #expect(meher.checks == .skipped)
        #expect(!meher.homeworkGiven)
    }

    @Test func aCheckSkippedTodayKeepsTheHomework() async throws {
        let plans = FakePlansRepository.evening()
        let plan = try #require(try await plans.plan(id: FakePlansRepository.planID, centre: Self.centre))
        let item = try #require(plan.items.first { $0.studentID == FakeStudentsRepository.dev && $0.kind == .check })
        try await plans.skip(item: item.id, centre: Self.centre)
        let store = await tests.store(plans: plans)
        let dev = try #require(student(store, FakeStudentsRepository.dev))
        #expect(dev.checks == .skipped && dev.homeworkGiven)
    }

    @Test func aCloseFromACachedPlanMakesNoCall() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: Self.centre, directory: directory)
        let evening = FakePlansRepository.evening()
        try cache.keep(#require(try await evening.plan(id: FakePlansRepository.planID, centre: Self.centre)), at: .now)
        let plans = FakePlansRepository()
        plans.nextError = URLError(.notConnectedToInternet)
        let ai = FakeAIRepository()
        let store = await tests.store(ai: ai, plans: plans, cache: cache)
        guard case .rows? = student(store, FakeStudentsRepository.dev)?.checks else {
            Issue.record("no rows from the copy")
            return
        }
        #expect(ai.checkCalls.isEmpty)
        #expect(store.loaded && store.canFinish)
    }

    @Test func aStudentTheRulesAddedAfterThePlanGoesPhaseElevensWay() async {
        let ai = FakeAIRepository()
        var plan = FakePlansRepository.boardPlan(changed: false, done: false)
        plan.items.removeAll { $0.studentID == FakeStudentsRepository.sahil }
        let plans = FakePlansRepository(plans: [plan], artefacts: FakePlansRepository.boardArtefacts)
        let store = await tests.store(ai: ai, plans: plans)
        guard case .rows? = student(store, FakeStudentsRepository.sahil)?.checks else {
            Issue.record("Sahil's ladder checks")
            return
        }
        #expect(!ai.checkCalls.isEmpty)
    }

    @Test func withoutAPlanTheCloseIsPhaseElevens() async {
        let ai = FakeAIRepository()
        let store = await tests.store(ai: ai, plans: FakePlansRepository())
        #expect(store.checklist.isEmpty)
        #expect(!store.hasPlan)
        #expect(!ai.checkCalls.isEmpty)
        #expect(store.homeworkLabel(store.students[0]) == "Homework given")
    }

    @Test func aQueuedCloseCarriesItsDoneLines() async throws {
        let queue = ChangeQueue(
            centre: Self.centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        let store = await tests.store(plans: .evening())
        store.queue = queue
        store.online = { false }
        store.toggle(line: store.checklist[0].rows[4].id, in: 1)
        _ = await store.done()
        guard case let .close(close, _, _, _) = try #require(queue.pending.changes.last).kind else {
            Issue.record("not queued")
            return
        }
        #expect(close.done.count == 3)
    }
}
