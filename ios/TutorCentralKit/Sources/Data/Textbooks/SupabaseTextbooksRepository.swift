import Domain
import Foundation
import Supabase

public final class SupabaseTextbooksRepository: TextbooksRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, school_id, class_level, subject, title, publisher, edition, chapters"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func textbooks(centre: UUID) async throws -> [Textbook] {
        let response = try await client.from("textbooks").select(Self.columns).eq("centre_id", value: centre)
            .order("subject").execute()
        return try Self.decoder.decode([TextbookRow].self, from: response.data).map(\.textbook)
    }

    public func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook {
        let response = try await client.from("textbooks")
            .upsert(Self.values(textbook, centre: centre), onConflict: "centre_id,school_id,class_level,subject")
            .select(Self.columns).single().execute()
        return try Self.decoder.decode(TextbookRow.self, from: response.data).textbook
    }

    public func copyChapters(of textbookID: UUID, to studentID: UUID, centre: UUID) async throws {
        try await client.rpc("copy_textbook_chapters", params: [
            "p_centre": AnyJSON.string(centre.uuidString.lowercased()),
            "p_textbook": .string(textbookID.uuidString.lowercased()),
            "p_student": .string(studentID.uuidString.lowercased()),
        ]).execute()
    }

    public func chapters(student: UUID) async throws -> [Chapter] {
        let response = try await client.from("chapters").select("id, subject, position, name, ladder")
            .eq("student_id", value: student).order("subject").order("position").execute()
        return try Self.decoder.decode([ChapterRow].self, from: response.data).map(\.chapter)
    }

    public func skills(student: UUID) async throws -> [Skill] {
        let response = try await client.from("skills")
            .select("id, chapter_id, position, name, state, state_at, last_checked_at")
            .eq("student_id", value: student).order("position").execute()
        return try Self.decoder.decode([SkillRow].self, from: response.data).map(\.skill)
    }

    public func setState(skillID: UUID, _ state: SkillState) async throws {
        // "now" is Postgres's word for the server's clock, as saved_at is.
        try await client.from("skills").update(["state": AnyJSON.string(state.rawValue), "state_at": .string("now")])
            .eq("id", value: skillID).execute()
    }

    /// The row as the database takes it; the id is the database's on a first capture.
    static func values(_ textbook: Textbook, centre: UUID) -> [String: AnyJSON] {
        let chapters: [AnyJSON] = textbook.chapters.map { chapter in
            .object([
                "position": .integer(chapter.position),
                "name": .string(chapter.name),
                "skills": .array(chapter.skills.map(AnyJSON.string)),
            ])
        }
        return [
            "centre_id": .string(centre.uuidString.lowercased()),
            "school_id": .string(textbook.schoolID.uuidString.lowercased()),
            "class_level": .string(textbook.classLevel.rawValue),
            "subject": .string(textbook.subject),
            "title": .string(textbook.title),
            "publisher": textbook.publisher.map(AnyJSON.string) ?? .null,
            "edition": textbook.edition.map(AnyJSON.string) ?? .null,
            "chapters": .array(chapters),
        ]
    }
}
