import Foundation
import Testing
@testable import Domain

struct ExamPreparationTests: SchoolSamples {
    let today = Day(year: 2026, month: 10, day: 7)! // Wednesday
    let calendar = DayHeading.india

    func context(_ holidays: [SchoolItem]) -> PreparationContext {
        PreparationContext(batch: evening, today: today, holidays: holidays, students: [dev], calendar: calendar)
    }

    @Test func portionsAreCutAtDotsSemicolonsLinesAndChapterMarkers() {
        #expect(ExamPreparation.portions("Ch 1 Chemical reactions · Ch 2 Acids, bases and salts") == [
            "Chemical reactions",
            "Acids, bases and salts",
        ])
        #expect(ExamPreparation.portions("Chapters 3 and 4") == ["Chapters 3 and 4"])
        #expect(ExamPreparation.portions("Fractions; Decimals\nPercentages") == [
            "Fractions",
            "Decimals",
            "Percentages",
        ])
    }

    @Test func aPortionMatchesAChapterByNameEitherWay() {
        #expect(ExamPreparation.matching("Ch 1 Chemical reactions", in: devChapters)
            .map(\.name) == ["Chemical reactions"])
        #expect(ExamPreparation.matching("acids and bases", in: devChapters).isEmpty)
        #expect(ExamPreparation.matching("Acids, bases and salts · indicators", in: devChapters)
            .map(\.name) == ["Acids, bases and salts"])
    }

    @Test func aPortionNamingChapterNumbersMatchesThoseChapters() {
        #expect(ExamPreparation.matching("chapters 1 and 2", in: devChapters).map(\.position) == [1, 2])
        #expect(ExamPreparation.matching("Ch 2", in: devChapters).map(\.name) == ["Acids, bases and salts"])
        #expect(ExamPreparation.matching("Chapters 1 to 2", in: devChapters).count == 2)
        #expect(ExamPreparation.matching("Chapter 9", in: devChapters).isEmpty)
    }

    @Test func nineDaysOutSplitsTwoPortionsOverTheRevisionDaysWithTheMockTwoDaysBefore() {
        // Fri 16 Oct: meeting days Wed 7, Thu 8, Fri 9, Mon 12, Tue 13, Wed 14, Thu 15 (seven). Mock Wed 14; after-mock
        // Thu 15.
        let days = ExamPreparation.days(
            exam: exam16,
            student: dev,
            chapters: devChapters,
            skills: devSkills,
            context: context([])
        )
        #expect(days.map(\.day.day) == [7, 8, 9, 12, 13, 14, 15, 16])
        #expect(days.map(\.kind) == [
            .revise(index: 1),
            .revise(index: 2),
            .revise(index: 3),
            .revise(index: 4),
            .revise(index: 5),
            .mock,
            .afterMock,
            .exam,
        ])
        #expect(days[0].title == "Chemical reactions · part 1 of 3" && days[0].skills.count == 2)
        #expect(days[3].title == "Acids, bases and salts · first half")
        #expect(days[5].title == "The mock" && days[6].title == "What the mock showed" && days[7].title == "The test")
    }

    @Test func aHolidayDropsItsDaysFromTheSplit() throws {
        var holiday = try SchoolItem.fixture(
            kind: .holiday,
            audience: .school(vidya.id),
            date: #require(Day(year: 2026, month: 10, day: 12))
        )
        holiday.endDate = try #require(Day(year: 2026, month: 10, day: 13))
        let days = ExamPreparation.days(
            exam: exam16,
            student: dev,
            chapters: devChapters,
            skills: devSkills,
            context: context([holiday])
        )
        #expect(!days.map(\.day.day).contains(12) && !days.map(\.day.day).contains(13))
    }

    @Test func fewerDaysThanPortionsPutSeveralOnOneDay() throws {
        let exam = try SchoolItem.fixture(
            kind: .exam,
            audience: .student(dev.id),
            date: #require(Day(year: 2026, month: 10, day: 12)),
            portions: "Ch 1 · Ch 2 · Ch 3 · Ch 4"
        )
        // Days before: Wed 7, Thu 8, Fri 9 → mock Fri 9, after-mock none, revision Wed and Thu for four portions.
        let days = ExamPreparation.days(exam: exam, student: dev, chapters: [], skills: [], context: context([]))
        #expect(days.map(\.kind) == [.revise(index: 1), .revise(index: 2), .mock, .exam])
        #expect(days[0].title == "Ch 1 · Ch 2" && days[0].skills == ["Ch 1", "Ch 2"])
    }

    @Test func twoDaysLeaveNoRoomForAMock() throws {
        let exam = try SchoolItem.fixture(
            kind: .exam,
            audience: .student(dev.id),
            date: #require(Day(year: 2026, month: 10, day: 9)),
            portions: "Ch 1"
        )
        let days = ExamPreparation.days(
            exam: exam,
            student: dev,
            chapters: devChapters,
            skills: devSkills,
            context: context([])
        )
        #expect(days.map(\.kind) == [.revise(index: 1), .revise(index: 2), .exam])
    }

    @Test func theDayBeforeTheExamIsTheLastRevisionDay() throws {
        let exam = try SchoolItem.fixture(
            kind: .exam,
            audience: .student(dev.id),
            date: #require(Day(year: 2026, month: 10, day: 8)),
            portions: "Ch 1"
        )
        let days = ExamPreparation.days(
            exam: exam,
            student: dev,
            chapters: devChapters,
            skills: devSkills,
            context: context([])
        )
        #expect(days.map(\.kind) == [.revise(index: 1), .exam])
    }

    @Test func aSecondExamAfterTheFirstIsNotSplitYet() {
        let board = SchoolItem.fixture(
            kind: .exam,
            audience: .student(dev.id),
            date: today.adding(days: 40, calendar: calendar),
            portions: "Everything"
        )
        #expect(!ExamPreparation.isWithinWindow(board, today: today, calendar: calendar))
        #expect(ExamPreparation.isWithinWindow(exam16, today: today, calendar: calendar))
    }

    @Test func theWeakestSkillAmongThePortionsIsRevisitThenPractisingThenTaught() {
        let names = devSkills.map(\.name)
        #expect(ExamPreparation.weakest(devSkills, among: names)?
            .name == "Balance a chemical equation") // the fixture's revisit
        #expect(ExamPreparation.weakest(devSkills.filter { $0.state == .secure }, among: names) == nil)
    }

    /// The plan reads the split each day: it starts when the item came (or at the window's start), not today, so the
    /// mock day found on Wednesday 7 is still the mock day on Wednesday 14.
    @Test func theSplitStartsWhenTheItemCameSoTheMockDayHolds() throws {
        var exam = exam16
        exam.receivedAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 15)))
        let wednesday14 = try #require(Day(year: 2026, month: 10, day: 14))
        let start = ExamPreparation.start(of: exam, today: wednesday14, calendar: calendar)
        #expect(start == today)
        let split = PreparationContext(batch: evening, today: start, holidays: [], students: [dev], calendar: calendar)
        let days = ExamPreparation.days(exam: exam, student: dev, chapters: [], skills: [], context: split)
        #expect(days.first { $0.day == wednesday14 }?.kind == .mock)
        #expect(ExamPreparation.start(of: exam, today: today, calendar: calendar) == today)
        exam.receivedAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 9)))
        #expect(ExamPreparation.start(of: exam, today: wednesday14, calendar: calendar) == Day(
            year: 2026,
            month: 10,
            day: 2
        ))
    }
}
