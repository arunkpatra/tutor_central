import SwiftUI

/// Where the marks' images live: DesignSystem's own resources (`Marks.xcassets`).
enum MarkImages {
    static let bundle = Bundle.module
}

/// The app's mark on sign-in (P23-SignIn, D122): a 56 logoTile tile, radius 16, the brand kit's mark at 33 in
/// logoMark (marigold with ink in dark, charcoal with marigold in light). Drawn flat: the system's glass belongs to the
/// Home Screen icon alone.
public struct AppLogo: View {
    /// The kit's vector mark (marigold), drawn as a template so `logoMark` colours it; the file stays as the kit
    /// has it.
    static let image = "AppMark"

    static var size: CGFloat {
        56
    }

    /// 0.586 of the tile, the icon's 600 of 1024.
    static var mark: CGFloat {
        33
    }

    public init() {}

    public var body: some View {
        Image(Self.image, bundle: MarkImages.bundle)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Tokens.logoMark.color)
            .frame(width: Self.mark, height: Self.mark)
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.logoTile.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
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
        Image(Self.image, bundle: MarkImages.bundle)
            .resizable()
            .scaledToFit()
            .frame(width: Tokens.iconButton, height: Tokens.iconButton)
            .accessibilityHidden(true)
    }
}
