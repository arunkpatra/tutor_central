import Domain
import Foundation

/// The schedule's events. RLS keeps every call inside the member's centre.
public protocol EventsRepository: Sendable {
    /// Events from `from` to `to` inclusive, by date then start time (a timeless one first).
    func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent]
    func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent
    func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent
    func delete(id: UUID) async throws
}
