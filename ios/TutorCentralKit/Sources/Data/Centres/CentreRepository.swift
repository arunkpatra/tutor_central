import Domain
import Foundation

/// The tutor's centre and profile.
public protocol CentreRepository: Sendable {
    /// The centre the user belongs to, with their profile, or nil when they have none yet (onboarding).
    func workspace(for user: AuthUser) async throws -> Workspace?
    /// One call: centre, membership, profile name (`create_centre`, migration 0002).
    func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace
    /// Each field writes only its own column, so two quick edits cannot undo each other.
    func updateCentreName(id: UUID, name: String) async throws
    func updateWhatsAppNumber(id: UUID, number: String?) async throws
    func updateProfile(displayName: String) async throws
    /// The UPI id; a changed id is unconfirmed again (`upi_confirmed_at` null in the same update).
    func updateUPI(id: UUID, upiID: String?) async throws
    func updatePaymentLink(id: UUID, link: String?) async throws
    func updateSendReceipts(id: UUID, on: Bool) async throws
    /// "That's right" on Fees' payee card.
    func confirmUPI(id: UUID, at: Date) async throws
    /// "I agree, continue" on the consent sheet: before a child's data first goes to the AI service.
    func recordAIConsent(id: UUID, at: Date) async throws
}
