import Data
import Domain
import Foundation
import Observation

/// One student's note on the note day (P10-Today-NoteDay): the language, the week's topic and its lead fact, and Read,
/// Sent or Held with the reason.
public struct NoteRowModel: Identifiable, Hashable, Sendable {
    public enum State: Hashable, Sendable {
        case read, sent, held(HeldReason)
    }

    /// The student.
    public let id: UUID
    public let name: String
    public let initials: String
    /// "Hindi · Chemical reactions · 2 absences"; "Kannada · Can now read short sentences"; "Hindi · waits for Neha's
    /// consent".
    public let line: String
    public let state: State
    /// The note day the note belongs to.
    public let noteDay: Day
}

/// The held sheet's model (P10-Held): the parent, their suggested messages this week, the footnote.
public struct HeldNote: Hashable, Sendable, Identifiable {
    public struct Sent: Hashable, Sendable {
        public let kind: String
        public let day: String
        public let symbol: String
    }

    public var id: UUID {
        studentID
    }

    public let studentID: UUID
    public let initials: String
    public let studentFirstName: String
    /// "Ramesh Kumar · Dev's parent".
    public let parentLine: String
    public let thisWeek: [Sent]
    public let footnote: String
    public let noteDay: Day
}

/// The note day on Today (plan/phase-14-plan.md decisions 4 to 6): from a batch's note time to the end of the next day,
/// one row per student of those batches with a parent's number; Sent once the note was opened in WhatsApp this week,
/// else the cadence's decision. The facts are worked out here only for the row's line; the note screen makes the note.
@MainActor @Observable public final class NoteDayStore {
    public static let heroNote = "Each one is about the week: what was taught, what went right, what to practise. "
        + "Read it as the parent will, then send."

    public private(set) var isOn = false
    public private(set) var rows: [NoteRowModel] = []
    public private(set) var loadFailed = false
    /// What was sent this week is known (the read answered): until then the rows are the register's, with no count.
    private var counted = false
    /// A refused change in words (the alert).
    public var message: String?
    /// Read and Send it now: AppShell opens the note (Artefacts) for the student and the note day.
    @ObservationIgnored public var onOpenNote: ((UUID, Day) -> Void)?
    /// A row held for consent: the student's page, where the consent is recorded (AppShell's).
    @ObservationIgnored public var onOpenStudent: ((UUID) -> Void)?
    /// Each listed student's parent's suggested messages this week, for the held sheet.
    private var parentWeek: [UUID: [MessageEntry]] = [:]
    /// The read in hand: an earlier read that answers late (a pull during Change day's reload) is dropped.
    @ObservationIgnored private var generation = 0

    let workspace: Workspace
    let register: any Register
    let textbooks: any TextbooksRepository
    let record: any RecordRepository
    let attendance: any AttendanceRepository
    let messages: any MessageLogRepository
    let schoolItems: (any SchoolItemsRepository)?
    let classes: any ClassesRepository
    let online: @Sendable () async -> Bool
    let now: () -> Date
    let calendar: Calendar

    public init(
        workspace: Workspace, register: any Register, textbooks: any TextbooksRepository, record: any RecordRepository,
        attendance: any AttendanceRepository, messages: any MessageLogRepository,
        schoolItems: (any SchoolItemsRepository)?, classes: any ClassesRepository,
        online: @escaping @Sendable () async -> Bool, now: @escaping () -> Date, calendar: Calendar
    ) {
        self.classes = classes
        self.online = online
        self.workspace = workspace
        self.register = register
        self.textbooks = textbooks
        self.record = record
        self.attendance = attendance
        self.messages = messages
        self.schoolItems = schoolItems
        self.now = now
        self.calendar = calendar
    }

    /// "7 notes for parents", "1 note for parents", "No notes this week".
    public var heroLine: String {
        switch rows.count {
        case 0: "No notes this week"
        case 1: "1 note for parents"
        default: "\(rows.count) notes for parents"
        }
    }

    /// "2 of 7 sent".
    public var countLine: String {
        counted ? "\(rows.filter { $0.state == .sent }.count) of \(rows.count) sent" : ""
    }

    /// The note day of the students whose note is on now, by student: a batch's own day, Sunday 18:00 for a student
    /// with no batch.
    func onDays(at moment: Date) -> [UUID: Day] {
        var days: [UUID: Day] = [:]
        for student in register.activeStudents where student.parentPhone != nil {
            let noteDay = register.classroom(student.classID)?.effectiveNoteDay ?? .default
            if noteDay.isOn(at: moment, calendar: calendar) {
                days[student.id] = noteDay.noteDay(for: moment, calendar: calendar)
            }
        }
        return days
    }

