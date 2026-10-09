import Data
import Domain
import Foundation
import Observation

/// The session gate (information-architecture.md, "Entry"): the one thing that decides which root shows. It starts
/// in `.loading` so the sign-in screen never flashes while the keychain is read.
@MainActor @Observable public final class SessionStore {
    public enum State: Equatable, Sendable {
        case loading
        case signedOut
        case needsOnboarding(AuthUser)
        case ready(Workspace)
    }

    public private(set) var state: State

    /// Signed in with a centre: the tabs show.
    public var isReady: Bool {
        if case .ready = state {
            true
        } else {
            false
        }
    }

    /// Set when the workspace could not be read; the root shows a footnote line and Retry (`refresh()`). Never
    /// onboarding: a tutor with a centre must not be asked to make a second one because the network blinked.
    public private(set) var lastError: String?
    /// The centre an account deletion just removed: the landing says so until the next sign-in (P7-Delete-Done).
    public private(set) var deletedCentre: String?
    private let deps: Dependencies
    private var following: Task<Void, Never>?
    /// Names the app's own sign-ins carried (Apple gives one once, in the credential); Supabase's announcement of the
    /// same sign-in has none, and either lookup may finish last.
    private var knownNames: [UUID: String] = [:]

    public init(deps: Dependencies, initial: State = .loading) {
        self.deps = deps
        state = initial
    }

    /// Reads the keychain user, resolves the workspace, then follows sign-ins and sign-outs from elsewhere.
    public func start() async {
        let changes = deps.auth.changes()
        if let user = await deps.auth.currentUser() {
            await resolve(user)
        } else {
            state = .signedOut
        }
        following = Task { [weak self] in
            for await user in changes {
                guard let self else { return }
                await follow(user)
            }
        }
    }

    /// After Delete account (D37): the auth user is gone and the phone wiped; the landing names what was deleted.
    public func deleted(centreName: String) {
        deletedCentre = centreName
        state = .signedOut
    }

    /// Called by the sign-in stores after a success.
    public func signedIn(_ user: AuthUser) async {
        deletedCentre = nil
        if let name = user.fullName {
            knownNames[user.id] = name
        }
        await resolve(user)
    }

    public func centreCreated(_ workspace: Workspace) {
        state = .ready(workspace)
    }

    /// Settings edits.
    public func workspaceChanged(_ workspace: Workspace) {
        state = .ready(workspace)
    }

    /// Foreground, and Retry: reads the workspace again.
    public func refresh() async {
        switch state {
        case let .ready(workspace): await resolve(workspace.user)
        case .loading:
            if let user = await deps.auth.currentUser() {
                await resolve(user)
            } else {
                state = .signedOut
            }
        case .signedOut, .needsOnboarding: break
        }
    }

    /// Sign-out wipes the phone first (D40): the centre's files, this iPhone's settings, the queue, the reminders.
    public func signOut(wiping wipe: SignOutWipe) async {
        await wipe.run()
        await deps.auth.signOut()
        state = .signedOut
    }

    private func follow(_ user: AuthUser?) async {
        guard let user else {
            state = .signedOut
            return
        }
        if case .signedOut = state {
            await resolve(user)
        }
    }

    private func resolve(_ user: AuthUser) async {
        do {
            let workspace = try await deps.centres.workspace(for: user)
            lastError = nil
            state = workspace.map(State.ready) ?? .needsOnboarding(withKnownName(user))
        } catch {
            lastError = "Couldn't load your centre. Check your connection and try again."
            if case .ready = state {} else {
                state = .loading
            }
        }
    }

    private func withKnownName(_ user: AuthUser) -> AuthUser {
        guard user.fullName == nil, let name = knownNames[user.id] else { return user }
        return AuthUser(id: user.id, email: user.email, fullName: name)
    }
}

/// What sign-out and deletion clear on this iPhone (D40): the centre's files under Application Support, this iPhone's
/// settings in `UserDefaults`, the queue, and the pending reminders.
public struct SignOutWipe {
    let centre: UUID
    let directory: URL?
    let defaults: UserDefaults
    let queue: ChangeQueue?
    let notifications: any NotificationCenterClient

    public init(
        centre: UUID, directory: URL? = nil, defaults: UserDefaults = .standard, queue: ChangeQueue?,
        notifications: any NotificationCenterClient
    ) {
        self.centre = centre
        self.directory = directory
        self.defaults = defaults
        self.queue = queue
        self.notifications = notifications
    }

    @MainActor func run() async {
        queue?.wipe()
        Wipe.everything(centre: centre, directory: directory, defaults: defaults)
        await notifications.removeAll()
    }
}
