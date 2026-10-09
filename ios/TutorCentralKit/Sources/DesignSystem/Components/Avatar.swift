import SwiftUI

/// Initials on accentTint in accentText: 40 in rows (14 pt), 36 in dense lists (13 pt), 56 on a detail header
/// (20 pt). Up to two letters from the first two words of the name.
public struct Avatar: View {
    let initials: String
    let size: CGFloat

    /// The initials as the caller made them (the Domain's `NameInitials`).
    public init(initials: String, size: CGFloat = 40) {
        self.initials = initials
        self.size = size
    }

    public init(name: String, size: CGFloat = 40) {
        self.init(initials: Self.initials(of: name), size: size)
    }

    public static func initials(of name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
    }

    public var body: some View {
        Text(initials)
            .typeStyle(size <= 36 ? Tokens.avatarSmall : size >= 56 ? Tokens.avatarLarge : Tokens.avatar)
            .foregroundStyle(Tokens.accentText.color)
            // The circle keeps its size; at the largest text sizes the initials shrink into it instead of "…".
            .lineLimit(1)
            .minimumScaleFactor(SingleLineTitle.smallest)
            .padding(.horizontal, Tokens.rowGapInner)
            .frame(width: size, height: size)
            .background(Tokens.accentTint.color, in: .circle)
            .accessibilityHidden(true)
    }
}

/// The class tile: surface2 with a symbol in text2; 40 with radius 12 in rows, 56 with radiusTile and the symbol at
/// 28 on the class detail header.
public struct IconTile: View {
    public enum Size: Sendable {
        case row
        case header
    }

    let symbol: String
    let size: Size
    let tint: ColorToken
    static var rowSize: CGFloat {
        40
    }

    static var rowRadius: CGFloat {
        12
    }

    static var headerSize: CGFloat {
        56
    }

    static var headerSymbol: CGFloat {
        28
    }

    /// `tint` colours the symbol (overdue on Delete account's hero, P7-Delete).
    public init(symbol: String, size: Size = .row, tint: ColorToken = Tokens.text2) {
        self.symbol = symbol
        self.size = size
        self.tint = tint
    }

    public var body: some View {
        let header = size == .header
        let side = header ? Self.headerSize : Self.rowSize
        Image(systemName: symbol)
            .font(.system(size: header ? Self.headerSymbol : Tokens.iconButton))
            .foregroundStyle(tint.color)
            .frame(width: side, height: side)
            .background(
                Tokens.surface2.color,
                in: .rect(cornerRadius: header ? Tokens.radiusTile : Self.rowRadius, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: Tokens.tileGap) {
        Avatar(initials: "AR")
        Avatar(initials: "AR", size: 56)
        IconTile(symbol: "book.closed")
        IconTile(symbol: "book.closed", size: .header)
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
