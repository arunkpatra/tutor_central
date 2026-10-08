import Domain
import Foundation

/// History in memory for tests, previews and `bun shots`: the six results the boards draw (P6-History), newest first,
/// a scripted error.
@MainActor public final class FakeAIHistoryRepository: AIHistoryRepository {
    public nonisolated static let quadraticID = id(1)

    public nonisolated static let seed: [Generation] = {
        let maths = FakeClassesRepository.maths.id
        let science = FakeClassesRepository.science.id
        let hemanth = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id
        let photosynthesis = QuestionSetResult(
            title: "Photosynthesis",
            instructions: "Answer in one or two lines.",
            questions: [
                .init(
                    number: 1,
                    text: "Name the green pigment in leaves.",
                    answer: "Chlorophyll"
                ),
                .init(
                    number: 2,
                    text: "Which gas do plants take in?",
                    answer: "Carbon dioxide"
                ),
            ]
        )
        let light = PaperResult(title: "Light and reflection", sections: [
            .init(title: "Section A", marksEach: 1, questions: [
                .init(
                    number: 1,
                    text: "State the first law of reflection.",
                    marks: 1,
                    answer: "The angle of incidence equals the angle of reflection."
                ),
            ]),
        ])
        let trigonometry = QuestionSetResult(title: "Trigonometry basics", instructions: nil, questions: [
            .init(number: 1, text: "Find sin 30°.", answer: "1/2"),
            .init(number: 2, text: "Find tan 45°.", answer: "1"),
        ])
        return [
            make(1, .paper, at: time(10, 6, 18, 32), .paper(PaperForm(
                classID: maths, subject: "Mathematics", topic: "Quadratic equations"
            )), .paper(AISamples.paper)),
            make(2, .progressNote, at: time(10, 5, 19, 5), .progressNote(NoteForm(
                studentID: hemanth,
                observations: "Improving in algebra, careless with signs. Homework on time this month. Needs to "
                    + "practise word problems before the mock test on 17 Oct.",
                tone: .warm
            )), .progressNote(AISamples.note)),
            make(3, .worksheet, at: time(10, 3, 11, 40), .worksheet(WorksheetForm(
                classID: science, subject: "Science", topic: "Photosynthesis", level: .easy, questions: 2
            )), .worksheet(photosynthesis)),
            make(4, .homework, at: time(10, 1, 17, 15), .homework(HomeworkForm(
                classID: maths, subject: "Mathematics", topic: "Linear equations in two variables", questions: 12
            )), .homework(AISamples.worksheet)),
            make(5, .paper, at: time(9, 28, 16, 0), .paper(PaperForm(
                classID: science, subject: "Science", topic: "Light and reflection", questions: 1, marks: 5
            )), .paper(light)),
            make(6, .worksheet, at: time(9, 22, 20, 10), .worksheet(WorksheetForm(
                classID: maths, subject: "Mathematics", topic: "Trigonometry basics", questions: 2
            )), .worksheet(trigonometry)),
        ]
    }()

    public var generations: [Generation]
    public var nextError: (any Error)?

    public init(generations: [Generation] = []) {
        self.generations = generations
    }

    public func generations(centre _: UUID) async throws -> [Generation] {
        try throwIfScripted()
        return generations.sorted { $0.createdAt > $1.createdAt }
    }

    public func generation(id: UUID) async throws -> Generation? {
        try throwIfScripted()
        return generations.first { $0.id == id }
    }

    public nonisolated static func id(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "cccccccc-0000-0000-0000-%012d", number)) ?? UUID()
    }

    private func throwIfScripted() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }

    /// A moment in 2026 in India.
    private nonisolated static func time(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let parts = DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)
        return DayHeading.india.date(from: parts) ?? .distantPast
    }

    private nonisolated static func make(
        _ number: Int, _ kind: GenerationKind, at date: Date, _ request: GenerateRequest, _ result: GenerationResult
    ) -> Generation {
        Generation(id: id(number), kind: kind, createdAt: date, request: request, result: result)
    }
}
