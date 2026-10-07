import AuthenticationServices
import Data
import Domain
import Testing
@testable import Onboarding

@MainActor struct SignInStoreTests {
    @Test func googleSucceedsAndReportsTheUser() async {
        let store = SignInStore(auth: FakeAuthRepository())
        let user = await store.continueWithGoogle()
        #expect(user == FakeAuthRepository.meera && store.busy == nil && store.message == nil)
    }

    /// Review Focus 1: a dismissed sheet leaves the landing exactly as it was.
    @Test func aCancelledSheetLeavesNoMessageAndNothingBusy() async {
        let auth = FakeAuthRepository()
        auth.nextFailure = .cancelled
        let store = SignInStore(auth: auth)
        #expect(await store.continueWithGoogle() == nil)
        #expect(store.busy == nil && store.message == nil)
    }

    @Test func failuresBecomeWords() async {
        let cases: [(SignInFailure, String)] = [
            (.offline, "You're offline. Connect and try again."),
            (.providerRefused, "Google didn't complete the sign-in. Try again, or use your email."),
            (.tooManyRequests, "Too many tries. Wait a minute and try again."),
            (.other("boom"), "Couldn't sign in. boom"),
        ]
        for (failure, words) in cases {
            let auth = FakeAuthRepository()
            auth.nextFailure = failure
            let store = SignInStore(auth: auth)
            _ = await store.continueWithGoogle()
            #expect(store.message == words)
        }
    }

    @Test func appleGetsAFreshNonceAndItsHashEachTime() {
        let store = SignInStore(auth: FakeAuthRepository())
        let firstHash = store.startApple()
        let firstNonce = store.nonce
        let secondHash = store.startApple()
        let secondNonce = store.nonce
        #expect(firstNonce != secondNonce)
        #expect(firstHash == Nonce.sha256(firstNonce) && secondHash == Nonce.sha256(secondNonce))
    }

    @Test func anAppleFailureIsItsOwnLine() async {
        let store = SignInStore(auth: FakeAuthRepository())
        _ = store.startApple()
        let user = await store.finishApple(result: .failure(ASAuthorizationError(.failed)))
        #expect(user == nil && store.message == "Apple didn't complete the sign-in. Try again, or use your email.")
    }

    @Test func aDismissedAppleSheetSaysNothing() async {
        let store = SignInStore(auth: FakeAuthRepository())
        _ = store.startApple()
        let user = await store.finishApple(result: .failure(ASAuthorizationError(.canceled)))
        #expect(user == nil && store.message == nil && store.busy == nil)
    }
}
