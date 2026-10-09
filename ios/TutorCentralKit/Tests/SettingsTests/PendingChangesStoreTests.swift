import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct PendingChangesStoreTests {
    let reason = "Dev Kumar is no longer in the register, so their fee can't be marked. Keep it here or discard it."

    func make() throws -> (ChangeQueue, PendingChangesStore) {
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let queue = ChangeQueue(
            centre: centre, directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
        let runner = QueueRunner(
            queue: queue, centre: centre, attendance: FakeAttendanceRepository(), fees: FakeFeesRepository(),
            messages: FakeMessageLogRepository()
        )
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let at = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 17, minute: 5))
            ?? Date()
        queue.add(QueuedChange(
            kind: .attendance(
                classID: UUID(),
                className: "Class 10 Maths",
                date: day,
                marks: [:],
                present: 5,
                total: 6
            ),
            madeAt: at
        ))
        let gone = QueuedChange(
            kind: .markPaid(
                invoiceID: UUID(), studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
                amount: Money(rupees: 1000), method: .upi, paidAt: at
            ),
            madeAt: at.addingTimeInterval(420)
        )
        queue.add(gone)
        queue.fail(id: gone.id, reason: reason)
        return (queue, PendingChangesStore(queue: queue, calendar: DayHeading.india) { await runner.run() })
    }

    @Test func rowsShowEveryChangeWithItsStateAndDiscardRemovesOne() throws {
        let (queue, store) = try make()
        #expect(store.rows.map(\.title) == ["Attendance · Class 10 Maths", "Fee · Dev Kumar"])
        #expect(store.rows.map(\.state) == [.waiting, .failed(reason: reason)])
        let fee = try #require(store.rows.last?.id)
        #expect(store.discardWords(for: fee)
            == "Dev's October fee stays as it was: due. The mark you made here is lost.")
        let attendance = try #require(store.rows.first?.id)
        #expect(store.discardWords(for: attendance)
            == "Attendance for Class 10 Maths on Wed 7 Oct stays as it was. What you marked here is lost.")
        store.discard(id: fee)
        #expect(queue.pending.failedCount == 0 && store.rows.count == 1)
    }

    @Test func sendAgainRetriesTheFailedOnes() async throws {
        let (queue, store) = try make()
        let outcome = await store.sendAgain()
        // The invoice is unknown to the fake, so it is refused again and stays failed; the attendance goes.
        #expect(outcome == .done(sent: 1, failed: 1) && queue.pending.failedCount == 1 && queue.pending
            .waitingCount == 0)
        #expect(store.canSend && !store.sending)
    }
}
