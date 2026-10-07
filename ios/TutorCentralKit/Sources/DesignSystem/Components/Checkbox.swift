import SwiftUI

/// 24 round, lineStrong ring 1.5; checked: ok fill with a white tick, the label struck through in text2. Selection
/// haptic.
public struct Checkbox: View {
    @Binding var isOn: Bool
    let label: String
    static var size: CGFloat {
        24
    }

    static var ring: CGFloat {
        1.5
    }

    static var tick: CGFloat {
        12
    }

    public init(isOn: Binding<Bool>, label: String) {
        _isOn = isOn
        self.label = label
    }

    public var body: some View {
        Button {
            isOn.toggle()
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.tileGap) {
                ZStack {
                    if isOn {
                        Circle().fill(Tokens.ok.color)
                        Image(systemName: "checkmark")
                            .font(.system(size: Self.tick, weight: .bold))
                            .foregroundStyle(Tokens.onStatus.color)
                    } else {
                        Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Self.ring)
                    }
                }
                .frame(width: Self.size, height: Self.size)
                Text(label)
                    .typeStyle(Tokens.subhead)
                    .strikethrough(isOn)
                    .foregroundStyle((isOn ? Tokens.text2 : Tokens.text).color)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// The system switch, tinted accent (51 × 31; the off track is the system's).
public struct Switch: View {
    @Binding var isOn: Bool
    let label: String

    public init(isOn: Binding<Bool>, label: String) {
        _isOn = isOn
        self.label = label
    }

    public var body: some View {
        Toggle(label, isOn: $isOn).labelsHidden().tint(Tokens.accent.color).accessibilityLabel(label)
    }
}
