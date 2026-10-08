import Foundation
import Testing
@testable import Domain

struct ClassroomTests {
    static let maths = Classroom(
        id: UUID(), name: "Class 10 Maths", subject: "Mathematics", monthlyFee: Money(rupees: 1200),
        meetingDays: [.monday, .wednesday, .friday], startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(
            hour: 18,
            minute: 0
        ),
        archivedAt: nil
    )

    @Test func theSummaryAsTheBoardsWriteIt() {
        #expect(Self.maths.meetingSummary == "Mon, Wed, Fri · 17:00–18:00")
        var noTime = Self.maths
        noTime.startTime = nil
        noTime.endTime = nil
        #expect(noTime.meetingSummary == "Mon, Wed, Fri" && noTime.timeRange == nil)
        var startOnly = Self.maths
        startOnly.endTime = nil
        #expect(startOnly.timeRange == "17:00")
        var daily = Self.maths
        daily.meetingDays = Set(Weekday.allCases)
        #expect(daily.daysSummary == "Every day")
        var none = Self.maths
        none.meetingDays = []
        #expect(none.meetingSummary == "No days set · 17:00–18:00")
    }

    @Test func daysAreListedInWeekOrderHoweverTheSetCame() {
        var c = Self.maths
        c.meetingDays = [.sunday, .tuesday]
        #expect(c.daysSummary == "Tue, Sun")
    }

    @Test func thisWeeksMeetingsFromAWednesday() throws {
        let wednesday = try #require(Day(year: 2026, month: 10, day: 7))
        let days = Self.maths.meetings(inWeekOf: wednesday, calendar: DayHeading.india)
        #expect(try days == [
            #require(Day(year: 2026, month: 10, day: 5)),
            wednesday,
            #require(Day(year: 2026, month: 10, day: 9)),
        ])
        // The week runs Monday to Sunday: asked on a Sunday, the same week comes back.
        let sunday = try #require(Day(year: 2026, month: 10, day: 11))
        #expect(Self.maths.meetings(inWeekOf: sunday, calendar: DayHeading.india) == days)
        var none = Self.maths
        none.meetingDays = []
        #expect(none.meetings(inWeekOf: wednesday, calendar: DayHeading.india).isEmpty)
    }

    @Test func archivedIsAFlagOnTheDate() {
        #expect(!Self.maths.isArchived)
        var gone = Self.maths
        gone.archivedAt = Date()
        #expect(gone.isArchived)
    }
}
