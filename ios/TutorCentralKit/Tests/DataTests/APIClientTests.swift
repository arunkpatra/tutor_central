import Domain
import Foundation
import Synchronization
import Testing
@testable import Data

@Suite(.serialized) struct APIClientTests {
    static let origin = URL(string: "https://api.test") ?? URL(fileURLWithPath: "/")
    static let centre = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
    static let context = GenerateContext(
        centre: centre, className: "Class 10 Maths", subject: "Mathematics", studentName: nil, parentName: nil,
        attendanceLine: nil, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
    )

    static func client(status: Int, body: String) -> (APIClient, StubProtocol.Recorder) {
        let recorder = StubProtocol.Recorder(status: status, body: body)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        StubProtocol.recorder.withLock { $0 = recorder }
        return (APIClient(origin: origin, token: { "tok" }, session: URLSession(configuration: config)), recorder)
    }

    static func sent(_ recorder: StubProtocol.Recorder) throws -> [String: Any] {
        let body = try #require(recorder.bodies.first)
        return try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func generatePostsTheFormWithTheBearerAndDecodesTheResult() async throws {
        let body = #"{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","result":{"title":"Quadratic equations","sections":"#
            + #"[{"title":"A","marksEach":1,"questions":[{"number":1,"text":"q","marks":1,"answer":"a"}]}]}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let form = PaperForm(classID: UUID(), subject: "Mathematics", topic: "Quadratic equations")
        let generation = try await client.generate(.paper(form), context: Self.context)
        #expect(generation.id == UUID(uuidString: "fbc6ae19-2769-4934-bf10-c830207fd6a3") && generation.kind == .paper)
        let request = try #require(recorder.requests.first)
        #expect(request.url?.path == "/ai/generate" && request
            .value(forHTTPHeaderField: "Authorization") == "Bearer tok")
        let sent = try Self.sent(recorder)
        #expect(sent["kind"] as? String == "paper" && sent["classLevel"] as? String == "Class 10 Maths")
        #expect(sent["centreId"] as? String == Self.centre.uuidString.lowercased())
        #expect(sent["topic"] as? String == "Quadratic equations" && sent["marks"] as? Int == 20)
        #expect(sent["classId"] as? String == form.classID?.uuidString.lowercased())
    }

    struct Answer {
        let status: Int
        let body: String
        let failure: APIFailure
    }

