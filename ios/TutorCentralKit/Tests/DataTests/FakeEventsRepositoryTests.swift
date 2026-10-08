import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeEventsRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func readsWritesAndDeletes() async throws {
        let repo = FakeEventsRepository(events: FakeEventsRepository.seed)
        let october = try await repo.events(
            centre: centre,
            from: #require(Day(year: 2026, month: 10, day: 1)),
            to: #require(Day(year: 2026, month: 10, day: 31))
        )
        #expect(october.map(\.title) == ["Parents' meeting", "Mock test, Class 10"])
        var draft = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 20)))
        draft.title = "Holiday"
        let made = try await repo.create(draft, centre: centre)
        #expect(made.title == "Holiday" && repo.created.count == 1)
        draft.title = "Diwali holiday"
        let changed = try await repo.update(id: made.id, with: draft)
        #expect(changed.title == "Diwali holiday" && changed.id == made.id)
        try await repo.delete(id: made.id)
        #expect(repo.deleted == [made.id] && repo.events.count == 2)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.delete(id: FakeEventsRepository.mockTest.id) }
    }
}
