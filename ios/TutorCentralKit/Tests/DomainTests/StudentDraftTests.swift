import Foundation
import Testing
@testable import Domain

struct StudentDraftTests {
    let today = Day(year: 2026, month: 10, day: 7)!

    @Test func aNameIsEnoughAndEverythingElseIsOptional() {
        var draft = StudentDraft()
        #expect(draft.problems(today: today) == [.nameMissing] && StudentDraft.Problem.nameMissing
            .message == "The student needs a name.")
        draft.name = " Riya Sharma "
        #expect(draft.isValid(today: today) && draft.trimmedName == "Riya Sharma")
        #expect(draft.trimmedParentName == nil && draft.trimmedNotes == nil && draft.parentPhone == nil)
    }

    @Test func thePhoneGoesThroughPhoneNumberOrIsRefusedInWords() {
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        draft.parentDigits = "98111 2223"
        #expect(draft.problems(today: today) == [.phoneInvalid] && StudentDraft.Problem.phoneInvalid
            .message == "Needs 10 digits after +91.")
        draft.parentDigits = "098111 22233"
        #expect(draft.isValid(today: today) && draft.parentPhone?.e164 == "+919811122233")
    }

    @Test func limitsInWords() {
        var draft = StudentDraft()
        draft.name = String(repeating: "a", count: 81)
        draft.parentName = String(repeating: "b", count: 81)
        draft.notes = String(repeating: "c", count: 2001)
        draft.fee = Money(rupees: 100_001)
        draft.dateOfBirth = Day(year: 2026, month: 10, day: 8)
        #expect(draft.problems(today: today) == [
            .nameTooLong,
            .parentNameTooLong,
            .notesTooLong,
            .feeTooHigh,
            .birthDateOut,
        ])
        #expect(StudentDraft.Problem.notesTooLong.message == "Keep the notes under 2,000 characters.")
        #expect(StudentDraft.Problem.birthDateOut.message == "Check the date of birth.")
        draft.dateOfBirth = Day(year: 1949, month: 12, day: 31)
        #expect(draft.problems(today: today).contains(.birthDateOut))
        draft.dateOfBirth = Day(year: 2011, month: 3, day: 14)
        #expect(!draft.problems(today: today).contains(.birthDateOut))
    }

    @Test func fromAStudentAndBack() {
        var student = StudentTests.student("Akshita Rao", classID: ClassroomTests.maths.id)
        student.gender = .female
        student.notes = "Board exam in March."
        let draft = StudentDraft(student)
        #expect(draft.name == "Akshita Rao" && draft.classID == ClassroomTests.maths.id && draft.fee == nil)
        #expect(draft.parentName == "Parent" && draft.parentDigits == "9799113211" && draft.gender == .female && draft
            .notes == "Board exam in March.")
    }
}
