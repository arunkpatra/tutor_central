import Domain
import Foundation
import Testing
@testable import Data

/// The key and the request id on every AI call (D84; plan decisions 7 and 12), and the answers they bring. In the
/// serialized APIClientTests suite: the stub's recorder is one for the process.
extension APIClientTests {
    static let paperAnswer = #"{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","result":{"title":"T","sections":"#
        + #"[{"title":"A","marksEach":1,"questions":[{"number":1,"text":"q","marks":1,"answer":"a"}]}]}}"#
    static let form = GenerateRequest.paper(PaperForm(
        classID: UUID(uuidString: "33333333-3333-3333-3333-333333333333"), subject: "Mathematics", topic: "Fractions"
    ))

    @Test func everyAICallCarriesTheKeyAndARequestID() async throws {
        let (client, recorder) = Self.client(status: 200, body: Self.paperAnswer)
        _ = try await client.generate(Self.form, context: Self.context)
        _ = try await client.generate(Self.form, context: Self.context)
        let requests = recorder.requests
        let keys = requests.map { $0.value(forHTTPHeaderField: "Idempotency-Key") }
        let ids = requests.compactMap { $0.value(forHTTPHeaderField: "X-Request-Id") }
        #expect(keys.count == 2 && keys[0] != nil && keys[0] == keys[1])
        #expect(ids.count == 2 && ids[0] != ids[1] && ids.allSatisfy { UUID(uuidString: $0) != nil })
    }

    @Test func createAgainSendsAFreshKey() async throws {
        let (client, recorder) = Self.client(status: 200, body: Self.paperAnswer)
        _ = try await client.generate(Self.form, context: Self.context)
        _ = try await client.generate(Self.form, context: Self.context.again())
        _ = try await client.generate(Self.form, context: Self.context.again())
        let keys = recorder.requests.compactMap { $0.value(forHTTPHeaderField: "Idempotency-Key") }
        #expect(Set(keys).count == 3)
    }

    /// Make it again, Write again (the review's finding 2): each call inside `another` takes a fresh key, so the same
    /// body asked twice is two calls; outside it the body's key stands.
    @Test func everyCallInsideAnotherTakesAFreshKey() async throws {
        let (client, recorder) = Self.client(status: 200, body: Self.paperAnswer)
        _ = try await client.generate(Self.form, context: Self.context)
        _ = try await IdempotencyKey.another { try await client.generate(Self.form, context: Self.context) }
        _ = try await IdempotencyKey.another { try await client.generate(Self.form, context: Self.context) }
        _ = try await client.generate(Self.form, context: Self.context)
        let keys = recorder.requests.compactMap { $0.value(forHTTPHeaderField: "Idempotency-Key") }
        #expect(keys.count == 4 && Set(keys).count == 3 && keys[0] == keys[3])
    }

    /// The plan's material asked again the next day is a new call (the review's finding 1): the key carries the day in
    /// India, so 23:59 and 00:01 there differ.
    @Test func theKeyTurnsWithTheDayInIndia() async throws {
        let before = Date(timeIntervalSince1970: 1_791_829_740) // 2026-10-12 23:59 IST
        let after = before.addingTimeInterval(120)
        let (early, first) = Self.client(status: 200, body: Self.paperAnswer, now: { before })
        _ = try await early.generate(Self.form, context: Self.context)
        let one = first.requests.first?.value(forHTTPHeaderField: "Idempotency-Key")
        let (late, second) = Self.client(status: 200, body: Self.paperAnswer, now: { after })
        _ = try await late.generate(Self.form, context: Self.context)
        let two = second.requests.first?.value(forHTTPHeaderField: "Idempotency-Key")
        #expect(one != nil && two != nil && one != two)
    }

    @Test func aReplayedAnswerReadsLikeAFirstOne() async throws {
        let (client, _) = Self.client(status: 200, body: Self.paperAnswer)
        let generation = try await client.generate(Self.form, context: Self.context)
        #expect(generation.id == UUID(uuidString: "fbc6ae19-2769-4934-bf10-c830207fd6a3"))
    }

    @Test func anInProgressAnswerReadsAsTimedOut() {
        let body = ErrorBody(error: "x", reason: "in_progress", limit: nil)
        #expect(APIClient.failure(status: 409, body: body) == .timedOut)
    }

    @Test func aReusedKeyReadsAsTheServiceWords() {
        #expect(APIClient
            .failure(status: 409, body: ErrorBody(error: "x", reason: "key_reused", limit: nil)) == .service)
        #expect(APIClient.failure(status: 409, body: nil) == .service)
    }

    @Test func aRateAnswerReadsAsTimedOutNotTheLimit() {
        #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: "rate", limit: nil)) == .timedOut)
        #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: nil, limit: 40)) == .limit(40))
    }

    @Test func aBodyTooLargeReadsAsTooManyPages() {
        #expect(APIClient.failure(status: 413, body: nil) == .tooLarge)
    }

    @Test func theAppleRevocationCarriesNoKey() async throws {
        let (client, recorder) = Self.client(status: 204, body: "")
        try await client.revokeApple(code: "c")
        let request = try #require(recorder.requests.first)
        #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Request-Id") != nil)
    }
}
