import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// The close offline (D39): kept on this iPhone, one per batch and day, sent with the queue; Today's hero reads it.
@MainActor struct CloseQueueTests {
    let tests = CloseStoreTests()

    func queue() -> ChangeQueue {
        ChangeQueue(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    @Test func offlineACloseIsKeptHere() async throws {
        let queue = queue()
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await tests.store(attendance: attendance)
        store.queue = queue
        store.online = { false }
        #expect(await store.done())
        #expect(attendance.closes.isEmpty && queue.pending.has(kind: .close))
        #expect(store.phase == .savedHere(at: CloseStoreTests.fivepast))
        guard case let .close(_, className, present, total) = try #require(queue.pending.changes.first).kind else {
            Issue.record("not a close")
            return
        }
        #expect(className == "Evening batch" && present == 5 && total == 5)
    }

    @Test func aCloseRefusedForTheNetworkIsKeptHereToo() async {
        let queue = queue()
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await tests.store(attendance: attendance)
        store.queue = queue
        attendance.nextError = URLError(.notConnectedToInternet)
        #expect(await store.done())
        #expect(queue.pending.has(kind: .close) && store.message == nil)
    }

    @Test func aSecondCloseOfTheSameBatchAndDayReplacesTheFirst() async {
        let queue = queue()
        let first = await tests.store()
        first.queue = queue
        first.online = { false }
        _ = await first.done()
        let again = await tests.store()
        again.queue = queue
        again.online = { false }
        again.toggle(0)
        _ = await again.done()
        #expect(queue.pending.changes.count == 1)
        if case let .close(close, _, present, _) = queue.pending.changes[0].kind {
            #expect(present == 4 && close.marks.values.contains(.absent))
        }
    }

    @Test func openingTheCloseOfflineGivesAttendanceAndHomeworkWithTheChecksTold() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.offline)
        let store = await tests.store(ai: ai)
        #expect(store.students.allSatisfy { $0.checks == .none || $0.checks == .failed(CloseStore.offlineWords) })
        #expect(store.students.first?.checks == .failed(
            "You're offline. The checks need a connection; mark attendance and homework, and Done still closes."
        ))
    }

    @Test func aBookThatCouldNotBeReadSaysTheChecksNeedAConnection() async {
        let textbooks = FakeTextbooksRepository.evening()
        textbooks.nextError = URLError(.notConnectedToInternet)
        let store = await tests.store(textbooks: textbooks)
        #expect(store.students.contains { $0.checks == .failed(CloseStore.offlineWords) })
        let failed = store.students.firstIndex { $0.checks == .failed(CloseStore.offlineWords) } ?? 0
        await store.retryChecks(for: failed)
        #expect(store.students[failed].checks != .failed(CloseStore.offlineWords))
    }

    @Test func withTwoBatchesClosedTheLatestCloseTakesTheHero() async throws {
        let queue = queue()
        let store = await tests.store(now: CloseStoreTests.at(7, 17, 30))
        store.queue = queue
        store.online = { false }
        _ = await store.done()
        var sessions = FakeAttendanceRepository.seedWithToday
        sessions[0].closedAt = CloseStoreTests.at(7, 17, 20)
        let today = await TodayStoreTests().make(
            now: CloseStoreTests.at(7, 17, 40), students: FakeStudentsRepository.eveningSeed,
            classes: FakeClassesRepository.withEvening, sessions: sessions
        )
        today.queue = queue
        await today.load()
        let hero = try #require(today.hero)
        #expect(hero.kind == .closed && hero.eyebrow == "Evening batch · saved on this iPhone")
        #expect(hero.line == "Homework given to 5")
    }

    @Test func theStudentsShowAtOnceWhileTheReadsWait() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        attendance.delay = .seconds(2)
        let register = await tests.register()
        let store = CloseStore(
            classID: FakeClassesRepository.evening.id, workspace: FakeCentreRepository.meeraWorkspace,
            register: register, textbooks: FakeTextbooksRepository.evening(), record: FakeRecordRepository(),
            attendance: attendance, ai: FakeAIRepository(), now: { CloseStoreTests.fivepast }
        )
        let loading = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(300))
        #expect(store.students.count == 5 && store.students.allSatisfy { $0.checks == .loading && $0.present })
        await loading.value
        #expect(store.loaded)
    }

    @Test func aCloseKeptHereMakesTodaysHeroReadClosed() async throws {
        let queue = queue()
        let store = await tests.store()
        store.queue = queue
        store.online = { false }
        store.toggle(tests.index(store, "Nikhil Das"))
        store.tap(tests.index(store, "Dev Kumar"), 0, right: true)
        _ = await store.done()
        let today = await TodayStoreTests().make(
            now: CloseStoreTests.at(7, 18, 10), students: FakeStudentsRepository.eveningSeed,
            classes: FakeClassesRepository.withEvening
        )
        today.queue = queue
        await today.load()
        let hero = try #require(today.hero)
        #expect(hero.kind == .closed && hero.eyebrow == "Evening batch · saved on this iPhone")
        #expect(hero.title == "4 of 5 came" && hero.line == "1 of 1 check right · homework given to 4 · Nikhil absent")
    }
}
