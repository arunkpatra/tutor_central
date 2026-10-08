import Foundation
import Testing
@testable import Domain

struct AttendanceStatsTests {
    let hemanth = UUID()
    let akshita = UUID()
    func session(_ day: Int, month: Int = 10, _ marks: [UUID: AttendanceStatus]) -> AttendanceSession {
        AttendanceSession(
            id: UUID(),
            classID: nil,
            date: Day(year: 2026, month: month, day: day)!,
            savedAt: Date(),
            marks: marks
        )
    }

    @Test func aStudentsMonthIsPresentOverMarked() {
        let sessions = [
            session(2, [hemanth: .present, akshita: .present]),
            session(5, [hemanth: .absent, akshita: .present]),
            session(7, [hemanth: .present, akshita: .present]),
        ]
        let count = AttendanceStats.forStudent(hemanth, in: sessions)
        #expect(count.present == 2 && count.total == 3 && count.percent == 67)
        #expect(AttendanceStats.absences(of: hemanth, in: sessions).map(\.date.day) == [5], "newest first")
    }

    @Test func noMarksIsNotZeroPercent() {
        let count = AttendanceStats.forStudent(hemanth, in: [session(2, [akshita: .present])])
        #expect(count.total == 0 && count.percent == nil && count.fraction == 0)
    }

    @Test func theMonthSummaryCountsMarks() {
        let sessions = [
            session(2, [hemanth: .present, akshita: .absent]),
            session(5, [hemanth: .absent, akshita: .present]),
            session(28, month: 9, [hemanth: .present]),
        ]
        let october = AttendanceStats.sessions(sessions, in: Period(year: 2026, month: 10))
        #expect(october.count == 2)
        let summary = AttendanceStats.forMonth(october)
        #expect(summary.present == 2 && summary.total == 4 && summary.percent == 50)
    }

    @Test func percentRoundsHalfUp() {
        #expect(AttendanceStats.Count(present: 19, total: 24).percent == 79)
        #expect(AttendanceStats.Count(present: 1, total: 8).percent == 13)
    }
}
