import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

@MainActor struct TodayStoreTests {
    static func clock(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func make(
        _ counts: FakeCountsRepository = FakeCountsRepository(),
        now: Date = FakeCountsRepository.fixedNow,
        students: [Student] = FakeStudentsRepository.seed,
        classes: [Classroom] = FakeClassesRepository.seed,
        sessions: [AttendanceSession] = FakeAttendanceRepository.seed,
        events: [CalendarEvent] = FakeEventsRepository.seed,
        tasks: [TaskItem] = FakeTasksRepository.seed,
        record: FakeRecordRepository? = nil,
        plans: FakePlansRepository? = nil
    ) async -> TodayStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: classes), cache: nil, now: { now }
        )
        let taskStore = TasksStore(
            workspace: FakeCentreRepository.meeraWorkspace, tasks: FakeTasksRepository(tasks: tasks), now: { now }
        )
        let attendance = FakeAttendanceRepository(sessions: sessions)
        let store = TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace, counts: counts, register: register,
            attendance: attendance, events: FakeEventsRepository(events: events),
            tasks: taskStore, now: { now }, record: record
        )
        if let plans {
            let maker = PlanTest.maker(plans: plans, attendance: attendance, now: now)
            store.makePlanStore = { classID in
                PlanStore(
                    classID: classID, workspace: FakeCentreRepository.meeraWorkspace, register: register,
                    plans: plans, classes: FakeClassesRepository(classes: classes), maker: maker, cache: nil,
                    now: { now }, calendar: DayHeading.india
                )
            }
        }
        return store
    }

    func makeLive(
        now: Date, sessions: [AttendanceSession] = FakeAttendanceRepository.seed, record: FakeRecordRepository? = nil
    ) async -> TodayStore {
        let counts = FakeCountsRepository(counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1))
        let store = await make(counts, now: now, sessions: sessions, record: record)
        await store.load()
        return store
    }

    @Test func headingGreetingInitialsAndZeroCounts() async {
        let store = await make()
        #expect(store.heading == "Wednesday 7 October" && store.greeting == "Good evening, Meera" && store
            .initials == "MN")
        await store.load()
        #expect(store.counts == .zero && store.error == nil && !store.loading)
    }

    @Test func realCountsAreShown() async {
        let counts = FakeCountsRepository()
        counts.counts = TodayCounts(students: 10, due: Money(rupees: 2200), classesToday: 2)
        let store = await make(counts)
        await store.load()
        #expect(store.counts.students == 10 && store.counts.due.rupees == 2200 && store.counts.classesToday == 2)
    }

    @Test func aCountsFailureKeepsTheLastValuesAndSaysSo() async {
        let counts = FakeCountsRepository()
        counts.counts = TodayCounts(students: 3, due: .zero, classesToday: 1)
        let store = await make(counts)
        await store.load()
        counts.nextError = URLError(.notConnectedToInternet)
        await store.load()
        #expect(store.counts.students == 3 && store.error == "Couldn't refresh. Check your connection and try again.")
    }

    @Test func aClassSoon() async throws {
        let store = await makeLive(now: Self.clock(7, 16, 35))
        #expect(store.greeting == "Good afternoon, Meera" && store.heading == "Wednesday 7 October")
        let hero = try #require(store.hero)
        #expect(hero.eyebrow == "Next batch · in 25 min" && hero.accent && hero.title == "Class 10 Maths")
        #expect(hero.line == "17:00–18:00 · 6 students" && hero.kind == .start && hero.classID == FakeClassesRepository
            .maths.id && !hero.titleMark)
        #expect(store.todayRows.map(\.title) == ["Class 10 Maths"] && store.todayRows[0]
            .line == "Mon, Wed, Fri · 6 students")
        #expect(!store.todayRows[0].marked)
        #expect(store.comingUp.map(\.day) == ["Sat 10"] && store.comingUp[0].line == "11:00–12:00 · Class 10 parents")
        #expect(!store.showsStartHere)
    }

    @Test func theEveningAfterTheClass() async throws {
        let store = await makeLive(now: Self.clock(7, 19, 30), sessions: FakeAttendanceRepository.seedWithToday)
        let hero = try #require(store.hero)
        #expect(store.greeting == "Good evening, Meera" && hero.eyebrow == "Next batch · tomorrow" && !hero.accent)
        #expect(hero.title == "Class 8 Science" && hero.line == "Thu 8 Oct · 16:30–17:30 · 3 students" && hero
            .kind == .upcoming)
        #expect(store.todayRows[0].line == "5 of 6 present" && store.todayRows[0].lineTone == .ok && store.todayRows[0]
            .marked)
    }

    @Test func aSaturdayWithNoClass() async throws {
        let store = await makeLive(now: Self.clock(10, 9, 30))
        let hero = try #require(store.hero)
        #expect(store.greeting == "Good morning, Meera" && hero.eyebrow == "No batch today" && hero.accent)
        #expect(hero.title == "Next: Class 10 Maths on Monday" && hero.kind == .upcoming)
        #expect(hero.line == "17:00–18:00 · 6 students · its plan is made when you open the app on Monday")
        #expect(store.todayRows.map(\.title) == ["Parents' meeting"] && store.todayRows[0].start == "11:00")
        #expect(store.todayRows[0].end == "12:00" && store.todayRows[0]
            .line == "Class 10 parents. Bring the September test papers.")
        #expect(store.comingUp.map(\.day) == ["Sat 17"])
    }

    @Test func theClockTicksTheCountdown() async {
        let store = await makeLive(now: Self.clock(7, 16, 35))
        store.tick(Self.clock(7, 16, 50))
        #expect(store.hero?.eyebrow == "Next batch · in 10 min")
        store.tick(Self.clock(7, 17, 0))
        #expect(store.hero?.eyebrow == "Now · until 18:00")
    }

    @Test func afterTheCloseTheHeroReadsWhatHappened() async throws {
        let record = FakeRecordRepository(
            checks: FakeRecordRepository.todaysChecks, homework: FakeRecordRepository.todaysHomework
        )
        let store = await makeLive(
            now: Self.clock(7, 18, 40), sessions: FakeAttendanceRepository.seedWithTodayClosed, record: record
        )
        let hero = try #require(store.hero)
        #expect(hero.eyebrow == "Class 10 Maths · closed at 18:32" && !hero.accent)
        #expect(hero.title == "5 of 6 came" && hero.titleMark && hero.kind == .closed)
        #expect(hero.line == "8 of 12 checks right · homework given to 5 · Hemanth absent")
    }

    @Test func aBatchClosedBeforeItsEndReadsClosed() async throws {
        let store = await makeLive(now: Self.clock(7, 17, 50), sessions: FakeAttendanceRepository.seedWithTodayClosed)
        let hero = try #require(store.hero)
        #expect(hero.kind == .closed && hero.line == "Hemanth absent")
    }

    @Test func aClosedBatchStillRunningGivesTheHeroToTheNextBatchSoon() async throws {
        var science = FakeClassesRepository.science
        science.meetingDays = [.wednesday]
        science.startTime = TimeOfDay(hour: 17, minute: 30)
        science.endTime = TimeOfDay(hour: 18, minute: 30)
        let counts = FakeCountsRepository(counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 2))
        let store = await make(
            counts, now: Self.clock(7, 17, 10), classes: [FakeClassesRepository.maths, science],
            sessions: FakeAttendanceRepository.seedWithTodayClosed
        )
        await store.load()
        let hero = try #require(store.hero)
        #expect(hero.kind == .start && hero.title == "Class 8 Science" && hero.eyebrow == "Next batch · in 20 min")
    }

    @Test func anEmptyRegisterKeepsStartHere() async {
        let store = await make(students: [], classes: [], sessions: [], events: [], tasks: [])
        await store.load()
        #expect(store.showsStartHere && store.hero == nil && store.todayRows.isEmpty)
    }

    @Test func todayHoldsAPlanStorePerBatchMeetingToday() async {
        let store = await make(
            now: PlanTest.at1635, students: FakeStudentsRepository.eveningSeed,
            classes: FakeClassesRepository.withEvening, plans: FakePlansRepository()
        )
        await store.load()
        #expect(Set(store.plans.keys) == [FakeClassesRepository.maths.id, FakeClassesRepository.evening.id])
        #expect(store.planBatches.map(\.id) == [FakeClassesRepository.maths.id, FakeClassesRepository.evening.id])
    }

    @Test func twoBatchesGetTwoPlans() async throws {
        let plans = FakePlansRepository()
        let store = await make(
            now: PlanTest.at1635, students: FakeStudentsRepository.eveningSeed,
            classes: FakeClassesRepository.withEvening, plans: plans
        )
        await store.load()
        for batch in [FakeClassesRepository.maths.id, FakeClassesRepository.evening.id] {
            #expect(try await plans.plan(centre: PlanTest.centre, classID: batch, date: PlanTest.wednesday) != nil)
        }
    }

    @Test func theHeroCountsThePlansGroups() async {
        let store = await make(
            now: PlanTest.at1635, students: FakeStudentsRepository.eveningSeed,
            classes: [FakeClassesRepository.evening], plans: FakePlansRepository()
        )
        await store.load()
        #expect(store.hero?.line == "17:00–18:30 · 5 students · 3 groups")
    }
}
