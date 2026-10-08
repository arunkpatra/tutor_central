import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeClassesRepositoryTests {
    @Test func theSeedIsTheTwoOfSeedSQLAndWritesAreRecorded() async throws {
        let fake = FakeClassesRepository(classes: FakeClassesRepository.seed)
        let all = try await fake.classes(centre: UUID())
        #expect(all.map(\.name) == ["Class 10 Maths", "Class 8 Science"])
        #expect(all[1].meetingSummary == "Tue, Thu · 16:30–17:30" && all[1].monthlyFee == Money(rupees: 1000))
        var draft = ClassroomDraft()
        draft.name = "Class 12 Physics"
        draft.meetingDays = [.tuesday, .thursday, .saturday]
        let made = try await fake.create(draft, centre: UUID())
        #expect(made.name == "Class 12 Physics" && fake.classes.count == 3 && fake.created == [draft])
        try await fake.archive(id: made.id)
        #expect(fake.classes.first { $0.id == made.id }?.isArchived == true && fake.archived == [made.id])
    }
}
