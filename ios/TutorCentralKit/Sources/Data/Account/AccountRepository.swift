import Domain

/// The API's account route (D38): Apple is told to forget the app before the account is deleted.
public protocol AccountRepository: Sendable {
    /// `POST /account/revoke-apple` with a fresh authorization code from Apple.
    func revokeApple(code: String) async throws(AccountFailure)
}
