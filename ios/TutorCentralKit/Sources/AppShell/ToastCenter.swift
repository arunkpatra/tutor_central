import DesignSystem
import Foundation
import Observation

/// One toast at a time, the newer wins; it leaves after `toastStay` (`toastStayUndo` when it carries an action).
/// `ToastHost` draws it above the tab bar.
@MainActor @Observable public final class ToastCenter {
    public struct Toast: Equatable {
        public let message: String
        public let action: (label: String, run: @MainActor () -> Void)?
        let id: UUID

        public static func == (lhs: Toast, rhs: Toast) -> Bool {
            lhs.id == rhs.id
        }
    }

    public private(set) var current: Toast?
    private var leaving: Task<Void, Never>?

    public init() {}

    public func show(
        _ message: String,
        action: (label: String, run: @MainActor () -> Void)? = nil,
        stay: Duration? = nil
    ) {
        leaving?.cancel()
        let toast = Toast(message: message, action: action, id: UUID())
        current = toast
        leaving = Task { [weak self] in
            try? await Task.sleep(for: stay ?? Self.stay(hasAction: action != nil))
            guard !Task.isCancelled, self?.current == toast else { return }
            self?.dismiss()
        }
    }

    public func dismiss() {
        leaving?.cancel()
        current = nil
    }

    static func stay(hasAction: Bool) -> Duration {
        .seconds(hasAction ? Tokens.toastStayUndo : Tokens.toastStay)
    }
}
