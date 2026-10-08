import SwiftUI

/// Draws the current toast at the bottom, above the tab bar when there is one; it slides in and out in `panel`.
public struct ToastHost: View {
    let toasts: ToastCenter
    let bottom: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(toasts: ToastCenter, bottom: CGFloat = Tokens.pageSide) {
        self.toasts = toasts
        self.bottom = bottom
    }

    public var body: some View {
        ZStack {
            if let toast = toasts.current {
                ToastView(
                    message: toast.message,
                    action: toast.action.map { action in
                        (label: action.label, run: {
                            action.run()
                            toasts.dismiss()
                        })
                    }
                )
                .padding(.horizontal, Tokens.pageSide)
                .padding(.bottom, bottom)
                .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .timingCurve(Tokens.easeOut, duration: Tokens.panel), value: toasts.current)
    }
}
