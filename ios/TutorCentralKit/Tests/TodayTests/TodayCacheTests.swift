import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

@MainActor struct TodayCacheTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("today-\(UUID().uuidString)")
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    func make(_ counts: FakeCountsRepository) -> TodayStore {
        let now = FakeCountsRepository.fixedNow
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: []),
            classes: FakeClassesRepository(classes: []), cache: nil, now: { now }
        )
        return TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace, counts: counts, register: register,
            attendance: FakeAttendanceRepository(), events: FakeEventsRepository(),
            tasks: TasksStore(
                workspace: FakeCentreRepository.meeraWorkspace,
                tasks: FakeTasksRepository(),
                now: { now }
            ),
            now: { now }, cache: CachedRead(centre: centre, key: "today", directory: folder)
        )
    }

    @Test func aCachedScreenShowsAtOnceWithItsTimeAndIsReplacedByTheNetwork() async {
        let savedAt = Date(timeIntervalSince1970: 1_791_540_000)
        let cached = TodayCounts(students: 9, due: Money(rupees: 3000), classesToday: 1)
        CachedRead<TodaySnapshot>(centre: centre, key: "today", directory: folder)
            .keep(TodaySnapshot(counts: cached, sessions: [], events: []), at: savedAt)
        let counts = FakeCountsRepository(counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1))
        let store = make(counts)
        store.showCached()
        #expect(store.counts.students == 9 && store.savedAt == savedAt)
        await store.load()
        #expect(store.counts == counts.counts && store.savedAt == nil && store.offlineRead == false)
        let kept = CachedRead<TodaySnapshot>(centre: centre, key: "today", directory: folder).load()
        #expect(kept?.value.counts == counts.counts)
    }

    @Test func anOfflineRefreshKeepsTheCachedValueAndSaysOffline() async {
        let counts = FakeCountsRepository(counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1))
        await make(counts).load() // fills the cache
        counts.nextError = URLError(.notConnectedToInternet)
        let again = make(counts)
        again.showCached()
        await again.load()
        #expect(again.counts == counts.counts && again.savedAt != nil && again.offlineRead && again.error == nil)
    }

    @Test func offlineWithNothingCachedSaysSoInTheErrorToo() async {
        let counts = FakeCountsRepository()
        counts.nextError = URLError(.notConnectedToInternet)
        let store = make(counts)
        store.showCached()
        await store.load()
        #expect(store.savedAt == nil && store.offlineRead && store.error != nil)
    }
}
