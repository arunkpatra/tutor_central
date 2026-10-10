import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeRecordRepositoryTests {
    let centre = FakeSchoolsRepository.centre

    @Test func theFakeRecordsAPlacementAndAStatusChange() async throws {
        let repo = FakeRecordRepository()
        let first = try #require(FakeRecordRepository.seedHomework.first)
        try await repo.setHomeworkStatus(id: first.id, .done)
        let hemanth = FakeStudentsRepository.hemanth
        let homework = try await repo.homework(centre: centre, students: [hemanth], since: .distantPast)
        #expect(homework.first { $0.id == first.id }?.status == .done)
        #expect(repo.statusChanges.count == 1)
        let placement = PlacementRecord(studentID: FakeStudentsRepository.riya, checks: [], states: [], track: nil)
        try await repo.recordPlacement(placement, centre: centre)
        #expect(repo.placements == [placement])
    }

    @Test func theSeedIsHemanthsSessionsOfThreeChecks() async throws {
        let repo = FakeRecordRepository()
        let checks = try await repo.checks(
            centre: centre,
            students: [FakeStudentsRepository.hemanth],
            since: .distantPast
        )
        let sessions = Dictionary(grouping: checks) { $0.sessionID }
        #expect(sessions.values.allSatisfy { $0.count == 3 } && checks == checks.sorted { $0.at < $1.at })
        let homework = try await repo.homework(
            centre: centre,
            students: [FakeStudentsRepository.hemanth],
            since: .distantPast
        )
        #expect(homework.first?.status == .given && homework == homework.sorted { $0.givenAt > $1.givenAt })
        #expect(try await repo.checks(centre: centre, students: [FakeStudentsRepository.riya], since: .distantPast)
            .isEmpty)
    }
}
