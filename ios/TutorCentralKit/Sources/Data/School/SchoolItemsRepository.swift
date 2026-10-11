import Domain
import Foundation

/// What the school sent, as the tutor kept it (`school_items`, migrations 0011 and 0021). RLS keeps every call inside
/// the member's centre.
public protocol SchoolItemsRepository: Sendable {
    /// The centre's items, by date then title.
    func items(centre: UUID) async throws -> [SchoolItem]
    func item(id: UUID, centre: UUID) async throws -> SchoolItem?
    /// Add on "Check what was read" (plan/phase-13-plan.md decision 1): the complete, ticked drafts in one insert with
    /// `confirmed_at` set; the items back.
    func add(_ drafts: [SchoolItemDraft], photoPath: String?, centre: UUID) async throws -> [SchoolItem]
    func update(_ item: SchoolItem, centre: UUID) async throws -> SchoolItem
    func delete(id: UUID, centre: UUID) async throws
}

/// The tab's copy on this iPhone (D39): `cache-<centre>-school.json`.
public struct SchoolCache: Sendable {
    private let read: CachedRead<[SchoolItem]>

    public init(centre: UUID, directory: URL? = nil) {
        read = CachedRead(centre: centre, key: "school", directory: directory)
    }

    public func load() -> CachedValue<[SchoolItem]>? {
        read.load()
    }

    public func keep(_ items: [SchoolItem], at: Date) {
        read.keep(items, at: at)
    }
}
