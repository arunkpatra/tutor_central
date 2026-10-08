import Data
import Domain
import Foundation

/// The AI Assistant's fixtures: the calls answered by the boards' results, an hour's wait for the creating states,
/// a lost connection for the failure (P6-Generate-Failed's words), and the forms as the boards fill them.
extension Fixtures {
    @MainActor static func ai(for state: LaunchState) -> FakeAIRepository {
        let ai = FakeAIRepository(now: { clock(for: state) })
        switch state {
        case .aiGenerating, .aiResultRegenerating: ai.delay = .seconds(3600)
        case .aiGenerateFailed: ai.script = .failure(.offline)
        default: break
        }
        return ai
    }

    /// The drafts each form state starts with (P6-Form-Paper, -Homework, -Worksheet, -ProgressNote).
    static func aiForms(for state: LaunchState) -> [GenerationKind: GenerateRequest] {
        let maths = FakeClassesRepository.maths
        let science = FakeClassesRepository.science
        let hemanth = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id
        let observations = "Improving in algebra, careless with signs. Homework on time this month. Needs to "
            + "practise word problems before the mock test on 17 Oct."
        return [
            .paper: .paper(PaperForm(classID: maths.id, subject: "Mathematics", topic: "Quadratic equations")),
            .homework: .homework(HomeworkForm(classID: science.id, subject: "Science", topic: "Cell structure")),
            .worksheet: .worksheet(WorksheetForm(
                classID: maths.id, subject: "Mathematics", topic: "Linear equations in two variables", level: .easy
            )),
            .progressNote: .progressNote(NoteForm(studentID: hemanth, observations: observations, tone: .warm)),
        ]
    }
}
