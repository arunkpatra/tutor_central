import Foundation
import Testing
@testable import Domain

struct SpacedQueueTests {
    @Test func theQueuePicksTheLatestTaughtThenTheMostOverdue() {
        let now = FakeClock.oct7at1635
        let day: TimeInterval = 86400
        let c = chapter(1)
        let fresh = skill(c, 1, state: .taught, stateAt: now - day)
        let secureOld = skill(c, 2, state: .secure, stateAt: now - 30 * day, checked: now - 20 * day)
        let practising = skill(c, 3, state: .practising, stateAt: now - 10 * day, checked: now - 5 * day)
        let secureNew = skill(c, 4, state: .secure, stateAt: now - 30 * day, checked: now - 2 * day)
        let notStarted = skill(c, 5, state: .notStarted, stateAt: now - day)
        let picked = SpacedQueue.pick(
            skills: [notStarted, secureNew, practising, secureOld, fresh], chapters: [c], now: now,
            calendar: DayHeading.india
        )
        #expect(picked.map(\.id) == [fresh.id, secureOld.id, practising.id])
    }

    @Test func fewerThanThreeEligibleGivesFewerAndNoneGivesNone() {
        let c = chapter(1)
        let one = skill(c, 1, state: .taught, stateAt: FakeClock.oct7at1635)
        #expect(SpacedQueue.pick(
            skills: [one, skill(c, 2)],
            chapters: [c],
            now: FakeClock.oct7at1635,
            calendar: DayHeading.india
        ).map(\.id) == [one.id])
        #expect(SpacedQueue.pick(
            skills: [skill(c, 2)],
            chapters: [c],
            now: FakeClock.oct7at1635,
            calendar: DayHeading.india
        ).isEmpty)
    }

    @Test func theIntervalsByState() {
        #expect(SpacedQueue.interval(for: .taught) == 1 && SpacedQueue.interval(for: .revisit) == 1)
        #expect(SpacedQueue.interval(for: .practising) == 3 && SpacedQueue.interval(for: .secure) == 7)
        #expect(SpacedQueue.interval(for: .notStarted) == nil)
    }
}
