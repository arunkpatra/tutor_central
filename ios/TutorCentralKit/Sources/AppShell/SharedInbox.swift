import Foundation

/// What was shared: a forwarded message's text, or one photo.
public enum SharedItemKind: String, Decodable, Sendable { case text, image }

/// The keys the extension writes; the id is the file's name, not a key.
private enum InboxItemKeys: String, CodingKey { case kind, text, file, receivedAt }

/// What the share extension left in the app group (`Share/ShareViewController.swift`): one JSON file per item in
/// `inbox/`, an image beside its item. The app reads it on launch and on foreground and opens "Check what was read"
/// (plan/phase-13-plan.md decision 25); an item is removed once it is added or left.
public struct SharedInbox: Sendable {
    public struct Item: Decodable, Hashable, Sendable {
        /// The item's file name without `.json` (the extension's UUID).
        public internal(set) var id = ""
        public let kind: SharedItemKind
        public let text: String?
        /// The image's file name in `inbox/`.
        public let file: String?
        public let receivedAt: Date

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: InboxItemKeys.self)
            kind = try c.decode(SharedItemKind.self, forKey: .kind)
            text = try c.decodeIfPresent(String.self, forKey: .text)
            file = try c.decodeIfPresent(String.self, forKey: .file)
            receivedAt = try c.decode(Date.self, forKey: .receivedAt)
        }
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
        return try FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Item? in
                guard var item = try? JSONDecoder.inbox.decode(Item.self, from: Data(contentsOf: url))
                else { return nil }
                item.id = url.deletingPathExtension().lastPathComponent
                return item
            }
            .sorted { $0.receivedAt < $1.receivedAt }
    }

    /// The item's file and its image; a file already gone is not a failure.
    public func remove(_ item: Item) throws {
        let inbox = container.appendingPathComponent("inbox")
        for name in ["\(item.id).json", item.file].compactMap(\.self) {
            let url = inbox.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    /// The bytes of the image beside an item, whatever their format (HEIC included); nil for a text.
    public func image(of item: Item) -> Data? {
        guard let file = item.file else { return nil }
        return try? Data(contentsOf: container.appendingPathComponent("inbox").appendingPathComponent(file))
    }
}

extension JSONDecoder {
    /// The extension writes its dates as ISO 8601.
    static var inbox: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
