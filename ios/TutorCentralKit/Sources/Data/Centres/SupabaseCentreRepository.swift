import Domain
import Foundation
import Supabase

/// The centre through PostgREST: RLS shows a user only the centres they belong to and their own profile.
public final class SupabaseCentreRepository: CentreRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func workspace(for user: AuthUser) async throws -> Workspace? {
        let centres: [CentreRow] = try await client.from("centres")
            .select("id, name, whatsapp_number")
            .order("created_at")
            .limit(1)
            .execute()
            .value
        guard let row = centres.first else { return nil }
        let profiles: [ProfileRow] = try await client.from("profiles")
            .select("display_name")
            .eq("user_id", value: user.id)
            .execute()
            .value
        return Workspace(
            user: user,
            centre: Centre(id: row.id, name: row.name, whatsappNumber: row.whatsappNumber),
            profile: Profile(displayName: profiles.first?.displayName)
        )
    }

    public func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace {
        let params: [String: AnyJSON] = [
            "p_name": .string(draft.centreName),
            "p_whatsapp": draft.whatsappNumber.map(AnyJSON.string) ?? .null,
            "p_display_name": .string(draft.displayName),
        ]
        let id: UUID = try await client.rpc("create_centre", params: params).execute().value
        return Workspace(
            user: user,
            centre: Centre(id: id, name: draft.centreName, whatsappNumber: draft.whatsappNumber),
            profile: Profile(displayName: draft.displayName)
        )
    }

    public func updateCentre(id: UUID, name: String, whatsappNumber: String?) async throws {
        let values: [String: AnyJSON] = [
            "name": .string(name),
            "whatsapp_number": whatsappNumber.map(AnyJSON.string) ?? .null,
        ]
        try await client.from("centres").update(values).eq("id", value: id).execute()
    }

    public func updateProfile(displayName: String) async throws {
        let userID = try await client.auth.session.user.id
        try await client.from("profiles")
            .update(["display_name": AnyJSON.string(displayName)])
            .eq("user_id", value: userID)
            .execute()
    }
}

private struct CentreRow: Decodable {
    let id: UUID
    let name: String
    let whatsappNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case whatsappNumber = "whatsapp_number"
    }
}

private struct ProfileRow: Decodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}
