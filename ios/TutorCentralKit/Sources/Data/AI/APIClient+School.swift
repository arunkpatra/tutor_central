import Domain
import Foundation

/// The school's calls (api/src/routes/ai.ts and v2.ts, Phase 13): what the school sent read, the mock, the gap report
/// and Test tomorrow. The parser and the mock carry no student; the gap report and the message name theirs (D62).
public extension APIClient {
    func parseSchool(
        _ source: SchoolSource, today: Day, schools: [String], classLevels: [ClassLevel], centre: UUID
    ) async throws(APIFailure) -> SchoolReading {
        if case let .image(upload) = source, upload.base64.count > Self.bodyLimit {
            throw .tooLarge
        }
        let body = ParseSchoolBody(
            source: source,
            today: today,
            schools: schools,
            classLevels: classLevels,
            centre: centre
        )
        let data = try await post("ai/parse-school", body: body)
        guard let answer = try? JSONDecoder().decode(MadeEnvelope<ParseSchoolResult>.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return SchoolReading(id: answer.id, items: answer.result.items)
    }

    func makeMock(_ request: MockRequest, centre: UUID) async throws(APIFailure) -> MadeMock {
        let answer = try await made(MockResult.self, body: MakeMockBody(request, centre: centre))
        let content = MockContent(
            title: answer.result.title, durationMinutes: answer.result.durationMinutes,
            sections: answer.result.sections,
            pattern: request.pattern, portions: request.portions, schoolItemID: request.schoolItemID
        )
        return MadeMock(generationID: answer.id, content: content)
    }

    func makeGapReport(_ request: GapRequest, centre: UUID) async throws(APIFailure) -> MadeGapReport {
        let answer = try await made(GapResult.self, body: MakeGapBody(request, centre: centre))
        return MadeGapReport(generationID: answer.id, summary: answer.result.summary, days: answer.result.days)
    }

    func makeTestTomorrow(_ request: TestTomorrowRequest, centre: UUID) async throws(APIFailure) -> MadeMessage {
        let answer = try await made(MessageResult.self, body: MakeTestTomorrowBody(request, centre: centre))
        return MadeMessage(generationID: answer.id, message: answer.result.message, english: answer.result.english)
    }
}
