import Domain
import Foundation

/// The centre's students. RLS keeps every call inside the member's centre.
public protocol StudentsRepository: Sendable {
    /// Every student of the centre, archived included, each with this month's invoice (amount, status, paid day and
    /// method) when there is one.
    func students(centre: UUID, period: Period) async throws -> [Student]
    func create(_ draft: StudentDraft, centre: UUID) async throws -> Student
    func update(id: UUID, with draft: StudentDraft) async throws -> Student
    func setArchived(id: UUID, _ archived: Bool) async throws
    /// The foreign keys take the student's invoices and attendance with them (migration 0001).
    func delete(id: UUID) async throws
    /// One statement: these students move to the class (nil: to no class).
    func assign(studentIDs: [UUID], toClass classID: UUID?, centre: UUID) async throws
}
