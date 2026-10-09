import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// The Fees tab (P5-Fees-*): one month of fees with its totals, the filter, the payee card and the overdue banner; the
/// sheets over it. One per centre (`ShellState.fees`), so a tab switch keeps the month and the filter. Money is the
/// tutor's: every write waits for the server (design-tokens.md, Numbers in code).
@MainActor @Observable public final class FeesStore {
    /// The sheets over the Fees tab (P5-Generate, -MarkPaid, -Remind, -Receipt, -Waive).
    public enum Sheet: Hashable, Sendable, Identifiable {
        case generate
        case markPaid(UUID)
        case remind(UUID)
        case receipt(UUID)
        case waive(UUID)

        public var id: String {
            switch self {
            case .generate: "generate"
            case let .markPaid(id): "markPaid-\(id)"
            case let .remind(id): "remind-\(id)"
            case let .receipt(id): "receipt-\(id)"
            case let .waive(id): "waive-\(id)"
            }
        }
    }

    /// A fee row as the tab draws it (components.md, Fee row).
    public struct Row: Hashable, Sendable, Identifiable {
        public let invoice: FeeInvoice
        public let name: String
        public let line: String
        public let lineTone: StatusTone?
        public let lineSymbol: String?
        public let state: FeeState
        public let showsButtons: Bool
        public var id: UUID {
            invoice.id
        }
    }

    /// The undo toast after Mark paid: its words and the one fee it reverses.
    public struct UndoToast: Hashable, Sendable {
        public let text: String
        public let invoiceID: UUID
    }

    /// The payee card: "Parents are told to pay <id>" until confirmed, or "No UPI id yet" with Add.
    public enum Payee: Hashable, Sendable {
        case confirm(upiID: String)
        case add
    }

    public internal(set) var month: Period
    public var filter: FeeFilter = .all
    public internal(set) var invoices: [FeeInvoice] = []
    public internal(set) var dueBefore: [FeeInvoice] = []
    public internal(set) var logs: [FeeLog] = []
    public internal(set) var loading = false
    /// True once a month's read has landed.
    public internal(set) var loaded = false
    public internal(set) var error: String?
    /// When the month on screen was saved on this iPhone, until the network replaces it (D39).
    public internal(set) var savedAt: Date?
    /// The last read failed for the network, not the server.
    public internal(set) var offlineRead = false
    /// Offline (AppShell says so): Remind and Generate are disabled; Mark paid queues (D39).
    public var offline = false
    /// The centre's queue (AppShell's): a Mark paid made offline waits in it (D39).
    public var queue: (any ChangeQueueing)?
    /// Whether the network is there (AppShell's monitor).
    public var online: @Sendable () async -> Bool = { true }
    /// The fees marked paid on this iPhone and not yet sent: their rows say so.
    public internal(set) var keptHere: Set<UUID> = []
    /// What a kept-here fee was before, for its Undo.
    var beforeKept: [UUID: FeeInvoice] = [:]
    /// A month's copy on this iPhone (AppShell's; nil in previews and most tests).
    public var cache: ((Period) -> CachedRead<FeesSnapshot>)?
    public var message: String?
    public internal(set) var canRetry = false
    public internal(set) var lastSavedAt: Date?
    public var sheet: Sheet?
    /// Set after a successful Mark paid; the view shows the toast with Undo and clears it.
    public var undo: UndoToast?
    /// A write in flight: the sheet's primary shows its spinner.
    public internal(set) var writing = false
    public internal(set) var confirming = false
    public internal(set) var workspace: Workspace
    /// Told when the centre's payment settings change here (That's right), so the shell's workspace follows.
    public var onWorkspaceChanged: (Workspace) -> Void = { _ in }
    /// Told after any fee write, so the register's month chips and the student detail agree.
    public var onFeesChanged: () -> Void = {}

    let register: any Register
    let fees: any FeesRepository
    let messages: any MessageLogRepository
    let centres: any CentreRepository
    let now: @Sendable () -> Date
    let calendar: Calendar
    var lastFailed: (@MainActor () async -> Void)?
    /// A waived fee's reason while it is marked paid, so its Undo waives it again rather than leaving it due.
    var reasonsBeforePaid: [UUID: String] = [:]
    /// True once a month was asked for (the tab's first open, a link, an action from the student detail).
    private var opened = false
    /// Counts the reads asked for; only the newest lands (two quick month moves can finish in the other order).
    private var loadGeneration = 0
    /// The month `invoices` hold, so a failed move never shows another month's fees under its title.
    private var invoicesMonth: Period?

