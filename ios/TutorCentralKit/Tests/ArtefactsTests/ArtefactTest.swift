import Data
import Domain
import Foundation
import Students
@testable import Artefacts

/// What the artefacts' tests share: the boards' moment, the centre, the Evening batch's register and plan.
enum ArtefactTest {
    static let centre = FakeCentreRepository.meeraWorkspace.centre.id
    static let wednesday = Day(year: 2026, month: 10, day: 7)!
    static let at1640 = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 7,
        hour: 16,
        minute: 40
    ))!

    @MainActor static func register() async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.eveningSeed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { at1640 }
        )
        await register.load()
        return register
    }

    @MainActor static func plan(_ plans: FakePlansRepository) async throws -> PlanRecord? {
        try await plans.plan(centre: centre, classID: FakeClassesRepository.evening.id, date: wednesday)
    }
}
