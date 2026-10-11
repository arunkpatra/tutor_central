import Domain
import Foundation

/// The week's kept notes on this iPhone (`cache-<centre>-notes.json`, plan/phase-14-plan.md decision 21), so a note
/// made earlier opens offline; wiped with the centre's other files (`Wipe`).
public struct NotesCache: Sendable {
    private let cache: JSONCache<[Artefact]>

    public init(centre: UUID, directory: URL? = nil) {
        cache = JSONCache(name: "cache-\(centre.uuidString.lowercased())-notes", directory: directory)
    }

    public var url: URL {
        cache.url
    }

    public func keep(_ notes: [Artefact]) throws {
        try cache.save(notes)
    }

    /// The notes kept; none when the file is missing or unreadable.
    public func read() -> [Artefact] {
        cache.load() ?? []
    }
}
