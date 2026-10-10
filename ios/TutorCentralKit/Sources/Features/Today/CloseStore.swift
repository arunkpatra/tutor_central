import Data
import Domain
import Foundation
import Observation

/// One check of the close: the skill as the eyebrow, the question, the expected answer, the tap.
public struct CheckLine: Identifiable, Hashable, Sendable {
    public var id: UUID {
        skillID
    }

    public let skillID: UUID
    public let skill: String
    public let question: String
    public let answer: String
    public var tap: Bool?
    /// The tap on record when today's close is opened again: an unchanged tap moves no state a second time.
    let recorded: Bool?
    let isPlacement: Bool
}

/// What a student's card asks: three checks, the placement, nothing (no book yet), or why the checks could not be made.
public enum CloseChecks: Hashable, Sendable {
    case loading
    case rows([CheckLine])
    case placement([PlacementSubject])
    case none
    case failed(String)
}

/// One student of the close: present, the checks, the homework switch, the catch-up line.
public struct CloseStudent: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let firstName: String
    public let initials: String
    public var present: Bool
    public var checks: CloseChecks
    public var homeworkGiven: Bool
    /// "Catch up · missed Mon and Fri": absent at the batch's last two sessions.
    public let catchUp: String?
}

public enum ClosePhase: Hashable, Sendable {
    case open
    case closing
    case closed(at: Date)
    /// Kept on this iPhone while offline (D39): sent with the queue's next run.
    case savedHere(at: Date)
}

/// The close (P10-Close, -Scrolled, -Placement; docs/spec-v2.md section 6): everyone starts present with homework
/// given; each student gets three checks from the spaced queue, the placement when nothing is taught yet, or attendance
/// and homework alone without a book. Done writes the marks, the tapped checks, the homework, the skill states and
/// every
/// student's status in one call. Opened again the same day it shows what was kept.
@MainActor @Observable public final class CloseStore {
    public internal(set) var students: [CloseStudent] = []
    public internal(set) var phase: ClosePhase = .open
    public internal(set) var loaded = false
    /// A refused write's words for the system alert (U33).
    public var message: String?
    /// The centre's queue (AppShell's): a close made offline waits in it (D39).
    public var queue: (any ChangeQueueing)?
    public var online: @Sendable () async -> Bool = { true }

    let classID: UUID
    let workspace: Workspace
    let register: any Register
    let textbooks: any TextbooksRepository
    let record: any RecordRepository
    let attendance: any AttendanceRepository
    let ai: any AIRepository
    let now: @Sendable () -> Date
    let calendar: Calendar
    var chapters: [UUID: [Chapter]] = [:]
    var skills: [UUID: [Skill]] = [:]
    /// The students' checks and homework of the last four weeks, before this close.
    var history: [CheckRecord] = []
    var homeworkHistory: [HomeworkRecord] = []
    var sessions: [AttendanceSession] = []
    /// Today's session of the batch when it was already closed (opened again).
    var closedSession: AttendanceSession?

    public init(
        classID: UUID, workspace: Workspace, register: any Register, textbooks: any TextbooksRepository,
        record: any RecordRepository, attendance: any AttendanceRepository, ai: any AIRepository,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.classID = classID
        self.workspace = workspace
        self.register = register
        self.textbooks = textbooks
        self.record = record
        self.attendance = attendance
        self.ai = ai
        self.now = now
        self.calendar = calendar
    }

    var day: Day {
        Day(now(), calendar: calendar)
    }

    var classroom: Classroom? {
        register.classroom(classID)
    }

    public var title: String {
        "Close the class"
    }

    public var batchName: String {
        classroom?.name ?? ""
    }

    /// "Wednesday 7 October · 17:00–18:30 · 5 students".
    public var batchLine: String {
        let count = register.members(of: classID).count
        return [
            DayHeading.long(now(), calendar: calendar), classroom?.timeRange,
            count == 1 ? "1 student" : "\(count) students",
        ].compactMap(\.self).joined(separator: " · ")
    }

    public var intro: String {
        "Everyone starts present and homework given. Tap what changed, tap each check as the student answers, then "
            + "Done. Done with attendance alone is a close too."
    }

    public var footnote: String {
        "Writes attendance for today, the checks and the homework in one go. The next plan follows from it."
    }

    /// "4 of 5 came, 1 check right".
    public var summary: String {
        let present = students.filter(\.present)
        let right = present.map { Self.taps($0.checks).count { $0.tap == true } }.reduce(0, +)
        return "\(present.count) of \(students.count) came, \(right) \(right == 1 ? "check" : "checks") right"
    }

    public var closing: Bool {
        phase == .closing
    }

