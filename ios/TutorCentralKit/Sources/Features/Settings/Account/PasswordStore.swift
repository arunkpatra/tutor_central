import Data
import Domain
import Foundation
import Observation

/// Set a password (P7-Account-Password): one field, 8 characters or more; the password, then `profiles.has_password`.
/// A failure keeps what was typed and says why; one write at a time.
@MainActor @Observable public final class PasswordStore {
    public var password = "" {
        didSet {
            if password != oldValue {
                error = nil
            }
        }
    }

    public private(set) var busy = false
    public private(set) var error: String?
    private let hasPassword: Bool
    private let auth: any AuthRepository
    private let centres: any CentreRepository

    public init(auth: any AuthRepository, centres: any CentreRepository, hasPassword: Bool) {
        self.auth = auth
        self.centres = centres
        self.hasPassword = hasPassword
    }

    /// "Set a password", or "Change password" once one is set (the same sheet retitled).
    public var title: String {
        hasPassword ? "Change password" : "Set a password"
    }

    public var canSubmit: Bool {
        !busy && PasswordRule.isAcceptable(password)
    }

    /// True when the password is set; refused while a write runs or under 8 characters.
    public func submit() async -> Bool {
        guard canSubmit else { return false }
        busy = true
        defer { busy = false }
        do {
            try await auth.setPassword(password)
        } catch {
            self.error = Self.words(for: error)
            return false
        }
        // The flag only offers the password at sign-in; the password itself is set, so a failure here is not the
        // tutor's failure.
        try? await centres.setHasPassword()
        return true
    }

    /// A weak password is the tutor's to change; the connection's failure says so; the server's says its words.
    static func words(for failure: AccountFailure) -> String {
        switch failure {
        case .weakPassword, .signedOut: failure.message
        case .offline: "Couldn't set the password. Check your connection and try again."
        default: "Couldn't set the password. \(failure.message)"
        }
    }
}
