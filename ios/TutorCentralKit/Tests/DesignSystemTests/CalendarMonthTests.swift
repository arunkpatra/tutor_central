import Foundation
import Testing
@testable import DesignSystem

struct CalendarMonthTests {
    @Test func octoberStartsOnAThursday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Kolkata"))
        let october = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let days = CalendarMonth.monthDays(october, calendar)
        #expect(days.prefix(3).allSatisfy { $0 == nil } && days[3] != nil && days.compactMap(\.self).count == 31)
    }
}
