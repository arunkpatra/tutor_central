import AuthenticationServices
import Domain
import Foundation
import Supabase

public extension SignInFailure {
    /// Supabase's, Apple's, the web session's and the network's errors, each to the one failure the screens name.
    init(_ error: any Error) {
        switch error {
        case let failure as SignInFailure:
            self = failure
        case let apple as ASAuthorizationError:
            self = apple.code == .canceled ? .cancelled : .providerRefused
        case let web as ASWebAuthenticationSessionError:
            self = web.code == .canceledLogin ? .cancelled : .providerRefused
        case let network as URLError:
            self = Self.offlineCodes.contains(network.code) ? .offline : .other(network.localizedDescription)
        case let .api(message, code, _, _) as AuthError:
            self = Self.fromSupabase(code, message)
        default:
            self = .other(error.localizedDescription)
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
        .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff,
    ]

    private static func fromSupabase(_ code: ErrorCode, _ message: String) -> SignInFailure {
        switch code {
        // Supabase answers a wrong code and an expired one alike: 403 otp_expired, "Token has expired or is
        // invalid". The code screen knows when it sent the code and says "expired" by its own clock.
        case .otpExpired: .wrongCode
        case .overEmailSendRateLimit, .overRequestRateLimit: .tooManyRequests
        case .invalidCredentials: .wrongPassword
        default: .other(message)
        }
    }
}
