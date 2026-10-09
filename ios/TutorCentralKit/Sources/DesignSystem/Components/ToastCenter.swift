import Foundation
import Observation

/// One toast at a time, the newer wins; it leaves after `toastStay` (`toastStayUndo` when it carries an action).
/// `ToastHost` draws it above the tab bar, and over a sheet that is open (a failed save says so where the tutor is).
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
    /// The newest footer on screen's height, 0 when there is none: `ToastHost` lifts the toast above it (D49, U16).
    public var footerInset: CGFloat {
        footers.last?.height ?? 0
    }

    /// The footers on screen, oldest first; a footer that appears again moves to the end.
    private var footers: [(id: UUID, height: CGFloat)] = []
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

    /// A `FooterButton` on screen, or its new height.
    public func footerShown(_ id: UUID, height: CGFloat) {
        footers.removeAll { $0.id == id }
        footers.append((id, height))
    }

    /// The footer left the screen (its screen was popped, its tab left, or the footer went).
    public func footerGone(_ id: UUID) {
        footers.removeAll { $0.id == id }
    }

    static func stay(hasAction: Bool) -> Duration {
        .seconds(hasAction ? Tokens.toastStayUndo : Tokens.toastStay)
    }
}
