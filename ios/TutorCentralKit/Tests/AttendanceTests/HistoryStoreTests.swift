import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct HistoryStoreTests {
    func make(_ sessions: [AttendanceSession] = FakeAttendanceRepository.seedWithToday) async -> HistoryStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = HistoryStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            register: register,
            attendance: FakeAttendanceRepository(sessions: sessions),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func octoberByDateAsTheBoardDrawsIt() async throws {
        let store = await make()
        #expect(store.monthTitle == "October 2026" && store.view == .byDate)
        let summary = try #require(store.summary)
        #expect(summary.title == "5 classes marked" && summary.percent == "79%" && summary.count == "19 of 24 present")
        #expect(store.dateRows.map(\.date) == ["7 Oct", "6 Oct", "5 Oct", "2 Oct", "1 Oct"] && store.dateRows.map(\.day)
            .first == "Wed")
        #expect(store.dateRows[0].title == "Class 10 Maths" && store.dateRows[0].line == "5 of 6 present" && store
            .dateRows[0].absent == "1 absent")
    }

    @Test func byStudentWithPercentagesAndLowestFirst() async {
        let store = await make()
        store.view = .byStudent
        #expect(store.studentRows.map(\.student.name).prefix(2) == ["Akshita Rao", "Ananya Iyer"] && store.studentRows
            .count == 9)
        let hemanth = store.studentRows.first { $0.student.id == FakeAttendanceRepository.hemanth }
        #expect(
            hemanth?.percent == "33%" && hemanth?.count == "1 of 3",
            "absent on the 5th and the 7th (P4-History-ByStudent)"
        )
        store.sortLowestFirst = true
        #expect(store.studentRows.first?.student.name == "Nikhil Das" && store.studentRows.first?.percent == "0%")
    }

    @Test func theMonthsMoveAndAnEmptyMonthSaysSo() async {
        let store = await make()
        await store.previousMonth()
        #expect(store.monthTitle == "September 2026" && store.summary?.title == "15 classes marked")
        await store.nextMonth()
        await store.nextMonth()
        #expect(store.monthTitle == "November 2026" && store.summary == nil && store.dateRows.isEmpty && store
            .studentRows.isEmpty)
    }
}
