import Foundation
import Testing
@testable import Domain

@Suite struct PeriodTests {
    private let kolkata = TimeZone(identifier: "Asia/Kolkata")!

    @Test func startsOnTheFirstOfTheMonth() {
        let start = Period(year: 2026, month: 10).start(in: kolkata)
        let parts = Calendar(identifier: .gregorian).dateComponents(in: kolkata, from: start)
        #expect(parts.year == 2026 && parts.month == 10 && parts.day == 1 && parts.hour == 0)
    }

    @Test func containsADate() {
        let lateOnTheLastDay = Period(year: 2026, month: 10).next.start(in: kolkata).addingTimeInterval(-60)
        #expect(Period.containing(lateOnTheLastDay, in: kolkata) == Period(year: 2026, month: 10))
    }

    @Test func stepsAcrossYears() {
        #expect(Period(year: 2026, month: 12).next == Period(year: 2027, month: 1))
        #expect(Period(year: 2026, month: 1).previous == Period(year: 2025, month: 12))
    }

    @Test func titles() {
        #expect(Period(year: 2026, month: 10).title == "October 2026")
        #expect(Period(year: 2026, month: 10).shortTitle == "Oct 2026")
    }

    @Test func isoDay() {
        #expect(Period(year: 2026, month: 3).isoDay == "2026-03-01")
        #expect(Period(isoDay: "2026-03-01") == Period(year: 2026, month: 3))
        #expect(Period(isoDay: "2026-03-15") == nil)
        #expect(Period(isoDay: "2026-13-01") == nil)
        #expect(Period(isoDay: "march") == nil)
    }

    @Test func ordering() {
        #expect(Period(year: 2026, month: 9) < Period(year: 2026, month: 10))
        #expect(Period(year: 2025, month: 12) < Period(year: 2026, month: 1))
    }
}
