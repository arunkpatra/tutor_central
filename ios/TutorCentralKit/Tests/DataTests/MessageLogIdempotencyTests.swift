import Domain
import Foundation
import Supabase
import Synchronization
import Testing
@testable import Data

/// One absence log a child and day (0033): a replayed log meets the unique index and answers the row already there, so
/// a queued log sent twice is done, not failed.
@Suite(.serialized) struct MessageLogIdempotencyTests {
    static let centre = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
    static let student = UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID()
    static let duplicate = #"{"code":"23505","details":"Key exists.","hint":null,"#
        + #""message":"duplicate key value violates unique constraint \"message_log_one_absence_a_day\""}"#
    static let row = #"[{"student_id":"44444444-4444-4444-4444-444444444444","opened_at":"2026-10-07T11:00:00+00:00","#
        + #""about_date":"2026-10-07"}]"#

    static func repository(_ answers: [(Int, String)]) throws -> SupabaseMessageLogRepository {
        SequenceStub.answers.withLock { $0 = answers }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SequenceStub.self]
        let client = try SupabaseClient(
            supabaseURL: #require(URL(string: "https://db.test")), supabaseKey: "anon",
            options: .init(global: .init(session: URLSession(configuration: config)))
        )
        return SupabaseMessageLogRepository(client: client)
    }

    @Test func aSecondLogForTheChildAndDayAnswersTheFirst() async throws {
        let repository = try Self.repository([(409, Self.duplicate), (200, Self.row)])
        let day = try #require(Day(iso: "2026-10-07"))
        let log = try await repository.logAbsence(centre: Self.centre, studentID: Self.student, about: day)
        #expect(log.studentID == Self.student && log.aboutDate == day)
        #expect(SequenceStub.paths.withLock { $0 } == ["/rest/v1/message_log", "/rest/v1/message_log"])
    }

    @Test func anyOtherRefusalStillThrows() async throws {
        let refused = #"{"code":"23503","details":null,"hint":null,"message":"insert or update violates foreign key"}"#
        let repository = try Self.repository([(409, refused)])
        let day = try #require(Day(iso: "2026-10-07"))
        await #expect(throws: (any Error).self) {
            _ = try await repository.logAbsence(centre: Self.centre, studentID: Self.student, about: day)
        }
    }
}

/// Answers each request with the next of its answers, in order; keeps the paths asked.
final class SequenceStub: URLProtocol {
    static let answers = Mutex<[(Int, String)]>([])
    static let paths = Mutex<[String]>([])

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.paths.withLock { $0.append(request.url?.path ?? "") }
        let (status, body) = Self.answers.withLock { $0.isEmpty ? (500, "{}") : $0.removeFirst() }
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"), statusCode: status, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
