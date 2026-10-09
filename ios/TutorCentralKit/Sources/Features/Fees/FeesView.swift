import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the Fees tab so it can be photographed beside its board: a filter, September (the
/// overdue month), or a sheet open over October.
public enum FeesBoardState: Hashable, Sendable {
    case due
    case paid
    case september
    case generate
    case markPaid
    case markedPaid
    case receipt
    case remind
    case waive
}

/// The Fees tab's root, to P5-Fees-Empty, -All (dark and light), -Due, -Paid, -Overdue, -Payee and -MarkedPaid: the
/// month, the money pair, the payee card until the UPI id is confirmed, the overdue banner, All | Due | Paid and the
/// ledger; the sheets of P5-Generate, -MarkPaid, -Waive, -Remind and -Receipt over it.
public struct FeesView: View {
    @Bindable var store: FeesStore
    let actions: FeesActions
    let boardState: FeesBoardState?
    let status: RootStatus
    @State private var topInset: CGFloat = 0
    @Environment(\.openURL) private var openURL

    /// `status` is AppShell's: the offline or sync line under the title, and whether Remind and Generate are live.
    public init(
        store: FeesStore, actions: FeesActions, boardState: FeesBoardState? = nil, status: RootStatus = .online
    ) {
        self.store = store
        self.actions = actions
        self.boardState = boardState
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                titleRow
                if let line = status.line {
                    StatusLine(line)
                }
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    MonthHeader(
                        title: store.monthTitle,
                        previous: { Task { await store.previous() } },
                        next: { Task { await store.next() } }
                    )
                    if let error = store.error {
                        FeesErrorLine(error) { Task { await store.retryLast() } }
                    }
                    if store.showsNothingSaved {
                        NothingSavedCard(month: store.month) { Task { await store.reload() } }
                    } else if store.isEmptyMonth {
                        PayeeSection(store: store, actions: actions)
                        EmptyMonthCard(month: store.month) { store.sheet = .generate }
                    } else if store.loaded {
                        LedgerSections(store: store, actions: actions)
                    }
                }
                .opacity(store.loading ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await store.reload() }
        .sheet(item: $store.sheet) { sheet in
            FeeSheet(
                sheet: sheet,
                store: store,
                waiveReason: boardState == .waive ? "Joined mid-month" : "",
                send: send
            )
        }
        .task {
            await store.load()
            await setUpBoardState()
        }
        .onChange(of: status.offline, initial: true) { _, offline in store.offline = offline }
    }

    private var titleRow: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Fees")
                .typeStyle(Tokens.display)
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Tokens.inline)
            Button("Payments", action: actions.openPayments).buttonStyle(.quiet)
        }
    }

    /// Open WhatsApp: logs first (D3), then the link; the reminder's text is copied too, for a phone without WhatsApp.
    private func send(_ message: FeeMessageSheet) async {
        if message.kind == .reminder {
            UIPasteboard.general.string = message.text
        }
        guard let url = await store.send(message) else { return }
        store.sheet = nil
        openURL(url)
    }

    private func setUpBoardState() async {
        guard let boardState else { return }
        switch boardState {
        case .due: store.filter = .due
        case .paid: store.filter = .paid
        case .september: await store.previous()
        case .generate: store.sheet = .generate
        case .markPaid: store.sheet = .markPaid(FakeFeesRepository.devOctober)
        case .markedPaid:
            _ = await store.markPaid(FakeFeesRepository.devOctober, method: .upi, on: store.today)
            store.sheet = nil
        case .receipt: _ = await store.markPaid(FakeFeesRepository.devOctober, method: .upi, on: store.today)
        case .remind: store.sheet = .remind(FakeFeesRepository.hemanthOctober)
        case .waive:
            store.filter = .due
            store.sheet = .waive(FakeFeesRepository.sahilOctober)
        }
    }
}
