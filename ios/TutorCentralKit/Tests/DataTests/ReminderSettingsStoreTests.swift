import Data
import Domain
import Foundation
import Testing

struct ReminderSettingsStoreTests {
    @Test func savesLoadsAndRemembersTheAsk() throws {
        let defaults = try #require(UserDefaults(suiteName: "reminder-settings-\(UUID().uuidString)"))
        let store = ReminderSettingsStore(defaults: defaults)
        #expect(store.load() == ReminderSettings() && !store.asked)
        var changed = ReminderSettings()
        changed.feesDay = 10
        changed.classOn = false
        store.save(changed)
        store.asked = true
        let again = ReminderSettingsStore(defaults: defaults)
        #expect(again.load() == changed && again.asked)
    }

    @Test func unreadableSettingsAreTheDefaults() throws {
        let defaults = try #require(UserDefaults(suiteName: "reminder-settings-\(UUID().uuidString)"))
        defaults.set(Data("nope".utf8), forKey: ReminderSettingsStore.key)
        #expect(ReminderSettingsStore(defaults: defaults).load() == ReminderSettings())
    }
}
