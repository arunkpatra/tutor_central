import Data
import Domain
import Foundation
import Testing
@testable import Settings

@MainActor struct SettingsStoreTests {
    func make(
        _ centres: FakeCentreRepository = FakeCentreRepository(),
        auth: FakeAuthRepository = FakeAuthRepository(user: FakeAuthRepository.meera)
    ) -> SettingsStore {
        centres.workspace = FakeCentreRepository.meeraWorkspace
        return SettingsStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            auth: auth,
            centres: centres,
            version: "0.1 (12)"
        )
    }

    @Test func showsTheWorkspaceAndTheAccount() {
        let store = make()
        #expect(store.displayName == "Meera Nair" && store.centreName == "Bright Minds Tuition")
        #expect(store.digits == "9611299988" && store.email == "meera.nair@gmail.com")
        #expect(store.version == "0.1 (12)" && store.saveState == .idle)
    }

    @Test func committingANameSavesAndMarksSaved() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        var changed: Workspace?
        store.onWorkspaceChanged = { changed = $0 }
        store.displayName = "Meera"
        await store.commitName()
        #expect(centres.profileUpdates == ["Meera"] && store.saveState == .saved)
        #expect(changed?.profile.displayName == "Meera")
    }

    @Test func anUnchangedCommitDoesNothing() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        await store.commitCentre()
        await store.commitName()
        await store.commitPhone()
        #expect(centres.nameUpdates.isEmpty && centres.whatsAppUpdates.isEmpty && centres.profileUpdates.isEmpty)
        #expect(store.saveState == .idle)
    }

    @Test func anEmptyNameOrCentreIsNotSaved() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        store.centreName = " "
        await store.commitCentre()
        #expect(centres.nameUpdates.isEmpty && store.message == "A centre needs a name.")
        #expect(store.centreName == "Bright Minds Tuition")
        store.displayName = ""
        await store.commitName()
        #expect(centres.profileUpdates.isEmpty && store.message == "Your name can't be empty.")
        #expect(store.displayName == "Meera Nair")
    }

    @Test func aBadPhoneIsRefusedAnEmptyOneClearsIt() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        store.digits = "12"
        await store.commitPhone()
        #expect(store.phoneError == "Needs 10 digits after +91." && centres.whatsAppUpdates.isEmpty)
        store.digits = ""
        await store.commitPhone()
        #expect(centres.whatsAppUpdates == [nil] && store.saveState == .saved)
    }

    @Test func aFailedSaveKeepsTheTypedValueAndSaysSo() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        centres.nextError = URLError(.notConnectedToInternet)
        store.centreName = "Bright Minds"
        await store.commitCentre()
        #expect(store.centreName == "Bright Minds" && store.saveState == .idle)
        #expect(store.message == "Couldn't save. Check your connection and try again.")
    }

    @Test func signOutSignsOut() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = make(auth: auth)
        await store.signOut()
        #expect(auth.signedOut == 1)
    }

    /// Review, Important 5: each field writes only its own column, so two quick edits cannot undo each other.
    @Test func eachCommitWritesOnlyItsOwnColumn() async {
        let centres = FakeCentreRepository()
        let store = make(centres)
        store.centreName = "Bright Minds"
        store.digits = "9876543210"
        await store.commitPhone()
        await store.commitCentre()
        #expect(centres.whatsAppUpdates == ["+919876543210"] && centres.nameUpdates == ["Bright Minds"])
    }
}
