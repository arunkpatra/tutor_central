import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct ReportsStoreTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)

    func make() async -> ReportsStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = ReportsStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees, attendance: attendance,
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func octobersFeesReadAsTheBoard() async {
        let store = await make()
        #expect(store.month == Period(year: 2026, month: 10) && store.segment == .fees && !store.isEmpty && store
            .studentsTitle == "10 students")
        #expect(store.totals.outstanding == Money(rupees: 4000) && store.feesLines
            .outstandingLine == "4 of 10 due" && store.feesLines.collectedLine == "6 of 10 paid")
        #expect(
            store.feeLines.map(\.name) == FakeStudentsRepository.seed.map(\.name),
            "by name, every student with a fee"
        )
        #expect(store.feeLines[3].className == "Class 8 Science" && store.feeLines[3].state == .due && store.feeLines[9]
            .className == "")
    }

    @Test func octobersAttendanceCountsMarksByStudent() async throws {
        let store = await make()
        store.segment = .attendance
        let hemanth = try #require(store.attendanceLines.first { $0.name == "Hemanth Reddy" })
        #expect(hemanth.present == 1 && hemanth.absent == 2 && hemanth.percent == "33%")
        let sahil = try #require(store.attendanceLines.first { $0.name == "Sahil Verma" })
        #expect(sahil.present == nil && sahil.percent == nil, "no class, nothing marked")
        let hero = try #require(store.attendanceHero)
        let sessions = FakeAttendanceRepository.seedWithToday.filter { $0.date.period == store.month }
        let marks = sessions.flatMap(\.marks.values)
        let present = marks.filter { $0 == .present }.count
        #expect(hero.line == "\(present) of \(marks.count) marks · \(sessions.count) classes marked")
        #expect(hero.percent == "\(Int((Double(present) * 100 / Double(marks.count)).rounded()))%")
    }

    @Test func theExportsHaveTheBoardsColumns() async throws {
        let store = await make()
        let fees = store.export(.fees)
        #expect(fees.fileName == "fees-2026-10.csv" && fees.text
            .hasPrefix("\u{FEFF}Student,Class,Amount,Status,Paid on,Paid by,Reminded on\r\n"))
        #expect(fees.text.contains("Dev Kumar,Class 8 Science,1000,Due,,,2026-10-06\r\n") && fees.text
            .contains("Akshita Rao,Class 10 Maths,1200,Paid,2026-10-04,UPI,\r\n"))
        let attendance = store.export(.attendance)
        #expect(attendance.fileName == "attendance-2026-10.csv" && attendance.text
            .contains("Hemanth Reddy,Class 10 Maths,1,2,33\r\n") && attendance.text.contains("Sahil Verma,,0,0,\r\n"))
        let url = try #require(store.exportFile(.fees))
        let written = try Data(contentsOf: url)
        #expect(url.lastPathComponent == "fees-2026-10.csv" && written == Data(fees.text.utf8))
        #expect(written.prefix(3) == Data([0xEF, 0xBB, 0xBF]), "the BOM reaches the file, so Numbers reads ₹ and names")
    }

    @Test func aMonthWithNothingIsEmptyAndAFailedReadIsNot() async {
        let store = await make()
        await store.next()
        #expect(store.month == Period(year: 2026, month: 11) && store.isEmpty && store.feeLines.isEmpty && store
            .attendanceHero == nil)
        fees.nextError = URLError(.notConnectedToInternet)
        await store.previous()
        #expect(store.error == "Couldn't load the report. Check your connection and try again." && !store.isEmpty)
        await store.retryLast()
        #expect(store.error == nil && store.feeLines.count == 10)
    }
}
