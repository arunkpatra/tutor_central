import Domain
import Foundation

/// The centre's schools. RLS keeps every call inside the member's centre.
public protocol SchoolsRepository: Sendable {
    func schools(centre: UUID) async throws -> [School]
    func create(name: String, board: Board?, centre: UUID) async throws -> School
}
