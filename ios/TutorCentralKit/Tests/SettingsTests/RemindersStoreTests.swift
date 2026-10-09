import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct RemindersStoreTests {
    let calendar = DayHeading.india
    var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()
    }

    var next: Reminder {
        Reminder(
            id: "class-x-2026-10-07", kind: .classMeeting, title: "Class 10 Maths at 17:00", body: "b",
            fireAt: calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 45)) ?? Date(),
            link: "tutorcentral://attendance", subject: "Class 10 Maths"
        )
    }

    func make(
        _ center: FakeNotificationCenter, settings: ReminderSettings = ReminderSettings(), plan: [Reminder] = [],
        defaults: UserDefaults? = nil
    ) throws -> RemindersStore {
        let defaults = try defaults ?? #require(UserDefaults(suiteName: "reminders-\(UUID().uuidString)"))
        let store = ReminderSettingsStore(defaults: defaults)
        store.save(settings)
        let now = now
        return RemindersStore(
            notifications: center, settingsStore: store, classNames: { ["Class 10 Maths", "Class 8 Science"] },
            now: { now }, calendar: calendar,
            replan: {
                await center.replace(with: plan)
                return plan
            }
        )
    }

    @Test func beforeTheAskThereIsNoBannerAndTurnOnAsksOnce() async throws {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        let store = try make(center, plan: [next])
        await store.load()
        #expect(store.permission == .notAsked && store.banner == nil)
        #expect(store.classesLine == "Class 10 Maths and Class 8 Science on their days")
        #expect(store.rowLines == ["15 min before", "1 hour before", "On the 5th at 09:00"])
        await store.turnOn()
        #expect(center.asked == 1 && store.permission == .allowed && center.replacements == 1)
        #expect(store.banner == .on(next: "Class 10 Maths, today at 16:45"))
        #expect(store.banner?.text == "Reminders are on. Next: Class 10 Maths, today at 16:45.")
    }

    @Test func refusedShowsOpenSettingsAndKeepsTheSwitches() async throws {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: false)
        let store = try make(center)
        await store.load()
        await store.turnOn()
        #expect(store.permission == .refused && store.banner == .refused && store.settings.classOn)
        #expect(store.banner?.text == "Notifications are off for Tutor Central.")
        #expect(store.onThisPhone.count == "Nothing set")
    }

    @Test func allOffSaysSoAndAChangeIsSavedAndReplanned() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        var off = ReminderSettings()
        off.classOn = false
        off.eventOn = false
        off.feesOn = false
        let defaults = try #require(UserDefaults(suiteName: "reminders-\(UUID().uuidString)"))
        let store = try make(center, settings: off, defaults: defaults)
        await store.load()
        #expect(store.banner == .allOff && store.onThisPhone.count == "No reminders set")
        #expect(store.banner?.text == "Reminders are allowed, but every switch below is off.")
        let before = center.replacements
        store.settings.feesDay = 10
        try await Task.sleep(for: .milliseconds(20))
        #expect(center.replacements == before + 1 && store.feesDayLabel == "10th")
        #expect(ReminderSettingsStore(defaults: defaults).load().feesDay == 10)
    }

    @Test func theCountAndTheLastDayReadAsTheBoard() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let later = Reminder(
            id: "fees-2026-10", kind: .fees, title: "t", body: "b",
            fireAt: calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 9)) ?? Date(), link: "l"
        )
        let store = try make(center, plan: [next, later])
        await store.load()
        #expect(store.onThisPhone.count == "2 reminders set" && store.onThisPhone.through == "through Fri 23 Oct")
    }

    @Test func dayNamesReadAsOrdinals() {
        #expect([1, 2, 3, 4, 11, 21, 22, 23, 28].map(RemindersStore.ordinal)
            == ["1st", "2nd", "3rd", "4th", "11th", "21st", "22nd", "23rd", "28th"])
    }
}
