import Data
import Domain
import Foundation
import Testing

@MainActor struct QueueRunnerTests {
    let attendance = FakeAttendanceRepository()
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let messages = FakeMessageLogRepository()
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    func make(_ changes: [QueuedChange]) -> (ChangeQueue, QueueRunner) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let queue = ChangeQueue(centre: centre, directory: folder)
        for change in changes {
            queue.add(change)
        }
        return (
            queue,
            QueueRunner(queue: queue, centre: centre, attendance: attendance, fees: fees, messages: messages)
        )
    }

    func save(at: Date, classID: UUID? = nil, className: String = "All students") throws -> QueuedChange {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        return QueuedChange(
            kind: .attendance(
                classID: classID, className: className, date: day, marks: [:], present: 6, total: 6
            ),
            madeAt: at
        )
    }

    func paid(_ id: UUID, at: Date) -> QueuedChange {
        QueuedChange(
            kind: .markPaid(
                invoiceID: id, studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
                amount: Money(rupees: 1000), method: .upi, paidAt: at
            ),
            madeAt: at
        )
    }

    func alert(at: Date) throws -> QueuedChange {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        return QueuedChange(
            kind: .absenceLog(studentID: FakeAttendanceRepository.hemanth, studentName: "Hemanth Reddy", about: day),
            madeAt: at
        )
    }

    @Test func changesAreSentInTheOrderMadeAndLeaveTheQueue() async throws {
        let invoice = try #require(fees.invoices.first { $0.status == .due }?.id)
        let (queue, runner) = try make([
            alert(at: Date(timeIntervalSince1970: 3)), save(at: Date(timeIntervalSince1970: 1)),
            paid(invoice, at: Date(timeIntervalSince1970: 2)),
        ])
        #expect(await runner.run() == .done(sent: 3, failed: 0))
        #expect(queue.pending.isEmpty && attendance.saves.count == 1 && fees.paid == [invoice])
        #expect(messages.logged == [FakeAttendanceRepository.hemanth])
    }

    @Test func anOfflineErrorStopsTheRunAndKeepsTheChange() async throws {
        let invoice = try #require(fees.invoices.first { $0.status == .due }?.id)
        let (queue, runner) = try make([
            save(at: Date(timeIntervalSince1970: 1)), paid(invoice, at: Date(timeIntervalSince1970: 2)),
        ])
        attendance.nextError = URLError(.notConnectedToInternet)
        #expect(await runner.run() == .offline(sent: 0))
        #expect(queue.pending.waitingCount == 2 && fees.paid.isEmpty)
    }

    @Test func aRefusedRowIsFailedAndTheRestStillGo() async throws {
        let (queue, runner) = try make([
            paid(UUID(), at: Date(timeIntervalSince1970: 1)), save(at: Date(timeIntervalSince1970: 2)),
        ])
        // The fake answers "no such invoice" for an unknown id, as PostgREST's single() does.
        #expect(await runner.run() == .done(sent: 1, failed: 1))
        #expect(queue.pending.failedCount == 1 && queue.pending.waitingCount == 0 && attendance.saves.count == 1)
        let failed = try #require(queue.pending.changes.first { $0.state != .waiting })
        let reason = "Dev Kumar is no longer in the register, so their fee can't be marked. Keep it here or discard it."
        #expect(failed.state == .failed(reason: reason))
    }

    @Test func aSignedOutErrorKeepsTheChangeAndSaysSo() async throws {
        let (queue, runner) = try make([save(at: Date())])
        attendance.nextError = FakeAttendanceRepository.signedOutError
        #expect(await runner.run() == .signedOut(sent: 0))
        #expect(queue.pending.waitingCount == 1)
    }

    @Test func aSecondRunWhileOneRunsIsRefused() async throws {
        let (_, runner) = try make([save(at: Date())])
        attendance.delay = .milliseconds(100)
        let first = Task { await runner.run() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(runner.running)
        #expect(await runner.run() == nil)
        #expect(await first.value == .done(sent: 1, failed: 0))
        #expect(!runner.running)
    }

    @Test func theReasonsNameWhatIsGone() throws {
        let gone = FakeFeesRepository.noSuchRow
        let maths = try save(at: Date(), classID: UUID(), className: "Class 10 Maths")
        let keep = "Keep it here or discard it."
        #expect(QueueRunner.reason(for: maths, error: gone)
            == "Class 10 Maths is no longer here, so this attendance can't be saved. \(keep)")
        #expect(try QueueRunner.reason(for: alert(at: Date()), error: gone)
            == "Hemanth Reddy is no longer in the register, so the absence alert can't be noted. \(keep)")
        struct Odd: Error {}
        #expect(try QueueRunner.reason(for: save(at: Date()), error: Odd())
            == "This change couldn't be saved. Keep it here or discard it.")
    }
}
