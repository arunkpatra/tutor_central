import Data
import Domain
import Foundation
import Testing
import Today
@testable import AppShell

/// The background refresh makes today's plans as the user (D60).
@MainActor struct RefreshHandlerTests {
    static func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func handler(signedIn: Bool, plans: FakePlansRepository, now: Date) -> RefreshHandler {
        RefreshHandler(
            workspace: { signedIn ? FakeCentreRepository.meeraWorkspace : nil },
            classes: FakeClassesRepository(classes: [FakeClassesRepository.evening]),
            students: FakeStudentsRepository(students: FakeStudentsRepository.eveningSeed), plans: plans,
            maker: { _ in
                PlanMaker(
                    plans: plans, textbooks: FakeTextbooksRepository.evening(),
                    attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
                    ai: FakeAIRepository(), cache: nil, now: { now }, calendar: DayHeading.india
                )
            },
            now: { now }, calendar: DayHeading.india
        )
    }

    @Test func theRefreshMakesTodaysPlansForTheSignedInCentre() async throws {
        let plans = FakePlansRepository()
        await handler(signedIn: true, plans: plans, now: Self.at(7, 6, 0)).run()
        let made = try await plans.plan(
            centre: FakeCentreRepository.meeraWorkspace.centre.id, classID: FakeClassesRepository.evening.id,
            date: #require(Day(year: 2026, month: 10, day: 7))
        )
        #expect(made?.groups.count == 3)
        #expect(made?.artefacts.isEmpty == false)
    }

    @Test func theRefreshDoesNothingSignedOutOrOnADayWithNoBatch() async {
        let plans = FakePlansRepository()
        await handler(signedIn: false, plans: plans, now: Self.at(7, 6, 0)).run()
        await handler(signedIn: true, plans: plans, now: Self.at(10, 6, 0)).run()
        #expect(plans.made.isEmpty)
    }

    @Test func theNextRefreshIsAskedForSixTomorrow() {
        #expect(BackgroundRefresh.nextMorning(after: Self.at(7, 16, 35), calendar: DayHeading.india) == Self.at(
            8,
            6,
            0
        ))
    }
}
