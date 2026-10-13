/// Every way an AI call can fail, as the screens say it. The API answers one shape (api/src/errors.ts); the app never
/// shows a status code.
public enum APIFailure: Error, Hashable, Sendable {
    case offline
    case signedOut
    /// The centre has not agreed to the notice: the store shows the consent sheet.
    case consent
    case limit(Int)
    /// The centre's monthly allowance of the V2 kinds (migration 0013) is used.
    case allowance(Int)
    /// The API's words: the AI service declined, or its answer did not fit.
    case refused(String)
    case service
    /// The app stopped waiting: the call may still finish, so nothing is promised about what was used.
    case timedOut
    /// The photos together are over what one request may carry.
    case tooLarge
    /// Anything else the API said, in its words.
    case server(String)
    /// A named student's parent has not agreed (403 `student_consent`, D62): the API's words are kept; every screen
    /// says the one alert (`studentAlert`), never the centre's notice words.
    case studentConsent(String)
    /// The kind is switched off for a while (D73's kill switch, 503 `paused`): the API's words, shown as the system
    /// alert (P20-Switched-Off).
    case paused(String)

    public var message: String {
        switch self {
        case .offline: "Couldn't reach the AI service. Check your connection and try again."
        case .signedOut: "Your sign-in has ended. Sign in again to use the AI tools."
        case .consent: "Agree to the notice before the first photo."
        case let .limit(limit): "You've made today's \(limit). Try again tomorrow."
        case let .allowance(allowance): "You've made this month's \(allowance). More next month."
        case let .refused(words), let .server(words), let .paused(words): words
        case .studentConsent: Self.studentAlert
        case .service: "The AI service didn't answer. Try again."
        case .timedOut: "That took too long to come back. Try again in a minute."
        case .tooLarge: "That's too many pages. Up to six, and try sharper, smaller photos."
        }
    }
}

public extension APIFailure {
    /// The alert a store shows for a student whose parent has not agreed (plan/phase-14-plan.md decision 15).
    static let studentAlert = "The parent hasn't agreed yet. Record their consent on the student's page first."
}
