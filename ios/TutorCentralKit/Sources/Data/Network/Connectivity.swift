import Foundation
import Network
import Synchronization

/// Whether this iPhone has a network path (D39): the offline bar, the queued writes and the replay ask it.
public protocol ConnectivityMonitor: Sendable {
    /// The last known state; true until the first path update says otherwise.
    var isOnline: Bool { get async }
    /// Every change after the current state.
    func changes() -> AsyncStream<Bool>
}

/// `NWPathMonitor` on its own queue; a satisfied path is online.
public final class PathMonitor: ConnectivityMonitor {
    private let monitor = NWPathMonitor()
    private let state = Mutex(true)
    private let listeners = Broadcast<Bool>()

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update(online: path.status == .satisfied)
        }
        monitor.start(queue: DispatchQueue(label: "in.tutorcentral.path"))
    }

    deinit {
        monitor.cancel()
    }

    public var isOnline: Bool {
        state.withLock { $0 }
    }

    public func changes() -> AsyncStream<Bool> {
        listeners.stream()
    }

    private func update(online: Bool) {
        let changed = state.withLock { current in
            defer { current = online }
            return current != online
        }
        guard changed else { return }
        listeners.send(online)
    }
}

/// The connectivity of tests, previews and `bun shots`: set by hand.
@MainActor public final class FakeConnectivity: ConnectivityMonitor {
    private var online: Bool
    private nonisolated let listeners = Broadcast<Bool>()

    public init(online: Bool = true) {
        self.online = online
    }

    public var isOnline: Bool {
        online
    }

    public nonisolated func changes() -> AsyncStream<Bool> {
        listeners.stream()
    }

    public func set(online: Bool) {
        self.online = online
        listeners.send(online)
    }
}

/// The open streams of one value, behind a lock so registering never waits for an actor; a stream registers at once,
/// so a change straight after `stream()` is never missed.
final class Broadcast<Element: Sendable>: Sendable {
    private let streams = Mutex<[UUID: AsyncStream<Element>.Continuation]>([:])

    func stream() -> AsyncStream<Element> {
        let key = UUID()
        let (stream, continuation) = AsyncStream<Element>.makeStream()
        streams.withLock { $0[key] = continuation }
        continuation.onTermination = { [weak self] _ in
            _ = self?.streams.withLock { $0.removeValue(forKey: key) }
        }
        return stream
    }

    func send(_ element: Element) {
        for listener in streams.withLock({ Array($0.values) }) {
            listener.yield(element)
        }
    }
}

/// Whether a thrown error means the network, not the server: no connection, a lost one, no host, a timeout.
public enum TransportError {
    public static func isOffline(_ error: any Error) -> Bool {
        if let url = error as? URLError {
            return TransportCodes.offline.contains(url.code)
        }
        let bridged = error as NSError
        guard bridged.domain == NSURLErrorDomain else { return false }
        return TransportCodes.offline.contains(URLError.Code(rawValue: bridged.code))
    }
}
