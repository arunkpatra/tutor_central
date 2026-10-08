import Foundation
import Testing
@testable import Domain

struct WeekdayTests {
    @Test func namesAndOrder() {
        #expect(Weekday.monday.short == "Mon" && Weekday.sunday.short == "Sun")
        #expect(Weekday.thursday.initial == "T" && Weekday.saturday.name == "Saturday")
        #expect(Weekday.monday < Weekday.sunday)
        #expect(Weekday.allCases.map(\.rawValue) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func fromADateInIndia() throws {
        // Wednesday 7 October 2026, 18:30 IST; and the same instant is still Wednesday in India after midnight UTC.
        let wednesday = try #require(DayHeading.india.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 7,
            hour: 18,
            minute: 30
        )))
        #expect(Weekday(date: wednesday, calendar: DayHeading.india) == .wednesday)
        let sundayLate = try #require(DayHeading.india.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 11,
            hour: 23,
            minute: 50
        )))
        #expect(Weekday(date: sundayLate, calendar: DayHeading.india) == .sunday)
    }
}
