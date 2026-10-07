import Domain
import Foundation

/// The tutor's centre and profile.
public protocol CentreRepository: Sendable {
    /// The centre the user belongs to, with their profile, or nil when they have none yet (onboarding).
    func workspace(for user: AuthUser) async throws -> Workspace?
    /// One call: centre, membership, profile name (`create_centre`, migration 0002).
    func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace
    func updateCentre(id: UUID, name: String, whatsappNumber: String?) async throws
    func updateProfile(displayName: String) async throws
}
