import Domain
import Foundation

/// Consent histories in memory, for tests, previews and `bun shots`, newest first.
public actor FakeConsentHistoryRepository: ConsentHistoryRepository {
    private let events: [UUID: [ConsentEvent]]
    private let failure: (any Error)?

    public init(events: [UUID: [ConsentEvent]] = [:], failure: (any Error)? = nil) {
        self.events = events
        self.failure = failure
    }

    public func history(centre _: UUID, student: UUID) async throws -> [ConsentEvent] {
        if let failure {
            throw failure
        }
        return (events[student] ?? []).sorted { $0.at > $1.at }
    }
}
