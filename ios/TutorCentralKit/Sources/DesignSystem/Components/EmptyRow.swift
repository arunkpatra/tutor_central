import SwiftUI

/// An empty section's one row, as the Today board draws it: the symbol at 28 light in text3, then the title
/// (rowHeading) and its line (rowLine, text2); padding 16.
public struct EmptyRow: View {
    let symbol: String
    let title: String
    let line: String
    static var symbolSize: CGFloat {
        28
    }

    public init(symbol: String, title: String, line: String) {
        self.symbol = symbol
        self.title = title
        self.line = line
    }

    public var body: some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            Image(systemName: symbol)
                .font(.system(size: Self.symbolSize, weight: .light))
                .foregroundStyle(Tokens.text3.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.rowHeading).foregroundStyle(Tokens.text.color)
                Text(line)
                    .typeStyle(Tokens.rowLine)
                    .foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }
}
