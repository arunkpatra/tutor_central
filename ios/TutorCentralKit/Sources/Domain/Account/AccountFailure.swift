import Foundation

/// Every way an account change can fail (a password, Apple's confirmation, the deletion), as the screens say it.
public enum AccountFailure: Error, Hashable, Sendable {
    case offline
    case signedOut
    case weakPassword
    case appleRefused
    case appleUnreachable
    /// Anything else, in the server's words.
    case server(String)

    public var message: String {
        switch self {
        case .offline: "You're offline. Connect and try again."
        case .signedOut: "Your sign-in has ended. Sign in again."
        case .weakPassword: "Choose a password that's harder to guess."
        case .appleRefused: "Apple didn't accept the confirmation. Try again."
        case .appleUnreachable: "Apple didn't answer. Try again in a minute."
        case let .server(words): words
        }
    }
}
