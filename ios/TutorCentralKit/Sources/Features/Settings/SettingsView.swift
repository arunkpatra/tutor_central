import DesignSystem
import Domain
import SwiftUI

/// What Settings opens: the screens on the same stack and the hosted pages. A nil action leaves its row without a
/// chevron (a screen this build does not have yet).
public struct SettingsActions {
    let openPayments: () -> Void
    let openReminders: (() -> Void)?
    let openPendingChanges: (() -> Void)?
    let openAccount: () -> Void
    let openHelp: (() -> Void)?
    let openURL: (URL) -> Void
    let privacy: URL
    let terms: URL

    public init(
        openPayments: @escaping () -> Void, openReminders: (() -> Void)?, openPendingChanges: (() -> Void)?,
        openAccount: @escaping () -> Void, openHelp: (() -> Void)?, openURL: @escaping (URL) -> Void, privacy: URL,
        terms: URL
    ) {
        self.openPayments = openPayments
        self.openReminders = openReminders
        self.openPendingChanges = openPendingChanges
        self.openAccount = openAccount
        self.openHelp = openHelp
        self.openURL = openURL
        self.privacy = privacy
        self.terms = terms
    }
}

/// Which board Settings draws (`bun shots`).
public enum SettingsBoardState: Sendable {
    /// The Saved mark (P7-Settings).
    case saved
    /// Scrolled to the end (P7-Settings-End).
    case end
    /// The centre's name typed longer and its save failed (P7-Settings-SaveFailed): the fixture's repository fails.
    case saveFailed
}

/// Settings in full (P7-Settings): the teaching profile saved as you go, Parents, This iPhone, Account, About. Pushed
/// from Today's account button and More's row; the board draws it without the tab bar.
public struct SettingsView: View {
    @State private var store: SettingsStore
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let boardState: SettingsBoardState?
    private let actions: SettingsActions
    private let reminders: () async -> ReminderSummary
    private static let endID = "settings-end"

    /// `reminders` reads where the reminders stand each time Settings shows (the permission can change in iOS).
    public init(
        store: SettingsStore,
        reminders: @escaping () async -> ReminderSummary,
        actions: SettingsActions,
        boardState: SettingsBoardState? = nil,
        onWorkspaceChanged: @escaping (Workspace) -> Void
    ) {
        store.onWorkspaceChanged = onWorkspaceChanged
        if boardState == .saved {
            store.saveState = .saved
        }
        if boardState == .saveFailed {
            store.centreName = "Bright Minds Tuition Centre"
        }
        _store = State(initialValue: store)
        self.actions = actions
        self.boardState = boardState
        self.reminders = reminders
    }

    public var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    BackRow(title: "Settings") { dismiss() }
                    profile
                    parents
                    thisIPhone
                    account
                    about
                    Text("Tutor Central is made in India for tutors who run their own centre.")
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .id(Self.endID)
                }
                .padding(.horizontal, Tokens.pageSide)
                .padding(.top, max(0, Tokens.pageTop - topInset))
                .padding(.bottom, Tokens.contentBottom)
            }
            .onAppear {
                if boardState == .end {
                    reader.scrollTo(Self.endID, anchor: .bottom)
                }
            }
            .task {
                store.reminders = await reminders()
                if boardState == .saveFailed {
                    await store.commitCentre()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: store.saveState) { _, state in
            if state == .saved {
                Haptic.play(.success)
            }
        }
        .onChange(of: [store.nameError, store.centreError, store.phoneError]) { _, errors in
            // A field's line arrives with the error haptic (U33: the line, not a toast).
            if errors.contains(where: { $0 != nil }) {
                Haptic.play(.error)
            }
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("Teaching profile")
                Spacer()
                SaveMark(saving: store.saveState == .saving, saved: store.saveState == .saved)
            }
            Card {
                VStack(spacing: Tokens.cardPaddingCompact) {
                    TextWell(label: "Your name", text: $store.displayName, error: store.nameError, content: .name) {
                        Task { await store.commitName() }
                    }
                    TextWell(
                        label: "Centre name", text: $store.centreName, error: store.centreError,
                        content: .organizationName
                    ) {
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

    private var parents: some View {
        section("Parents") {
            SettingRow(
                symbol: "indianrupeesign", label: "Parent payments", trailing: { RowValue("UPI") },
                action: actions.openPayments
            )
            .rowDivider()
            SettingRow(
                symbol: "message", label: "Parent messages",
                line: "Reminders, receipts, alerts and notes open WhatsApp with the message ready.",
                trailing: { RowValue("WhatsApp") }
            )
        }
    }

    private var thisIPhone: some View {
        section("This iPhone") {
            SettingRow(
                symbol: "bell", label: "Teacher reminders", trailing: { RowValue(store.reminders.value) },
                action: actions.openReminders
            )
            .rowDivider()
            SettingRow(symbol: "hand.raised", label: "Haptic feedback") {
                Switch(isOn: $store.haptics, label: "Haptic feedback")
            }
            .rowDivider()
            SegmentedRow(
                symbol: "moon", label: "Appearance",
                options: AppearanceChoice.allCases.map { ($0, $0.label) }, selection: $store.appearance
            )
            .rowDivider()
            SettingRow(
                symbol: "tray", label: "Pending changes",
                trailing: { RowValue(SettingsStore.pendingValue(store.pendingCount)) },
                action: actions.openPendingChanges
            )
        }
    }

    private var account: some View {
        section("Account") {
            SettingRow(
                symbol: "person.crop.circle", label: "Account", trailing: { RowValue(store.email) },
                action: actions.openAccount
            )
        }
    }

    private var about: some View {
        section("About") {
            SettingRow(label: "Version") { RowValue(store.version) }.rowDivider()
            SettingRow(label: "Help", action: actions.openHelp).rowDivider()
            link("Privacy policy", actions.privacy).rowDivider()
            link("Terms of use", actions.terms)
        }
    }

    /// A row that opens a hosted page in Safari: `arrow.up.right` in text3 instead of a chevron.
    private func link(_ label: String, _ url: URL) -> some View {
        Button { actions.openURL(url) } label: {
            SettingRow(label: label) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: Tokens.iconInline, weight: .semibold))
                    .foregroundStyle(Tokens.text3.color)
                    .accessibilityHidden(true)
            }
        }
        .pressable()
        .accessibilityHint("Opens in Safari")
    }

    private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card {
                VStack(spacing: 0) { rows() }
            }
        }
    }
}
