import Domain

/// Signing in and out, whatever the method. The Supabase implementation talks to Auth; the fake runs tests,
/// previews and `bun shots`.
public protocol AuthRepository: Sendable {
    /// The user from the keychain session at launch, or nil, read without the network: an expired token is still the
    /// signed-in user (offline is not signed out). Never throws.
    func currentUser() async -> AuthUser?
    /// Every change after the current state: a user on sign-in, nil on sign-out.
    func changes() -> AsyncStream<AuthUser?>
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws(SignInFailure) -> AuthUser
    func signInWithGoogle() async throws(SignInFailure) -> AuthUser
    func requestCode(email: EmailAddress) async throws(SignInFailure)
    func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser
    func signIn(email: EmailAddress, password: String) async throws(SignInFailure) -> AuthUser
    func signOut() async
}
