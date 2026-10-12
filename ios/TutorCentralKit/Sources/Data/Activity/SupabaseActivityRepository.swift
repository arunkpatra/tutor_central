import Domain
import Foundation
import Supabase

public struct SupabaseActivityRepository: ActivityRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func post(_ events: [ActivityEvent], centre: UUID) async throws {
        guard !events.isEmpty else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let rows: [[String: AnyJSON]] = events.map { event in
            [
                "centre_id": .string(centre.uuidString.lowercased()),
                "kind": .string(event.kind.rawValue),
                "screen": event.screen.map(AnyJSON.string) ?? .null,
                "at": .string(formatter.string(from: event.at)),
            ]
        }
        try await client.from("events").insert(rows).execute()
    }
}
