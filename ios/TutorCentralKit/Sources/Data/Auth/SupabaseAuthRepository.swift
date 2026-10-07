import Domain
import Foundation
import Supabase

/// supabase-swift's AuthClient behind the protocol: the keychain session, Apple by id token, Google through its own
/// ASWebAuthenticationSession (the inventory row), the email code and the password.
public final class SupabaseAuthRepository: AuthRepository {
    private let auth: AuthClient

    public init(client: SupabaseClient) {
        auth = client.auth
    }

    public func currentUser() async -> AuthUser? {
        await (try? auth.session)?.user.authUser
    }

    public func changes() -> AsyncStream<AuthUser?> {
        let auth = auth
        return AsyncStream { continuation in
            let task = Task {
                for await (event, session) in auth.authStateChanges where event != .initialSession {
                    continuation.yield(session?.user.authUser)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func signInWithApple(
        idToken: String,
        nonce: String,
        fullName: String?
    ) async throws(SignInFailure) -> AuthUser {
        let user = try await wrap {
            try await auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)).user
        }
        // Apple gives the name only on the first authorisation, in the credential, never in the token.
        guard let fullName, user.authUser.fullName == nil else { return user.authUser }
        return AuthUser(id: user.id, email: user.email, fullName: fullName)
    }

    public func signInWithGoogle() async throws(SignInFailure) -> AuthUser {
        try await wrap {
            try await auth.signInWithOAuth(provider: .google, redirectTo: SupabaseClientFactory.redirectURL).user
        }.authUser
    }

    public func requestCode(email: EmailAddress) async throws(SignInFailure) {
        try await wrap { try await auth.signInWithOTP(email: email.string, shouldCreateUser: true) }
    }

    public func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser {
        try await wrap { try await auth.verifyOTP(email: email.string, token: code, type: .email).user }.authUser
    }

    public func signIn(email: EmailAddress, password: String) async throws(SignInFailure) -> AuthUser {
        try await wrap { try await auth.signIn(email: email.string, password: password).user }.authUser
    }

    public func signOut() async {
        try? await auth.signOut(scope: .local)
    }

    private func wrap<T: Sendable>(_ body: () async throws -> T) async throws(SignInFailure) -> T {
        do {
            return try await body()
        } catch {
            throw SignInFailure(error)
        }
    }
}

extension User {
    /// Google puts the name in `user_metadata.full_name` (and `name`); Apple's arrives in the credential instead.
    var authUser: AuthUser {
        AuthUser(id: id, email: email, fullName: (userMetadata["full_name"] ?? userMetadata["name"])?.stringValue)
    }
}
