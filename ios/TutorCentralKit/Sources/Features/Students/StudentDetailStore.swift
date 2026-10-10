import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Which of the fee row's buttons was tapped (the detail hands it to the Fees tab as a `FeeAction`).
public enum FeeActionKind: Sendable {
    case remind
    case markPaid
}

@MainActor @Observable public final class StudentDetailStore {
    public static let missingMessage = "That student is no longer here."
    /// This month's attendance on the detail (P4-StudentDetail-Attendance): the month, the bar, the line, the percent.
    public struct AttendanceSummary: Hashable, Sendable {
        public let title: String
        public let fraction: Double
        public let line: String
        public let percent: String
    }

    public let id: UUID
    let register: RegisterStore
    private let attendance: any AttendanceRepository
    let messageLog: any MessageLogRepository
    let textbooks: (any TextbooksRepository)?
    let record: (any RecordRepository)?
    let now: @Sendable () -> Date
    let online: @Sendable () async -> Bool
    var sessions: [AttendanceSession] = []
    private var feeLogs: [FeeLog] = []
    // V2's record (P10-Student): the student's chapters and skills, checks and homework, every message sent.
    var chapters: [Chapter] = []
    var skills: [Skill] = []
    var checkRecords: [CheckRecord] = []
    var homeworkRecords: [HomeworkRecord] = []
    var entries: [MessageEntry] = []
    var openChapterID: UUID?
    /// The record's reads have answered (the record's board opens its chapter then).
    public internal(set) var recordLoaded = false
    /// A refused write's words for the system alert (U33); the view clears it.
    public var message: String?
    /// Consent's section (D62).
    public let consent: ConsentStore

    public init(
        id: UUID, register: RegisterStore, attendance: any AttendanceRepository, messages: any MessageLogRepository,
        textbooks: (any TextbooksRepository)? = nil, record: (any RecordRepository)? = nil,
        now: @escaping @Sendable () -> Date = Date.init, online: @escaping @Sendable () async -> Bool = { true }
    ) {
        consent = ConsentStore(
            studentID: id, register: register, messages: messages, tutorName: register.workspace.profile.displayName,
            centreName: register.workspace.centre.name, now: now, online: online
        )
        self.id = id
        self.register = register
        self.attendance = attendance
        messageLog = messages
        self.textbooks = textbooks
        self.record = record
        self.now = now
        self.online = online
    }

    /// Nil while nothing is marked this month: the empty row says so, never 0%.
    public var attendanceCard: AttendanceSummary? {
        let count = AttendanceStats.forStudent(id, in: sessions)
        guard count.total > 0 else { return nil }
        let absent = count.total - count.present
        let absences = switch absent {
        case 0: "no absences"
        case 1: "1 absence"
        default: "\(absent) absences"
        }
        return AttendanceSummary(
            title: register.period.title,
            fraction: count.fraction,
            line: "\(count.present) of \(count.total) classes · \(absences)",
            percent: "\(count.percent ?? 0)%"
        )
    }

    /// This month's sessions, the student's fee messages and the record; a failed read leaves its section as it was.
    public func load() async {
        let centre = register.workspace.centre.id
        async let sessionsRead = try? attendance.sessions(centre: centre, month: register.period)
        async let logsRead = try? messageLog.feeLogs(centre: centre, student: id)
        async let recordRead: Void = loadRecord()
        async let consentRead: Void = consent.load()
        if let read = await sessionsRead {
            sessions = read
        }
        if let read = await logsRead {
            feeLogs = read
        }
        await recordRead
        await consentRead
    }

    /// "Reminded Tue 6 Oct" once a reminder about this month's fee was opened (the latest).
    public var remindedLine: String? {
        guard student?.thisMonth?.status == .due,
              let log = feeLogs.first(where: { $0.kind == .reminder && $0.month == register.period })
        else { return nil }
        let day = Day(log.openedAt, calendar: DayHeading.india)
        return day == register.today ? "Reminded today" : "Reminded \(day.shortWeekdayText)"
    }

    /// Remind and Mark paid under this month's fee while it is due (P5-StudentDetail-Fees).
    public var showsFeeButtons: Bool {
        student?.thisMonth?.status == .due
    }

    /// What the Fees tab is asked to do for this month; nil without a fee this month.
    public func feeAction(_ kind: FeeActionKind) -> FeeAction? {
        guard student?.thisMonth != nil else { return nil }
        return switch kind {
        case .remind: .remind(studentID: id, month: register.period)
        case .markPaid: .markPaid(studentID: id, month: register.period)
        }
    }

    public var student: Student? {
        register.student(id)
    }

    public var classroom: Classroom? {
        register.classroom(student?.classID)
    }

    public var feeLine: String {
        guard let student else { return "" }
        if let own = student.monthlyFee {
            return "\(own.formatted) a month, \(Self.possessive(student.gender)) own fee"
        }
        if let fee = classroom?.monthlyFee {
            return "\(fee.formatted) a month, the batch fee"
        }
        return "No fee set yet"
    }

    public var monthTitle: String {
        register.period.title
    }

    public var monthAmount: String? {
        student?.thisMonth?.amount.formatted
    }

    public var monthLine: String {
        guard let fee = student?.thisMonth else { return "No fee for this month yet" }
        switch fee.status {
        case .paid:
            let method = fee.paidMethod.map { " by \($0.label)" } ?? ""
            let day = fee.paidOn.map { " on \($0.shortText)" } ?? ""
            return "Paid\(method)\(day)"
        case .due: return remindedLine.map { "Due · \($0)" } ?? "Due"
        case .waived: return "Waived"
        }
    }

    public var monthMark: (tone: StatusTone?, text: String)? {
        switch student?.thisMonth?.status {
        case .paid: (.ok, "Paid")
        case .due: (.due, "Due")
        case .waived: (nil, "Waived")
        case nil: nil
        }
    }

    public var archivedChip: String? {
        student?.archivedAt.map { "Archived \(Day($0, calendar: DayHeading.india).shortText)" }
    }

    public var archivedLine: String? {
        student?
            .isArchived == true ? "Archived: off the list and today's counts. Fees and attendance history are kept." :
            nil
    }

    public var notesLine: String? {
        student?.notes
    }

    public var callURL: URL? {
        student?.parentPhone.flatMap { URL(string: "tel:\($0.e164)") }
    }

    public var whatsAppURL: URL? {
        student?.parentPhone.flatMap { URL(string: "https://wa.me/\($0.e164.dropFirst())") }
    }

    public func archive() async {
        await register.setArchived(id, true)
    }

    public func restore() async {
        await register.setArchived(id, false)
    }

    public func delete() async -> Bool {
        await register.deleteStudent(id)
    }
}
