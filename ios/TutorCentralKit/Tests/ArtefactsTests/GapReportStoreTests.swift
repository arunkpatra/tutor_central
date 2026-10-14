import Data
import Domain
import Foundation
import Students
import Testing
@testable import Artefacts

/// The gap report after a marked mock (P10-GapReport; plan/phase-13-plan.md decision 15): made once from the marking
/// and
/// the mock, kept with the exam, the hero counting the days left, Use this plan marking it used.
@MainActor struct GapReportStoreTests {
    nonisolated static let wednesday14 = DayHeading.india.date(from: DateComponents(
        year: 2026, month: 10, day: 14, hour: 18, minute: 50
    ))!
    var exam: SchoolItem {
        FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }!
    }

    struct World {
        let plans: FakePlansRepository
        let record: FakeRecordRepository
        let mock: Artefact
    }

    /// The exam's mock kept, and Dev's mark on it: every question right but the first's marks halved.
    func world() async throws -> World {
        let plans = FakePlansRepository(now: Self.wednesday14)
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
            to: ArtefactLink(item: exam.id, student: nil), centre: ArtefactTest.centre
        )
        let questions = made.content.sections.flatMap(\.questions)
        let marks = questions.map { question in
            CheckResult.QuestionMark(
                number: question.number, text: question.text, note: question.number == 1 ? "One slip" : "",
                marks: question.number == 1 ? 0 : question.marks, of: question.marks, changedFrom: nil
            )
        }
        let score = marks.reduce(0) { $0 + $1.marks }
        let mark = MarkRecord(
            id: UUID(), studentID: FakeStudentsRepository.dev, subject: "Science", test: "Science unit test 3 · mock",
            date: Day(year: 2026, month: 10, day: 14)!, score: score, max: made.content.marks, photoPath: nil,
            schoolItemID: exam.id, artefactID: mock.id, questions: marks
        )
        return World(plans: plans, record: FakeRecordRepository(marks: [mark]), mock: mock)
    }

    /// The Evening batch with Dev's parent's consent recorded unless asked otherwise.
    func register(devConsents: Bool = true) async -> RegisterStore {
        let students = FakeStudentsRepository.eveningSeed.map { student in
            guard student.id == FakeStudentsRepository.dev, devConsents, let phone = student.parentPhone else {
                return student
            }
            var changed = student
            changed.consent = ConsentRecord(at: Self.wednesday14, phone: phone, how: .inPerson)
            return changed
        }
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { Self.wednesday14 }
        )
        await register.load()
        return register
    }

    func store(
        _ world: World, ai: FakeAIRepository = FakeAIRepository(), devConsents: Bool = true, online: Bool = true
    ) async -> GapReportStore {
        let store = await GapReportStore(
            itemID: exam.id, studentID: FakeStudentsRepository.dev, workspace: FakeCentreRepository.meeraWorkspace,
            register: register(devConsents: devConsents), plans: world.plans, ai: ai, record: world.record,
            schoolItems: FakeSchoolItemsRepository(items: [exam]), now: { Self.wednesday14 },
            calendar: DayHeading.india
        )
        store.online = { online }
        return store
    }

    @Test func theReportIsMadeOnceFromTheMarkingAndKept() async throws {
        let world = try await world()
        let ai = FakeAIRepository()
        let store = await store(world, ai: ai)
        await store.load()
        #expect(store.stage == .ready && ai.gapCalls.count == 1)
        let mock = try #require({
            if case let .mock(content) = world.mock.content {
                content
            } else {
                nil
            }
        }())
        var skills: [String] = []
        for question in mock.sections.flatMap(\.questions) where !skills.contains(question.skill) {
            skills.append(question.skill)
        }
        #expect(store.report?.bySkill.map(\.skill) == skills)
        #expect(try await world.plans.gapReport(
            for: exam.id, student: FakeStudentsRepository.dev, centre: ArtefactTest.centre
        ) != nil)
        let again = await self.store(world, ai: ai)
        await again.load()
        #expect(ai.gapCalls.count == 1 && again.stage == .ready)
    }

    @Test func theHeroCountsTheDaysLeft() async throws {
        let store = try await store(world())
        await store.load()
        #expect(store.eyebrow == "Dev Kumar · Science mock · marked Wed 14 Oct")
        #expect(store.line == "The test is on Friday. Two days left.")
        #expect(store.score == store.report?.score && store.of == 40)
        #expect(store.days.first?.date == "15 Oct" && store.days.first?.day == "Thu")
    }

    @Test func useSetsUsedAtAndTellsThePlan() async throws {
        let world = try await world()
        let store = await store(world)
        await store.load()
        var told: UUID?
        store.onUsed = { told = $0 }
        #expect(await store.use())
        #expect(store.used && told == FakeStudentsRepository.dev)
        let kept = try await world.plans.gapReport(
            for: exam.id, student: FakeStudentsRepository.dev, centre: ArtefactTest.centre
        )
        guard case let .gapReport(content)? = kept?.content else {
            Issue.record("no report")
            return
        }
        #expect(content.usedAt == Self.wednesday14)
    }

    /// P21-GapReport-Used: a report the exam's job used reads as in the plan, with the footnote naming whose marks.
    @Test func aUsedGapReportShowsTheDoneRow() async throws {
        let world = try await world()
        let store = await store(world)
        await store.load()
        #expect(!store.used)
        #expect(await store.use())
        let again = await self.store(world)
        await again.load()
        #expect(again.used)
        #expect(again.usedFootnote
            == "The last two days were changed from this report when Dev's marks were saved. "
            + "Change them on the exam's page.")
    }

    @Test func withoutConsentNothingIsMade() async throws {
        let ai = FakeAIRepository()
        let store = try await store(world(), ai: ai, devConsents: false)
        await store.load()
        #expect(ai.gapCalls.isEmpty)
        #expect(store.stage == .failed("Dev's gap report waits for Ramesh's consent. Record it on Dev's page."))
    }

    @Test func offlineTheKeptReportOpensAndANewOneIsRefused() async throws {
        let world = try await world()
        let made = await store(world)
        await made.load()
        let offline = await store(world, online: false)
        await offline.load()
        #expect(offline.stage == .ready)
        let fresh = try await self.world()
        let ai = FakeAIRepository()
        let refused = await store(fresh, ai: ai, online: false)
        await refused.load()
        #expect(ai.gapCalls.isEmpty && refused.stage == .failed(OfflineRefusal.words(for: .gapReport)))
    }
}
