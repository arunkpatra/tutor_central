import SwiftUI

/// How a stat tile's value is coloured: `text`, `text3` for a zero (the Today board), `due` for money owed.
public enum StatTone: Sendable {
    case plain
    case zero
    case due
}

/// surface1, line border, radiusTile, padding 14, shadowRaised; value numberTile, label footnote text2, 6 apart; the
/// whole tile presses. In a row whose height is fixed by its tallest tile, every tile fills that height with its words
/// at the top (U4: "Classes today" wrapping makes all three taller, never one).
public struct StatTile: View {
    let value: String
    let label: String
    let tone: StatTone
    let action: () -> Void
    static var smallestValue: CGFloat {
        0.5
    }

    public init(value: String, label: String, tone: StatTone = .plain, action: @escaping () -> Void) {
        self.value = value
        self.label = label
        self.tone = tone
        self.action = action
    }

    private var valueColor: ColorToken {
        switch tone {
        case .plain: Tokens.text
        case .zero: Tokens.text3
        case .due: Tokens.due
        }
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                // One line, always: a long amount (₹1,20,000) shrinks to fit the tile rather than wrap.
                Text(value)
                    .typeStyle(Tokens.numberTile)
                    .foregroundStyle(valueColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(Self.smallestValue)
                Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Tokens.cardPaddingCompact)
            .surface(radius: Tokens.radiusTile)
        }
        .pressable()
        .accessibilityElement(children: .combine)
    }
}
