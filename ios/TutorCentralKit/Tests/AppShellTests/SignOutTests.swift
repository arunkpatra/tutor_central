import Data
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct SignOutTests {
    @Test func signOutForgetsThePushTokenThenWipesTheCachesTheQueueAndTheReminders() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "signout-\(UUID().uuidString)", isDirectory: true
        )
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let queue = ChangeQueue(centre: centre, directory: dir)
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        queue.add(QueuedChange(
            kind: .absenceLog(studentID: UUID(), studentName: "Hemanth Reddy", about: day), madeAt: Date()
        ))
        CachedRead<[String]>(centre: centre, key: "tasks", directory: dir).keep(["x"], at: Date())
        let notifications = FakeNotificationCenter(permission: .allowed)
        // The token is forgotten while the queue is still there: before the wipe.
        let tokens = FakeDeviceTokenRepository(onForget: { @MainActor in #expect(!queue.pending.isEmpty) })
        let push = PushRegistrar(
            notifications: notifications, tokens: tokens, registerForRemote: {}, deviceID: { "device-1" },
            environment: "sandbox", build: 28
        )
        let defaults = try #require(UserDefaults(suiteName: "signout-\(UUID().uuidString)"))
        defaults.set(false, forKey: "haptics")
        let deps = Fixtures.dependencies(for: .today)
        let auth = try #require(deps.auth as? FakeAuthRepository)
        let session = SessionStore(deps: deps, initial: .ready(FakeCentreRepository.meeraWorkspace))
        await session.signOut(wiping: SignOutWipe(
            centre: centre, directory: dir, defaults: defaults, queue: queue, notifications: notifications,
            forgetPush: { await push.forget() }
        ))
        #expect(session.state == .signedOut && auth.signedOut == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path).isEmpty)
        #expect(queue.pending.isEmpty && notifications.allRemoved == 1)
        #expect(await tokens.forgotten == ["device-1"])
        #expect(defaults.object(forKey: "haptics") == nil)
    }
}
