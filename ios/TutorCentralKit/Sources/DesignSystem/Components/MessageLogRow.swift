import SwiftUI

/// A sent-log row (P10-Student-Messages): an icon tile by kind, the kind, the line; a chevron when it opens something;
/// a held row has the quiet Send now in its place and its tile's symbol in text3.
public struct MessageLogRow: View {
    let symbol: String
    let title: String
    let line: String
    let open: (() -> Void)?
    let held: (() -> Void)?

    public init(
        symbol: String, title: String, line: String, open: (() -> Void)? = nil, held: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.open = open
        self.held = held
    }

    public var body: some View {
        ListRow(action: held == nil ? open : nil) {
            IconTile(symbol: symbol, tint: held == nil ? Tokens.text2 : Tokens.text3)
            RowTitles(title: title, subtitle: line)
            if let held {
                Button("Send now", action: held).buttonStyle(.quiet(emphasised: true)).fixedSize()
            } else if open != nil {
                Chevron()
            }
        }
    }
}
