import Data
import Domain
import Foundation
import Testing
@testable import Students

/// The Marks section (U36; P13-Student-Marks, -Empty): mocks and checked papers newest first, the school and the day,
/// the score, Below usual; the empty row; no add from a photo yet.
@MainActor struct MarksSectionTests {
    let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()

    func detail(_ id: UUID, marks: [MarkRecord]) async -> StudentDetailStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }, schools: FakeSchoolsRepository()
        )
        await register.load()
        let store = StudentDetailStore(
            id: id, register: register, attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
            messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            textbooks: FakeTextbooksRepository.seeded(),
            record: FakeRecordRepository(marks: marks), now: { [now] in now }
        )
        await store.load()
        return store
    }

    @Test func theMarksListNewestFirstWithTheSchoolAndTheScore() async {
        let store = await detail(FakeStudentsRepository.hemanth, marks: FakeRecordRepository.hemanthsMarks)
        #expect(store.markRows.map(\.title) == [
            "Maths unit test 3 · mock · Mathematics", "Unit test 2 · Mathematics", "Unit test 1 · Mathematics",
            "Class test · Mathematics",
        ])
        let second = store.markRows[1]
        #expect(second.line == "Vidya Niketan · 28 Sep" && second.score == "14 of 25")
    }

    @Test func aMarkBelowUsualWearsTheChip() async {
        let store = await detail(FakeStudentsRepository.hemanth, marks: FakeRecordRepository.hemanthsMarks)
        #expect(store.markRows.map(\.belowUsual) == [false, true, false, false])
    }

    @Test func aStudentWithNoMarksSeesTheEmptyRow() async {
        let store = await detail(FakeStudentsRepository.riya, marks: FakeRecordRepository.hemanthsMarks)
        #expect(store.markRows.isEmpty && store.marksLoaded)
        #expect(StudentDetailStore.noMarks == ("No marks yet", "Marks from mocks and checked papers appear here."))
    }

    @Test func aMockMarkNamesTheMock() async {
        let store = await detail(FakeStudentsRepository.hemanth, marks: FakeRecordRepository.hemanthsMarks)
        #expect(store.markRows.first?.title == "Maths unit test 3 · mock · Mathematics")
        #expect(store.markRows.first?.score == "26 of 40")
    }
}
