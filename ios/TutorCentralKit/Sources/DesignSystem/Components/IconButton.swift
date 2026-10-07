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
            Group {
                switch face {
                case let .symbol(name):
                    Image(systemName: name)
                        .font(.system(size: Tokens.iconButton))
                        .foregroundStyle(Tokens.text.color)
                case let .initials(text):
                    Text(text).typeStyle(Tokens.avatar).foregroundStyle(Tokens.accentText.color)
                }
            }
            .frame(width: Self.size, height: Self.size)
            .background(Tokens.buttonFill.color, in: .circle)
            .overlay(Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline))
            .shadowed(isInitials ? [] : [Tokens.shadowButton], radius: Self.size / 2)
        }
        .pressable()
        .accessibilityLabel(label)
    }

    private var isInitials: Bool {
        if case .initials = face {
            true
        } else {
            false
        }
    }
}
