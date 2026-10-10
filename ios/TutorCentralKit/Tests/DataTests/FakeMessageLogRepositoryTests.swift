import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeMessageLogRepositoryTests {
    @Test func aConsentAskIsLoggedAndEveryMessageAboutAStudentIsListedNewestFirst() async throws {
        let repo = FakeMessageLogRepository(
            logs: FakeMessageLogRepository.seed,
            feeLogs: FakeMessageLogRepository.feeSeed
        )
        let riya = FakeStudentsRepository.riya
        let asked = try await repo.logConsent(centre: FakeSchoolsRepository.centre, studentID: riya)
        #expect(asked == FakeCountsRepository.fixedNow && repo.consentLogs == [riya])
        #expect(try await repo.messages(centre: FakeSchoolsRepository.centre, student: riya).map(\.kind) == [.consent])
        let hemanth = try await repo.messages(
            centre: FakeSchoolsRepository.centre,
            student: FakeStudentsRepository.hemanth
        )
        #expect(hemanth.first?.kind == .absence)
        let dev = try await repo.messages(centre: FakeSchoolsRepository.centre, student: FakeStudentsRepository.id(4))
        #expect(dev.map(\.kind) == [.reminder])
    }
}
