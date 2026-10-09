import DesignSystem
import Domain
import SwiftUI

/// P5-Generate and P5-Generate-Nothing: what `generate_fees` will make for the month, by class, before it runs; when
/// everyone has a fee, the month's one total row and the primary disabled.
struct GenerateSheet: View {
    let preview: GeneratePreview
    /// The month's fees as they are, for the nothing-to-create total row.
    let existing: [FeeInvoice]
    let creating: Bool
    let create: () -> Void
    let close: () -> Void
    /// The boards' sheets start 300 pt (what will be made) and 420 pt (nothing) down an 852 pt screen.
    static let fractions = (create: 0.68, nothing: 0.53)

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Generate fees", cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    Eyebrow(preview.month.title)
                    Text(preview.title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                    Text(preview.line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                }
                Card(.onSheet) {
                    VStack(spacing: 0) {
                        ForEach(preview.groups) { group in
                            OnSheetRow(label: group.line, value: group.total.formatted).rowDivider()
                        }
                        totalRow
                    }
                }
                if preview.canCreate {
                    Text(
                        "A student who already has a fee for \(preview.month.monthName) is skipped. "
                            + "You can edit any fee after."
                    )
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                }
            }
            Spacer(minLength: 0)
            Button(preview.buttonLabel, action: create)
                .buttonStyle(.primary(.sheet, loading: creating))
                .disabled(!preview.canCreate || creating)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .boardDetents(preview.canCreate ? Self.fractions.create : Self.fractions.nothing)
    }

    /// What will be made; with nothing to make, every fee the month already has.
    private var totalRow: some View {
        let count = preview.canCreate ? preview.count : existing.count
        let amount = preview.canCreate ? preview.total : existing.map(\.amount).total
        return OnSheetRow(label: FeeLedger.title(count: count, filter: .all), value: amount.formatted, strong: true)
    }
}
