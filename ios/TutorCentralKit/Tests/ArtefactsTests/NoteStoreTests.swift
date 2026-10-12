import Data
import Domain
import Foundation
import Students
import Testing
@testable import Artefacts

/// The weekly note and can-now-do (P10-Note, P10-CanNowDo, P10-Note-Send; plan/phase-14-plan.md decisions 1 to 3, 18,
/// 21). Sunday 11 October 18:30: Dev's parent writes in Hindi and agreed, Meher's in English, Sahil's in Kannada (the
/// ladder), Riya's (Hindi) has not agreed.
@MainActor struct NoteStoreTests {
    nonisolated static let sunday1830 = DayHeading.india.date(from: DateComponents(
        year: 2026, month: 10, day: 11, hour: 18, minute: 30
    ))!
    static let noteDay = Day(year: 2026, month: 10, day: 11)!
    static let dev = FakeStudentsRepository.dev
    static let meher = FakeStudentsRepository.meher
    static let sahil = FakeStudentsRepository.sahil
    static let riya = FakeStudentsRepository.riya

    final class Effects {
        var opened: URL?
        var copied: String?
    }

    @MainActor struct World {
        var ai = FakeAIRepository()
        var plans = FakePlansRepository(now: NoteStoreTests.sunday1830)
        var messages = FakeMessageLogRepository(now: { NoteStoreTests.sunday1830 })
        var online = true
        var devAbsentAllWeek = false
        var notesCache: NotesCache?
        var effects = Effects()
    }

