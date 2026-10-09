import Data
import Domain
import Foundation
import Testing

@MainActor struct ChangeQueueTests {
    func dir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("queue-\(UUID().uuidString)", isDirectory: true)
    }

    func fee(_ name: String = "Dev Kumar") -> QueuedChange {
        QueuedChange(
            kind: .markPaid(
                invoiceID: UUID(), studentName: name, month: Period(year: 2026, month: 10),
                amount: Money(rupees: 1000), method: .upi, paidAt: Date()
            ),
            madeAt: Date()
        )
    }

    @Test func aQueueIsKeptPerCentreAndSurvivesARelaunch() {
        let folder = dir()
        let centre = UUID()
        let queue = ChangeQueue(centre: centre, directory: folder)
        let change = fee()
        queue.add(change)
        #expect(ChangeQueue(centre: centre, directory: folder).pending.changes == [change])
        #expect(ChangeQueue(centre: UUID(), directory: folder).pending.isEmpty)
    }

    @Test func failRetryAndRemoveAreKept() {
        let folder = dir()
        let centre = UUID()
        let queue = ChangeQueue(centre: centre, directory: folder)
        let change = fee()
        queue.add(change)
        queue.fail(id: change.id, reason: "No.")
        #expect(ChangeQueue(centre: centre, directory: folder).pending.failedCount == 1)
        queue.retryAll()
        #expect(ChangeQueue(centre: centre, directory: folder).pending.waitingCount == 1)
        queue.remove(id: change.id)
        #expect(ChangeQueue(centre: centre, directory: folder).pending.isEmpty)
    }

    @Test func wipeRemovesTheFile() throws {
        let folder = dir()
        let queue = ChangeQueue(centre: UUID(), directory: folder)
        queue.add(fee())
        queue.wipe()
        #expect(queue.pending.isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }
}
