import Data
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct SessionStoreTests {
    func deps(auth: FakeAuthRepository, centres: FakeCentreRepository = FakeCentreRepository(), files: URL? = nil)
        -> Dependencies {
        Dependencies(
            auth: auth,
            centres: centres,
            counts: FakeCountsRepository(),
            students: FakeStudentsRepository(),
            classes: FakeClassesRepository(),
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository(),
            schools: FakeSchoolsRepository(),
            textbooks: FakeTextbooksRepository(),
            record: FakeRecordRepository(),
            plans: FakePlansRepository(),
            photos: FakePhotoStore(),
            events: FakeEventsRepository(),
            tasks: FakeTasksRepository(),
            fees: FakeFeesRepository(),
            qrImages: MemoryQRImageStore(),
            ai: FakeAIRepository(),
            aiHistory: FakeAIHistoryRepository(),
            account: FakeAccountRepository(),
            notifications: FakeNotificationCenter(),
            reminderSettings: ReminderSettingsStore(defaults: UserDefaults(suiteName: "session-tests") ?? .standard),
            connectivity: FakeConnectivity(),
            cachesLists: false,
            filesDirectory: files ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
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
        await store.signOut(wiping: SignOutWipe(
            centre: workspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            defaults: UserDefaults(suiteName: "session-sign-out") ?? .standard, queue: nil,
            notifications: FakeNotificationCenter()
        ))
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

    @Test func aDeletedUsersSessionBecomesSignedOut() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        let store = SessionStore(deps: deps(auth: auth, centres: centres))
        await store.start()
        auth.emit(nil) // Supabase's refresh of a deleted user's token fails and announces a sign-out
        try? await Task.sleep(for: .milliseconds(20))
        #expect(store.state == .signedOut && store.deletedCentre == nil)
    }

    @Test func afterADeletionTheLandingNamesTheCentreUntilTheNextSignIn() async {
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        let store = SessionStore(deps: deps(auth: auth, centres: centres))
        await store.start()
        store.deleted(centreName: "Bright Minds Tuition")
        #expect(store.state == .signedOut && store.deletedCentre == "Bright Minds Tuition")
        await store.signedIn(FakeAuthRepository.meera)
        #expect(store.deletedCentre == nil)
    }

    /// Run 7: offline at launch the centre is read from this iPhone, so the saved lists can show.
    @Test func offlineAtLaunchTheSavedCentreOpensTheTabs() async {
        let files = FileManager.default.temporaryDirectory.appendingPathComponent("session-\(UUID().uuidString)")
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        let online = SessionStore(deps: deps(auth: auth, centres: centres, files: files))
        await online.start()
        centres.nextError = URLError(.cannotConnectToHost)
        let offline = SessionStore(deps: deps(auth: auth, centres: centres, files: files))
        await offline.start()
        #expect(offline.state == .ready(FakeCentreRepository.meeraWorkspace))
    }

    @Test func anotherTutorsSavedCentreIsNeverOpened() async {
        let files = FileManager.default.temporaryDirectory.appendingPathComponent("session-\(UUID().uuidString)")
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        await SessionStore(deps: deps(
            auth: FakeAuthRepository(user: FakeAuthRepository.meera),
            centres: centres,
            files: files
        ))
        .start()
        let someoneElse = AuthUser(id: UUID(), email: "ravi@example.com")
        centres.nextError = URLError(.cannotConnectToHost)
        let offline = SessionStore(deps: deps(
            auth: FakeAuthRepository(user: someoneElse),
            centres: centres,
            files: files
        ))
        await offline.start()
        #expect(offline.state == .loading)
    }

    /// The tabs open at once from the saved centre; the read refreshes it behind them.
    @Test func theSavedCentreOpensAtOnceWhileTheReadRuns() async throws {
        let files = FileManager.default.temporaryDirectory.appendingPathComponent("session-\(UUID().uuidString)")
        let auth = FakeAuthRepository(user: FakeAuthRepository.meera)
        let centres = FakeCentreRepository()
        centres.workspace = FakeCentreRepository.meeraWorkspace
        await SessionStore(deps: deps(auth: auth, centres: centres, files: files)).start()
        centres.firstLookupDelay = .milliseconds(200)
        let store = SessionStore(deps: deps(auth: auth, centres: centres, files: files))
        let starting = Task { await store.start() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(store.state == .ready(FakeCentreRepository.meeraWorkspace))
        await starting.value
    }
}
