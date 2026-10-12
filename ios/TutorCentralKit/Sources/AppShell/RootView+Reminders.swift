import Data
import DesignSystem
import Domain
import Settings
import SwiftUI
import UIKit

/// Teacher reminders, sent by the server (Phase 18): this iPhone registered for pushes once notifications are allowed,
/// the settings moved to the account on the first launch of a build with push, and the screen pushed from Settings.
extension RootView {
    /// One registrar for the life of the workspace.
    func pushRegistrar() -> PushRegistrar {
        if let push = shell.push {
            return push
        }
        let made = PushRegistrar(
            notifications: deps.notifications, tokens: deps.deviceTokens,
            registerForRemote: { UIApplication.shared.registerForRemoteNotifications() },
            unregisterFromRemote: { UIApplication.shared.unregisterForRemoteNotifications() },
            deviceID: { UIDevice.current.identifierForVendor?.uuidString.lowercased() },
            environment: Bundle.main.object(forInfoDictionaryKey: "PUSH_ENVIRONMENT") as? String ?? "sandbox",
            build: (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String).flatMap(Int.init)
        )
        shell.push = made
        PushRelay.shared.onToken = { token in Task { await made.received(token: token) } }
        return made
    }

    /// After a sign-in and on each return to the app: the old settings moved once, then the token asked for (iOS
    /// answers with the same token, which keeps the row's last seen). A launch state touches nothing.
    func startPush() {
        guard launch == nil, case let .ready(workspace) = session.state else { return }
        let registrar = pushRegistrar()
        Task {
            await ReminderSettingsMigration.run(
                defaults: .standard, repository: deps.reminderSettings, notifications: deps.notifications,
                centre: workspace.centre.id
            )
            await registrar.register()
        }
    }

    @ViewBuilder var remindersView: some View {
        if case let .ready(workspace) = session.state {
            let register = register(for: workspace)
            RemindersView(
                store: RemindersStore(
                    notifications: deps.notifications, repository: deps.reminderSettings, centre: workspace.centre.id,
                    classNames: { register.activeClasses.map(\.name) }, now: deps.now, calendar: DayHeading.india,
                    onAllowed: {
                        if launch == nil {
                            await pushRegistrar().register()
                        }
                    }
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
