import Foundation
import Testing
@testable import Domain

struct DayTests {
    @Test func isoRoundTripAndValidation() {
        let day = Day(iso: "2011-03-14")
        #expect(day == Day(year: 2011, month: 3, day: 14) && day?.iso == "2011-03-14")
        #expect(Day(iso: "2011-02-30") == nil && Day(iso: "14/03/2011") == nil && Day(year: 2026, month: 13, day: 1) ==
            nil)
    }

    @Test func textsAsComponentsWritesThem() throws {
        let day = try #require(Day(year: 2011, month: 3, day: 14))
        #expect(day.text == "14 Mar 2011" && Day(year: 2026, month: 10, day: 4)!.shortText == "4 Oct")
        #expect(Day(year: 2026, month: 10, day: 7)?.longText == "7 October")
    }

    @Test func fromADateAndBackInIndia() throws {
        let instant = try #require(DayHeading.india.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 7,
            hour: 23,
            minute: 50
        )))
        let day = Day(instant, calendar: DayHeading.india)
        #expect(day == Day(year: 2026, month: 10, day: 7))
        #expect(day.weekday(in: DayHeading.india) == .wednesday)
        #expect(day.adding(days: 2, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 9))
        #expect(day.adding(days: -2, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 5))
        #expect(DayHeading.india.component(.hour, from: day.date(in: DayHeading.india)) == 0)
        #expect(try #require(Day(year: 2026, month: 9, day: 30)) < day)
    }

    @Test func theWordsThePhaseFourBoardsUse() throws {
        let saturday = try #require(Day(year: 2026, month: 10, day: 10))
        #expect(saturday.shortWeekdayText == "Sat 10 Oct" && saturday.weekdayLongText == "Saturday 10 October")
        #expect(saturday.period == Period(year: 2026, month: 10))
    }

    @Test func theEventFormsDay() {
        #expect(Day(year: 2026, month: 10, day: 10)?.fullText == "Sat 10 Oct 2026")
    }
}
