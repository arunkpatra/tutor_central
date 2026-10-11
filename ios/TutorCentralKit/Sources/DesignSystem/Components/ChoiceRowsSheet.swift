import SwiftUI

/// Choice rows in a sheet (P10-NextStep): Cancel and the title, a line, an on-sheet card of rows (a symbol, the title,
/// what it means; the chosen one ticked in accent, the others a ring), and Use this.
public struct ChoiceRowsSheet: View {
    public struct Row: Hashable, Sendable {
        let symbol: String
        let title: String
        let meaning: String

        public init(symbol: String, title: String, meaning: String) {
            self.symbol = symbol
            self.title = title
            self.meaning = meaning
        }
    }

    let title: String
    let line: String
    let rows: [Row]
    @State private var chosen: Int
    let use: (Int) -> Void
    let cancel: () -> Void
    static var ringSize: CGFloat {
        22
    }

    public init(
        title: String, line: String, rows: [Row], chosen: Int, use: @escaping (Int) -> Void,
        cancel: @escaping () -> Void
    ) {
        self.title = title
        self.line = line
        self.rows = rows
        _chosen = State(initialValue: chosen)
        self.use = use
        self.cancel = cancel
    }

    public var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: title, cancel: ("Cancel", cancel))
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
                Card(.onSheet) {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            ListRow(action: { chosen = index }, content: {
                                Image(systemName: row.symbol)
                                    .typeStyle(Tokens.body)
                                    .foregroundStyle(Tokens.text2.color)
                                    .frame(width: IconTile.rowSize)
                                    .accessibilityHidden(true)
                                RowTitles(title: row.title, subtitle: row.meaning)
                                mark(index == chosen)
                            })
                            .accessibilityAddTraits(index == chosen ? .isSelected : [])
                            .rowDivider(index < rows.count - 1)
                        }
                    }
                }
                Button("Use this") { use(chosen) }.buttonStyle(.primary(.sheet))
                    .padding(.top, Tokens.inline)
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    @ViewBuilder private func mark(_ chosen: Bool) -> some View {
        if chosen {
            Image(systemName: "checkmark").typeStyle(Tokens.bodyStrong).foregroundStyle(Tokens.accentText.color)
                .frame(width: Self.ringSize)
        } else {
            Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline * 1.5)
                .frame(width: Self.ringSize, height: Self.ringSize)
        }
    }
}
