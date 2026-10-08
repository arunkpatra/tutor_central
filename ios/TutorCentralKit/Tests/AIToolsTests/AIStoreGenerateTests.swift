import Data
import Domain
import Foundation
import Testing
@testable import AITools

@MainActor struct AIStoreGenerateTests {
    static let maths = FakeClassesRepository.maths.id
    static let paper = GenerateRequest.paper(PaperForm(
        classID: maths,
        subject: "Mathematics",
        topic: "Quadratic equations"
    ))

    @Test func aGenerationSurvivesLeavingTheScreen() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(60)
        let store = await AIStoreTests.make(ai: ai)
        var arrived: Generation?
        store.onResult = { arrived = $0 }
        #expect(store.create(Self.paper) == .started)
        #expect(store.inFlight?.line == "Writing 10 questions on Quadratic equations")
        // The form's screen is gone (nothing observes the store) and the call keeps running.
        try await Task.sleep(for: .milliseconds(150))
        #expect(store.inFlight == nil && arrived?.kind == .paper)
        #expect(store.history.first?.id == arrived?.id, "the new result leads History and Recent without a reload")
        #expect(ai.requests.count == 1)
    }

    @Test func aSecondCreateWhileOneRunsIsRefused() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(60)
        let store = await AIStoreTests.make(ai: ai)
        #expect(store.create(Self.paper) == .started)
        #expect(store.create(Self.paper) == .busy)
        #expect(store.message == "One at a time: the last one is still being written.")
        try await Task.sleep(for: .milliseconds(150))
        #expect(store.create(Self.paper) == .started)
    }

    @Test func aFailureKeepsTheFormAndOffersRetry() async throws {
        let ai = FakeAIRepository()
        let store = await AIStoreTests.make(ai: ai)
        ai.script = .failure(.service)
        #expect(store.create(Self.paper) == .started)
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure == AIStore.Failure(
            kind: .paper,
            message: "The AI service didn't answer. Try again.",
            consent: false
        ))
        #expect(store.forms[.paper] == Self.paper, "the form is still filled")
        ai.script = .answer
        store.retry()
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure == nil && store.history.first?.kind == .paper)
        ai.script = .failure(.limit(40))
        _ = store.create(Self.paper)
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.failure?.message == "You've made today's 40. Try again tomorrow." && store.failure?
            .canRetry == false)
    }

    @Test func aNoteWithoutConsentAsksFirstAndAnInvalidFormIsRefused() async {
        let store = await AIStoreTests.make(workspace: FakeCentreRepository.meeraWorkspace)
        let note = GenerateRequest.progressNote(NoteForm(
            studentID: FakeStudentsRepository.akshita, observations: "Improving", tone: .warm
        ))
        #expect(store.create(note) == .needsConsent)
        #expect(store.create(.paper(PaperForm())) == .invalid)
        #expect(store.create(Self.paper) == .started, "a paper needs no consent")
    }

    @Test func createAgainKeepsTheOldResultUntilTheNewOneLands() async throws {
        let ai = FakeAIRepository()
        let store = await AIStoreTests.make(ai: ai)
        await store.loadHistory()
        let old = try #require(store.history.first)
        ai.delay = .milliseconds(60)
        #expect(store.createAgain(old) == .started)
        #expect(store.inFlight?.regenerating == old.id)
        #expect(await store.generation(old.id) != nil, "the old one is still there")
        try await Task.sleep(for: .milliseconds(150))
        #expect(store.inFlight == nil && store.history.first?.id != old.id && store.history.count == 7)
    }

    @Test func cancelStopsWaitingAndLeavesNoFailure() async throws {
        let ai = FakeAIRepository()
        ai.delay = .milliseconds(200)
        let store = await AIStoreTests.make(ai: ai)
        var arrived: Generation?
        store.onResult = { arrived = $0 }
        #expect(store.create(Self.paper) == .started)
        store.cancel()
        #expect(store.inFlight == nil)
        try await Task.sleep(for: .milliseconds(250))
        #expect(arrived == nil && store.failure == nil && store.history.isEmpty)
    }

    @Test func theContextNamesTheClassTheStudentAndTheAttendance() async throws {
        let store = await AIStoreTests.make()
        let context = store.context(for: Self.paper)
        #expect(context.className == "Class 10 Maths" && context.subject == "Mathematics")
        #expect(context.tutorName == "Meera Nair" && context.centreName == "Bright Minds Tuition")
        let hemanth = try #require(FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" })
        let note = store.context(for: .progressNote(NoteForm(studentID: hemanth.id, observations: "x", tone: .warm)))
        #expect(note.studentName == "Hemanth Reddy" && note.parentName == "Lakshmi Reddy")
        #expect(note.className == "Class 10 Maths" && note.subject == "Mathematics")
    }

    @Test func aNewFormStartsOnTheFirstActiveClassWithItsSubject() async {
        let store = await AIStoreTests.make()
        guard case let .paper(form) = store.form(for: .paper) else {
            Issue.record("not a paper form")
            return
        }
        #expect(form.classID == FakeClassesRepository.maths.id && form.subject == "Mathematics" && form.topic.isEmpty)
    }
}
