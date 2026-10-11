import Domain
import Foundation

/// A `textbooks` row. The chapters are kept on the row as read from the contents page, so a student who joins the
/// class later gets the same list; the `chapters` and `skills` tables hold each student's copy.
struct TextbookRow: Decodable {
    let id: UUID
    let schoolId: UUID
    let classLevel: ClassLevel
    let subject: String
    let title: String
    let publisher: String?
    let edition: String?
    let chapters: [TextbookChapter]

    var textbook: Textbook {
        Textbook(
            id: id, schoolID: schoolId, classLevel: classLevel, subject: subject, title: title,
            publisher: publisher, edition: edition, chapters: chapters
        )
    }
}

/// A student's `chapters` row.
struct ChapterRow: Decodable {
    let id: UUID
    let subject: String
    let position: Int
    let name: String
    let ladder: Ladder.Area?

    var chapter: Chapter {
        Chapter(id: id, subject: subject, position: position, name: name, ladder: ladder)
    }
}

/// A student's `skills` row.
struct SkillRow: Decodable {
    static let columns = "id, chapter_id, position, name, state, state_at, last_checked_at"
    let id: UUID
    let chapterId: UUID
    let position: Int
    let name: String
    let state: SkillState
    let stateAt: Date
    let lastCheckedAt: Date?

    var skill: Skill {
        Skill(
            id: id, chapterID: chapterId, position: position, name: name, state: state, stateAt: stateAt,
            lastCheckedAt: lastCheckedAt
        )
    }
}

/// A chapter's position alone (the tutor's own chapter goes after the last).
struct PositionRow: Decodable {
    let position: Int
}

/// A row read with its `student_id` beside its own columns (a read across students).
struct Owned<Row: Decodable>: Decodable {
    let studentId: UUID
    let row: Row

    private enum Keys: String, CodingKey { case studentId }

    init(from decoder: any Decoder) throws {
        studentId = try decoder.container(keyedBy: Keys.self).decode(UUID.self, forKey: .studentId)
        row = try Row(from: decoder)
    }
}
