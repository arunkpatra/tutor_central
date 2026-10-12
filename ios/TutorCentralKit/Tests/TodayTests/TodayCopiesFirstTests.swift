import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// Offline each read takes its timeout to fail (about 20 s with the gateway down): Today, its plans and the note day
/// show
/// what this iPhone has before any read answers (Phase 18's hand run 8).
@MainActor struct TodayCopiesFirstTests {
    /// Offline the exams' read takes its timeout to fail: the copy is on screen before it answers, and the cards are
    /// drawn again when it does (run 8).
    @Test func theCopyShowsBeforeTheReadsAroundIt() async {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: PlanTest.centre, directory: directory)
        _ = await PlanStoreTests().store(cache: cache)
        let held = HeldRead()
        let items = FakeSchoolItemsRepository(items: [])
        items.beforeRead = { await held.hold() }
        let store = await PlanStoreTests().store(
            plans: FakePlansRepository(),
            online: false,
            cache: cache,
            items: items,
            load: false
        )
        let loading = Task { await store.load() }
        await held.untilHeld()
        let shown = if case .made = store.state {
            true
        } else {
            false
        }
        #expect(shown, "the copy waited for the exams' read")
        held.release()
        await loading.value
        #expect(store.groups.count == 3)
    }

    /// Offline the batches read one after another, each read taking its timeout: every plan is on screen from its copy
    /// before the first batch's reads answer (run 8).
    @Test func everyPlanShowsItsCopyBeforeAnyBatchReads() async {
        let cache = PlanCache(
            centre: PlanTest.centre,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        let (students, classes) = (FakeStudentsRepository.eveningSeed, FakeClassesRepository.withEvening)
        let online = await TodayStoreTests().make(
            now: PlanTest.at1635, students: students, classes: classes, plans: FakePlansRepository(), planCache: cache
        )
        await online.load()
        let held = HeldRead()
        let items = FakeSchoolItemsRepository(items: [])
        items.beforeRead = { await held.hold() }
        let store = await TodayStoreTests().make(
            now: PlanTest.at1635, students: students, classes: classes, plans: FakePlansRepository(), items: items,
            planCache: cache, plansOnline: false
        )
        let loading = Task { await store.load() }
        await held.untilHeld()
        let made = store.plans.values.filter {
            if case .made = $0.state {
                true
            } else {
                false
            }
        }
        #expect(store.plans.count == 2 && made.count == 2, "a batch waited for the one before it")
        held.release()
        await loading.value
    }

    /// Offline the week's read takes its timeout to fail: the register's rows are on screen before it answers, with no
    /// count until what was sent is known (run 8: "No notes this week" showed for ten seconds).
    @Test func theRegistersRowsShowBeforeTheWeeksRead() async {
        let held = HeldRead()
        let items = FakeSchoolItemsRepository(items: [])
        items.beforeRead = { await held.hold() }
        let store = await NoteDayStoreTests.make(NoteDayStoreTests.World(
            sent: [FakeStudentsRepository.dev],
            items: items
        ))
        let loading = Task { await store.load() }
        await held.untilHeld()
        #expect(store.isOn && store.heroLine == "7 notes for parents")
        #expect(store.countLine.isEmpty)
        #expect(store.rows.first { $0.id == FakeStudentsRepository.riya }?
            .state == .held(.consent(parentFirstName: "Neha")))
        held.release()
        await loading.value
        #expect(store.countLine == "1 of 7 sent")
    }
}
