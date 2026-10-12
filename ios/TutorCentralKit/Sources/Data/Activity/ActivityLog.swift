import Domain
import Foundation

/// The tutor's activity on this iPhone (D77, D82), kept in `activity-<centre>.json` with the caches' file protection
/// (D40), one event a line, and posted in batches: when `batch` have gathered, and when the app goes to the background
/// or
/// comes back. A record adds its line; the file is written whole only after a post or when the oldest go (at most
/// `cap`).
/// A failed post keeps the events for the next. Sign-out closes the log: the sign-out is posted with everything
/// gathered,
/// and nothing is written after, so the wipe's removal stands (`Wipe`).
public actor ActivityLog {
    private let centre: UUID
    private let repository: any ActivityRepository
    private let url: URL
    private let now: @Sendable () -> Date
    private let batch: Int
    private let cap: Int
    private var events: [ActivityEvent]
    private var inFlight: Task<Void, any Error>?
    private var closed = false

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
        events = Self.read(url)
    }

    public var pending: Int {
        events.count
    }

    public func record(_ kind: ActivityKind, screen: String? = nil) async {
        guard !closed else { return }
        let event = ActivityEvent(kind: kind, screen: screen, at: now())
        events.append(event)
        if events.count > cap {
            events.removeFirst(events.count - cap)
            keep()
        } else {
            add(event)
        }
        if events.count >= batch {
            await flush()
        }
    }

    /// Posts what has gathered and removes exactly what was posted; a post already running is left to finish.
    public func flush() async {
        guard inFlight == nil, !closed, !events.isEmpty else { return }
        let sending = events
        let post = Task { [repository, centre] in try await repository.post(sending, centre: centre) }
        inFlight = post
        defer { inFlight = nil }
        do {
            try await post.value
        } catch {
            return
        }
        let sent = Set(sending.map(\.id))
        events.removeAll { sent.contains($0.id) }
        keep()
    }

    /// Sign-out: `kind` recorded and posted with everything gathered, beside a post still running (an event posted
    /// twice
    /// is one row, by its id); then the file goes, and nothing is recorded or written after.
    public func close(with kind: ActivityKind) async {
        guard !closed else { return }
        closed = true
        events.append(ActivityEvent(kind: kind, screen: nil, at: now()))
        if let inFlight {
            _ = try? await inFlight.value
        }
        try? await repository.post(events, centre: centre)
        events = []
        try? FileManager.default.removeItem(at: url)
    }

    /// One event at the file's end.
    private func add(_ event: ActivityEvent) {
        guard let line = try? Self.encoder.encode(event) else { return }
        guard let handle = try? FileHandle(forWritingTo: url) else {
            keep()
            return
        }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: line + Data("\n".utf8))
    }

    /// The file written whole: the events left, or none.
    private func keep() {
        guard !closed else { return }
        guard !events.isEmpty else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let lines = events.compactMap { try? Self.encoder.encode($0) }.map { $0 + Data("\n".utf8) }
        try? lines.reduce(Data(), +).write(
            to: url,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    private static func read(_ url: URL) -> [ActivityEvent] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return data.split(separator: UInt8(ascii: "\n"))
            .compactMap { try? decoder.decode(ActivityEvent.self, from: $0) }
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
