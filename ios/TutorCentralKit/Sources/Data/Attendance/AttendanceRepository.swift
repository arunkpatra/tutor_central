import Domain
import Foundation

/// Saved attendance. RLS keeps every call inside the member's centre.
public protocol AttendanceRepository: Sendable {
    /// Every session of the month with its marks, newest first.
    func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession]
    /// `save_attendance` (migration 0004): the session is made or found and its marks replaced.
    func save(centre: UUID, classID: UUID?, date: Day, marks: [UUID: AttendanceStatus]) async throws
        -> AttendanceSession
}