    @Test func everyAnswerBecomesItsFailure() async {
        let refusal = "Couldn't make this one. Change the topic and try again."
        let answers = [
            Answer(
                status: 403,
                body: #"{"error":"Agree to the notice before the first photo.","reason":"consent"}"#,
                failure: .consent
            ),
            Answer(status: 403, body: #"{"error":"sign in again","reason":"member"}"#, failure: .signedOut),
            Answer(
                status: 429,
                body: #"{"error":"You've made today's 40. Try again tomorrow.","limit":40}"#,
                failure: .limit(40)
            ),
            Answer(status: 422, body: #"{"error":"\#(refusal)"}"#, failure: .refused(refusal)),
            Answer(status: 502, body: #"{"error":"The AI service didn't answer. Try again."}"#, failure: .service),
            Answer(status: 401, body: #"{"error":"sign in again"}"#, failure: .signedOut),
            Answer(status: 400, body: #"{"error":"topic: too long"}"#, failure: .server("topic: too long")),
        ]
        for answer in answers {
            let (status, expected) = (answer.status, answer.failure)
            let (client, _) = Self.client(status: status, body: answer.body)
            do {
                _ = try await client.scanRegister(
                    ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg"), centre: Self.centre
                )
                Issue.record("\(status) did not throw")
            } catch {
                #expect(error == expected, "\(status)")
            }
        }
    }

    @Test func aBodyOverTheLimitIsRefusedBeforeTheRequest() async {
        let (client, recorder) = Self.client(status: 200, body: "{}")
        let page = ImageUpload(data: Data(repeating: 0xFF, count: 1_100_000), mediaType: "image/jpeg")
        do {
            _ = try await client.checkPaper(
                pages: Array(repeating: page, count: 3), scheme: .typed("Q1 (1) b"), studentName: "Hemanth Reddy",
                centre: Self.centre
            )
            Issue.record("did not throw")
        } catch {
            #expect(error == .tooLarge && recorder.requests.isEmpty)
        }
        #expect(APIFailure.tooLarge.message == "That's too many pages. Up to six, and try sharper, smaller photos.")
        #expect(APIFailure.offline.message == "Couldn't reach the AI service. Check your connection and try again.")
    }

    @Test func revokeApplePostsTheCodeAndMapsEveryAnswer() async throws {
        let (client, recorder) = Self.client(status: 204, body: "")
        try await client.revokeApple(code: "c.abc")
        #expect(recorder.requests.first?.url?.path == "/account/revoke-apple")
        #expect(try Self.sent(recorder)["code"] as? String == "c.abc")
        let answers: [(Int, AccountFailure)] = [
            // Any other answer is never shown as the API wrote it (D41).
            (400, .appleRefused), (401, .signedOut), (502, .appleUnreachable), (500, .unexpected), (404, .unexpected),
        ]
        for (status, failure) in answers {
            let (failing, _) = Self.client(status: status, body: #"{"error":"Boom."}"#)
            await #expect(throws: failure) { try await failing.revokeApple(code: "c") }
        }
    }

    @Test func aTimeoutIsNotOfflineAndDoesNotPromiseNothingWasUsed() {
        #expect(APIClient.failure(transport: URLError(.timedOut)) == .timedOut)
        #expect(APIClient.failure(transport: URLError(.notConnectedToInternet)) == .offline)
        #expect(APIFailure.timedOut.message == "That took too long to come back. Try again in a minute.")
    }

    @Test func checkPaperSendsThePagesInOrderAndTheScheme() async throws {
        let body = #"{"id":"11111111-1111-1111-1111-111111111111","result":{"questions":[{"number":1,"text":"q","#
            + #""note":"n","marks":3,"of":1}],"summary":"s"}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let pages = [Data([0xFF, 0xD8, 0xFF, 1]), Data([0xFF, 0xD8, 0xFF, 2])].map {
            ImageUpload(data: $0, mediaType: "image/jpeg")
        }
        let answer = try await client.checkPaper(
            pages: pages, scheme: .paper(generationID: UUID()), studentName: "Hemanth Reddy", centre: Self.centre
        )
        #expect(answer.result.questions[0].marks == 1, "clamped on arrival")
        let sent = try Self.sent(recorder)
        let sentPages = try #require(sent["pages"] as? [[String: String]])
        #expect(sentPages.map { $0["imageBase64"] } == pages.map(\.base64))
        #expect((sent["scheme"] as? [String: String])?["kind"] == "paper")
    }
}

extension APIClientTests {
    @Test func theThreeV2BodiesMatchTheSchemas() throws {
        let image = ImageBody(ImageUpload(data: Data([1, 2]), mediaType: "image/jpeg"))
        let textbook = try JSONSerialization.jsonObject(with: JSONEncoder().encode(TextbookBody(
            centreId: "c", image: image, classLevel: "5", subject: "Mathematics"
        ))) as? [String: Any]
        #expect(textbook?["classLevel"] as? String == "5")
        #expect((textbook?["image"] as? [String: Any])?["mediaType"] as? String == "image/jpeg")
        let check = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeCheckBody(
            centreId: "c", classLevel: "8", subject: "Science", skills: ["A", "B"]
        ))) as? [String: Any]
        #expect(check?["kind"] as? String == "check" && (check?["skills"] as? [String])?.count == 2)
        let placement = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakePlacementBody(
            centreId: "c", classLevel: "5", subject: "Mathematics", chapters: ["X"]
        ))) as? [String: Any]
        #expect(placement?["kind"] as? String == "placement" && (placement?["chapters"] as? [String]) == ["X"])
    }

    @Test func a429OnAV2KindIsTheMonthlyAllowance() {
        #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: nil, limit: 600, kind: "check"))
            == .allowance(600))
        #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: nil, limit: 40, kind: "paper"))
            == .limit(40))
        #expect(APIFailure.allowance(600).message == "You've made this month's 600. More next month.")
    }

    @Test func theTextbookIsReadIntoNumberedChapters() async throws {
        let body = #"{"id":"6b2d0f3e-1c2d-4e8f-a1b2-c3d4e5f60901","result":{"title":"Math-Magic 5","chapters":"#
            + #"[{"name":"The Fish Tale","skills":["Compare lengths"]},{"name":"Shapes","skills":["Angles"]}]}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let reading = try await client.parseTextbook(
            ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg"), classLevel: .five,
            subject: "Mathematics", centre: Self.centre
        )
        #expect(reading.title == "Math-Magic 5")
        #expect(reading.chapters == [
            TextbookChapter(position: 1, name: "The Fish Tale", skills: ["Compare lengths"]),
            TextbookChapter(position: 2, name: "Shapes", skills: ["Angles"]),
        ])
        #expect(recorder.requests.first?.url?.path == "/ai/parse-textbook")
        #expect(try Self.sent(recorder)["subject"] as? String == "Mathematics")
    }

    @Test func theChecksAndThePlacementDecode() async throws {
        let checks = #"{"id":"6b2d0f3e-1c2d-4e8f-a1b2-c3d4e5f60902","result":{"questions":"#
            + #"[{"skill":"A","question":"Q","answer":"R"}]}}"#
        let (client, recorder) = Self.client(status: 200, body: checks)
        let made = try await client.makeChecks(
            classLevel: .eight,
            subject: "Science",
            skills: ["A"],
            centre: Self.centre
        )
        #expect(made == [CheckQuestion(skill: "A", question: "Q", answer: "R")])
        #expect(recorder.requests.first?.url?.path == "/ai/make")
        #expect(try Self.sent(recorder)["kind"] as? String == "check")
        let placement = #"{"id":"6b2d0f3e-1c2d-4e8f-a1b2-c3d4e5f60903","result":{"questions":"#
            + #"[{"chapter":"X","question":"Q","answer":"R"}]}}"#
        let (other, _) = Self.client(status: 200, body: placement)
        let asked = try await other.makePlacement(
            classLevel: .five,
            subject: "Mathematics",
            chapters: ["X"],
            centre: Self.centre
        )
        #expect(asked == [PlacementQuestion(chapter: "X", question: "Q", answer: "R")])
    }
}

/// Answers every request with one status and body, recording what was sent. URLSession calls it off the main actor,
/// so the recorder lives behind a lock.
final class StubProtocol: URLProtocol {
    static let recorder = Mutex<Recorder?>(nil)

    final class Recorder: @unchecked Sendable {
        let status: Int
        let body: String
        private let lock = NSLock()
        private var sentRequests: [URLRequest] = []
        private var sentBodies: [Data] = []

        init(status: Int, body: String) {
            self.status = status
            self.body = body
        }

        var requests: [URLRequest] {
            lock.withLock { sentRequests }
        }

        var bodies: [Data] {
            lock.withLock { sentBodies }
        }

        func record(_ request: URLRequest, body: Data) {
            lock.withLock {
                sentRequests.append(request)
                sentBodies.append(body)
            }
        }
    }

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let recorder = Self.recorder.withLock({ $0 }) else { return }
        recorder.record(request, body: request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data())
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"), statusCode: recorder.status, httpVersion: nil,
            headerFields: ["content-type": "application/json"]
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Data(recorder.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 65536)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}
