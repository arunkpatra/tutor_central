import Data
import Domain
import Foundation
import Testing

@MainActor struct AuthAdditionsTests {
    @Test func theFakeReportsMethodsSetsAPasswordAndDeletes() async throws {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        #expect(await auth.signInMethods() == [.apple, .email])
        try await auth.setPassword("brightminds2026")
        #expect(auth.passwords == ["brightminds2026"])
        var seen: [AuthUser?] = []
        let stream = auth.changes()
        let listening = Task {
            for await user in stream {
                seen.append(user)
                if user == nil {
                    break
                }
            }
        }
        try await auth.deleteAccount()
        await listening.value
        #expect(auth.deleted == 1 && seen == [nil] && auth.user == nil)
    }

    @Test func aScriptedFailureIsThrownOnce() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        auth.nextAccountFailure = .weakPassword
        await #expect(throws: AccountFailure.weakPassword) { try await auth.setPassword("x") }
        await #expect(throws: Never.self) { try await auth.setPassword("brightminds2026") }
        auth.nextAccountFailure = .offline
        await #expect(throws: AccountFailure.offline) { try await auth.deleteAccount() }
        #expect(auth.deleted == 0 && auth.user != nil)
    }

    @Test func theWordsSayWhatHappened() {
        #expect(AccountFailure.appleRefused.message == "Apple didn't accept the confirmation. Try again.")
        #expect(AccountFailure.offline.message == "You're offline. Connect and try again.")
        #expect(AccountFailure.signedOut.message == "Your sign-in has ended. Sign in again.")
        #expect(AccountFailure.server("Nope.").message == "Nope.")
    }

    @Test func theFakeCentreRecordsThePasswordFlagAndTheAccountRepositoryTheCodes() async throws {
        let centres = FakeCentreRepository()
        try await centres.setHasPassword()
        #expect(centres.hasPasswordSet == 1)
        let account = FakeAccountRepository()
        try await account.revokeApple(code: "c-1")
        account.nextFailure = .appleUnreachable
        await #expect(throws: AccountFailure.appleUnreachable) { try await account.revokeApple(code: "c-2") }
        #expect(account.revoked == ["c-1"])
    }

    @Test func supabaseErrorsBecomeAccountFailures() {
        #expect(AccountFailure(URLError(.notConnectedToInternet)) == .offline)
        #expect(AccountFailure(AccountFailure.weakPassword) == .weakPassword)
        struct Other: Error {}
        if case .server = AccountFailure(Other()) {} else {
            Issue.record("not server")
        }
    }
}

struct WipeTests {
    @Test func everythingOfTheCentreGoesAndNothingElse() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "wipe-\(UUID().uuidString)", isDirectory: true
        )
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let mine = UUID().uuidString.lowercased()
        let other = UUID().uuidString.lowercased()
        for name in [
            "register-\(mine).json", "cache-\(mine)-fees-2026-10.json", "queue-\(mine).json", "upi-qr-\(mine).png",
            "register-\(other).json",
        ] {
            try Data("x".utf8).write(to: dir.appendingPathComponent(name))
        }
        let defaults = try #require(UserDefaults(suiteName: "wipe-\(UUID().uuidString)"))
        defaults.set(false, forKey: "haptics")
        defaults.set("light", forKey: "appearance")
        defaults.set(Data(), forKey: "reminders")
        defaults.set(true, forKey: "reminders.asked")
        try Wipe.everything(centre: #require(UUID(uuidString: mine)), directory: dir, defaults: defaults)
        let left = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(left == ["register-\(other).json"])
        #expect(defaults.object(forKey: "haptics") == nil && defaults.object(forKey: "appearance") == nil)
        #expect(defaults.object(forKey: "reminders") == nil && defaults.object(forKey: "reminders.asked") == nil)
    }

    @Test func aMissingFolderIsNothingToWipe() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("none-\(UUID().uuidString)")
        let defaults = try #require(UserDefaults(suiteName: "wipe-\(UUID().uuidString)"))
        Wipe.everything(centre: UUID(), directory: dir, defaults: defaults)
        #expect(!FileManager.default.fileExists(atPath: dir.path))
    }
}
