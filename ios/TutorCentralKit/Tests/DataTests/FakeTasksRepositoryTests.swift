import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeTasksRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func theSeedAndTheWrites() async throws {
        let repo = FakeTasksRepository(tasks: FakeTasksRepository.seed)
        let all = try await repo.tasks(centre: centre)
        #expect(all.count == 4 && all.filter(\.isDone).count == 2)
        let made = try await repo.create(
            title: "Print worksheets for Class 8",
            dueDate: Day(year: 2026, month: 10, day: 9),
            centre: centre
        )
        #expect(made.title == "Print worksheets for Class 8" && made.dueDate?.day == 9 && !made.isDone)
        let done = try await repo.setDone(id: made.id, true)
        #expect(done.isDone && repo.doneCalls.count == 1)
        let undone = try await repo.setDone(id: made.id, false)
        #expect(!undone.isDone)
        #expect(try await repo.clearDone(centre: centre) == 2)
        #expect(try await repo.tasks(centre: centre).count == 3 && repo.cleared == 1)
    }
}
