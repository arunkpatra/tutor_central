import AuthenticationServices
import Data
import Domain
import Foundation
import Observation

/// The landing's two system sign-ins. Email has its own store (EmailSignInStore).
@MainActor @Observable public final class SignInStore {
    public enum Provider: Sendable {
        case apple
        case google
    }

    public private(set) var busy: Provider?
    /// One line for the toast; nil when nothing is wrong or the tutor cancelled.
    public var message: String?
    /// The raw nonce of this Apple attempt; the request carries its SHA-256.
    public private(set) var nonce = ""
    private let auth: any AuthRepository

    public init(auth: any AuthRepository) {
        self.auth = auth
    }

    /// A new nonce for this attempt; returns the hash Apple's request carries.
    public func startApple() -> String {
        nonce = Nonce.random()
        return Nonce.sha256(nonce)
    }

    public func finishApple(result: Result<ASAuthorization, any Error>) async -> AuthUser? {
        let nonce = nonce
        return await attempt(.apple) { [auth] in
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken,
                  let token = String(data: data, encoding: .utf8) else { throw SignInFailure.providerRefused }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap(\.self)
                .joined(separator: " ")
            return try await auth.signInWithApple(idToken: token, nonce: nonce, fullName: name.isEmpty ? nil : name)
        }
    }

    public func continueWithGoogle() async -> AuthUser? {
        await attempt(.google) { [auth] in try await auth.signInWithGoogle() }
    }

    private func attempt(_ provider: Provider, _ body: () async throws -> AuthUser) async -> AuthUser? {
        guard busy == nil else { return nil }
        busy = provider
        message = nil
        defer { busy = nil }
        do {
            return try await body()
        } catch {
            message = Self.words(for: SignInFailure(error), provider: provider)
            return nil
        }
    }

    static func words(for failure: SignInFailure, provider: Provider) -> String? {
        let name = provider == .apple ? "Apple" : "Google"
        switch failure {
        case .cancelled: return nil
        case .offline: return "You're offline. Connect and try again."
        case .providerRefused: return "\(name) didn't complete the sign-in. Try again, or use your email."
        case .tooManyRequests: return "Too many tries. Wait a minute and try again."
        case let .other(message): return "Couldn't sign in. \(message)"
        case .wrongCode, .codeExpired, .wrongPassword: return "Couldn't sign in. Try again, or use your email."
        }
    }
}
