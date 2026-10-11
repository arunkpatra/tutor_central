import Domain
import Foundation

/// The record's reads and writes outside the close (docs/spec-v2.md section 5): the checks and homework the page, the
/// trend and the rules read; a homework's status; the placement. RLS keeps every call inside the member's centre.
public protocol RecordRepository: Sendable {
    /// The students' checks since a moment, oldest first (the trend and the rules).
    func checks(centre: UUID, students: [UUID], since: Date) async throws -> [CheckRecord]
    /// The students' homework since a moment, newest first.
    func homework(centre: UUID, students: [UUID], since: Date) async throws -> [HomeworkRecord]
    func setHomeworkStatus(id: UUID, _ status: HomeworkStatus) async throws
    /// `record_placement` (migration 0017): the placement's checks, the states and the status in one write.
    func recordPlacement(_ placement: PlacementRecord, centre: UUID) async throws
    /// The students' marks, newest first (the page's Marks, below usual).
    func marks(centre: UUID, students: [UUID]) async throws -> [MarkRecord]
    /// A marked mock's or a checked paper's mark (Phase 13).
    func addMark(_ mark: NewMark, centre: UUID) async throws -> MarkRecord
    /// Undo after a marking's Save.
    func deleteMark(id: UUID, centre: UUID) async throws
}
