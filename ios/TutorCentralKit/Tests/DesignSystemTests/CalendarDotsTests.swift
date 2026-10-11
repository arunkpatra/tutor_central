import Foundation
import Testing
@testable import DesignSystem

struct CalendarDotsTests {
    @Test func aDayDrawsOneDotPerKindExamFirstAtMostThree() {
        #expect(CalendarMonth.dots(for: [.notice, .holiday, .exam, .homework]) == [.exam, .homework, .holiday])
        #expect(CalendarMonth.dots(for: [.holiday, .holiday, .notice]) == [.holiday, .notice])
        #expect(CalendarMonth.dots(for: []).isEmpty)
    }
}
