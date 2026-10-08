import Foundation
import Testing
@testable import Domain

struct OccurrencesTests {
    @Test func aClassesDaysInOctober() {
        let days = Occurrences.days(
            of: NextClassTests.maths,
            in: Period(year: 2026, month: 10),
            calendar: DayHeading.india
        )
        #expect(days.map(\.day) == [2, 5, 7, 9, 12, 14, 16, 19, 21, 23, 26, 28, 30])
        var none = NextClassTests.maths
        none.meetingDays = []
        #expect(Occurrences.days(of: none, in: Period(year: 2026, month: 10), calendar: DayHeading.india).isEmpty)
    }
}
