import Domain
import Foundation

/// The plan's calls (api/src/routes/v2.ts, Phase 12): a first topic per group, and the group material. None carries a
/// student (D62).
public extension APIClient {
    func makeChecksWithID(
        classLevel: ClassLevel, subject: String, skills: [String], centre: UUID
    ) async throws(APIFailure) -> MadeChecks {
        let body = MakeCheckBody(
            centreId: centre.uuidString.lowercased(), classLevel: classLevel.rawValue, subject: subject, skills: skills
        )
        let answer = try await made(ChecksEnvelope.Result.self, body: body)
        return MadeChecks(generationID: answer.id, questions: answer.result.questions)
    }

    func makeSheet(_ request: SheetRequest, centre: UUID) async throws(APIFailure) -> MadeSheet {
        let body = MakeSheetBody(
            centreId: centre.uuidString.lowercased(), classLevel: request.classLevel.rawValue,
            subject: request.subject, skills: request.skills, questions: request.questions,
            forHomework: request.forHomework, reason: request.reason
        )
        let answer = try await made(SheetResult.self, body: body)
        let content = SheetContent(
            title: answer.result.title, instructions: answer.result.instructions, questions: answer.result.questions,
            forHomework: request.forHomework, light: request.forHomework && request.classLevel.homeworkIsLight
        )
        return MadeSheet(generationID: answer.id, content: content)
    }

    func makeWorkedExample(
        classLevel: ClassLevel, subject: String, skill: String, centre: UUID
    ) async throws(APIFailure) -> MadeWorkedExample {
        let body = MakeWorkedExampleBody(
            centreId: centre.uuidString.lowercased(), classLevel: classLevel.rawValue, subject: subject, skill: skill
        )
        let answer = try await made(WorkedExample.self, body: body)
        return MadeWorkedExample(generationID: answer.id, example: answer.result)
    }

    /// A spec that fails the app's own rule is refused here too, in the API's words for it (D59).
    func makeFigure(
        _ kind: FigureSpec.Kind, classLevel: ClassLevel, subject: String, skill: String, centre: UUID
    ) async throws(APIFailure) -> MadeFigure {
        let body = MakeFigureBody(
            centreId: centre.uuidString.lowercased(), figure: kind.rawValue, classLevel: classLevel.rawValue,
            subject: subject, skill: skill
        )
        let answer = try await made(FigureContent.self, body: body)
        guard answer.result.figure.kind == kind, answer.result.figure.validate() == nil else {
            throw .refused(Self.figureRefused)
        }
        return MadeFigure(generationID: answer.id, figure: answer.result)
    }

    func makeBrief(
        classLevel: ClassLevel, subject: String, chapter: String, centre: UUID
    ) async throws(APIFailure) -> MadeBrief {
        let body = MakeBriefBody(
            centreId: centre.uuidString.lowercased(), classLevel: classLevel.rawValue, subject: subject,
            chapter: chapter
        )
        let answer = try await made(Brief.self, body: body)
        return MadeBrief(generationID: answer.id, brief: answer.result)
    }

    func planTopics(
        classID: UUID?, date: Day, month: Int, groups: [PlanTopicGroup], centre: UUID
    ) async throws(APIFailure) -> [PlanTopic] {
        let body = PlanBody(
            centreId: centre.uuidString.lowercased(), classId: classID?.uuidString.lowercased(), date: date.iso,
            month: month,
            groups: groups.map { .init(groupNo: $0.groupNo, classLevel: $0.classLevel.rawValue, subject: $0.subject) }
        )
        let data = try await post("ai/plan", body: body)
        guard let answer = try? JSONDecoder().decode(MadeEnvelope<TopicsResult>.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return answer.result.groups
    }

    /// The API's words for a figure that does not add up (api/src/errors.ts).
    static let figureRefused = "Couldn't draw a figure for this skill. The plan goes on without it."

    private func made<Result: Decodable>(
        _: Result.Type, body: some Encodable
    ) async throws(APIFailure) -> MadeEnvelope<Result> {
        let data = try await post("ai/make", body: body)
        guard let answer = try? JSONDecoder().decode(MadeEnvelope<Result>.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return answer
    }
}
