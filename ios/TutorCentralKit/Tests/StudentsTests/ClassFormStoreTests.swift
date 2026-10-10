import Data
import Domain
import Testing
@testable import Students

@MainActor struct ClassFormStoreTests {
    @Test func aNewClassNeedsOnlyAName() {
        let form = ClassFormStore(mode: .new)
        #expect(form.title == "New batch" && !form.canSave && form.summary == "No days set" && form
            .feeHelper == "Students you add to this batch start at this fee.")
        form.name = "Class 12 Physics"
        #expect(form.canSave && form.draft.trimmedName == "Class 12 Physics" && form.draft.meetingDays.isEmpty)
    }

    @Test func daysTimesAndTheSummary() {
        let form = ClassFormStore(mode: .new)
        form.name = "Class 12 Physics"
        form.daySelection = [2, 4, 6]
        #expect(form.days == [.tuesday, .thursday, .saturday] && form.summary == "Tue, Thu, Sat")
        form.setStart(TimeOfDay(hour: 18, minute: 0))
        #expect(form.endTime == TimeOfDay(hour: 19, minute: 0), "the end defaults to an hour after the start")
        form.setEnd(TimeOfDay(hour: 19, minute: 30))
        #expect(form.summary == "Tue, Thu, Sat · 18:00–19:30" && form.canSave)
        form.setEnd(TimeOfDay(hour: 17, minute: 0))
        #expect(form.timeError == "The class has to end after it starts." && !form.canSave)
        form.setStart(nil)
        #expect(form.timeError == nil && form.canSave && form.endTime == nil, "clearing the start clears the end")
        form.everyDay = true
        #expect(form.days.count == 7 && form.summary == "Every day")
        form.everyDay = false
        #expect(form.days.isEmpty && form.dayItems.map(\.initial) == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func theFeeIsCheckedInWords() {
        let form = ClassFormStore(mode: .new)
        form.name = "Class 12 Physics"
        form.feeText = "15oo"
        #expect(form.feeError == "Type a whole number of rupees." && !form.canSave)
        form.feeText = "1,500"
        #expect(form.feeError == nil && form.draft.fee == Money(rupees: 1500) && form.canSave)
    }

    @Test func editingStartsFromTheClassAndSavesOnlyWhenChanged() {
        let form = ClassFormStore(mode: .edit(FakeClassesRepository.maths))
        #expect(form.title == "Edit batch" && form.name == "Class 10 Maths" && form.subject == "Mathematics" && form
            .feeText == "1,200")
        #expect(form.days == [.monday, .wednesday, .friday] && form.summary == "Mon, Wed, Fri · 17:00–18:00" && !form
            .canSave)
        #expect(form
            .feeHelper == "Changing it changes the fee of every student on the batch fee, from next month's bill.")
        form.daySelection.insert(6)
        #expect(form.isChanged && form.canSave)
    }
}
