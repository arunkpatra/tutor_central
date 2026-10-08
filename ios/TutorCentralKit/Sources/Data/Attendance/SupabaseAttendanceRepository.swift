import Domain
import Foundation
import Supabase

public final class SupabaseAttendanceRepository: AttendanceRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, class_id, date, saved_at, attendance_marks(student_id, status)"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession] {
        let response = try await client.from("attendance_sessions")
            .select(Self.columns)
            .eq("centre_id", value: centre)
            .gte("date", value: month.isoDay)
            .lte("date", value: month.next.previousDayISO)
            .order("date", ascending: false)
            .execute()
        return try Self.decoder.decode([SessionRow].self, from: response.data).map(\.session)
    }

    public func save(
        centre: UUID,
        classID: UUID?,
        date: Day,
        marks: [UUID: AttendanceStatus]
    ) async throws -> AttendanceSession {
        let response = try await client.rpc("save_attendance", params: [
            "p_centre": AnyJSON.string(centre.uuidString),
            "p_class": classID.map { .string($0.uuidString) } ?? .null,
            "p_date": .string(date.iso),
            "p_marks": Self.marksJSON(marks),
        ]).execute()
        let id = try Self.decoder.decode(UUID.self, from: response.data)
        // The row as saved: its saved_at is the server's clock.
        let row = try await client.from("attendance_sessions").select(Self.columns).eq("id", value: id).single()
            .execute()
        return try Self.decoder.decode(SessionRow.self, from: row.data).session
    }

    static func marksJSON(_ marks: [UUID: AttendanceStatus]) -> AnyJSON {
        .object(Dictionary(uniqueKeysWithValues: marks.map { (
            $0.key.uuidString.lowercased(),
            AnyJSON.string($0.value.rawValue)
        ) }))
    }
}
