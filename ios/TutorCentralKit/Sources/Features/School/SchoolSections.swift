import DesignSystem
import Domain
import SwiftUI

/// P10-School-Empty: the empty card with its two plain-label buttons, and the footnote under it.
struct SchoolEmptyCard: View {
    let askParents: () -> Void
    let fromPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            Card {
                EmptyState(
                    symbol: "building.columns",
                    title: SchoolWords.emptyTitle,
                    line: SchoolWords.emptyLine,
                    actions: (
                        .init("Ask parents to forward", emphasis: .primary, run: askParents),
                        .init("Add from a photo", run: fromPhoto)
                    )
                )
            }
            Text(SchoolWords.emptyFootnote).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }
}

/// The list by week (P10-School-List): a section per week, a card of school rows.
struct SchoolList: View {
    let buckets: [(title: String, rows: [SchoolRowModel])]
    let open: @MainActor (UUID) -> Void

    var body: some View {
        ForEach(buckets, id: \.title) { bucket in
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader(bucket.title)
                SchoolRowsCard(rows: bucket.rows, open: open)
            }
        }
    }
}

/// A card of school rows, divided.
struct SchoolRowsCard: View {
    let rows: [SchoolRowModel]
    let open: @MainActor (UUID) -> Void

    var body: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    SchoolRow(day: row.day, date: row.date, title: row.title, line: row.line, kind: row.kind) {
                        open(row.id)
                    }
                    .rowDivider(row.id != rows.last?.id)
                }
            }
        }
    }
}

/// The "+" menu (P10-School-AddMenu) in the system popover: label left, symbol right, 46 high, 260 wide.
struct SchoolAddMenu: View {
    let fromPhoto: () -> Void
    let paste: () -> Void
    let byHand: () -> Void
    let askParents: () -> Void
    static var width: CGFloat {
        260
    }

    var body: some View {
        VStack(spacing: 0) {
            row("From a photo", symbol: "camera", action: fromPhoto).rowDivider(glass: true)
            row("Paste a message", symbol: "doc.on.clipboard", action: paste).rowDivider(glass: true)
            row("Add by hand", symbol: "pencil.line", action: byHand).rowDivider(glass: true)
            row("Ask parents to forward", symbol: "arrowshape.turn.up.right", action: askParents)
        }
        .frame(width: Self.width)
    }

    private func row(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                Spacer(minLength: 0)
                Image(systemName: symbol).accessibilityHidden(true).font(.system(size: Tokens.iconButton))
                    .foregroundStyle(Tokens.text.color)
            }
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(height: Well<EmptyView>.height)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
