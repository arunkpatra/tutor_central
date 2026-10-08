import Domain
import Foundation

/// The in-memory tasks for tests, previews and `bun shots`: the seed's two open tasks and two done ones, a scripted
/// error, a delay, a record of every write.
@MainActor public final class FakeTasksRepository: TasksRepository {
    public nonisolated static let seed: [TaskItem] = {
        let calendar = DayHeading.india
        func at(_ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(
                year: 2026,
                month: 10,
                day: day,
                hour: hour
            ))!
        }
        func id(_ number: Int) -> UUID {
            UUID(uuidString: String(format: "dddddddd-0000-0000-0000-%012d", number))!
        }
        return [
            TaskItem(
                id: id(1),
                title: "Call Dev's father about Saturday",
                dueDate: Day(year: 2026, month: 10, day: 9),
                doneAt: nil,
                createdAt: at(5, 9)
            ),
            TaskItem(id: id(2), title: "Buy chalk and dusters", dueDate: nil, doneAt: nil, createdAt: at(5, 10)),
            TaskItem(
                id: id(3),
                title: "Order Class 8 workbooks",
                dueDate: Day(year: 2026, month: 10, day: 6),
                doneAt: at(6, 10),
                createdAt: at(1, 9)
            ),
            TaskItem(
                id: id(4),
                title: "Send September report to parents",
                dueDate: Day(year: 2026, month: 10, day: 1),
                doneAt: at(1, 19),
                createdAt: at(1, 8)
            ),
        ]
    }()

    public var tasks: [TaskItem]
    public var nextError: (any Error)?
    public var delay: Duration?
    public private(set) var created: [(String, Day?)] = []
    public private(set) var doneCalls: [(UUID, Bool)] = []
    public private(set) var cleared = 0
    private let now: () -> Date

    public init(tasks: [TaskItem] = [], now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.tasks = tasks
        self.now = now
    }

    public func tasks(centre _: UUID) async throws -> [TaskItem] {
        try await begin()
        return tasks
    }

    public func create(title: String, dueDate: Day?, centre _: UUID) async throws -> TaskItem {
        try await begin()
        created.append((title, dueDate))
        let made = TaskItem(id: UUID(), title: title, dueDate: dueDate, doneAt: nil, createdAt: now())
        tasks.append(made)
        return made
    }

    public func setDone(id: UUID, _ done: Bool) async throws -> TaskItem {
        try await begin()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        doneCalls.append((id, done))
        tasks[index].doneAt = done ? now() : nil
        return tasks[index]
    }

    public func clearDone(centre _: UUID) async throws -> Int {
        try await begin()
        cleared += 1
        let count = tasks.filter(\.isDone).count
        tasks.removeAll(where: \.isDone)
        return count
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
