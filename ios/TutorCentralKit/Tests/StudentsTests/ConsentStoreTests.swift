import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct ConsentStoreTests {
    let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()

    func store(logs: [MessageEntry] = [], online: Bool = true) async throws -> (ConsentStore, RegisterStore) {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let messages = FakeMessageLogRepository(entries: [FakeStudentsRepository.riya: logs], now: { [now] in now })
        let store = ConsentStore(
            studentID: FakeStudentsRepository.riya, register: register, messages: messages, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition", now: { [now] in now }, online: { online }
        )
        await store.load()
        return (store, register)
    }

    @Test func notRecordedThenWaitingAfterAnAsk() async throws {
        let (store, _) = try await store()
        #expect(store.state == .notRecorded && store.title == "Not recorded yet")
        #expect(store.line == "Before Riya's own work, marks or name go to the AI service, her parent agrees once: in "
            + "person, on a call or on WhatsApp. Note it here.")
        let url = await store.openWhatsApp()
        #expect(url?.absoluteString.hasPrefix("https://wa.me/919811122233?text=") == true)
        #expect(try store.state == .waiting(askedOn: #require(Day(year: 2026, month: 10, day: 7))))
        #expect(store.title == "Asked Neha Sharma on Wed 7 Oct")
    }

    @Test func recordThenRemove() async throws {
        let (store, register) = try await store()
        store.sheet.how = .call
        #expect(store.sheet.digits == "9811122233" && store.sheet.canRecord)
        #expect(await store.record())
        #expect(register.student(FakeStudentsRepository.riya)?.consent?.how == .call)
        #expect(store.title == "Neha Sharma agreed" && store.line == "Wed 7 Oct · +91 98111 22233 · on a call")
        #expect(await store.remove())
        #expect(register.student(FakeStudentsRepository.riya)?.consent == nil && store.state == .notRecorded)
    }

    @Test func waitingShowsAfterAnAskUntilRecorded() async throws {
        let asked = MessageEntry(id: UUID(), kind: .consent, openedAt: now - 2 * 86400, language: nil)
        let (store, _) = try await store(logs: [asked])
        #expect(try store.state == .waiting(askedOn: #require(Day(year: 2026, month: 10, day: 5))))
        #expect(store.line == "Waiting for her reply. Riya's own notes and marking wait too; sheets and sets do not.")
        _ = await store.record()
        #expect(store.title == "Neha Sharma agreed")
    }

    @Test func theMessageSpeaksOfTheChildAndSignsOff() async throws {
        let (store, _) = try await store()
        #expect(store.message.hasPrefix("Hello Neha, I use Tutor Central to plan Riya's classes"))
        #expect(store.message.hasSuffix("Meera Nair\nBright Minds Tuition"))
    }

    @Test func offlineTheAskAndTheRecordAreRefusedInWords() async throws {
        let (store, _) = try await store(online: false)
        #expect(await store.openWhatsApp() == nil)
        #expect(store.failure == OfflineRefusal.words(for: .consent))
    }

    @Test func aStoreMadeBeforeTheRegisterIsReadTakesTheNumberOnLoad() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let store = ConsentStore(
            studentID: FakeStudentsRepository.riya, register: register, messages: FakeMessageLogRepository(),
            tutorName: nil, centreName: nil, now: { [now] in now }
        )
        #expect(store.sheet.digits.isEmpty)
        await register.load()
        await store.load()
        #expect(store.sheet.digits == "9811122233" && store.agreedOnText == "Today, 7 Oct")
    }
}
