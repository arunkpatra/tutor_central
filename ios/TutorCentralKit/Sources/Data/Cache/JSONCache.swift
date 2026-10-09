import Foundation

/// One Codable value in one file under Application Support/TutorCentral (or the directory given), so a list shows at
/// once on the next launch while the network refreshes it. Dates as ISO 8601.
public struct JSONCache<Value: Codable & Sendable>: Sendable {
    public let url: URL

    /// `directory` nil: Application Support/TutorCentral.
    public init(name: String, directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        url = base.appendingPathComponent("\(name).json")
    }

    /// Nil when missing or unreadable; never throws: a cache is a convenience.
    public func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? Self.decoder.decode(Value.self, from: data)
    }

    /// Creates the directory and writes atomically, readable only once the iPhone has been unlocked since it started
    /// (D40).
    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.encoder.encode(value).write(
            to: url,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    /// Made per use: `JSONDecoder` is not `Sendable`, and nothing mutable is global (D8).
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
