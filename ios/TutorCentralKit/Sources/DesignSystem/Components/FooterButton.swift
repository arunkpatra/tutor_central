import SwiftUI

/// The footer above the tab bar on a root whose primary action must never need a scroll (Save attendance): 12 of
/// ground above and below, pageSide beside; the list scrolls under its ground. Applied with
/// `.safeAreaInset(edge: .bottom)` on the root's scroll view (components.md, Footer button on a root).
/// While on screen it tells the toasts its height, so a toast sits above it (D49, U16).
public struct FooterButton<Content: View>: View {
    let content: Content
    @Environment(ToastCenter.self) private var toasts: ToastCenter?
    @State private var id = UUID()
    @State private var height: CGFloat = 0

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, Tokens.pageSide)
            .padding(.vertical, Tokens.rowPaddingDense)
            .frame(maxWidth: .infinity)
            .background(Tokens.ground.color)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { new in
                height = new
                toasts?.footerShown(id, height: new)
            }
            .onAppear {
                if height > 0 {
                    toasts?.footerShown(id, height: height)
                }
            }
            .onDisappear { toasts?.footerGone(id) }
    }
}

/// After a save the footer's button becomes this mark: okTint fill, ok text with a tick, 50 high, radiusControl; not a
/// button.
public struct SavedMark: View {
    let text: String
    let keptHere: Bool
    static var height: CGFloat {
        ButtonSize.card.rawValue
    }

    /// `keptHere` is the saved-here mark (P7-Offline-AttendanceSaved): "Saved on this iPhone" in the due tone with
    /// its clock.
    public init(_ text: String = "Saved", keptHere: Bool = false) {
        self.text = text
        self.keptHere = keptHere
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            Image(systemName: keptHere ? "clock" : "checkmark").accessibilityHidden(true)
                .font(.system(size: Tokens.iconSmall, weight: keptHere ? .semibold : .bold))
            Text(text)
        }
        .typeStyle(Tokens.buttonStrong)
        .foregroundStyle((keptHere ? Tokens.due : Tokens.ok).color)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .background(
            (keptHere ? Tokens.dueTint : Tokens.okTint).color,
            in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        FooterButton {
            Button("Save attendance") {}.buttonStyle(.primary(.card))
        }
        FooterButton {
            SavedMark()
        }
    }
    .background(Tokens.ground.color)
}
