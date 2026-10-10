import Domain
import Foundation

/// A `schools` row (migration 0009).
struct SchoolRow: Decodable {
    let id: UUID
    let name: String
    let board: Board?

    var school: School {
        School(id: id, name: name, board: board)
    }
}
