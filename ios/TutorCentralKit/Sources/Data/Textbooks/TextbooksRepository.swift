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
}
