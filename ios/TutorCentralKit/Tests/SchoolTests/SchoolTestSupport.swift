import Data
import Domain
import Foundation
import Students

/// The School tests' world: the fixtures' register (the Evening batch), Vidya Niketan, Wednesday 7 October 16:35.
enum SchoolFixtures {
    static let centre = FakeSchoolsRepository.centre
    static let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35))!
    static let boardItems = FakeSchoolItemsRepository.boardItems
    static let boardMessage = FakeSchoolItemsRepository.boardMessage

    @MainActor static func register() async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.eveningSeed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.load()
        return register
    }

    static var tmp: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("school-\(UUID().uuidString)")
    }
}
