import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// The mock (P10-Mock): read from the plan or offline from its copy, the hero and the pattern line from the mock and
/// its
/// exam, Make it again kept with the exam, the PDF without the key unless asked, Mark from a photo for the exam's
/// students.
@MainActor struct MockStoreTests {
    /// Science unit test 3 for class 8 at Vidya Niketan on Friday 16 October.
    var exam: SchoolItem {
        FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }!
    }

    /// A plan whose Group 1 is the exam, its set line "The mock", and the mock kept with the plan and the exam.
    struct World {
        let plans: FakePlansRepository
        let mock: Artefact
        let plan: PlanRecord
    }

    func world() async throws -> World {
        let plans = FakePlansRepository(now: ArtefactTest.at1640)
        let group = PlanGroup(
            number: 1, subject: "Science", chapter: exam.title, skill: "The mock", classLevels: [.eight],
            memberIDs: [FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil],
            skillID: nil, examItemID: exam.id
        )
        let lines = group.memberIDs.map {
            PlanLine(studentID: $0, groupNo: 1, kind: .practise, skillID: nil, words: "The mock")
        }
        let draft = PlanDraft(
            classID: FakeClassesRepository.evening.id, date: ArtefactTest.wednesday, groups: [group], lines: lines,
            leftOut: []
        )
        let plan = try await plans.make(draft, centre: ArtefactTest.centre)
        let request = MockRequest(
            classLevel: .eight, subject: "Science", title: exam.title, portions: ["Chemical reactions"],
            pattern: .default(for: .eight), schoolItemID: exam.id
        )
        let made = try await FakeAIRepository().makeMock(request, centre: ArtefactTest.centre)
        let mock = try await plans.keep(
            NewArtefact(
                kind: .mock, source: .made, title: exam.title, content: .mock(made.content), photoPath: nil,
                generationID: made.generationID, regeneratedFrom: nil
            ),
            to: ArtefactLink(plan: plan.id, group: 1, student: nil, itemKind: .practise, schoolItem: exam.id),
            centre: ArtefactTest.centre
        )
        let kept = try #require(try await plans.plan(id: plan.id, centre: ArtefactTest.centre))
        return World(plans: plans, mock: mock, plan: kept)
    }

    func store(
        _ plans: FakePlansRepository, _ id: UUID, ai: FakeAIRepository = FakeAIRepository(), online: Bool = true
    ) async -> MockStore {
        let store = await MockStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: plans, ai: ai, schoolItems: FakeSchoolItemsRepository(items: [exam]),
            schools: FakeSchoolsRepository(), now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        store.online = { online }
        return store
    }

    @Test func theMockOpensFromThePlanAndOffline() async throws {
        let world = try await world()
        let (mock, plan) = (world.mock, world.plan)
        let cache = PlanCache(
            centre: ArtefactTest.centre,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        cache.keep(plan, at: .now)
        let offline = FakePlansRepository()
        offline.nextError = URLError(.notConnectedToInternet)
        let store = await store(offline, mock.id)
        store.planCache = cache
        await store.load()
        #expect(store.loadFailed == nil && store.mock?.marks == 40)
    }

    @Test func theHeroAndPatternLineReadFromTheMockAndItsExam() async throws {
        let world = try await world()
        let (plans, mock) = (world.plans, world.mock)
        let store = await store(plans, mock.id)
        await store.load()
        #expect(store.eyebrow == "Science unit test 3 · Fri 16 Oct")
        #expect(store.title == "Mock in the school's pattern")
        #expect(store
            .line ==
            "40 marks · 60 minutes · Ch 1 Chemical reactions · Ch 2 Acids, bases and salts · made today, 16:40")
        #expect(store.patternLine == "as Vidya Niketan sets them")
    }

    @Test func againMakesANewMockAndRelinksTheExam() async throws {
        let world = try await world()
        let (plans, mock, plan) = (world.plans, world.mock, world.plan)
        let ai = FakeAIRepository()
        let store = await store(plans, mock.id, ai: ai)
        await store.load()
        #expect(await store.again())
        #expect(ai.mockCalls.count == 1 && ai.mockCalls.first?.schoolItemID == exam.id && ai.anotherCalls == 1)
        let newer = try #require(try await plans.mock(for: exam.id, centre: ArtefactTest.centre))
        #expect(newer.id != mock.id && store.artefact?.id == newer.id)
        #expect(plans.artefacts.contains { $0.id == mock.id })
        let relinked = try #require(try await plans.plan(id: plan.id, centre: ArtefactTest.centre))
        #expect(relinked.items.filter { $0.kind == .practise }.allSatisfy { $0.artefactID == newer.id })
        let offline = await self.store(plans, newer.id, online: false)
        await offline.load()
        #expect(await !offline.again() && offline.message == OfflineRefusal.words(for: .regenerate))
    }

    @Test func thePDFLeavesTheKeyOutUnlessAsked() async throws {
        let world = try await world()
        let (plans, mock) = (world.plans, world.mock)
        let store = await store(plans, mock.id)
        await store.load()
        let paper = store.pdfSheet(withKey: false)
        #expect(!paper.blocks.contains {
            if case .key = $0 {
                true
            } else {
                false
            }
        })
        #expect(paper.blocks.count == store.mock?.sections.count)
        let keyed = store.pdfSheet(withKey: true)
        #expect(keyed.blocks.contains {
            if case .key = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func markOffersEachOfTheExamsStudentsWithTheMocksScheme() async throws {
        let world = try await world()
        let (plans, mock) = (world.plans, world.mock)
        let store = await store(plans, mock.id)
        await store.load()
        #expect(store.students.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        var marked: MockMark?
        store.onMark = { marked = $0 }
        store.mark(store.students[1])
        let generation = try #require(mock.generationID)
        #expect(marked?.student.id == FakeStudentsRepository.meher)
        #expect(marked?.scheme == .mock(generationID: generation, artefactID: mock.id))
        #expect(marked?.subject == "Science" && marked?.test == "Science unit test 3 · mock")
        #expect(marked?.schoolItemID == exam.id && marked?.artefactID == mock.id)
    }
}
