import Domain
import Foundation
import Observation

/// What Attendance and Fees see (D39): a write they could not make now goes in; what is waiting is shown.
@MainActor public protocol ChangeQueueing: AnyObject {
    var pending: PendingChanges { get }
    func add(_ change: QueuedChange)
    func remove(id: UUID)
}

/// The queue of one centre, kept in Application Support/TutorCentral/queue-<centre>.json after every change, so a
/// change made offline survives a relaunch and never runs for another centre (the file is named by the centre).
@MainActor @Observable public final class ChangeQueue: ChangeQueueing {
    public private(set) var pending: PendingChanges
    /// Told after a change is added, so the shell can send it at once when online (review I1).
    @ObservationIgnored public var onAdded: (@MainActor () -> Void)?
    @ObservationIgnored private let url: URL

    public init(centre: UUID, directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        url = base.appendingPathComponent("queue-\(centre.uuidString.lowercased()).json")
        pending = Self.read(url)
    }

    /// The saved queue; a file that cannot be read (a future format, a damaged write) is kept aside as
    /// `queue-<centre>.unreadable.json` rather than overwritten by the next change.
    private static func read(_ url: URL) -> PendingChanges {
        guard let data = try? Data(contentsOf: url) else { return PendingChanges() }
        if let pending = try? JSONDecoder().decode(PendingChanges.self, from: data) {
            return pending
        }
        let aside = url.deletingPathExtension().appendingPathExtension("unreadable.json")
        try? FileManager.default.removeItem(at: aside)
        try? FileManager.default.moveItem(at: url, to: aside)
        return PendingChanges()
    }

    public func add(_ change: QueuedChange) {
        pending.add(change)
        keep()
        onAdded?()
    }

    public func remove(id: UUID) {
        pending.remove(id: id)
        keep()
    }

    public func removeSent(_ sent: QueuedChange) {
        pending.removeSent(sent)
        keep()
    }

    public func fail(id: UUID, reason: String) {
        pending.fail(id: id, reason: reason)
        keep()
    }

    public func retryAll() {
        pending.retryAll()
        keep()
    }

    /// Sign-out and deletion (D40): nothing waits, and the file is gone.
    public func wipe() {
        pending = PendingChanges()
        try? FileManager.default.removeItem(at: url)
    }

    /// The whole queue after every change, with the caches' file protection; an empty queue leaves no file. Dates
    /// keep their fractions so the order made survives a relaunch.
    private func keep() {
        guard !pending.isEmpty else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(pending)
            .write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
