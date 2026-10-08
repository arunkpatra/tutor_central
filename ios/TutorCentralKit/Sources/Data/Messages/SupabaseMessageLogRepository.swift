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

    public func feeLogs(centre: UUID, month: Period) async throws -> [FeeLog] {
        let response = try await client.from("message_log").select(Self.feeColumns)
            .eq("centre_id", value: centre).in("kind", values: Self.feeKinds).eq("about_date", value: month.isoDay)
            .order("opened_at", ascending: false).execute()
        return try Self.decoder.decode([FeeLogRow].self, from: response.data).compactMap(\.log)
    }

    public func feeLogs(centre: UUID, student: UUID) async throws -> [FeeLog] {
        let response = try await client.from("message_log").select(Self.feeColumns)
            .eq("centre_id", value: centre).in("kind", values: Self.feeKinds).eq("student_id", value: student)
            .order("opened_at", ascending: false).execute()
        return try Self.decoder.decode([FeeLogRow].self, from: response.data).compactMap(\.log)
    }

    public func logFee(centre: UUID, studentID: UUID, kind: FeeLog.Kind, month: Period) async throws -> FeeLog {
        let response = try await client.from("message_log")
            .insert([
                "centre_id": AnyJSON.string(centre.uuidString),
                "student_id": .string(studentID.uuidString),
                "kind": .string(kind.rawValue),
                "about_date": .string(month.isoDay),
            ])
            .select(Self.feeColumns).single().execute()
        guard let log = try Self.decoder.decode(FeeLogRow.self, from: response.data).log else {
            throw URLError(.cannotParseResponse)
        }
        return log
    }

    private static let feeColumns = "student_id, kind, opened_at, about_date"
    private static let feeKinds = [FeeLog.Kind.reminder, .receipt].map(\.rawValue)
}

/// A reminder or receipt row; nil without a student (deleted), a kind this build knows or a month (`about_date`).
struct FeeLogRow: Decodable {
    let studentId: UUID?
    let kind: String
    let openedAt: Date
    let aboutDate: String?

    var log: FeeLog? {
        guard let studentId, let kind = FeeLog.Kind(rawValue: kind), let month = aboutDate.flatMap(Period.init(isoDay:))
        else { return nil }
        return FeeLog(studentID: studentId, kind: kind, openedAt: openedAt, month: month)
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
