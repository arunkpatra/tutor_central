import Foundation

/// A thing to remember (`tasks`). Named `TaskItem` because Swift's `Task` is taken.
public struct TaskItem: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var dueDate: Day?
    public var doneAt: Date?
    public let createdAt: Date

    public static let titleLimit = 200

    public init(id: UUID, title: String, dueDate: Day?, doneAt: Date?, createdAt: Date) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.doneAt = doneAt
        self.createdAt = createdAt
    }

    public var isDone: Bool {
        doneAt != nil
    }
}
