import Foundation

/// What was shared: a forwarded message's text, or one photo.
public enum SharedItemKind: String, Decodable, Sendable { case text, image }

/// What the share extension left in the app group (`Share/ShareViewController.swift`): one JSON file per item in
/// `inbox/`, an image beside its item. The School tab reads it on foreground from Phase 13; in Phase 10 nothing reads
/// it.
public struct SharedInbox: Sendable {
    public struct Item: Decodable, Hashable, Sendable {
        public let kind: SharedItemKind
        public let text: String?
        /// The image's file name in `inbox/`.
        public let file: String?
        public let receivedAt: Date
    }

    public static let groupID = "group.in.tutorcentral"
    private let container: URL

    public init(container: URL) {
        self.container = container
    }

    public static func live() -> SharedInbox? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
            .map(SharedInbox.init(container:))
    }

    /// The items in the order they arrived, left in place; a file that is not an item is passed over.
    public func items() throws -> [Item] {
        let inbox = container.appendingPathComponent("inbox")
        guard FileManager.default.fileExists(atPath: inbox.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { url in try? decoder.decode(Item.self, from: Data(contentsOf: url)) }
            .sorted { $0.receivedAt < $1.receivedAt }
    }
}
