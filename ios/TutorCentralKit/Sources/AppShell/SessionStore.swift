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
    /// Set when the workspace could not be read; the root shows a footnote line and Retry (`refresh()`). Never
    /// onboarding: a tutor with a centre must not be asked to make a second one because the network blinked.
    public private(set) var lastError: String?
    private let deps: Dependencies
    private var following: Task<Void, Never>?

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

    /// Called by the sign-in stores after a success.
    public func signedIn(_ user: AuthUser) async {
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

    public func signOut() async {
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
            state = workspace.map(State.ready) ?? .needsOnboarding(user)
        } catch {
            lastError = "Couldn't load your centre. Check your connection and try again."
            if case .ready = state {} else {
                state = .loading
            }
        }
    }
}
