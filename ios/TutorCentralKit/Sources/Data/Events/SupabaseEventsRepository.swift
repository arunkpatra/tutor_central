import Domain
import Foundation
import Supabase

/// `calendar_events` through PostgREST.
public final class SupabaseEventsRepository: EventsRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, title, date, start_time, end_time, note"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent] {
        let response = try await client.from("calendar_events").select(Self.columns)
            .eq("centre_id", value: centre).gte("date", value: from.iso).lte("date", value: to.iso)
            .order("date").order("start_time", nullsFirst: true).execute()
        return try Self.decoder.decode([EventRow].self, from: response.data).map(\.event)
    }

    public func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("calendar_events").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(EventRow.self, from: response.data).event
    }

    public func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent {
        let response = try await client.from("calendar_events").update(Self.values(draft)).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(EventRow.self, from: response.data).event
    }

    public func delete(id: UUID) async throws {
        try await client.from("calendar_events").delete().eq("id", value: id).execute()
    }

    static func values(_ draft: EventDraft) -> [String: AnyJSON] {
        [
            "title": .string(draft.trimmedTitle),
            "date": .string(draft.date.iso),
            "start_time": draft.startTime.map { .string($0.iso) } ?? .null,
            "end_time": draft.endTime.map { .string($0.iso) } ?? .null,
            "note": draft.trimmedNote.map(AnyJSON.string) ?? .null,
        ]
    }
}
