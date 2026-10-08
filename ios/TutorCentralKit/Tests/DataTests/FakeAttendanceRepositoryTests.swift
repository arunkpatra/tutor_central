import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeAttendanceRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    @Test func theSeedFollowsTheSeedRule() async throws {
        let repo = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let october = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.map(\.date.day) == [6, 5, 2, 1], "newest first; nothing on the 7th before a save")
        let fifth = try #require(october.first { $0.date.day == 5 })
        #expect(fifth.classID == FakeClassesRepository.maths.id && fifth.presentCount == 5 && fifth
            .absentStudentIDs == [FakeAttendanceRepository.hemanth])
        let september = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 9))
        #expect(september.count == 15)
        let withToday = try await FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday).sessions(
            centre: centre,
            month: Period(year: 2026, month: 10)
        )
        #expect(withToday.first?.date.day == 7 && withToday.first?
            .absentStudentIDs == [FakeAttendanceRepository.hemanth])
    }

    @Test func savingMakesOrReplacesASession() async throws {
        let repo = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let akshita = FakeStudentsRepository.akshita
        let saved = try await repo.save(
            centre: centre,
            classID: FakeClassesRepository.maths.id,
            date: day,
            marks: [akshita: .absent]
        )
        #expect(saved.date == day && saved.marks == [akshita: .absent] && repo.saves.count == 1)
        let again = try await repo.save(
            centre: centre,
            classID: FakeClassesRepository.maths.id,
            date: day,
            marks: [akshita: .present]
        )
        #expect(again.id == saved.id && again.marks == [akshita: .present] && again.savedAt >= saved.savedAt)
        let october = try await repo.sessions(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.filter { $0.date == day }.count == 1)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await repo.save(centre: centre, classID: nil, date: day, marks: [:])
        }
    }

    @Test func theMessageLogRemembersWhoWasTold() async throws {
        let log = FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)
        let october = try await log.absences(centre: centre, month: Period(year: 2026, month: 10))
        #expect(october.map(\.studentID) == [FakeAttendanceRepository.hemanth])
        let made = try await log.logAbsence(
            centre: centre, studentID: FakeStudentsRepository.akshita, about: #require(Day(
                year: 2026,
                month: 10,
                day: 7
            ))
        )
        #expect(made.studentID == FakeStudentsRepository.akshita && log.logged == [FakeStudentsRepository.akshita])
        #expect(try await log.absences(centre: centre, month: Period(year: 2026, month: 10)).count == 2)
    }
}
