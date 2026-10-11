import Domain
import Foundation
import Testing

struct SchoolItemRulesTests: SchoolSamples {
    let today = Day(year: 2026, month: 10, day: 7)!
    let calendar = DayHeading.india

    @Test func anItemForASchoolsClassReachesItsActiveStudentsNowAndLater() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .eight))
        #expect(SchoolItemRules.students(for: item, in: people).map(\.name) == [
            "Dev Kumar",
            "Meher Shah",
            "Nikhil Das",
        ])
        var late = student("Late Joiner", level: .eight, school: vidya.id)
        #expect(SchoolItemRules.students(for: item, in: people + [late]).count == 4)
        late.archivedAt = Date()
        #expect(SchoolItemRules.students(for: item, in: people + [late]).count == 3)
    }

    @Test func anItemForAWholeSchoolReachesEveryClassAndAStudentsItemOnlyThem() {
        let holiday = SchoolItem.fixture(
            kind: .holiday,
            audience: .school(vidya.id),
            date: today.adding(days: 12, calendar: calendar)
        )
        #expect(SchoolItemRules.students(for: holiday, in: people).map(\.name) == [
            "Akshita Rao",
            "Dev Kumar",
            "Meher Shah",
            "Nikhil Das",
        ])
        let own = exam(audience: .student(dev.id))
        #expect(SchoolItemRules.students(for: own, in: people).map(\.id) == [dev.id])
    }

    @Test func anItemForAnEmptyClassReachesNoOneYet() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .nine))
        #expect(SchoolItemRules.students(for: item, in: people).isEmpty)
        #expect(SchoolItemRules
            .audienceLine(item, students: people, schools: [vidya]) ==
            "Class 9 at Vidya Niketan · no one in class 9 there yet")
    }

    @Test func aStudentAddedLaterIsReached() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .nine))
        let joiner = student("New Nine", level: .nine, school: vidya.id)
        #expect(SchoolItemRules.students(for: item, in: people + [joiner]).map(\.id) == [joiner.id])
    }

    @Test func theAudienceLineNamesTheClassTheSchoolAndTheStudents() {
        #expect(SchoolItemRules.audienceLine(
            exam(audience: .schoolClass(school: vidya.id, level: .eight)),
            students: people,
            schools: [vidya]
        ) == "Class 8 at Vidya Niketan · Dev, Meher, Nikhil")
        #expect(SchoolItemRules
            .audienceLine(exam(audience: .school(vidya.id)), students: people, schools: [vidya]) ==
            "Vidya Niketan, every class")
        #expect(SchoolItemRules.audienceLine(
            exam(audience: .student(riya.id)),
            students: people,
            schools: [vidya, stMarys]
        ) == "Riya Sharma · St Mary's School")
    }

    @Test func theCountdownReadsTodayTomorrowAndDaysAndNothingForThePast() {
        #expect(SchoolItemRules.countdown(from: today, to: today) == "today")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: 1, calendar: calendar)) == "tomorrow")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: 9, calendar: calendar)) == "in 9 days")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: -1, calendar: calendar)) == nil)
    }

    @Test func theListGroupsThisWeekNextWeekAndLaterFromTodayOn() {
        // Wednesday 7 October: this week ends Sunday 11; next week Monday 12 to Sunday 18.
        let items = [
            exam(date: today.adding(days: 1, calendar: calendar)), exam(date: today.adding(
                days: 9,
                calendar: calendar
            )),
            exam(date: today.adding(days: 12, calendar: calendar)), exam(date: today.adding(
                days: -2,
                calendar: calendar
            )),
        ]
        let buckets = SchoolItemRules.buckets(items, today: today, calendar: calendar)
        #expect(buckets.map(\.title) == ["This week", "Next week", "Later"])
        #expect(buckets.map(\.items.count) == [1, 1, 1])
    }

    @Test func theLineReadsWhoTheSubjectAndTheCountdownOrAHolidaysLastDay() {
        let item = exam(
            audience: .schoolClass(school: vidya.id, level: .eight),
            date: today.adding(days: 9, calendar: calendar),
            portions: "Ch 1 · Ch 2"
        )
        #expect(SchoolItemRules
            .line(item, today: today, students: people, schools: [vidya]) ==
            "Class 8 at Vidya Niketan · Dev, Meher, Nikhil · in 9 days")
        var holiday = SchoolItem.fixture(
            kind: .holiday,
            audience: .school(vidya.id),
            date: today.adding(days: 12, calendar: calendar)
        )
        holiday.endDate = today.adding(days: 14, calendar: calendar)
        #expect(SchoolItemRules
            .line(holiday, today: today, students: people, schools: [vidya]) == "Vidya Niketan · to Wed 21 Oct")
    }

    @Test func theNearestExamOfASubjectDrivesThenTheNext() {
        let preBoard = exam(
            audience: .student(akshita.id),
            date: today.adding(days: 10, calendar: calendar),
            subject: "Mathematics",
            title: "Pre-board"
        )
        let board = exam(
            audience: .student(akshita.id),
            date: today.adding(days: 40, calendar: calendar),
            subject: "Mathematics",
            title: "Board exam"
        )
        #expect(SchoolItemRules.nearestExam(
            for: akshita,
            items: [board, preBoard],
            students: people,
            today: today,
            calendar: calendar
        )?.title == "Pre-board")
        let after = today.adding(days: 11, calendar: calendar)
        #expect(SchoolItemRules.nearestExam(
            for: akshita,
            items: [board, preBoard],
            students: people,
            today: after,
            calendar: calendar
        ) == nil)
        let inWindow = today.adding(days: 27, calendar: calendar)
        #expect(SchoolItemRules.nearestExam(
            for: akshita,
            items: [board, preBoard],
            students: people,
            today: inWindow,
            calendar: calendar
        )?.title == "Board exam")
    }

    @Test func hintsCarryOneExamPerStudentWithinTheWindow() {
        let item = exam(
            audience: .schoolClass(school: vidya.id, level: .eight),
            date: today.adding(days: 9, calendar: calendar)
        )
        let far = exam(
            audience: .schoolClass(school: vidya.id, level: .eight),
            date: today.adding(days: 20, calendar: calendar),
            subject: "Mathematics"
        )
        let hints = SchoolItemRules.hints([item, far], students: people, today: today, calendar: calendar)
        #expect(hints.count == 3 && hints.allSatisfy { $0.subject == "Science" })
    }

    @Test func aDraftWithoutADateIsNotComplete() {
        var draft = SchoolItemDraft(
            kind: .exam,
            audience: .student(dev.id),
            title: "Unit test",
            subject: "Science",
            date: nil,
            source: .sharedText
        )
        #expect(!draft.isComplete && draft.missing == [.date])
        draft.date = today
        #expect(draft.isComplete)
        let noOne = SchoolItemDraft(
            kind: .holiday,
            audience: nil,
            title: "Dasara",
            subject: nil,
            date: today,
            source: .sharedText
        )
        #expect(noOne.missing == [.audience])
        let noSubject = SchoolItemDraft(
            kind: .exam,
            audience: .student(dev.id),
            title: "Test",
            subject: nil,
            date: today,
            source: .typed
        )
        #expect(noSubject.missing == [.subject])
    }

    @Test func portionsAndTheTitleCountScalarsAndAreHeldToTheirLimits() {
        var draft = SchoolItemDraft(
            kind: .exam,
            audience: .student(dev.id),
            title: String(repeating: "अ", count: 120),
            subject: "Hindi",
            date: today,
            source: .typed
        )
        #expect(draft.isComplete)
        draft.title += "अ"
        #expect(draft.missing == [.title])
        draft.title = "Test"
        draft.portions = String(repeating: "क", count: 501)
        #expect(!draft.isComplete)
    }
}
