import SwiftUI

/// Draws the current toast at the bottom, above the tab bar when there is one and above a footer on screen; it slides
/// in
/// and out in `panel`.
public struct ToastHost: View {
    let toasts: ToastCenter
    let base: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(toasts: ToastCenter, bottom: CGFloat = Tokens.pageSide) {
        self.toasts = toasts
        base = bottom
    }

    /// The toast's distance from the bottom: its base (the page side, or over a sheet's footer) plus a footer on screen
    /// and a gap (D49, U16): a toast never hides Save attendance, Add N students or the Saved mark.
    public nonisolated static func bottom(base: CGFloat, footerInset: CGFloat) -> CGFloat {
        footerInset > 0 ? base + footerInset + Tokens.tileGap : base
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
                .padding(.bottom, Self.bottom(base: base, footerInset: toasts.footerInset))
                .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .timingCurve(Tokens.easeOut, duration: Tokens.panel), value: toasts.current)
    }
}

/// A toast over an open sheet: the app's toasts draw under sheets, so a failed save is said where the tutor is.
public struct SheetToasts: ViewModifier {
    let aboveFooter: Bool

    /// `aboveFooter` lifts the toast over the sheet's footer button (52 and the sheet's bottom margin), so an Undo
    /// toast never hides the sheet's one action (the receipt after Mark paid).
    public init(aboveFooter: Bool = false) {
        self.aboveFooter = aboveFooter
    }

    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    public func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toasts {
                ToastHost(
                    toasts: toasts,
                    bottom: aboveFooter ? ButtonSize.sheet.rawValue + Tokens.groupGap + Tokens.tileGap : Tokens.pageSide
                )
            }
        }
    }
}
