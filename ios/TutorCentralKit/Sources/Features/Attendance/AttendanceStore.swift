import Data
import Domain
import Foundation
import Observation

/// The mark screen (P4-Attendance-Mark-*): a date, a class, one mark per member, Save, then the absent students and
/// their alerts. One per centre (`ShellState.attendance`), so a tab switch keeps the date, the class and the unsaved
/// toggles.
@MainActor @Observable public final class AttendanceStore {
    public enum Phase: Hashable, Sendable {
        case fresh
        case saved(at: Date)
        case reopened(savedAt: Date)
        case saving
        /// Kept on this iPhone while offline (D39): it reaches the server on the next run of the queue.
        case savedHere(at: Date)
    }

    /// A row of the class menu: All students first, then each active class, with how many it holds.
    public struct ClassOption: Hashable, Sendable, Identifiable {
        public let classID: UUID?
        public let name: String
        public let count: Int
        public var id: String {
            classID?.uuidString ?? "all"
        }
    }

    /// The one line under the date and class: after a save, or on a day marked before.
    public struct MarkBanner: Hashable, Sendable {
        public let symbol: String
        public let text: String
        public let ok: Bool
        /// Kept on this iPhone: the due tone with its clock.
        public var due = false
    }

    /// An absent student of the saved class: the parent and their number, and whether they were told that day.
    public struct AbsentRow: Hashable, Sendable, Identifiable {
        public let student: Student
        public let line: String
        public let told: String?
        public var id: UUID {
            student.id
        }
    }

    public private(set) var draft: AttendanceDraft
    public internal(set) var saved: AttendanceSession?
    public internal(set) var phase: Phase = .fresh
    public private(set) var loading = false
    public internal(set) var error: String?
    /// When the month's sessions on screen were saved on this iPhone, until the network replaces them (D39).
    public internal(set) var savedAt: Date?
    /// The last read failed for the network, not the server.
    public internal(set) var offlineRead = false
    /// A month's copy on this iPhone (AppShell's): its sessions and the absence alerts told.
    public var cache: ((Period) -> CachedRead<AttendanceSnapshot>)?
    /// The centre's queue (AppShell's): a save or an alert's log made offline waits in it (D39).
    public var queue: (any ChangeQueueing)?
    /// Whether the network is there (AppShell's monitor).
    public var online: @Sendable () async -> Bool = { true }
    public var message: String?
    public internal(set) var canRetry = false
    public internal(set) var lastSavedAt: Date?
    /// True once a class and day have been opened: the empty state waits for it, and `load()` runs only once.
    public private(set) var opened = false
    /// Counts the opens asked for (the tab's first, a link, Mark attendance, the menus): only the newest lands, however
    /// the reads interleave, so a slower earlier read never replaces the day chosen last.
    private var openGeneration = 0
    var sessions: [AttendanceSession] = []
    var told: [AbsenceLog] = []
    var loadedMonth: Period?
    private var lastFailed: (@MainActor () async -> Void)?
    let workspace: Workspace
    let register: any Register
    private let attendance: any AttendanceRepository
    let messages: any MessageLogRepository
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        workspace: Workspace, register: any Register, attendance: any AttendanceRepository,
        messages: any MessageLogRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.attendance = attendance
        self.messages = messages
        self.now = now
        self.calendar = calendar
        draft = AttendanceDraft(date: Day(now(), calendar: calendar), classID: nil, members: [], saved: nil)
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    /// The active members of the chosen class by name; everyone when the class is All students.
    public var members: [Student] {
        Self.members(of: draft.classID, in: register)
    }

    public var classOptions: [ClassOption] {
        [ClassOption(classID: nil, name: "All students", count: register.activeStudents.count)]
            + register.activeClasses.map {
                ClassOption(classID: $0.id, name: $0.name, count: register.members(of: $0.id).count)
            }
    }

    public var className: String {
        register.classroom(draft.classID)?.name ?? "All students"
    }

    /// "Today, 7 Oct" or "Mon 5 Oct".
    public var dateText: String {
        draft.date == today ? "Today, \(draft.date.shortText)" : draft.date.shortWeekdayText
    }

    public var hasStudents: Bool {
        !register.activeStudents.isEmpty
    }

    /// A fresh class is always worth saving; a saved or reopened one once a mark changed; never while saving, and never
    /// while the day's sessions are unread: "everyone present" saved blind would erase real absences.
    public var canSave: Bool {
        guard phase != .saving, !members.isEmpty, error == nil, loadedMonth == draft.date.period else { return false }
        return draft.isChanged(from: saved, members: members)
    }

    public var saveLabel: String {
        saved == nil ? "Save attendance" : "Save changes"
    }

    public var banner: MarkBanner? {
        switch phase {
        case let .saved(at):
            MarkBanner(
                symbol: "checkmark.circle",
                text: "Saved at \(clock(at)). Tap a name to change a mark, then save again.",
                ok: true
            )
        case let .reopened(savedAt):
            MarkBanner(
                symbol: "clock",
                text: "Marked on \(draft.date.shortWeekdayText) at \(clock(savedAt)). Saving again replaces it.",
                ok: false
            )
        case let .savedHere(at):
            MarkBanner(
                symbol: "clock",
                text: "Saved on this iPhone at \(clock(at)). It reaches the server when you're back online.",
                ok: false, due: true
            )
        case .fresh, .saving: nil
        }
    }

