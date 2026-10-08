import DesignSystem
import Domain
import Settings
import SwiftUI
import Today

/// Today's and Settings' wiring: Today's one store and its actions; Settings, whose centre changes reach every store
/// that shows the workspace.
extension RootView {
    @ViewBuilder var settingsView: some View {
        if case let .ready(workspace) = session.state {
            let store = SettingsStore(
                workspace: workspace,
                auth: deps.auth,
                centres: deps.centres,
                version: deps.bundleVersion
            )
            SettingsView(
                store: store,
                boardState: launch == .settings,
                onWorkspaceChanged: { changed in applyWorkspace { $0.takingSettings(from: changed) } },
                onMessage: { toasts.show($0) },
                openPayments: { shell.tabs.push(.payments) }
            )
        }
    }

    /// One Today store for the life of the workspace, so its counts survive a tab switch; it reads the shared register
    /// and tasks.
    @ViewBuilder var todayView: some View {
        if case let .ready(workspace) = session.state {
            let store = shell.today ?? TodayStore(
                workspace: workspace, counts: deps.counts, register: register(for: workspace),
                attendance: deps.attendance, events: deps.events, tasks: tasksStore(for: workspace), now: deps.now
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
                    openFeesDue: { openFeesDue(in: workspace) }
                ),
                ticks: !deps.fixedClock,
                boardState: launch.flatMap(Self.todayBoardState)
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
