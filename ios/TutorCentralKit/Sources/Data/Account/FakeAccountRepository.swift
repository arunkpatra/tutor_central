import Domain

/// The account route for tests, previews and `bun shots`: a record of every code, a scripted failure used once.
@MainActor public final class FakeAccountRepository: AccountRepository {
    public private(set) var revoked: [String] = []
    public var nextFailure: AccountFailure?

    public init() {}

    public func revokeApple(code: String) async throws(AccountFailure) {
        if let failure = nextFailure {
            nextFailure = nil
            throw failure
        }
        revoked.append(code)
    }
}
