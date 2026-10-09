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

    /// Review I1: a change added (online behind a waiting one, or a correction) tells the shell, which starts a run.
    @Test func addingAChangeTellsTheShell() {
        let queue = ChangeQueue(centre: UUID(), directory: dir())
        var told = 0
        queue.onAdded = { told += 1 }
        queue.add(fee())
        queue.remove(id: queue.pending.changes[0].id)
        #expect(told == 1)
    }

    /// Review minor 11: a file that cannot be read is kept aside, not overwritten by the next change.
    @Test func anUnreadableFileIsKeptAside() throws {
        let folder = dir()
        let centre = UUID()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("queue-\(centre.uuidString.lowercased()).json")
        try Data("not a queue".utf8).write(to: file)
        let queue = ChangeQueue(centre: centre, directory: folder)
        queue.add(fee())
        let aside = folder.appendingPathComponent("queue-\(centre.uuidString.lowercased()).unreadable.json")
        #expect(try String(contentsOf: aside, encoding: .utf8) == "not a queue")
    }
}
