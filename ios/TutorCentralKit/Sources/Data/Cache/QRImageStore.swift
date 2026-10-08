import Foundation
import Synchronization

/// The UPI QR image kept on this iPhone to show a parent (Parent payments): never uploaded, one per centre.
public protocol QRImageStore: Sendable {
    func image(for centre: UUID) -> Data?
    func save(_ data: Data, for centre: UUID) throws
    func remove(for centre: UUID)
}

/// Application Support/TutorCentral/upi-qr-<centre id>.png (the register cache's folder), complete file protection.
public struct FileQRImageStore: QRImageStore {
    public init() {}

    public func image(for centre: UUID) -> Data? {
        try? Data(contentsOf: url(for: centre))
    }

    public func save(_ data: Data, for centre: UUID) throws {
        let url = url(for: centre)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    /// A missing file is already removed.
    public func remove(for centre: UUID) {
        try? FileManager.default.removeItem(at: url(for: centre))
    }

    private func url(for centre: UUID) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
            .appendingPathComponent("upi-qr-\(centre.uuidString.lowercased()).png")
    }
}

/// The fixtures' and tests' store: a dictionary behind a lock (the protocol's calls are synchronous).
public final class MemoryQRImageStore: QRImageStore {
    private let stored: Mutex<[UUID: Data]>

    public init(images: [UUID: Data] = [:]) {
        stored = Mutex(images)
    }

    public var images: [UUID: Data] {
        stored.withLock { $0 }
    }

    public func image(for centre: UUID) -> Data? {
        stored.withLock { $0[centre] }
    }

    public func save(_ data: Data, for centre: UUID) throws {
        stored.withLock { $0[centre] = data }
    }

    public func remove(for centre: UUID) {
        _ = stored.withLock { $0.removeValue(forKey: centre) }
    }
}
