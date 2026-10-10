import Foundation

/// Where a student is with a skill (`skill_state`, migration 0009).
public enum SkillState: String, CaseIterable, Hashable, Sendable, Codable {
    case notStarted = "not_started", taught, practising, secure, revisit
}

/// A student's chapter of a subject: from a textbook, the board's syllabus, the tutor, or the ladder.
public struct Chapter: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var subject: String
    public var position: Int
    public var name: String
    /// Set for the ladder's chapters (LKG to class 3).
    public var ladder: Ladder.Area?

    public init(id: UUID, subject: String, position: Int, name: String, ladder: Ladder.Area? = nil) {
        self.id = id
        self.subject = subject
        self.position = position
        self.name = name
        self.ladder = ladder
    }
}

public struct Skill: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let chapterID: UUID
    public var position: Int
    public var name: String
    public var state: SkillState
    public var stateAt: Date
    public var lastCheckedAt: Date?

    public init(
        id: UUID,
        chapterID: UUID,
        position: Int,
        name: String,
        state: SkillState,
        stateAt: Date,
        lastCheckedAt: Date?
    ) {
        self.id = id
        self.chapterID = chapterID
        self.position = position
        self.name = name
        self.state = state
        self.stateAt = stateAt
        self.lastCheckedAt = lastCheckedAt
    }
}
