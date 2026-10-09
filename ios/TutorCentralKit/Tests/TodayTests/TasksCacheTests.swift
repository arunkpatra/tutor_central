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
}
