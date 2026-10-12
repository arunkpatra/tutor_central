import Domain
import Foundation

/// The tutor's activity on this iPhone (D77, D82), kept in `activity-<centre>.json` with the caches' file protection
/// (D40) and posted in batches: when `batch` have gathered, and when the app goes to the background or comes back. A
/// failed post keeps the events for the next; the file holds at most `cap`, the oldest going. Sign-out posts it, then
/// the wipe removes the file (`Wipe`).
public actor ActivityLog {
    private let centre: UUID
    private let repository: any ActivityRepository
    private let url: URL
    private let now: @Sendable () -> Date
    private let batch: Int
    private let cap: Int
    private var events: [ActivityEvent]
    private var posting = false

    public init(
        centre: UUID, repository: any ActivityRepository, directory: URL? = nil,
        now: @escaping @Sendable () -> Date = Date.init, batch: Int = 20, cap: Int = 500
    ) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        url = base.appendingPathComponent("activity-\(centre.uuidString.lowercased()).json")
        self.centre = centre
        self.repository = repository
        self.now = now
        self.batch = batch
        self.cap = cap
        events = (try? Data(contentsOf: url)).flatMap { try? Self.decoder.decode([ActivityEvent].self, from: $0) } ?? []
    }

    public var pending: Int {
        events.count
    }

    public func record(_ kind: ActivityKind, screen: String? = nil) async {
        events.append(ActivityEvent(kind: kind, screen: screen, at: now()))
        if events.count > cap {
            events.removeFirst(events.count - cap)
        }
        keep()
        if events.count >= batch {
            await flush()
        }
    }

    /// Posts what has gathered and removes exactly what was posted; a post already running is left to finish.
    public func flush() async {
        guard !posting, !events.isEmpty else { return }
        posting = true
        defer { posting = false }
        let sending = events
        do {
            try await repository.post(sending, centre: centre)
        } catch {
            return
        }
        let sent = Set(sending.map(\.id))
        events.removeAll { sent.contains($0.id) }
        keep()
    }

    private func keep() {
        guard !events.isEmpty else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Self.encoder.encode(events).write(
            to: url,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
