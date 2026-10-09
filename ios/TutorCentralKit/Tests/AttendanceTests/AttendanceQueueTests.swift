import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct AttendanceQueueTests {
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
    let messages = FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)
    let hemanth = FakeAttendanceRepository.hemanth

    func queue() -> ChangeQueue {
        ChangeQueue(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    func make(online: Bool, queue: ChangeQueue) async -> AttendanceStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: messages, now: { FakeCountsRepository.fixedNow }
        )
        store.queue = queue
        store.online = { online }
        await store.load()
        return store
    }

    @Test func offlineASaveIsKeptHereAndTheScreenReadsSaved() async throws {
        let waiting = queue()
        let store = await make(online: false, queue: waiting)
        store.toggle(hemanth)
        #expect(await store.save())
        #expect(waiting.pending.waitingCount == 1 && attendance.saves.isEmpty)
        let change = try #require(waiting.pending.changes.first)
        #expect(change.title == "Attendance · Class 10 Maths")
        if case let .attendance(_, _, _, marks, present, total) = change.kind {
            #expect(marks[hemanth] == .absent && present == 5 && total == 6)
        } else {
            Issue.record("not attendance")
        }
        #expect(store.phase == .savedHere(at: FakeCountsRepository.fixedNow))
        #expect(store.banner?.text == "Saved on this iPhone at 18:30. It's sent when you're back online.")
        #expect(store.absentRows.map(\.student.id) == [hemanth])
    }

    @Test func onlineButWithASaveWaitingTheNewSaveJoinsTheQueue() async throws {
        let waiting = queue()
        let day = try #require(Day(year: 2026, month: 10, day: 6))
        waiting.add(QueuedChange(
            kind: .attendance(classID: nil, className: "All students", date: day, marks: [:], present: 6, total: 6),
            madeAt: Date()
        ))
        let store = await make(online: true, queue: waiting)
        store.toggle(hemanth)
        #expect(await store.save())
        #expect(waiting.pending.waitingCount == 2 && attendance.saves.isEmpty)
    }

    @Test func aSaveTheNetworkDropsIsKeptHereToo() async {
        let waiting = queue()
        let store = await make(online: true, queue: waiting)
        store.toggle(hemanth)
        attendance.nextError = URLError(.networkConnectionLost)
        #expect(await store.save())
        #expect(waiting.pending.waitingCount == 1)
        if case .savedHere = store.phase {} else {
            Issue.record("not saved here: \(store.phase)")
        }
    }

    @Test func offlineTellParentStillOpensWhatsAppAndQueuesTheLog() async {
        let waiting = queue()
        let store = await make(online: false, queue: waiting)
        store.toggle(hemanth)
        _ = await store.save()
        let url = await store.tell(hemanth)
        #expect(url != nil && messages.logged.isEmpty)
        #expect(waiting.pending.changes.contains { $0.title == "Absence alert · Hemanth Reddy" })
        #expect(store.absentRows.first?.told == "Told today")
    }
}

@MainActor struct AttendanceAfterSendTests {
    /// Run 9: once the queue sent the save, the screen reads the server's session again: no "saved on this iPhone".
    @Test func reloadAfterTheSendReadsWhatTheServerHas() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let queue = ChangeQueue(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: FakeMessageLogRepository(), now: { FakeCountsRepository.fixedNow }
        )
        store.queue = queue
        store.online = { false }
        await store.load()
        store.toggle(FakeAttendanceRepository.hemanth)
        _ = await store.save()
        let runner = QueueRunner(
            queue: queue, centre: FakeCentreRepository.meeraWorkspace.centre.id, attendance: attendance,
            fees: FakeFeesRepository(), messages: FakeMessageLogRepository()
        )
        #expect(await runner.run() == .done(sent: 1, failed: 0))
        store.online = { true }
        await store.reload()
        if case .reopened = store.phase {} else {
            Issue.record("not reopened: \(store.phase)")
        }
        #expect(store.saved?.marks[FakeAttendanceRepository.hemanth] == .absent && store.savedAt == nil)
    }
}
