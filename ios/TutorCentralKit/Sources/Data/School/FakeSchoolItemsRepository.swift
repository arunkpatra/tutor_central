import Domain
import Foundation

/// The in-memory items for tests and the launch states: a scripted error, every add, update and delete.
@MainActor public final class FakeSchoolItemsRepository: SchoolItemsRepository {
    public private(set) var stored: [SchoolItem]
    public var nextError: (any Error)?
    /// When the fake's adds are confirmed.
    public var now: Date
    /// Awaited before the items answer: a test holds the read, as a connection that takes its timeout to fail.
    public var beforeRead: (@MainActor () async -> Void)?

    public init(items: [SchoolItem], now: Date = Date()) {
        stored = items
        self.now = now
    }

    public func items(centre _: UUID) async throws -> [SchoolItem] {
        await beforeRead?()
        try begin()
        return stored.sorted { ($0.date, $0.title) < ($1.date, $1.title) }
    }

    public func item(id: UUID, centre _: UUID) async throws -> SchoolItem? {
        try begin()
        return stored.first { $0.id == id }
    }

    public func add(_ drafts: [SchoolItemDraft], photoPath: String?, centre _: UUID) async throws -> [SchoolItem] {
        try begin()
        let added = drafts.filter { $0.ticked && $0.isComplete }.compactMap { draft -> SchoolItem? in
            guard let audience = draft.audience, let date = draft.date else { return nil }
            return SchoolItem(
                id: UUID(), kind: draft.kind, audience: audience, title: draft.title, subject: draft.subject,
                date: date,
                endDate: draft.endDate, portions: draft.portions, sourceText: draft.sourceText, photoPath: photoPath,
                source: draft.source, receivedAt: draft.receivedAt ?? now, confirmedAt: now
            )
        }
        stored += added
        return added
    }

    public func update(_ item: SchoolItem, centre _: UUID) async throws -> SchoolItem {
        try begin()
        if let index = stored.firstIndex(where: { $0.id == item.id }) {
            stored[index] = item
        }
        return item
    }

    public func delete(id: UUID, centre _: UUID) async throws {
        try begin()
        stored.removeAll { $0.id == id }
    }

    private func begin() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
