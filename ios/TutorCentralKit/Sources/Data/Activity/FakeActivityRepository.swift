import Domain
import Foundation
import Synchronization

/// The activity in memory, for tests and the launch states: each batch posted, or a failure for the first `failures`; a
/// held one keeps each post waiting until `release()` (a post still running when the tutor signs out).
public final class FakeActivityRepository: ActivityRepository {
    private struct State {
        var batches: [[ActivityEvent]] = []
        var failures: Int
        var held: Bool
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state: Mutex<State>

    public init(failures: Int = 0, held: Bool = false) {
        state = Mutex(State(failures: failures, held: held))
    }

    public var batches: [[ActivityEvent]] {
        state.withLock { $0.batches }
    }

    /// The posts waiting for `release()`.
    public var waiting: Int {
        state.withLock { $0.waiters.count }
    }

    /// Lets every waiting post through, and every later one.
    public func release() {
        let waiters = state.withLock { state in
            state.held = false
            defer { state.waiters = [] }
            return state.waiters
        }
        waiters.forEach { $0.resume() }
    }

    public func post(_ events: [ActivityEvent], centre _: UUID) async throws {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let held = state.withLock { state in
                if state.held {
                    state.waiters.append(continuation)
                }
                return state.held
            }
            if !held {
                continuation.resume()
            }
        }
        try state.withLock { state in
            if state.failures > 0 {
                state.failures -= 1
                throw URLError(.notConnectedToInternet)
            }
            state.batches.append(events)
        }
    }
}
