import Data
import DesignSystem
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct StudentFeesStoreTests {
    func make(_ id: UUID = FakeAttendanceRepository.hemanth) async -> StudentFeesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = StudentFeesStore(
            studentID: id, workspace: FakeCentreRepository.meeraWorkspace, register: register,
            fees: FakeFeesRepository(invoices: FakeFeesRepository.seed),
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func hemanthsMonthsReadAsTheBoard() async {
        let store = await make()
        #expect(store.title == "Hemanth's fees" && store.sectionTitle == "4 months")
        #expect(store.totals.outstanding == Money(rupees: 1200) && store.outstandingLine == "October")
        #expect(store.totals.collected == Money(rupees: 2400) && store.collectedLine == "2 of 4 months")
        #expect(store.rows.map(\.title) == ["October 2026", "September 2026", "August 2026", "July 2026"])
        #expect(store.rows[0].state == .due && store.rows[0].line == "Lakshmi Reddy · +91 93802 60871")
        #expect(store.rows[0].showsButtons && store.rows[0].showsRemind)
        #expect(store.rows[1].line == "Paid by UPI on 3 Sep" && store.rows[2].line == "Paid by cash on 5 Aug")
        #expect(store.rows[3].line == "Waived · Joined mid-month")
        #expect(!store.rows[1].showsButtons && !store.rows[2].showsButtons)
        #expect(store.rows[3].showsButtons && !store.rows[3].showsRemind, "a waived month: Mark paid only (the owner)")
        #expect(store.footnote
            == "Months before Hemanth joined have no fee. A month's fee is made when you generate that month.")
    }

    @Test func devReadsRemindedAndNikhilOverdue() async {
        let dev = await make(FakeStudentsRepository.id(4))
        #expect(dev.rows[0].line == "Reminded Tue 6 Oct" && dev.rows[0].lineTone == .ok)
        #expect(dev.rows[0].lineSymbol == "checkmark")
        let nikhil = await make(FakeStudentsRepository.id(8))
        #expect(nikhil.rows.map(\.state) == [.due, .overdue] && nikhil.outstandingLine == "October and September")
        #expect(nikhil.collectedLine == "0 of 2 months" && nikhil.rows[1].line == "Reminded Wed 30 Sep")
    }

    @Test func threeDueMonthsNameTwoAndBefore() {
        let months = [10, 9, 8].map { Period(year: 2026, month: $0) }
        #expect(StudentFeesStore.dueLine(months) == "October, September and before")
        #expect(StudentFeesStore.dueLine([]) == "Nothing due" && StudentFeesStore.dueLine([months[0]]) == "October")
    }
}
