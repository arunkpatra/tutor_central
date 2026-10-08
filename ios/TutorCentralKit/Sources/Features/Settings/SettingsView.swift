import DesignSystem
import Domain
import SwiftUI

/// Settings, minimal, to P2-Settings and P5-Settings: the teaching profile saved as you go, Parent payments and what
/// comes later, the account and sign out. Pushed from Today's account button; the board draws it without the tab bar.
public struct SettingsView: View {
    @State private var store: SettingsStore
    @State private var confirmingSignOut = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let onMessage: (String) -> Void
    private let openPayments: () -> Void

    /// `boardState` shows the board's "Saved" mark.
    public init(
        store: SettingsStore,
        boardState: Bool = false,
        onWorkspaceChanged: @escaping (Workspace) -> Void,
        onMessage: @escaping (String) -> Void,
        openPayments: @escaping () -> Void
    ) {
        store.onWorkspaceChanged = onWorkspaceChanged
        if boardState {
            store.saveState = .saved
        }
        _store = State(initialValue: store)
        self.onMessage = onMessage
        self.openPayments = openPayments
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                navigation
                profile
                payments
                account
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
        .overlay {
            if confirmingSignOut {
                signOutDialog
            }
        }
        .onChange(of: store.saveState) { _, state in
            if state == .saved {
                Haptic.play(.success)
            }
        }
        .onChange(of: store.message) { _, message in
            if let message {
                // Every Settings message is a failure: the error haptic with its toast.
                Haptic.play(.error)
                onMessage(message)
                store.message = nil
            }
        }
    }

    private var navigation: some View {
        ZStack {
            Text("Settings").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
            }
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("Teaching profile")
                Spacer()
                saveMark
            }
            Card {
                VStack(spacing: Tokens.cardPaddingCompact) {
                    TextWell(label: "Your name", text: $store.displayName, content: .name) {
                        Task { await store.commitName() }
                    }
                    TextWell(label: "Centre name", text: $store.centreName, content: .organizationName) {
                        Task { await store.commitCentre() }
                    }
                    PhoneWell(label: "Your WhatsApp number", digits: $store.digits, error: store.phoneError) {
                        Task { await store.commitPhone() }
                    }
                }
                .padding(Tokens.rowPaddingHorizontal)
            }
        }
    }

    private var saveMark: some View {
        SaveMark(saving: store.saveState == .saving, saved: store.saveState == .saved)
    }

    /// Parent payments live (P5-Settings), over what is still to come.
    private var payments: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Payments and later builds")
            Card {
                VStack(spacing: 0) {
                    SettingRow(
                        symbol: "indianrupeesign", label: "Parent payments",
                        trailing: { Text("UPI").typeStyle(Tokens.body).foregroundStyle(Tokens.text2.color) },
                        action: openPayments
                    )
                    .rowDivider()
                    LaterRow(symbol: "bell", label: "Reminders and haptics", phase: "Phase 7")
                }
            }
        }
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Account")
            Card {
                VStack(spacing: 0) {
                    SettingRow(label: "Signed in as") {
                        Text(store.email).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color).lineLimit(1)
                    }
                    .rowDivider()
                    SettingRow(label: "Version") {
                        Text(store.version).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                    .rowDivider()
                    Button { confirmingSignOut = true } label: {
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: Tokens.iconButton))
                            Text("Sign out").typeStyle(Tokens.bodyStrong)
                            Spacer()
                        }
                        .foregroundStyle(Tokens.overdue.color)
                        .padding(.vertical, Tokens.rowPaddingVertical)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .contentShape(.rect)
                    }
                    .pressable()
                }
            }
        }
    }

    private var signOutDialog: some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { confirmingSignOut = false }
            DialogView(
                title: "Sign out?",
                message: "You can sign back in with Apple, Google or your email.",
                action: "Sign out",
                destructive: true,
                onCancel: { confirmingSignOut = false },
                onAction: {
                    confirmingSignOut = false
                    Task { await store.signOut() }
                }
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }
}
