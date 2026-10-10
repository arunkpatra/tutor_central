import Domain
import Foundation

/// The in-memory schools for tests and previews: the boards' Vidya Niketan (CBSE), a scripted error, every create.
@MainActor public final class FakeSchoolsRepository: SchoolsRepository {
    public nonisolated static let centre = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    public nonisolated static let vidya = School(
        id: UUID(uuidString: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60731")!, name: "Vidya Niketan", board: .cbse
    )

    public private(set) var schools: [School]
    public var nextError: (any Error)?

    public init(schools: [School] = [vidya]) {
        self.schools = schools
    }

    public func schools(centre _: UUID) async throws -> [School] {
        try begin()
        return schools.sorted { $0.name < $1.name }
    }

    public func create(name: String, board: Board?, centre _: UUID) async throws -> School {
        try begin()
        let school = School(id: UUID(), name: name, board: board)
        schools.append(school)
        return school
    }

    private func begin() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