    public init(
        workspace: Workspace, register: any Register, fees: any FeesRepository, messages: any MessageLogRepository,
        centres: any CentreRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.fees = fees
        self.messages = messages
        self.centres = centres
        self.now = now
        self.calendar = calendar
        month = Period.containing(now(), in: calendar.timeZone)
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    public var monthTitle: String {
        month.title
    }

    public var totals: FeeTotals {
        FeeTotals(invoices: invoices)
    }

    /// The hero's Outstanding line; a past month's still-due fees are overdue (P5-Fees-Overdue: "1 parent, overdue").
    public var outstandingLine: String {
        let totals = totals
        return month < today.period && totals.outstandingCount > 0
            ? "\(totals.outstandingLine), overdue" : totals.outstandingLine
    }

    public var rows: [Row] {
        FeeLedger.rows(invoices, filter: filter, current: today.period) { register.student($0)?.name ?? "" }
            .map(row)
    }

    public var ledgerTitle: String {
        FeeLedger.title(count: rows.count, filter: filter)
    }

    /// The earlier months' due fees, on the current month only (P5-Fees-All's banner).
    public var overdue: OverdueSummary? {
        month == today.period ? FeeLedger.overdueBefore(dueBefore, current: today.period) : nil
    }

    public var payee: Payee? {
        let payments = workspace.centre.payments
        guard let upiID = payments.upiID else { return .add }
        return payments.needsConfirmation ? .confirm(upiID: upiID) : nil
    }

    /// Read, and nothing in it: the empty card with Generate (P5-Fees-Empty). A failed read is not empty.
    public var isEmptyMonth: Bool {
        loaded && invoices.isEmpty && error == nil && !loading && !showsNothingSaved
    }

    /// Offline with no copy of the month on this iPhone (P7-Offline-NoCache): the empty card with Try again.
    public var showsNothingSaved: Bool {
        offlineRead && invoicesMonth != month
    }

    private func apply(_ snapshot: FeesSnapshot, month: Period) {
        invoices = snapshot.invoices
        invoicesMonth = month
        dueBefore = snapshot.dueBefore
        logs = snapshot.logs
        overlayQueued()
    }

    /// What Generate will make for the shown month, counted here by `generate_fees`' rule.
    public var generatePreview: GeneratePreview {
        GeneratePreview.make(
            students: register.activeStudents, classes: register.activeClasses, invoices: invoices, month: month
        )
    }

    /// The first open: the current month, once; a month asked for meanwhile (a link) stands.
    public func load() async {
        guard !opened else { return }
        await register.loadIfNeeded()
        guard !opened else { return }
        await open(month: today.period)
    }

    public func open(month: Period) async {
        opened = true
        self.month = month
        loadGeneration += 1
        let generation = loadGeneration
        loading = true
        defer {
            if generation == loadGeneration {
                loading = false
            }
        }
        let centre = workspace.centre.id
        if invoicesMonth != month, let cached = cache?(month).load() {
            apply(cached.value, month: month)
            savedAt = cached.savedAt
            loaded = true
        }
        do {
            async let monthRead = fees.invoices(centre: centre, month: month)
            async let earlier = fees.dueBefore(centre: centre, month: today.period)
            async let logRead = messages.feeLogs(centre: centre, month: month)
            let read = try await monthRead
            let before = try await earlier
            let readLogs = try await logRead
            guard generation == loadGeneration else { return }
            let snapshot = FeesSnapshot(invoices: read, dueBefore: before, logs: readLogs)
            apply(snapshot, month: month)
            cache?(month).keep(snapshot, at: now())
            savedAt = nil
            offlineRead = false
            error = nil
            loaded = true
        } catch {
            guard generation == loadGeneration else { return }
            offlineRead = TransportError.isOffline(error)
            if invoicesMonth != month {
                invoices = []
                logs = []
                savedAt = nil
            }
            canRetry = true
            lastFailed = { [weak self] in await self?.open(month: month) }
            // Offline, the line under the title says it: a saved copy shows, or the empty card says nothing is saved.
            self.error = offlineRead ? nil : "Couldn't load fees. Check your connection and try again."
        }
    }

    public func previous() async {
        await open(month: month.previous)
    }

    public func next() async {
        await open(month: month.next)
    }

    /// The same month again: after a write from elsewhere (the student detail's actions) or a pull.
    public func reload() async {
        await open(month: month)
    }

    /// Today's Due tile: this month's fees at Due, whichever month was open (a link may have left another).
    public func showDue() async {
        filter = .due
        guard month != today.period || !loaded else { return }
        await open(month: today.period)
    }

    /// The banner: the latest month with a fee still due, from any month.
    public func openOverdue() async {
        guard let latest = FeeLedger.overdueBefore(dueBefore, current: today.period)?.latest else { return }
        await open(month: latest)
    }

    public func workspaceChanged(_ workspace: Workspace) {
        self.workspace = workspace
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    func invoice(_ id: UUID) -> FeeInvoice? {
        invoices.first { $0.id == id }
    }

    func replace(_ invoice: FeeInvoice) {
        guard let index = invoices.firstIndex(where: { $0.id == invoice.id }) else { return }
        invoices[index] = invoice
    }

    func firstName(of invoice: FeeInvoice) -> String {
        register.student(invoice.studentID)?.firstName ?? "The"
    }
}

/// A fees month's copy on this iPhone (D39): its invoices, the fees due before it, its message log.
public struct FeesSnapshot: Codable, Sendable {
    public let invoices: [FeeInvoice]
    public let dueBefore: [FeeInvoice]
    public let logs: [FeeLog]

    public init(invoices: [FeeInvoice], dueBefore: [FeeInvoice], logs: [FeeLog]) {
        self.invoices = invoices
        self.dueBefore = dueBefore
        self.logs = logs
    }
}
