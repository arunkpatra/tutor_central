import Domain
import Foundation
import Supabase

public final class SupabaseRecordRepository: RecordRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func checks(centre: UUID, students: [UUID], since: Date) async throws -> [CheckRecord] {
        guard !students.isEmpty else { return [] }
        let response = try await client.from("checks")
            .select("id, student_id, skill_id, session_id, kind, question, correct, created_at")
            .eq("centre_id", value: centre)
            .in("student_id", values: students.map { $0.uuidString.lowercased() })
            .gte("created_at", value: ISO8601DateFormatter().string(from: since))
            .order("created_at")
            .execute()
        return try Self.decoder.decode([CheckRow].self, from: response.data).map(\.record)
    }

    public func homework(centre: UUID, students: [UUID], since: Date) async throws -> [HomeworkRecord] {
        guard !students.isEmpty else { return [] }
        let response = try await client.from("homework")
            .select("id, student_id, session_id, given_at, status, artefact_id")
            .eq("centre_id", value: centre)
            .in("student_id", values: students.map { $0.uuidString.lowercased() })
            .gte("given_at", value: ISO8601DateFormatter().string(from: since))
            .order("given_at", ascending: false)
            .execute()
        return try Self.decoder.decode([HomeworkRow].self, from: response.data).map(\.record)
    }

    public func setHomeworkStatus(id: UUID, _ status: HomeworkStatus) async throws {
        try await client.from("homework").update(["status": AnyJSON.string(status.rawValue)]).eq("id", value: id)
            .execute()
    }

    public func recordPlacement(_ placement: PlacementRecord, centre: UUID) async throws {
        try await client.rpc("record_placement", params: Self.placementParams(placement, centre: centre)).execute()
    }

    /// The checks as `close_session` takes them with the kind always `placement`, the states, and the student's status
    /// or `{}` (nothing stored).
    static func placementParams(_ placement: PlacementRecord, centre: UUID) -> [String: AnyJSON] {
        let id = { (uuid: UUID) in AnyJSON.string(uuid.uuidString.lowercased()) }
        let checks: [AnyJSON] = placement.checks.map { check in
            .object([
                "student_id": id(check.studentID),
                "skill_id": id(check.skillID),
                "question": .object(["text": .string(check.question)]),
                "correct": .bool(check.correct),
                "kind": .string("placement"),
            ])
        }
        let track: AnyJSON = placement.track.map { track in
            .object(["status": .string(track.status.rawValue), "reasons": .array(track.reasons.map(AnyJSON.string))])
        } ?? .object([:])
        return [
            "p_centre": id(centre),
            "p_student": id(placement.studentID),
            "p_checks": .array(checks),
            "p_states": SupabaseAttendanceRepository.statesJSON(placement.states),
            "p_track": track,
        ]
    }
}
