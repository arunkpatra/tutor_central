import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeStudentsRepositoryTests {
    @Test func theSeedIsTheTenOfSeedSQL() async throws {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let all = try await fake.students(centre: UUID(), period: Period(year: 2026, month: 10))
        #expect(all.count == 10 && all.map(\.name).sorted().first == "Akshita Rao")
        #expect(all.filter { $0.thisMonth?.status == .paid }.count == 6 && all.filter { $0.thisMonth?.status == .due }
            .count == 4)
        #expect(all.first { $0.name == "Sahil Verma" }?.classID == nil && all.first { $0.name == "Riya Sharma" }?
            .monthlyFee == Money(rupees: 1500))
        #expect(FakeStudentsRepository.few.count == 3 && FakeStudentsRepository.few
            .allSatisfy { $0.classID == nil && $0.thisMonth == nil })
    }

    @Test func writesChangeTheListAndAreRecorded() async throws {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.few)
        var draft = StudentDraft()
        draft.name = "Akshita Rao"
        draft.parentDigits = "9799113211"
        let made = try await fake.create(draft, centre: UUID())
        #expect(made.name == "Akshita Rao" && made.parentPhone?.e164 == "+919799113211" && fake.students
            .count == 4 && fake.created == [draft])
        draft.name = "Akshita R"
        let changed = try await fake.update(id: made.id, with: draft)
        #expect(changed.name == "Akshita R" && fake.students.first { $0.id == made.id }?.name == "Akshita R")
        try await fake.setArchived(id: made.id, true)
        #expect(fake.students.first { $0.id == made.id }?.isArchived == true)
        try await fake.assign(studentIDs: [made.id], toClass: FakeClassesRepository.maths.id, centre: UUID())
        #expect(fake.students.first { $0.id == made.id }?.classID == FakeClassesRepository.maths.id)
        try await fake.delete(id: made.id)
        #expect(fake.students.count == 3 && fake.deleted == [made.id])
    }

    @Test func aScriptedErrorFiresOnce() async {
        let fake = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        fake.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await fake.setArchived(id: FakeStudentsRepository.akshita, true) }
        await #expect(throws: Never.self) { try await fake.setArchived(id: FakeStudentsRepository.akshita, true) }
    }
}
