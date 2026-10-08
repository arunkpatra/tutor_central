import SwiftUI

/// Hero (radiusHero, padding 18), List (radiusCard, no padding: rows carry their own), Compact (radiusTile, 14),
/// Selected (accent border and haloFocus). All surface1 with a line border and shadowRaised; On sheet is surface2,
/// flat, for a list inside a sheet.
public struct Card<Content: View>: View {
    public enum Kind: Sendable {
        case hero
        case list
        case compact
        case selected
        /// A list card inside a sheet (P3-ClassDetail-AddMembers): surface2, line border, no shadow.
        case onSheet
    }

    let kind: Kind
    let content: Content

    public init(_ kind: Kind = .list, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.content = content()
    }

    private var radius: CGFloat {
        switch kind {
        case .hero: Tokens.radiusHero
        case .list, .onSheet: Tokens.radiusCard
        case .compact, .selected: Tokens.radiusTile
        }
    }

    private var padding: CGFloat {
        switch kind {
        case .hero: Tokens.cardPadding
        case .list, .onSheet: 0
        case .compact, .selected: Tokens.cardPaddingCompact
        }
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if kind == .onSheet {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Tokens.surface2.color, in: shape)
                .clipShape(shape)
                .overlay(shape.strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline))
        } else {
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surface(radius: radius, selected: kind == .selected)
        }
    }
}

public extension View {
    /// A raised surface: surface1 fill clipped to `radius`, a line border (accent when selected), shadowRaised
    /// (haloFocus
    /// when selected).
    func surface(radius: CGFloat, selected: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return background(Tokens.surface1.color, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder((selected ? Tokens.accent : Tokens.line).color, lineWidth: Tokens.hairline))
            .shadowed(selected ? Tokens.haloFocus : Tokens.shadowRaised, radius: radius)
    }

    /// The line between rows inside a list card; the last row has none. `glass` is the edge of glass (a menu's rows).
    func rowDivider(_ shown: Bool = true, glass: Bool = false) -> some View {
        overlay(alignment: .bottom) {
            if shown {
                Rectangle().fill((glass ? Tokens.lineGlass : Tokens.line).color).frame(height: Tokens.hairline)
            }
        }
    }
}
