import Domain
import Foundation

/// Textbooks captured once per school, class and subject, and each student's copy of their chapters and skills (D58).
/// RLS keeps every call inside the member's centre.
public protocol TextbooksRepository: Sendable {
    func textbooks(centre: UUID) async throws -> [Textbook]
    /// One row per school, class and subject; a second capture for the same three replaces the chapters.
    func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook
    /// `copy_textbook_chapters` (migration 0009): the book's chapters and skills to the student, replacing what came
    /// from this book before and keeping the rest.
    func copyChapters(of textbookID: UUID, to studentID: UUID, centre: UUID) async throws
    func chapters(student: UUID) async throws -> [Chapter]
    func skills(student: UUID) async throws -> [Skill]
    func setState(skillID: UUID, _ state: SkillState) async throws
    /// `copy_textbook_to_class` (migration 0017): Keep copies the book to every active student of its school and
    /// class; the count copied to.
    func copyToClass(textbookID: UUID, centre: UUID) async throws -> Int
    /// `copy_textbooks_to_student` (migration 0017): a student saved with a school and class gets every book of that
    /// school and class; the count of books.
    func copyAll(to studentID: UUID, centre: UUID) async throws -> Int
    /// A chapter of the tutor's own, after the subject's last, with its skills in order.
    func addChapter(student: UUID, subject: String, name: String, skills: [String], centre: UUID) async throws
        -> Chapter
    /// The ladder's three chapters (Reading, Writing, Numbers) with their five steps, for a student of LKG to class 3
    /// who has none yet; nothing when they exist.
    func ensureLadder(student: UUID, centre: UUID) async throws
}
