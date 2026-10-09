import Foundation

/// A list's copy and the time it was saved.
public struct CachedValue<Value: Codable & Sendable>: Codable, Sendable {
    public let value: Value
    public let savedAt: Date

    public init(value: Value, savedAt: Date) {
        self.value = value
        self.savedAt = savedAt
    }
}

/// One list's copy on this iPhone (D39): Application Support/TutorCentral/cache-<centre>-<key>.json, shown at once
/// while the network refreshes it and offline with its age.
public struct CachedRead<Value: Codable & Sendable>: Sendable {
    private let cache: JSONCache<CachedValue<Value>>

    public init(centre: UUID, key: String, directory: URL? = nil) {
        cache = JSONCache(name: "cache-\(centre.uuidString.lowercased())-\(key)", directory: directory)
    }

    public func load() -> CachedValue<Value>? {
        cache.load()
    }

    /// Never throws: a cache is a convenience.
    public func keep(_ value: Value, at: Date) {
        try? cache.save(CachedValue(value: value, savedAt: at))
    }

    public func remove() {
        cache.remove()
    }
}
