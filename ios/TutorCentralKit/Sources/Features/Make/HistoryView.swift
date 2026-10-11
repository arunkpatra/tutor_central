import DesignSystem
import Domain
import SwiftUI

/// History (P6-History, -Empty), pushed from Make's nav row and See all: what Make made and V1's results by month,
/// newest first; a row reopens it. Scans and checked papers are not listed.
public struct HistoryView: View {
    let store: MakeStore
    let actions: MakeActions
    /// AppShell's: the offline or sync line under the title (D39).
    let status: RootStatus
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: MakeStore, actions: MakeActions, status: RootStatus = .online) {
        self.store = store
        self.actions = actions
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "History") { dismiss() }
                if let line = status.line {
                    StatusLine(line)
                }
                if let error = store.historyError, !store.historyLoaded {
                    HStack(alignment: .firstTextBaseline) {
                        Text(error).typeStyle(Tokens.footnote).foregroundStyle(Tokens.overdue.color)
                        Spacer()
                        Button("Retry") { Task { await store.loadHistory() } }.buttonStyle(.quiet(emphasised: true))
                    }
                } else if store.showsEmpty {
                    Card { EmptyRow(symbol: "sparkles", title: MakeWords.emptyTitle, line: MakeWords.emptyLine) }
                } else if !store.historyLoaded {
                    Card { SkeletonRow() }
                } else {
                    ForEach(store.months, id: \.period) { month in
                        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                            Eyebrow(month.period.monthName).padding(.horizontal, Tokens.rowGapInner)
                            Card {
                                VStack(spacing: 0) {
                                    ForEach(month.rows) { row in
                                        ResultRow(symbol: row.symbol, title: row.title, line: row.line) {
                                            actions.open(row.opens)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text("Results are kept for your centre. Scans and checked papers are not listed here; what you "
                        + "added or saved is on the student's page.")
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadHistory() }
    }
}
