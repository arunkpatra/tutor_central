import Domain
import Foundation

/// One moment of the tutor's activity: its kind, a screen's name (a tab, a link's kind), when it happened on the phone.
public struct ActivityEvent: Codable, Hashable, Sendable {
    /// The phone's own id for the event, so a post removes exactly what it sent.
    public let id: UUID
    public let kind: ActivityKind
    public let screen: String?
    public let at: Date

    public init(id: UUID = UUID(), kind: ActivityKind, screen: String?, at: Date) {
        self.id = id
        self.kind = kind
        self.screen = screen
        self.at = at
    }
}

/// Where the activity goes: one insert of a batch into `events` (the row's user is the column's default).
public protocol ActivityRepository: Sendable {
    func post(_ events: [ActivityEvent], centre: UUID) async throws
}
