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
        /// The server's jobs; nil writes an asked note at once, as the note day's job would (NoteWriter).
        var jobs: FakeJobsRepository?
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
        let reader = NoteRecordReader(
            textbooks: FakeTextbooksRepository.evening(), record: FakeRecordRepository(checks: [], homework: []),
            attendance: FakeAttendanceRepository(sessions: sessions(devAbsentAllWeek: world.devAbsentAllWeek)),
            schoolItems: nil
        )
        let context = NoteContext(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, reader: reader,
            messages: world.messages, plans: world.plans, ai: world.ai,
            jobs: world.jobs ?? serving(world, reader: reader), notesCache: world.notesCache,
            online: { [online = world.online] in online }, now: { sunday1830 }, calendar: DayHeading.india,
            pause: {}
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

    /// Write again is the phone's call: the note shown stays until the new one arrives (Phase 21, as the sheet's), so
    /// its failure keeps that note and its facts and says so.
    @Test func aFailedWriteAgainKeepsTheNoteShownAndSaysSo() async {
        let world = World()
        let store = await Self.make(Self.dev, world)
        await store.load()
        let shown = store.message
        world.ai.scriptByKind[.note] = .failure(.service)
        await store.writeAgain(.warmer)
        #expect(store.stage == .ready && store.message == shown && store.facts.count == 4)
        #expect(store.alert == "Couldn't write it again. The note you have is still here.")
        world.ai.scriptByKind[.note] = nil
        await store.writeAgain(.warmer)
        #expect(store.stage == .ready && world.plans.kept.count == 2)
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

/// D107 and D110 on the note: an edit kept at Send (never an unchanged draft), Write again's reason sent and kept, a
/// note
/// the check set aside shown as such, and the tutor's own note in its place kept as a replacement.
extension NoteStoreTests {
    @Test func anUnchangedSendWritesNoFeedbackAnEditWritesOne() async {
        let recorder = FakeFeedbackRecorder()
        let store = await Self.make(Self.dev, World())
        store.feedback = recorder
        await store.load()
        #expect(await store.send())
        #expect(recorder.recorded.isEmpty)
        store.message += " रमेश जी"
        #expect(await store.send())
        #expect(recorder.recorded.map(\.kind) == [.edit])
        #expect(recorder.recorded.first?.revised?.text == store.message.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test func writeAgainCarriesItsReasonKeepsItAndTheOldNoteStaysUntilTheNewOne() async throws {
        let world = World(), recorder = FakeFeedbackRecorder()
        let store = await Self.make(Self.dev, world)
        store.feedback = recorder
        await store.load()
        let old = store.message
        world.ai.delay = .seconds(1)
        let task = Task { await store.writeAgain(.lessAboutMarks) }
        try await Task.sleep(for: .milliseconds(300))
        #expect(store.stage == .ready && store.message == old)
        #expect(store
            .regeneratingLine == "A note with less about marks is on its way. This one stays until it arrives.")
        await task.value
        #expect(world.ai.noteCalls.last?.reason == "Less about marks")
        #expect(recorder.recorded.map(\.kind) == [.again] && recorder.recorded.first?.reason == "Less about marks")
        #expect(store.rewriting == nil && world.plans.kept.count == 2)
    }

    @Test func aSetAsideNoteShowsTheCardAndWriteItMyselfKeepsAReplacement() async {
        let world = World(), recorder = FakeFeedbackRecorder()
        let draft = UUID()
        world.plans.setAside = [Self.dev: draft]
        let store = await Self.make(Self.dev, world)
        store.feedback = recorder
        await store.load()
        #expect(store.stage == .setAside && world.ai.noteCalls.isEmpty)
        #expect(!store.canSend && store.facts.map(\.label) == ["Taught", "Got right", "To practise", "Coming"])
        #expect(
            store.setAsideLine == "The draft said something that is not in Dev's record, so it was set aside. "
                + "Tap Write again for a fresh one, or write it yourself."
        )
        #expect(store
            .aiLine == "Every note is checked against Dev's record before it reaches you. This one did not pass.")
        store.writeMyself()
        #expect(store.stage == .ready && store.message.isEmpty && store.english == nil)
        store.message = "नमस्ते रमेश जी, इस हफ़्ते देव ने समीकरण सीखे।"
        #expect(await store.send())
        #expect(recorder.recorded == [Feedback.replace(draft, with: .text("नमस्ते रमेश जी, इस हफ़्ते देव ने समीकरण सीखे।"))])
    }

    /// The review of Phase 21 (R-app-2): Send again on the same note keeps its feedback once.
    @Test func anEditedNoteSentTwiceKeepsOneEdit() async {
        let recorder = FakeFeedbackRecorder()
        let store = await Self.make(Self.dev, World())
        store.feedback = recorder
        await store.load()
        store.message += " रमेश जी"
        #expect(await store.send())
        #expect(await store.send())
        #expect(recorder.recorded.map(\.kind) == [.edit])
    }

    /// The review of Phase 21 (R-app-3): after Write it myself, a note the server writes (Try Again) is not the tutor's
    /// own: sending it keeps no replacement.
    @Test func aServerNoteShownAfterWriteItMyselfIsNotTheTutorsOwn() async {
        let world = World(), recorder = FakeFeedbackRecorder()
        world.plans.setAside = [Self.dev: UUID()]
        let store = await Self.make(Self.dev, world)
        store.feedback = recorder
        await store.load()
        store.writeMyself()
        // The server writes a passing note meanwhile (the note day's job, or request_note).
        world.plans.setAside = [:]
        let server = await Self.make(Self.dev, world)
        await server.load()
        await store.make()
        #expect(store.stage == .ready && !store.writingOwn && !store.message.isEmpty)
        #expect(await store.send())
        #expect(recorder.recorded.isEmpty)
    }

    @Test func aNoteKeptThisWeekIsNotSetAside() async {
        let world = World()
        let first = await Self.make(Self.dev, world)
        await first.load()
        world.plans.setAside = [Self.dev: UUID()]
        let again = await Self.make(Self.dev, World(ai: FakeAIRepository(), plans: world.plans))
        await again.load()
        #expect(again.stage == .ready)
    }
}
