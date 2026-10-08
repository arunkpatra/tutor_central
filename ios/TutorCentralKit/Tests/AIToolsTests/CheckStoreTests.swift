import Data
import Domain
import Foundation
import Students
import Testing
@testable import AITools

@MainActor struct CheckStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 1]), mediaType: "image/jpeg")
    static let hemanth = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id ?? UUID()

    static func make(
        ai: FakeAIRepository = FakeAIRepository(),
        students: FakeStudentsRepository = FakeStudentsRepository(students: FakeStudentsRepository.seed),
        workspace: Workspace = FakeCentreRepository.meeraWorkspaceConsented
    ) async -> CheckStore {
        let register = RegisterStore(
            workspace: workspace, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        let store = CheckStore(
            workspace: workspace, register: register, ai: ai,
            history: FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed), students: students,
            centres: FakeCentreRepository(), now: { now }
        )
        store.studentID = hemanth
        return store
    }

    @Test func pagesAreCappedAtSixAndTheSchemeComesFromHistoryOrIsTyped() async {
        let store = await Self.make()
        store.addPages(Array(repeating: Self.page, count: 7))
        #expect(store.pages.count == 6 && store.message == "Up to six pages. The extra ones were left out.")
        store.removePage(at: 0)
        #expect(store.pages.count == 5 && store.canContinue)
        await store.loadPapers()
        #expect(store.papers.map { $0.title(studentName: { _ in nil }) } == [
            "Quadratic equations", "Photosynthesis", "Linear equations in two variables", "Light and reflection",
            "Trigonometry basics",
        ], "notes are not schemes")
        store.scheme = .typed("Q1 (1) b")
        #expect(store.scheme.isValid)
    }

    @Test func checkClampsAndFailsInWords() async throws {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai)
        store.addPages([Self.page, Self.page])
        let paper = try #require(FakeAIHistoryRepository.seed.first)
        await store.loadPapers()
        store.scheme = .paper(generationID: paper.id)
        await store.check()
        #expect(store.stage == .result && store.result?.total == 14 && store.result?.outOf == 20)
        #expect(store.title == "Quadratic equations")
        #expect(store.totalLine == "10 questions · 2 pages · checked today")
        #expect(ai.checks == [SchemeSource.paper(generationID: paper.id)])
        ai.script = .failure(.tooLarge)
        await store.retry()
        #expect(store.stage == .failed("That's too many pages. Up to six, and try sharper, smaller photos."))
    }

    @Test func saveAppendsAndUndoRestoresExactly() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        store.addPages([Self.page])
        store.scheme = .typed("Q1 (1) b")
        await store.check()
        store.set(question: 6, to: 2)
        #expect(store.result?.total == 15 && store.saveLabel == "Save 15 of 20 to Hemanth's notes")
        #expect(await store.save())
        let update = try #require(students.notesUpdates.last)
        #expect(update.id == Self.hemanth)
        #expect(update.notes == "7 Oct · Typed scheme · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted.")
        #expect(store.saved && store.previousNotes == nil)
        #expect(store.toast == "Saved to Hemanth's notes: 15 of 20 on Typed scheme.")
        #expect(await store.undoSave())
        #expect(students.notesUpdates.last?.notes == nil && !store.saved, "nil goes back as nil")
        // Full notes refuse in words.
        _ = try await students.updateNotes(id: Self.hemanth, notes: String(repeating: "x", count: 1990))
        let again = await Self.make(students: students)
        again.addPages([Self.page])
        again.scheme = .typed("Q1 (1) b")
        await again.check()
        #expect(await !(again.save()))
        #expect(again.message == "Hemanth's notes are full. Share the marks instead, or shorten the notes first.")
    }

    @Test func aSecondSaveAppendsToTheSavedNotesAndConsentIsAskedFirst() async {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        store.addPages([Self.page])
        store.scheme = .typed("Q1 (1) b")
        await store.check()
        #expect(await store.save())
        #expect(await store.undoSave())
        #expect(await store.save())
        #expect(students.notesUpdates.count == 3 && students.notesUpdates.last?.notes?.contains("\n") == false)
        let unconsented = await Self.make(workspace: FakeCentreRepository.meeraWorkspace)
        #expect(unconsented.needsConsent)
        #expect(unconsented.shareText.isEmpty, "nothing to share before a check")
    }

    @Test func aSecondCheckWhileOneRunsIsRefusedAndCancelDropsTheLateAnswer() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(200)
        let store = await Self.make(ai: ai)
        store.addPages([Self.page])
        store.scheme = .typed("Q1 (1) b")
        store.begin()
        try await Task.sleep(for: .milliseconds(30))
        #expect(store.stage == .checking && ai.checks.count == 1)
        store.begin()
        try await Task.sleep(for: .milliseconds(30))
        #expect(ai.checks.count == 1, "one check at a time")
        store.cancel()
        #expect(store.stage == .scheme)
        try await Task.sleep(for: .milliseconds(300))
        #expect(store.stage == .scheme && store.result == nil, "a cancelled check's answer is dropped")
    }

    @Test func aConsentRefusalAsksForConsentAndChecksAgain() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.consent)
        let store = await Self.make(ai: ai)
        store.addPages([Self.page])
        store.scheme = .typed("Q1 (1) b")
        await store.check()
        #expect(store.askingConsent && store.needsConsent)
        #expect(store.stage == .failed(APIFailure.consent.message), "not left on the checking card")
        ai.script = .answer
        #expect(await store.recordConsent())
        await store.retry()
        #expect(!store.askingConsent && store.stage == .result)
    }
}
