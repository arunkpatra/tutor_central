import Domain
import Foundation
import Supabase

public final class SupabaseMessageLogRepository: MessageLogRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "student_id, opened_at"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func absences(centre: UUID, month: Period) async throws -> [AbsenceLog] {
        let timeZone = DayHeading.india.timeZone
        let formatter = ISO8601DateFormatter()
        let response = try await client.from("message_log")
            .select(Self.columns)
            .eq("centre_id", value: centre)
            .eq("kind", value: "absence")
            .gte("opened_at", value: formatter.string(from: month.start(in: timeZone)))
            .lt("opened_at", value: formatter.string(from: month.next.start(in: timeZone)))
            .order("opened_at", ascending: false)
            .execute()
        return try Self.decoder.decode([LogRow].self, from: response.data).compactMap(\.log)
    }

    public func logAbsence(centre: UUID, studentID: UUID) async throws -> AbsenceLog {
        let response = try await client.from("message_log")
            .insert([
                "centre_id": AnyJSON.string(centre.uuidString),
                "student_id": .string(studentID.uuidString),
                "kind": .string("absence"),
            ])
            .select(Self.columns).single().execute()
        guard let log = try Self.decoder.decode(LogRow.self, from: response.data).log else {
            throw URLError(.cannotParseResponse)
        }
        return log
    }
}

/// A `message_log` row. `student_id` is null once its student is deleted (the log stays); such a row tells no one.
struct LogRow: Decodable {
    let studentId: UUID?
    let openedAt: Date

    var log: AbsenceLog? {
        studentId.map { AbsenceLog(studentID: $0, openedAt: openedAt) }
    }
}
