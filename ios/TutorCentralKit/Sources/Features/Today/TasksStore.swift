import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// The tutor's tasks (P4-Tasks, P4-Today-AddingTask): one per centre (`ShellState.tasks`), shared by Today's Tasks
/// card and the Tasks screen under More, with the inline add's state. Add, done and clear show at once and roll back
/// with a toast and Retry.
@MainActor @Observable public final class TasksStore {
    public private(set) var tasks: [TaskItem] = []
    public private(set) var loading = false
    public private(set) var error: String?
    /// When the copy on screen was saved on this iPhone, until the network replaces it (D39).
    public private(set) var savedAt: Date?
    /// The last read failed for the network, not the server.
    public private(set) var offlineRead = false
    /// The tasks' copy on this iPhone (AppShell's).
    public var cache: CachedRead<[TaskItem]>?
    public var message: String?
    public private(set) var canRetry = false
    public private(set) var lastSavedAt: Date?
    public var newTitle = ""
    public var newDue: Day?
    public var adding = false
    private var loaded = false
    private var lastFailed: (@MainActor () async -> Void)?
    private let workspace: Workspace
    private let repository: any TasksRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        workspace: Workspace, tasks: any TasksRepository, now: @escaping @Sendable () -> Date,
        calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        repository = tasks
        self.now = now
        self.calendar = calendar
    }

    public var open: [TaskItem] {
        TaskOrdering.open(tasks)
    }

    public var done: [TaskItem] {
        TaskOrdering.done(tasks)
    }

    /// Open tasks, then those done within a day.
    public var onToday: [TaskItem] {
        TaskOrdering.onToday(tasks, now: now())
    }

    public var openTitle: String {
        switch open.count {
        case 0: "Nothing to do"
        case let count: "\(count) to do"
        }
    }

    private var today: Day {
        Day(now(), calendar: calendar)
    }

    /// The next Monday-to-Friday after today, the date chip's first offer.
    public var suggestedDue: Day {
        var day = today.adding(days: 1, calendar: calendar)
        while [.saturday, .sunday].contains(day.weekday(in: calendar)) {
            day = day.adding(days: 1, calendar: calendar)
        }
        return day
    }

    /// The date chip (the chosen day, else the next weekday; it opens the date picker) and No date.
    public var dueChips: [(label: String, day: Day?)] {
        let day = newDue ?? suggestedDue
        return [(dueLabel(day), day), ("No date", nil)]
    }

    public var canAdd: Bool {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && title.count <= TaskItem.titleLimit
    }

    /// The due words (overdue in that tone) for an open task, the done day for a done one.
    public func trailing(for task: TaskItem) -> (text: String, tone: StatusTone?)? {
        if task.isDone {
            return TaskOrdering.doneText(task, calendar: calendar).map { ($0, nil) }
        }
        return TaskOrdering.dueText(task, today: today, calendar: calendar)
            .map { ($0.text, $0.overdue ? .overdue : nil) }
    }

    public func load() async {
        if !loaded, let cached = cache?.load() {
            tasks = cached.value
            savedAt = cached.savedAt
            loaded = true
        }
        loading = !loaded
        defer { loading = false }
        do {
            tasks = try await repository.tasks(centre: workspace.centre.id)
            cache?.keep(tasks, at: now())
            savedAt = nil
            offlineRead = false
            loaded = true
            error = nil
        } catch {
            offlineRead = TransportError.isOffline(error)
            // A saved copy offline: the line under the title says it.
            self.error = loaded && offlineRead ? nil : "Couldn't load your tasks. Check your connection and try again."
        }
    }

    /// Reads only once; Today and the Tasks screen share what was read.
    public func loadIfNeeded() async {
        if !loaded {
            await load()
        }
    }

    @discardableResult public func add() async -> Bool {
        guard canAdd else { return false }
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let due = newDue
        let placeholder = TaskItem(id: UUID(), title: title, dueDate: due, doneAt: nil, createdAt: now())
        tasks.append(placeholder)
        newTitle = ""
        newDue = nil
        adding = false
        do {
            let made = try await repository.create(title: title, dueDate: due, centre: workspace.centre.id)
            replace(placeholder.id, with: made)
            saved()
            return true
        } catch {
            tasks.removeAll { $0.id == placeholder.id }
            newTitle = title
            newDue = due
            adding = true
            failed(
                "Couldn't add the task. Check your connection and try again.",
                .addTask,
                error: error
            ) { [weak self] in
                await self?.add()
            }
            return false
        }
    }

    /// The date chip turns on with the suggested day (the picker it opens starts there, and picking the day it shows
    /// changes nothing); a chosen day stays.
    public func pickDueChip() {
        newDue = newDue ?? suggestedDue
    }

    public func cancelAdd() {
        adding = false
        newTitle = ""
        newDue = nil
    }

    public func setDone(_ id: UUID, _ done: Bool) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let before = tasks[index]
        tasks[index].doneAt = done ? now() : nil
        do {
            let changed = try await repository.setDone(id: id, done)
            replace(id, with: changed)
            saved()
        } catch {
            replace(id, with: before)
            failed(
                "Couldn't update the task. Check your connection and try again.",
                .editTask,
                error: error
            ) { [weak self] in
                await self?.setDone(id, done)
            }
        }
    }

    public func clearDone() async {
        let gone = tasks.filter(\.isDone)
        guard !gone.isEmpty else { return }
        tasks.removeAll(where: \.isDone)
        do {
            _ = try await repository.clearDone(centre: workspace.centre.id)
            saved()
        } catch {
            tasks.append(contentsOf: gone)
            failed(
                "Couldn't clear the done tasks. Check your connection and try again.",
                .editTask,
                error: error
            ) { [weak self] in
                await self?.clearDone()
            }
        }
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    /// "Today", "Tomorrow", "Fri 9 Oct".
    public func dueLabel(_ day: Day) -> String {
        if day == today {
            return "Today"
        }
        return day == today.adding(days: 1, calendar: calendar) ? "Tomorrow" : day.shortWeekdayText
    }

    private func replace(_ id: UUID, with task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index] = task
        }
    }

    private func saved() {
        lastSavedAt = now()
        lastFailed = nil
        canRetry = false
    }

    private func failed(
        _ text: String, _ refusal: OfflineRefusal.Write? = nil, error: (any Error)? = nil,
        retry: @escaping @MainActor () async -> Void
    ) {
        if let error, let refusal, TransportError.isOffline(error) {
            // Offline: the write needs a connection; nothing was saved, and Retry would only fail again (D39).
            message = OfflineRefusal.words(for: refusal)
            canRetry = false
            lastFailed = nil
            return
        }
        message = text
        canRetry = true
        lastFailed = retry
    }
}
