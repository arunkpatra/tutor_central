import DesignSystem
import Domain
import Schedule
import SwiftUI
import Today

/// The schedule's and the tasks' wiring: pushed from More and from Today; an event link opens its Edit sheet.
extension RootView {
    @ViewBuilder func scheduleView(openEvent: UUID?) -> some View {
        if case let .ready(workspace) = session.state {
            ScheduleView(
                store: ScheduleStore(
                    workspace: workspace, register: register(for: workspace), events: deps.events,
                    attendance: deps.attendance, now: deps.now, cache: monthCache(workspace, "schedule")
                ),
                actions: ScheduleActions(openClass: { shell.tabs.push(.classroom($0)) }),
                boardState: launch.flatMap(Self.scheduleBoardState),
                openEvent: openEvent,
                onMissingEvent: { toasts.show("That event is no longer here.") },
                status: { rootStatus(savedAt: $0, offlineRead: $1) }
            )
        }
    }

    /// One tasks store for the life of the workspace, shared by Today and the Tasks screen.
    func tasksStore(for workspace: Workspace) -> TasksStore {
        if let tasks = shell.tasks {
            return tasks
        }
        let made = TasksStore(workspace: workspace, tasks: deps.tasks, now: deps.now)
        made.cache = cachedRead(workspace, "tasks")
        shell.tasks = made
        return made
    }

    @ViewBuilder var tasksView: some View {
        if case let .ready(workspace) = session.state {
            let store = tasksStore(for: workspace)
            TasksView(store: store, status: rootStatus(savedAt: store.savedAt, offlineRead: store.offlineRead))
                .onChange(of: store.message) { _, message in
                    guard let message else { return }
                    Haptic.play(.error)
                    toasts.show(message, action: store.canRetry ? Self.retry(store) : nil)
                    store.message = nil
                }
        }
    }
}
