import Auth
import Domain
import Foundation
import Supabase
import Synchronization
import Testing
@testable import Data

/// Review, Important 1: a tutor who opens the app offline after the access token expired is still signed in. The
/// keychain session is read without a refresh; a refresh that truly fails reaches the gate through `changes()`.
struct SupabaseAuthRepositoryTests {
    final class MemoryStorage: AuthLocalStorage {
        private let values = Mutex<[String: Data]>([:])

        func store(key: String, value: Data) throws {
            values.withLock { $0[key] = value }
        }

        func retrieve(key: String) throws -> Data? {
            values.withLock { $0[key] }
        }

        func remove(key: String) throws {
            _ = values.withLock { $0.removeValue(forKey: key) }
        }
    }

    @Test func anExpiredSessionReadOfflineIsStillTheSignedInUser() async throws {
        let storage = MemoryStorage()
        let id = UUID()
        let user = User(
            id: id,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            email: "meera@example.com",
            createdAt: .now,
            updatedAt: .now
        )
        let expired = Session(
            accessToken: "expired",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date.now.addingTimeInterval(-3600).timeIntervalSince1970,
            refreshToken: "refresh",
            user: user
        )
        try storage.store(key: "test-session", value: JSONEncoder().encode(expired))
        // Nothing listens on port 9: every network call fails at once, as offline.
        let client = try SupabaseClient(
            supabaseURL: #require(URL(string: "http://127.0.0.1:9")),
            supabaseKey: "test",
            options: .init(auth: .init(storage: storage, storageKey: "test-session", autoRefreshToken: false))
        )
        let repository = SupabaseAuthRepository(client: client)
        let current = await repository.currentUser()
        #expect(current?.id == id && current?.email == "meera@example.com")
    }
}
