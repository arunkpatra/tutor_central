import Foundation

/// The push token iOS hands the app delegate, relayed to the shell (D8: UIKit's callback, SwiftUI's session). A token
/// that arrives before the shell listens is kept and handed over when it does.
@MainActor public final class PushRelay {
    public static let shared = PushRelay()

    private var kept: Data?

    /// Set by RootView once the session is ready; a kept token is handed over on set.
    public var onToken: ((Data) -> Void)? {
        didSet {
            guard let onToken, let token = kept else { return }
            kept = nil
            onToken(token)
        }
    }

    public init() {}

    public func received(_ token: Data) {
        guard let onToken else {
            kept = token
            return
        }
        onToken(token)
    }
}
