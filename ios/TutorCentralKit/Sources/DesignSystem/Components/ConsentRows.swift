import SwiftUI

/// The consent section's one row (components.md "Consent section"), in its three forms: not recorded and waiting carry
/// the line and two buttons 44 high under it (the secondary ask, the primary Parent agreed); agreed carries
/// `checkmark.circle` 22 in `ok` and the quiet Change. The footnotes sit outside the card.
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
    static var agreedSymbol: CGFloat {
        22
    }

    /// Not recorded, or waiting for the reply: the two buttons.
    public init(title: String, line: String, buttons: Buttons) {
        self.title = title
        self.line = line
        self.buttons = buttons
        change = nil
    }

    /// Agreed: the tick and Change.
    public init(agreedTitle: String, line: String, change: @escaping () -> Void) {
        title = agreedTitle
        self.line = line
        buttons = nil
        self.change = change
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
            HStack(alignment: .center, spacing: Tokens.rowPaddingDense) {
                if change != nil {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: Self.agreedSymbol))
                        .foregroundStyle(Tokens.ok.color)
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
