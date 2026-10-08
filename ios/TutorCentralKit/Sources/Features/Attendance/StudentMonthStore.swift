import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// One student's month (P4-History-Student; the student detail's See all): the percentage hero, the absences with
/// whether the parent was told, and the month before. Made per screen.
@MainActor @Observable public final class StudentMonthStore {
    /// The percentage hero: the month, "33%" (nil when nothing is marked), the bar, "1 of 3 classes · 2 absences".
    public struct Hero: Hashable, Sendable {
        public let eyebrow: String
        public let percent: String?
        public let fraction: Double
        public let line: String
    }

    /// An absence, newest first: the class and either "Parent told on Mon 5 Oct" in ok or the class's time.
    public struct AbsenceLine: Hashable, Sendable, Identifiable {
        public let session: AttendanceSession
        public let day: String
        public let date: String
        public let title: String
        public let line: String
        public let lineTone: StatusTone?
        public var id: UUID {
            session.id
        }
    }

    /// The month before, as one row: "September", "8 of 11 present · 3 absences".
    public struct EarlierLine: Hashable, Sendable, Identifiable {
        public let month: Period
        public let title: String
        public let line: String
        public var id: Period {
            month
        }
    }

    public let studentID: UUID
    public private(set) var month: Period
    public private(set) var loading = false
    public private(set) var error: String?
    private var sessions: [AttendanceSession] = []
    private var previous: [AttendanceSession] = []
    private var told: [AbsenceLog] = []
    private let workspace: Workspace
    private let register: any Register
    private let attendance: any AttendanceRepository
    private let messages: any MessageLogRepository
    private let calendar: Calendar

    public init(
        studentID: UUID, workspace: Workspace, register: any Register, attendance: any AttendanceRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.studentID = studentID
        self.workspace = workspace
        self.register = register
        self.attendance = attendance
        self.messages = messages
        self.calendar = calendar
        month = Period.containing(now(), in: calendar.timeZone)
    }

    public var name: String {
        register.student(studentID)?.name ?? ""
    }

    public var monthTitle: String {
        month.title
    }

    public var hero: Hero {
        let count = AttendanceStats.forStudent(studentID, in: sessions)
        guard count.total > 0 else {
            return Hero(
                eyebrow: month.title,
                percent: nil,
                fraction: 0,
                line: "Nothing marked in \(month.monthName) yet"
            )
        }
        return Hero(
            eyebrow: month.title,
            percent: "\(count.percent ?? 0)%",
            fraction: count.fraction,
            line: "\(count.present) of \(count.total) classes · \(Self.absences(count.total - count.present))"
        )
    }

    public var absences: [AbsenceLine] {
        AttendanceStats.absences(of: studentID, in: sessions).map { session in
            let toldOn = told
                .first { $0.studentID == studentID && Day($0.openedAt, calendar: calendar) == session.date }
            let classroom = register.classroom(session.classID)
            return AbsenceLine(
                session: session,
                day: session.date.weekday(in: calendar).short,
                date: session.date.shortText,
                title: classroom?.name ?? "All students",
                line: toldOn.map { _ in "Parent told on \(session.date.shortWeekdayText)" }
                    ?? classroom?.timeRange ?? "All students",
                lineTone: toldOn == nil ? nil : .ok
            )
        }
    }

    public var earlier: [EarlierLine] {
        let count = AttendanceStats.forStudent(studentID, in: previous)
        guard count.total > 0 else { return [] }
        let line = EarlierLine(
            month: month.previous,
            title: month.previous.monthName,
            line: "\(count.present) of \(count.total) present · \(Self.absences(count.total - count.present))"
        )
        return [line]
    }

    public func load() async {
        await register.loadIfNeeded()
        loading = true
        defer { loading = false }
        do {
            async let current = attendance.sessions(centre: workspace.centre.id, month: month)
            async let before = attendance.sessions(centre: workspace.centre.id, month: month.previous)
            async let logs = messages.absences(centre: workspace.centre.id, month: month)
            (sessions, previous, told) = try await (current, before, logs)
            error = nil
        } catch {
            self.error = "Couldn't load attendance. Check your connection and try again."
        }
    }

    public func previousMonth() async {
        month = month.previous
        await load()
    }

    public func nextMonth() async {
        month = month.next
        await load()
    }

    private static func absences(_ count: Int) -> String {
        switch count {
        case 0: "No absences"
        case 1: "1 absence"
        default: "\(count) absences"
        }
    }
}
