import SwiftUI

/// The app's mark on sign-in (A-SignIn, P2-SignIn-Light): a 56 accent tile, radius 16, the open book at 30 in
/// textOnAccent, shadowLogo.
public struct AppLogo: View {
    static var size: CGFloat {
        56
    }

    static var mark: CGFloat {
        30
    }

    public init() {}

    public var body: some View {
        Image(systemName: "book")
            .font(.system(size: Self.mark, weight: .medium))
            .foregroundStyle(Tokens.textOnAccent.color)
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.accent.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
            .shadowed(Tokens.shadowLogo, radius: Tokens.radiusTile)
            .accessibilityHidden(true)
    }
}

/// The tile that heads a card for a place on its way (P2-Later): 56, accentTint, radius 16, the place's symbol at 28
/// in accentText.
public struct FeatureTile: View {
    let symbol: String
    static var size: CGFloat {
        56
    }

    static var glyph: CGFloat {
        28
    }

    public init(symbol: String) {
        self.symbol = symbol
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Self.glyph))
            .foregroundStyle(Tokens.accentText.color)
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.accentTint.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Google's mark on Continue with Google (A-SignIn drew a stand-in ring): 20 pt, beside the label.
public struct GoogleMark: View {
    /// Google's own "G", in its colours, as its sign-in branding guidelines ask (the owner, 2026-10-09).
    static let image = "GoogleG"

    public init() {}

    public var body: some View {
        Image(Self.image, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: Tokens.iconButton, height: Tokens.iconButton)
            .accessibilityHidden(true)
    }
}
