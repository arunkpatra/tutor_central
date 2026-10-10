import Domain
import Foundation

/// The in-memory counts for tests, previews and `bun shots`.
@MainActor public final class FakeCountsRepository: CountsRepository {
    /// Wednesday 7 October 2026, 18:30 in India: the boards' moment ("Good evening, Meera").
    public nonisolated static let fixedNow: Date = DayHeading.india.date(
        from: DateComponents(year: 2026, month: 10, day: 7, hour: 18, minute: 30)
    ) ?? .distantPast

    public var counts: TodayCounts
    public var nextError: (any Error)?
    /// Every read waits this long first, as a read through a stopped gateway does.
    public var delay: Duration?

    public init(counts: TodayCounts = .zero) {
        self.counts = counts
    }

    public func todayCounts(centre _: UUID, on _: Date) async throws -> TodayCounts {
        if let delay {
            try await Task.sleep(for: delay)
        }
        if let error = nextError {
            nextError = nil
            throw error
        }
        return counts
    }
}
