import Data
import Domain
import Foundation
import Observation

/// Account (P7-Account): the tutor, the sign-in methods the account has, the password row, and what Sign out's dialog
/// says (with changes waiting, that they would be lost).
@MainActor @Observable public final class AccountStore {
    /// The sign-out dialog's words.
    public struct SignOutDialog: Equatable {
        public let message: String
        public let action: String
    }

    public let name: String
    public let email: String
    public let initials: String
    public let centreName: String
    public private(set) var methods: [SignInProvider] = []
    public private(set) var hasPassword: Bool
    public var confirmingSignOut = false
    private let auth: any AuthRepository
    private let queue: any ChangeQueueing
    private let onPasswordSet: () -> Void

    /// `onPasswordSet` tells the shell, so the session's profile reads Set too.
    public init(
        workspace: Workspace, auth: any AuthRepository, queue: any ChangeQueueing,
        onPasswordSet: @escaping () -> Void = {}
    ) {
        name = workspace.profile.displayName ?? workspace.user.fullName ?? ""
        email = workspace.user.email ?? "your Apple ID"
        initials = workspace.profile.initials
        centreName = workspace.centre.name
        hasPassword = workspace.profile.hasPassword
        self.auth = auth
        self.queue = queue
        self.onPasswordSet = onPasswordSet
    }

    public func load() async {
        methods = await auth.signInMethods()
    }

    /// "Any of these signs you in to Bright Minds Tuition. The code always works; a password is optional."
    public var methodsFootnote: String {
        "Any of these signs you in to \(centreName). The code always works; a password is optional."
    }

    /// "Not set" or "Set" (the Password row).
    public var passwordValue: String {
        hasPassword ? "Set" : "Not set"
    }

    public var signOutDialog: SignOutDialog {
        if let warning = queue.pending.signOutWarning {
            return SignOutDialog(
                message: "\(warning) Sign out now and they are lost. Connect first and they go on their own.",
                action: "Sign out anyway"
            )
        }
        return SignOutDialog(
            message: "You can sign back in with Apple, Google or your email. What Tutor Central saved on this iPhone "
                + "for \(centreName) is removed.",
            action: "Sign out"
        )
    }

    /// After the sheet set it: the row reads Set, which says so in place (U33).
    public func passwordSet() {
        hasPassword = true
        onPasswordSet()
    }
}
