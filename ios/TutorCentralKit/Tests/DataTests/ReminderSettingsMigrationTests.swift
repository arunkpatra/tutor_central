import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct ReminderSettingsMigrationTests {
    let centre = UUID()

    func defaults(with settings: ReminderSettings?) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: "migration-\(UUID().uuidString)"))
        if let settings {
            try defaults.set(JSONEncoder().encode(settings), forKey: ReminderSettingsMigration.key)
            defaults.set(true, forKey: ReminderSettingsMigration.askedKey)
        }
        return defaults
    }

    @Test func thePhonesChoicesGoToTheAccountThenTheKeysAndThePendingRemindersGo() async throws {
        var old = ReminderSettings()
        old.feesDay = 10
        old.classOn = false
        let defaults = try defaults(with: old)
        let repository = FakeReminderSettingsRepository()
        let center = FakeNotificationCenter(permission: .allowed)
        await ReminderSettingsMigration.run(
            defaults: defaults, repository: repository, notifications: center, centre: centre
        )
        #expect(await repository.saves == [old])
        #expect(defaults.data(forKey: ReminderSettingsMigration.key) == nil)
        #expect(defaults.object(forKey: ReminderSettingsMigration.askedKey) == nil)
        #expect(center.pendingRemoved == 1)
    }

    @Test func aFailedSaveKeepsTheKeyForTheNextLaunch() async throws {
        let defaults = try defaults(with: ReminderSettings())
        let center = FakeNotificationCenter(permission: .allowed)
        await ReminderSettingsMigration.run(
            defaults: defaults, repository: FakeReminderSettingsRepository(failure: URLError(.timedOut)),
            notifications: center, centre: centre
        )
        #expect(defaults.data(forKey: ReminderSettingsMigration.key) != nil && center.pendingRemoved == 0)
    }

    @Test func nothingKeptRunsNothingAndUnreadableChoicesStillGo() async throws {
        let center = FakeNotificationCenter(permission: .allowed)
        let repository = FakeReminderSettingsRepository()
        try await ReminderSettingsMigration.run(
            defaults: defaults(with: nil), repository: repository, notifications: center, centre: centre
        )
        #expect(center.pendingRemoved == 0)
        let broken = try defaults(with: nil)
        broken.set(Data("x".utf8), forKey: ReminderSettingsMigration.key)
        await ReminderSettingsMigration.run(
            defaults: broken, repository: repository, notifications: center, centre: centre
        )
        #expect(await repository.saves.isEmpty && broken.data(forKey: ReminderSettingsMigration.key) == nil)
        #expect(center.pendingRemoved == 1)
    }
}
