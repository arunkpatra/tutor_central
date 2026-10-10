import Foundation

/// The placement taken from a student's page (P10-Placement), written in one call by `record_placement` (migration
/// 0017): its answers as placement checks, the skills it made secure, and the status worked out with them.
public struct PlacementRecord: Hashable, Sendable {
    public let studentID: UUID
    public let checks: [SessionClose.Check]
    public let states: [SkillStateChange]
    public let track: SessionClose.Track?

    public init(studentID: UUID, checks: [SessionClose.Check], states: [SkillStateChange], track: SessionClose.Track?) {
        self.studentID = studentID
        self.checks = checks
        self.states = states
        self.track = track
    }
}