    /// The absent students of the saved session (not the draft), in list order.
    public var absentRows: [AbsentRow] {
        guard let saved else { return [] }
        return members.filter { saved.marks[$0.id] == .absent }.map { student in
            let line = [student.parentName, student.parentPhone?.display].compactMap(\.self).joined(separator: " · ")
            // Matched by the day of the absence; the words name the day the parent was told.
            let toldOn = told.first { $0.studentID == student.id && $0.day(in: calendar) == saved.date }
                .map { Day($0.openedAt, calendar: calendar) }
            return AbsentRow(
                student: student,
                line: line.isEmpty ? "No parent details yet" : line,
                told: toldOn.map { $0 == today ? "Told today" : "Told \($0.shortWeekdayText)" }
            )
        }
    }

    /// The tab's first open: today, the first active class (All students when there is none). Coming back to the tab
    /// keeps the date, the class and the unsaved toggles.
    public func load() async {
        guard !opened, openGeneration == 0 else { return }
        await register.loadIfNeeded()
        // A link or Mark attendance asked for a class and day while the register was read: theirs stands.
        guard openGeneration == 0 else { return }
        await open(classID: register.activeClasses.first?.id, date: today)
    }

    /// A class and day (the menu, the date picker, Mark attendance on Today, the link): the month's sessions are read
    /// once, the saved session found, the draft made from it.
    public func open(classID: UUID?, date: Day) async {
        openGeneration += 1
        let generation = openGeneration
        await register.loadIfNeeded()
        if loadedMonth != date.period {
            loading = true
            defer { loading = false }
            let cached = cache?(date.period).load()
            do {
                async let read = attendance.sessions(centre: workspace.centre.id, month: date.period)
                async let logs = messages.absences(centre: workspace.centre.id, month: date.period)
                let (month, monthLogs) = try await (read, logs)
                guard generation == openGeneration else { return }
                (sessions, told) = (month, monthLogs)
                loadedMonth = date.period
                cache?(date.period).keep(AttendanceSnapshot(sessions: month, told: monthLogs), at: now())
                savedAt = nil
                offlineRead = false
                error = nil
            } catch {
                guard generation == openGeneration else { return }
                offlineRead = TransportError.isOffline(error)
                if !showSaved(cached, month: date.period) {
                    self.error = "Couldn't load attendance. Check your connection and try again."
                }
            }
        }
        guard generation == openGeneration else { return }
        saved = sessions.first { $0.date == date && $0.classID == classID }
        draft = AttendanceDraft(
            date: date, classID: classID, members: Self.members(of: classID, in: register), saved: saved
        )
        phase = saved.map { .reopened(savedAt: $0.savedAt) } ?? .fresh
        opened = true
    }

    public func toggle(_ studentID: UUID) {
        draft.toggle(studentID)
        if case .saved = phase, let saved {
            phase = .reopened(savedAt: saved.savedAt)
        }
    }

    /// Waits for the server: a draft shown as saved before it said so would mislead the tutor.
    @discardableResult public func save() async -> Bool {
        guard canSave else { return false }
        let before = phase
        phase = .saving
        // A student saved here before who has since left the class (or the register) keeps that mark: a save
        // replaces the marks it sends, so it sends theirs too.
        let marks = (saved?.marks ?? [:]).merging(draft.marks) { _, mark in mark }
        if await mustQueue(.attendance) {
            keepHere(marks)
            return true
        }
        do {
            let session = try await attendance.save(
                centre: workspace.centre.id, classID: draft.classID, date: draft.date, marks: marks
            )
            saved = session
            sessions.removeAll { $0.id == session.id || ($0.date == session.date && $0.classID == session.classID) }
            sessions.insert(session, at: 0)
            phase = .saved(at: session.savedAt)
            lastSavedAt = now()
            lastFailed = nil
            canRetry = false
            message = nil
            return true
        } catch {
            if queue != nil, TransportError.isOffline(error) {
                keepHere(marks)
                return true
            }
            phase = before
            message = "Couldn't save attendance. Check your connection and try again."
            canRetry = true
            lastFailed = { [weak self] in await self?.save() }
            return false
        }
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    private static func members(of classID: UUID?, in register: any Register) -> [Student] {
        guard let classID else {
            return StudentQuery.apply(
                register.activeStudents, classes: register.activeClasses, search: "", filter: .all, sort: .name
            )
        }
        return register.members(of: classID)
    }

    func clock(_ date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0)?.text ?? ""
    }
}

/// What the absence alert sheet shows (P4-Absence-Alert): the student, the parent and number (or what is missing), the
/// message, and the WhatsApp link when there is a number.
public struct AbsenceAlert: Hashable, Sendable, Identifiable {
    public let student: Student
    /// "Hemanth was absent today", "… on Mon 5 Oct".
    public let headline: String
    public let parentLine: String
    public let text: String
    public let url: URL?
    public var id: UUID {
        student.id
    }
}

/// An attendance month's copy on this iPhone (D39): its saved sessions and the absence alerts told.
public struct AttendanceSnapshot: Codable, Sendable {
    public let sessions: [AttendanceSession]
    public let told: [AbsenceLog]

    public init(sessions: [AttendanceSession], told: [AbsenceLog]) {
        self.sessions = sessions
        self.told = told
    }
}
