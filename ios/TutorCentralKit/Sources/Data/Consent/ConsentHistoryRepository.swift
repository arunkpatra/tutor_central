import Domain
import Foundation

/// A student's consent history (`consent_events`, members read their centre's; D79), newest first. The events are
/// written by the database: the agreement by 0032's trigger, a withdrawal by `withdraw_consent` (0036).
public protocol ConsentHistoryRepository: Sendable {
    func history(centre: UUID, student: UUID) async throws -> [ConsentEvent]
}
