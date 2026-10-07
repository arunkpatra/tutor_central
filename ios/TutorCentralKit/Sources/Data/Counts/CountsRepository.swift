import Domain
import Foundation

/// Today's three numbers for a centre.
public protocol CountsRepository: Sendable {
    func todayCounts(centre: UUID, on date: Date) async throws -> TodayCounts
}
