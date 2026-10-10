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

    @Test func theV2CallsAnswerTheSamplesAndAreRecorded() async throws {
        let ai = FakeAIRepository()
        let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg")
        let reading = try await ai.parseTextbook(page, classLevel: .five, subject: "Mathematics", centre: UUID())
        #expect(reading.title == "Math-Magic 5" && reading.chapters.count == 5 && reading.chapters[4].position == 5)
        let checks = try await ai.makeChecks(
            classLevel: .eight,
            subject: "Science",
            skills: ["Name the reactants", "X"],
            centre: UUID()
        )
        #expect(checks.map(\.skill) == ["Name the reactants", "X"] && checks[1]
            .question == "Which is bigger, 1/2 or 1/3?")
        let placement = try await ai.makePlacement(
            classLevel: .five,
            subject: "Mathematics",
            chapters: ["The Fish Tale"],
            centre: UUID()
        )
        #expect(placement.map(\.chapter) == ["The Fish Tale"])
        #expect(ai.textbooks == ["Mathematics"] && ai.checkCalls == [["Name the reactants", "X"]])
        #expect(ai.placementCalls == [["The Fish Tale"]])
        ai.scriptBySubject = ["Science": .failure(.service)]
        await #expect(throws: APIFailure.service) {
            try await ai.makeChecks(classLevel: .eight, subject: "Science", skills: ["A"], centre: UUID())
        }
    }

    @MainActor @Test func theFakeAnswersEachKindAndCountsItsCalls() async throws {
        let fake = FakeAIRepository()
        let sheet = try await fake.makeSheet(
            SheetRequest(
                classLevel: .five, subject: "Mathematics", skills: ["Compare simple fractions"], questions: 5,
                forHomework: true
            ), centre: UUID()
        )
        #expect(sheet.content.questions.count == 5)
        #expect(sheet.content.light)
        let figure = try await fake.makeFigure(
            .foodChain,
            classLevel: .seven,
            subject: "Science",
            skill: "x",
            centre: UUID()
        )
        #expect(figure.figure.figure.kind == .foodChain)
        fake.scriptByKind[.brief] = .failure(.service)
        await #expect(throws: APIFailure.service) {
            try await fake.makeBrief(classLevel: .eight, subject: "Science", chapter: "x", centre: UUID())
        }
        #expect(fake.sheets.count == 1 && fake.figures.count == 1 && fake.briefs.count == 1)
    }

    @MainActor @Test func theFakeNamesATopicPerGroup() async throws {
        let fake = FakeAIRepository()
        let topics = try await fake.planTopics(
            classID: nil, date: #require(Day(iso: "2026-10-07")), month: 10,
            groups: [
                PlanTopicGroup(groupNo: 1, classLevel: .eight, subject: "Science"),
                PlanTopicGroup(groupNo: 2, classLevel: .two, subject: "Mathematics"),
            ], centre: UUID()
        )
        #expect(topics.map(\.chapter) == ["Chemical reactions", "Numbers"])
        #expect(fake.topics.count == 1)
    }
}
