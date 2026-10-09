/// Why a sign-in step did not complete. The words a tutor reads live with the screens; this is what happened.
public enum SignInFailure: Error, Hashable, Sendable {
    /// The Apple sheet or the web session was dismissed: not an error on screen.
    case cancelled
    case offline
    case wrongCode
    case codeExpired
    /// Supabase's email or request rate limit.
    case tooManyRequests
    /// Invalid credentials on the password path.
    case wrongPassword
    /// Apple or Google answered with an error that is not the user's doing.
    case providerRefused
    /// Anything else, with Supabase's own message kept for diagnosis; never shown (D41: the screen says what failed and
    /// Try again).
    case other(String)
}
