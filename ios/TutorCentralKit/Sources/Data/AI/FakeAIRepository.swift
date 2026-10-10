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
        pages _: [ImageUpload], scheme: SchemeSource, studentName _: String, centre _: UUID
    ) async throws(APIFailure) -> CheckAnswer {
        checks.append(scheme)
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

    private func answer(subject: String) async throws(APIFailure) {
        if case let .failure(failure)? = scriptBySubject[subject] {
            throw failure
        }
        try await answer()
    }

    private func answer() async throws(APIFailure) {
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
