import Data
import Domain
import Foundation
import Observation

/// Check a paper (P6-Check-*): a student, up to six pages reduced on the iPhone, the marking scheme (a paper created
/// here, or typed), then the suggested marks the tutor edits. Nothing is written before Save, which appends one line
/// to the student's notes; its Undo puts the notes back exactly. The pages are kept only for Retry, never stored.
@MainActor @Observable public final class CheckStore {
    public enum Stage: Hashable, Sendable {
        case intro, pages, scheme, checking, result
        case failed(String)
    }

    public static let maxPages = 6

    public internal(set) var stage: Stage = .intro
    public var studentID: UUID?
    public internal(set) var pages: [ImageUpload] = []
    public var scheme: SchemeSource = .typed("")
    /// The last typed scheme, kept while the tutor looks at the papers.
    public var typedScheme = ""
    public internal(set) var papers: [Generation] = []
    public internal(set) var result: CheckResult?
    public internal(set) var saved = false
    public internal(set) var saving = false
    public internal(set) var previousNotes: String?
    /// After Save: "Saved to Hemanth's notes: 15 of 20 on Quadratic equations." with Undo.
    public internal(set) var toast: String?
    public var message: String?
    /// The server refused for want of consent (the session thought it given): the consent sheet, then Retry.
    public var askingConsent = false
    public internal(set) var workspace: Workspace
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    /// AppShell refreshes the register after Save or Undo (the detail's notes).
    public var onStudentChanged: (() -> Void)?

    let register: any Register
    let ai: any AIRepository
    let students: any StudentsRepository
    private let history: any AIHistoryRepository
    private let centres: any CentreRepository
    let now: @Sendable () -> Date
    let calendar: Calendar
    /// The notes as this screen last wrote them, ahead of the register's refresh.
    @ObservationIgnored var notesNow: [UUID: String?] = [:]
    /// The scheme's title at the time of the check.
    @ObservationIgnored var checkedTitle: String?
    /// The check in flight, so Cancel can abandon it.
    @ObservationIgnored var task: Task<Void, Never>?

    public init(
        workspace: Workspace, register: any Register, ai: any AIRepository, history: any AIHistoryRepository,
        students: any StudentsRepository, centres: any CentreRepository, now: @escaping @Sendable () -> Date,
        calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.ai = ai
        self.history = history
        self.students = students
        self.centres = centres
        self.now = now
        self.calendar = calendar
    }

    public var needsConsent: Bool {
        workspace.centre.aiConsentAt == nil
    }

    public var student: Student? {
        studentID.flatMap(register.student)
    }

    public var canContinue: Bool {
        student != nil && !pages.isEmpty
    }

    /// The scheme's paper title, or "Typed scheme".
    public var title: String {
        if let checkedTitle, stage == .result || saved {
            return checkedTitle
        }
        return schemeTitle
    }

    var schemeTitle: String {
        switch scheme {
        case let .paper(id): papers.first { $0.id == id }?.result.title ?? "Marking scheme"
        case .typed: "Typed scheme"
        }
    }

    /// The marks of the chosen paper ("Against Quadratic equations · 20 marks").
    public var schemeMarks: Int? {
        guard case let .paper(id) = scheme, case let .paper(paper)? = papers.first(where: { $0.id == id })?.result
        else { return nil }
        return paper.totalMarks
    }

    public func prepare() async {
        await register.loadIfNeeded()
    }

    /// The centre's papers, homework and worksheets from History: the schemes a check can use.
    public func loadPapers() async {
        await prepare()
        guard let all = try? await history.generations(centre: workspace.centre.id) else { return }
        papers = all.filter { $0.kind != .progressNote }
        if case let .typed(text) = scheme, text.isEmpty, let first = papers.first {
            scheme = .paper(generationID: first.id)
        }
    }

    /// Up to six together; the rest are left out with a word.
    public func addPages(_ uploads: [ImageUpload]) {
        let room = Self.maxPages - pages.count
        pages.append(contentsOf: uploads.prefix(max(0, room)))
        if uploads.count > room {
            message = "Up to six pages. The extra ones were left out."
        }
        if stage == .intro {
            stage = .pages
        }
    }

    public func removePage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        pages.remove(at: index)
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
        askingConsent = false
        onWorkspaceChanged?(workspace)
        return true
    }

    /// Checking: the pages and the scheme to the API, the marks clamped on arrival. One at a time: a check while one
    /// runs is refused; an answer that arrives after Cancel is dropped.
    public func check() async {
        guard canCheck else { return }
        stage = .checking
        await run()
    }

    var canCheck: Bool {
        student != nil && !pages.isEmpty && scheme.isValid && stage != .checking
    }

    func run() async {
        guard let student else { return }
        saved = false
        let title = schemeTitle
        do {
            let answer = try await ai.checkPaper(
                pages: pages, scheme: scheme, studentName: student.name, centre: workspace.centre.id
            )
            guard !Task.isCancelled, stage == .checking else { return }
            result = answer.result
            checkedTitle = title
            stage = .result
        } catch {
            guard !Task.isCancelled, stage == .checking else { return }
            if error == .consent {
                workspace.centre.aiConsentAt = nil
                askingConsent = true
            }
            stage = .failed(error.message)
        }
    }

    public func retry() async {
        await check()
    }
}

public extension CheckStore {
    /// Checking in a task the store owns; refused while one runs.
    func begin() {
        guard canCheck else { return }
        stage = .checking
        task = Task { [weak self] in
            await self?.run()
        }
    }

    /// Cancel or Back while checking: the check is abandoned (its row stays on the server), back at the scheme.
    func cancel() {
        task?.cancel()
        task = nil
        if stage == .checking {
            stage = .scheme
        }
    }
}
