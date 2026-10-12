import Domain
import Foundation
import Supabase

public struct SupabaseActivityRepository: ActivityRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// Each row carries the event's id; one already sent is ignored, so a batch posted again after its answer was lost
    /// (or beside the sign-out's post) is one row.
    public func post(_ events: [ActivityEvent], centre: UUID) async throws {
        guard !events.isEmpty else { return }
        try await client.from("events")
            .upsert(Self.rows(events, centre: centre), onConflict: "id", ignoreDuplicates: true)
            .execute()
    }

    static func rows(_ events: [ActivityEvent], centre: UUID) -> [[String: AnyJSON]] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return events.map { event in
            [
                "id": .string(event.id.uuidString.lowercased()),
                "centre_id": .string(centre.uuidString.lowercased()),
                "kind": .string(event.kind.rawValue),
                "screen": event.screen.map(AnyJSON.string) ?? .null,
                "at": .string(formatter.string(from: event.at)),
            ]
        }
    }
}
