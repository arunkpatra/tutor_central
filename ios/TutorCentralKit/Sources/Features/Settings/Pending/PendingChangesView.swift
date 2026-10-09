import Data
import DesignSystem
import Domain
import SwiftUI

/// Pending changes (P7-Pending, -Discard): the order made, each change's state and when, a failed one's reason and
/// Discard (confirmed); Send again in the footer band. Pushed from Settings and from the failure line on every root.
public struct PendingChangesView: View {
    @State private var store: PendingChangesStore
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let onChanged: (RunOutcome?) -> Void

    /// `boardDiscard` opens the dialog over the failed row (P7-Pending-Discard). `onChanged` is AppShell's (after Send
    /// again or a discard):
    /// and back when nothing is left.
    public init(store: PendingChangesStore, boardDiscard: Bool = false, onChanged: @escaping (RunOutcome?) -> Void) {
        if boardDiscard {
            store.confirmingDiscard = store.rows.first { $0.state != .waiting }?.id
        }
        _store = State(initialValue: store)
        self.onChanged = onChanged
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Pending changes") { dismiss() }
                Text("Saved on this iPhone while you were offline, in the order you made them.")
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                if !store.rows.isEmpty {
                    Card {
                        VStack(spacing: 0) {
                            ForEach(store.rows) { change in
                                PendingRow(
                                    symbol: Self.symbol(change.kind), title: change.title,
                                    line: store.line(for: change), failure: Self.failure(change.state)
                                ) {
                                    store.confirmingDiscard = change.id
                                }
                                .rowDivider(change.id != store.rows.last?.id)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if let id = store.confirmingDiscard {
                discardDialog(id)
            }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                Button("Send again") {
                    Task { await onChanged(store.sendAgain()) }
                }
                .buttonStyle(.primary(.card, loading: store.sending))
                .disabled(!store.canSend)
                Text(
                    "Each change is sent on its own; one that fails doesn't hold up the rest. A failed change stays "
                        + "here until you discard it."
                )
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
            }
        }
    }

    private func discardDialog(_ id: UUID) -> some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { store.confirmingDiscard = nil }
            DialogView(
                title: "Discard this change?", message: store.discardWords(for: id), action: "Discard",
                destructive: true, onCancel: { store.confirmingDiscard = nil },
                onAction: {
                    store.discard(id: id)
                    onChanged(nil)
                }
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    static func symbol(_ kind: QueuedChange.Kind) -> String {
        switch kind {
        case .attendance: "checkmark.circle"
        case .markPaid: "indianrupeesign"
        case .absenceLog: "text.bubble"
        }
    }

    static func failure(_ state: QueuedChange.State) -> String? {
        guard case let .failed(reason) = state else { return nil }
        return reason
    }
}
