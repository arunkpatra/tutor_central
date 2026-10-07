import SwiftUI

/// How a stat tile's value is coloured: `text`, `text3` for a zero (the Today board), `due` for money owed.
public enum StatTone: Sendable {
    case plain
    case zero
    case due
}

/// surface1, line border, radiusTile, padding 14, shadowRaised; value numberTile, label footnote text2, 6 apart; the
/// whole tile presses.
public struct StatTile: View {
    let value: String
    let label: String
    let tone: StatTone
    let action: () -> Void

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
                Text(value).typeStyle(Tokens.numberTile).foregroundStyle(valueColor.color)
                Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.cardPaddingCompact)
            .surface(radius: Tokens.radiusTile)
        }
        .pressable()
        .accessibilityElement(children: .combine)
    }
}
