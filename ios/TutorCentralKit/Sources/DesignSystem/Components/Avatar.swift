import SwiftUI

/// Initials on accentTint in accentText: 40 in rows (14 pt), 36 in dense lists (13 pt), 56 on a detail header
/// (20 pt). Up to two letters from the first two words of the name.
public struct Avatar: View {
    let name: String
    let size: CGFloat

    public init(name: String, size: CGFloat = 40) {
        self.name = name
        self.size = size
    }

    public static func initials(of name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
    }

    public var body: some View {
        Text(Self.initials(of: name))
            .typeStyle(size <= 36 ? Tokens.avatarSmall : size >= 56 ? Tokens.avatarLarge : Tokens.avatar)
            .foregroundStyle(Tokens.accentText.color)
            .frame(width: size, height: size)
            .background(Tokens.accentTint.color, in: .circle)
            .accessibilityHidden(true)
    }
}

/// The class tile: 40, radius 12, surface2, a symbol in text2.
public struct IconTile: View {
    let symbol: String
    static var size: CGFloat {
        40
    }

    static var radius: CGFloat {
        12
    }

    public init(symbol: String) {
        self.symbol = symbol
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Tokens.iconButton))
            .foregroundStyle(Tokens.text2.color)
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.surface2.color, in: .rect(cornerRadius: Self.radius, style: .continuous))
            .accessibilityHidden(true)
    }
}
