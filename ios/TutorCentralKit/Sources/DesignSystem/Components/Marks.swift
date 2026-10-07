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

/// The board's stand-in for Google's mark (A-SignIn): a 20 ring, 2 text2 stroke, a "G" at 12 heavy in text2. No
/// Google asset ships with the app.
public struct GoogleMark: View {
    static var stroke: CGFloat {
        2
    }

    static var letter: CGFloat {
        12
    }

    public init() {}

    public var body: some View {
        Text("G")
            .font(.system(size: Self.letter, weight: .heavy))
            .foregroundStyle(Tokens.text2.color)
            .frame(width: Tokens.iconButton, height: Tokens.iconButton)
            .overlay(Circle().strokeBorder(Tokens.text2.color, lineWidth: Self.stroke))
            .accessibilityHidden(true)
    }
}
