import Domain
import Foundation
import Supabase

public final class SupabaseMessageLogRepository: MessageLogRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "student_id, opened_at, about_date"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func absences(centre: UUID, month: Period) async throws -> [AbsenceLog] {
        let timeZone = DayHeading.india.timeZone
        let formatter = ISO8601DateFormatter()
        // About a day of the month; a row from before migration 0005 counts by the day it was opened.
        let about = "and(about_date.gte.\(month.isoDay),about_date.lte.\(month.next.previousDayISO))"
        let opened = "and(about_date.is.null,opened_at.gte.\(formatter.string(from: month.start(in: timeZone)))," +
            "opened_at.lt.\(formatter.string(from: month.next.start(in: timeZone))))"
        let response = try await client.from("message_log")
            .select(Self.columns)
            .eq("centre_id", value: centre)
            .eq("kind", value: "absence")
            .or("\(about),\(opened)")
            .order("opened_at", ascending: false)
            .execute()
        return try Self.decoder.decode([LogRow].self, from: response.data).compactMap(\.log)
    }

    public func logAbsence(centre: UUID, studentID: UUID, about: Day) async throws -> AbsenceLog {
        let response = try await client.from("message_log")
            .insert([
                "centre_id": AnyJSON.string(centre.uuidString),
                "student_id": .string(studentID.uuidString),
                "kind": .string("absence"),
                "about_date": .string(about.iso),
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
    let aboutDate: String?

    var log: AbsenceLog? {
        studentId.map { AbsenceLog(studentID: $0, openedAt: openedAt, aboutDate: aboutDate.flatMap(Day.init(iso:))) }
    }
}
