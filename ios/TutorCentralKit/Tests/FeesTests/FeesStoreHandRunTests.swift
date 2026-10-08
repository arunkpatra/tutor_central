import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

/// What the D32 hand run and the final review found, pinned.
@MainActor struct FeesStoreHandRunTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let hemanth = FakeFeesRepository.hemanthOctober

    func make() async -> FeesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees,
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed),
            centres: FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func undoClosesThatFeesReceipt() async {
        let store = await make()
        _ = await store.markPaid(hemanth, method: .cash, on: store.today)
        #expect(store.sheet == .receipt(hemanth))
        #expect(await store.undoPaid(hemanth))
        #expect(store.sheet == nil, "the receipt of a fee no longer paid stayed open, empty")
    }

    @Test func todaysDueTileOpensThisMonthAtDue() async {
        let store = await make()
        await store.open(month: Period(year: 2026, month: 9))
        await store.showDue()
        #expect(store.month == Period(year: 2026, month: 10) && store.filter == .due, "a link had left September open")
    }

    @Test func undoAfterPayingAWaivedFeeWaivesItAgain() async {
        let store = await make()
        let sahil = FakeFeesRepository.sahilOctober
        #expect(await store.waive(sahil, reason: "Joined mid-month"))
        _ = await store.markPaid(sahil, method: .cash, on: store.today)
        #expect(await store.undoPaid(sahil))
        let fee = store.invoices.first { $0.id == sahil }
        #expect(fee?.status == .waived && fee?.waivedReason == "Joined mid-month" && fee?.paidAt == nil)
        #expect(store.totals.outstanding == Money(rupees: 3200), "a waived fee is not outstanding again")
    }
}
