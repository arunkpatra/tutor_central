import UIKit
import UniformTypeIdentifiers

/// "Share to Tutor Central" from WhatsApp or Photos: one text or one image written to the app group's `inbox/`, then
/// done; the app reads the inbox (`SharedInbox`) when it next opens, from Phase 13. A share extension's entry point is
/// a view controller (the system's sheet hosts it), so this is UIKit with that reason (D8); it draws nothing of its
/// own.
final class ShareViewController: UIViewController {
    /// The same shape `SharedInbox.Item` reads.
    private struct Item: Encodable {
        let kind: String
        let text: String?
        let file: String?
        let receivedAt: Date
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await save()
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func save() async {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.in.tutorcentral"),
            let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        let inbox = container.appendingPathComponent("inbox")
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let id = UUID().uuidString
        for provider in items.flatMap({ $0.attachments ?? [] }) {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
               let data = await Self.data(of: provider, as: .image) {
                let file = "\(id).jpg"
                guard (try? data.write(to: inbox.appendingPathComponent(file), options: .atomic)) != nil else { return }
                write(Item(kind: "image", text: nil, file: file, receivedAt: .now), to: inbox, id: id)
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let data = await Self.data(of: provider, as: .plainText) {
                write(
                    Item(kind: "text", text: String(decoding: data, as: UTF8.self), file: nil, receivedAt: .now),
                    to: inbox,
                    id: id
                )
                return
            }
        }
    }

    private static func data(of provider: NSItemProvider, as type: UTType) async -> Data? {
        await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(for: type) { data, _ in continuation.resume(returning: data) }
        }
    }

    private func write(_ item: Item, to inbox: URL, id: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(item) else { return }
        try? data.write(to: inbox.appendingPathComponent("\(id).json"), options: .atomic)
    }
}
