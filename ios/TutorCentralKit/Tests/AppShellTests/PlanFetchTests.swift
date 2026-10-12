import Data
import Domain
import Foundation
import Testing
@testable import AppShell

/// A plan's background push (plan decision 17): today's plans read into the copy on this iPhone.
@MainActor struct PlanFetchTests {
    let wednesday = Day(year: 2026, month: 10, day: 7)!

    func fetch(
        plans: FakePlansRepository, cache: PlanCache, signedIn: Bool = true, classes: [Classroom]? = nil
    ) -> PlanFetch {
        PlanFetch(
            workspace: { signedIn ? FakeCentreRepository.meeraWorkspace : nil },
            classes: FakeClassesRepository(classes: classes ?? FakeClassesRepository.withEvening), plans: plans,
            cache: { _ in cache }, now: { FakeCountsRepository.fixedNow }, calendar: DayHeading.india
        )
    }

    func cache() -> PlanCache {
        PlanCache(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
    }

    @Test func theFetchReadsTodaysPlansIntoTheCopy() async {
        let copy = cache()
        #expect(await fetch(plans: FakePlansRepository.evening(), cache: copy).run())
        #expect(copy.load(classID: FakeClassesRepository.evening.id, date: wednesday)?.value.id
            == FakePlansRepository.planID)
    }

    @Test func aFailedReadAnswersFalse() async {
        let plans = FakePlansRepository.evening()
        plans.nextError = URLError(.timedOut)
        #expect(await !fetch(plans: plans, cache: cache()).run())
    }

    /// iOS gives a background push 30 seconds and a stalled read takes about 20 s to fail: the fetch answers false at
    /// its deadline (the Phase 18 review's R-app-1).
    @Test func aStalledReadAnswersFalseAtTheDeadline() async {
        let plans = FakePlansRepository.evening()
        plans.delay = .seconds(60)
        let clock = ContinuousClock()
        var answered = true
        let took = await clock.measure {
            answered = await fetch(plans: plans, cache: cache()).run(within: .milliseconds(200))
        }
        #expect(!answered)
        #expect(took < .seconds(2), "the fetch waited for the stalled read")
    }

    @Test func withinTheDeadlineTheFetchAnswersAsBefore() async {
        #expect(await fetch(plans: FakePlansRepository.evening(), cache: cache()).run(within: .seconds(5)))
    }

    @Test func signedOutTheFetchDoesNothing() async {
        let copy = cache()
        #expect(await !fetch(plans: FakePlansRepository.evening(), cache: copy, signedIn: false).run())
        #expect(copy.load(classID: FakeClassesRepository.evening.id, date: wednesday) == nil)
    }

    @Test func onlyAPlansFetchIsAsked() {
        let fetch: [AnyHashable: Any] = ["aps": ["content-available": 1], "fetch": "plan", "id": "n1"]
        let alert: [AnyHashable: Any] = ["aps": ["alert": ["title": "t"]], "link": "tutorcentral://today"]
        let asked = (PlanFetch.asks(fetch), PlanFetch.asks(alert))
        #expect(asked.0 && !asked.1)
    }
}
