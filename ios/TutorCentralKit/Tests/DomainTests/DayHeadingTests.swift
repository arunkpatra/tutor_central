import Foundation
import Testing
@testable import Domain

struct DayHeadingTests {
    @Test func theLongFormForTodayHasNoYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18)))
        #expect(DayHeading.long(date, calendar: calendar) == "Wednesday 7 October")
    }
}
