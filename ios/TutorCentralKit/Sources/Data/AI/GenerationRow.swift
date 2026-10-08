import Domain
import Foundation
import Supabase

/// A row of `ai_generations` as History reads it: the output is the JSON the API wrote, the input the body it
/// recorded (its own keys, camelCase).
public struct GenerationRow: Decodable, Sendable {
    public let id: UUID
    public let kind: String
    public let input: AnyJSON?
    public let output: String?
    public let createdAt: Date

    /// The generation when its kind is one of the four and its output still reads; nil otherwise (a scan, a check, a
    /// failed or pending call, a row from a newer build).
    public var generation: Generation? {
        guard let kind = GenerationKind(rawValue: kind), let output,
              let result = GenerationResult.decode(kind: kind, output: output) else { return nil }
        return Generation(id: id, kind: kind, createdAt: createdAt, request: request(kind), result: result)
    }

    private func request(_ kind: GenerationKind) -> GenerateRequest? {
        guard let input, let data = try? JSONEncoder().encode(input),
              let stored = try? JSONDecoder().decode(StoredInput.self, from: data) else { return nil }
        return stored.request(kind)
    }
}

/// The recorded body of a generation (api/src/schemas.ts, GenerateInput, with the class's and student's ids).
private struct StoredInput: Decodable {
    let classId: UUID?
    let subject: String?
    let topic: String?
    let level: Level?
    let questions: Int?
    let marks: Int?
    let withAnswers: Bool?
    let studentId: UUID?
    let observations: String?
    let tone: Tone?

    func request(_ kind: GenerationKind) -> GenerateRequest {
        let subject = subject ?? ""
        let topic = topic ?? ""
        let level = level ?? .medium
        switch kind {
        case .paper:
            return .paper(PaperForm(
                classID: classId, subject: subject, topic: topic, level: level, questions: questions ?? 10,
                marks: marks ?? 20
            ))
        case .homework:
            return .homework(HomeworkForm(
                classID: classId, subject: subject, topic: topic, level: level, questions: questions ?? 5
            ))
        case .worksheet:
            return .worksheet(WorksheetForm(
                classID: classId, subject: subject, topic: topic, level: level, questions: questions ?? 12,
                withAnswers: withAnswers ?? true
            ))
        case .progressNote:
            return .progressNote(NoteForm(studentID: studentId, observations: observations ?? "", tone: tone ?? .warm))
        }
    }
}
