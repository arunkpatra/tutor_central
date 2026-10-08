import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeAIRepositoryTests {
    static let context = GenerateContext(
        centre: UUID(), className: "Class 10 Maths", subject: "Mathematics", studentName: nil, parentName: nil,
        attendanceLine: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
    )

    @Test func theFakeAnswersTheBoardsAndRecordsTheCall() async throws {
        let fake = FakeAIRepository()
        let form = PaperForm(classID: UUID(), subject: "Mathematics", topic: "Quadratic equations")
        let generation = try await fake.generate(.paper(form), context: Self.context)
        guard case let .paper(paper) = generation.result else {
            Issue.record("not a paper")
            return
        }
        #expect(paper.title == "Quadratic equations" && paper.questionCount == 10 && paper.totalMarks == 20)
        #expect(fake.requests.count == 1)
        let scan = try await fake.scanRegister(ImageUpload(data: Data([1]), mediaType: "image/jpeg"), centre: UUID())
        #expect(scan.rows.map(\.name) == [
            "Aarav Mehta", "Diya Pillai", "Dev Kumar", "Kavya Nair", "Rohan Gupta", "Sneha Joshi", "Ishaan Bose",
            "Tanvi Kulkarni",
        ])
        #expect(scan.rows[3].phone == nil && scan.rows[2].phone == "+919884843831")
        let check = try await fake.checkPaper(
            pages: [],
            scheme: .typed("x"),
            studentName: "Hemanth Reddy",
            centre: UUID()
        )
        #expect(check.result.total == 14 && check.result.outOf == 20 && check.result.questions.count == 10)
        fake.script = .failure(.service)
        await #expect(throws: APIFailure.service) {
            try await fake.generate(.paper(PaperForm()), context: Self.context)
        }
        #expect(FakeAIHistoryRepository.seed.count == 6 && FakeAIHistoryRepository.seed.first?.kind == .paper)
    }
}
