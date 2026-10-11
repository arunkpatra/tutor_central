import Foundation
import Testing
@testable import Domain

struct NoteDayTests: ParentFixtures {
    @Test func theDefaultIsSundayAtSix() {
        #expect(NoteDay.default.title == "Sunday 18:00")
        #expect(NoteDay.choices.map(\.title) == [
            "Friday 18:00", "Saturday 18:00", "Sunday 18:00", "Sunday 20:00", "Monday 08:00",
        ])
    }

    @Test func theNoteDayIsOnFromItsTimeToTheEndOfTheNextDay() {
        let note = NoteDay.default
        #expect(!note.isOn(at: india(2026, 10, 11, 17, 59), calendar: calendar))
        #expect(note.isOn(at: india(2026, 10, 11, 18, 0), calendar: calendar))
        #expect(note.isOn(at: india(2026, 10, 12, 23, 59), calendar: calendar))
        #expect(!note.isOn(at: india(2026, 10, 13, 0, 1), calendar: calendar))
    }

    @Test func theWeekEndsOnTheNoteDayWhateverTheWeekday() throws {
        let saturday = try NoteDay(weekday: .saturday, time: #require(TimeOfDay(hour: 18, minute: 0)))
        let week = NoteDay.week(
            ending: saturday.noteDay(for: india(2026, 10, 10, 19, 0), calendar: calendar), calendar: calendar
        )
        #expect(week == day(10, 5) ... day(10, 10))
        let monday = try NoteDay(weekday: .monday, time: #require(TimeOfDay(hour: 8, minute: 0)))
        let mondayWeek = NoteDay.week(
            ending: monday.noteDay(for: india(2026, 10, 12, 9, 0), calendar: calendar), calendar: calendar
        )
        #expect(mondayWeek == day(10, 6) ... day(10, 12))
    }

    @Test func beforeTheNoteTimeTheNoteDayIsLastWeeks() {
        #expect(NoteDay.default.noteDay(for: india(2026, 10, 11, 12, 0), calendar: calendar) == day(10, 4))
        #expect(NoteDay.default.noteDay(for: india(2026, 10, 12, 9, 0), calendar: calendar) == day(10, 11))
    }

    @Test func aNoteCountsAsSentFromTheDayAfterTheLastNoteDaysEnd() {
        // Sunday 11 October's note: last Sunday's ran to the end of Monday 5, so from Tuesday 6 a send is this week's.
        #expect(NoteDay.sendsFrom(day(10, 11)) == day(10, 6))
        #expect(NoteDay.sendsFrom(day(10, 12)) == day(10, 7))
    }

    @Test func aBatchWithNoNoteDaySetReadsSundayAtSix() {
        #expect(evening.noteDay == nil)
        #expect(evening.effectiveNoteDay == .default)
    }
}

struct NextStepTests: ParentFixtures {
    @Test func thePlanChoosesByStatus() {
        #expect(NextStep.planned(.notOnTrack) == .tellParent)
        #expect(NextStep.planned(.watch) == .teachAgain)
        #expect(NextStep.planned(.onTrack) == .leave && NextStep.planned(.notKnown) == .leave)
    }

    @Test func theTutorsChoiceHoldsOverThePlans() {
        var student = dev
        student.trackStatus = .notOnTrack
        #expect(student.effectiveStep == .tellParent)
        student.nextStep = .stepBack
        #expect(student.effectiveStep == .stepBack)
    }

    @Test func theRowsReadAsTheBoard() {
        let skill = "Balancing equations", before = "Counting atoms in a formula"
        #expect(NextStep.tellParent.title == "Tell the parent, then teach again")
        #expect(NextStep.allCases.map(\.title) == [
            "Tell the parent, then teach again", "Teach again with the worked example",
            "Step back to what comes before",
            "Add it to the checks", "Leave it for now",
        ])
        #expect(NextStep.tellParent.meaning(language: .hindi, skill: skill, before: before)
            == "A message in Hindi; the worked example in the next class")
        #expect(NextStep.teachAgain.meaning(language: .hindi, skill: skill, before: nil)
            == "Balancing equations in the next class, a set after")
        #expect(NextStep.stepBack.meaning(language: .hindi, skill: skill, before: before)
            == "Counting atoms in a formula, then balancing equations")
        #expect(NextStep.addToChecks.meaning(language: .hindi, skill: nil, before: nil)
            == "Three questions on it, spaced over the next weeks")
        #expect(NextStep.leave
            .meaning(language: .hindi, skill: nil, before: nil) == "The plan carries on; the status stays")
        #expect(NextStep.tellParent.nextLine(skill: skill, before: nil)
            == "Tell the parent, then teach again with the worked example.")
        #expect(NextStep.stepBack.nextLine(skill: skill, before: before)
            == "Step back to Counting atoms in a formula, then Balancing equations.")
    }

    @Test func aStudentCachedBeforePhase14ReadsWithNoStep() throws {
        let data = try JSONEncoder().encode(dev)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "nextStep")
        let old = try JSONDecoder().decode(Student.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(old.nextStep == nil)
    }
}

