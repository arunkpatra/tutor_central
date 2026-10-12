import Domain
import Foundation
import Synchronization

/// The activity in memory, for tests and the launch states: each batch posted, or a failure for the first `failures`.
public final class FakeActivityRepository: ActivityRepository {
    private let state: Mutex<(batches: [[ActivityEvent]], failures: Int)>

    public init(failures: Int = 0) {
        state = Mutex(([], failures))
    }

    public var batches: [[ActivityEvent]] {
        state.withLock { $0.batches }
    }

    public func post(_ events: [ActivityEvent], centre _: UUID) async throws {
        try state.withLock { state in
            if state.failures > 0 {
                state.failures -= 1
                throw URLError(.notConnectedToInternet)
            }
            state.batches.append(events)
        }
    }
}
