import DesignSystem
import Domain
import Settings
import SwiftUI

/// Settings and the screens on its stack: Settings, whose centre changes reach every store that shows the workspace;
/// Account; Delete account; Help; Pending changes; Teacher reminders.
extension RootView {
    @ViewBuilder func settingsScreen(_ route: Route) -> some View {
        switch route {
        case .help:
            HelpView(version: deps.bundleVersion, boardOpen: launch == .helpAnswer ? 0 : nil) { openExternal($0) }
        case .account:
            accountView
        case .deleteAccount:
            deleteAccountView
        case .pendingChanges:
            pendingChangesView
        case .reminders:
            remindersView
        default:
            settingsView
        }
    }

    @ViewBuilder private var settingsView: some View {
        if case let .ready(workspace) = session.state {
            let store = SettingsStore(
                workspace: workspace,
                centres: deps.centres,
                version: deps.bundleVersion,
                reminders: ReminderSummary(permission: .notAsked, settings: ReminderSettings()),
                pendingCount: shell.queue?.pending.changes.count ?? 0
            )
            SettingsView(
                store: store,
                reminders: { await reminderSummary() },
                actions: SettingsActions(
                    openPayments: { shell.tabs.push(.payments) },
                    openReminders: { shell.tabs.push(.reminders) },
                    openPendingChanges: { shell.tabs.push(.pendingChanges) },
                    openAccount: { shell.tabs.push(.account) },
                    openHelp: { shell.tabs.push(.help) },
                    openURL: { openExternal($0) },
                    privacy: Legal.privacy,
                    terms: Legal.terms
                ),
                boardState: launch.flatMap(Self.settingsBoardState),
                onWorkspaceChanged: { changed in applyWorkspace { $0.takingSettings(from: changed) } },
                onMessage: { toasts.show($0, stay: launch == nil ? nil : .seconds(3600)) }
            )
        }
    }

    @ViewBuilder private var accountView: some View {
        if case let .ready(workspace) = session.state, let queue = centreQueue() {
            AccountView(
                store: AccountStore(workspace: workspace, auth: deps.auth, queue: queue) {
                    applyWorkspace { current in
                        var changed = current
                        changed.profile.hasPassword = true
                        return changed
                    }
                },
                actions: AccountActions(
                    openDelete: { shell.tabs.push(.deleteAccount) },
                    signOut: { await session.signOut(wiping: wipe(for: workspace)) },
                    makePassword: { PasswordStore(auth: deps.auth, centres: deps.centres, hasPassword: $0) },
                    onMessage: { toasts.show($0, stay: launch == nil ? nil : .seconds(3600)) }
                ),
                boardState: launch.flatMap(Self.accountBoardState)
            )
        }
    }

    @ViewBuilder private var deleteAccountView: some View {
        if case let .ready(workspace) = session.state {
            // Captured now: the deletion's own sign-out drops the shell's queue before the wipe runs.
            let wipe = wipe(for: workspace)
            DeleteAccountView(
                store: DeleteAccountStore(
                    workspace: workspace, register: register(for: workspace), auth: deps.auth, account: deps.account,
                    reauthorize: reauthorize
                ) {
                    await wipe.run()
                    session.deleted(centreName: workspace.centre.name)
                },
                boardState: launch.flatMap(Self.deleteAccountBoardState)
            )
        }
    }

    /// Apple's confirmation (D38); the fixture's for `bun shots` (Deleting's never answers).
    private var reauthorize: @MainActor () async throws(AccountFailure) -> String {
        if launch == .deleteAccountDeleting {
            return {
                try? await Task.sleep(for: .seconds(3600))
                return "never"
            }
        }
        if launch != nil {
            return { "fixture-code" }
        }
        let apple = AppleReauthorizer(controller: authorizationController)
        return { () async throws(AccountFailure) -> String in try await apple.authorizationCode() }
    }

    @ViewBuilder private var pendingChangesView: some View {
        if let queue = shell.queue {
            PendingChangesView(
                store: PendingChangesStore(queue: queue, calendar: DayHeading.india) { await runQueue() },
                boardDiscard: launch == .pendingDiscard
            ) { _ in
                if queue.pending.isEmpty {
                    shell.tabs.remove(.pendingChanges)
                }
                afterQueueChanged()
            }
        }
    }

    /// What sign-out and deletion clear for this centre (D40).
    func wipe(for workspace: Workspace) -> SignOutWipe {
        SignOutWipe(
            centre: workspace.centre.id, directory: deps.filesDirectory, queue: shell.queue,
            notifications: deps.notifications
        )
    }

    /// Where reminders stand on this iPhone, for Settings' row.
    func reminderSummary() async -> ReminderSummary {
        await ReminderSummary(permission: deps.notifications.permission(), settings: deps.reminderSettings.load())
    }

    /// Mail, Safari: the system opens it; in a launch state nothing leaves the app.
    func openExternal(_ url: URL) {
        guard launch == nil else { return }
        systemOpenURL(url)
    }
}
