import Domain
import Foundation
import Testing
@testable import Data

@MainActor
struct FakeSchoolItemsRepositoryTests {
    let centre = FakeSchoolsRepository.centre
    let vidya = FakeSchoolsRepository.vidya.id
    let today = Day(year: 2026, month: 10, day: 7)!

    func draft(_ title: String, date: Day?, ticked: Bool? = nil) -> SchoolItemDraft {
        SchoolItemDraft(
            kind: .homework, audience: .schoolClass(school: vidya, level: .eight), title: title, subject: "Mathematics",
            date: date, source: .sharedText, ticked: ticked
        )
    }

    @Test func addKeepsOnlyCompleteTickedDraftsAndConfirmsThem() async throws {
        let repo = FakeSchoolItemsRepository(items: [])
        let added = try await repo.add(
            [draft("Ex 3.2", date: today), draft("No date", date: nil), draft("Unticked", date: today, ticked: false)],
            photoPath: "c/item/a.jpg", centre: centre
        )
        #expect(added.map(\.title) == ["Ex 3.2"] && added[0].confirmedAt != nil && added[0].photoPath == "c/item/a.jpg")
        #expect(try await repo.items(centre: centre) == added)
        #expect(try await repo.item(id: added[0].id, centre: centre) == added[0])
    }

    @Test func updateReplacesTheItem() async throws {
        let repo = FakeSchoolItemsRepository(items: [])
        var item = try #require(try await repo.add([draft("Ex 3.2", date: today)], photoPath: nil, centre: centre)
            .first)
        item.title = "Ex 3.3"
        #expect(try await repo.update(item).title == "Ex 3.3")
        #expect(try await repo.items(centre: centre).map(\.title) == ["Ex 3.3"])
    }

    @Test func deleteRemovesIt() async throws {
        let repo = FakeSchoolItemsRepository(items: [])
        let item = try #require(try await repo.add([draft("Ex 3.2", date: today)], photoPath: nil, centre: centre)
            .first)
        try await repo.delete(id: item.id, centre: centre)
        #expect(try await repo.items(centre: centre).isEmpty)
    }

    @Test func aScriptedFailureThrows() async throws {
        let repo = FakeSchoolItemsRepository(items: [])
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.items(centre: centre) }
        #expect(try await repo.items(centre: centre).isEmpty)
    }

    @Test func theItemsComeByDateThenTitle() async throws {
        let repo = FakeSchoolItemsRepository(items: [])
        _ = try await repo.add(
            [
                draft("B", date: today.adding(days: 1, calendar: DayHeading.india)),
                draft("Z", date: today),
                draft("A", date: today),
            ],
            photoPath: nil, centre: centre
        )
        #expect(try await repo.items(centre: centre).map(\.title) == ["A", "Z", "B"])
    }
}

struct SchoolCacheTests {
    @Test func keepsAndLoadsTheItems() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("school-\(UUID().uuidString)")
        let cache = SchoolCache(centre: UUID(), directory: dir)
        #expect(cache.load() == nil)
        let item = try SchoolItem(
            id: UUID(), kind: .notice, audience: .school(UUID()), title: "PTM, 10:00", subject: nil,
            date: #require(Day(year: 2026, month: 10, day: 9)), endDate: nil, portions: nil, sourceText: nil,
            photoPath: nil,
            source: .typed, receivedAt: Date(timeIntervalSince1970: 1_791_540_000), confirmedAt: nil
        )
        let at = Date(timeIntervalSince1970: 1_791_540_100)
        cache.keep([item], at: at)
        #expect(cache.load()?.value == [item] && cache.load()?.savedAt == at)
    }
}
