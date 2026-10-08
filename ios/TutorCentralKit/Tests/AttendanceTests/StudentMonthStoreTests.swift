import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct StudentMonthStoreTests {
    @Test func hemanthsOctober() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = StudentMonthStore(
            studentID: FakeAttendanceRepository.hemanth, workspace: FakeCentreRepository.meeraWorkspace,
            register: register,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday),
            messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        #expect(store.name == "Hemanth Reddy" && store.monthTitle == "October 2026")
        #expect(store.hero.percent == "33%" && store.hero.line == "1 of 3 classes · 2 absences" && store.hero
            .eyebrow == "October 2026")
        #expect(store.absences.map(\.date) == ["7 Oct", "5 Oct"], "newest first; the seed's rule and the saved 7th")
        #expect(store.absences[0].line == "17:00–18:00" && store.absences[0].lineTone == nil)
        #expect(store.absences[1].line == "Parent told on Mon 5 Oct" && store.absences[1].lineTone == .ok)
        #expect(
            store.earlier.first?.title == "September" && store.earlier.first?
                .line == "7 of 9 present · 2 absences",
            "the seed's rule: 9 maths days from 10 September"
        )
        await store.nextMonth()
        #expect(store.hero.percent == nil && store.hero.line == "Nothing marked in November yet")
    }

    @Test func aQuickSecondMonthMoveWins() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let slow = MonthDelayAttendance(
            sessions: FakeAttendanceRepository.seedWithToday,
            slow: Period(year: 2026, month: 8)
        )
        let store = StudentMonthStore(
            studentID: FakeAttendanceRepository.hemanth, workspace: FakeCentreRepository.meeraWorkspace,
            register: register, attendance: slow,
            messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        async let back: Void = store.previousMonth()
        try? await Task.sleep(for: .milliseconds(10))
        await store.nextMonth()
        await back
        #expect(store.monthTitle == "October 2026" && store.hero.percent == "33%")
    }

    @Test func aParentToldTheNextDayStillReadsAsTold() async throws {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let wednesday = try #require(Day(year: 2026, month: 10, day: 7))
        let thursdayMorning = try #require(DayHeading.india.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 8,
            hour: 9
        )))
        let store = StudentMonthStore(
            studentID: FakeAttendanceRepository.hemanth, workspace: FakeCentreRepository.meeraWorkspace,
            register: register, attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday),
            messages: FakeMessageLogRepository(logs: [
                AbsenceLog(
                    studentID: FakeAttendanceRepository.hemanth,
                    openedAt: thursdayMorning,
                    aboutDate: wednesday
                ),
            ]),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        #expect(store.absences.first?.date == "7 Oct" && store.absences.first?.line == "Parent told on Thu 8 Oct")
    }
}
