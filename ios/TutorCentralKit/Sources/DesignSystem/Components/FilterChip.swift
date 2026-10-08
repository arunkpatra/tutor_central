import SwiftUI

/// A selectable chip. Off: a neutral chip (surface2, text2 600). On: accentTint fill, accentText 700. 28 high, padding
/// 0 12. Selection haptic. Used in a row of filters and as a toggle inside a form (gender, "Every day").
public struct FilterChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void
    static var padding: CGFloat {
        12
    }

    public init(_ label: String, isOn: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button {
            action()
            Haptic.play(.selection)
        } label: {
            Text(label)
                .typeStyle(isOn ? Tokens.chipLabel : Tokens.chipNeutralLabel)
                .foregroundStyle((isOn ? Tokens.accentText : Tokens.text2).color)
                .padding(.horizontal, Self.padding)
                .frame(height: Chip.height)
                .background((isOn ? Tokens.accentTint : Tokens.surface2).color, in: .capsule)
                .contentShape(.capsule)
        }
        .pressable()
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: Tokens.inline) {
        FilterChip("All", isOn: true) {}
        FilterChip("Class 10 Maths", isOn: false) {}
        FilterChip("Archived", isOn: false) {}
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
