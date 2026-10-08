import Domain
import Foundation
import Supabase

public final class SupabaseClassesRepository: ClassesRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, name, subject, monthly_fee, meeting_days, start_time, end_time, archived_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func classes(centre: UUID) async throws -> [Classroom] {
        let response = try await client.from("classes").select(Self.columns).eq("centre_id", value: centre)
            .order("name").execute()
        return try Self.decoder.decode([ClassroomRow].self, from: response.data).map(\.classroom)
    }

    public func create(_ draft: ClassroomDraft, centre: UUID) async throws -> Classroom {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("classes").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(ClassroomRow.self, from: response.data).classroom
    }

    public func update(id: UUID, with draft: ClassroomDraft) async throws -> Classroom {
        let response = try await client.from("classes").update(Self.values(draft)).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(ClassroomRow.self, from: response.data).classroom
    }

    public func archive(id: UUID) async throws {
        try await client.rpc("archive_class", params: ["p_class": AnyJSON.string(id.uuidString)]).execute()
    }

    static func values(_ draft: ClassroomDraft) -> [String: AnyJSON] {
        [
            "name": .string(draft.trimmedName),
            "subject": draft.trimmedSubject.map(AnyJSON.string) ?? .null,
            "monthly_fee": draft.fee.map { .integer($0.rupees) } ?? .null,
            "meeting_days": .array(draft.meetingDays.sorted().map { .integer($0.rawValue) }),
            "start_time": draft.startTime.map { .string($0.iso) } ?? .null,
            "end_time": draft.endTime.map { .string($0.iso) } ?? .null,
        ]
    }
}