    /// The members, the month's sessions, each student's chapters, skills and record, then the checks at once.
    public func load() async {
        await register.loadIfNeeded()
        await readSessions()
        let members = register.members(of: classID).sorted { $0.name < $1.name }
        let ids = members.map(\.id)
        await readRecords(ids)
        closedSession = sessions.first { $0.date == day && $0.classID == classID && $0.closedAt != nil }
        let kept = closedSession.map { session in history.filter { $0.sessionID == session.id } } ?? []
        let given = closedSession.map { session in homeworkHistory.filter { $0.sessionID == session.id } } ?? []
        students = members.map { student in
            CloseStudent(
                id: student.id, name: student.name, firstName: student.firstName, initials: student.initials,
                present: closedSession?.marks[student.id] != .absent,
                checks: keptChecks(kept.filter { $0.studentID == student.id }, student: student.id) ?? .loading,
                homeworkGiven: closedSession == nil || given.contains { $0.studentID == student.id },
                catchUp: catchUp(student.id)
            )
        }
        if let closedSession, let at = closedSession.closedAt {
            phase = .closed(at: at)
            history.removeAll { $0.sessionID == closedSession.id }
            homeworkHistory.removeAll { $0.sessionID == closedSession.id }
        }
        loaded = true
        await makeChecks(students.indices.filter { students[$0].present && students[$0].checks == .loading })
    }

    public func toggle(_ index: Int) {
        guard students.indices.contains(index) else { return }
        students[index].present.toggle()
        if students[index].present, students[index].checks == .loading {
            Task { await makeChecks([index]) }
        }
    }

    public func setHomework(_ index: Int, given: Bool) {
        guard students.indices.contains(index) else { return }
        students[index].homeworkGiven = given
    }

    /// Right or Wrong on a check; the same again clears it.
    public func tap(_ index: Int, _ row: Int, right: Bool) {
        guard case let .rows(rows)? = students[safe: index]?.checks, rows.indices.contains(row) else { return }
        setTap(index, row, rows[row].tap == right ? nil : right)
    }

    /// The check row's binding: the tap as `CheckRow` set it.
    public func setTap(_ index: Int, _ row: Int, _ tap: Bool?) {
        guard case var .rows(rows)? = students[safe: index]?.checks, rows.indices.contains(row) else { return }
        rows[row].tap = tap
        students[index].checks = .rows(rows)
    }

    public func tapPlacement(_ index: Int, subject: Int, row: Int, right: Bool) {
        guard case let .placement(subjects)? = students[safe: index]?.checks,
              subjects[safe: subject]?.rows.indices.contains(row) == true else { return }
        let current = subjects[subject].rows[row].tap
        setPlacementTap(index, subject: subject, row: row, current == right ? nil : right)
    }

    public func setPlacementTap(_ index: Int, subject: Int, row: Int, _ tap: Bool?) {
        guard case var .placement(subjects)? = students[safe: index]?.checks,
              subjects[safe: subject]?.rows.indices.contains(row) == true else { return }
        subjects[subject].rows[row].tap = tap
        students[index].checks = .placement(subjects)
    }

    /// The tappable rows of a card, the placement's included.
    static func taps(_ checks: CloseChecks) -> [(skillID: UUID, tap: Bool?)] {
        switch checks {
        case let .rows(rows): rows.map { ($0.skillID, $0.tap) }
        case let .placement(subjects): subjects.flatMap(\.rows).map { ($0.skillID, $0.tap) }
        default: []
        }
    }

    private func readSessions() async {
        let from = calendar.date(byAdding: .day, value: -TrackingRules.absenceWindowDays, to: now()) ?? now()
        let months = Set([
            Period.containing(from, in: calendar.timeZone), Period.containing(now(), in: calendar.timeZone),
        ])
        var read: [AttendanceSession] = []
        for month in months {
            read += await (try? attendance.sessions(centre: workspace.centre.id, month: month)) ?? []
        }
        sessions = read
    }

    private func readRecords(_ ids: [UUID]) async {
        let since = calendar.date(byAdding: .day, value: -TrackingRules.absenceWindowDays, to: now()) ?? now()
        let centre = workspace.centre.id
        history = await (try? record.checks(centre: centre, students: ids, since: since)) ?? []
        homeworkHistory = await (try? record.homework(centre: centre, students: ids, since: since)) ?? []
        for id in ids {
            chapters[id] = await (try? textbooks.chapters(student: id)) ?? []
            skills[id] = await (try? textbooks.skills(student: id)) ?? []
        }
    }

    /// Opened again: the checks kept today, tapped as they were answered.
    private func keptChecks(_ kept: [CheckRecord], student: UUID) -> CloseChecks? {
        guard !kept.isEmpty else { return nil }
        let names = Dictionary((skills[student] ?? []).map { ($0.id, $0.name) }) { first, _ in first }
        return .rows(kept.map { check in
            CheckLine(
                skillID: check.skillID, skill: names[check.skillID] ?? "", question: check.question, answer: "",
                tap: check.correct, recorded: check.correct, isPlacement: check.isPlacement
            )
        })
    }

    /// "Catch up · missed Mon and Fri" when the student was absent at both of the batch's last two sessions.
    private func catchUp(_ student: UUID) -> String? {
        let last = sessions.filter { $0.classID == classID && $0.date < day }.sorted { $0.date > $1.date }.prefix(2)
        guard last.count == 2, last.allSatisfy({ $0.marks[student] == .absent }) else { return nil }
        let days = last.reversed().map { $0.date.weekday(in: calendar).short }
        return "Catch up · missed \(days[0]) and \(days[1])"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
