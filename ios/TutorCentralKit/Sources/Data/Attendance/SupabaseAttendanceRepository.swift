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

    public func close(_ close: SessionClose, centre: UUID) async throws -> UUID {
        let response = try await client.rpc("close_session", params: Self.closeParams(close, centre: centre)).execute()
        return try Self.decoder.decode(UUID.self, from: response.data)
    }

    static func closeParams(_ close: SessionClose, centre: UUID) -> [String: AnyJSON] {
        let id = { (uuid: UUID) in AnyJSON.string(uuid.uuidString.lowercased()) }
        let checks: [AnyJSON] = close.checks.map { check in
            .object([
                "student_id": id(check.studentID),
                "skill_id": id(check.skillID),
                "question": .object(["text": .string(check.question)]),
                "correct": .bool(check.correct),
                "kind": .string(check.isPlacement ? "placement" : "check"),
            ])
        }
        let homework: [AnyJSON] = close.homework.map { item in
            var values: [String: AnyJSON] = ["student_id": id(item.studentID), "status": .string("given")]
            if let artefact = item.artefactID {
                values["artefact_id"] = id(artefact)
            }
            return .object(values)
        }
        let track = Dictionary(uniqueKeysWithValues: close.track.map { student, track in
            (student.uuidString.lowercased(), AnyJSON.object([
                "status": .string(track.status.rawValue),
                "reasons": .array(track.reasons.map(AnyJSON.string)),
            ]))
        })
        return [
            "p_centre": id(centre),
            "p_class": close.classID.map(id) ?? .null,
            "p_date": .string(close.date.iso),
            "p_marks": marksJSON(close.marks),
            "p_checks": .array(checks),
            "p_homework": .array(homework),
            "p_track": .object(track),
            "p_states": statesJSON(close.states),
        ]
    }

    /// The skill states the app worked out: `[{"skill_id", "state"}]` (migration 0017).
    static func statesJSON(_ states: [SkillStateChange]) -> AnyJSON {
        .array(states.map { change in
            .object([
                "skill_id": .string(change.skillID.uuidString.lowercased()),
                "state": .string(change.state.rawValue),
            ])
        })
    }

    static func marksJSON(_ marks: [UUID: AttendanceStatus]) -> AnyJSON {
        .object(Dictionary(uniqueKeysWithValues: marks.map { (
            $0.key.uuidString.lowercased(),
            AnyJSON.string($0.value.rawValue)
        ) }))
    }
}
