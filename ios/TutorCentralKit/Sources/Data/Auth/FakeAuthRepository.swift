import Domain
import Foundation
import Synchronization

/// The in-memory auth for tests, previews and `bun shots`: scripted failures, a record of every call, a stream that
/// tests and the session gate can observe.
@MainActor public final class FakeAuthRepository: AuthRepository {
    public nonisolated static let meera = AuthUser(
        id: UUID(uuid: (
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11
        )),
        email: "meera.nair@gmail.com",
        fullName: "Meera Nair"
    )

    public var user: AuthUser?
    public var nextFailure: SignInFailure?
    public private(set) var requested: [EmailAddress] = []
    public private(set) var verified: [(EmailAddress, String)] = []
    public private(set) var signedOut = 0
    public var methods: [SignInProvider] = [.apple, .email]
    public private(set) var passwords: [String] = []
    public private(set) var deleted = 0
    public var nextAccountFailure: AccountFailure?
    /// Registered synchronously, so a change right after `changes()` is never missed.
    private nonisolated let listeners = Listeners()

    public init(user: AuthUser? = nil) {
        self.user = user
    }

    public func currentUser() async -> AuthUser? {
        user
    }

    public nonisolated func changes() -> AsyncStream<AuthUser?> {
        let key = UUID()
        let (stream, continuation) = AsyncStream<AuthUser?>.makeStream()
        listeners.add(continuation, for: key)
        continuation.onTermination = { [listeners] _ in listeners.remove(key) }
        return stream
    }

    public func emit(_ user: AuthUser?) {
        self.user = user
        for listener in listeners.all {
            listener.yield(user)
        }
    }

    private func takeFailure() throws(SignInFailure) {
        guard let failure = nextFailure else { return }
        nextFailure = nil
        throw failure
    }

    public func signInWithApple(
        idToken _: String,
        nonce _: String,
        fullName: String?
    ) async throws(SignInFailure) -> AuthUser {
        try takeFailure()
        // As Supabase does: the change it announces carries no name (Apple's is in the credential); the call's
        // answer does.
        emit(AuthUser(id: Self.meera.id, email: Self.meera.email))
        return AuthUser(id: Self.meera.id, email: Self.meera.email, fullName: fullName)
    }

    public func signInWithGoogle() async throws(SignInFailure) -> AuthUser {
        try takeFailure()
        return signedIn(Self.meera)
    }

    public func requestCode(email: EmailAddress) async throws(SignInFailure) {
        try takeFailure()
        requested.append(email)
    }

    public func verifyCode(email: EmailAddress, code: String) async throws(SignInFailure) -> AuthUser {
        verified.append((email, code))
        try takeFailure()
        return signedIn(AuthUser(id: Self.meera.id, email: email.string))
    }

    public func signIn(email: EmailAddress, password _: String) async throws(SignInFailure) -> AuthUser {
        try takeFailure()
        return signedIn(AuthUser(id: Self.meera.id, email: email.string))
    }

    public func signOut() async {
        signedOut += 1
        emit(nil)
    }

    public func signInMethods() async -> [SignInProvider] {
        methods
    }

    public func setPassword(_ password: String) async throws(AccountFailure) {
        try takeAccountFailure()
        passwords.append(password)
    }

    /// Holds the deletion this long, as the network can.
    public var deleteDelay: Duration?

    /// As Supabase does: the user is gone and the local session ends, announced as a sign-out.
    public func deleteAccount() async throws(AccountFailure) {
        try takeAccountFailure()
        if let deleteDelay {
            try? await Task.sleep(for: deleteDelay)
        }
        deleted += 1
        // A cancelled request loses its answer, though the database has already deleted.
        if Task.isCancelled {
            throw .unexpected
        }
        emit(nil)
    }

    private func takeAccountFailure() throws(AccountFailure) {
        guard let failure = nextAccountFailure else { return }
        nextAccountFailure = nil
        throw failure
    }

    private func signedIn(_ user: AuthUser) -> AuthUser {
        emit(user)
        return user
    }
}

/// The open `changes()` streams, behind a lock so registering never waits for the main actor.
private final class Listeners: Sendable {
    private let streams = Mutex<[UUID: AsyncStream<AuthUser?>.Continuation]>([:])

    func add(_ continuation: AsyncStream<AuthUser?>.Continuation, for key: UUID) {
        streams.withLock { $0[key] = continuation }
    }

    func remove(_ key: UUID) {
        _ = streams.withLock { $0.removeValue(forKey: key) }
    }

    var all: [AsyncStream<AuthUser?>.Continuation] {
        streams.withLock { Array($0.values) }
    }
}
