import Settings

/// Phase 7's launch states on the Settings stack: Settings, Account, Delete account, Help (P7-*).
extension RootView {
    /// What a Settings-stack state opens, or nil for a state elsewhere.
    static func settingsRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .settingsEnd, .settingsSaveFailed: [.settings]
        case .help, .helpAnswer: [.settings, .help]
        case .account, .accountPassword, .accountPasswordFailed, .accountPasswordSaved, .accountSignOut,
             .accountSignOutPending: [.settings, .account]
        case .deleteAccount, .deleteAccountTyped, .deleteAccountDeleting, .deleteAccountFailed:
            [.settings, .account, .deleteAccount]
        case .pending, .pendingDiscard: [.settings, .pendingChanges]
        default: nil
        }
    }

    static func settingsBoardState(_ state: LaunchState) -> SettingsBoardState? {
        switch state {
        case .settings: .saved
        case .settingsEnd: .end
        case .settingsSaveFailed: .saveFailed
        default: nil
        }
    }

    static func accountBoardState(_ state: LaunchState) -> AccountBoardState? {
        switch state {
        case .accountPassword: .password
        case .accountPasswordFailed: .passwordFailed
        case .accountPasswordSaved: .passwordSaved
        case .accountSignOut, .accountSignOutPending: .signOut
        default: nil
        }
    }

    static func deleteAccountBoardState(_ state: LaunchState) -> DeleteAccountBoardState? {
        switch state {
        case .deleteAccountTyped: .typed
        case .deleteAccountDeleting: .deleting
        case .deleteAccountFailed: .failed
        default: nil
        }
    }
}
