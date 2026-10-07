import Data
import Domain
import Foundation
import Testing
@testable import Today

@MainActor struct TodayStoreTests {
    func make(_ counts: FakeCountsRepository = FakeCountsRepository()) -> TodayStore {
        TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            counts: counts,
            now: { FakeCountsRepository.fixedNow }
        )
    }

    @Test func headingGreetingInitialsAndZeroCounts() async {
        let store = make()
        #expect(store.heading == "Wednesday 7 October" && store.greeting == "Good evening, Meera" && store
            .initials == "MN")
        await store.load()
        #expect(store.counts == .zero && store.error == nil && !store.loading)
    }

    @Test func realCountsAreShown() async {
        let counts = FakeCountsRepository()
        counts.counts = TodayCounts(students: 10, due: Money(rupees: 2200), classesToday: 2)
        let store = make(counts)
        await store.load()
        #expect(store.counts.students == 10 && store.counts.due.rupees == 2200 && store.counts.classesToday == 2)
    }

    @Test func aCountsFailureKeepsTheLastValuesAndSaysSo() async {
        let counts = FakeCountsRepository()
        counts.counts = TodayCounts(students: 3, due: .zero, classesToday: 1)
        let store = make(counts)
        await store.load()
        counts.nextError = URLError(.notConnectedToInternet)
        await store.load()
        #expect(store.counts.students == 3 && store.error == "Couldn't refresh. Check your connection and try again.")
    }
}
