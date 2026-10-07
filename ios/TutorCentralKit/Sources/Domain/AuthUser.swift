import Foundation

/// The signed-in person as Supabase Auth knows them. `fullName` comes only from Apple's first sign-in or Google's
/// profile; it prefills onboarding and is never shown as the tutor's name (that is `Profile.displayName`).
public struct AuthUser: Hashable, Sendable {
    public let id: UUID
    public let email: String?
    public let fullName: String?

    public init(id: UUID, email: String?, fullName: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
    }
}
