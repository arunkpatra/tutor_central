import Foundation

/// How tasks are listed (phase file item 6): open by due date, done tasks fall off Today after a day.
public enum TaskOrdering {
    public static let stayOnToday: TimeInterval = 24 * 60 * 60

    public static func open(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { !$0.isDone }.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (x?, y?) where x != y: x < y
            case (nil, _?): false
            case (_?, nil): true
            default: lhs.createdAt < rhs.createdAt
            }
        }
    }

    public static func done(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter(\.isDone).sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    public static func onToday(_ tasks: [TaskItem], now: Date) -> [TaskItem] {
        open(tasks) + done(tasks).filter { now.timeIntervalSince($0.doneAt ?? .distantPast) < stayOnToday }
    }

    public static func dueText(_ task: TaskItem, today: Day, calendar: Calendar) -> (text: String, overdue: Bool)? {
        guard let due = task.dueDate, !task.isDone else { return nil }
        if due == today {
            return ("Today", false)
        }
        if due == today.adding(days: 1, calendar: calendar) {
            return ("Tomorrow", false)
        }
        return (due.shortWeekdayText, due < today)
    }

    public static func doneText(_ task: TaskItem, calendar: Calendar) -> String? {
        task.doneAt.map { Day($0, calendar: calendar).shortWeekdayText }
    }
}
