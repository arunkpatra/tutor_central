import Foundation
import Testing
@testable import Domain

struct HolidayRulesTests: SchoolSamples {
    let calendar = DayHeading.india

    var evening: Classroom {
        Classroom(
            id: UUID(), name: "Evening batch", subject: "Science", monthlyFee: nil,
            meetingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 30), archivedAt: nil
        )
    }

    /// Dasara: Monday 19 to Wednesday 21 October, for Vidya Niketan.
    var dasara: SchoolItem {
        var item = SchoolItem.fixture(
            kind: .holiday,
            audience: .school(vidya.id),
            date: Day(year: 2026, month: 10, day: 19)!
        )
        item.endDate = Day(year: 2026, month: 10, day: 21)
        return item
    }

    @Test func aHolidayCoversItsDays() throws {
        #expect(try !HolidayRules.covers(dasara, #require(Day(year: 2026, month: 10, day: 18))))
        #expect(try HolidayRules.covers(dasara, #require(Day(year: 2026, month: 10, day: 19))))
        #expect(try HolidayRules.covers(dasara, #require(Day(year: 2026, month: 10, day: 21))))
        #expect(try !HolidayRules.covers(dasara, #require(Day(year: 2026, month: 10, day: 22))))
        let oneDay = SchoolItem.fixture(kind: .holiday, audience: .school(vidya.id), date: sampleToday)
        #expect(HolidayRules.covers(oneDay, sampleToday))
        #expect(!HolidayRules.covers(oneDay, sampleToday.adding(days: 1, calendar: calendar)))
        let anExam = exam(date: sampleToday)
        #expect(!HolidayRules.covers(anExam, sampleToday))
    }

    @Test func aStudentOfTheSchoolIsOnHolidayAndOthersAreNot() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 20))
        #expect(HolidayRules.onHoliday(dev, on: day, items: [dasara], students: people))
        #expect(!HolidayRules.onHoliday(riya, on: day, items: [dasara], students: people))
        #expect(!HolidayRules.onHoliday(
            dev,
            on: day.adding(days: 2, calendar: calendar),
            items: [dasara],
            students: people
        ))
    }

    @Test func aStudentsOwnHolidayCoversOnlyThem() {
        let own = SchoolItem.fixture(kind: .holiday, audience: .student(meher.id), date: sampleToday)
        #expect(HolidayRules.onHoliday(meher, on: sampleToday, items: [own], students: people))
        #expect(!HolidayRules.onHoliday(dev, on: sampleToday, items: [own], students: people))
    }

    @Test func theBatchDaysCoveredNameTheBatchsMeetingDays() {
        #expect(HolidayRules.batchDays(dasara, batch: evening, calendar: calendar).map(\.day) == [19, 20, 21])
        #expect(HolidayRules.coveredLine(dasara, batches: [evening], calendar: calendar)
            == "Mon 19, Tue 20 and Wed 21 Oct · Evening batch")
        var saturday = evening
        saturday.name = "Saturday batch"
        saturday.meetingDays = [.saturday]
        #expect(HolidayRules.batchDays(dasara, batch: saturday, calendar: calendar).isEmpty)
        #expect(HolidayRules.coveredLine(dasara, batches: [saturday], calendar: calendar).isEmpty)
    }
}