    public func load() async {
        generation += 1
        let mine = generation
        await register.loadIfNeeded()
        let moment = now()
        let days = onDays(at: moment)
        isOn = !days.isEmpty
        guard isOn else {
            rows = []
            return
        }
        // The register's rows at once: offline the read takes its timeout to fail (run 8).
        if rows.isEmpty {
            rows = rowsOrdered(registerRows(days))
        }
        do {
            let week = try await read(days: days, at: moment)
            guard mine == generation else { return }
            rows = rowsOrdered(week.rows)
            parentWeek = week.parents
            loadFailed = false
            counted = true
        } catch {
            guard mine == generation else { return }
            // Offline or a failed read: the register's rows, so a note kept on this iPhone still opens (plan decision
            // 21); what was sent this week is not known, so nothing is counted.
            rows = rowsOrdered(registerRows(days))
            parentWeek = [:]
            loadFailed = true
            counted = false
        }
    }

    /// The rows the register alone gives: the language, and the consent a note waits for.
    func registerRows(_ days: [UUID: Day]) -> [NoteRowModel] {
        days.compactMap { id, noteDay in
            guard let student = register.student(id) else { return nil }
            let language = student.messageLanguage.title
            let state: NoteRowModel.State = student.consent == nil
                ? .held(.consent(parentFirstName: student.parentName.flatMap {
                    $0.split(separator: " ").first.map(String.init)
                }))
                : .read
            let line = if case let .held(reason) = state {
                "\(language) · \(MessageCadence.heldWords(reason))"
            } else {
                language
            }
            return NoteRowModel(
                id: id, name: student.name, initials: student.initials, line: line, state: state, noteDay: noteDay
            )
        }
    }

    /// The note day shown: the shown batches' own when they share one, else Sunday 18:00.
    public var chosen: NoteDay {
        let days = Set(shownBatches().map(\.effectiveNoteDay))
        return days.count == 1 ? days.first ?? .default : .default
    }

    /// The batches whose students are listed now.
    func shownBatches() -> [Classroom] {
        let ids = Set(rows.compactMap { register.student($0.id)?.classID })
        return register.activeClasses.filter { ids.contains($0.id) }
    }

    /// Change day (P10-NoteDay-Change): the day set on each batch shown whose note day is the one the wheel shows (a
    /// batch with another day, still on from yesterday, keeps its own), then the card read again; refused offline.
    public func changeDay(to noteDay: NoteDay) async -> Bool {
        guard await online() else {
            message = OfflineRefusal.words(for: .noteDay)
            return false
        }
        do {
            let current = chosen
            for batch in shownBatches() where batch.effectiveNoteDay == current {
                let written = try await classes.setNoteDay(
                    id: batch.id, noteDay == .default ? nil : noteDay, centre: workspace.centre.id
                )
                register.applyClassroom(written)
            }
        } catch {
            message = "That didn't go through. Check your connection and try again."
            // A failure part way: the card shows what was written.
            await load()
            return false
        }
        await load()
        return true
    }

    /// Read on a row, and the held sheet's Send it now (the send counts as one more, by the tutor's hand).
    /// Read: the note; a row held for consent opens the student's page instead (no note is made without it).
    public func open(_ row: NoteRowModel) {
        if case .held(.consent) = row.state {
            onOpenStudent?(row.id)
            return
        }
        onOpenNote?(row.id, row.noteDay)
    }

    public func sendNow(_ held: HeldNote) {
        onOpenNote?(held.studentID, held.noteDay)
    }

    /// The held sheet for a held row, nil for any other.
    public func held(for student: UUID) -> HeldNote? {
        guard let row = rows.first(where: { $0.id == student }), case .held(.threeThisWeek) = row.state,
              let person = register.student(student) else { return nil }
        let entries = (parentWeek[student] ?? []).sorted { $0.openedAt < $1.openedAt }
        let next = row.noteDay.adding(days: 7, calendar: calendar)
        return HeldNote(
            studentID: student, initials: person.initials, studentFirstName: person.firstName,
            parentLine: [person.parentName, "\(person.firstName)'s parent"].compactMap(\.self).joined(separator: " · "),
            thisWeek: entries.map {
                HeldNote.Sent(
                    kind: $0.kind.title, day: Day($0.openedAt, calendar: calendar).shortWeekdayText,
                    symbol: Self.symbol($0.kind)
                )
            },
            footnote: MessageCadence.heldFootnote(nextNoteDay: next), noteDay: row.noteDay
        )
    }

    static func symbol(_ kind: MessageKind) -> String {
        switch kind {
        case .testTomorrow: "doc.text"
        case .notOnTrack: "exclamationmark.circle"
        case .canDo: "star"
        default: "note.text"
        }
    }

    /// Sent first, then the ones to read, then the held; by name within each.
    private func rowsOrdered(_ rows: [NoteRowModel]) -> [NoteRowModel] {
        func rank(_ state: NoteRowModel.State) -> Int {
            switch state {
            case .sent: 0
            case .read: 1
            case .held: 2
            }
        }
        return rows.sorted { (rank($0.state), $0.name) < (rank($1.state), $1.name) }
    }
}
