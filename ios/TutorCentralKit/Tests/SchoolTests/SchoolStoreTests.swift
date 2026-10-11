import Data
import Domain
import Foundation
import School
import Testing

@MainActor struct SchoolStoreTests {
    let centre = SchoolFixtures.centre

    func makeStore(items: [SchoolItem], failure: (any Error)? = nil, cache: SchoolCache? = nil) async -> SchoolStore {
        let repo = FakeSchoolItemsRepository(items: items)
        repo.nextError = failure
        return await SchoolStore(
            workspace: FakeCentreRepository.meeraWorkspace, items: repo, register: SchoolFixtures.register(),
            schools: FakeSchoolsRepository(), cache: cache, now: { SchoolFixtures.now }, calendar: DayHeading.india
        )
    }

    @Test func withNoItemsTheTabIsEmptyAndWithItemsItBuckets() async {
        let store = await makeStore(items: [])
        await store.load()
        #expect(store.state == .empty)
        let filled = await makeStore(items: SchoolFixtures.boardItems)
        await filled.load()
        #expect(filled.state == .items && filled.buckets.map(\.title) == ["This week", "Next week", "Later"])
        #expect(filled.buckets[1].rows.map(\.title) == ["Maths Ex 3.2, Q1 to 10", "Science unit test 3"])
        #expect(filled.buckets[1].rows[1].line == "Class 8 at Vidya Niketan · Dev, Meher, Nikhil · in 9 days")
        #expect(filled.buckets[1].rows[1].day == "Fri" && filled.buckets[1].rows[1].date == "16 Oct")
    }

    @Test func theCalendarDotsEachDayByKindAndListsTheChosenDay() async throws {
        let store = await makeStore(items: SchoolFixtures.boardItems)
        await store.load()
        store.segment = .calendar
        store.selectedDay = Day(year: 2026, month: 10, day: 16)
        #expect(try store.dots[#require(Day(year: 2026, month: 10, day: 16))] == [.exam])
        #expect(try store
            .dots[#require(Day(year: 2026, month: 10, day: 20))] == [.holiday]) // a holiday covers its days
        #expect(store.dayRows.map(\.title) == ["Science unit test 3"])
    }

    @Test func offlineTheTabShowsItsCopyAndAFailedReadWithNoCopySaysSo() async {
        let cache = SchoolCache(centre: centre, directory: SchoolFixtures.tmp)
        cache.keep(SchoolFixtures.boardItems, at: .now)
        let offline = await makeStore(
            items: SchoolFixtures.boardItems, failure: URLError(.notConnectedToInternet), cache: cache
        )
        await offline.load()
        #expect(offline.state == .offline && !offline.buckets.isEmpty)
        let bare = await makeStore(items: [], failure: URLError(.notConnectedToInternet), cache: nil)
        await bare.load()
        #expect(bare.state == .failed)
    }
}
