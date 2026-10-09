import Data
import Domain
import Foundation
import Students
import Testing
@testable import AppShell

@MainActor struct ReminderSchedulerTests {
    func make(
        _ center: FakeNotificationCenter,
        now: Date,
        settings: ReminderSettingsStore? = nil
    ) throws -> ReminderScheduler {
        let defaults = try #require(UserDefaults(suiteName: "sched-\(UUID().uuidString)"))
        let workspace = FakeCentreRepository.meeraWorkspace
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        return ReminderScheduler(
            notifications: center, settingsStore: settings ?? ReminderSettingsStore(defaults: defaults),
            register: register, events: FakeEventsRepository(events: FakeEventsRepository.seed),
            fees: FakeFeesRepository(invoices: FakeFeesRepository.seed), now: { now }, calendar: DayHeading.india
        )
    }

    @Test func replanReadsTheRegisterTheEventsAndTheDueFeesAndReplacesWhenAllowed() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 9)) ?? Date()
        let scheduler = try make(center, now: now)
        let plan = await scheduler.replan(workspace: FakeCentreRepository.meeraWorkspace)
        let pending = await center.pending()
        #expect(!plan.isEmpty && center.replacements == 1 && pending == plan)
        #expect(plan.contains { $0.kind == .classMeeting } && plan.contains { $0.kind == .fees })
        #expect(plan.contains { $0.kind == .event })
    }

    @Test func nothingIsScheduledWithoutThePermission() async throws {
        let center = FakeNotificationCenter(permission: .notAsked)
        let scheduler = try make(center, now: Date())
        _ = await scheduler.replan(workspace: FakeCentreRepository.meeraWorkspace)
        #expect(center.replacements == 0)
    }

    /// A switch turned off while a run sets its plan is planned by the call it made, not answered with the older plan.
    @Test func aCallMadeDuringARunPlansAgainAfterIt() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 9)) ?? Date()
        let settings = try ReminderSettingsStore(defaults: #require(UserDefaults(suiteName: "sched-\(UUID())")))
        center.delay = .milliseconds(100)
        let scheduler = try make(center, now: now, settings: settings)
        let first = Task { await scheduler.replan(workspace: FakeCentreRepository.meeraWorkspace) }
        try await Task.sleep(for: .milliseconds(20))
        var off = settings.load()
        off.classOn = false
        settings.save(off)
        let second = await scheduler.replan(workspace: FakeCentreRepository.meeraWorkspace)
        #expect(await first.value.contains { $0.kind == .classMeeting })
        #expect(!second.contains { $0.kind == .classMeeting } && !second.isEmpty)
        #expect(await center.pending() == second)
    }
}
