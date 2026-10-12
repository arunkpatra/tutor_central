import Domain
import Foundation
import Supabase

/// `reminder_settings` and `notifications` through the signed-in user (RLS: their own rows). The event lead takes the
/// account's names (`min15`, `min30`, `hour1`, `day_before`).
public struct SupabaseReminderSettingsRepository: ReminderSettingsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    struct Row: Codable {
        var classOn: Bool
        var classMinutes: Int
        var eventsOn: Bool
        var eventLead: String
        var feesOn: Bool
        var feesDay: Int
        var planReadyOn: Bool
        var notesReadyOn: Bool
    }

    struct NextRow: Decodable {
        let subject: String?
        let title: String?
        let dueAt: Date
    }

    static let leads: [ReminderSettings.EventLead: String] = [
        .minutes15: "min15", .minutes30: "min30", .hour1: "hour1", .dayBefore18: "day_before",
    ]

    static func settings(_ row: Row) -> ReminderSettings {
        var settings = ReminderSettings()
        settings.classOn = row.classOn
        settings.classMinutesBefore = row.classMinutes
        settings.eventOn = row.eventsOn
        settings.eventLead = leads.first { $0.value == row.eventLead }?.key ?? .hour1
        settings.feesOn = row.feesOn
        settings.feesDay = row.feesDay
        settings.planReady = row.planReadyOn
        settings.notesReady = row.notesReadyOn
        return settings
    }

    static func row(_ settings: ReminderSettings) -> Row {
        Row(
            classOn: settings.classOn, classMinutes: settings.classMinutesBefore, eventsOn: settings.eventOn,
            eventLead: leads[settings.eventLead] ?? "hour1", feesOn: settings.feesOn, feesDay: settings.feesDay,
            planReadyOn: settings.planReady, notesReadyOn: settings.notesReady
        )
    }

    public func read(centre: UUID) async throws -> ReminderSettings {
        let response = try await client.from("reminder_settings")
            .select("class_on, class_minutes, events_on, event_lead, fees_on, fees_day, plan_ready_on, notes_ready_on")
            .eq("centre_id", value: centre.uuidString).limit(1).execute()
        let rows = try PostgRESTDecoder.make().decode([Row].self, from: response.data)
        return rows.first.map(Self.settings) ?? ReminderSettings()
    }

    public func save(_ settings: ReminderSettings, centre: UUID) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var row = try JSONDecoder().decode([String: AnyJSON].self, from: encoder.encode(Self.row(settings)))
        row["centre_id"] = .string(centre.uuidString.lowercased())
        try await client.from("reminder_settings").upsert(row, onConflict: "centre_id,user_id").execute()
    }

    public func next(centre: UUID) async throws -> NextReminder? {
        let response = try await client.from("notifications").select("subject, title, due_at")
            .eq("centre_id", value: centre.uuidString).eq("state", value: "due")
            .in("kind", values: ["class", "event", "fees"])
            .gte("due_at", value: ISO8601DateFormatter().string(from: Date()))
            .order("due_at").limit(1).execute()
        let rows = try PostgRESTDecoder.make().decode([NextRow].self, from: response.data)
        return rows.first.map { NextReminder(subject: $0.subject ?? $0.title ?? "", at: $0.dueAt) }
    }
}
