import Data
import DesignSystem
import Domain
import Settings
import SwiftUI
import UIKit

/// Teacher reminders: the centre's planner, the moments it plans again (a sign-in, the foreground, a class, an event or
/// a fee saved, the queue sent), and the screen pushed from Settings.
extension RootView {
    /// One planner for the life of the workspace, reading the shared register.
    func reminderScheduler(for workspace: Workspace) -> ReminderScheduler {
        if let scheduler = shell.scheduler {
            return scheduler
        }
        let made = ReminderScheduler(
            notifications: deps.notifications, settingsStore: deps.reminderSettings,
            register: register(for: workspace), events: deps.events, fees: deps.fees, now: deps.now,
            calendar: DayHeading.india
        )
        shell.scheduler = made
        return made
    }

    /// Plans the reminders again in the background; a launch state leaves the board's plan alone.
    func replanReminders() {
        guard launch == nil, case let .ready(workspace) = session.state else { return }
        let scheduler = reminderScheduler(for: workspace)
        Task { await scheduler.replan(workspace: workspace) }
    }

    @ViewBuilder var remindersView: some View {
        if case let .ready(workspace) = session.state {
            let register = register(for: workspace)
            let scheduler = reminderScheduler(for: workspace)
            RemindersView(
                store: RemindersStore(
                    notifications: deps.notifications, settingsStore: deps.reminderSettings,
                    classNames: { register.activeClasses.map(\.name) }, now: deps.now, calendar: DayHeading.india,
                    replan: { await scheduler.replan(workspace: workspace) }
                ),
                boardState: launch != nil,
                boardWheel: launch == .remindersDayPicker ? .feesDay : nil
            ) {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openExternal(url)
                }
            }
        }
    }
}
