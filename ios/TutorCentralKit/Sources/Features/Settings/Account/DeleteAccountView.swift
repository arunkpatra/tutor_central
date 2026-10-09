import DesignSystem
import Domain
import SwiftUI

/// Which board Delete account draws (`bun shots`).
public enum DeleteAccountBoardState: Sendable {
    /// The centre's name typed (P7-Delete-Typed).
    case typed
    /// The deletion running (P7-Delete-Deleting): the fixture's Apple step never answers.
    case deleting
    /// The deletion failed (P7-Delete-Failed): the fixture's deletion fails once.
    case failed
}

/// Delete account (P7-Delete): what goes, the centre's name typed to confirm, Delete my account (solid destructive,
/// live only when the name matches, loading while it runs), the line under it by phase; a failure above the field
/// with Retry. Pushed from Account. What follows a deletion (the wipe, the landing) is the store's, not the screen's.
public struct DeleteAccountView: View {
    @State private var store: DeleteAccountStore
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let boardState: DeleteAccountBoardState?
    @FocusState private var focused: Bool

    public init(store: DeleteAccountStore, boardState: DeleteAccountBoardState? = nil) {
        if boardState != nil {
            store.typed = store.centreName
        }
        _store = State(initialValue: store)
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Delete account") {
                    store.cancel()
                    dismiss()
                }
                IntroHero(
                    symbol: "trash", tint: Tokens.overdue, title: "Delete your account permanently",
                    line: "Everything in \(store.centreName) goes, and your sign-in with it. There is no way back."
                )
                NoticesCard(notices)
                if case let .failed(failure) = store.phase {
                    ErrorRow(title: failure.title, line: failure.line) { start() }
                }
                field
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    Button("Delete my account", action: start)
                        .buttonStyle(.destructive(.card, solid: true, loading: store.busy))
                        .disabled(!store.canDelete)
                    Text(footnote)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .scrollDismissesKeyboard(.interactively)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await store.load()
            if boardState == .deleting || boardState == .failed {
                start()
            }
        }
        .onChange(of: store.phase) { _, phase in
            switch phase {
            case .done: Haptic.play(.success)
            case .failed: Haptic.play(.error)
            default: break
            }
        }
    }

    private var notices: [NoticesCard.Notice] {
        let symbols = ["tray", "person.crop.circle", "apple.logo"]
        return zip(symbols, store.notices).map { NoticesCard.Notice(symbol: $0, text: $1) }
    }

    private var field: some View {
        Well(label: "Type the centre's name to confirm", focused: focused) {
            TextField(text: $store.typed) {
                Text(store.centreName).foregroundStyle(Tokens.text3.color)
            }
            .typeStyle(Tokens.body)
            .foregroundStyle(Tokens.text.color)
            .tint(Tokens.accent.color)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focused)
        }
        .disabled(store.busy)
    }

    private var footnote: String {
        store.busy
            ? "Removing everything. Keep the app open until it is done."
            : "Takes a moment. You are signed out when it is done."
    }

    private func start() {
        Keyboard.dismiss()
        Task { await store.delete() }
    }
}
