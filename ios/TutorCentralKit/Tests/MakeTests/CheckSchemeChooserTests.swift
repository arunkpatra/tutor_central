import Data
import Domain
import Foundation
import Students
import Testing
@testable import Make

/// Check a paper under Make (plan/phase-15-plan.md Task 9, decision 14; Review focus 8; U22, U23).
@MainActor struct CheckSchemeChooserTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let dev = FakeStudentsRepository.dev
    static let page = CheckStoreTests.page

    /// Dev's exam (Science unit test 3, class 8 at Vidya Niketan) has its mock; Make made one for Dev too.
    static func make(
        students: [Student] = FakeStudentsRepository.eveningSeed, history: [Generation] = FakeAIHistoryRepository.seed
    ) async -> CheckStore {
        let workspace = FakeCentreRepository.meeraWorkspaceConsented
        let roster = FakeStudentsRepository(students: students)
        let register = RegisterStore(
            workspace: workspace, students: roster,
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.load()
        let examMock = Artefact(
            id: UUID(), kind: .mock, source: .made, title: "Science unit test 3",
            content: FakePlansRepository.boardMock.content,
            photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: now.addingTimeInterval(-3600),
            generationID: UUID(), schoolItemID: FakeSchoolItemsRepository.scienceTest3
        )
        let plans = FakePlansRepository(artefacts: [examMock] + FakePlansRepository.madeRecent)
        let store = CheckStore(
            workspace: workspace, register: register, ai: FakeAIRepository(),
            history: FakeAIHistoryRepository(generations: history), students: roster, centres: FakeCentreRepository(),
            now: { now }, record: FakeRecordRepository(), plans: plans,
            schoolItems: FakeSchoolItemsRepository(items: FakeSchoolItemsRepository.boardItems)
        )
        store.studentID = dev
        return store
    }

    @Test func theChooserListsTheStudentsMocksThenThePapers() async {
        let store = await Self.make()
        await store.loadSchemes()
        let titles = store.schemeChoices.map(\.title)
        #expect(Array(titles.prefix(2)) == ["Science unit test 3 · the mock", "Science unit test 3 · the mock"])
        #expect(titles.dropFirst(2).first == "Quadratic equations")
        #expect(store.schemeChoices.filter(\.isMock).count == 2)
    }

    @Test func aMockChosenOnTheIntroSkipsTheSchemeStep() async throws {
        let store = await Self.make()
        await store.loadSchemes()
        let mock = try #require(store.schemeChoices.first)
        store.choose(mock)
        #expect(store.schemeChosenOnIntro && store.skipsScheme)
        #expect(store.schemeTitle == "Science unit test 3 · the mock")
        #expect(store.markTarget?.test == "Science unit test 3 · mock" && store.markTarget?.subject == "Science")
    }

    @Test func changingTheStudentClearsAMockSchemeAndKeepsAPaper() async throws {
        let store = await Self.make()
        await store.loadSchemes()
        try store.choose(#require(store.schemeChoices.first))
        store.studentID = FakeStudentsRepository.meher
        #expect(!store.schemeChosenOnIntro)
        if case .mock = store.scheme {
            Issue.record("a mock is another student's exam")
        }
        let paper = try #require(store.schemeChoices.first { !$0.isMock })
        store.choose(paper)
        store.studentID = Self.dev
        #expect(store.scheme == .paper(generationID: FakeAIHistoryRepository.quadraticID) && store.schemeChosenOnIntro)
    }

    @Test func aMocksKeyStillNeedsTheStudentsConsent() async throws {
        let store = await Self.make()
        await store.loadSchemes()
        try store.choose(#require(store.schemeChoices.first))
        store.addPages([Self.page])
        #expect(await store.checkFromPages())
        #expect(store.stage == .failed("Marking Dev's paper waits for Ramesh's consent. Record it on Dev's page."))
    }

    @Test func twoPapersOnOneTopicShowTheirDayAndTime() {
        let early = Self.paper(at: Self.now.addingTimeInterval(-3600))
        let late = Self.paper(at: Self.now)
        let line = { (paper: Generation) in
            CheckStore.paperLine(paper, calendar: DayHeading.india, batchName: { _ in nil })
        }
        #expect(line(early) != line(late))
        #expect(line(late).hasSuffix("Wed 7 Oct, 18:30"))
    }

    @Test func noPagesReadsNoPagesAndTheFooterIsOff() async {
        let store = await Self.make()
        store.addPages([Self.page, Self.page])
        #expect(store.pagesHeading == "2 pages")
        store.removePage(at: 0)
        #expect(store.pagesHeading == "1 page")
        store.removePage(at: 0)
        #expect(store.pagesHeading == "No pages" && !store.canContinue)
    }

    @Test func withNoSchemeChosenThePagesStepStillLeadsToTheScheme() async {
        let store = await Self.make()
        store.addPages([Self.page])
        #expect(!store.schemeChosenOnIntro && !store.skipsScheme)
    }

    @Test func theIntroTileNamesTheChoiceOrAsksForOne() async throws {
        let store = await Self.make()
        #expect(store.introSchemeTitle == "Type a scheme")
        await store.loadSchemes()
        try store.choose(#require(store.schemeChoices.first { !$0.isMock }))
        #expect(store.introSchemeTitle == "Quadratic equations")
    }

    static func paper(at date: Date) -> Generation {
        let seed = FakeAIHistoryRepository.seed[0]
        return Generation(id: UUID(), kind: seed.kind, createdAt: date, request: seed.request, result: seed.result)
    }
}

/// D62, spec section 8 (found writing the trust page): marking a student's paper waits for their parent's consent with
/// any scheme, and the call names the student so the gate asks it.
@MainActor struct CheckConsentTests {
    @Test func aPapersMarkingWaitsForTheStudentsConsentToo() async {
        let ai = FakeAIRepository()
        let store = await CheckStoreTests.make(
            ai: ai,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed)
        )
        await store.loadPapers()
        store.scheme = .paper(generationID: FakeAIHistoryRepository.quadraticID)
        store.addPages([CheckStoreTests.page])
        await store.check()
        #expect(store
            .stage == .failed("Marking Hemanth's paper waits for Lakshmi's consent. Record it on Hemanth's page."))
        #expect(ai.checks.isEmpty)
    }

    @Test func aTypedSchemesMarkingNamesTheStudent() async {
        let ai = FakeAIRepository()
        let consented = FakeStudentsRepository.seed.map { student in
            var agreed = student
            agreed.consent = student.parentPhone
                .map { ConsentRecord(at: CheckStoreTests.now, phone: $0, how: .whatsapp) }
            return agreed
        }
        let store = await CheckStoreTests.make(ai: ai, students: FakeStudentsRepository(students: consented))
        store.scheme = .typed("Q1 (1) b")
        store.addPages([CheckStoreTests.page])
        await store.check()
        #expect(ai.checkStudents.last == CheckStoreTests.hemanth)
    }
}
