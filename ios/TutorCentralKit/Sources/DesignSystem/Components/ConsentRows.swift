import SwiftUI

/// The consent section's one row (components.md "Consent section"), in its four forms: not recorded and waiting carry
/// the line and two buttons 44 high under it (the secondary ask, the primary Parent agreed); agreed carries
/// `checkmark.circle` 22 in `ok` and the quiet Change; withdrawn (P18-Student-Withdrawn) `minus.circle` 22 in `text3`
/// and the two buttons. Agreed and withdrawn show the history under the row once there is more than the first
/// agreement. The footnotes sit outside the card.
public struct ConsentRow: View {
    public struct Buttons {
        let ask: (label: String, run: () -> Void)
        let agreed: () -> Void

        public init(ask: (label: String, run: () -> Void), agreed: @escaping () -> Void) {
            self.ask = ask
            self.agreed = agreed
        }
    }

    let title: String
    let line: String
    let buttons: Buttons?
    let change: (() -> Void)?
    let symbol: (name: String, color: ColorToken)?
    let history: [ConsentHistoryLine]
    static var agreedSymbol: CGFloat {
        22
    }

    /// Not recorded, or waiting for the reply: the two buttons.
    public init(title: String, line: String, buttons: Buttons) {
        self.title = title
        self.line = line
        self.buttons = buttons
        change = nil
        symbol = nil
        history = []
    }

    /// Agreed: the tick and Change, with the history when there is one.
    public init(agreedTitle: String, line: String, history: [ConsentHistoryLine] = [], change: @escaping () -> Void) {
        title = agreedTitle
        self.line = line
        buttons = nil
        self.change = change
        symbol = ("checkmark.circle", Tokens.ok)
        self.history = history
    }

    /// Withdrawn: the mark, the history and the two buttons.
    public init(withdrawnTitle: String, line: String, history: [ConsentHistoryLine], buttons: Buttons) {
        title = withdrawnTitle
        self.line = line
        self.buttons = buttons
        change = nil
        symbol = ("minus.circle", Tokens.text3)
        self.history = history
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
            HStack(alignment: .center, spacing: Tokens.rowPaddingDense) {
                if let symbol {
                    Image(systemName: symbol.name)
                        .font(.system(size: Self.agreedSymbol))
                        .foregroundStyle(symbol.color.color)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(line)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let change {
                    Button("Change", action: change).buttonStyle(.quiet).fixedSize()
                }
            }
            if !history.isEmpty {
                ConsentHistory(lines: history)
            }
            if let buttons {
                AdaptiveRow(spacing: Tokens.tileGap, stackedSpacing: Tokens.tileGap) {
                    Button(action: buttons.ask.run) {
                        Text(buttons.ask.label).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary(.row))
                    Button(action: buttons.agreed) {
                        Label("Parent agreed", systemImage: "checkmark")
                            .typeStyle(Tokens.buttonStrong)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary(.row))
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .surface(radius: Tokens.radiusCard)
    }
}
