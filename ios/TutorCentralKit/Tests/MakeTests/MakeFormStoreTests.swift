import Data
import Domain
import Foundation
import Students
import Testing
@testable import Make

/// A kind's form (plan/phase-15-plan.md Task 8, decisions 3 and 7 to 13; Review focus 1, 2, 6 and 7).
@MainActor struct MakeFormStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let dev = FakeStudentsRepository.dev
    static let meher = FakeStudentsRepository.meher
    static let riya = FakeStudentsRepository.riya

    struct Kit {
        let store: MakeFormStore
        let make: MakeStore
        let ai: FakeAIRepository
        let plans: FakePlansRepository
    }

    static func kit(
        _ kind: MakeKind, students: [Student] = FakeStudentsRepository.eveningSeed,
        plans: FakePlansRepository = FakePlansRepository.evening(), ai: FakeAIRepository = FakeAIRepository(),
        online: Bool = true, defaults: UserDefaults? = nil
    ) async -> Kit {
        let workspace = FakeCentreRepository.meeraWorkspaceConsented
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.load()
        let assistant = await AIStoreTests.make(ai: ai)
        let make = MakeStore(workspace: workspace, register: register, plans: plans, ai: assistant, now: { now })
        plans.now = now
        let context = MakeContext(
            workspace: workspace, register: register, plans: plans, textbooks: FakeTextbooksRepository.evening(),
            schoolItems: FakeSchoolItemsRepository(items: FakeSchoolItemsRepository.boardItems), ai: ai,
            online: { online }, now: { now }, calendar: DayHeading.india, defaults: defaults
        )
        let store = MakeFormStore(kind: kind, context: context, make: make)
        await store.prepare()
        return Kit(store: store, make: make, ai: ai, plans: plans)
    }

    static var groupOne: MakeTarget {
        .group(plan: FakePlansRepository.planID, number: 1)
    }

    @Test func makeWaitsForALevelAndATopic() async {
        var noLevel = FakeStudentsRepository.eveningSeed
        if let index = noLevel.firstIndex(where: { $0.id == Self.riya }) {
            noLevel[index].classLevel = nil
        }
        let kit = await Self.kit(.sheet, students: noLevel)
        kit.store.choose(.student(Self.riya))
        #expect(kit.store.level == nil && !kit.store.canMake)
        // The review's R-app-2: the helper names the way out (P10-Make-Form has no Class tile).
        #expect(kit.store.helper == "Riya has no class yet. Set it on their page, or choose a class in For.")
        let group = await Self.kit(.workedExample, students: noLevel.map { student in
            var changed = student
            changed.classLevel = nil
            return changed
        }, plans: FakePlansRepository())
        group.store.choose(.batch(FakeClassesRepository.evening.id))
        #expect(group.store.helper == "No class is set for Evening batch's students. Choose a class in For.")
        kit.store.choose(.classLevel(.five))
        kit.store.subject = "Mathematics"
        #expect(!kit.store.canMake)
        kit.store.skill = "Fractions"
        #expect(kit.store.canMake)
    }

    @Test func aSheetForAStudentSendsNoStudentAndNeedsNoConsent() async {
        let kit = await Self.kit(.sheet)
        kit.store.choose(.student(Self.dev))
        #expect(kit.store.subject == "Science" && kit.store.skill == "Balancing equations")
        let outcome = await kit.store.make()
        #expect(kit.ai.sheetRequests.last == SheetRequest(
            classLevel: .eight, subject: "Science", skills: ["Balancing equations"], questions: 10, forHomework: false,
            reason: nil
        ))
        guard case let .made(artefact) = outcome else { Issue.record("not made: \(outcome)"); return }
        #expect(artefact.studentID == Self.dev && artefact.madeFor?.title == "For Dev")
    }

    @Test func aGroupsSheetSendsTheGroupsLevelAndSkill() async {
        let kit = await Self.kit(.sheet)
        kit.store.choose(.group(plan: FakePlansRepository.planID, number: 2))
        let outcome = await kit.store.make()
        let asked = kit.ai.sheetRequests.last
        #expect(asked?.classLevel == .five && asked?.skills == ["Equivalent fractions"])
        guard case let .made(artefact) = outcome else { Issue.record("not made"); return }
        #expect(artefact.madeFor?.title == "Group 2" && artefact.studentID == nil)
    }

    @Test func lengthAndLevelReachTheRequest() async {
        let kit = await Self.kit(.sheet)
        kit.store.choose(Self.groupOne)
        kit.store.length = 15
        kit.store.levelReason = "easier"
        _ = await kit.store.make()
        #expect(kit.ai.sheetRequests.last?.questions == 15 && kit.ai.sheetRequests.last?.reason == "easier")
    }

    /// A kind switched off (D73, P20-Switched-Off): the system alert in the API's words, OK only, the form kept as it
    /// was and no failure row under it.
    @Test func aPausedAnswerShowsTheAlertWithOKAndKeepsTheForm() async {
        let ai = FakeAIRepository()
        let words = "Sheets can't be made right now. Making sheets is switched off for a short while "
            + "so we can fix something. Everything else works as usual. Try again later."
        ai.scriptByKind[.sheet] = .failure(.paused(words))
        let kit = await Self.kit(.sheet, ai: ai)
        kit.store.choose(Self.groupOne)
        let outcome = await kit.store.make()
        #expect(outcome == .refused)
        #expect(kit.store.alert == words)
        #expect(kit.make.failure == nil)
        #expect(kit.store.canMake)
    }

    @Test func theHelperNamesTheTarget() async {
        let kit = await Self.kit(.sheet)
        kit.store.choose(Self.groupOne)
        #expect(kit.store.helper
            == "Made against Group 1's record. A sheet made for a class alone follows the class's chapters.")
        kit.store.choose(.classLevel(.eight))
        #expect(kit.store.helper == "A sheet made for a class alone follows the class's chapters.")
    }

    @Test func aMadeSheetIsKeptWithMadeFromAndOpens() async throws {
        let kit = await Self.kit(.sheet)
        kit.store.choose(Self.groupOne)
        kit.store.keyAtEnd = false
        let outcome = await kit.store.make()
        guard case let .made(artefact) = outcome else { Issue.record("not made"); return }
        #expect(artefact.madeFrom == "make" && artefact.title == "Balancing equations · sheet")
        #expect(artefact.madeFor?.keyAtEnd == false && artefact.madeFor?.skills == ["Balancing equations"])
        #expect(try await kit.plans.made(centre: UUID()).map(\.id) == [artefact.id])
        #expect(kit.make.recent.first?.opens == .artefact(artefact.id))
    }

    @Test func anExamWithAMockOpensItWithoutACall() async {
        let mock = FakePlansRepository.boardMock
        let plans = FakePlansRepository(artefacts: [mock])
        let kit = await Self.kit(.mock, plans: plans)
        kit.store.studentID = Self.dev
        let exam = kit.store.exams.first { $0.id == FakeSchoolItemsRepository.devsTest }
        kit.store.exam = exam.map(ExamChoice.item)
        #expect(await kit.store.make() == .opensExisting(mock.id))
        #expect(kit.ai.mockCalls.isEmpty)
    }

    @Test func aStudentsExamsAreTheComingOnesNearestFirst() async {
        let kit = await Self.kit(.mock)
        kit.store.studentID = Self.dev
        #expect(kit.store.exams.map(\.title) == ["Science unit test", "Science unit test 3"])
    }

    @Test func aMockForAnExamIsKeptWithTheExam() async {
        let kit = await Self.kit(.mock, plans: FakePlansRepository())
        kit.store.studentID = Self.dev
        kit.store.exam = kit.store.exams.last.map(ExamChoice.item)
        guard case let .made(artefact) = await kit.store.make() else { Issue.record("not made"); return }
        #expect(artefact.schoolItemID == FakeSchoolItemsRepository.scienceTest3)
        #expect(artefact.title == "Science unit test 3 · mock" && artefact.studentID == Self.dev)
        #expect(kit.ai.mockCalls.last?.pattern == .default(for: .eight))
    }

    @Test func aTypedMockHasNoExam() async {
        let kit = await Self.kit(.mock, plans: FakePlansRepository())
        kit.store.studentID = Self.dev
        kit.store.exam = .typed(subject: "Science", title: "Class test", portions: "Chemical reactions")
        guard case let .made(artefact) = await kit.store.make() else { Issue.record("not made"); return }
        #expect(artefact.schoolItemID == nil && artefact.title == "Class test · mock")
        #expect(kit.ai.mockCalls.last?.portions == ["Chemical reactions"])
    }

    @Test func aFigureWhoseSpecFailsIsRefusedInWords() async throws {
        let ai = FakeAIRepository()
        ai.figureOverride = FigureContent(figure: .fractionBar(parts: 4, shaded: 6, label: "6/4"), caption: "c")
        let plans = FakePlansRepository.evening()
        let kit = await Self.kit(.figure, plans: plans, ai: ai)
        kit.store.choose(.classLevel(.five))
        kit.store.subject = "Mathematics"
        kit.store.skill = "Fractions on a bar"
        #expect(await kit.store.make() == .failed)
        #expect(kit.make.failure?.message == MakeWords.figureRefused)
        #expect(try await plans.made(centre: UUID()).isEmpty)
    }

    @Test func theFigureTemplateFollowsTheSkill() async {
        let kit = await Self.kit(.figure)
        kit.store.skill = "Fractions on a bar"
        #expect(kit.store.template == .fractionBar)
        kit.store.chosenTemplate = .numberLine
        #expect(kit.store.template == .numberLine)
    }

    @Test func aBriefIsMadeForTheClassAndChapter() async {
        let kit = await Self.kit(.brief)
        kit.store.classLevel = .eight
        #expect(kit.store.subjectChoices == ["Science"])
        kit.store.subject = "Science"
        #expect(kit.store.chapterChoices == ["Chemical reactions", "Metals and non-metals"])
        kit.store.chapter = "Chemical reactions"
        guard case let .made(artefact) = await kit.store.make() else { Issue.record("not made"); return }
        #expect(kit.ai.briefs.last == "Chemical reactions" && artefact.madeFor?.title == "Class 8")
    }

    @Test func aNoteOpensPhase14sNoteWithTheTutorsWords() async throws {
        var students = FakeStudentsRepository.eveningSeed
        if let index = students.firstIndex(where: { $0.id == Self.meher }) {
            students[index].consent = students[index].parentPhone.map { ConsentRecord(
                at: Self.now,
                phone: $0,
                how: .whatsapp
            ) }
        }
        let kit = await Self.kit(.noteToParent, students: students)
        kit.store.studentID = Self.meher
        kit.store.tutorSays = "  Ask her to read aloud. "
        let sunday = try #require(Day(year: 2026, month: 10, day: 4))
        #expect(await kit.store.make() == .opensNote(Self.meher, sunday, tutorSays: "Ask her to read aloud."))
        #expect(kit.ai.noteCalls.isEmpty)
    }

    @Test func aNoteForAStudentWithoutConsentIsRefusedBeforeAnyCall() async {
        let kit = await Self.kit(.noteToParent)
        kit.store.studentID = Self.dev
        #expect(await kit.store.make() == .refused)
        #expect(kit.store.alert?.hasSuffix("Record it on Dev's page first.") == true)
        #expect(kit.ai.noteCalls.isEmpty)
    }

    @Test func offlineMakeIsRefusedAndTheFormKept() async {
        let kit = await Self.kit(.sheet, online: false)
        kit.store.choose(Self.groupOne)
        let skill = kit.store.skill
        #expect(await kit.store.make() == .refused)
        #expect(kit.store.alert == OfflineRefusal.words(for: .make))
        #expect(kit.store.skill == skill && kit.ai.sheetRequests.isEmpty)
    }

    @Test func leavingTheFormDoesNotLoseTheCall() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(200)
        let kit = await Self.kit(.sheet, ai: ai)
        kit.store.choose(Self.groupOne)
        let started = Task { await kit.store.make() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(kit.make.running?.kind == .sheet)
        _ = await started.value
        #expect(kit.make.running == nil && kit.make.recent.first?.title == "Balancing equations · sheet")
    }

    @Test func aSecondMakeWhileOneRunsIsRefused() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(200)
        let kit = await Self.kit(.sheet, ai: ai)
        kit.store.choose(Self.groupOne)
        let first = Task { await kit.store.make() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(await kit.store.make() == .refused)
        _ = await first.value
    }
}

