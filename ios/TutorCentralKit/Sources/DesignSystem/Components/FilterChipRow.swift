import SwiftUI

/// A list filtered to one person (P14-School-Student): the chip on (their initials and "Dev's items", accentTint,
/// accentText) and the quiet clear on the right ("Show all").
public struct FilterChipRow: View {
    let label: String
    let initials: String
    let clear: (label: String, run: () -> Void)
    static var avatarSize: CGFloat {
        20
    }

    public init(_ label: String, initials: String, clear: (label: String, run: () -> Void)) {
        self.label = label
        self.initials = initials
        self.clear = clear
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            HStack(spacing: Tokens.rowGapInner * 2) {
                Avatar(initials: initials, size: Self.avatarSize)
                Text(label).typeStyle(Tokens.chipLabel).foregroundStyle(Tokens.accentText.color)
            }
            .padding(.leading, Tokens.rowGapInner * 2)
            .padding(.trailing, Tokens.rowPaddingDense)
            .frame(minHeight: Chip.height + Tokens.rowGapInner * 2)
            .background(Tokens.accentTint.color, in: .capsule)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isSelected)
            Spacer(minLength: Tokens.inline)
            Button(clear.label, action: clear.run).buttonStyle(.quiet(emphasised: true))
        }
    }
}
