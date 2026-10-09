import DesignSystem
import Domain
import SwiftUI

/// What Account opens and does: Delete account on the same stack, sign-out (AppShell wipes the phone first), the
/// password sheet's store, the toasts.
public struct AccountActions {
    let openDelete: () -> Void
    let signOut: () async -> Void
    let makePassword: (_ hasPassword: Bool) -> PasswordStore
    let onMessage: (String) -> Void

    public init(
        openDelete: @escaping () -> Void, signOut: @escaping () async -> Void,
        makePassword: @escaping (_ hasPassword: Bool) -> PasswordStore, onMessage: @escaping (String) -> Void
    ) {
        self.openDelete = openDelete
        self.signOut = signOut
        self.makePassword = makePassword
        self.onMessage = onMessage
    }
}

/// Which board Account draws (`bun shots`).
public enum AccountBoardState: Sendable {
    /// The Set a password sheet, the field focused (P7-Account-Password).
    case password
    /// The sheet after a failed write (P7-Account-Password-Failed): the fixture's auth fails once.
    case passwordFailed
    /// Password Set and the toast (P7-Account-Password-Saved).
    case passwordSaved
    /// The sign-out dialog (P7-Account-SignOut, -Pending).
    case signOut
}

/// Account (P7-Account): the tutor, the sign-in methods, the password, Sign out, Delete account permanently. Pushed
/// from
/// Settings and More.
public struct AccountView: View {
    @State private var store: AccountStore
    @State private var passwordSheet: PasswordStore?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let actions: AccountActions
    private let boardState: AccountBoardState?

    public init(store: AccountStore, actions: AccountActions, boardState: AccountBoardState? = nil) {
        _store = State(initialValue: store)
        self.actions = actions
        self.boardState = boardState
        if boardState == .signOut {
            store.confirmingSignOut = true
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Account") { dismiss() }
                AccountHero(initials: store.initials, name: store.name, email: store.email)
                methods
                Card {
                    DestructiveRow(symbol: "rectangle.portrait.and.arrow.right", label: "Sign out") {
                        store.confirmingSignOut = true
                    }
                }
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader("Delete")
                    Card {
                        DestructiveRow(symbol: "trash", label: "Delete account permanently", chevron: true) {
                            actions.openDelete()
                        }
                    }
                }
                footnote("Removes your students, fees, attendance, classes and your sign-in. It cannot be undone.")
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if store.confirmingSignOut {
                signOutDialog
            }
        }
        .sheet(item: $passwordSheet) { password in
            PasswordSheet(store: password, showsFocus: boardState == .password, autofocus: boardState == nil) {
                passwordSheet = nil
                Haptic.play(.success)
                actions.onMessage(store.passwordSet())
            } close: {
                passwordSheet = nil
            }
        }
        .task {
            await store.load()
            await showBoard()
        }
    }

    private var methods: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Sign-in methods")
                Card {
                    VStack(spacing: 0) {
                        if store.methods.contains(.apple) {
                            MethodRow(symbol: "apple.logo", label: "Apple", value: "Connected", tone: Tokens.ok)
                                .rowDivider()
                        }
                        if store.methods.contains(.google) {
                            MethodRow(symbol: "g.circle", label: "Google", value: "Connected", tone: Tokens.ok)
                                .rowDivider()
                        }
                        MethodRow(symbol: "envelope", label: "Email code", value: "On").rowDivider()
                        MethodRow(symbol: "key", label: "Password", value: store.passwordValue) {
                            passwordSheet = actions.makePassword(store.hasPassword)
                        }
                    }
                }
            }
            footnote(store.methodsFootnote)
        }
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .typeStyle(Tokens.footnote)
            .foregroundStyle(Tokens.text3.color)
            .padding(.horizontal, Tokens.rowGapInner)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var signOutDialog: some View {
        let dialog = store.signOutDialog
        return ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { store.confirmingSignOut = false }
            DialogView(
                title: "Sign out?",
                message: dialog.message,
                action: dialog.action,
                destructive: true,
                onCancel: { store.confirmingSignOut = false },
                onAction: {
                    store.confirmingSignOut = false
                    Task { await actions.signOut() }
                }
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    /// The boards' states: the sheet open (empty, or after its failed write), or the toast after it was set.
    private func showBoard() async {
        switch boardState {
        case .password:
            passwordSheet = actions.makePassword(store.hasPassword)
        case .passwordFailed:
            let password = actions.makePassword(store.hasPassword)
            password.password = "brightminds2026"
            passwordSheet = password
            _ = await password.submit()
        case .passwordSaved:
            actions.onMessage(store.passwordSet())
        case .signOut, nil:
            break
        }
    }
}

extension PasswordStore: Identifiable {
    public nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
