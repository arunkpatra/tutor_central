import Data
import Domain
import Foundation
import Testing
@testable import Today

@MainActor struct TasksCacheTests {
    @Test func offlineTheSavedTasksShowWithTheirTime() async {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("tasks-\(UUID().uuidString)")
        let repository = FakeTasksRepository(tasks: FakeTasksRepository.seed)
        func make() -> TasksStore {
            let store = TasksStore(
                workspace: FakeCentreRepository.meeraWorkspace, tasks: repository,
                now: { FakeCountsRepository.fixedNow }
            )
            store.cache = CachedRead(
                centre: FakeCentreRepository.meeraWorkspace.centre.id,
                key: "tasks",
                directory: folder
            )
            return store
        }
        await make().load()
        repository.nextError = URLError(.notConnectedToInternet)
        let offline = make()
        await offline.load()
        #expect(offline.tasks.count == FakeTasksRepository.seed.count && offline.savedAt != nil)
        #expect(offline.offlineRead && offline.error == nil)
    }

    /// Hand run 14: a reload that fails offline after a good read keeps the read's time; the line never says nothing
    /// is saved over a list on screen.
    @Test func aFailedReloadAfterAGoodReadKeepsTheReadsTime() async {
        let repository = FakeTasksRepository(tasks: FakeTasksRepository.seed)
        let store = TasksStore(
            workspace: FakeCentreRepository.meeraWorkspace, tasks: repository, now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        repository.nextError = URLError(.notConnectedToInternet)
        await store.load()
        #expect(store.savedAt == FakeCountsRepository.fixedNow && store.offlineRead && store.error == nil)
    }
}
