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
        #expect(offline.savedAt == nil && !offline.offlineRead)
    }
}
