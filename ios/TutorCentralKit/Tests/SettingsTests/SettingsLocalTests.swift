import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct SettingsLocalTests {
    func make(defaults: UserDefaults, centres: FakeCentreRepository = FakeCentreRepository()) -> SettingsStore {
        centres.workspace = FakeCentreRepository.meeraWorkspace
        return SettingsStore(
            workspace: FakeCentreRepository.meeraWorkspace, centres: centres, version: "1.0 (14)", defaults: defaults,
            reminders: ReminderSummary(permission: .allowed, settings: ReminderSettings()), pendingCount: 0
        )
    }

    func suite() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "settings-\(UUID().uuidString)"))
    }

    @Test func appearanceAndHapticsWriteTheDefaultsAtOnce() throws {
        let defaults = try suite()
        let store = make(defaults: defaults)
        #expect(store.appearance == .dark && store.haptics == true)
        store.appearance = .light
        store.haptics = false
        #expect(defaults.string(forKey: AppearanceChoice.storageKey) == "light")
        #expect(defaults.object(forKey: Haptic.storageKey) as? Bool == false)
        let again = make(defaults: defaults)
        #expect(again.appearance == .light && again.haptics == false)
    }

    @Test func theRemindersRowSaysWhereTheyStand() {
        #expect(ReminderSummary(permission: .notAsked, settings: ReminderSettings()).value == "Not set up")
        #expect(ReminderSummary(permission: .refused, settings: ReminderSettings()).value == "Not allowed")
        #expect(ReminderSummary(permission: .allowed, settings: ReminderSettings()).value == "On")
        var off = ReminderSettings()
        off.classOn = false
        off.eventOn = false
        off.feesOn = false
        #expect(ReminderSummary(permission: .allowed, settings: off).value == "Off")
    }

    @Test func thePendingRowReadsNoneOrTheCount() {
        #expect(SettingsStore.pendingValue(0) == "None" && SettingsStore.pendingValue(2) == "2")
    }

    @Test func aFailedSaveNamesTheFieldAndKeepsWhatWasTyped() async throws {
        let centres = FakeCentreRepository()
        let store = try make(defaults: suite(), centres: centres)
        centres.nextError = URLError(.notConnectedToInternet)
        store.centreName = "Bright Minds Tuition Centre"
        await store.commitCentre()
        #expect(store.message == "Couldn't save the centre's name. Check your connection and try again.")
        #expect(store.centreName == "Bright Minds Tuition Centre" && store.saveState == .idle)
        centres.nextError = URLError(.notConnectedToInternet)
        store.displayName = "Meera N"
        await store.commitName()
        #expect(store.message == "Couldn't save your name. Check your connection and try again.")
        centres.nextError = URLError(.notConnectedToInternet)
        store.digits = "9611299900"
        await store.commitPhone()
        #expect(store.message == "Couldn't save your WhatsApp number. Check your connection and try again.")
    }
}
