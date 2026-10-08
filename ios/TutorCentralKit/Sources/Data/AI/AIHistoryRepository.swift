import Domain
import Foundation

/// The centre's AI Assistant results as `ai_generations` holds them (History, Recent, a result reopened).
public protocol AIHistoryRepository: Sendable {
    /// The centre's finished generations of the four kinds, newest first, at most 50.
    func generations(centre: UUID) async throws -> [Generation]
    func generation(id: UUID) async throws -> Generation?
}
