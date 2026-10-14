import Domain
import Foundation

/// The AI routes in memory for tests, previews and `bun shots`: the boards' answers, a scripted failure, a delay, a
/// record of every call.
@MainActor public final class FakeAIRepository: AIRepository {
    public enum Script: Sendable {
        case answer
        case failure(APIFailure)
    }

    public var script: Script = .answer
    public var delay: Duration?
    /// The rows a scan answers; the board's eight unless a test sets others.
    public var scanRows = AISamples.scanRows
    public private(set) var requests: [GenerateRequest] = []
    public private(set) var scans = 0
    public private(set) var checks: [SchemeSource] = []
    /// V2: the subjects of each contents page read, the skills of each check call, the chapters of each placement.
    public private(set) var textbooks: [String] = []
    public private(set) var checkCalls: [[String]] = []
    public private(set) var placementCalls: [[String]] = []
    /// One subject's answer scripted apart (a close or placement where one subject fails).
    public var scriptBySubject: [String: Script] = [:]
    /// The plan's calls (Phase 12), each scripted apart.
    public enum Call: Hashable, Sendable {
        case sheet, workedExample, figure, brief
        case note, canDo, notOnTrack, readMarks
    }

    public var scriptByKind: [Call: Script] = [:]
    /// A delay for one kind of the plan's calls only (a sheet still on its way while the rest have landed).
    public var delayByKind: [Call: Duration] = [:]
    public private(set) var sheets: [[String]] = []
    /// Every sheet asked for, whole (Make's form sends the level, the subject and the skills only).
    public private(set) var sheetRequests: [SheetRequest] = []
    public private(set) var reasons: [String?] = []
    public private(set) var examples: [String] = []
    public private(set) var figures: [FigureSpec.Kind] = []
    public private(set) var briefs: [String] = []
    /// The calls made as "another one" (`IdempotencyKey.another`): Make it again and Write again.
    public private(set) var anotherCalls = 0
    /// The school's calls (Phase 13).
    public private(set) var parseCalls: [SchoolSource] = []
    public private(set) var mockCalls: [MockRequest] = []
    /// Each brief's reason (Make it again, D107), nil for a first.
    public private(set) var briefReasons: [String?] = []
    public private(set) var gapCalls: [GapRequest] = []
    public private(set) var messageCalls: [TestTomorrowRequest] = []
    /// The parents' calls (Phase 14).
    public private(set) var noteCalls: [NoteRequest] = []
    public private(set) var canDoCalls: [CanDoRequest] = []
    public private(set) var notOnTrackCalls: [NotOnTrackRequest] = []
    public private(set) var readMarksCalls: [ReadMarksRequest] = []
    /// The rows marks from a photo answer; the board's three unless a test sets others.
    public var readMarksRows = AISamples.readMarks
    /// The students named by each marking (nil for V1's).
    public private(set) var checkStudents: [UUID?] = []
    /// The items a reading answers, the samples unless a test sets others.
    public var schoolItems: [ParsedItem]?
    /// A figure answered in place of the template's sample (a spec the app refuses).
    public var figureOverride: FigureContent?
    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    public func generate(
        _ request: GenerateRequest,
        context _: GenerateContext
    ) async throws(APIFailure) -> Generation {
        requests.append(request)
        try await answer()
        let result: GenerationResult = switch request.kind {
        case .paper: .paper(AISamples.paper)
        case .homework: .homework(AISamples.homework)
        case .worksheet: .worksheet(AISamples.worksheet)
        case .progressNote: .progressNote(AISamples.note)
        }
        return Generation(id: UUID(), kind: request.kind, createdAt: now(), request: request, result: result)
    }

    public func scanRegister(_: ImageUpload, centre _: UUID) async throws(APIFailure) -> ScanAnswer {
        scans += 1
        try await answer()
        return ScanAnswer(id: UUID(), rows: scanRows)
    }

    public func checkPaper(
        pages _: [ImageUpload], scheme: SchemeSource, studentName _: String, studentID: UUID?, centre _: UUID
    ) async throws(APIFailure) -> CheckAnswer {
        checks.append(scheme)
        checkStudents.append(studentID)
        try await answer()
        return CheckAnswer(id: UUID(), result: AISamples.check)
    }

    public func parseTextbook(
        _: ImageUpload, classLevel _: ClassLevel, subject: String, centre _: UUID
    ) async throws(APIFailure) -> TextbookReading {
        textbooks.append(subject)
        try await answer(subject: subject)
        return AISamples.textbook
    }

    public func makeChecks(
        classLevel _: ClassLevel, subject: String, skills: [String], centre _: UUID
    ) async throws(APIFailure) -> [CheckQuestion] {
        checkCalls.append(skills)
        try await answer(subject: subject)
        return AISamples.checks(for: skills)
    }

    public func makePlacement(
        classLevel _: ClassLevel, subject: String, chapters: [String], centre _: UUID
    ) async throws(APIFailure) -> [PlacementQuestion] {
        placementCalls.append(chapters)
        try await answer(subject: subject)
        return AISamples.placement(for: chapters)
    }

