import Domain
import Foundation
import Supabase

public extension AccountFailure {
    /// Supabase's and the network's errors, each to the failure the account screens name.
    init(_ error: any Error) {
        switch error {
        case let failure as AccountFailure:
            self = failure
        case let network as URLError:
            self = TransportCodes.offline.contains(network.code) ? .offline : .server(network.localizedDescription)
        case AuthError.weakPassword:
            self = .weakPassword
        case AuthError.sessionMissing:
            self = .signedOut
        case let .api(message, code, _, response) as AuthError:
            if code == .weakPassword {
                self = .weakPassword
            } else if response.statusCode == 401 || code == .sessionNotFound || code == .badJWT {
                self = .signedOut
            } else {
                self = .server(message)
            }
        case let postgrest as PostgrestError where postgrest.code == "PGRST301":
            self = .signedOut
        case let postgrest as PostgrestError:
            self = .server(postgrest.message)
        default:
            self = .server(error.localizedDescription)
        }
    }
}

/// The URL errors that mean the network, not the server (`TransportError`).
enum TransportCodes {
    static let offline: Set<URLError.Code> = [
        .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
        .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff,
    ]
}
