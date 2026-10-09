import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct FeesQueueTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let dev = FakeFeesRepository.devOctober

    func queue() -> ChangeQueue {
        ChangeQueue(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    func make(online: Bool, queue: ChangeQueue) async -> FeesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees,
            messages: FakeMessageLogRepository(), centres: FakeCentreRepository(),
            now: { FakeCountsRepository.fixedNow }
        )
        store.queue = queue
        store.online = { online }
        await store.load()
        return store
    }

    @Test func offlineMarkPaidIsKeptHereAndUndoRemovesIt() async throws {
        let waiting = queue()
        let store = await make(online: false, queue: waiting)
        #expect(await store.markPaid(dev, method: .upi, on: store.today))
        #expect(fees.paid.isEmpty && waiting.pending.waitingCount == 1)
        #expect(store.invoice(dev)?.status == .paid && store.keptHere.contains(dev))
        #expect(store.undo?.text == "Dev's fee marked paid here. It's sent when you're back online.")
        let row = try #require(store.rows.first { $0.id == dev })
        #expect(row.line == "Paid by UPI on 7 Oct · Kept on this iPhone until you're online" && row.lineTone == .due)
        #expect(store.sheet == nil)
        #expect(await store.undoPaid(dev))
        #expect(waiting.pending.isEmpty && store.invoice(dev)?.status == .due && fees.undone.isEmpty)
        #expect(!store.keptHere.contains(dev))
    }

    @Test func aReadWhileTheChangeWaitsStillShowsItPaidHere() async {
        let waiting = queue()
        let store = await make(online: false, queue: waiting)
        _ = await store.markPaid(dev, method: .upi, on: store.today)
        await store.reload() // the server still says due: the change has not gone
        #expect(store.invoice(dev)?.status == .paid && store.keptHere.contains(dev))
    }

    @Test func onlineWithAMarkPaidWaitingTheNextJoinsTheQueue() async {
        let waiting = queue()
        let offline = await make(online: false, queue: waiting)
        _ = await offline.markPaid(dev, method: .upi, on: offline.today)
        let store = await make(online: true, queue: waiting)
        #expect(await store.markPaid(FakeFeesRepository.hemanthOctober, method: .cash, on: store.today))
        #expect(waiting.pending.waitingCount == 2 && fees.paid.isEmpty)
    }
}
