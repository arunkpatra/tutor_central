import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct RemindersStoreTests {
    let calendar = DayHeading.india
    let centre = UUID()

    func at(day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? Date()
    }

    final class Calls {
        var allowed = 0
    }

    func make(
        _ center: FakeNotificationCenter, repository: FakeReminderSettingsRepository, calls: Calls = Calls()
    ) -> RemindersStore {
        let now = at(day: 7, hour: 16, minute: 35)
        return RemindersStore(
            notifications: center, repository: repository, centre: centre,
            classNames: { ["Class 10 Maths", "Class 8 Science"] }, now: { now }, calendar: calendar,
            onAllowed: { calls.allowed += 1 }
        )
    }

    @Test func beforeTheAskThereIsNoBannerAndTurnOnAsksOnceThenRegisters() async {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        let calls = Calls()
        let next = NextReminder(subject: "Class 10 Maths", at: at(day: 7, hour: 16, minute: 45))
        let store = make(center, repository: FakeReminderSettingsRepository(next: next), calls: calls)
        await store.load()
        #expect(store.permission == .notAsked && store.banner == nil)
        #expect(store.classesLine == "Class 10 Maths and Class 8 Science on their days")
        #expect(store.rowLines == ["1 hour before", "1 hour before", "On the 5th at 09:00"])
        await store.turnOn()
        #expect(center.asked == 1 && store.permission == .allowed && calls.allowed == 1)
        #expect(store.banner?.text == "Reminders are on. Next: Class 10 Maths, today at 16:45.")
    }

    @Test func refusedShowsOpenSettingsKeepsTheSwitchesAndRegistersNothing() async {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: false)
        let calls = Calls()
        let store = make(center, repository: FakeReminderSettingsRepository(), calls: calls)
        await store.load()
        await store.turnOn()
        #expect(store.permission == .refused && store.banner == .refused && store.settings.classOn)
        #expect(store.banner?.text == "Notifications are off for Tutor Central." && calls.allowed == 0)
    }

    @Test func theAccountsChoicesAreReadAndAChangeIsSavedWithIt() async throws {
        var off = ReminderSettings()
        off.classOn = false
        off.eventOn = false
        off.feesOn = false
        off.planReady = false
        off.notesReady = false
        let repository = FakeReminderSettingsRepository(kept: off)
        let store = make(FakeNotificationCenter(permission: .allowed), repository: repository)
        await store.load()
        #expect(store.banner == .allOff)
        #expect(await repository.saves.isEmpty)
        #expect(store.banner?.text == "Reminders are allowed, but every switch below is off.")
        store.settings.feesDay = 10
        try await Task.sleep(for: .milliseconds(20))
        #expect(await repository.saves.map(\.feesDay) == [10] && store.feesDayLabel == "10th")
    }

    /// The review's R-app-3: the lead scrolled 15 → 30 → 60 while the first save is slow; the account ends at 60, never
    /// at
    /// an earlier choice landing last.
    @Test func quickChangesSaveInOrderAndTheLastChoiceStays() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let repository = FakeReminderSettingsRepository()
        let store = make(center, repository: repository)
        await store.load()
        await repository.holdNextSave()
        store.settings.classMinutesBefore = 15
        while await !repository.isHolding {
            await Task.yield()
        }
        store.settings.classMinutesBefore = 30
        store.settings.classMinutesBefore = 60
        try await Task.sleep(for: .milliseconds(50))
        await repository.releaseSave()
        // Long enough for every save to land, in whatever order they run.
        try await Task.sleep(for: .milliseconds(200))
        #expect(await repository.kept?.classMinutesBefore == 60)
        #expect(await repository.saves.last?.classMinutesBefore == 60)
        #expect(store.settings.classMinutesBefore == 60)
    }

    @Test func aSaveThatFailsPutsTheChoiceBackAndSaysSo() async throws {
        let repository = FakeReminderSettingsRepository(failure: URLError(.notConnectedToInternet))
        let store = make(FakeNotificationCenter(permission: .allowed), repository: repository)
        await store.load()
        store.settings.classOn = false
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.settings.classOn && store.alert == "That didn't go through. Check your connection and try again.")
    }

    @Test func theNextReminderReadsTodayTomorrowOrItsDay() async {
        let cases: [(Date?, String)] = [
            (at(day: 8, hour: 9), "Reminders are on. Next: Fees still due, tomorrow at 09:00."),
            (at(day: 10, hour: 10), "Reminders are on. Next: Fees still due, Sat 10 Oct at 10:00."),
            (nil, "Reminders are on. Next: nothing in the next day."),
        ]
        for (date, text) in cases {
            let next = date.map { NextReminder(subject: "Fees still due", at: $0) }
            let store = make(FakeNotificationCenter(permission: .allowed), repository: .init(next: next))
            await store.load()
            #expect(store.banner?.text == text)
        }
    }

    @Test func dayNamesReadAsOrdinals() {
        #expect([1, 2, 3, 4, 11, 21, 22, 23, 28].map(RemindersStore.ordinal)
            == ["1st", "2nd", "3rd", "4th", "11th", "21st", "22nd", "23rd", "28th"])
    }
}