    public func makeSheet(_ request: SheetRequest, centre _: UUID) async throws(APIFailure) -> MadeSheet {
        sheets.append(request.skills)
        sheetRequests.append(request)
        reasons.append(request.reason)
        try await answer(.sheet)
        let light = request.forHomework && request.classLevel.homeworkIsLight
        let content = AISamples.sheet(questions: request.questions, forHomework: request.forHomework, light: light)
        return MadeSheet(generationID: UUID(), content: content)
    }

    public func makeWorkedExample(
        classLevel _: ClassLevel, subject _: String, skill: String, centre _: UUID
    ) async throws(APIFailure) -> MadeWorkedExample {
        examples.append(skill)
        try await answer(.workedExample)
        return MadeWorkedExample(generationID: UUID(), example: AISamples.workedExample)
    }

    public func makeFigure(
        _ kind: FigureSpec.Kind, classLevel _: ClassLevel, subject _: String, skill _: String, centre _: UUID
    ) async throws(APIFailure) -> MadeFigure {
        figures.append(kind)
        try await answer(.figure)
        return MadeFigure(generationID: UUID(), figure: figureOverride ?? AISamples.figure(kind))
    }

    public func makeBrief(
        classLevel _: ClassLevel, subject _: String, chapter: String, reason: String?, centre _: UUID
    ) async throws(APIFailure) -> MadeBrief {
        briefs.append(chapter)
        briefReasons.append(reason)
        try await answer(.brief)
        return MadeBrief(generationID: UUID(), brief: AISamples.brief)
    }

    public func parseSchool(
        _ source: SchoolSource, today _: Day, schools _: [String], classLevels _: [ClassLevel], centre _: UUID
    ) async throws(APIFailure) -> SchoolReading {
        parseCalls.append(source)
        try await answer()
        if let schoolItems {
            return SchoolReading(id: UUID(), items: schoolItems)
        }
        if case .image = source {
            return SchoolReading(id: UUID(), items: AISamples.photoItems)
        }
        return SchoolReading(id: UUID(), items: AISamples.schoolItems)
    }

    public func makeMock(_ request: MockRequest, centre _: UUID) async throws(APIFailure) -> MadeMock {
        mockCalls.append(request)
        try await answer()
        return MadeMock(generationID: UUID(), content: AISamples.mock(request))
    }

    public func makeGapReport(_ request: GapRequest, centre _: UUID) async throws(APIFailure) -> MadeGapReport {
        gapCalls.append(request)
        try await answer()
        return MadeGapReport(generationID: UUID(), summary: AISamples.gapSummary, days: AISamples.gapDays)
    }

    public func makeTestTomorrow(
        _ request: TestTomorrowRequest,
        centre _: UUID
    ) async throws(APIFailure) -> MadeMessage {
        messageCalls.append(request)
        try await answer()
        return MadeMessage(
            generationID: UUID(), message: AISamples.testTomorrowHindi, english: AISamples.testTomorrowEnglish
        )
    }

    public func makeNote(_ request: NoteRequest, centre _: UUID) async throws(APIFailure) -> MadeMessage {
        noteCalls.append(request)
        try await answer(.note)
        return MadeMessage(generationID: UUID(), message: AISamples.noteHindi, english: AISamples.noteEnglish)
    }

    public func makeCanDo(_ request: CanDoRequest, centre _: UUID) async throws(APIFailure) -> MadeMessage {
        canDoCalls.append(request)
        try await answer(.canDo)
        return MadeMessage(generationID: UUID(), message: AISamples.canDoKannada, english: AISamples.canDoEnglish)
    }

    public func makeNotOnTrack(_ request: NotOnTrackRequest, centre _: UUID) async throws(APIFailure) -> MadeMessage {
        notOnTrackCalls.append(request)
        try await answer(.notOnTrack)
        return MadeMessage(
            generationID: UUID(), message: AISamples.notOnTrackHindi, english: AISamples.notOnTrackEnglish
        )
    }

    public func readMarks(_ request: ReadMarksRequest, centre _: UUID) async throws(APIFailure) -> ReadMarksAnswer {
        readMarksCalls.append(request)
        try await answer(.readMarks)
        return ReadMarksAnswer(generationID: UUID(), marks: readMarksRows)
    }

    private func answer(_ call: Call) async throws(APIFailure) {
        if let wait = delayByKind[call] {
            do {
                try await Task.sleep(for: wait)
            } catch {
                throw .offline
            }
        }
        if case let .failure(failure)? = scriptByKind[call] {
            throw failure
        }
        try await answer()
    }

    private func answer(subject: String) async throws(APIFailure) {
        if case let .failure(failure)? = scriptBySubject[subject] {
            throw failure
        }
        try await answer()
    }

    private func answer() async throws(APIFailure) {
        if IdempotencyKey.isAnother {
            anotherCalls += 1
        }
        if let delay {
            do {
                try await Task.sleep(for: delay)
            } catch {
                throw .offline
            }
        }
        if case let .failure(failure) = script {
            throw failure
        }
    }
}
