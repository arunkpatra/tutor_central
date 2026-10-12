import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct RegisterOfflineTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("register-\(UUID().uuidString)")

    func make(_ students: FakeStudentsRepository, at now: Date) -> RegisterStore {
        RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed),
            cache: .forCentre(FakeCentreRepository.meeraWorkspace.centre.id, directory: folder), now: { now }
        )
    }

    @Test func offlineTheSavedRegisterShowsWithItsTimeAndNoErrorLine() async {
        let saved = FakeCountsRepository.fixedNow
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        await make(students, at: saved).load()
        students.nextError = URLError(.notConnectedToInternet)
        let offline = make(students, at: saved.addingTimeInterval(3600))
        await offline.load()
        #expect(offline.activeStudents.count == 10 && offline.savedAt == saved && offline.offlineRead)
        #expect(offline.error == nil)
        await offline.refresh()
        #expect(offline.savedAt == saved.addingTimeInterval(3600) && !offline.offlineRead)
    }

    /// Hand run 14: a reload that fails offline after a good read keeps the read's time; the line never says nothing
    /// is saved over a list on screen.
    @Test func aFailedRefreshAfterAGoodReadKeepsTheReadsTime() async {
        let now = FakeCountsRepository.fixedNow
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = make(students, at: now)
        await store.load()
        students.nextError = URLError(.notConnectedToInternet)
        await store.refresh()
        #expect(store.savedAt == now && store.offlineRead && store.error == nil)
    }

    /// Phase 18's hand run 8: Today's plans and the note day wait for the register; with a saved copy it answers at
    /// once and the read runs on (offline it takes its timeout to fail).
    @Test func withASavedCopyLoadIfNeededAnswersBeforeTheRead() async {
        let now = FakeCountsRepository.fixedNow
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        await make(students, at: now).load()
        students.delay = .seconds(5)
        let store = make(students, at: now.addingTimeInterval(3600))
        let clock = ContinuousClock()
        let took = await clock.measure { await store.loadIfNeeded() }
        #expect(took < .seconds(1), "it waited for the read")
        #expect(store.activeStudents.count == 10 && store.savedAt == now)
    }
}
