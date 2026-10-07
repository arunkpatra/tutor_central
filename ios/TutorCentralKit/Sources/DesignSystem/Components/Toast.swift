import SwiftUI

/// Bottom, above the tab bar: surface1, lineStrong border, radiusTile, shadowFloat, padding 12 16, subhead, an
/// optional quiet action on the right in 700.
public struct ToastView: View {
    let message: String
    let action: (label: String, run: () -> Void)?

    public init(message: String, action: (label: String, run: () -> Void)? = nil) {
        self.message = message
        self.action = action
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Text(message).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color)
            Spacer(minLength: 0)
            if let action {
                Button(action.label, action: action.run).buttonStyle(.quiet(emphasised: true))
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .background(Tokens.surface1.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
        )
        .shadowed(Tokens.shadowFloat, radius: Tokens.radiusTile)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Under the navigation bar while offline: surface2, radius 12, padding 8 14, footnote text2 with the wifi.slash
/// symbol.
public struct OfflineBar: View {
    let text: String
    static var radius: CGFloat {
        12
    }

    public init(text: String = "Offline. Showing what was last saved.") {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            Image(systemName: "wifi.slash").font(.system(size: Tokens.iconInline))
            Text(text)
            Spacer(minLength: 0)
        }
        .typeStyle(Tokens.footnote)
        .foregroundStyle(Tokens.text2.color)
        .padding(.vertical, Tokens.inline)
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .background(Tokens.surface2.color, in: .rect(cornerRadius: Self.radius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
