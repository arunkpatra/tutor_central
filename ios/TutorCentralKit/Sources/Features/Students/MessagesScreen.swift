import DesignSystem
import Domain
import SwiftUI

/// The sent log (P10-Student-Messages): Back with "Messages · Dev", the line, each month's messages newest first, the
/// held note after this month with Send now; a weekly note's row opens it.
public struct MessagesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: MessagesStore
    @State private var topInset: CGFloat = 0
    let openNote: (UUID, Day) -> Void

    public init(store: MessagesStore, openNote: @escaping (UUID, Day) -> Void) {
        _store = State(initialValue: store)
        self.openNote = openNote
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.title) { dismiss() }
                Text(store.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
                if store.loadFailed {
                    LoadFailedView("Couldn't load the messages.") { Task { await store.load() } }
                }
                ForEach(Array(store.months.enumerated()), id: \.element.id) { index, month in
                    section(month.title) {
                        ForEach(month.rows) { row in
                            MessageLogRow(
                                symbol: row.symbol, title: row.title, line: row.line,
                                open: row.opens.map { day in { openNote(store.studentID, day) } }
                            )
                            .rowDivider(row.id != month.rows.last?.id)
                        }
                    }
                    if index == 0, let held = store.held {
                        heldSection(held)
                    }
                }
                if store.months.isEmpty, let held = store.held {
                    heldSection(held)
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
        .task { await store.load() }
    }

    private func heldSection(_ held: MessagesStore.Held) -> some View {
        section("Held") {
            MessageLogRow(symbol: "clock", title: held.title, line: held.line, held: {
                if let send = store.sendNow() {
                    openNote(send.0, send.1)
                } else if held.waitsForConsent {
                    dismiss()
                }
            })
        }
    }

    private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card { VStack(spacing: 0) { rows() } }
        }
    }
}
