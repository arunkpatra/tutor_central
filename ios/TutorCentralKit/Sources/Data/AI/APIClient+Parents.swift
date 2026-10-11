import Domain
import Foundation

/// The parents' calls (Phase 14): the note, can-now-do and not-on-track messages through /ai/make, and marks from a
/// photo through /ai/read-marks.
public extension APIClient {
    func makeNote(_ request: NoteRequest, centre: UUID) async throws(APIFailure) -> MadeMessage {
        let answer = try await made(MessageResult.self, body: MakeNoteBody(request, centre: centre))
        return MadeMessage(generationID: answer.id, message: answer.result.message, english: answer.result.english)
    }

    func makeCanDo(_ request: CanDoRequest, centre: UUID) async throws(APIFailure) -> MadeMessage {
        let answer = try await made(MessageResult.self, body: MakeCanDoBody(request, centre: centre))
        return MadeMessage(generationID: answer.id, message: answer.result.message, english: answer.result.english)
    }

    func makeNotOnTrack(_ request: NotOnTrackRequest, centre: UUID) async throws(APIFailure) -> MadeMessage {
        let answer = try await made(MessageResult.self, body: MakeNotOnTrackBody(request, centre: centre))
        return MadeMessage(generationID: answer.id, message: answer.result.message, english: answer.result.english)
    }

    func readMarks(_ request: ReadMarksRequest, centre: UUID) async throws(APIFailure) -> ReadMarksAnswer {
        let body = ReadMarksBody(request, centre: centre)
        guard body.pages.reduce(0, { $0 + $1.imageBase64.count }) <= Self.bodyLimit else { throw .tooLarge }
        let data = try await post("ai/read-marks", body: body)
        guard let answer = try? JSONDecoder().decode(MadeEnvelope<ReadMarksResult>.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return ReadMarksAnswer(generationID: answer.id, marks: answer.result.read)
    }
}
