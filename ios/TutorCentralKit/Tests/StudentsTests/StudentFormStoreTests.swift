import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct StudentFormStoreTests {
    let today = Day(year: 2026, month: 10, day: 7)!
    let classes = FakeClassesRepository.seed

    @Test func aNewFormStartsEmptyWithSaveDisabled() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        #expect(form.title == "New student" && form.classLabel == "No class" && form.feePlaceholder == "0" && !form
            .canSave)
        #expect(form.feeHelper == "Pick a class to use its fee, or type one here." && form.notesCount == 0)
        form.name = "Riya Sharma"
        #expect(form.canSave && form.draft.trimmedName == "Riya Sharma" && form.draft.fee == nil)
    }

    /// P7-NewStudent-ClassMade: a class made from the form's menu joins the menu, is chosen, and its fee is used.
    @Test func aClassMadeFromTheFormIsChosen() {
        let form = StudentFormStore(mode: .new, classes: [], today: today)
        form.memberCounts = [FakeClassesRepository.maths.id: 6]
        let physics = Classroom(
            id: UUID(), name: "Class 12 Physics", subject: "Physics", monthlyFee: Money(rupees: 1500), meetingDays: [],
            startTime: nil, endTime: nil, archivedAt: nil
        )
        form.classAdded(physics)
        #expect(form.classes == [physics] && form.classID == physics.id && form.classLabel == "Class 12 Physics")
        #expect(form.feeHelper == "Using the class fee, ₹1,500. Type an amount to set one for this student.")
        #expect(form.membersLine(physics.id) == "No students yet")
        #expect(form.membersLine(FakeClassesRepository.maths.id) == "6 students")
    }

    @Test func anUntouchedFeeFollowsTheClassATypedOneStays() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.select(classID: FakeClassesRepository.maths.id)
        #expect(form.feePlaceholder == "1,200" && form.feeText == "" && form.draft.fee == nil)
        #expect(form.feeHelper == "Using the class fee, ₹1,200. Type an amount to set one for this student.")
        form.feeText = "1,500"
        #expect(form.draft.fee == Money(rupees: 1500) && form
            .feeHelper == "The class fee is ₹1,200. This student pays this amount instead.")
        form.select(classID: FakeClassesRepository.science.id)
        #expect(
            form.feeText == "1,500" && form.draft.fee == Money(rupees: 1500),
            "a typed fee stays when the class changes"
        )
        form.select(classID: nil)
        #expect(form.feeHelper == "This student's own fee.")
    }

    @Test func clearingTheFeeReturnsToTheClassFee() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.select(classID: FakeClassesRepository.maths.id)
        form.feeText = "1,500"
        form.feeText = ""
        #expect(form.draft.fee == nil && form.feePlaceholder == "1,200")
        form.feeText = "12a"
        #expect(form.feeError == "Type a whole number of rupees." && !form.canSave)
        form.feeText = "1,00,001"
        #expect(form.feeError == "That's more than ₹1,00,000. Check the amount." && !form.canSave)
    }

    @Test func thePhoneIsCheckedOnCommitAndClearedOnTyping() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.digits = "981112223"
        form.commitPhone()
        #expect(form.phoneError == "Needs 10 digits after +91." && !form.canSave)
        form.digits = "9811122233"
        #expect(form.phoneError == nil && form.canSave && form.draft.parentPhone?.e164 == "+919811122233")
    }

    @Test func birthDateAndGenderAreOptionalToggles() throws {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        #expect(form.draft.dateOfBirth == nil && form.draft.gender == nil)
        form.hasBirthDate = true
        form.birthDate = try #require(Day(year: 2011, month: 3, day: 14))
        form.toggle(.female)
        #expect(form.draft.dateOfBirth == Day(year: 2011, month: 3, day: 14) && form.draft.gender == .female)
        form.toggle(.female)
        #expect(form.draft.gender == nil)
        form.birthDate = try #require(Day(year: 2026, month: 10, day: 8))
        #expect(form.birthDateError == "Check the date of birth." && !form.canSave)
        form.hasBirthDate = false
        #expect(form.draft.dateOfBirth == nil && form.canSave)
    }

    @Test func editingStartsFromTheStudentAndSavesOnlyWhenSomethingChanged() {
        let akshita = FakeStudentsRepository.seed[0]
        let form = StudentFormStore(mode: .edit(akshita), classes: classes, today: today)
        #expect(form.title == "Edit student" && form.name == "Akshita Rao" && form.classLabel == "Class 10 Maths")
        #expect(form.feeText == "" && form.feePlaceholder == "1,200" && form.digits == "9799113211" && form
            .parentName == "Priya Rao")
        #expect(!form.isChanged && !form.canSave)
        form.notes = "Board exam in March."
        #expect(form.isChanged && form.canSave && form.notesCount == 20)
        form.notes = ""
        #expect(!form.canSave)
        let riya = FakeStudentsRepository.seed[8]
        #expect(StudentFormStore(mode: .edit(riya), classes: classes, today: today).feeText == "1,500")
        #expect(StudentFormStore.text(Money(rupees: 100_000)) == "1,00,000")
    }

    @Test func limitsAreSaidUnderTheirFields() {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = String(repeating: "a", count: 81)
        #expect(form.nameError == "Keep the name under 80 characters.")
        form.name = "Riya"
        form.notes = String(repeating: "n", count: 2001)
        #expect(form.notesError == "Keep the notes under 2,000 characters." && !form.canSave)
    }

    @Test func fixingAScannedRowStartsFromItAndSaysWhatWasRead() throws {
        let today = try #require(Day(year: 2026, month: 10, day: 7))
        var kavya = StudentDraft()
        kavya.name = "Kavya Nair"
        kavya.fee = Money(rupees: 1200)
        kavya.classID = FakeClassesRepository.maths.id
        let store = StudentFormStore(mode: .fix(kavya), classes: FakeClassesRepository.seed, today: today)
        #expect(store.title == "Fix this row" && store.name == "Kavya Nair" && store.feeText == "1,200")
        #expect(store.feeHelper == "Read from the page. The class fee is ₹1,200 too.")
        #expect(store.phoneHelper == "Nothing was read for the number. Type it, or leave it empty and add it later.")
        #expect(store.canSave, "the row as read can be kept as it is")
        store.digits = "98765 00000"
        #expect(store.phoneHelper == nil && store.draft.parentDigits == "98765 00000")
        let blank = StudentFormStore(mode: .fix(StudentDraft()), classes: FakeClassesRepository.seed, today: today)
        #expect(!blank.canSave, "a row needs a name")
    }
}
