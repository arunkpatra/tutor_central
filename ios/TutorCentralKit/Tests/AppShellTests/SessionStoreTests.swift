import Data
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct SessionStoreTests {
    func deps(auth: FakeAuthRepository, centres: FakeCentreRepository = FakeCentreRepository()) -> Dependencies {
        Dependencies(
            auth: auth,
            centres: centres,
            counts: FakeCountsRepository(),
            students: FakeStudentsRepository(),
            classes: FakeClassesRepository(),
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository(),
            events: FakeEventsRepository(),
            tasks: FakeTasksRepository(),
            fees: FakeFeesRepository(),
            qrImages: MemoryQRImageStore(),
            cachesRegister: false,
            now: { Fixtures.now },
            bundleVersion: "0.1 (1)"
        )
    }

    @Test func startsLoadingThenSignedOutWhenTheKeychainIsEmpty() async {
        let store = SessionStore(deps: deps(auth: FakeAuthRepository()))
        #expect(store.state == .loading)
        await store.start()
        #expect(store.state == .signedOut)
    }

    @Test func aSignedInUserWithoutACentreGoesToOnboarding() async {
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera)))
        await store.start()
        #expect(store.state == .needsOnboarding(FakeAuthRepository.meera))
    }

    @Test func aSignedInUserWithACentreIsReady() async throws {
        let centres = FakeCentreRepository()
        let draft = CentreDraft(displayName: "Meera Nair", centreName: "Bright Minds Tuition", whatsappNumber: nil)
        let workspace = try await centres.createCentre(draft, for: FakeAuthRepository.meera)
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera), centres: centres))
        await store.start()
        #expect(store.state == .ready(workspace))
    }

    @Test func signInThenCreateThenSignOutWalksTheThreeRoots() async throws {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        let store = SessionStore(deps: deps(auth: auth, centres: centres))
        await store.start()
        try await store.signedIn(auth.signInWithGoogle())
        #expect(store.state == .needsOnboarding(FakeAuthRepository.meera))
        let draft = CentreDraft(displayName: "M", centreName: "C", whatsappNumber: nil)
        let workspace = try await centres.createCentre(draft, for: FakeAuthRepository.meera)
        store.centreCreated(workspace)
        #expect(store.state == .ready(workspace))
        await store.signOut()
        #expect(store.state == .signedOut && auth.signedOut == 1)
    }

    @Test func aSignOutFromElsewhereIsFollowed() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let store = SessionStore(deps: deps(auth: auth))
        await store.start()
        auth.emit(nil)
        for _ in 0 ..< 5 {
            await Task.yield()
        }
        #expect(store.state == .signedOut)
    }

    @Test func aWorkspaceLookupThatFailsKeepsTheUserSignedInAndReportsIt() async {
        let centres = FakeCentreRepository()
        centres.nextError = URLError(.notConnectedToInternet)
        let store = SessionStore(deps: deps(auth: FakeAuthRepository(user: FakeAuthRepository.meera), centres: centres))
        await store.start()
        // Not onboarding: a tutor with a centre must never be asked to make a second one because the network blinked.
        #expect(store.state == .loading && store.lastError != nil)
        await store.refresh()
        #expect(store.state == .needsOnboarding(FakeAuthRepository.meera) && store.lastError == nil)
    }

    /// Review, Important 3: Supabase announces an Apple sign-in with a user that has no name (Apple gives the name in
    /// the credential, once); the app's own sign-in carries it. Onboarding must get the name either way.
    @Test func appleGivesItsNameOnceAndOnboardingStillGetsIt() async throws {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        let store = SessionStore(deps: deps(auth: auth, centres: centres))
        await store.start()
        // The announced (nameless) sign-in's lookup is slow; the app's own (named) one finishes first.
        centres.firstLookupDelay = .milliseconds(100)
        let named = try await auth.signInWithApple(idToken: "t", nonce: "n", fullName: "Meera Nair")
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        await store.signedIn(named)
        try await Task.sleep(for: .milliseconds(300))
        #expect(named.fullName == "Meera Nair")
        #expect(store.state == .needsOnboarding(named))
    }
}
