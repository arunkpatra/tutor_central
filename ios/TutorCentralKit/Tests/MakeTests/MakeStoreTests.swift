import Data
import Domain
import Foundation
import Students
import Testing
@testable import Make

/// Make something's home (plan/phase-15-plan.md Task 7, decision 5; Review focus 5).
@MainActor struct MakeStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let centre = FakeCentreRepository.meeraWorkspaceConsented.centre.id
    static let groupOne = MakeFor(
        target: .group(plan: UUID(), number: 1), title: "Group 1", line: "Class 8 Science · Balancing equations"
    )

    static func make(
        plans: FakePlansRepository = FakePlansRepository(),
        history: FakeAIHistoryRepository = FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed)
    ) async -> MakeStore {
        let ai = await AIStoreTests.make(history: history)
        return MakeStore(
            workspace: FakeCentreRepository.meeraWorkspaceConsented, register: ai.register, plans: plans, ai: ai,
            now: { now }
        )
    }

    static func artefact(_ kind: ArtefactKind, title: String) -> NewArtefact {
        let content: ArtefactContent = switch kind {
        case .brief: .brief(Brief(
                about: "A", mistakes: [],
                workedExample: WorkedExample(problem: "P", steps: [], slip: "S"), words: []
            ))
        default: .sheet(SheetContent(title: title, instructions: nil, questions: [], forHomework: false, light: false))
        }
        return NewArtefact(
            kind: kind, source: .made, title: title, content: content, photoPath: nil, generationID: nil,
            regeneratedFrom: nil
        )
    }

    @discardableResult
    static func keep(
        _ kind: ArtefactKind, _ title: String, at minutesAgo: Double, for made: MakeFor = groupOne,
        student: UUID? = nil, in plans: FakePlansRepository
    ) async throws -> Artefact {
        plans.now = now.addingTimeInterval(-minutesAgo * 60)
        return try await plans.keepMade(
            artefact(kind, title: title).made(for: made),
            student: student,
            exam: nil,
            centre: centre
        )
    }

    @Test func recentListsMakesArtefactsAndV1ResultsTogetherNewestFirstThree() async throws {
        let plans = FakePlansRepository()
        try await Self.keep(.sheet, "Balancing equations · sheet", at: 0, in: plans)
        try await Self.keep(.brief, "Chemical reactions", at: 10, in: plans)
        try await Self.keep(.mock, "Science unit test 3 · mock", at: 30 * 24 * 60, in: plans)
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        #expect(store.recent.map(\.title) == [
            "Balancing equations · sheet",
            "Chemical reactions",
            "Quadratic equations",
        ])
        #expect(store.rows.count == FakeAIHistoryRepository.seed.count + 3)
        #expect(store.rows.last?.title == "Science unit test 3 · mock")
    }

    @Test func aRowsLineNamesTheKindTheTargetAndTheTime() async throws {
        let plans = FakePlansRepository()
        let dev = MakeFor(target: .student(FakeStudentsRepository.dev), title: "For Dev", line: "Class 8 Science")
        try await Self.keep(.sheet, "Balancing equations · sheet 1", at: 0, in: plans)
        try await Self.keep(
            .mock,
            "Science unit test 3 · mock",
            at: 1,
            for: dev,
            student: FakeStudentsRepository.dev,
            in: plans
        )
        try await Self.keep(
            .brief,
            "Chemical reactions",
            at: 2,
            for: MakeFor(target: .classLevel(.eight), title: "Class 8", line: "Science"),
            in: plans
        )
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        #expect(store.rows[0].line == "Sheet · Group 1 · today, 18:30")
        #expect(store.rows[1].line == "Mock · Dev Kumar · today, 18:29")
        #expect(store.rows[2].line == "Brief · today, 18:28")
        #expect(store.rows[0].symbol == "doc.text" && store.rows[0].opens == .artefact(store.made[0].id))
        #expect(store.rows[3].opens == .generation(FakeAIHistoryRepository.quadraticID))
    }

    @Test func makeItAgainFromRecentReplacesTheRowAndKeepsTheRecord() async throws {
        let plans = FakePlansRepository()
        let first = try await Self.keep(.sheet, "Balancing equations · sheet", at: 5, in: plans)
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        plans.now = Self.now
        let again = NewArtefact(
            kind: .sheet, source: .made, title: first.title, content: first.content, photoPath: nil,
            generationID: nil, regeneratedFrom: first.id
        )
        let second = try await plans.keepMade(
            again.made(for: Self.groupOne),
            student: nil,
            exam: nil,
            centre: Self.centre
        )
        await store.loadHistory()
        #expect(store.made.map(\.id) == [second.id])
        #expect(store.rows.filter { $0.opens == .artefact(second.id) }.count == 1)
        #expect(!store.rows.contains { $0.opens == .artefact(first.id) })
        #expect(plans.artefacts.count == 2)
    }

    @Test func aMadeArtefactLandsInRecentAtOnceInItsPredecessorsPlace() async throws {
        let plans = FakePlansRepository()
        let first = try await Self.keep(.sheet, "Balancing equations · sheet", at: 5, in: plans)
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        plans.now = Self.now
        let again = NewArtefact(
            kind: .sheet, source: .made, title: first.title, content: first.content, photoPath: nil,
            generationID: nil, regeneratedFrom: first.id
        )
        let second = try await plans.keepMade(
            again.made(for: Self.groupOne),
            student: nil,
            exam: nil,
            centre: Self.centre
        )
        store.kept(second)
        #expect(store.recent.first?.opens == .artefact(second.id))
        #expect(!store.rows.contains { $0.opens == .artefact(first.id) })
    }

    @Test func historyGroupsBothByMonth() async throws {
        let plans = FakePlansRepository()
        try await Self.keep(.sheet, "Balancing equations · sheet", at: 0, in: plans)
        try await Self.keep(.sheet, "Fractions · sheet", at: 40 * 24 * 60, in: plans)
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        let months = store.months
        #expect(months.first?.period == Period(year: 2026, month: 10))
        #expect(months.first?.rows.first?.title == "Balancing equations · sheet")
        #expect(months.last?.rows.contains { $0.title == "Fractions · sheet" } == true)
    }

    @Test func theEmptyRowShowsOnlyOnceHistoryHasLoaded() async {
        let store = await Self.make(history: FakeAIHistoryRepository(generations: []))
        #expect(!store.showsEmpty)
        await store.loadHistory()
        #expect(store.showsEmpty && store.historyLoaded)
    }

    @Test func historyOpensFromItsCopyOffline() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("make-\(UUID().uuidString)")
        let plans = FakePlansRepository()
        try await Self.keep(.sheet, "Balancing equations · sheet", at: 0, in: plans)
        let first = await Self.make(plans: plans)
        first.madeCache = CachedRead(centre: Self.centre, key: "make-made", directory: folder)
        await first.loadHistory()
        plans.nextError = URLError(.notConnectedToInternet)
        let offline = await Self.make(plans: plans)
        offline.madeCache = CachedRead(centre: Self.centre, key: "make-made", directory: folder)
        await offline.loadHistory()
        #expect(offline.made.map(\.title) == ["Balancing equations · sheet"])
        #expect(offline.madeSavedAt != nil && offline.historyError == nil)
    }

    @Test func aFailedReadWithNothingSavedSaysSo() async {
        let plans = FakePlansRepository()
        plans.nextError = URLError(.notConnectedToInternet)
        let store = await Self.make(plans: plans)
        await store.loadHistory()
        #expect(store.historyError == "Couldn't load History. Check your connection and try again.")
    }

    /// Hand run 14: a reload that fails offline after a good read keeps the read's time; the line never says nothing
    /// is saved over a list on screen.
    @Test func aFailedReloadAfterAGoodReadKeepsTheReadsTime() async throws {
        let plans = FakePlansRepository()
        try await Self.keep(.sheet, "Balancing equations · sheet", at: 0, in: plans)
        let history = FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed)
        let store = await Self.make(plans: plans, history: history)
        await store.loadHistory()
        plans.nextError = URLError(.notConnectedToInternet)
        history.nextError = URLError(.notConnectedToInternet)
        await store.loadHistory()
        #expect(store.savedAt == Self.now && store.offlineRead && store.historyError == nil)
    }
}
