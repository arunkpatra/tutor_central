import Foundation

/// A password set on Account (P7-Account-Password): 8 characters or more, not only spaces.
public enum PasswordRule {
    public static let minimum = 8

    public static func isAcceptable(_ password: String) -> Bool {
        password.count >= minimum && !password.allSatisfy(\.isWhitespace)
    }
}

/// Delete account's typed confirmation (P7-Delete): the centre's name, trimmed, any case, runs of spaces as one.
public enum DeletionConfirmation {
    public static func matches(typed: String, centreName: String) -> Bool {
        let wanted = fold(centreName)
        return !wanted.isEmpty && fold(typed) == wanted
    }

    private static func fold(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased()
    }
}

/// A way the tutor signs in (`auth.identities.provider`); email means the code.
public enum SignInProvider: String, Hashable, Sendable, Codable, CaseIterable {
    case apple, google, email

    /// "Apple", "Google", "Email code" (Account's sign-in methods card).
    public var label: String {
        switch self {
        case .apple: "Apple"
        case .google: "Google"
        case .email: "Email code"
        }
    }
}
