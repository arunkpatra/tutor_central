import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct AccountStoreTests {
    func queue() -> ChangeQueue {
        ChangeQueue(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    func make(queue: ChangeQueue? = nil, auth: FakeAuthRepository = FakeAuthRepository(user: FakeAuthRepository.meera))
        -> AccountStore {
        AccountStore(workspace: FakeCentreRepository.meeraWorkspace, auth: auth, queue: queue ?? self.queue())
    }

    @Test func showsTheTutorAndTheirMethods() async {
        let store = make()
        await store.load()
        #expect(store.name == "Meera Nair" && store.email == "meera.nair@gmail.com" && store.initials == "MN")
        #expect(store.methods == [.apple, .email] && store.hasPassword == false)
        #expect(store.methodsFootnote
            == "Any of these signs you in to Bright Minds Tuition. The code always works; a password is optional.")
    }

    @Test func signOutWarnsWhenChangesWait() throws {
        let waiting = queue()
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        waiting.add(QueuedChange(
            kind: .attendance(classID: nil, className: "Class 10 Maths", date: day, marks: [:], present: 5, total: 6),
            madeAt: Date()
        ))
        let store = make(queue: waiting)
        #expect(store.signOutDialog.message == "1 saved change hasn't been sent yet: attendance for Class 10 "
            + "Maths. Sign out now and they are lost. Connect first and they go on their own.")
        #expect(store.signOutDialog.action == "Sign out anyway")
        let plain = make().signOutDialog
        #expect(plain.message == "You can sign back in with Apple, Google or your email. What Tutor Central saved on "
            + "this iPhone for Bright Minds Tuition is removed.")
        #expect(plain.action == "Sign out")
    }

    @Test func aPasswordSetFlipsTheRowAndSaysSo() {
        let store = make()
        #expect(store.passwordValue == "Not set")
        store.passwordSet()
        #expect(store.hasPassword && store.passwordValue == "Set")
    }

    /// Review minor 8: the shell hears of it, so Account opened again reads Set, not the session's older Not set.
    @Test func aPasswordSetIsToldToTheShell() {
        var told = 0
        let store = AccountStore(
            workspace: FakeCentreRepository.meeraWorkspace, auth: FakeAuthRepository(),
            queue: ChangeQueue(centre: UUID(), directory: FileManager.default.temporaryDirectory)
        ) { told += 1 }
        store.passwordSet()
        #expect(told == 1)
    }
}

@MainActor struct PasswordStoreTests {
    @Test func submitIsRefusedUnderEightCharactersAndSetsThePasswordAndTheFlag() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        let store = PasswordStore(auth: auth, centres: centres, hasPassword: false)
        store.password = "short"
        #expect(!store.canSubmit && store.title == "Set a password")
        store.password = "brightminds2026"
        #expect(store.canSubmit)
        #expect(await store.submit())
        #expect(auth.passwords == ["brightminds2026"] && centres.hasPasswordSet == 1 && store.error == nil)
    }

    @Test func aFailureKeepsThePasswordAndSaysWhy() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = PasswordStore(auth: auth, centres: FakeCentreRepository(), hasPassword: true)
        store.password = "brightminds2026"
        auth.nextAccountFailure = .offline
        #expect(await store.submit() == false)
        #expect(store.password == "brightminds2026")
        #expect(store.error == "Couldn't set the password. Check your connection and try again.")
        #expect(store.title == "Change password" && !store.busy)
        auth.nextAccountFailure = .weakPassword
        #expect(await store.submit() == false)
        #expect(store.error == "Choose a password that's harder to guess.")
    }

    @Test func aSecondSubmitWhileOneRunsIsRefused() async throws {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        centres.delay = .milliseconds(100)
        let store = PasswordStore(auth: auth, centres: centres, hasPassword: false)
        store.password = "brightminds2026"
        let first = Task { await store.submit() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.busy && !store.canSubmit)
        #expect(await store.submit() == false)
        #expect(await first.value && auth.passwords.count == 1)
    }
}
