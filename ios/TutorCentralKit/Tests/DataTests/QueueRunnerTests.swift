import Domain
import Foundation
import Supabase
import Testing
@testable import Data

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

    /// Review C1: a save corrected while its first version is being sent is sent too, not removed with the first.
    @Test func aChangeReplacedDuringItsSendIsSentAfterIt() async throws {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        let first = QueuedChange(
            kind: .attendance(classID: nil, className: "All students", date: day, marks: [:], present: 6, total: 6),
            madeAt: Date(timeIntervalSince1970: 1)
        )
        let (queue, runner) = make([first])
        attendance.delay = .milliseconds(100)
        let run = Task { await runner.run() }
        try await Task.sleep(for: .milliseconds(20))
        let absent = [FakeAttendanceRepository.hemanth: AttendanceStatus.absent]
        queue.add(QueuedChange(
            kind: .attendance(classID: nil, className: "All students", date: day, marks: absent, present: 5, total: 6),
            madeAt: Date(timeIntervalSince1970: 2)
        ))
        _ = await run.value
        #expect(attendance.saves.map(\.marks) == [[:], absent])
        #expect(queue.pending.isEmpty)
    }

    /// Review C1: a change undone or discarded while the run sends an earlier one is never sent.
    @Test func aChangeRemovedDuringARunIsNotSent() async throws {
        let invoice = try #require(fees.invoices.first { $0.status == .due }?.id)
        let later = paid(invoice, at: Date(timeIntervalSince1970: 2))
        let (queue, runner) = try make([save(at: Date(timeIntervalSince1970: 1)), later])
        attendance.delay = .milliseconds(100)
        let run = Task { await runner.run() }
        try await Task.sleep(for: .milliseconds(20))
        queue.remove(id: later.id)
        _ = await run.value
        #expect(fees.paid.isEmpty && attendance.saves.count == 1)
    }

    /// Review I1: a change added while a run sends the last one goes in the same run.
    @Test func aChangeAddedDuringARunGoesInTheSameRun() async throws {
        let invoice = try #require(fees.invoices.first { $0.status == .due }?.id)
        let (queue, runner) = try make([save(at: Date(timeIntervalSince1970: 1))])
        attendance.delay = .milliseconds(100)
        let run = Task { await runner.run() }
        try await Task.sleep(for: .milliseconds(20))
        queue.add(paid(invoice, at: Date(timeIntervalSince1970: 2)))
        #expect(await run.value == .done(sent: 2, failed: 0))
        #expect(fees.paid == [invoice] && queue.pending.isEmpty)
    }

    /// Review I2: an outage (a gateway's 5xx, any transport error, a cancelled request) waits; only the database
    /// refusing the row fails it.
    @Test func anOutageWaitsAndOnlyARefusedRowFails() {
        #expect(QueueRunner.classify(URLError(.badServerResponse)) == .offline)
        #expect(QueueRunner.classify(URLError(.secureConnectionFailed)) == .offline)
        #expect(QueueRunner.classify(CancellationError()) == .offline)
        #expect(QueueRunner.classify(PostgrestError(message: "Bad gateway")) == .offline)
        #expect(QueueRunner.classify(FakeFeesRepository.noSuchRow) == .refused)
        #expect(QueueRunner.classify(PostgrestError(code: "42501", message: "denied")) == .refused)
    }

    @Test func aQueuedCloseIsSentAsOne() async throws {
        let close = try SessionClose(
            classID: FakeClassesRepository.maths.id, date: #require(Day(year: 2026, month: 10, day: 7)),
            marks: [FakeStudentsRepository.akshita: .absent], checks: [], homework: [], track: [:]
        )
        let change = QueuedChange(
            kind: .close(close: close, className: "Class 10 Maths", present: 0, total: 1), madeAt: Date()
        )
        let (queue, runner) = make([change])
        #expect(await runner.run() == .done(sent: 1, failed: 0))
        #expect(attendance.closes == [close] && queue.pending.isEmpty)
    }

    @Test func aGoneBatchFailsTheCloseInWords() throws {
        let close = try SessionClose(
            classID: UUID(),
            date: #require(Day(year: 2026, month: 10, day: 7)),
            marks: [:],
            checks: [],
            homework: [],
            track: [:]
        )
        let change = QueuedChange(
            kind: .close(close: close, className: "Evening batch", present: 0, total: 0),
            madeAt: Date()
        )
        #expect(QueueRunner.reason(for: change, error: PostgrestError(code: "23503", message: "attendance_sessions"))
            == "Evening batch is no longer here, so this close can't be saved. Keep it here or discard it.")
        let studentGone = "A student marked here is no longer in the register, so this close can't be saved."
        #expect(QueueRunner.reason(for: change, error: PostgrestError(code: "23503", message: "checks"))
            == "\(studentGone) Keep it here or discard it.")
    }
}
