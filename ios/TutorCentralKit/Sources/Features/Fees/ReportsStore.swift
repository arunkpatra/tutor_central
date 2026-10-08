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

        public var title: String {
            switch self {
            case .fees: "Fees"
            case .attendance: "Attendance"
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
    public private(set) var loading = false
    public private(set) var loaded = false
    public private(set) var error: String?
    private var invoices: [FeeInvoice] = []
    private var sessions: [AttendanceSession] = []
    private var logs: [FeeLog] = []
    private var loadGeneration = 0
    private let workspace: Workspace
    private let register: any Register
    private let fees: any FeesRepository
    private let attendance: any AttendanceRepository
    private let messages: any MessageLogRepository
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        workspace: Workspace, register: any Register, fees: any FeesRepository, attendance: any AttendanceRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
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
        let count = segment == .fees ? feeLines.count : attendanceLines.count
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
            error = nil
            loaded = true
        } catch {
            guard generation == loadGeneration else { return }
            invoices = []
            sessions = []
            logs = []
            self.error = "Couldn't load the report. Check your connection and try again."
        }
    }

    public func previous() async {
        month = month.previous
        await load()
    }

    public func next() async {
        month = month.next
        await load()
    }

    public func retryLast() async {
        await load()
    }

    public func export(_ segment: Segment) -> Export {
        switch segment {
        case .fees:
            let rows = invoices.map { invoice in
                let student = register.student(invoice.studentID)
                let reminded = logs.first { $0.kind == .reminder && $0.studentID == invoice.studentID }
                return FeesCSVRow(
                    student: student?.name ?? "", className: className(student), amount: invoice.amount,
                    state: invoice.state(current: current), paidOn: invoice.paidOn(calendar: calendar),
                    paidBy: invoice.paidMethod, remindedOn: reminded.map { Day($0.openedAt, calendar: calendar) }
                )
            }
            .sorted { $0.student.localizedStandardCompare($1.student) == .orderedAscending }
            return Export(fileName: FeesCSV.fileName(month), text: FeesCSV.make(rows))
        case .attendance:
            let rows = attendanceLines.map { line in
                AttendanceCSVRow(
                    student: line.name, className: line.className, present: line.present ?? 0, absent: line.absent ?? 0
                )
            }
            return Export(fileName: AttendanceCSV.fileName(month), text: AttendanceCSV.make(rows))
        }
    }

    /// The CSV in the temporary directory, for the share sheet; nil when it cannot be written.
    public func exportFile(_ segment: Segment) -> URL? {
        let file = export(segment)
        let url = FileManager.default.temporaryDirectory.appending(path: file.fileName)
        do {
            try file.text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// The month it is now: a due fee of an earlier month is overdue.
    private var current: Period {
        Period.containing(now(), in: calendar.timeZone)
    }

    private func className(_ student: Student?) -> String {
        register.classroom(student?.classID)?.name ?? ""
    }
}
