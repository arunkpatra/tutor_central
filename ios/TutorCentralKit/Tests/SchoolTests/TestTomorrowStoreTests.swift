import Data
import Domain
import Foundation
import School
import Testing

@MainActor struct TestTomorrowStoreTests {
    final class Opened: @unchecked Sendable {
        var url: URL?
    }

    /// Dev's own Science unit test on Thursday 8 October; Wednesday 7 October 18:40.
    var exam: SchoolItem {
        FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.devsTest }!
    }

    func dev(language: MessageLanguage, consent: Bool) -> Student {
        var student = FakeStudentsRepository.eveningSeed.first { $0.id == FakeStudentsRepository.dev }!
        student.messageLanguage = language
        student.gender = .male
        student.consent = consent
            ? ConsentRecord(at: SchoolFixtures.now, phone: student.parentPhone!, how: .inPerson) : nil
        return student
    }

    func makeStore(
        language: MessageLanguage, consent: Bool, ai: FakeAIRepository = FakeAIRepository(),
        messages: FakeMessageLogRepository = FakeMessageLogRepository(), opened: Opened = Opened()
    ) -> TestTomorrowStore {
        TestTomorrowStore(
            ask: TestTomorrowAsk(item: exam, student: dev(language: language, consent: consent)),
            workspace: FakeCentreRepository.meeraWorkspace, ai: ai, messages: messages,
            textbooks: FakeTextbooksRepository.evening(), open: { opened.url = $0 },
            now: { SchoolFixtures.now.addingTimeInterval(2 * 3600) }, calendar: DayHeading.india, online: { true }
        )
    }

    @Test func anEnglishParentGetsTheTemplateWithNoCallAndNoSecondBlock() async {
        let ai = FakeAIRepository()
        let store = makeStore(language: .english, consent: false, ai: ai)
        await store.make()
        #expect(store.stage == .ready && store.english == nil && ai.messageCalls.isEmpty)
        #expect(store.message.hasPrefix(
            "Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2."
        ))
        #expect(store.message.contains("let him go over balancing equations once."))
        #expect(store.title == "Dev's test is tomorrow" && store.languageTitle == "English")
    }

    @Test func aHindiParentWithConsentGetsTheMadeMessageWithTheEnglishBeside() async {
        let ai = FakeAIRepository()
        let store = makeStore(language: .hindi, consent: true, ai: ai)
        await store.make()
        #expect(store.english?.contains("Dev's science unit test is tomorrow") == true && store
            .languageTitle == "Hindi")
        #expect(ai.messageCalls.first?.language == .hindi && ai.messageCalls.first?.revise == "balancing equations")
        #expect(store.note.hasPrefix("Opens WhatsApp with the Hindi message ready to send. We note it on Dev's page."))
    }

    @Test func aHindiParentWithoutConsentGetsTheEnglishTemplateAndTheReason() async {
        let ai = FakeAIRepository()
        let store = makeStore(language: .hindi, consent: false, ai: ai)
        await store.make()
        #expect(ai.messageCalls.isEmpty && store.english == nil)
        #expect(store.consentLine == "Ramesh's language needs consent; this is in English.")
    }

    @Test func openLogsTheLanguageAndTheBodyAndOpensWhatsApp() async {
        let log = FakeMessageLogRepository()
        let opened = Opened()
        let store = makeStore(language: .english, consent: false, messages: log, opened: opened)
        await store.make()
        await store.open()
        #expect(log.testTomorrowLogs.first?.language == .english && log.testTomorrowLogs.first?.body == store.message)
        #expect(opened.url?.host() == "wa.me" && store.sent)
    }

    @Test func aFailedCallKeepsTheSheetWithTryAgainInWords() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.service)
        let store = makeStore(language: .hindi, consent: true, ai: ai)
        await store.make()
        #expect(store.stage == .failed("The AI service didn't answer. Try again."))
    }
}