struct MessageSignatureTests: ParentFixtures {
    @Test func theSignatureIsTheTutorTheCentreAndMadeWith() {
        #expect(MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
            == "\n\nMeera Nair\nBright Minds Tuition\nMade with Tutor Central")
        #expect(MessageSignature.text(tutorName: nil, centreName: "Bright Minds Tuition")
            == "\n\nBright Minds Tuition\nMade with Tutor Central")
        #expect(MessageSignature.signed("Hello.", tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
            == "Hello.\n\nMeera Nair\nBright Minds Tuition\nMade with Tutor Central")
    }

    @Test func eachMessageTheAppWritesEndsWithIt() {
        let signature = MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        var receipt = feeMessage
        receipt = FeeMessage(
            kind: .receipt(method: .upi, day: day(10, 7)), parentName: receipt.parentName,
            studentName: receipt.studentName, month: receipt.month, amount: receipt.amount, upiID: nil,
            paymentLink: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
        let messages = [
            feeMessage.text,
            receipt.text,
            AbsenceMessage(
                parentName: "Asha Das", studentName: "Nikhil Das", className: "Evening batch", day: day(10, 7),
                today: day(10, 7), tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
            ).text,
            ConsentMessage.text(
                parentFirstName: "Ramesh", childFirstName: "Dev", gender: .male, tutorName: "Meera Nair",
                centreName: "Bright Minds Tuition"
            ),
            ForwardAskMessage.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition"),
            testTomorrow.text,
        ]
        for message in messages {
            #expect(message.hasSuffix(signature), "\(message.suffix(60))")
            #expect(message.components(separatedBy: MessageSignature.madeWith).count == 2)
        }
    }
}

struct ExamWindowTests: ParentFixtures {
    @Test func anExamsOwnWindowReplacesTheFourteen() {
        var item = exam16
        #expect(ExamPreparation.window(item) == 14)
        item.windowDays = 7
        #expect(ExamPreparation.window(item) == 7)
        #expect(!ExamPreparation.isWithinWindow(item, today: day(10, 7), calendar: calendar))
        #expect(ExamPreparation.isWithinWindow(item, today: day(10, 9), calendar: calendar))
    }

    @Test func theWindowCountsDaysInTheCalendarItIsGiven() {
        #expect(ExamPreparation.isWithinWindow(exam16, today: day(10, 2), calendar: calendar))
        #expect(!ExamPreparation.isWithinWindow(exam16, today: day(10, 1), calendar: calendar))
        #expect(ExamPreparation.isWithinWindow(exam16, today: day(10, 16), calendar: calendar))
        #expect(!ExamPreparation.isWithinWindow(exam16, today: day(10, 17), calendar: calendar))
    }

    @Test func theSplitAndTheNearestExamReadTheExamsWindow() {
        var item = exam16
        item.windowDays = 21
        item.receivedAt = india(2026, 9, 20)
        #expect(ExamPreparation.start(of: item, today: day(10, 7), calendar: calendar) == day(9, 25))
        #expect(SchoolItemRules.nearestExam(
            for: dev, items: [item], students: [dev], today: day(9, 26), calendar: calendar
        )?.id == item.id)
    }

    @Test func anItemCachedBeforePhase14ReadsWithNoWindow() throws {
        let data = try JSONEncoder().encode(exam16)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "windowDays")
        let old = try JSONDecoder().decode(SchoolItem.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(old.windowDays == nil && ExamPreparation.window(old) == 14)
    }
}
