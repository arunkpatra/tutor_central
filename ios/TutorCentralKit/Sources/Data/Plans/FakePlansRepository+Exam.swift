import Domain
import Foundation

public extension FakePlansRepository {
    /// The boards' mock (P10-Mock): Dev's own Science unit test on Thursday 8 October, chapters 1 and 2, in the default
    /// pattern for class 8, made at 16:40 on Wednesday 7 October, kept with the exam and no plan.
    nonisolated static let boardMockID = UUID(uuidString: "abababab-0000-0000-0013-000000000001")!

    nonisolated static var boardMock: Artefact {
        let request = MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test", portions: ["chapters 1 and 2"],
            pattern: .default(for: .eight), schoolItemID: FakeSchoolItemsRepository.devsTest
        )
        let madeAt = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 40))
            ?? Date()
        return Artefact(
            id: boardMockID, kind: .mock, source: .made, title: request.title, content: .mock(AISamples.mock(request)),
            photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: madeAt,
            generationID: UUID(uuidString: "abababab-0000-0000-0013-000000000002"), schoolItemID: request.schoolItemID
        )
    }
}
