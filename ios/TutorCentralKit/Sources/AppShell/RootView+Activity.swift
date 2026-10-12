import Data
import Domain

extension RootView {
    /// A sign-in: the session resolved, the shell following it (its activity log made), then the sign-in recorded.
    func signedIn(_ user: AuthUser) async {
        await session.signedIn(user)
        Self.follow(session.state, shell: shell, deps: deps, launch: launch)
        await shell.recorder?.signedIn()
    }
}
