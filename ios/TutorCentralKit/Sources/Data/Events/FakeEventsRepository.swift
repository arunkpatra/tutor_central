import Domain
import Foundation

/// The in-memory schedule for tests, previews and `bun shots`: the two events the boards draw, a scripted error, a
/// delay, a record of every write.
@MainActor public final class FakeEventsRepository: EventsRepository {
    public nonisolated static let parentsMeeting = CalendarEvent(
        id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000001")!, title: "Parents' meeting",
        date: Day(year: 2026, month: 10, day: 10)!, startTime: TimeOfDay(hour: 11, minute: 0), endTime: TimeOfDay(
            hour: 12,
            minute: 0
        ),
        note: "Class 10 parents. Bring the September test papers."
    )
    public nonisolated static let mockTest = CalendarEvent(
        id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000002")!, title: "Mock test, Class 10",
        date: Day(year: 2026, month: 10, day: 17)!, startTime: TimeOfDay(hour: 10, minute: 0), endTime: TimeOfDay(
            hour: 12,
            minute: 0
        ), note: nil
    )
    public nonisolated static let seed = [parentsMeeting, mockTest]

    public var events: [CalendarEvent]
    public var nextError: (any Error)?
    public var delay: Duration?
    public private(set) var created: [EventDraft] = []
    public private(set) var updated: [UUID] = []
    public private(set) var deleted: [UUID] = []

    public init(events: [CalendarEvent] = []) {
        self.events = events
    }

    public func events(centre _: UUID, from: Day, to: Day) async throws -> [CalendarEvent] {
        try await begin()
        // As the read orders: by date, then start time with a timeless event first.
        return events.filter { $0.date >= from && $0.date <= to }.sorted { lhs, rhs in
            lhs.date != rhs.date ? lhs.date < rhs.date : Self.minute(lhs.startTime) < Self.minute(rhs.startTime)
        }
    }

    public func create(_ draft: EventDraft, centre _: UUID) async throws -> CalendarEvent {
        try await begin()
        created.append(draft)
        let made = CalendarEvent(
            id: UUID(),
            title: draft.trimmedTitle,
            date: draft.date,
            startTime: draft.startTime,
            endTime: draft.endTime,
            note: draft.trimmedNote
        )
        events.append(made)
        return made
    }

    public func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent {
        try await begin()
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        updated.append(id)
        events[index] = CalendarEvent(
            id: id,
            title: draft.trimmedTitle,
            date: draft.date,
            startTime: draft.startTime,
            endTime: draft.endTime,
            note: draft.trimmedNote
        )
        return events[index]
    }

    public func delete(id: UUID) async throws {
        try await begin()
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        deleted.append(id)
        events.remove(at: index)
    }

    private static func minute(_ time: TimeOfDay?) -> Int {
        time.map { $0.hour * 60 + $0.minute } ?? -1
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
