import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// A student's fees (P5-StudentFees): every month with a fee, newest first, with the money pair over them. Its
/// Remind and Mark paid open on the Fees tab (`FeeAction`). Made per screen.
@MainActor @Observable public final class StudentFeesStore {
    /// A month as the screen draws it: the fee row with the month as its title.
    public struct Row: Hashable, Sendable, Identifiable {
        public let invoice: FeeInvoice
        public let title: String
        public let line: String
        public let lineTone: StatusTone?
        public let lineSymbol: String?
        public let state: FeeState
        /// Mark paid under a month not yet paid (a waived one too, the owner's call: the Waive sheet promises it).
        public let showsButtons: Bool
        /// Remind beside it while the fee is due or overdue.
        public let showsRemind: Bool
        public var id: UUID {
            invoice.id
        }
    }

    public let studentID: UUID
    public private(set) var invoices: [FeeInvoice] = []
    public private(set) var logs: [FeeLog] = []
    public private(set) var loading = false
    public private(set) var error: String?
    private let workspace: Workspace
    private let register: any Register
    private let fees: any FeesRepository
    private let messages: any MessageLogRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        studentID: UUID, workspace: Workspace, register: any Register, fees: any FeesRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.studentID = studentID
        self.workspace = workspace
        self.register = register
        self.fees = fees
        self.messages = messages
        self.now = now
        self.calendar = calendar
    }

    public var student: Student? {
        register.student(studentID)
    }

    public var title: String {
        "\(student?.firstName ?? "The student")'s fees"
    }

    public var totals: FeeTotals {
        FeeTotals(invoices: invoices)
    }

    /// The months still due, newest first: "October", "October and September", "October, September and before".
    public var outstandingLine: String {
        Self.dueLine(invoices.filter { $0.status == .due }.map(\.period).sorted(by: >))
    }

    /// "2 of 4 months".
    public var collectedLine: String {
        "\(totals.paidCount) of \(Self.months(invoices.count))"
    }

    public var sectionTitle: String {
        Self.months(invoices.count)
    }

    public var footnote: String {
        let name = student?.firstName ?? "the student"
        return "Months before \(name) joined have no fee. A month's fee is made when you generate that month."
    }

    public var rows: [Row] {
        let current = Day(now(), calendar: calendar).period
        return invoices.sorted { $0.period > $1.period }.map { invoice in
            let state = invoice.state(current: current)
            let line = line(for: invoice, state: state)
            return Row(
                invoice: invoice, title: invoice.period.title, line: line.text, lineTone: line.tone,
                lineSymbol: line.symbol, state: state, showsButtons: state != .paid, showsRemind: !state.isSettled
            )
        }
    }

    public func load() async {
        loading = true
        defer { loading = false }
        let centre = workspace.centre.id
        do {
            async let invoicesRead = fees.invoices(centre: centre, student: studentID)
            async let logsRead = messages.feeLogs(centre: centre, student: studentID)
            let read = try await invoicesRead
            let readLogs = try await logsRead
            invoices = read
            logs = readLogs
            error = nil
        } catch {
            self.error = "Couldn't load fees. Check your connection and try again."
        }
    }

    public func reload() async {
        await load()
    }

    nonisolated static func dueLine(_ months: [Period]) -> String {
        switch months.count {
        case 0: "Nothing due"
        case 1: months[0].monthName
        case 2: "\(months[0].monthName) and \(months[1].monthName)"
        default: "\(months[0].monthName), \(months[1].monthName) and before"
        }
    }

    private nonisolated static func months(_ count: Int) -> String {
        count == 1 ? "1 month" : "\(count) months"
    }

    /// The fee row's line by the Fees tab's rule: settled words, or Reminded, or the parent.
    private func line(for invoice: FeeInvoice, state: FeeState) -> FeeRowLine {
        guard !state.isSettled else { return FeeRowLine(invoice.settledLine(calendar: calendar) ?? "") }
        if let reminded = logs.first(where: { $0.kind == .reminder && $0.month == invoice.period }) {
            let day = Day(reminded.openedAt, calendar: calendar)
            let today = Day(now(), calendar: calendar)
            return FeeRowLine(
                day == today ? "Reminded today" : "Reminded \(day.shortWeekdayText)", tone: .ok, symbol: "checkmark"
            )
        }
        return FeeRowLine(FeesStore.parentLine(student) ?? "No parent details yet")
    }
}
