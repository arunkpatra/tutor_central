import Data
import Domain
import Foundation
import Students
import Testing
@testable import AITools

@MainActor struct AIStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow

    static func make(
        ai: FakeAIRepository = FakeAIRepository(),
        history: FakeAIHistoryRepository = FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed),
        centres: FakeCentreRepository = FakeCentreRepository(),
        workspace: Workspace = FakeCentreRepository.meeraWorkspaceConsented,
        messages: FakeMessageLogRepository = FakeMessageLogRepository()
    ) async -> AIStore {
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        return AIStore(
            workspace: workspace, register: register, ai: ai, history: history, centres: centres, messages: messages,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed, now: { now }), now: { now }
        )
    }

    @Test func historyLoadsNewestFirstAndRecentIsThree() async {
        let store = await Self.make()
        #expect(!store.historyLoaded && store.recent.isEmpty)
        await store.loadHistory()
        #expect(store.historyLoaded && store.history.count == 6 && store.recent.count == 3)
        #expect(store.history.first?.title(studentName: store.studentName) == "Quadratic equations")
        #expect(store.history[1].title(studentName: store.studentName) == "Hemanth Reddy", "the note names its student")
        #expect(store.history.first?.line(className: store.className, calendar: DayHeading.india)
            == "Question paper · Class 10 Maths · Tue 6 Oct")
        #expect(
            store.history[1].line(className: store.className, calendar: DayHeading.india)
                == "Progress note · Class 10 Maths · Mon 5 Oct",
            "a note's line names its student's class"
        )
    }

    @Test func aFailedHistoryReadSaysSoAndKeepsNothingStale() async {
        let history = FakeAIHistoryRepository(generations: [])
        let store = await Self.make(history: history)
        history.nextError = URLError(.notConnectedToInternet)
        await store.loadHistory()
        #expect(store.historyError == "Couldn't load History. Check your connection and try again." && !store
            .historyLoaded)
        await store.loadHistory()
        #expect(store.historyError == nil && store.historyLoaded)
    }

    @Test func aResultIsFoundInMemoryThenInTheRepository() async throws {
        let store = await Self.make()
        let seeded = try #require(FakeAIHistoryRepository.seed.first)
        #expect(await store.generation(seeded.id)?.id == seeded.id)
        #expect(await store.generation(UUID()) == nil)
    }

    @Test func theNoteMessageCarriesTheSignatureAndTheParentsNumber() async throws {
        let store = await Self.make()
        let note = try #require(FakeAIHistoryRepository.seed.first { $0.kind == .progressNote })
        let message = try #require(store.noteMessage(note, text: "Hello Lakshmi, a short note."))
        #expect(message.name == "Hemanth Reddy" && message.parentLine == "Lakshmi Reddy · +91 93802 60871")
        #expect(message.text == "Hello Lakshmi, a short note.\n\nMeera Nair\nBright Minds Tuition")
        #expect(message.url?.absoluteString.hasPrefix("https://wa.me/919380260871?text=") == true)
    }

    @Test func openingTheNoteLogsCopiesAndOpens() async throws {
        let messages = FakeMessageLogRepository()
        let store = await Self.make(messages: messages)
        var copied: String?
        var opened: URL?
        store.effects = AIStore.Effects(copy: { copied = $0 }, open: { opened = $0 })
        let note = try #require(FakeAIHistoryRepository.seed.first { $0.kind == .progressNote })
        await store.openNote(note, text: "Hello Lakshmi.")
        #expect(messages.progressLogs == [note.studentID].compactMap(\.self))
        #expect(copied == "Hello Lakshmi.\n\nMeera Nair\nBright Minds Tuition" && opened?.host() == "wa.me")
    }

    @Test func consentIsRecordedAndMerged() async {
        let centres = FakeCentreRepository()
        let store = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(store.needsConsent)
        var merged: Workspace?
        store.onWorkspaceChanged = { merged = $0 }
        #expect(await store.recordConsent())
        #expect(centres.consents.count == 1 && merged?.centre.aiConsentAt != nil && !store.needsConsent)
        centres.nextError = URLError(.notConnectedToInternet)
        let again = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(await !(again.recordConsent()))
        #expect(again.message == "Couldn't save your agreement. Check your connection and try again.")
    }

    @Test func theMonthLineCountsTheStudentsClassesAndNamesTheFee() async throws {
        let store = await Self.make()
        let hemanth = try #require(FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" })
        await store.loadMonthLine(for: hemanth.id)
        let line = try #require(store.monthLines[hemanth.id])
        #expect(line.hasSuffix("classes attended · October fee due"), "\(line)")
    }
}
