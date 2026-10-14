import Domain
import Foundation
import Supabase

/// Where a tutor's feedback on a made thing goes (D107, `generation_feedback` through `record_feedback`, migration
/// 0057):
/// an edit to a note at Send, a reason at Make it again or Write again, a replacement by their own.
public protocol FeedbackRecorder: Sendable {
    func record(_ feedback: Feedback, centre: UUID) async throws
}

/// `record_feedback` as the signed-in member (RLS and the function check the centre).
public struct SupabaseFeedbackRepository: FeedbackRecorder {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func record(_ feedback: Feedback, centre: UUID) async throws {
        try await client.rpc("record_feedback", params: Self.params(feedback, centre: centre)).execute()
    }

    /// The function's arguments: the revised text as a JSON string, a photo as `{"photo": true}` (never the photo).
    static func params(_ feedback: Feedback, centre: UUID) -> [String: AnyJSON] {
        let revised: AnyJSON = switch feedback.revised {
        case let .text(text)?: .string(text)
        case .photo?: .object(["photo": .bool(true)])
        case nil: .null
        }
        return [
            "p_centre": .string(centre.uuidString.lowercased()),
            "p_generation": .string(feedback.generation.uuidString.lowercased()),
            "p_kind": .string(feedback.kind.rawValue),
            "p_reason": feedback.reason.map(AnyJSON.string) ?? .null,
            "p_revised": revised,
        ]
    }
}

/// The feedback in memory for tests, previews and `bun shots`: what was recorded, in order; a scripted failure.
@MainActor public final class FakeFeedbackRecorder: FeedbackRecorder {
    public private(set) var recorded: [Feedback] = []
    public var fails = false

    public init() {}

    public func record(_ feedback: Feedback, centre _: UUID) async throws {
        if fails {
            throw URLError(.notConnectedToInternet)
        }
        recorded.append(feedback)
    }
}
