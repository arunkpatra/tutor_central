import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Today

/// One batch's plan on Today (P10-Today-Plan and its states).
/// The job's own states are PlanStoreJobTests'.
@MainActor struct PlanStoreTests {
    /// A store over the fakes; with no `jobs`, a request is answered at once by the server's plan (PlanTest.serving).
    func store(
        plans: FakePlansRepository = FakePlansRepository(), jobs: FakeJobsRepository? = nil, online: Bool = true,
        cache: PlanCache? = nil, now: Date = PlanTest.at1635,
        attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
        classes: FakeClassesRepository = FakeClassesRepository(classes: FakeClassesRepository.withEvening),
        items: FakeSchoolItemsRepository = FakeSchoolItemsRepository(items: []),
        textbooks: FakeTextbooksRepository = .evening(), load: Bool = true,
        pause: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(3600)) }
    ) async -> PlanStore {
        let preview = PlanTest.preview(
            plans: plans, textbooks: textbooks, attendance: attendance, cache: cache, now: now, schoolItems: items
        )
        let store = await PlanStore(
            classID: PlanTest.evening.id, workspace: FakeCentreRepository.meeraWorkspace,
            register: PlanTest.register(now: now), plans: plans, classes: classes,
            jobs: jobs ?? PlanTest.serving(plans, preview: preview, now: now), preview: preview, cache: cache,
            now: { now }, calendar: DayHeading.india, pause: pause
        )
        store.online = { online }
        if load {
            await store.load()
        }
        return store
    }

    func live(at: Date = PlanTest.at(7, 5, 30)) -> FakeJobsRepository {
        FakeJobsRepository(planJobs: [PlanTest.evening.id: JobStatus(id: UUID(), state: .running, createdAt: at)])
    }

    @Test func aLineReadsInThePlansOrderWhateverOrderTheItemsArriveIn() async {
        var plan = FakePlansRepository.boardPlan(changed: false, done: false)
        plan.items.reverse()
        let store = await store(plans: FakePlansRepository(
            plans: [plan],
            artefacts: FakePlansRepository.boardArtefacts
        ))
        let meher = store.groups.first?.lines.first { $0.name == "Meher Shah" }
        #expect(meher?.rest.map(\.text) == ["Practise set 1", "Check 3", "Homework sheet 1"])
    }

    @Test func aSecondOpenWhileTheJobIsLiveAsksNothingTwice() async {
        let jobs = FakeJobsRepository()
        let store = await store(jobs: jobs)
        #expect(store.state == .planning(nil))
        await store.load()
        #expect(jobs.requested == [.plan(classID: PlanTest.evening.id, date: PlanTest.wednesday, choices: nil)])
    }

    @Test func openingAsksTheServerAndShowsThePlanItMade() async {
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
        #expect(store.madeLine == nil)
    }

    @Test func aPlanAlreadyMadeOpensAtOnceWithoutAskingAgain() async {
        let plans = FakePlansRepository(), preview = PlanTest.preview(plans: FakePlansRepository())
        let jobs = PlanTest.serving(plans, preview: preview)
        _ = await store(plans: plans, jobs: jobs)
        let store = await store(plans: plans, jobs: jobs)
        guard case .made = store.state else { Issue.record("not made")
            return
        }
        #expect(jobs.requested.count == 1)
    }

    @Test func offlineWithNoPlanShowsNothingAndStartClassStays() async {
        let jobs = FakeJobsRepository()
        let store = await store(jobs: jobs, online: false)
        #expect(store.state == .offline)
        #expect(store.groups.isEmpty && jobs.requested.isEmpty)
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
        let jobs = FakeJobsRepository()
        let store = await store(
            jobs: jobs, now: PlanTest.at1840,
            attendance: FakeAttendanceRepository(sessions: PlanTest.eveningClosedToday)
        )
        #expect(store.state == .none)
        #expect(jobs.requested.isEmpty)
    }

    @Test func anUnclosedBatchIsPlannedAfterItsHours() async {
        let store = await store(now: PlanTest.at1840)
        guard case .made = store.state else { Issue.record("not made: \(store.state)")
            return
        }
    }

    @Test func noBatchTodayAsksForNoPlan() async {
        let jobs = FakeJobsRepository()
        let store = await store(jobs: jobs, now: PlanTest.saturday0930)
        #expect(store.state == .none)
        #expect(jobs.requested.isEmpty && jobs.reads == 0)
    }

    /// P18-Today-Plan-Making: the plan the server made at 06:00, its material still coming.
    @Test func aPlanWithALiveJobShowsItsMarksOnTheirWayAndTheLine() async {
        let store = await store(plans: FakePlansRepository.eveningMaking(), jobs: live(), now: PlanTest.at(7, 6, 5))
        guard case .planning(_?) = store.state else { Issue.record("not planning with the plan: \(store.state)")
            return
        }
        #expect(store.madeLine == "Made at 06:00, before the batch. The sheets and checks are still being made; each "
            + "mark turns green when it is ready.")
        #expect(store.groups[0].marks.map(\.state) == [.made, .made, .onItsWay, .onItsWay])
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

    // MARK: - Phase 13: holidays and items that change the day

    /// A holiday for class 8 at Vidya Niketan (Dev, Meher, Nikhil) on `day`.
    func classEightHoliday(on day: Day) -> SchoolItem {
        var item = FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.dasara }!
        item.audience = .schoolClass(school: FakeSchoolsRepository.vidya.id, level: .eight)
        item.date = day
        item.endDate = nil
        return item
    }

    var classEight: Set<UUID> {
        [FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil]
    }

    @Test func aHolidayOnAClosedDayChangesNothing() async throws {
        let plans = FakePlansRepository()
        let items = FakeSchoolItemsRepository(items: [classEightHoliday(on: FakeSchoolItemsRepository.day(30))])
        let store = await store(plans: plans, items: items)
        let plan = try #require(store.record)
        plans.markDone(Set(plan.items.prefix(1).map(\.id)), session: UUID())
        let made = plans.made.count
        _ = try await items.update(classEightHoliday(on: PlanTest.wednesday), centre: UUID())
        await store.remake(for: classEight)
        #expect(plans.made.count == made)
    }

    @Test func aHolidayTodayRemakesAnOpenPlanWithoutThem() async throws {
        let plans = FakePlansRepository()
        let items = FakeSchoolItemsRepository(items: [classEightHoliday(on: FakeSchoolItemsRepository.day(30))])
        let store = await store(plans: plans, items: items)
        #expect(plans.made.count == 1)
        _ = try await items.update(classEightHoliday(on: PlanTest.wednesday), centre: UUID())
        await store.remake(for: classEight)
        #expect(plans.made.count == 2 && Set(plans.made.last?.leftOut ?? []) == classEight)
        let notHere: Set<UUID> = [FakeStudentsRepository.hemanth]
        await store.remake(for: notHere) // nobody of this batch
        #expect(plans.made.count == 2)
    }

    @Test func aBatchWhollyOnHolidayHasNoPlan() async {
        var vidya = classEightHoliday(on: PlanTest.wednesday)
        vidya.audience = .school(FakeSchoolsRepository.vidya.id)
        var sahil = classEightHoliday(on: PlanTest.wednesday)
        sahil.audience = .student(FakeStudentsRepository.sahil)
        let plans = FakePlansRepository()
        let store = await store(plans: plans, items: FakeSchoolItemsRepository(items: [vidya, sahil]))
        #expect(store.state == .holiday && plans.made.isEmpty && store.groups.isEmpty)
    }

    @Test func anExamAddedTodayRemakesTheOpenPlanWithRevisionLines() async throws {
        var exam = try #require(FakeSchoolItemsRepository.boardItems
            .first { $0.id == FakeSchoolItemsRepository.scienceTest3 })
        exam.date = FakeSchoolItemsRepository.day(30)
        let plans = FakePlansRepository()
        let items = FakeSchoolItemsRepository(items: [exam])
        let store = await store(plans: plans, items: items)
        #expect(store.record?.groups.allSatisfy { $0.examItemID == nil } == true)
        exam.date = FakeSchoolItemsRepository.day(16)
        _ = try await items.update(exam, centre: UUID())
        await store.remake(for: classEight)
        #expect(store.record?.groups.first?.examItemID == exam.id)
        let dev = store.record?.items.first { $0.studentID == FakeStudentsRepository.dev && $0.kind == .teach }
        #expect(dev?.words.hasPrefix(PlanRules.revisionPrefix) == true)
    }

    /// P13-Today-Revision: the exam group's head counts down to the test; its marks are Set, Sheet and Checks.
    @Test func anExamGroupsCardCountsDownToTheTest() async throws {
        let exam = try #require(FakeSchoolItemsRepository.boardItems
            .first { $0.id == FakeSchoolItemsRepository.scienceTest3 })
        let store = await store(items: FakeSchoolItemsRepository(items: [exam]))
        let card = try #require(store.groups.first)
        #expect(card.title == "Group 1 · Science unit test 3")
        #expect(card.line == "Class 8 Science · 3 students · the test in 9 days")
        #expect(card.marks.map(\.name) == ["Set", "Sheet", "Checks"])
    }

    /// Review Important 2: a plan made before the whole batch went on holiday is not shown again when reopened.
    @Test func aBatchWhollyOnHolidayStaysWithoutAPlanWhenReopened() async throws {
        var vidya = classEightHoliday(on: FakeSchoolItemsRepository.day(30))
        vidya.audience = .school(FakeSchoolsRepository.vidya.id)
        // Sahil's own holiday, an item of its own (the PTM's row made a holiday).
        var sahil = try #require(FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.ptm })
        sahil.kind = .holiday
        sahil.audience = .student(FakeStudentsRepository.sahil)
        sahil.date = FakeSchoolItemsRepository.day(30)
        let plans = FakePlansRepository()
        let items = FakeSchoolItemsRepository(items: [vidya, sahil])
        let first = await store(plans: plans, items: items)
        #expect(first.record != nil)
        vidya.date = PlanTest.wednesday
        sahil.date = PlanTest.wednesday
        _ = try await items.update(vidya, centre: UUID())
        _ = try await items.update(sahil, centre: UUID())
        let again = await store(plans: plans, items: items)
        #expect(again.state == .holiday && again.groups.isEmpty)
    }
}
