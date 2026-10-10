import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Today

/// One batch's plan on Today (P10-Today-Plan and its states).
@MainActor struct PlanStoreTests {
    func store(
        plans: FakePlansRepository = FakePlansRepository(), ai: FakeAIRepository = FakeAIRepository(),
        online: Bool = true, cache: PlanCache? = nil, now: Date = PlanTest.at1635,
        attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
        classes: FakeClassesRepository = FakeClassesRepository(classes: FakeClassesRepository.withEvening),
        load: Bool = true
    ) async -> PlanStore {
        let maker = PlanTest.maker(plans: plans, ai: ai, attendance: attendance, cache: cache, now: now)
        let store = await PlanStore(
            classID: PlanTest.evening.id, workspace: FakeCentreRepository.meeraWorkspace,
            register: PlanTest.register(now: now), plans: plans, classes: classes, maker: maker, cache: cache,
            now: { now }, calendar: DayHeading.india
        )
        store.online = { online }
        if load {
            await store.load()
        }
        return store
    }

    @Test func openingMakesThePlanAndShowsTheGroupsAsTheyLand() async {
        let store = await store()
        guard case .made = store.state else { Issue.record("not made: \(store.state)")
            return
        }
        #expect(store.groups.count == 3)
        #expect(store.groups[0].title == "Group 1 · Chemical reactions")
        #expect(store.groups[0].line == "Class 8 Science · 3 students")
        #expect(store.groups[0].marks.map(\.name) == ["Set", "Sheet", "Checks", "Worked example"])
        #expect(store.groups[0].marks.allSatisfy { $0.state == .made })
        #expect(store.groups[0].lines.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        #expect(store.groups[0].lines[1].teach == "Teach: Types of reactions")
        #expect(store.groups[0].lines[1].rest.map(\.text) == ["Practise set 1", "Check 3", "Homework sheet 1"])
        #expect(store.briefRow?.afterGroup == 1)
        #expect(store.briefRow?.title == "Your brief · Chemical reactions")
        #expect(store.briefRow?.line == "Five minutes · three common mistakes · the worked example to use")
    }

    @Test func aPlanAlreadyMadeOpensAtOnceWithoutMakingAgain() async {
        let plans = FakePlansRepository(), ai = FakeAIRepository()
        _ = await store(plans: plans, ai: ai)
        let calls = ai.sheets.count
        let store = await store(plans: plans, ai: ai)
        guard case .made = store.state else { Issue.record("not made")
            return
        }
        #expect(ai.sheets.count == calls)
    }

    @Test func offlineWithNoPlanShowsNothingAndStartClassStays() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai, online: false)
        #expect(store.state == .offline)
        #expect(store.groups.isEmpty && ai.sheets.isEmpty)
    }

    @Test func aPlanAlreadyMadeOpensOffline() async {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: PlanTest.centre, directory: directory)
        _ = await store(cache: cache)
        let store = await store(plans: FakePlansRepository(), online: false, cache: cache)
        guard case let .made(plan) = store.state else { Issue.record("not made from the copy")
            return
        }
        #expect(plan.artefact(group: 1, kind: .check) != nil)
        #expect(store.groups.count == 3)
    }

    @Test func aClosedBatchIsNotPlanned() async {
        let ai = FakeAIRepository()
        let store = await store(
            ai: ai, now: PlanTest.at1840, attendance: FakeAttendanceRepository(sessions: PlanTest.eveningClosedToday)
        )
        #expect(store.state == .none)
        #expect(ai.sheets.isEmpty)
    }

    @Test func anUnclosedBatchIsPlannedAfterItsHours() async {
        let store = await store(now: PlanTest.at1840)
        guard case .made = store.state else { Issue.record("not made: \(store.state)")
            return
        }
    }

    @Test func noBatchTodayMakesNoPlan() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai, now: PlanTest.saturday0930)
        #expect(store.state == .none)
        #expect(ai.sheets.isEmpty)
    }

    @Test func planningShowsTheLinesBeforeTheMaterial() async throws {
        let ai = FakeAIRepository()
        ai.delay = .seconds(5)
        let store = await store(ai: ai, load: false)
        let load = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(300))
        guard case let .planning(plan?) = store.state else { Issue.record("not planning with lines: \(store.state)")
            load.cancel()
            return
        }
        #expect(!plan.items.isEmpty)
        #expect(store.groups[0].marks.allSatisfy { $0.state == .onItsWay })
        load.cancel()
    }

    @Test func aLineOpensItsArtefact() async throws {
        let store = await store()
        guard case let .made(plan) = store.state else { Issue.record("not made")
            return
        }
        let homework = try #require(plan.items(of: FakeStudentsRepository.dev).first { $0.kind == .homework })
        #expect(try store.open(line: homework) == .artefact(#require(homework.artefactID)))
        let teach = try #require(plan.items(of: FakeStudentsRepository.dev).first { $0.kind == .teach })
        #expect(store.open(line: teach) == nil)
    }

    @Test func aCatchUpLeadsTheLineAndThePlacementIsTheCheckBit() async throws {
        let store = await store(
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithNikhilAbsentTwice)
        )
        let lines = store.groups.flatMap(\.lines)
        let nikhil = try #require(lines.first { $0.id == FakeStudentsRepository.nikhil })
        #expect(nikhil.teach == "Catch up: missed Mon and Fri · then Balancing equations")
        let riya = try #require(lines.first { $0.id == FakeStudentsRepository.riya })
        #expect(riya.rest.map(\.text).contains("Placement, her first checks"))
        #expect(riya.status == "Not known yet")
    }
}
