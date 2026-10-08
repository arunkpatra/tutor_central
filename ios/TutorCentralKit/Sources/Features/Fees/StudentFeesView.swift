import DesignSystem
import Domain
import SwiftUI

/// A student's fees (P5-StudentFees), pushed from the detail's See all: the money pair over the months with a fee,
/// one row per month, and the footnote. Remind and Mark paid open on the Fees tab.
public struct StudentFeesView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: StudentFeesStore
    let act: (FeeAction) -> Void
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StudentFeesStore, act: @escaping (FeeAction) -> Void) {
        _store = State(initialValue: store)
        self.act = act
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.title) { dismiss() }
                if let error = store.error {
                    FeesErrorLine(error) { Task { await store.reload() } }
                }
                Group {
                    MoneyPair(
                        outstanding: store.totals.outstanding.formatted, outstandingLine: store.outstandingLine,
                        collected: store.totals.collected.formatted, collectedLine: store.collectedLine
                    )
                    months
                    Text(store.footnote)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                }
                .opacity(store.loading ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.reload() }
            }
        }
    }

    private var months: some View {
        let rows = store.rows
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.sectionTitle)
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        FeeRow(
                            title: row.title, line: FeeRowLine(row.line, tone: row.lineTone, symbol: row.lineSymbol),
                            amount: row.invoice.amount.formatted, chip: LedgerSections.chip(row.state),
                            buttons: row.showsButtons ? buttons(row) : nil
                        )
                        .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }

    private func buttons(_ row: StudentFeesStore.Row) -> FeeButtons {
        let month = row.invoice.period
        let student = store.studentID
        return FeeButtons(
            remind: row.showsRemind ? { act(.remind(studentID: student, month: month)) } : nil,
            markPaid: { act(.markPaid(studentID: student, month: month)) }
        )
    }
}
