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

    @Test func aTickedLineIsNotDoneForAStudentMarkedAbsent() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await tests.store(attendance: attendance, plans: .evening())
        let practise = try #require(store.checklist[0].rows.first { $0.text == "Practise set 1" })
        store.toggle(line: practise.id, in: 1)
        let meher = try #require(store.students.firstIndex { $0.id == FakeStudentsRepository.meher })
        store.toggle(meher)
        #expect(await store.done())
        let close = try #require(attendance.closes.last)
        let plan = try #require(store.plan)
        let meherItems = Set(plan.items(of: FakeStudentsRepository.meher).map(\.id))
        #expect(close.done.count == 2 && meherItems.isDisjoint(with: close.done))
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

    @Test func offlineTheCopyShowsTheChecksBeforeTheReadsGiveUp() async throws {
        let cache = PlanCache(
            centre: Self.centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        let evening = FakePlansRepository.evening()
        try cache.keep(#require(try await evening.plan(id: FakePlansRepository.planID, centre: Self.centre)), at: .now)
        let plans = FakePlansRepository()
        plans.delay = .seconds(1)
        plans.nextError = URLError(.timedOut)
        let store = await CloseStore(
            classID: FakeClassesRepository.evening.id, workspace: FakeCentreRepository.meeraWorkspace,
            register: tests.register(), textbooks: FakeTextbooksRepository.evening(), record: FakeRecordRepository(),
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), ai: FakeAIRepository(),
            now: { CloseStoreTests.fivepast }
        )
        store.plans = plans
        store.planCache = cache
        let loading = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(300))
        #expect(!store.checklist.isEmpty)
        guard case .rows? = student(store, FakeStudentsRepository.meher)?.checks else {
            Issue.record("the copy's checks were not shown at once")
            return
        }
        await loading.value
        #expect(store.loaded && store.canFinish && !store.checklist.isEmpty)
    }

    @Test func offlineAPlanCheckIsRecordedOnTheStudentsSkillFromTheBooksCopy() async throws {
        let cache = PlanCache(
            centre: Self.centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        let evening = FakePlansRepository.evening()
        try cache.keep(#require(try await evening.plan(id: FakePlansRepository.planID, centre: Self.centre)), at: .now)
        let online = FakeTextbooksRepository.evening()
        let meherID = FakeStudentsRepository.meher
        cache.keepBook(
            BookCopy(chapters: online.chaptersByStudent[meherID] ?? [], skills: online.skillsByStudent[meherID] ?? []),
            student: meherID, at: .now
        )
        let offline = FakeTextbooksRepository.evening()
        offline.failure = URLError(.notConnectedToInternet)
        let plans = FakePlansRepository()
        plans.nextError = URLError(.notConnectedToInternet)
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await tests.store(attendance: attendance, textbooks: offline, plans: plans, cache: cache)
        let meher = try #require(store.students.firstIndex { $0.id == meherID })
        store.tap(meher, 0, right: true)
        #expect(await store.done())
        let check = try #require(attendance.closes.last?.checks.first { $0.studentID == meherID })
        #expect(online.skillsByStudent[meherID]?.contains { $0.id == check.skillID } == true)
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

/// The approved board's sentences (components.md "Phase 12 parts"), copied here so the build is held to them.
enum P12Words {
    static let closeMaking = "Making the three questions. A second or two."
    static let closeOffline = "You're offline. The checks need a connection; mark attendance and homework, and Done "
        + "still closes."

    static func closeNoBook(_ firstName: String) -> String {
        "No book yet, so no checks. Add one from \(firstName)'s page."
    }
}

/// The close card's three states (P12-Close-Cards; U37, U38).
struct CloseCardWordsTests {
    @Test func theCardStatesWordsAreTheBoards() {
        #expect(CloseStore.offlineWords == P12Words.closeOffline)
        #expect(CloseStore.noBookWords(firstName: "Bir") == P12Words.closeNoBook("Bir"))
        #expect(CloseStore.makingWords == P12Words.closeMaking)
    }
}
