import Data
import Domain
import Foundation
import Testing
@testable import Onboarding

@MainActor struct OnboardingStoreTests {
    func make(
        _ user: AuthUser = FakeAuthRepository.meera,
        auth: FakeAuthRepository = FakeAuthRepository(),
        centres: FakeCentreRepository = FakeCentreRepository()
    ) -> OnboardingStore {
        OnboardingStore(user: user, auth: auth, centres: centres)
    }

    /// Review Focus 2: a hidden Apple email or a nameless Google account still reaches a usable form.
    @Test func prefillsFromTheProviderAndShowsWhoIsSignedIn() {
        let store = make()
        #expect(store.displayName == "Meera Nair" && store.signedInAs == "meera.nair@gmail.com")
        let relay = AuthUser(id: FakeAuthRepository.meera.id, email: "x9@privaterelay.appleid.com", fullName: nil)
        let bare = make(relay)
        #expect(bare.displayName.isEmpty && bare.signedInAs == "x9@privaterelay.appleid.com")
        let noEmail = make(AuthUser(id: relay.id, email: nil))
        #expect(noEmail.signedInAs == "your Apple ID")
    }

    @Test func submitNeedsANameAndACentreAndAValidOptionalPhone() async {
        let centres = FakeCentreRepository()
        let store = make(centres: centres)
        store.displayName = "  "
        store.centreName = "Bright Minds Tuition"
        #expect(!store.canSubmit)
        store.displayName = "Meera Nair"
        #expect(store.canSubmit)
        store.digits = "96112"
        #expect(await store.submit() == nil)
        #expect(store.phoneError == "Needs 10 digits after +91." && centres.created.isEmpty)
        store.digits = "9611299988"
        #expect(store.phoneError == nil)
        let workspace = await store.submit()
        #expect(workspace?.centre.whatsappNumber == "+919611299988" && centres.created.first?
            .displayName == "Meera Nair")
        store.digits = ""
        #expect(store.canSubmit)
    }

    @Test func aFailureIsSaidAndTheFieldsAreKept() async {
        let centres = FakeCentreRepository()
        centres.nextError = URLError(.notConnectedToInternet)
        let store = make(centres: centres)
        store.centreName = "Bright Minds Tuition"
        #expect(await store.submit() == nil)
        #expect(store.message == "Couldn't create your centre. Check your connection and try again.")
        #expect(store.centreName == "Bright Minds Tuition")
    }

    @Test func notYouSignsOut() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = make(auth: auth)
        await store.notYou()
        #expect(auth.signedOut == 1)
    }
}
