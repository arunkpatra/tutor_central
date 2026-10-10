import Domain
import Foundation

/// The V2 routes this phase calls (api/src/routes/v2.ts): the contents page, the close's checks, the placement.
public extension APIClient {
    func parseTextbook(
        _ image: ImageUpload, classLevel: ClassLevel, subject: String, centre: UUID
    ) async throws(APIFailure) -> TextbookReading {
        guard image.base64.count <= Self.bodyLimit else { throw .tooLarge }
        let body = TextbookBody(
            centreId: centre.uuidString.lowercased(), image: ImageBody(image), classLevel: classLevel.rawValue,
            subject: subject
        )
        let data = try await post("ai/parse-textbook", body: body)
        guard let answer = try? JSONDecoder().decode(TextbookEnvelope.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        let chapters = answer.result.chapters.enumerated().map { index, chapter in
            TextbookChapter(position: index + 1, name: chapter.name, skills: chapter.skills)
        }
        return TextbookReading(id: answer.id, title: answer.result.title, chapters: chapters)
    }

    func makeChecks(
        classLevel: ClassLevel, subject: String, skills: [String], centre: UUID
    ) async throws(APIFailure) -> [CheckQuestion] {
        let body = MakeCheckBody(
            centreId: centre.uuidString.lowercased(), classLevel: classLevel.rawValue, subject: subject, skills: skills
        )
        let data = try await post("ai/make", body: body)
        guard let answer = try? JSONDecoder().decode(ChecksEnvelope.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return answer.result.questions
    }

    func makePlacement(
        classLevel: ClassLevel, subject: String, chapters: [String], centre: UUID
    ) async throws(APIFailure) -> [PlacementQuestion] {
        let body = MakePlacementBody(
            centreId: centre.uuidString.lowercased(), classLevel: classLevel.rawValue, subject: subject,
            chapters: chapters
        )
        let data = try await post("ai/make", body: body)
        guard let answer = try? JSONDecoder().decode(PlacementEnvelope.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return answer.result.questions
    }
}
