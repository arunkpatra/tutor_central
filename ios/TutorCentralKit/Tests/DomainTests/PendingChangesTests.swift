import Domain
import Foundation
import Testing

struct PendingChangesTests {
    let calendar = DayHeading.india
    let maths = UUID()
    let dev = UUID()

    func day(_ number: Int) throws -> Day {
        try #require(Day(year: 2026, month: 10, day: number))
    }

    func at(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: hour, minute: minute)) ?? Date()
    }

    func attendance(_ number: Int, present: Int, at: Date) throws -> QueuedChange {
        try QueuedChange(
            kind: .attendance(
                classID: maths, className: "Class 10 Maths", date: day(number), marks: [:], present: present, total: 6
            ),
            madeAt: at
        )
    }

    func fee(at: Date) -> QueuedChange {
        QueuedChange(
            kind: .markPaid(
                invoiceID: dev, studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
                amount: Money(rupees: 1000), method: .upi, paidAt: at
            ),
            madeAt: at
        )
    }

    @Test func aSecondSaveOfTheSameClassAndDayReplacesTheFirst() throws {
        var pending = PendingChanges()
        try pending.add(attendance(7, present: 5, at: at(17, 5)))
        pending.add(fee(at: at(17, 12)))
        try pending.add(attendance(7, present: 6, at: at(17, 20)))
        #expect(pending.changes.count == 2)
        #expect(pending.inOrder.map(\.title) == ["Attendance · Class 10 Maths", "Fee · Dev Kumar"])
        #expect(pending.inOrder.first?.madeAt == at(17, 5)) // keeps its place in the order, carries the newer marks
        if case let .attendance(_, _, _, _, present, _) = pending.inOrder.first?.kind {
            #expect(present == 6)
        } else {
            Issue.record("not attendance")
        }
        try pending.add(attendance(8, present: 6, at: at(18, 0)))
        #expect(pending.changes.count == 3)
    }

    @Test func aSecondMarkPaidOfTheSameInvoiceReplacesTheFirst() {
        var pending = PendingChanges()
        pending.add(fee(at: at(17, 12)))
        pending.add(fee(at: at(17, 30)))
        #expect(pending.changes.count == 1 && pending.inOrder.first?.madeAt == at(17, 12))
    }

    @Test func failedChangesLeaveTheOrderAndComeBackOnRetry() throws {
        var pending = PendingChanges()
        let fee = fee(at: at(17, 12))
        try pending.add(attendance(7, present: 5, at: at(17, 5)))
        pending.add(fee)
        let reason = "Dev Kumar is no longer in the register, so his fee can't be marked. Keep it here or discard it."
        pending.fail(id: fee.id, reason: reason)
        #expect(pending.inOrder.count == 1 && pending.failedCount == 1 && pending.waitingCount == 1)
        pending.retryAll()
        #expect(pending.inOrder.count == 2 && pending.failedCount == 0)
        pending.remove(id: fee.id)
        #expect(pending.changes.count == 1 && pending.has(kind: .markPaid) == false && pending.has(kind: .attendance))
    }

    @Test func theLinesAndTheWarningReadAsTheBoardsDo() throws {
        var pending = PendingChanges()
        let saved = try attendance(7, present: 5, at: at(17, 5))
        pending.add(saved)
        pending.add(fee(at: at(17, 12)))
        #expect(saved.line(calendar: calendar) == "Wed 7 Oct · 5 of 6 present · 17:05")
        #expect(fee(at: at(17, 12)).line(calendar: calendar) == "₹1,000 by UPI on 7 Oct · 17:12")
        let alert = try QueuedChange(
            kind: .absenceLog(studentID: UUID(), studentName: "Hemanth Reddy", about: day(7)), madeAt: at(17, 6)
        )
        #expect(alert.title == "Absence alert · Hemanth Reddy")
        #expect(alert.line(calendar: calendar) == "Wed 7 Oct · WhatsApp opened at 17:06")
        #expect(alert.shortName == "Hemanth's absence alert")
        let warning = "2 saved changes haven't been sent yet: attendance for Class 10 Maths and Dev's fee."
        #expect(pending.signOutWarning == warning)
        #expect(PendingChanges().signOutWarning == nil)
        let one = PendingChanges(changes: [saved])
        #expect(one.signOutWarning == "1 saved change hasn't been sent yet: attendance for Class 10 Maths.")
        pending.add(alert)
        #expect(pending.signOutWarning?.hasSuffix("Class 10 Maths, Hemanth's absence alert and Dev's fee.") == true)
    }

    @Test func itRoundTripsAsJSON() throws {
        var pending = PendingChanges()
        try pending.add(attendance(7, present: 5, at: at(17, 5)))
        pending.add(fee(at: at(17, 12)))
        let data = try JSONEncoder().encode(pending)
        #expect(try JSONDecoder().decode(PendingChanges.self, from: data) == pending)
    }

    @Test func aSecondCloseOfTheSameBatchAndDayReplacesTheFirst() throws {
        var pending = PendingChanges()
        let batch = UUID(), day = try day(7)
        func close(_ present: Int) -> QueuedChange {
            QueuedChange(
                kind: .close(
                    close: SessionClose(
                        classID: batch,
                        date: day,
                        marks: [:],
                        checks: [],
                        homework: [],
                        track: [:]
                    ),
                    className: "Evening batch",
                    present: present,
                    total: 5
                ),
                madeAt: FakeClock.oct7at1635
            )
        }
        pending.add(close(5))
        pending.add(close(4))
        #expect(pending.changes.count == 1)
        if case let .close(_, _, present, _) = pending.changes[0].kind {
            #expect(present == 4)
        } else {
            Issue.record("not a close")
        }
        pending.add(QueuedChange(kind: .attendance(
            classID: batch,
            className: "Evening batch",
            date: day,
            marks: [:],
            present: 5,
            total: 5
        ), madeAt: FakeClock.oct7at1635))
        #expect(pending.changes.count == 2 && pending.has(kind: .close) && pending.has(kind: .attendance))
    }

    @Test func theCloseRowReadsAsTheBoardDoes() throws {
        let check = SessionClose.Check(
            studentID: dev,
            skillID: UUID(),
            question: "Q",
            correct: true,
            isPlacement: false
        )
        let checks = [check]
        let change = try QueuedChange(
            kind: .close(
                close: SessionClose(
                    classID: UUID(),
                    date: day(7),
                    marks: [:],
                    checks: checks,
                    homework: [],
                    track: [:]
                ),
                className: "Evening batch",
                present: 4,
                total: 5
            ),
            madeAt: FakeClock.oct7at1832
        )
        #expect(change.title == "Class closed · Evening batch")
        #expect(change.line(calendar: calendar) == "Wed 7 Oct · 4 of 5 came · 1 check · 18:32")
        #expect(change.shortName == "the close of Evening batch")
        let back = try JSONDecoder().decode(QueuedChange.self, from: JSONEncoder().encode(change))
        #expect(back == change)
    }

    @Test func aCloseWithNoChecksLeavesTheCountOut() throws {
        let close = try SessionClose(classID: UUID(), date: day(7), marks: [:], checks: [], homework: [], track: [:])
        let change = QueuedChange(
            kind: .close(close: close, className: "Class 8 Science", present: 2, total: 3),
            madeAt: FakeClock.oct7at1832
        )
        #expect(change.line(calendar: calendar) == "Wed 7 Oct · 2 of 3 came · 18:32")
    }
}
