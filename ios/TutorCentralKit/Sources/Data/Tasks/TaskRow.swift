import Domain
import Foundation

/// A `tasks` row; `due_date` is a day, `done_at` a moment.
struct TaskRow: Decodable {
    let id: UUID
    let title: String
    let dueDate: String?
    let doneAt: Date?
    let createdAt: Date

    var task: TaskItem {
        TaskItem(id: id, title: title, dueDate: dueDate.flatMap(Day.init(iso:)), doneAt: doneAt, createdAt: createdAt)
    }
}
