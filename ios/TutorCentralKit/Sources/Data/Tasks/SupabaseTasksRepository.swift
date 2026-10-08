import Domain
import Foundation
import Supabase

/// `tasks` through PostgREST.
public final class SupabaseTasksRepository: TasksRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, title, due_date, done_at, created_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func tasks(centre: UUID) async throws -> [TaskItem] {
        let response = try await client.from("tasks").select(Self.columns).eq("centre_id", value: centre)
            .order("created_at").execute()
        return try Self.decoder.decode([TaskRow].self, from: response.data).map(\.task)
    }

    public func create(title: String, dueDate: Day?, centre: UUID) async throws -> TaskItem {
        let values: [String: AnyJSON] = [
            "centre_id": .string(centre.uuidString), "title": .string(title),
            "due_date": dueDate.map { .string($0.iso) } ?? .null,
        ]
        let response = try await client.from("tasks").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(TaskRow.self, from: response.data).task
    }

    public func setDone(id: UUID, _ done: Bool) async throws -> TaskItem {
        let value: AnyJSON = done ? .string(ISO8601DateFormatter().string(from: Date())) : .null
        let response = try await client.from("tasks").update(["done_at": value]).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(TaskRow.self, from: response.data).task
    }

    public func clearDone(centre: UUID) async throws -> Int {
        let response = try await client.from("tasks").delete().eq("centre_id", value: centre).not(
            "done_at",
            operator: .is,
            value: "null"
        )
        .select("id").execute()
        return try Self.decoder.decode([IDRow].self, from: response.data).count
    }
}

/// The clear answers the ids it deleted.
struct IDRow: Decodable {
    let id: UUID
}
