import Data
import Domain
import Foundation
import Observation

/// Reports (P5-Reports-Fees, -Attendance, -Empty): one month's fees and attendance by student, and the two CSV files
/// to share. Made per screen; a load generation keeps the newest month's answer.
@MainActor @Observable public final class ReportsStore {
    public enum Segment: Hashable, Sendable, CaseIterable {
        case fees
        case attendance
        case progress

        public var title: String {
            switch self {
            case .fees: "Fees"
            case .attendance: "Attendance"
            case .progress: "Progress"
            }
        }
    }

    /// Progress by month or by the school's term (P10-Reports-Progress, -Term).
    public enum Span: Hashable, Sendable, CaseIterable {
        case month, term

        public var title: String {
            switch self {
            case .month: "Month"
            case .term: "Term"
            }
        }
    }

    /// A student's fee for the month: name over the class, the amount, the chip.
    public struct FeeLine: Hashable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let className: String
        public let amount: String
        public let state: FeeState
    }

    /// A student's month of attendance; nil counts when nothing was marked.
    public struct AttendanceLine: Hashable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let className: String
        public let present: Int?
        public let absent: Int?
        public let percent: String?
    }

    /// "79%", the bar, "19 of 24 marks · 5 classes marked".
    public struct AttendanceHero: Hashable, Sendable {
        public let percent: String
        public let fraction: Double
        public let line: String
    }

    /// The money pair's lines on Reports: "4 of 10 due", "6 of 10 paid".
    public struct FeesLines: Hashable, Sendable {
        public let outstandingLine: String
        public let collectedLine: String
    }

    /// A file to share: its name and its text.
    public struct Export: Hashable, Sendable {
        public let fileName: String
        public let text: String
    }

    public private(set) var month: Period
    public var segment: Segment = .fees
    public var span: Span = .month
    public var sort: ProgressSort = .lowestFirst
    /// The term Progress shows: the centre's calendar's current term until the tutor steps.
    public internal(set) var term: Term
    @ObservationIgnored var termMoved = false
    public private(set) var loading = false
    public internal(set) var loaded = false
    public internal(set) var error: String?
    /// When the report on screen was saved on this iPhone, until the network replaces it (U26).
    public internal(set) var savedAt: Date?
    public internal(set) var offlineRead = false
    var invoices: [FeeInvoice] = []
    var sessions: [AttendanceSession] = []
    var logs: [FeeLog] = []
    /// Each active student's record for the span (Progress).
    var progressInputs: [UUID: ProgressInput] = [:]
    /// The rows from this iPhone's copy, shown while the network is away.
    var progressCopy: [ProgressRow]?
    var loadGeneration = 0
    let workspace: Workspace
    let register: any Register
    let progressReader: ProgressReader?
    let cache: ReportsCache?
    private let fees: any FeesRepository
    private let attendance: any AttendanceRepository
    private let messages: any MessageLogRepository
    let calendar: Calendar
    let now: @Sendable () -> Date

    public init(
        workspace: Workspace, register: any Register, fees: any FeesRepository, attendance: any AttendanceRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india,
        progress: ProgressReader? = nil, cache: ReportsCache? = nil
    ) {
        progressReader = progress
        self.cache = cache
        term = Term.containing(Day(now(), calendar: calendar), calendar: .standard)
        self.workspace = workspace
        self.register = register
        self.fees = fees
        self.attendance = attendance
        self.messages = messages
        self.calendar = calendar
        self.now = now
        month = Period.containing(now(), in: calendar.timeZone)
    }

    public var monthTitle: String {
        month.title
    }

    public var totals: FeeTotals {
        FeeTotals(invoices: invoices)
    }

    public var feesLines: FeesLines {
        FeesLines(
            outstandingLine: "\(totals.outstandingCount) of \(totals.total) due", collectedLine: totals.collectedLine
        )
    }

    public var feeLines: [FeeLine] {
        invoices.map { invoice in
            let student = register.student(invoice.studentID)
            return FeeLine(
                id: invoice.id, name: student?.name ?? "", className: className(student),
                amount: invoice.amount.formatted,
                state: invoice.state(current: current)
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var attendanceLines: [AttendanceLine] {
        register.activeStudents.map { student in
            let count = AttendanceStats.forStudent(student.id, in: sessions)
            let marked = count.total > 0
            return AttendanceLine(
                id: student.id, name: student.name, className: className(student),
                present: marked ? count.present : nil, absent: marked ? count.total - count.present : nil,
                percent: count.percent.map { "\($0)%" }
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The whole month's marks; nil when no class was marked.
    public var attendanceHero: AttendanceHero? {
        guard !sessions.isEmpty else { return nil }
        let count = AttendanceStats.forMonth(sessions)
        let classes = sessions.count == 1 ? "1 class marked" : "\(sessions.count) classes marked"
        return AttendanceHero(
            percent: "\(count.percent ?? 0)%", fraction: count.fraction,
            line: "\(count.present) of \(count.total) marks · \(classes)"
        )
    }

    /// Read, and neither fees nor marks: "Nothing for November yet". A failed read is not empty.
    public var isEmpty: Bool {
        loaded && invoices.isEmpty && sessions.isEmpty && error == nil && !loading
    }

    public var studentsTitle: String {
        let count = switch segment {
        case .fees: feeLines.count
        case .attendance: attendanceLines.count
        case .progress: progressRows.count
        }
        return count == 1 ? "1 student" : "\(count) students"
    }

    public func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        await register.loadIfNeeded()
        loading = true
        defer {
            if generation == loadGeneration {
                loading = false
            }
        }
        followCentreCalendar()
        if segment == .progress {
            await loadProgress(generation)
            return
        }
        let centre = workspace.centre.id
        let month = month
        do {
            async let invoicesRead = fees.invoices(centre: centre, month: month)
            async let sessionsRead = attendance.sessions(centre: centre, month: month)
            async let logsRead = messages.feeLogs(centre: centre, month: month)
            let readInvoices = try await invoicesRead
            let readSessions = try await sessionsRead
            let readLogs = try await logsRead
            guard generation == loadGeneration else { return }
            invoices = readInvoices
            sessions = readSessions
            logs = readLogs
            cache?.month(month).keep(
                MonthCopy(invoices: readInvoices, sessions: readSessions, logs: readLogs),
                at: now()
            )
            (error, savedAt, offlineRead, loaded) = (nil, nil, false, true)
        } catch {
            guard generation == loadGeneration else { return }
            showMonthCopy(month, failure: error)
        }
    }

    /// This iPhone's copy of the month when the network is away; else the error line (U26).
    private func showMonthCopy(_ month: Period, failure: any Error) {
        if let copy = cache?.month(month).load() {
            invoices = copy.value.invoices
            sessions = copy.value.sessions
            logs = copy.value.logs
            (error, savedAt, offlineRead, loaded) = (nil, copy.savedAt, TransportError.isOffline(failure), true)
            return
        }
        invoices = []
        sessions = []
        logs = []
        (savedAt, offlineRead) = (nil, TransportError.isOffline(failure))
        error = "Couldn't load the report. Check your connection and try again."
    }

    /// The month back, or on Progress by term the term back.
    public func previous() async {
        if segment == .progress, span == .term {
            term = term.previous
            termMoved = true
        } else {
            month = month.previous
        }
        await load()
    }

    public func next() async {
        if segment == .progress, span == .term {
            term = term.next
            termMoved = true
        } else {
            month = month.next
        }
        await load()
    }

    public func retryLast() async {
        await load()
    }

    /// The month it is now: a due fee of an earlier month is overdue.
    var current: Period {
        Period.containing(now(), in: calendar.timeZone)
    }

    func className(_ student: Student?) -> String {
        register.classroom(student?.classID)?.name ?? ""
    }
}
