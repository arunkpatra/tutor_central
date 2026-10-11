import Data
import Domain
import Foundation
import Students
import Testing
@testable import Schedule

@MainActor struct ScheduleCacheTests {
    @Test func offlineTheSavedMonthsEventsShow() async {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("schedule-\(UUID().uuidString)")
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let events = FakeEventsRepository(events: FakeEventsRepository.seed)
        func make() -> ScheduleStore {
            let register = RegisterStore(
                workspace: FakeCentreRepository.meeraWorkspace,
                students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
                classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
                now: { FakeCountsRepository.fixedNow }
            )
            let store = ScheduleStore(
                workspace: FakeCentreRepository.meeraWorkspace, register: register, events: events,
                attendance: FakeAttendanceRepository(), now: { FakeCountsRepository.fixedNow }
            )
            store.cache = { CachedRead(centre: centre, key: "schedule-\($0.isoMonth)", directory: folder) }
            return store
        }
        await make().load()
        events.nextError = URLError(.notConnectedToInternet)
        let offline = make()
        await offline.load()
        #expect(!offline.comingUp.isEmpty && offline.savedAt != nil && offline.offlineRead && offline.error == nil)
    }

    /// Hand run 14: a reload that fails offline after a good read keeps the read's time; the line never says nothing
    /// is saved over a list on screen.
    @Test func aFailedReloadAfterAGoodReadKeepsTheReadsTime() async {
        let events = FakeEventsRepository(events: FakeEventsRepository.seed)
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let store = ScheduleStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, events: events,
            attendance: FakeAttendanceRepository(), now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        events.nextError = URLError(.notConnectedToInternet)
        await store.load()
        #expect(store.savedAt == FakeCountsRepository.fixedNow && store.offlineRead && store.error == nil)
    }
}
