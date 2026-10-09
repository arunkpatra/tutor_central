import Data
import Domain
import Foundation
import Students
import Testing
@testable import Settings

@MainActor struct DeleteAccountStoreTests {
    let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
    let account = FakeAccountRepository()

    func make(
        apple: Bool = true, reauthorize: @escaping @MainActor () async throws(AccountFailure) -> String = { "code-1" }
    ) -> DeleteAccountStore {
        auth.methods = apple ? [.apple, .email] : [.email]
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { Date() }
        )
        return DeleteAccountStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, auth: auth, account: account,
            reauthorize: reauthorize
        )
    }

    @Test func theButtonWaitsForTheCentresNameAndTheNoticesCountTheRegister() async {
        let store = make()
        await store.load()
        #expect(!store.canDelete && store.centreName == "Bright Minds Tuition")
        store.typed = "bright minds tuition"
        #expect(store.canDelete)
        #expect(store.notices.first == "10 students with their fees and attendance, 2 classes, your events, tasks, "
            + "notes and everything created with AI.")
        #expect(store.notices.count == 3 && store.needsApple)
        let email = make(apple: false)
        await email.load()
        #expect(email.notices.count == 2 && !email.needsApple)
    }

    @Test func deleteConfirmsWithAppleRevokesThenDeletesThenIsDone() async {
        let store = make()
        await store.load()
        store.typed = "Bright Minds Tuition"
        await store.delete()
        #expect(account.revoked == ["code-1"] && auth.deleted == 1 && store.phase == .done)
    }

    @Test func aFailedDeleteAfterAppleKeepsTheTutorSignedInAndRetries() async {
        let store = make()
        await store.load()
        store.typed = "Bright Minds Tuition"
        auth.nextAccountFailure = .offline
        await store.delete()
        #expect(store.phase == .failed(DeleteAccountStore.Failure(
            title: "Couldn't delete your account.",
            line: "Check your connection and try again. Nothing was removed; you are still signed in."
        )))
        #expect(store.typed == "Bright Minds Tuition" && auth.user != nil && account.revoked == ["code-1"])
        await store.delete()
        #expect(account.revoked == ["code-1", "code-1"] && auth.deleted == 1 && store.phase == .done)
    }

    @Test func appleCancelledGoesBackQuietlyAndAppleRefusedSaysSo() async {
        let cancelled = make(reauthorize: { () async throws(AccountFailure) -> String in throw .cancelled })
        await cancelled.load()
        cancelled.typed = "Bright Minds Tuition"
        await cancelled.delete()
        #expect(cancelled.phase == .idle && auth.deleted == 0)
        let refused = make()
        await refused.load()
        refused.typed = "Bright Minds Tuition"
        account.nextFailure = .appleRefused
        await refused.delete()
        #expect(refused.phase == .failed(DeleteAccountStore.Failure(
            title: "Couldn't delete your account.",
            line: "Apple didn't accept the confirmation. Try again. Nothing was removed; you are still signed in."
        )))
    }

    @Test func anEmailAccountNeedsNoAppleAndEndsSignedOut() async {
        var asked = 0
        let store = make(apple: false, reauthorize: {
            asked += 1
            return "never"
        })
        await store.load()
        store.typed = "Bright Minds Tuition"
        await store.delete()
        #expect(store.phase == .done && auth.user == nil && asked == 0 && account.revoked.isEmpty)
    }

    @Test func aSecondDeleteWhileOneRunsIsRefusedAndCancelDropsALateAnswer() async throws {
        let store = make(reauthorize: {
            try? await Task.sleep(for: .milliseconds(100))
            return "code-1"
        })
        await store.load()
        store.typed = "Bright Minds Tuition"
        let first = Task { await store.delete() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.phase == .confirmingWithApple && !store.canDelete)
        await store.delete()
        store.cancel()
        await first.value
        #expect(store.phase == .idle && account.revoked.isEmpty && auth.deleted == 0)
    }
}
