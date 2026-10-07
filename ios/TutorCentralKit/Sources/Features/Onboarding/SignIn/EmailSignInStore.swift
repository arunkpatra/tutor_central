import Data
import Domain
import Foundation
import Observation

/// Request a code, enter it, resend after a cooldown; or a password for an account that has one.
@MainActor @Observable public final class EmailSignInStore {
    public enum Step: Equatable, Sendable {
        case request
        case code
        case password
    }

    public private(set) var step: Step = .request
    public var email = ""
    public private(set) var emailError: String?
    public var code = "" {
        didSet {
            if code != oldValue, !code.isEmpty {
                codeError = nil
            }
        }
    }

    public private(set) var codeError: String?
    public var password = "" {
        didSet {
            if password != oldValue {
                passwordError = nil
            }
        }
    }

    public private(set) var passwordError: String?
    public private(set) var busy = false
    public private(set) var resendAvailableIn = 0
    public private(set) var sentTo: EmailAddress?

    public static let codeLength = 6
    /// The code works for ten minutes (the board's words; Supabase's OTP expiry, 600 s).
    public static let codeLifetime: TimeInterval = 600
    private let auth: any AuthRepository
    private let cooldown: Int
    private let now: () -> Date
    private var sentAt: Date?
    /// After a resend the first email's code no longer works; a wrong code then most likely came from it.
    private var resent = false

    public init(auth: any AuthRepository, cooldown: Int = 60, now: @escaping () -> Date = Date.init) {
        self.auth = auth
        self.cooldown = cooldown
        self.now = now
    }

    public func requestCode() async {
        guard let address = EmailAddress(email) else {
            emailError = "Enter a full email address, like name@example.com."
            return
        }
        emailError = nil
        await run { [auth] in
            try await auth.requestCode(email: address)
        } onSuccess: {
            sent(to: address)
            step = .code
        } onFailure: {
            emailError = Self.requestWords($0)
        }
    }

    public func verify() async -> AuthUser? {
        guard let sentTo, code.count == Self.codeLength else { return nil }
        var user: AuthUser?
        let code = code
        await run { [auth] in
            user = try await auth.verifyCode(email: sentTo, code: code)
        } onSuccess: {} onFailure: { failure in
            codeError = Self.codeWords(expired(failure), afterResend: resent)
            self.code = ""
        }
        return user
    }

    public func resend() async {
        guard let sentTo, resendAvailableIn == 0 else { return }
        await run { [auth] in
            try await auth.requestCode(email: sentTo)
        } onSuccess: {
            sent(to: sentTo)
            resent = true
        } onFailure: {
            codeError = Self.requestWords($0)
        }
    }

    /// Once a second, from the code view's timer.
    public func tick() {
        if resendAvailableIn > 0 {
            resendAvailableIn -= 1
        }
    }

    public func usePassword() {
        step = .password
        passwordError = nil
    }

    public func useCode() {
        step = .request
        emailError = nil
    }

    public func signInWithPassword() async -> AuthUser? {
        guard let address = EmailAddress(email) else {
            emailError = "Enter a full email address, like name@example.com."
            return nil
        }
        emailError = nil
        guard !password.isEmpty else {
            passwordError = "Enter your password."
            return nil
        }
        var user: AuthUser?
        let password = password
        await run { [auth] in
            user = try await auth.signIn(email: address, password: password)
        } onSuccess: {} onFailure: {
            passwordError = Self.passwordWords($0)
        }
        return user
    }

    /// A board's state, for the fixtures.
    func preset(step: Step, code: String, resendIn: Int, codeError: String?) {
        sentTo = EmailAddress(email)
        sentAt = now()
        self.step = step
        self.code = code
        resendAvailableIn = resendIn
        self.codeError = codeError
    }

    private func sent(to address: EmailAddress) {
        sentTo = address
        sentAt = now()
        code = ""
        codeError = nil
        resendAvailableIn = cooldown
    }

    /// Supabase answers a wrong code and an expired one alike; past the code's ten minutes, it is the clock that
    /// knows (Review Focus 3).
    private func expired(_ failure: SignInFailure) -> SignInFailure {
        guard failure == .wrongCode, let sentAt, now().timeIntervalSince(sentAt) >= Self.codeLifetime else {
            return failure
        }
        return .codeExpired
    }

    private func run(
        _ body: () async throws -> Void,
        onSuccess: () -> Void,
        onFailure: (SignInFailure) -> Void
    ) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await body()
            onSuccess()
        } catch {
            onFailure(SignInFailure(error))
        }
    }

    static func requestWords(_ failure: SignInFailure) -> String {
        switch failure {
        case .tooManyRequests: "Too many codes asked for. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(message): "Couldn't send the code. \(message)"
        default: "Couldn't send the code. Try again."
        }
    }

    static func codeWords(_ failure: SignInFailure, afterResend: Bool = false) -> String {
        switch failure {
        case .wrongCode where afterResend: "That code isn't right. Use the code in the newest email."
        case .wrongCode: "That code isn't right. Check the email or ask for a new one."
        case .codeExpired: "That code has expired. Ask for a new one."
        case .tooManyRequests: "Too many tries. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(message): "Couldn't sign in. \(message)"
        default: "Couldn't sign in. Try again."
        }
    }

    static func passwordWords(_ failure: SignInFailure) -> String {
        switch failure {
        case .wrongPassword: "That password isn't right. If you never set one, sign in with a code instead."
        case .tooManyRequests: "Too many tries. Wait a minute and try again."
        case .offline: "You're offline. Connect and try again."
        case let .other(message): "Couldn't sign in. \(message)"
        default: "Couldn't sign in. Try again."
        }
    }
}
