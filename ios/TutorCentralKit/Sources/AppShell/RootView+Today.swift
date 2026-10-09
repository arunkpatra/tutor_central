import DesignSystem
import Domain
import SwiftUI
import Today

/// Today's wiring: its one store and its actions.
extension RootView {
    /// One Today store for the life of the workspace, so its counts survive a tab switch; it reads the shared register
    /// and tasks.
    @ViewBuilder var todayView: some View {
        if case let .ready(workspace) = session.state {
            let store = shell.today ?? TodayStore(
                workspace: workspace, counts: deps.counts, register: register(for: workspace),
                attendance: deps.attendance, events: deps.events, tasks: tasksStore(for: workspace), now: deps.now,
                cache: cachedRead(workspace, "today")
            )
            TodayView(
                store: store,
                actions: TodayActions(
                    openSettings: { shell.tabs.push(.settings) },
                    openTab: { shell.tabs.select($0) },
                    openSchedule: { shell.tabs.push(.schedule) },
                    openMarkAttendance: { openAttendance(classID: $0, date: nil, in: workspace) },
                    openClass: { shell.tabs.push(.classroom($0)) },
                    openEvent: { shell.tabs.push(.event($0)) },
                    openFeesDue: { openFeesDue(in: workspace) },
                    openAI: { shell.tabs.push(.aiAssistant) }
                ),
                ticks: !deps.fixedClock,
                boardState: launch.flatMap(Self.todayBoardState),
                status: rootStatus(savedAt: store.savedAt, offlineRead: store.offlineRead)
            )
            .onAppear {
                if shell.today == nil {
                    shell.today = store
                }
            }
            .onChange(of: store.tasks.message) { _, message in
                guard let message else { return }
                Haptic.play(.error)
                toasts.show(message, action: store.tasks.canRetry ? Self.retry(store.tasks) : nil)
                store.tasks.message = nil
            }
        }
    }
}
