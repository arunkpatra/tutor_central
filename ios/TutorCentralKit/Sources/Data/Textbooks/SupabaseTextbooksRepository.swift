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

    public func copyToClass(textbookID: UUID, centre: UUID) async throws -> Int {
        try await client.rpc("copy_textbook_to_class", params: [
            "p_centre": AnyJSON.string(centre.uuidString.lowercased()),
            "p_textbook": .string(textbookID.uuidString.lowercased()),
        ]).execute().value
    }

    public func copyAll(to studentID: UUID, centre: UUID) async throws -> Int {
        try await client.rpc("copy_textbooks_to_student", params: [
            "p_centre": AnyJSON.string(centre.uuidString.lowercased()),
            "p_student": .string(studentID.uuidString.lowercased()),
        ]).execute().value
    }

    public func addChapter(student: UUID, subject: String, name: String, skills: [String], centre: UUID) async throws
        -> Chapter {
        let last = try await client.from("chapters").select("position").eq("student_id", value: student)
            .eq("subject", value: subject).order("position", ascending: false).limit(1).execute()
        let position = try (Self.decoder.decode([PositionRow].self, from: last.data).first?.position ?? 0) + 1
        let values: [String: AnyJSON] = [
            "centre_id": .string(centre.uuidString.lowercased()),
            "student_id": .string(student.uuidString.lowercased()),
            "subject": .string(subject),
            "position": .integer(position),
            "name": .string(name),
        ]
        let response = try await client.from("chapters").insert(values).select("id, subject, position, name, ladder")
            .single().execute()
        let chapter = try Self.decoder.decode(ChapterRow.self, from: response.data).chapter
        if !skills.isEmpty {
            try await client.from("skills").insert(Self.skillRows(
                skills,
                chapter: chapter.id,
                student: student,
                centre: centre
            )).execute()
        }
        return chapter
    }

    public func ensureLadder(student: UUID, centre: UUID) async throws {
        let existing = try await client.from("chapters").select("id, subject, position, name, ladder")
            .eq("student_id", value: student).not("ladder", operator: .is, value: AnyJSON.null).execute()
        let have = try Set(Self.decoder.decode([ChapterRow].self, from: existing.data).compactMap(\.chapter.ladder))
        let missing = Self.ladderChapters(student: student, centre: centre).filter { row in
            guard case let .string(area)? = row["ladder"],
                  let ladder = Ladder.Area(rawValue: area) else { return false }
            return !have.contains(ladder)
        }
        guard !missing.isEmpty else { return }
        let response = try await client.from("chapters").insert(missing).select("id, subject, position, name, ladder")
            .execute()
        let made = try Self.decoder.decode([ChapterRow].self, from: response.data).map(\.chapter)
        let skills = made.flatMap { chapter in
            Self.skillRows(chapter.ladder?.steps ?? [], chapter: chapter.id, student: student, centre: centre)
        }
        try await client.from("skills").insert(skills).execute()
    }

    /// One chapter per ladder area, its subject and name the area's title (migration 0009's rule: one per student and
    /// area).
    static func ladderChapters(student: UUID, centre: UUID) -> [[String: AnyJSON]] {
        Ladder.Area.allCases.map { area in
            [
                "centre_id": .string(centre.uuidString.lowercased()),
                "student_id": .string(student.uuidString.lowercased()),
                "subject": .string(area.title),
                "position": .integer(1),
                "name": .string(area.title),
                "ladder": .string(area.rawValue),
            ]
        }
    }

    static func skillRows(_ names: [String], chapter: UUID, student: UUID, centre: UUID) -> [[String: AnyJSON]] {
        names.enumerated().map { index, name in
            [
                "centre_id": .string(centre.uuidString.lowercased()),
                "chapter_id": .string(chapter.uuidString.lowercased()),
                "student_id": .string(student.uuidString.lowercased()),
                "position": .integer(index + 1),
                "name": .string(name),
            ]
        }
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
