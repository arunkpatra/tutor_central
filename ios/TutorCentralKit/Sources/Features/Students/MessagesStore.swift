import Data
import Domain
import Foundation
import Observation

/// The sent log (P10-Student-Messages; plan/phase-14-plan.md decisions 6 and 7): every message sent about the student
/// by month, newest first, with the kind, the day, the language and "opened <day>", "copied <day>" or "not opened yet";
/// the note held this note day in a Held section with Send now.
@MainActor @Observable public final class MessagesStore {
    public struct Row: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let symbol: String
        public let title: String
        public let line: String
        /// A weekly note's note day: the row opens the note.
        public let opens: Day?
    }

    public struct Month: Identifiable, Hashable, Sendable {
        public var id: String {
            title
        }

        public let title: String
        public let rows: [Row]
    }

    public struct Held: Hashable, Sendable {
        public let title: String
        /// "Held since Sun 11 Oct · Ramesh had three messages that week".
        public let line: String
        public let noteDay: Day
    }

    public private(set) var months: [Month] = []
    public private(set) var held: Held?
    public private(set) var loadFailed = false
    let studentID: UUID
    let centre: UUID
    let register: any Register
    let messages: any MessageLogRepository
    let plans: any PlansRepository
    let now: () -> Date
    let calendar: Calendar

    public init(
        student: UUID, centre: UUID, register: any Register, messages: any MessageLogRepository,
        plans: any PlansRepository, now: @escaping () -> Date, calendar: Calendar
    ) {
        studentID = student
        self.centre = centre
        self.register = register
        self.messages = messages
        self.plans = plans
        self.now = now
        self.calendar = calendar
    }

    var student: Student? {
        register.student(studentID)
    }

    /// "Messages · Dev".
    public var title: String {
        "Messages · \(student?.firstName ?? "")"
    }

    public var line: String {
        let parent = student?.parentName ?? "the parent"
        return "What went to \(parent) from here, newest first. Opened means WhatsApp was opened with it; what they "
            + "read is theirs."
    }

    public func load() async {
        await register.loadIfNeeded()
        guard let student else { return }
        let centreID = centre
        let moment = now()
        do {
            async let entriesRead = messages.messages(centre: centreID, student: studentID)
            async let notesRead = try? plans.notes(
                centre: centreID, students: [studentID], since: moment.addingTimeInterval(-120 * 86400)
            )
            async let parentRead = try? messages.entries(
                centre: centreID, since: moment.addingTimeInterval(-14 * 86400)
            )
            let entries = try await entriesRead
            let notes = await notesRead ?? []
            let parent = await (parentRead ?? []).filter { register.sameParent($0.studentID, student) }.map(\.entry)
            held = heldNote(student, entries: entries, parent: parent)
            months = Self.months(rows(entries: entries, notes: notes), calendar: calendar)
            loadFailed = false
        } catch {
            months = []
            loadFailed = true
        }
    }

    /// The held note's student and note day, for the note's route.
    public func sendNow() -> (UUID, Day)? {
        held.map { (studentID, $0.noteDay) }
    }
}
