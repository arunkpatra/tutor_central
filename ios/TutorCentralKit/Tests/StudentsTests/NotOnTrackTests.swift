import Data
import Domain
import Foundation
import Testing
@testable import Students

/// Not on track on the student's page (P10-Student-NotOnTrack, P10-NextStep, P10-NotOnTrack-Message;
/// plan/phase-14-plan.md decisions 9 and 10): the next step the plan chose unless changed, and the message to the
/// parent.
@MainActor struct NotOnTrackTests {
    nonisolated static let friday = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 9,
        hour: 16,
        minute: 35
    ))!
    static let dev = FakeStudentsRepository.dev
    static let meher = FakeStudentsRepository.meher
    static let riya = FakeStudentsRepository.riya

    static func students(step: NextStep? = nil) -> [Student] {
        FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            if student.id == dev {
                changed.trackStatus = .notOnTrack
                changed.trackSince = friday
                changed.trackReasons = ["3 of 10 on the mock", "Absent twice in four weeks"]
                changed.messageLanguage = .hindi
                changed.nextStep = step
            }
            if student.id == meher || student.id == riya {
                changed.trackStatus = .notOnTrack
                changed.trackSince = friday
                changed.trackReasons = ["1 of 6 checks right over three weeks"]
                changed.messageLanguage = student.id == riya ? .hindi : .english
            }
            if student.id != riya, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: friday, phone: phone, how: .inPerson)
            }
            return changed
        }
    }

    final class Opened {
        var url: URL?
    }

    @MainActor struct World {
        var repository = FakeStudentsRepository(students: NotOnTrackTests.students())
        var log = FakeMessageLogRepository(now: { NotOnTrackTests.friday })
        var ai = FakeAIRepository()
        var online = true
        var opened = Opened()
    }

    static func register(_ world: World) async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: world.repository,
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { friday }
        )
        await register.loadIfNeeded()
        return register
    }

    static func detail(_ id: UUID, _ world: World) async -> StudentDetailStore {
        let store = await StudentDetailStore(
            id: id, register: register(world), attendance: FakeAttendanceRepository(sessions: []), messages: world.log,
            textbooks: FakeTextbooksRepository.notOnTrack(), record: FakeRecordRepository(checks: [], homework: []),
            now: { friday }, online: { [online = world.online] in online }
        )
        await store.load()
        return store
    }

    static func message(_ id: UUID, _ world: World) async -> NotOnTrackStore {
        let opened = world.opened
        return await NotOnTrackStore(
            student: id, register: register(world), textbooks: FakeTextbooksRepository.notOnTrack(), ai: world.ai,
            messages: world.log, online: { [online = world.online] in online },
            effects: NotOnTrackStore.Effects(copy: { _ in }, open: { opened.url = $0 })
        )
    }

    @Test func theCardsNextReadsTheEffectiveStepAndChangeWritesTheChoice() async {
        let world = World()
        let store = await Self.detail(Self.dev, world)
        #expect(store.tracking?.next == "Tell the parent, then teach again with the worked example.")
        #expect(store.tracking?.canChange == true)
        #expect(store.nextStepRows.map(\.title) == NextStep.allCases.map(\.title) && store.chosenStep == .tellParent)
        #expect(store.nextStepRows[2].meaning == "Counting atoms in a formula, then balancing equations")
        #expect(await store.chooseStep(.stepBack))
        #expect(world.repository.nextStepCalls.last == .stepBack)
        #expect(store.tracking?.next == "Step back to Counting atoms in a formula, then Balancing equations.")
        #expect(await store.chooseStep(.tellParent))
        #expect(world.repository.nextStepCalls.last == .some(nil))
    }

    @Test func theTellParentCardShowsUntilTheParentIsToldOrTheStepChanges() async {
        let store = await Self.detail(Self.dev, World())
        #expect(store.tellParent?.title == "Ramesh Kumar has not been told yet")
        #expect(store.tellParent?.line.hasPrefix("A message in Hindi that says what is hard") == true)
        let world = World()
        let told = MessageEntry(
            id: UUID(), kind: .notOnTrack, openedAt: Self.friday.addingTimeInterval(600), language: .hindi
        )
        world.log.entries = [Self.dev: [told]]
        let page = await Self.detail(Self.dev, world)
        #expect(page.tellParent == nil)
        _ = await store.chooseStep(.leave)
        #expect(store.tellParent == nil)
    }

    @Test func aChangedStatusClearsTheTutorsStepAsTheDatabaseDoes() async {
        let world = World(repository: FakeStudentsRepository(students: Self.students(step: .stepBack)))
        let register = await Self.register(world)
        register.applyTracking([Self.dev: SessionClose.Track(status: .notOnTrack, reasons: [])], at: Self.friday)
        #expect(register.student(Self.dev)?.nextStep == .stepBack)
        register.applyTracking([Self.dev: SessionClose.Track(status: .watch, reasons: [])], at: Self.friday)
        #expect(register.student(Self.dev)?.nextStep == nil)
    }

    @Test func aStepWaitsWhileACloseThatTracksTheStudentIsStillToBeSent() async {
        let world = World()
        let store = await Self.detail(Self.dev, world)
        store.closeWaits = { (_: UUID) in true }
        #expect(await store.chooseStep(.stepBack) == false)
        #expect(store.message == StudentDetailStore.closeWaitingWords)
        #expect(world.repository.nextStepCalls.isEmpty)
    }

    @Test func offlineTheChangeIsRefusedInWords() async {
        let store = await Self.detail(Self.dev, World(online: false))
        #expect(await store.chooseStep(.stepBack) == false && store.message == OfflineRefusal.words(for: .nextStep))
    }

    @Test func anEnglishParentGetsTheTemplateWithNoCall() async {
        let world = World()
        let store = await Self.message(Self.meher, world)
        await store.make()
        #expect(store.stage == .ready && store.english == nil && world.ai.notOnTrackCalls.isEmpty)
        #expect(store.message.hasPrefix("Hello Kavita, Meher is finding"))
        #expect(!store.message.contains(MessageSignature.madeWith))
        #expect(store.signedBody.hasSuffix("Made with Tutor Central"))
    }

    @Test func aHindiParentWithConsentGetsTheMadeMessageWithTheEnglishBeside() async {
        let world = World()
        let store = await Self.message(Self.dev, world)
        await store.make()
        #expect(store.english?.contains("Dev is finding") == true && store.heading == "Dev needs a hand this month")
        #expect(store.languageTitle == "Hindi" && world.ai.notOnTrackCalls.first?.facts.hard == ["balancing equations"])
        #expect(!store.message.contains(MessageSignature.madeWith))
        #expect(store.signatureLines == "Meera Nair\nBright Minds Tuition\nMade with Tutor Central")
    }

    @Test func aParentWithoutConsentGetsTheEnglishTemplateAndTheReason() async {
        let world = World()
        let store = await Self.message(Self.riya, world)
        await store.make()
        #expect(world.ai.notOnTrackCalls.isEmpty && store.english == nil && store.languageTitle == "English")
        #expect(store.note.hasPrefix("Neha hasn't agreed yet, so this is in English."))
    }

    @Test func openLogsNotOnTrackWithTheLanguageAndSignedBody() async {
        let world = World()
        let store = await Self.message(Self.dev, world)
        await store.make()
        var heard = false
        store.onSent = { heard = true }
        #expect(await store.open())
        #expect(heard)
        let logged = world.log.messageLogs.first
        #expect(logged?.kind == .notOnTrack && logged?.language == .hindi)
        #expect(logged?.body.hasSuffix("Made with Tutor Central") == true && world.opened.url?.host() == "wa.me")
    }
}
