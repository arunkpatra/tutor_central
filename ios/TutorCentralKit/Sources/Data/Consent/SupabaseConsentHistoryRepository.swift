import Domain
import Foundation
import Supabase

public struct SupabaseConsentHistoryRepository: ConsentHistoryRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    struct Row: Decodable {
        let kind: ConsentEvent.Kind
        let how: String?
        let at: Date
        let phone: String?

        var event: ConsentEvent {
            ConsentEvent(
                kind: kind, how: how.flatMap(ConsentMethod.init(rawValue:)), at: at,
                phone: phone.flatMap(PhoneNumber.init(e164:))
            )
        }
    }

    public func history(centre: UUID, student: UUID) async throws -> [ConsentEvent] {
        let response = try await client.from("consent_events").select("kind, how, at, phone")
            .eq("centre_id", value: centre.uuidString).eq("student_id", value: student.uuidString)
            .order("at", ascending: false).order("created_at", ascending: false).execute()
        return try PostgRESTDecoder.make().decode([Row].self, from: response.data).map(\.event)
    }
}
