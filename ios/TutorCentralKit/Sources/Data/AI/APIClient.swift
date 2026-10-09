import Domain
import Foundation

/// The AI routes over HTTPS with the tutor's Supabase token (`Authorization: Bearer`). The API checks the token, the
/// consent and the day's limit, and calls Claude (D11); this client sends, waits up to 125 s, and maps every answer to
/// a result or an `APIFailure`.
public struct APIClient: AIRepository, AccountRepository {
    /// Base64 characters in one request: under Vercel's 4.5 MB body with room for the JSON around it.
    public static let bodyLimit = 4_200_000
    public static let timeout: TimeInterval = 125

    private let origin: URL
    private let token: @Sendable () async throws -> String
    private let session: URLSession
    private let now: @Sendable () -> Date

    public init(
        origin: URL, token: @escaping @Sendable () async throws -> String, session: URLSession = .shared,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.origin = origin
        self.token = token
        self.session = session
        self.now = now
    }

    public func generate(_ request: GenerateRequest, context: GenerateContext) async throws(APIFailure) -> Generation {
        let data = try await post("ai/generate", body: GenerateBody(request, context: context))
        guard let envelope = try? JSONDecoder().decode(AnswerEnvelope.self, from: data),
              let output = Self.result(in: data),
              let result = GenerationResult.decode(kind: request.kind, output: output)
        else { throw .server("The answer didn't read. Try again.") }
        return Generation(id: envelope.id, kind: request.kind, createdAt: now(), request: request, result: result)
    }

    public func scanRegister(_ image: ImageUpload, centre: UUID) async throws(APIFailure) -> ScanAnswer {
        guard image.base64.count <= Self.bodyLimit else { throw .tooLarge }
        let body = ScanBody(
            centreId: centre.uuidString.lowercased(),
            imageBase64: image.base64,
            mediaType: image.mediaType
        )
        let data = try await post("ai/scan-register", body: body)
        guard let answer = try? JSONDecoder().decode(ScanEnvelope.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return ScanAnswer(id: answer.id, rows: answer.result.rows)
    }

    public func checkPaper(
        pages: [ImageUpload], scheme: SchemeSource, studentName: String, centre: UUID
    ) async throws(APIFailure) -> CheckAnswer {
        let images = pages.map(ImageBody.init)
        guard images.reduce(0, { $0 + $1.imageBase64.count }) <= Self.bodyLimit else { throw .tooLarge }
        let body = CheckBody(
            centreId: centre.uuidString.lowercased(), pages: images, scheme: SchemeBody(scheme),
            studentName: studentName
        )
        let data = try await post("ai/check-paper", body: body)
        guard let answer = try? JSONDecoder().decode(CheckEnvelope.self, from: data) else {
            throw .server("The answer didn't read. Try again.")
        }
        return CheckAnswer(id: answer.id, result: answer.result.result)
    }

    private func post(_ path: String, body: some Encodable) async throws(APIFailure) -> Data {
        let answer = try await exchange(path, body: body)
        guard !(200 ..< 300).contains(answer.status) else { return answer.data }
        throw Self.failure(status: answer.status, body: try? JSONDecoder().decode(ErrorBody.self, from: answer.data))
    }

    /// One request with the bearer: its status and body, or the failure before any answer came.
    private func exchange(_ path: String, body: some Encodable) async throws(APIFailure) -> Answer {
        let bearer: String
        do {
            bearer = try await token()
        } catch {
            throw .signedOut
        }
        var request = URLRequest(url: origin.appending(path: path), timeoutInterval: Self.timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw .server("Couldn't send that. Try again.")
        }
        do {
            let (data, response) = try await session.data(for: request)
            return Answer(status: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
        } catch {
            throw Self.failure(transport: error)
        }
    }

    struct Answer {
        let status: Int
        let data: Data
    }

    /// A request that never got its answer: the app's own deadline (`timeout`) is not being offline.
    static func failure(transport error: any Error) -> APIFailure {
        (error as? URLError)?.code == .timedOut ? .timedOut : .offline
    }

    static func failure(status: Int, body: ErrorBody?) -> APIFailure {
        switch status {
        case 401: .signedOut
        case 403: body?.reason == "consent" ? .consent : .signedOut
        case 429: .limit(body?.limit ?? 0)
        case 422: .refused(body?.error ?? APIFailure.service.message)
        case 502, 503, 504: .service
        default: body.map { .server($0.error) } ?? .service
        }
    }

    /// The `result` object of `{ id, result }` as JSON text, for `GenerationResult.decode`.
    private static func result(in data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = object["result"],
              let json = try? JSONSerialization.data(withJSONObject: result) else { return nil }
        return String(bytes: json, encoding: .utf8)
    }
}

public extension APIClient {
    /// `POST /account/revoke-apple` (D38): 2xx is done; 400 Apple refused the code; 401 signed out; 502 Apple did not
    /// answer; no answer at all is offline, a timeout Apple not answering.
    func revokeApple(code: String) async throws(AccountFailure) {
        let answer: Answer
        do {
            answer = try await exchange("account/revoke-apple", body: ["code": code])
        } catch {
            throw switch error {
            case .signedOut: .signedOut
            case .timedOut: .appleUnreachable
            case .offline: .offline
            default: .unexpected
            }
        }
        guard !(200 ..< 300).contains(answer.status) else { return }
        throw Self.accountFailure(status: answer.status)
    }

    internal static func accountFailure(status: Int) -> AccountFailure {
        switch status {
        case 400: .appleRefused
        case 401, 403: .signedOut
        case 502, 503, 504: .appleUnreachable
        // Anything else (a route missing, a fault) is never shown in the API's own words (D41).
        default: .unexpected
        }
    }
}
