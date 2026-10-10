import Domain
import Foundation
import Supabase

public final class SupabaseSchoolsRepository: SchoolsRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, name, board"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func schools(centre: UUID) async throws -> [School] {
        let response = try await client.from("schools").select(Self.columns).eq("centre_id", value: centre)
            .order("name").execute()
        return try Self.decoder.decode([SchoolRow].self, from: response.data).map(\.school)
    }

    public func create(name: String, board: Board?, centre: UUID) async throws -> School {
        let values: [String: AnyJSON] = [
            "centre_id": .string(centre.uuidString.lowercased()),
            "name": .string(name),
            "board": board.map { .string($0.rawValue) } ?? .null,
        ]
        let response = try await client.from("schools").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(SchoolRow.self, from: response.data).school
    }

    public func setBoard(id: UUID, _ board: Board) async throws {
        try await client.from("schools").update(["board": AnyJSON.string(board.rawValue)]).eq("id", value: id).execute()
    }
}
