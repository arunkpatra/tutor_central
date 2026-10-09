import Data
import Domain
import Foundation
import Observation

/// History (P4-History-ByDate, -ByStudent, -Empty): one month of saved classes, by date with the month's summary, or
/// every student with a mark that month and their percentage. Made per screen.
@MainActor @Observable public final class HistoryStore {
    public enum View: Hashable, Sendable {
        case byDate
        case byStudent
    }

    /// The month's summary card: "5 classes marked", the bar, "79%", "19 of 24 present".
    public struct Summary: Hashable, Sendable {
        public let title: String
        public let fraction: Double
        public let percent: String
        public let count: String
    }

    /// A class marked that month, newest first: "Wed" over "7 Oct", the class, "5 of 6 present", "1 absent".
    public struct DateRow: Hashable, Sendable, Identifiable {
        public let session: AttendanceSession
        public let day: String
        public let date: String
        public let title: String
        public let line: String
        public let absent: String?
        public var id: UUID {
            session.id
        }
    }

    /// A student marked that month: the bar, "33%", "1 of 3".
    public struct StudentLine: Hashable, Sendable, Identifiable {
        public let student: Student
        public let fraction: Double
        public let percent: String
        public let count: String
        public var id: UUID {
            student.id
        }
    }

    public var view: View = .byDate
    public var sortLowestFirst = false
    public private(set) var month: Period
    public private(set) var sessions: [AttendanceSession] = []
    public private(set) var loading = false
    public private(set) var error: String?
    /// When the copy on screen was saved on this iPhone, until the network replaces it (D39).
    public private(set) var savedAt: Date?
    /// The last read failed for the network, not the server.
    public private(set) var offlineRead = false
    /// A month's copy on this iPhone (AppShell's).
    public var cache: ((Period) -> CachedRead<[AttendanceSession]>)?
    private var sessionsMonth: Period?
    private let now: @Sendable () -> Date
    /// Counts the reads asked for; only the newest lands (two quick month moves can finish in the other order).
    private var loadGeneration = 0
    private let workspace: Workspace
    private let register: any Register
    private let attendance: any AttendanceRepository

    public init(
        workspace: Workspace, register: any Register, attendance: any AttendanceRepository,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india,
        cache: ((Period) -> CachedRead<[AttendanceSession]>)? = nil
    ) {
        self.cache = cache
        self.workspace = workspace
        self.register = register
        self.attendance = attendance
        self.now = now
        month = Period.containing(now(), in: calendar.timeZone)
    }

    public var monthTitle: String {
        month.title
    }

    public var summary: Summary? {
        guard !sessions.isEmpty else { return nil }
        let count = AttendanceStats.forMonth(sessions)
        return Summary(
            title: sessions.count == 1 ? "1 class marked" : "\(sessions.count) classes marked",
            fraction: count.fraction,
            percent: "\(count.percent ?? 0)%",
            count: "\(count.present) of \(count.total) present"
        )
    }

    public var dateRows: [DateRow] {
        sessions.sorted { $0.date > $1.date }.map { session in
            DateRow(
                session: session,
                day: session.date.weekday(in: DayHeading.india).short,
                date: session.date.shortText,
                title: register.classroom(session.classID)?.name ?? "All students",
                line: "\(session.presentCount) of \(session.marks.count) present",
                absent: session.absentCount == 0 ? nil : "\(session.absentCount) absent"
            )
        }
    }

    public var studentRows: [StudentLine] {
        let lines = register.activeStudents.compactMap { student -> StudentLine? in
            let count = AttendanceStats.forStudent(student.id, in: sessions)
            guard count.total > 0 else { return nil }
            return StudentLine(
                student: student,
                fraction: count.fraction,
                percent: "\(count.percent ?? 0)%",
                count: "\(count.present) of \(count.total)"
            )
        }
        return lines.sorted { lhs, rhs in
            if sortLowestFirst, lhs.fraction != rhs.fraction {
                return lhs.fraction < rhs.fraction
            }
            return lhs.student.name.localizedStandardCompare(rhs.student.name) == .orderedAscending
        }
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
        let month = month
        if sessionsMonth != month, let cached = cache?(month).load() {
            sessions = cached.value
            sessionsMonth = month
            savedAt = cached.savedAt
        }
        do {
            let read = try await attendance.sessions(centre: workspace.centre.id, month: month)
            guard generation == loadGeneration else { return }
            sessions = read
            sessionsMonth = month
            cache?(month).keep(read, at: now())
            savedAt = nil
            offlineRead = false
            error = nil
        } catch {
            guard generation == loadGeneration else { return }
            // Its screen went away mid-read: nothing failed; the next visit reads again.
            if TransportError.isCancelled(error) {
                return
            }
            offlineRead = TransportError.isOffline(error)
            let shown = sessionsMonth == month && savedAt != nil
            self.error = shown && offlineRead ? nil : "Couldn't load attendance. Check your connection and try again."
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
}
