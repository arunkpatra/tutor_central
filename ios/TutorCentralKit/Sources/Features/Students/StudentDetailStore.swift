import Data
import DesignSystem
import Domain
import Foundation
import Observation

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
    private let register: RegisterStore
    private let attendance: any AttendanceRepository
    private var sessions: [AttendanceSession] = []

    public init(id: UUID, register: RegisterStore, attendance: any AttendanceRepository) {
        self.id = id
        self.register = register
        self.attendance = attendance
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

    /// This month's sessions; a failed read leaves the section as it was.
    public func loadAttendance() async {
        if let read = try? await attendance.sessions(centre: register.workspace.centre.id, month: register.period) {
            sessions = read
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
            return "\(own.formatted) a month"
        }
        if let fee = classroom?.monthlyFee {
            return "\(fee.formatted) a month, the class fee"
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
        case .due: return "Due"
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
