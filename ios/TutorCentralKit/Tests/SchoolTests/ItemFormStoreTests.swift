import Data
import Domain
import Foundation
import School
import Testing

@MainActor struct ItemFormStoreTests {
    let vidya = FakeSchoolsRepository.vidya

    func makeForm(_ draft: SchoolItemDraft? = nil) async -> ItemFormStore {
        let register = await SchoolFixtures.register()
        return ItemFormStore(
            draft: draft, students: register.activeStudents, schools: [vidya], today: Day(
                year: 2026,
                month: 10,
                day: 7
            )!
        )
    }

    @Test func saveNeedsAKindATitleWhoAndADateAndAnExamASubject() async {
        let form = await makeForm()
        #expect(!form.canSave)
        form.title = "Unit test"
        form.audience = .schoolClass(school: vidya.id, level: .eight)
        form.date = Day(year: 2026, month: 10, day: 16)
        form.kind = .exam
        #expect(!form.canSave)
        form.subject = "Science"
        #expect(form.canSave && form.draft().ticked && form.draft().isComplete)
        form.kind = .notice
        form.subject = nil
        #expect(form.canSave)
    }

    @Test func theCounterCountsScalarsOf500() async {
        let form = await makeForm()
        form.portions = "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts"
        #expect(form.counter == "53 of 500")
        form.portions = String(repeating: "क", count: 501)
        #expect(form.counter == "501 of 500" && !form.canSave)
    }

    @Test func aHolidayTakesAnEndDateNotBeforeItsDate() async {
        let form = await makeForm()
        form.kind = .holiday
        form.title = "Dasara holidays"
        form.audience = .school(vidya.id)
        form.date = Day(year: 2026, month: 10, day: 19)
        form.endDate = Day(year: 2026, month: 10, day: 18)
        #expect(!form.canSave)
        form.endDate = Day(year: 2026, month: 10, day: 21)
        #expect(form.canSave && form.draft().endDate?.day == 21)
        form.kind = .exam
        form.subject = "Science"
        #expect(form.draft().endDate == nil)
    }

    @Test func theForSheetListsEachSchoolsClassesWithCountsEveryClassAndTheStudents() async {
        let form = await makeForm()
        let options = form.forOptions
        let classes = options.filter {
            if case .schoolClass = $0.audience {
                true
            } else {
                false
            }
        }
        #expect(classes.map(\.title) == ["Class 5", "Class 8", "Class 10"])
        #expect(classes.first { $0.title == "Class 8" }?.line == "Dev, Meher and Nikhil")
        #expect(options.contains { $0.audience == .school(vidya.id) && $0.title == "Every class" })
        #expect(options.contains { $0.audience == .student(FakeStudentsRepository.sahil) })
        form.audience = .schoolClass(school: vidya.id, level: .eight)
        #expect(form.forValue == "Class 8 at Vidya Niketan")
        #expect(form.forNote == "Dev, Meher and Nikhil are in class 8 there. Or one student.")
    }

    /// Hand run 7: the calendar opened on today with nothing chosen, and tapping today set nothing.
    @Test func openingADayPickerChoosesTheDayItShows() async {
        let form = await makeForm()
        form.openDay()
        #expect(form.date == Day(year: 2026, month: 10, day: 7))
        form.date = Day(year: 2026, month: 10, day: 19)
        form.openEndDay()
        #expect(form.endDate == Day(year: 2026, month: 10, day: 19))
        form.date = Day(year: 2026, month: 10, day: 20)
        form.openDay()
        form.openEndDay()
        #expect(form.date == Day(year: 2026, month: 10, day: 20) && form.endDate == Day(year: 2026, month: 10, day: 19))
    }

    @Test func aKeptExamsPreparationIsFourteenUnlessChosenAndTheItemCarriesIt() async throws {
        let register = await SchoolFixtures.register()
        let exam = try #require(SchoolFixtures.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 })
        let form = try ItemFormStore(
            item: exam, students: register.activeStudents, schools: [vidya], today: #require(Day(
                year: 2026,
                month: 10,
                day: 7
            ))
        )
        #expect(form.showsWindow && form.windowTitle == "14 days before" && form.windowChoices == [7, 10, 14, 21])
        form.windowDays = 7
        #expect(form.windowTitle == "7 days before" && form.item(from: exam).windowDays == 7)
        form.windowDays = 14
        #expect(form.item(from: exam).windowDays == nil)
        form.kind = .homework
        #expect(!form.showsWindow && form.item(from: exam).windowDays == nil)
        let draft = await makeForm()
        #expect(!draft.showsWindow)
    }
}
