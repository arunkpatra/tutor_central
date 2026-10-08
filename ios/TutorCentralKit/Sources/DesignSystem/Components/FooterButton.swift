import SwiftUI

/// The footer above the tab bar on a root whose primary action must never need a scroll (Save attendance): 12 of
/// ground above and below, pageSide beside; the list scrolls under its ground. Applied with
/// `.safeAreaInset(edge: .bottom)` on the root's scroll view (components.md, Footer button on a root).
public struct FooterButton<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, Tokens.pageSide)
            .padding(.vertical, Tokens.rowPaddingDense)
            .frame(maxWidth: .infinity)
            .background(Tokens.ground.color)
    }
}

/// After a save the footer's button becomes this mark: okTint fill, ok text with a tick, 50 high, radiusControl; not a
/// button.
public struct SavedMark: View {
    let text: String
    static var height: CGFloat {
        ButtonSize.card.rawValue
    }

    public init(_ text: String = "Saved") {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            Image(systemName: "checkmark").font(.system(size: Tokens.iconSmall, weight: .bold))
            Text(text)
        }
        .typeStyle(Tokens.buttonStrong)
        .foregroundStyle(Tokens.ok.color)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .background(Tokens.okTint.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
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
