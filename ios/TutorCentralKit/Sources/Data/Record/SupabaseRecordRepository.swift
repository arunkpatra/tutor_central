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

    public func marks(centre: UUID, students: [UUID]) async throws -> [MarkRecord] {
        guard !students.isEmpty else { return [] }
        let response = try await client.from("marks").select(MarkRow.columns).eq("centre_id", value: centre)
            .in("student_id", values: students.map { $0.uuidString.lowercased() })
            .order("date", ascending: false).order("created_at", ascending: false).execute()
        return try Self.decoder.decode([MarkRow].self, from: response.data).compactMap(\.record)
    }

    public func addMark(_ mark: NewMark, centre: UUID) async throws -> MarkRecord {
        let response = try await client.from("marks").insert(Self.markValues(mark, centre: centre))
            .select(MarkRow.columns).single().execute()
        guard let record = try Self.decoder.decode(MarkRow.self, from: response.data).record else {
            throw URLError(.cannotParseResponse)
        }
        return record
    }

    public func deleteMark(id: UUID, centre: UUID) async throws {
        try await client.from("marks").delete().eq("centre_id", value: centre).eq("id", value: id).execute()
    }

    static func markValues(_ mark: NewMark, centre: UUID) throws -> [String: AnyJSON] {
        let id = { (uuid: UUID) in AnyJSON.string(uuid.uuidString.lowercased()) }
        var values: [String: AnyJSON] = [
            "centre_id": id(centre), "student_id": id(mark.studentID), "subject": .string(mark.subject),
            "test": .string(String(mark.test.prefix(80))), "date": .string(mark.date.iso),
            "score": .integer(mark.score),
            "max": .integer(mark.max), "photo_path": mark.photoPath.map(AnyJSON.string) ?? .null,
            "school_item_id": mark.schoolItemID.map(id) ?? .null, "artefact_id": mark.artefactID.map(id) ?? .null,
        ]
        if let questions = mark.questions {
            values["questions"] = try JSONDecoder().decode(AnyJSON.self, from: JSONEncoder().encode(questions))
        }
        return values
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
