import SwiftUI

/// 40 × 40, round, buttonFill, lineStrong border, shadowButton, icon 20 in text; the account button shows initials in
/// accentText and carries no shadow (Kit-Controls board).
public struct IconButton: View {
    enum Face {
        case symbol(String)
        case initials(String)
    }

    let face: Face
    let label: String
    let action: () -> Void
    public static let size: CGFloat = 40

    public init(symbol: String, label: String, action: @escaping () -> Void) {
        face = .symbol(symbol)
        self.label = label
        self.action = action
    }

    public init(initials: String, label: String, action: @escaping () -> Void) {
        face = .initials(initials)
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            switch face {
            case let .symbol(name):
                IconButtonLook(symbol: name)
            case let .initials(text):
                Text(text)
                    .typeStyle(Tokens.avatar)
                    .foregroundStyle(Tokens.accentText.color)
                    // The circle keeps its size; the initials shrink into it at the largest sizes instead of "…".
                    .lineLimit(1)
                    .minimumScaleFactor(SingleLineTitle.smallest)
                    .padding(.horizontal, Tokens.rowGapInner)
                    .frame(width: Self.size, height: Self.size)
                    .background(Tokens.buttonFill.color, in: .circle)
                    .overlay(Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline))
            }
        }
        .pressable()
        .accessibilityLabel(label)
    }
}

/// The look of an icon button without the Button, for a menu or popover anchor that needs the same 40 round surface:
/// buttonFill, lineStrong border, shadowButton, the symbol 20 in text.
public struct IconButtonLook: View {
    let symbol: String

    public init(symbol: String) {
        self.symbol = symbol
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Tokens.iconButton))
            .foregroundStyle(Tokens.text.color)
            .frame(width: IconButton.size, height: IconButton.size)
            .background(Tokens.buttonFill.color, in: .circle)
            .overlay(Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline))
            .shadowed([Tokens.shadowButton], radius: IconButton.size / 2)
    }
}
