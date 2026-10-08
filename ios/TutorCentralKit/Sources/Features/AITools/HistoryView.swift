import DesignSystem
import Domain
import SwiftUI

/// History (P6-History, -Empty), pushed from the Assistant's nav row and See all: every result by month, newest first;
/// a row reopens it. Scans and checked papers are not listed.
public struct HistoryView: View {
    let store: AIStore
    let actions: AIToolsActions
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: AIStore, actions: AIToolsActions) {
        self.store = store
        self.actions = actions
    }

    /// The months, newest first, each with its results.
    private var months: [(period: Period, items: [Generation])] {
        let grouped = Dictionary(grouping: store.history) {
            Period.containing($0.createdAt, in: store.calendar.timeZone)
        }
        return grouped.keys.sorted { $0.isoDay > $1.isoDay }.map { (period: $0, items: grouped[$0] ?? []) }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "History") { dismiss() }
                if let error = store.historyError, !store.historyLoaded {
                    HStack(alignment: .firstTextBaseline) {
                        Text(error).typeStyle(Tokens.footnote).foregroundStyle(Tokens.overdue.color)
                        Spacer()
                        Button("Retry") { Task { await store.loadHistory() } }.buttonStyle(.quiet(emphasised: true))
                    }
                } else if store.historyLoaded, store.history.isEmpty {
                    Card { EmptyRow(symbol: "sparkles", title: AIWords.emptyTitle, line: AIWords.emptyLine) }
                } else if !store.historyLoaded {
                    Card { SkeletonRow() }
                } else {
                    ForEach(months, id: \.period) { month in
                        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                            Eyebrow(month.period.monthName).padding(.horizontal, Tokens.rowGapInner)
                            Card {
                                VStack(spacing: 0) {
                                    ForEach(month.items) { generation in
                                        ResultRow(
                                            symbol: generation.kind.symbol,
                                            title: generation.title(studentName: store.studentName),
                                            line: generation.line(className: store.className, calendar: store.calendar)
                                        ) { actions.openResult(generation.id) }
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
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadHistory() }
    }
}
