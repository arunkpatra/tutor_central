import Testing
@testable import Domain

struct ClassroomDraftTests {
    @Test func aNameIsEnough() {
        var draft = ClassroomDraft()
        #expect(draft.problems == [.nameMissing] && !draft.isValid)
        draft.name = "  Class 9 English "
        #expect(draft.isValid && draft.trimmedName == "Class 9 English" && draft.trimmedSubject == nil)
        draft.subject = " English "
        #expect(draft.trimmedSubject == "English")
    }

    @Test func limitsAndTimesInWords() {
        var draft = ClassroomDraft()
        draft.name = String(repeating: "x", count: 81)
        #expect(draft.problems.contains(.nameTooLong) && ClassroomDraft.Problem.nameTooLong
            .message == "Keep the name under 80 characters.")
        draft.name = "Class 12 Physics"
        draft.fee = Money(rupees: 100_001)
        #expect(draft.problems == [.feeTooHigh] && ClassroomDraft.Problem.feeTooHigh
            .message == "That's more than ₹1,00,000. Check the amount.")
        draft.fee = Money(rupees: 1500)
        draft.startTime = TimeOfDay(hour: 18, minute: 0)
        draft.endTime = TimeOfDay(hour: 18, minute: 0)
        #expect(draft.problems == [.endNotAfterStart] && ClassroomDraft.Problem.endNotAfterStart
            .message == "The class has to end after it starts.")
        draft.endTime = TimeOfDay(hour: 19, minute: 30)
        #expect(draft.isValid)
        draft.startTime = nil
        #expect(draft.isValid, "one time alone is allowed")
    }

    @Test func fromAClassAndBack() {
        let draft = ClassroomDraft(ClassroomTests.maths)
        #expect(draft.name == "Class 10 Maths" && draft.subject == "Mathematics" && draft.fee == Money(rupees: 1200))
        #expect(draft.meetingDays == [.monday, .wednesday, .friday] && draft.startTime?.text == "17:00" && draft
            .endTime?.text == "18:00")
    }
}