    static func students() -> [Student] {
        let languages: [UUID: MessageLanguage] = [dev: .hindi, sahil: .kannada, riya: .hindi]
        return FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            changed.messageLanguage = languages[student.id] ?? .english
            if student.id != riya, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: sunday1830, phone: phone, how: .inPerson)
            }
            return changed
        }
    }

    static func sessions(devAbsentAllWeek: Bool) -> [AttendanceSession] {
        let members = FakeStudentsRepository.eveningSeed.filter { $0.classID == FakeClassesRepository.evening.id }
        return [5, 7, 9].map { day in
            var marks = Dictionary(uniqueKeysWithValues: members.map { ($0.id, AttendanceStatus.present) })
            marks[dev] = devAbsentAllWeek || day != 9 ? .absent : .present
            let date = Day(year: 2026, month: 10, day: day)!
            return AttendanceSession(
                id: UUID(), classID: FakeClassesRepository.evening.id, date: date,
                savedAt: date.date(in: DayHeading.india), marks: marks
            )
        }
    }

    static func make(_ student: UUID, _ world: World) async -> NoteStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: students()),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { sunday1830 }
        )
        await register.loadIfNeeded()
        let context = NoteContext(
            workspace: FakeCentreRepository.meeraWorkspace, register: register,
            reader: NoteRecordReader(
                textbooks: FakeTextbooksRepository.evening(), record: FakeRecordRepository(checks: [], homework: []),
                attendance: FakeAttendanceRepository(sessions: sessions(devAbsentAllWeek: world.devAbsentAllWeek)),
                schoolItems: nil
            ),
            messages: world.messages, plans: world.plans, ai: world.ai, notesCache: world.notesCache,
            online: { [online = world.online] in online }, now: { sunday1830 }, calendar: DayHeading.india
        )
        let effects = world.effects
        return NoteStore(
            student: student, noteDay: noteDay, context: context,
            effects: NoteStore.Effects(copy: { effects.copied = $0 }, open: { effects.opened = $0 })
        )
    }

    @Test func aNoteIsMadeFromTheWeeksFactsKeptAndShownWithTheEnglishBeside() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        #expect(store.stage == .ready && !store.isLadder)
        #expect(world.ai.noteCalls.first?.language == .hindi && world.ai.noteCalls.first?.week.attendance != nil)
        #expect(store.message.hasPrefix("नमस्ते") && store.english?.contains("Dev learnt") == true)
        #expect(store.heroName == "Dev Kumar" && store.heroLine == "Ramesh Kumar · Hindi · the week of 5 October")
        #expect(store.wellTitle == "The note · Hindi")
        #expect(store.facts.map(\.label) == ["Taught", "Got right", "To practise", "Coming"])
        #expect(world.plans.kept.first?.kind == .note && world.plans.artefacts.first?.studentID == Self.dev)
        #expect(world.plans.artefacts.first?.planID == nil)
    }

    @Test func aNoteAlreadyKeptThisWeekOpensWithoutACall() async {
        let world = World()
        let first = await Self.make(Self.dev, world)
        await first.load()
        let again = await Self.make(Self.dev, World(ai: FakeAIRepository(), plans: world.plans))
        await again.load()
        #expect(again.stage == .ready && again.message == first.message)
        #expect(world.ai.noteCalls.count == 1)
    }

    @Test func theTutorsWordsGoInTheRequestAndAreKept() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        store.tutorSays = "Ask him to read aloud."
        await store.load()
        #expect(world.ai.noteCalls.last?.tutorSays == "Ask him to read aloud.")
        guard case let .note(content)? = world.plans.artefacts.last?.content else { Issue.record("no note"); return }
        #expect(content.tutorSays == "Ask him to read aloud.")
        await store.writeAgain()
        #expect(world.ai.noteCalls.last?.tutorSays == "Ask him to read aloud.")
    }

    @Test func theTutorsWordsWithANoteKeptThisWeekMakeANewOne() async {
        let world = World()
        let first = await Self.make(Self.dev, world)
        await first.load()
        let kept = world.plans.artefacts.first?.id
        let again = await Self.make(Self.dev, World(ai: world.ai, plans: world.plans))
        again.tutorSays = "Please send the fee by Friday."
        await again.load()
        #expect(world.ai.noteCalls.count == 2 && world.ai.noteCalls.last?.tutorSays == "Please send the fee by Friday.")
        #expect(world.plans.kept.last?.regeneratedFrom == kept)
    }

    @Test func writeAgainMakesAFreshDraftAndKeepsTheOldOne() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        let first = world.plans.artefacts.first?.id
        await store.writeAgain()
        #expect(world.plans.kept.count == 2 && world.plans.kept.last?.regeneratedFrom == first)
        #expect(world.ai.anotherCalls == 1)
    }

    @Test func aLadderStudentGetsCanNowDoWithMovedUp() async {
        let world = World()
        let store = await Self.make(Self.sahil, world)
        await store.load()
        #expect(store.isLadder && world.ai.canDoCalls.count == 1 && world.ai.noteCalls.isEmpty)
        #expect(store.ladder?.area == "Reading")
        #expect(store.facts.map(\.label) == ["Can now do", "At home", "Next"])
        #expect(store.aiLine.hasSuffix("the facts are from Sahil's ladder."))
        #expect(store.heroLine == "Deepak Verma · Kannada · the week of 5 October")
        #expect(world.plans.kept.first?.kind == .canDo)
    }

    @Test func anEnglishParentSeesOneBlock() async {
        let store = await Self.make(Self.meher, World())
        await store.load()
        #expect(store.english == nil && store.wellTitle == "The note · English")
    }

    @Test func anAbsentStudentsNoteIsStillMade() async {
        let world = World(devAbsentAllWeek: true)
        let store = await Self.make(Self.dev, world)
        await store.load()
        #expect(store.stage == .ready)
        #expect(world.ai.noteCalls.first?.week.attendance == "absent all week (3 classes)")
        #expect(world.ai.noteCalls.first?.week.taught.isEmpty == true)
    }

    @Test func aNoteOverSixHundredScalarsCannotBeSentAndTheCounterSaysSo() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        store.message = String(repeating: "क", count: 601)
        #expect(!store.canSend && store.counter.text == "601 of 600" && store.counter.over)
        #expect(await store.send() == false && world.messages.messageLogs.isEmpty)
        store.message = String(repeating: "क", count: 600)
        #expect(store.canSend && store.counter.text == "600 of 600" && !store.counter.over)
    }

    @Test func aKannadaNoteCountsScalarsNotBytes() async {
        let store = await Self.make(Self.sahil, World())
        await store.load()
        store.message = String(repeating: "ನ", count: 600)
        #expect(store.canSend)
    }

    @Test func sendLogsTheKindLanguageAndSignedBodyThenOpensWhatsApp() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        #expect(await store.send())
        let logged = world.messages.messageLogs.first
        #expect(logged?.kind == .note && logged?.language == .hindi && logged?.channel == .whatsAppLink)
        #expect(logged?.body.hasSuffix("Made with Tutor Central") == true)
        #expect(logged?.body.hasPrefix(store.message) == true)
        #expect(world.effects.opened?.host() == "wa.me" && world.effects.copied == logged?.body && store.sent)
        #expect(store.sendSheet.heading == "Dev's week, for Ramesh" && store.sendSheet.title == "Send the note")
    }

    @Test func copyLogsAsCopiedAndSendsNothing() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        await store.copy()
        #expect(world.messages.messageLogs.first?.channel == .copied && !store.sent)
        #expect(world.effects.copied?.hasSuffix("Made with Tutor Central") == true)
    }

    @Test func aParentWithoutConsentIsRefusedBeforeAnyCall() async {
        let world = World()
        let store = await Self.make(Self.riya, world)
        await store.load()
        #expect(world.ai.noteCalls.isEmpty)
        #expect(store.stage == .failed("Riya's note waits for Neha's consent. Record it on Riya's page first."))
    }

    @Test func aFailedCallKeepsTheFactsAndOffersTryAgain() async {
        let world = World()
        world.ai.scriptByKind[.note] = .failure(.service)
        let store = await Self.make(Self.dev, world)
        await store.load()
        #expect(store.stage == .failed("The AI service didn't answer. Try again.") && store.facts.count == 4)
        world.ai.scriptByKind[.note] = nil
        await store.make()
        #expect(store.stage == .ready)
    }

    @Test func offlineAKeptNoteOpensFromItsCopyAndAnUnmadeOneIsRefused() async {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = NotesCache(centre: FakeCentreRepository.meeraWorkspace.centre.id, directory: directory)
        let made = await Self.make(Self.dev, World(notesCache: cache))
        await made.load()
        let kept = await Self.make(Self.dev, World(online: false, notesCache: cache))
        await kept.load()
        #expect(kept.stage == .ready && kept.message == made.message)
        let unmade = await Self.make(Self.meher, World(online: false, notesCache: cache))
        await unmade.load()
        #expect(unmade.stage == .failed(OfflineRefusal.words(for: .weeklyNote)))
    }

    @Test func aNoteAnsweredAsTheScreenIsLeftIsStillKeptSoTheNextReadMakesNoCall() async throws {
        let world = World()
        world.plans.keepDelay = .milliseconds(300)
        let store = await Self.make(Self.dev, world)
        let reading = Task { await store.load() }
        while world.ai.noteCalls.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }
        try await Task.sleep(for: .milliseconds(50))
        reading.cancel()
        try await Task.sleep(for: .milliseconds(450))
        #expect(world.plans.kept.count == 1)
    }

    @Test func aKeptCopyOpensAtOnceWhileTheServerIsSlow() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = NotesCache(centre: FakeCentreRepository.meeraWorkspace.centre.id, directory: directory)
        let made = await Self.make(Self.dev, World(notesCache: cache))
        await made.load()
        // U47: the connection hangs (the server read takes 20 s offline); the copy on this iPhone shows meanwhile.
        let world = World(notesCache: cache)
        world.plans.notesDelay = .seconds(2)
        let store = await Self.make(Self.dev, world)
        let opening = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(200))
        #expect(store.stage == .ready && store.message == made.message)
        opening.cancel()
        #expect(world.ai.noteCalls.isEmpty)
    }
}
