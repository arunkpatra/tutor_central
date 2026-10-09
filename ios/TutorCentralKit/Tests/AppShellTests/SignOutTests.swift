import Data
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct SignOutTests {
    @Test func signOutWipesTheCachesTheQueueAndTheReminders() async throws {
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
        let reminder = Reminder(
            id: "fees-2026-10", kind: .fees, title: "t", body: "b", fireAt: Date(), link: "tutorcentral://fees"
        )
        await notifications.replace(with: [reminder])
        let defaults = try #require(UserDefaults(suiteName: "signout-\(UUID().uuidString)"))
        defaults.set(false, forKey: "haptics")
        let deps = Fixtures.dependencies(for: .today)
        let auth = try #require(deps.auth as? FakeAuthRepository)
        let session = SessionStore(deps: deps, initial: .ready(FakeCentreRepository.meeraWorkspace))
        await session.signOut(wiping: SignOutWipe(
            centre: centre, directory: dir, defaults: defaults, queue: queue, notifications: notifications
        ))
        #expect(session.state == .signedOut && auth.signedOut == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path).isEmpty)
        let pending = await notifications.pending()
        #expect(queue.pending.isEmpty && pending.isEmpty)
        #expect(defaults.object(forKey: "haptics") == nil)
    }
}
