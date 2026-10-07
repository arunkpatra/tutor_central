import Data
import Domain
import Foundation
import Observation

/// One screen: your name, centre name, WhatsApp number (optional). One call makes the centre (`create_centre`).
@MainActor @Observable public final class OnboardingStore {
    public var displayName: String
    public var centreName = ""
    public var digits = "" {
        didSet {
            if digits != oldValue {
                phoneError = nil
            }
        }
    }

    public private(set) var phoneError: String?
    public private(set) var busy = false
    /// One line for the toast.
    public var message: String?
    /// The address the session has, or "your Apple ID" when Apple hid it entirely.
    public let signedInAs: String
    private let user: AuthUser
    private let auth: any AuthRepository
    private let centres: any CentreRepository

    public init(user: AuthUser, auth: any AuthRepository, centres: any CentreRepository) {
        self.user = user
        self.auth = auth
        self.centres = centres
        displayName = user.fullName ?? ""
        signedInAs = user.email ?? "your Apple ID"
    }

    public var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !centreName.trimmingCharacters(in: .whitespaces).isEmpty && !busy
    }

    public func submit() async -> Workspace? {
        guard canSubmit else { return nil }
        var phone: PhoneNumber?
        if !digits.isEmpty {
            guard let number = PhoneNumber(indianDigits: digits) else {
                phoneError = PhoneNumber.invalidMessage
                return nil
            }
            phone = number
        }
        busy = true
        defer { busy = false }
        message = nil
        let draft = CentreDraft(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            centreName: centreName.trimmingCharacters(in: .whitespaces),
            whatsappNumber: phone?.e164
        )
        do {
            return try await centres.createCentre(draft, for: user)
        } catch {
            message = "Couldn't create your centre. Check your connection and try again."
            return nil
        }
    }

    public func notYou() async {
        await auth.signOut()
    }
}
