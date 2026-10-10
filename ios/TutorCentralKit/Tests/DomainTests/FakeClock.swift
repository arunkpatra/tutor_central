import Foundation
@testable import Domain

/// The fixtures' moments in India (the boards' Wednesday 7 October 2026).
enum FakeClock {
    static func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    static let oct7at1635 = at(2026, 10, 7, 16, 35)
    static let oct7at1705 = at(2026, 10, 7, 17, 5)
    static let oct7at1832 = at(2026, 10, 7, 18, 32)
    static let oct7at1840 = at(2026, 10, 7, 18, 40)
    static let sat10at0930 = at(2026, 10, 10, 9, 30)
}
