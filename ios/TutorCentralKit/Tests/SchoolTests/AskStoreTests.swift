import Data
import Domain
import Foundation
import School
import Students
import Testing

@MainActor struct AskStoreTests {
    final class Opened: @unchecked Sendable {
        var urls: [URL] = []
    }

    func makeStore(
        students: [Student] = FakeStudentsRepository.eveningSeed,
        log: FakeMessageLogRepository = FakeMessageLogRepository(),
        opened: Opened = Opened(), online: Bool = true
    ) async -> AskStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { SchoolFixtures.now }
        )
        await register.load()
        return AskStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, messages: log,
            open: { opened.urls.append($0) }, now: { SchoolFixtures.now }, online: { online }
        )
    }

    /// The seed with Riya's parent's number on Dev too, and Sahil without a number.
    var sharedNumber: [Student] {
        let devPhone = FakeStudentsRepository.eveningSeed.first { $0.id == FakeStudentsRepository.dev }?.parentPhone
        return FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            if student.id == FakeStudentsRepository.riya {
                changed.parentPhone = devPhone
            }
            if student.id == FakeStudentsRepository.sahil {
                changed.parentPhone = nil
            }
            return changed
        }
    }

    @Test func oneRowPerParentNumberWithTheirStudentsNamed() async {
        let store = await makeStore(students: sharedNumber)
        await store.load()
        let shared = store.rows.first { $0.studentIDs.contains(FakeStudentsRepository.dev) }
        #expect(shared?.line == "Dev and Riya's parent" && shared?.studentIDs.count == 2)
        #expect(!store.rows.contains { $0.studentIDs.contains(FakeStudentsRepository.sahil) })
        #expect(Set(store.rows.map(\.id)).count == store.rows.count)
    }

    @Test func sendLogsEachStudentAndOpensWhatsAppWithTheMessage() async throws {
        let log = FakeMessageLogRepository()
        let opened = Opened()
        let store = await makeStore(students: sharedNumber, log: log, opened: opened)
        await store.load()
        let row = try #require(store.rows.first { $0.studentIDs.contains(FakeStudentsRepository.dev) })
        await store.send(row)
        let asked = try await log.forwardAsked(centre: FakeCentreRepository.meeraWorkspace.centre.id)
        #expect(Set(asked.keys) == [FakeStudentsRepository.dev, FakeStudentsRepository.riya])
        let url = try #require(opened.urls.first)
        #expect(url.host() == "wa.me")
        let text = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
        #expect(text == store.message)
        #expect(store.rows.first { $0.id == row.id }?.sent == true)
        #expect(store.countLine == "1 of \(store.rows.count) sent")
    }

    @Test func aParentAskedBeforeReadsSentOnLoad() async {
        let entry = MessageEntry(id: UUID(), kind: .forwardAsk, openedAt: SchoolFixtures.now, language: nil)
        let log = FakeMessageLogRepository(entries: [FakeStudentsRepository.meher: [entry]])
        let store = await makeStore(log: log)
        await store.load()
        #expect(store.rows.first { $0.studentIDs.contains(FakeStudentsRepository.meher) }?.sent == true)
        #expect(store.countLine.hasPrefix("1 of "))
    }

    @Test func sendOfflineIsRefusedInWords() async throws {
        let log = FakeMessageLogRepository()
        let opened = Opened()
        let store = await makeStore(log: log, opened: opened, online: false)
        await store.load()
        let row = try #require(store.rows.first)
        await store.send(row)
        #expect(store.notice == OfflineRefusal.words(for: .forwardAsk) && opened.urls.isEmpty)
        #expect(try await log.forwardAsked(centre: FakeCentreRepository.meeraWorkspace.centre.id).isEmpty)
    }

    @Test func theMessageIsHeldTo600Scalars() async {
        let store = await makeStore()
        #expect(store.message.hasPrefix("Hello, this is Meera from Bright Minds Tuition."))
        store.message = String(repeating: "क", count: 700)
        #expect(store.message.unicodeScalars.count == ForwardAskMessage.limit)
    }
}
