import Domain
import Foundation
import Supabase

/// The register through PostgREST: RLS scopes everything to the member's centre; the centre id is still sent so an
/// index serves the read.
public final class SupabaseStudentsRepository: StudentsRepository {
    private let client: SupabaseClient
    private let calendar: Calendar
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, name, class_id, monthly_fee, parent_name, parent_phone, date_of_birth, gender, "
        + "notes, archived_at, class_level, school_id, board, message_language, consent_at, consent_phone, "
        + "consent_how, track_status, track_reasons, track_since, created_at"

    public init(client: SupabaseClient, calendar: Calendar = DayHeading.india) {
        self.client = client
        self.calendar = calendar
    }

    public func students(centre: UUID, period: Period) async throws -> [Student] {
        let response = try await client.from("students")
            .select("\(Self.columns), fee_invoices(amount, status, paid_at, paid_method)")
            .eq("centre_id", value: centre)
            .eq("fee_invoices.period", value: period.isoDay)
            .order("name")
            .execute()
        return try Self.decoder.decode([StudentRow].self, from: response.data).map { $0.student(calendar: calendar) }
    }

    public func create(_ draft: StudentDraft, centre: UUID) async throws -> Student {
        var values = Self.values(draft)
        values["centre_id"] = .string(centre.uuidString)
        let response = try await client.from("students").insert(values).select(Self.columns).single().execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    public func update(id: UUID, with draft: StudentDraft) async throws -> Student {
        let response = try await client.from("students").update(Self.values(draft)).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    public func setArchived(id: UUID, _ archived: Bool) async throws {
        let value: AnyJSON = archived ? .string(ISO8601DateFormatter().string(from: Date())) : .null
        try await client.from("students").update(["archived_at": value]).eq("id", value: id).execute()
    }

    public func delete(id: UUID) async throws {
        try await client.from("students").delete().eq("id", value: id).execute()
    }

    public func assign(studentIDs: [UUID], toClass classID: UUID?, centre: UUID) async throws {
        guard !studentIDs.isEmpty else { return }
        try await client.from("students")
            .update(["class_id": classID.map { AnyJSON.string($0.uuidString) } ?? .null])
            .eq("centre_id", value: centre)
            .in("id", values: studentIDs.map(\.uuidString))
            .execute()
    }

    public func createMany(_ drafts: [StudentDraft], centre: UUID) async throws -> [Student] {
        guard !drafts.isEmpty else { return [] }
        let rows = drafts.map { draft in
            var values = Self.values(draft)
            values["centre_id"] = .string(centre.uuidString)
            return values
        }
        let response = try await client.from("students").insert(rows).select(Self.columns).execute()
        return try Self.decoder.decode([StudentRow].self, from: response.data).map { $0.student(calendar: calendar) }
    }

    public func deleteMany(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        try await client.from("students").delete().in("id", values: ids.map(\.uuidString)).execute()
    }

    public func updateNotes(id: UUID, notes: String?) async throws -> Student {
        let response = try await client.from("students")
            .update(["notes": notes.map(AnyJSON.string) ?? .null])
            .eq("id", value: id)
            .select(Self.columns)
            .single()
            .execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    public func setConsent(id: UUID, _ consent: ConsentRecord?) async throws -> Student {
        let response = try await client.from("students").update(Self.consentValues(consent)).eq("id", value: id)
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(StudentRow.self, from: response.data).student(calendar: calendar)
    }

    /// The three consent columns, or three nulls to clear them (plan decision 13).
    static func consentValues(_ consent: ConsentRecord?) -> [String: AnyJSON] {
        [
            "consent_at": consent.map { .string(ISO8601DateFormatter().string(from: $0.at)) } ?? .null,
            "consent_phone": consent.map { .string($0.phone.e164) } ?? .null,
            "consent_how": consent.map { .string($0.how.rawValue) } ?? .null,
        ]
    }

    /// Every column the form owns, nulls included, so an edit clears what the tutor cleared. The board is kept from
    /// class 8 only.
    static func values(_ draft: StudentDraft) -> [String: AnyJSON] {
        let board = draft.classLevel?.expectsBoard == true ? draft.board : nil
        return [
            "name": .string(draft.trimmedName),
            "class_id": draft.classID.map { .string($0.uuidString) } ?? .null,
            "monthly_fee": draft.fee.map { .integer($0.rupees) } ?? .null,
            "parent_name": draft.trimmedParentName.map(AnyJSON.string) ?? .null,
            "parent_phone": draft.parentPhone.map { .string($0.e164) } ?? .null,
            "date_of_birth": draft.dateOfBirth.map { .string($0.iso) } ?? .null,
            "gender": draft.gender.map { .string($0.rawValue) } ?? .null,
            "notes": draft.trimmedNotes.map(AnyJSON.string) ?? .null,
            "class_level": draft.classLevel.map { .string($0.rawValue) } ?? .null,
            "school_id": draft.schoolID.map { .string($0.uuidString.lowercased()) } ?? .null,
            "board": board.map { .string($0.rawValue) } ?? .null,
            "message_language": .string(draft.messageLanguage.rawValue),
        ]
    }
}

/// A notes update's answer when only the notes are asked for.
struct NotesRow: Decodable {
    let id: UUID
    let notes: String?
}
