import Data
import Domain
import Foundation
import Observation

/// What the note screen needs (AppShell's): the centre, the register, the record's reader, the log, the plans (the
/// kept notes), the AI, the copy on this iPhone.
public struct NoteContext {
    let workspace: Workspace
    let register: any Register
    let reader: NoteRecordReader
    let messages: any MessageLogRepository
    let plans: any PlansRepository
    let ai: any AIRepository
    let notesCache: NotesCache?
    let online: () async -> Bool
    let now: () -> Date
    let calendar: Calendar

    public init(
        workspace: Workspace, register: any Register, reader: NoteRecordReader, messages: any MessageLogRepository,
        plans: any PlansRepository, ai: any AIRepository, notesCache: NotesCache?, online: @escaping () async -> Bool,
        now: @escaping () -> Date, calendar: Calendar
    ) {
        self.workspace = workspace
        self.register = register
        self.reader = reader
        self.messages = messages
        self.plans = plans
        self.ai = ai
        self.notesCache = notesCache
        self.online = online
        self.now = now
        self.calendar = calendar
    }
}

/// The weekly note or can-now-do of one student for one note day (P10-Note, P10-CanNowDo; plan/phase-14-plan.md
/// decisions 1 to 3, 18, 21): the kept note of the week, else made from the week's facts and kept; edited, written
/// again, copied, sent on WhatsApp with the signature and logged.
@MainActor @Observable public final class NoteStore {
    public enum Stage: Hashable, Sendable {
        case loading, writing, ready, failed(String)
    }

    /// The pasteboard and the link (the view's; tests record them).
    public struct Effects {
        let copy: (String) -> Void
        let open: (URL) -> Void

        public init(copy: @escaping (String) -> Void, open: @escaping (URL) -> Void) {
            self.copy = copy
            self.open = open
        }
    }

    /// "Moved up" (P10-CanNowDo): the area, its five steps, the step shown and its line.
    public struct LadderModel: Hashable, Sendable {
        public let area: String
        public let steps: [String]
        public let current: Int
        public let line: String
    }

    /// The two-language sheet's words (P10-Note-Send).
    public struct SendSheet: Hashable, Sendable {
        public let title: String
        public let heading: String
        public let parentLine: String
        public let note: String
    }

    public static let limit = 600
    public static let helper = "Edit anything before it goes. Tap Write again for a fresh draft."

    public internal(set) var stage: Stage = .loading
    public internal(set) var isLadder = false
    public var message = ""
    public internal(set) var english: String?
    public internal(set) var facts: [NoteContent.FactRow] = []
    public internal(set) var ladder: LadderModel?
    public internal(set) var sent = false
    /// A refused send in words (the alert).
    public var alert: String?
    /// The failure was the call's (the AI service, the connection): the alert offers Try Again.
    public internal(set) var canRetry = false
    var kept: Artefact?
    var content: NoteContent?
    let studentID: UUID
    let noteDay: Day
    let context: NoteContext
    let effects: Effects

    public init(student: UUID, noteDay: Day, context: NoteContext, effects: Effects) {
        studentID = student
        self.noteDay = noteDay
        self.context = context
        self.effects = effects
    }

    var student: Student? {
        context.register.student(studentID)
    }

    var week: ClosedRange<Day> {
        NoteDay.week(ending: noteDay, calendar: context.calendar)
    }

    var language: MessageLanguage {
        student?.messageLanguage ?? .english
    }

    public var heroName: String {
        student?.name ?? ""
    }

    /// "Ramesh Kumar · Hindi · the week of 5 October".
    public var heroLine: String {
        [student?.parentName, language.title, "the week of \(week.lowerBound.longText)"].compactMap(\.self)
            .joined(separator: " · ")
    }

    /// "The note · Hindi".
    public var wellTitle: String {
        "The note · \(language.title)"
    }

    public var counter: (text: String, over: Bool) {
        let count = message.storedCount
        return ("\(count) of \(Self.limit)", count > Self.limit)
    }

    public var canSend: Bool {
        stage == .ready && !counter.over && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var aiLine: String {
        let first = student?.firstName ?? ""
        return "AI can make mistakes. Read the note as the parent will; the facts are from \(first)'s "
            + (isLadder ? "ladder." : "record.")
    }

    /// The title on the back row.
    public var title: String {
        isLadder ? "Can now do" : "Weekly note"
    }

    /// The words under the creating card while the note is written.
    public var writingTitle: String {
        "Writing \(student?.firstName ?? "the")'s note"
    }

    /// The tutor's signature, outside the 600 (decision 12).
    var signature: String {
        MessageSignature.text(
            tutorName: context.workspace.profile.displayName, centreName: context.workspace.centre.name
        )
    }

    public var languageTitle: String {
        language.title
    }

    public var signedBody: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines) + signature
    }

    public var sendSheet: SendSheet {
        let first = student?.firstName ?? ""
        let parent = student?.parentName.flatMap { $0.split(separator: " ").first.map(String.init) }
        return SendSheet(
            title: "Send the note",
            heading: parent.map { "\(first)'s week, for \($0)" } ?? "\(first)'s week",
            parentLine: [student?.parentName, student?.parentPhone?.display, language.title].compactMap(\.self)
                .joined(separator: " · "),
            note: "Opens WhatsApp with the note ready to send. We note the day and the language on \(first)'s page. "
                + "The text is copied too, in case WhatsApp can't open."
        )
    }

    /// The signature's lines as the send sheet shows them under the message.
    public var signatureLines: String {
        signature.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
