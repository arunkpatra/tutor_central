import Data
import Domain
import Foundation
import Testing
@testable import Onboarding

@MainActor struct EmailSignInStoreTests {
    final class Clock {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    func make(_ auth: FakeAuthRepository = FakeAuthRepository(), clock: Clock = Clock()) -> EmailSignInStore {
        EmailSignInStore(auth: auth, cooldown: 60, now: { clock.now })
    }

    @Test func aBadAddressIsRefusedInWordsBeforeAnyRequest() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "meera@"
        await store.requestCode()
        #expect(store.emailError == "Enter a full email address, like name@example.com.")
        #expect(auth.requested.isEmpty && store.step == .request)
    }

    @Test func aGoodAddressRequestsACodeAndMovesToCodeEntryWithTheCooldownRunning() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = " Meera.Nair@gmail.com "
        await store.requestCode()
        #expect(auth.requested.map(\.string) == ["meera.nair@gmail.com"])
        #expect(store.step == .code && store.sentTo?.string == "meera.nair@gmail.com" && store.resendAvailableIn == 60)
        for _ in 0 ..< 36 {
            store.tick()
        }
        #expect(store.resendAvailableIn == 24)
        for _ in 0 ..< 30 {
            store.tick()
        }
        #expect(store.resendAvailableIn == 0)
    }

    @Test func sixDigitsVerifyAndReturnTheUser() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"
        await store.requestCode()
        store.code = "481234"
        let user = await store.verify()
        #expect(user?.email == "a@b.co" && auth.verified.last?.1 == "481234")
    }

    @Test func fewerThanSixDigitsNeverCallsVerify() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"
        await store.requestCode()
        store.code = "48123"
        #expect(await store.verify() == nil && auth.verified.isEmpty)
    }

    @Test func wrongAndExpiredCodesHaveTheirOwnLinesAndClearTheDigits() async {
        let cases: [(SignInFailure, String)] = [
            (.wrongCode, "That code isn't right. Check the email or ask for a new one."),
            (.codeExpired, "That code has expired. Ask for a new one."),
            (.tooManyRequests, "Too many tries. Wait a minute and try again."),
            (.offline, "You're offline. Connect and try again."),
        ]
        for (failure, words) in cases {
            let auth = FakeAuthRepository()
            let store = make(auth)
            store.email = "a@b.co"
            await store.requestCode()
            auth.nextFailure = failure
            store.code = "000000"
            #expect(await store.verify() == nil)
            #expect(store.codeError == words && store.code.isEmpty && store.step == .code)
        }
    }

    /// Review Focus 3: Supabase answers a wrong code and an expired one alike; past ten minutes the screen says
    /// expired, never "isn't right".
    @Test func aCodeTypedAfterTenMinutesSaysItHasExpired() async {
        let auth = FakeAuthRepository()
        let clock = Clock()
        let store = make(auth, clock: clock)
        store.email = "a@b.co"
        await store.requestCode()
        clock.now += 601
        auth.nextFailure = .wrongCode
        store.code = "481234"
        #expect(await store.verify() == nil)
        #expect(store.codeError == "That code has expired. Ask for a new one.")
    }

    @Test func aResendStartsTheTenMinutesAgain() async {
        let auth = FakeAuthRepository()
        let clock = Clock()
        let store = make(auth, clock: clock)
        store.email = "a@b.co"
        await store.requestCode()
        clock.now += 590
        for _ in 0 ..< 60 {
            store.tick()
        }
        await store.resend()
        clock.now += 30
        auth.nextFailure = .wrongCode
        store.code = "000000"
        _ = await store.verify()
        // Review, Important 4: after a resend, a wrong code is most likely the first email's.
        #expect(store.codeError == "That code isn't right. Use the code in the newest email.")
    }

    @Test func resendOnlyAfterTheCooldownAndItRestartsIt() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.email = "a@b.co"
        await store.requestCode()
        await store.resend()
        #expect(auth.requested.count == 1)
        for _ in 0 ..< 60 {
            store.tick()
        }
        await store.resend()
        #expect(auth.requested.count == 2 && store.resendAvailableIn == 60 && store.codeError == nil)
    }

    @Test func theRateLimitOnRequestIsSaidUnderTheEmailField() async {
        let auth = FakeAuthRepository()
        auth.nextFailure = .tooManyRequests
        let store = make(auth)
        store.email = "a@b.co"
        await store.requestCode()
        #expect(store.step == .request && store.emailError == "Too many codes asked for. Wait a minute and try again.")
    }

    @Test func thePasswordPathValidatesAndMapsAWrongPassword() async {
        let auth = FakeAuthRepository()
        let store = make(auth)
        store.usePassword()
        #expect(store.step == .password)
        store.email = "a@b.co"
        store.password = ""
        #expect(await store.signInWithPassword() == nil && store.passwordError == "Enter your password.")
        auth.nextFailure = .wrongPassword
        store.password = "nope"
        #expect(await store.signInWithPassword() == nil)
        #expect(store.passwordError == "That password isn't right. If you never set one, sign in with a code instead.")
        store.password = "right"
        #expect(await store.signInWithPassword()?.email == "a@b.co")
    }

    /// A backend's own words never reach the screen (D41): each step says what failed and Try again.
    @Test func aBackendMessageIsNeverShown() {
        let raw = SignInFailure.other("Email rate limit exceeded: 429")
        #expect(EmailSignInStore.requestWords(raw) == "Couldn't send the code. Try again.")
        #expect(EmailSignInStore.codeWords(raw) == "Couldn't sign in. Try again.")
        #expect(EmailSignInStore.passwordWords(raw) == "Couldn't sign in. Try again.")
    }
}
