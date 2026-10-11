import Domain
import Foundation
import Supabase

public final class SupabaseSchoolItemsRepository: SchoolItemsRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func items(centre: UUID) async throws -> [SchoolItem] {
        let response = try await client.from("school_items").select(SchoolItemRow.columns)
            .eq("centre_id", value: centre).order("date").order("title").execute()
        return try Self.decoder.decode([SchoolItemRow].self, from: response.data).compactMap(\.item)
    }

    public func item(id: UUID, centre: UUID) async throws -> SchoolItem? {
        let response = try await client.from("school_items").select(SchoolItemRow.columns)
            .eq("centre_id", value: centre).eq("id", value: id).limit(1).execute()
        return try Self.decoder.decode([SchoolItemRow].self, from: response.data).first?.item
    }

    public func add(_ drafts: [SchoolItemDraft], photoPath: String?, centre: UUID) async throws -> [SchoolItem] {
        let now = Date()
        let rows = drafts.filter { $0.ticked && $0.isComplete }
            .map { SchoolItemWrite(draft: $0, photoPath: photoPath, centre: centre, confirmedAt: now) }
        guard !rows.isEmpty else { return [] }
        let response = try await client.from("school_items").insert(rows).select(SchoolItemRow.columns).execute()
        return try Self.decoder.decode([SchoolItemRow].self, from: response.data).compactMap(\.item)
    }

    /// The item's own row, filtered by its centre as well as its id (RLS holds; the filter says so in the query).
    public func update(_ item: SchoolItem, centre: UUID) async throws -> SchoolItem {
        let response = try await client.from("school_items").update(SchoolItemWrite(item: item))
            .eq("centre_id", value: centre).eq("id", value: item.id)
            .select(SchoolItemRow.columns).single().execute()
        return try Self.decoder.decode(SchoolItemRow.self, from: response.data).item ?? item
    }

    public func delete(id: UUID, centre: UUID) async throws {
        try await client.from("school_items").delete().eq("centre_id", value: centre).eq("id", value: id).execute()
    }
}
