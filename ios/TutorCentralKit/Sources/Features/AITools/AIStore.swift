import Data
import Domain
import Foundation
import Observation
import UIKit

/// The AI Assistant for one centre (`ShellState.ai`): the forms' drafts, the one call running, the results seen, and
/// History. A call belongs to the store, not the screen, so leaving the form does not lose it (P6-Generating).
@MainActor @Observable public final class AIStore {
    /// The call running: its kind and request, the result it replaces (Create again), and the creating card's title.
    public struct InFlight: Hashable, Sendable {
        public let kind: GenerationKind
        public let request: GenerateRequest
        public let regenerating: UUID?
        public let line: String
    }

    /// The last call's failure, for its form's error row.
    public struct Failure: Hashable, Sendable {
        public let kind: GenerationKind
        public let message: String
        /// The centre has not agreed: the form shows the consent sheet.
        public let consent: Bool
        /// False for the day's limit: trying again cannot help.
        public let canRetry: Bool

        public init(kind: GenerationKind, message: String, consent: Bool, canRetry: Bool = true) {
            self.kind = kind
            self.message = message
            self.consent = consent
            self.canRetry = canRetry
        }
    }

    public enum CreateOutcome: Hashable, Sendable {
        case started, busy, needsConsent, invalid
    }

    /// What Send on WhatsApp does besides logging: copy the text and open the link (the application's, in tests a
    /// record).
    public struct Effects {
        public let copy: @MainActor (String) -> Void
        public let open: @MainActor (URL) async -> Void

        public init(copy: @escaping @MainActor (String) -> Void, open: @escaping @MainActor (URL) async -> Void) {
            self.copy = copy
            self.open = open
        }

        @MainActor public static var system: Effects {
            Effects(copy: { UIPasteboard.general.string = $0 }, open: { await UIApplication.shared.open($0) })
        }
    }

    public internal(set) var workspace: Workspace
    public var forms: [GenerationKind: GenerateRequest] = [:]
    public internal(set) var history: [Generation] = []
    public private(set) var historyLoaded = false
    public private(set) var historyError: String?
    /// When History on screen was saved on this iPhone, until the network replaces it (D39).
    public private(set) var historySavedAt: Date?
    /// History's last read failed for the network, not the server.
    public private(set) var historyOfflineRead = false
    /// History's copy on this iPhone (AppShell's).
    public var historyCache: CachedRead<[Generation]>?
    public internal(set) var results: [UUID: Generation] = [:]
    public internal(set) var inFlight: InFlight?
    public internal(set) var failure: Failure?
    /// "This month: 2 of 3 classes attended · October fee due" by student, read when a note's student is chosen.
    public private(set) var monthLines: [UUID: String] = [:]
    /// A toast for the shell (a refused second Create, a failed agreement, Copied).
    public var message: String?
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    /// AppShell pushes the result when its form (or the result it replaces) is on top.
    public var onResult: ((Generation) -> Void)?
    /// The result the last arrival replaced (Create again), read by `onResult`.
    public internal(set) var lastReplaced: UUID?
    @ObservationIgnored public var effects = Effects.system

    let register: any Register
    let ai: any AIRepository
    private let historyRepository: any AIHistoryRepository
    private let centres: any CentreRepository
    let messagesRepository: any MessageLogRepository
    private let attendance: any AttendanceRepository
    let now: @Sendable () -> Date
    let calendar: Calendar
    @ObservationIgnored var task: Task<Void, Never>?
    @ObservationIgnored var lastRequest: (request: GenerateRequest, regenerating: UUID?)?

    public init(
        workspace: Workspace, register: any Register, ai: any AIRepository, history: any AIHistoryRepository,
        centres: any CentreRepository, messages: any MessageLogRepository, attendance: any AttendanceRepository,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.ai = ai
        historyRepository = history
        self.centres = centres
        messagesRepository = messages
        self.attendance = attendance
        self.now = now
        self.calendar = calendar
    }

    public var recent: [Generation] {
        Array(history.prefix(3))
    }

    public var needsConsent: Bool {
        workspace.centre.aiConsentAt == nil
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    public func workspaceChanged(_ workspace: Workspace) {
        self.workspace = workspace
    }

    /// The register the names come from: read once, by whichever AI screen shows first.
    public func prepare() async {
        await register.loadIfNeeded()
    }

    public func loadHistory() async {
        await prepare()
        if !historyLoaded, let cached = historyCache?.load() {
            history = cached.value
            historySavedAt = cached.savedAt
            historyLoaded = true
        }
        do {
            let loaded = try await historyRepository.generations(centre: workspace.centre.id)
            historyCache?.keep(loaded, at: now())
            historySavedAt = nil
            historyOfflineRead = false
            let ids = Set(loaded.map(\.id))
            history = (Array(results.values.filter { !ids.contains($0.id) }) + loaded)
                .sorted { $0.createdAt > $1.createdAt }
            historyLoaded = true
            historyError = nil
        } catch {
            historyOfflineRead = TransportError.isOffline(error)
            historyError = historyLoaded && historyOfflineRead
                ? nil : "Couldn't load History. Check your connection and try again."
        }
    }

    /// A result: this session's, else History's, else read by id (a link, a relaunch).
    public func generation(_ id: UUID) async -> Generation? {
        if let seen = results[id] ?? history.first(where: { $0.id == id }) {
            return seen
        }
        guard let read = try? await historyRepository.generation(id: id) else { return nil }
        results[id] = read
        return read
    }

    /// The draft of a kind, else a new form on the first active class with its subject.
    public func form(for kind: GenerationKind) -> GenerateRequest {
        if let draft = forms[kind] {
            return draft
        }
        let first = register.activeClasses.first
        let classID = first?.id
        let subject = first?.subject ?? ""
        switch kind {
        case .paper: return .paper(PaperForm(classID: classID, subject: subject))
        case .homework: return .homework(HomeworkForm(classID: classID, subject: subject))
        case .worksheet: return .worksheet(WorksheetForm(classID: classID, subject: subject))
        case .progressNote: return .progressNote(NoteForm())
        }
    }

    /// "I agree, continue": the centre's consent written and merged into the session's workspace.
    public func recordConsent() async -> Bool {
        let at = now()
        do {
            try await centres.recordAIConsent(id: workspace.centre.id, at: at)
        } catch {
            message = "Couldn't save your agreement. Check your connection and try again."
            return false
        }
        workspace.centre.aiConsentAt = at
        onWorkspaceChanged?(workspace)
        return true
    }

    public func studentName(_ id: UUID) -> String? {
        register.student(id)?.name
    }

    /// A class's name; for a student's id, their class's (a note's line names the student's class).
    public func className(_ id: UUID?) -> String? {
        guard let id else { return nil }
        if let classroom = register.classroom(id) {
            return classroom.name
        }
        return register.student(id).flatMap { register.classroom($0.classID)?.name }
    }

    /// The month's attendance and fee for the note's banner, also sent with the note.
    public func loadMonthLine(for studentID: UUID) async {
        guard let student = register.student(studentID) else { return }
        let period = Period.containing(now(), in: calendar.timeZone)
        let sessions = await (try? attendance.sessions(centre: workspace.centre.id, month: period)) ?? []
        let marks = sessions.compactMap { $0.marks[studentID] }
        let present = marks.filter { $0 == .present }.count
        var parts = [marks.isEmpty ? "No classes marked yet" : "\(present) of \(marks.count) classes attended"]
        if let fee = student.thisMonth {
            parts.append("\(period.monthName) fee \(fee.status.rawValue)")
        }
        monthLines[studentID] = parts.joined(separator: " · ")
    }
}
