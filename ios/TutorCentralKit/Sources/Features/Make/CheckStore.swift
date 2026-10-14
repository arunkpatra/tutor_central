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

    public static let maxPages = APIContract.pagesMax

    public internal(set) var stage: Stage = .intro
    public var studentID: UUID? {
        didSet {
            // A mock is the student's exam: another student's is cleared; a paper stays.
            if studentID != oldValue, preset == nil, case .mock = scheme {
                scheme = .typed(typedScheme)
                chosenMark = nil
                schemeChosenOnIntro = false
            }
        }
    }

    public internal(set) var pages: [ImageUpload] = []
    public var scheme: SchemeSource = .typed("")
    /// The last typed scheme, kept while the tutor looks at the papers.
    public var typedScheme = ""
    public internal(set) var papers: [Generation] = []
    /// The student's mocks (their exams' and Make's for them), newest first (Phase 15).
    public internal(set) var mocks: [Artefact] = []
    /// A scheme chosen on the intro's tile: the pages go straight to the marks.
    public internal(set) var schemeChosenOnIntro = false
    /// The mark a chosen mock writes (its exam and title).
    @ObservationIgnored var chosenMark: MarkTarget?
    /// The exams read with the mocks, for a mock's title and subject.
    @ObservationIgnored var exams: [SchoolItem] = []
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
    /// Where a saved check writes its mark (Phase 13); none before the record exists.
    let record: (any RecordRepository)?
    /// The mocks a scheme can be (Phase 15): the plans' artefacts and the school's exams.
    let plans: (any PlansRepository)?
    /// The chooser's mocks could not be read: said in their place, with Try Again (U33).
    public internal(set) var schemesFailed: String?
    let schoolItems: (any SchoolItemsRepository)?
    /// A mock's Mark from a photo: the student and the key set, the scheme step skipped.
    public let preset: CheckPreset?
    /// Whether the network is there (AppShell's connectivity); a test sets it.
    @ObservationIgnored public var online: () async -> Bool = { true }
    /// The server's jobs (D106): a mock's marks saved wake its exam's job, which writes the gap report.
    @ObservationIgnored public var jobs: (any JobsRepository)?
    /// The mark Save wrote, for Undo.
    @ObservationIgnored var savedMarkID: UUID?
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
        calendar: Calendar = DayHeading.india, record: (any RecordRepository)? = nil, preset: CheckPreset? = nil,
        plans: (any PlansRepository)? = nil, schoolItems: (any SchoolItemsRepository)? = nil
    ) {
        self.record = record
        self.plans = plans
        self.schoolItems = schoolItems
        self.preset = preset
        if let preset {
            studentID = preset.studentID
            scheme = preset.scheme
        }
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
        case let .mock(_, artefact):
            presetInUse?.mark.test ?? mocks.first { $0.id == artefact }.map(mockTitle) ?? "The mock"
        }
    }

    /// The preset while its scheme is the one in use: a scheme chosen in its place marks no exam.
    var presetInUse: CheckPreset? {
        preset.flatMap { $0.scheme == scheme ? $0 : nil }
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
        guard canCheck, await mayCheck() else { return }
        stage = .checking
        await run()
    }

    /// A preset's pages go straight to checking (the key is the mock's), and so do a scheme chosen on the intro's.
    public var skipsScheme: Bool {
        preset != nil || schemeChosenOnIntro
    }

    /// A mock's marks saved: Back goes back to where Mark from a photo started, not to the pages (hand run 9).
    public var leavesVisitOnBack: Bool {
        skipsScheme && saved
    }

    /// Before any call: offline it is refused with the pages kept; marking a student's paper needs their parent's
    /// consent,
    /// whatever the scheme (D62, spec section 8).
    func mayCheck() async -> Bool {
        guard await online() else {
            message = OfflineRefusal.words(for: .mark)
            return false
        }
        if let student, student.consent == nil {
            stage = .failed(Self.waitsForConsent(student))
            return false
        }
        return true
    }

    /// "Marking Dev's paper waits for Ramesh's consent. Record it on Dev's page."
    static func waitsForConsent(_ student: Student) -> String {
        let parent = student.parentName?.split(separator: " ").first.map { "\($0)'s" } ?? "their parent's"
        let name = student.firstName
        return "Marking \(name)'s paper waits for \(parent) consent. Record it on \(name)'s page."
    }

    var canCheck: Bool {
        student != nil && !pages.isEmpty && scheme.isValid && stage != .checking
    }

    func run() async {
        guard let student else { return }
        saved = false
        let title = schemeTitle
        do {
            // The marking names the student: the API asks their parent's consent (D62, migration 0021).
            let answer = try await ai.checkPaper(
                pages: pages, scheme: scheme, studentName: student.name, studentID: student.id,
                centre: workspace.centre.id
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
        task = Task { [weak self] in
            guard let self, await mayCheck() else { return }
            stage = .checking
            await run()
        }
    }

    /// The pages step's Check with a preset (the scheme is the mock's key): checking starts in a task the store owns;
    /// true when the result screen should open (checking, or refused for want of consent in its words), false when it
    /// was refused offline (the pages stay).
    func checkFromPages() async -> Bool {
        guard canCheck else { return false }
        guard await mayCheck() else {
            if case .failed = stage {
                return true
            }
            return false
        }
        stage = .checking
        task = Task { [weak self] in
            await self?.run()
        }
        return true
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

extension CheckStore {
    /// "Question paper · Class 8 · 20 marks · Sun 11 Oct, 16:40" (a paper made from a batch before names the batch); a
    /// set names its questions; the time tells two papers of one day apart (U22).
    func paperLine(_ paper: Generation) -> String {
        Self.paperLine(paper, calendar: calendar) { self.register.classroom($0)?.name }
    }

    nonisolated static func paperLine(
        _ paper: Generation, calendar: Calendar, batchName: (UUID?) -> String?
    ) -> String {
        let size = switch paper.result {
        case let .paper(result): result.totalMarks == 1 ? "1 mark" : "\(result.totalMarks) marks"
        case let .homework(set), let .worksheet(set):
            set.questions.count == 1 ? "1 question" : "\(set.questions.count) questions"
        case .progressNote: ""
        }
        let day = Day(paper.createdAt, calendar: calendar).shortWeekdayText
        let when = "\(day), \(QueuedChange.clock(paper.createdAt, calendar: calendar))"
        return [paper.kind.title, paper.className(batchName: batchName), size, when].joined(separator: " · ")
    }
}
