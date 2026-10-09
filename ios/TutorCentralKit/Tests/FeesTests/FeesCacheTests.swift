import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct FeesCacheTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("fees-\(UUID().uuidString)")
    let centre = FakeCentreRepository.meeraWorkspace.centre.id
    let october = Period(year: 2026, month: 10)

    func make(_ fees: FakeFeesRepository) -> FeesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let folder = folder
        let centre = centre
        let store = FeesStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, fees: fees,
            messages: FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed),
            centres: FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace),
            now: { FakeCountsRepository.fixedNow }
        )
        store.cache = { CachedRead(centre: centre, key: "fees-\($0.isoMonth)", directory: folder) }
        return store
    }

    @Test func aReadMonthIsKeptAndAnOfflineOpenShowsItWithItsTime() async {
        let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        await make(fees).load()
        let kept = CachedRead<FeesSnapshot>(centre: centre, key: "fees-2026-10", directory: folder).load()
        #expect(kept?.value.invoices.count == 10)
        fees.nextError = URLError(.notConnectedToInternet)
        let offline = make(fees)
        await offline.load()
        #expect(offline.invoices.count == 10 && offline.savedAt != nil && offline.offlineRead && offline.error == nil)
        #expect(offline.loaded && !offline.showsNothingSaved)
    }

    @Test func offlineWithNothingSavedShowsTheEmptyCardAndAFreshReadClearsIt() async {
        let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        fees.nextError = URLError(.notConnectedToInternet)
        let store = make(fees)
        await store.load()
        #expect(store.invoices.isEmpty && store.savedAt == nil && store.offlineRead && store.showsNothingSaved)
        await store.reload()
        #expect(store.invoices.count == 10 && !store.offlineRead && !store.showsNothingSaved && store.savedAt == nil)
    }
}
