import Domain
import Foundation
import Supabase

/// History through PostgREST: RLS shows only the centre's own rows.
public final class SupabaseAIHistoryRepository: AIHistoryRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    static let columns = "id, kind, input, output, created_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func generations(centre: UUID) async throws -> [Generation] {
        let response = try await client.from("ai_generations")
            .select(Self.columns)
            .eq("centre_id", value: centre)
            .in("kind", values: GenerationKind.allCases.map(\.rawValue))
            .eq("status", value: "ok")
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
        return try Self.decoder.decode([GenerationRow].self, from: response.data).compactMap(\.generation)
    }

    public func generation(id: UUID) async throws -> Generation? {
        let response = try await client.from("ai_generations")
            .select(Self.columns)
            .eq("id", value: id)
            .execute()
        return try Self.decoder.decode([GenerationRow].self, from: response.data).first?.generation
    }
}
