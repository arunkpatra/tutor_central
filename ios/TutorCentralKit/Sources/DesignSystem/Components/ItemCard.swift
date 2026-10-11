import SwiftUI

/// Item card, to check (components.md 10.5): a list card with its head (a 24 pt checkbox, the title, the kind chip, a
/// chevron) and two-column fact lines indented under the title.
public struct ItemCard<Facts: View>: View {
    @Binding var ticked: Bool
    let title: String
    let kind: KindChipKind
    let open: () -> Void
    let facts: Facts

    public init(
        ticked: Binding<Bool>, title: String, kind: KindChipKind, open: @escaping () -> Void,
        @ViewBuilder facts: () -> Facts
    ) {
        _ticked = ticked
        self.title = title
        self.kind = kind
        self.open = open
        self.facts = facts()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                HStack(spacing: Tokens.rowPaddingDense) {
                    Button {
                        ticked.toggle()
                        Haptic.play(.selection)
                    } label: {
                        CheckMark(isOn: ticked)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ticked ? "Will be added" : "Not added")
                    .accessibilityAddTraits(ticked ? .isSelected : [])
                    Button(action: open) {
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            KindChip(kind)
                            Chevron()
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: Tokens.fieldGap) { facts }
                    .padding(.leading, CheckMark.size + Tokens.rowPaddingDense)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
        }
    }
}

/// A fact under an item's title: the label 64 wide `footnote` `text3`, the value `rowLine` `text` (`text3` when
/// missing).
public struct FactLine: View {
    let label: String
    let value: String
    let missing: Bool
    static var labelWidth: CGFloat {
        64
    }

    public init(label: String, value: String, missing: Bool = false) {
        self.label = label
        self.value = value
        self.missing = missing
    }

    public var body: some View {
        AdaptiveRow(alignment: .firstTextBaseline) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                .frame(width: Self.labelWidth, alignment: .leading)
            Text(value).typeStyle(Tokens.rowLine).foregroundStyle((missing ? Tokens.text3 : Tokens.text).color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ItemCard(ticked: .constant(true), title: "Science unit test 3", kind: .exam, open: {}, facts: {
        FactLine(label: "For", value: "Class 8 at Vidya Niketan · Dev, Meher, Nikhil")
        FactLine(label: "Date", value: "Not given", missing: true)
    })
    .padding()
    .background(Tokens.ground.color)
}
