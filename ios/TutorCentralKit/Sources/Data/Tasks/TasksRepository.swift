import Domain
import Foundation

/// The tutor's tasks. RLS keeps every call inside the member's centre.
public protocol TasksRepository: Sendable {
    /// Every task, open and done.
    func tasks(centre: UUID) async throws -> [TaskItem]
    func create(title: String, dueDate: Day?, centre: UUID) async throws -> TaskItem
    func setDone(id: UUID, _ done: Bool) async throws -> TaskItem
    /// Deletes the done ones (Clear on the Tasks screen); answers how many went.
    func clearDone(centre: UUID) async throws -> Int
}
