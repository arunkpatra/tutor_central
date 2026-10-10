import Foundation

/// A school the centre's students go to.
public struct School: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var board: Board?

    public init(id: UUID, name: String, board: Board?) {
        self.id = id
        self.name = name
        self.board = board
    }
}