@MainActor struct ForStoreTests {
    @Test func groupsAreTodaysPlansGroups() async {
        let kit = await MakeFormStoreTests.kit(.sheet)
        let store = kit.store.forStore()
        await store.load()
        #expect(store.groups.map(\.title) == [
            "Group 1 · Chemical reactions", "Group 2 · Parts and wholes", "Group 3 · Reading",
        ])
        #expect(store.groups.first?.line.hasSuffix("Class 8 Science · today's plan") == true)
        #expect(store.groups.first?.line.hasPrefix("Dev, Meher") == true)
    }

    @Test func withNoPlanTodayTheGroupSegmentIsEmptyInWords() async {
        let kit = await MakeFormStoreTests.kit(.sheet, plans: FakePlansRepository())
        let store = kit.store.forStore()
        await store.load()
        #expect(store.groups.isEmpty && store.groupsEmptyLine == "Open Today to make the plan.")
    }

    /// Hand run 1: with two batches meeting today, each group's line names its batch (two "Group 1"s otherwise).
    @Test func twoBatchesTodayNameTheirGroupsBatch() async throws {
        let evening = FakePlansRepository.evening()
        let plan = try #require(evening.plans.first)
        let maths = PlanRecord(
            id: UUID(), classID: FakeClassesRepository.maths.id, date: plan.date, madeAt: plan.madeAt,
            groups: Array(plan.groups.prefix(1)), items: [], artefacts: [], sessionID: nil
        )
        let plans = FakePlansRepository(plans: evening.plans + [maths], artefacts: [], now: evening.now)
        let kit = await MakeFormStoreTests.kit(.sheet, plans: plans)
        let store = kit.store.forStore()
        await store.load()
        #expect(store.groups.filter { $0.line.hasPrefix("Evening batch · ") }.count == plan.groups.count)
        #expect(store.groups.filter { $0.line.hasPrefix("Class 10 Maths · ") }.count == 1)
    }

    /// Hand run 1: the For tile opens on the segment of what is chosen (a group's on Group), Student when nothing is.
    @Test func theForTileOpensOnTheChosenTargetsSegment() async {
        let kit = await MakeFormStoreTests.kit(.sheet)
        #expect(kit.store.forSegment == .student)
        kit.store.choose(MakeFormStoreTests.groupOne)
        #expect(kit.store.forSegment == .group)
        kit.store.choose(.classLevel(.eight))
        #expect(kit.store.forSegment == .level)
        kit.store.choose(.batch(FakeClassesRepository.evening.id))
        #expect(kit.store.forSegment == .batch)
    }

    @Test func theBatchesCountTheirStudentsAndTheCentresLevelsComeFirst() async {
        let kit = await MakeFormStoreTests.kit(.sheet)
        let store = kit.store.forStore()
        await store.load()
        #expect(store.batches.first { $0.title == "Evening batch" }?.line == "5 students")
        #expect(Array(store.levels.prefix(4)) == [.two, .five, .eight, .ten])
        #expect(store.levels.count == ClassLevel.allCases.count)
    }
}
