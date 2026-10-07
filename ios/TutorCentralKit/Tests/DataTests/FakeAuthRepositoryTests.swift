import Domain
import Testing
@testable import Data

@MainActor struct FakeAuthRepositoryTests {
    @Test func aScriptedFailureFiresOnceThenTheHappyPathReturns() async throws {
        let fake = FakeAuthRepository()
        fake.nextFailure = .wrongCode
        let email = try #require(EmailAddress("a@b.co"))
        await #expect(throws: SignInFailure.wrongCode) { try await fake.verifyCode(email: email, code: "000000") }
        let user = try await fake.verifyCode(email: email, code: "481234")
        #expect(user.email == "a@b.co")
        #expect(await fake.currentUser() == user)
        #expect(fake.verified.map(\.1) == ["000000", "481234"])
    }

    @Test func theChangesStreamSeesSignInAndSignOut() async throws {
        let fake = FakeAuthRepository()
        let stream = fake.changes()
        var iterator = stream.makeAsyncIterator()
        _ = try await fake.signInWithGoogle()
        #expect(await iterator.next()??.email == "meera.nair@gmail.com")
        await fake.signOut()
        #expect(await iterator.next() == .some(nil))
        #expect(fake.signedOut == 1)
    }
}
