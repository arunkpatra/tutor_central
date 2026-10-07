import Data
import Domain
import Foundation
import Observation

/// Settings, minimal: the onboarding fields saved as they are committed (return or leaving the field), the account
/// and the version, sign out.
@MainActor @Observable public final class SettingsStore {
    public enum SaveState: Equatable, Sendable {
        case idle
        case saving
        case saved
    }

    public var displayName: String
    public var centreName: String
    public var digits: String {
        didSet {
            if digits != oldValue {
                phoneError = nil
            }
        }
    }

    public private(set) var phoneError: String?
    public internal(set) var saveState: SaveState = .idle
    /// One line for the toast.
    public var message: String?
    public let email: String
    public let version: String
    public var onWorkspaceChanged: (Workspace) -> Void = { _ in }
    private var workspace: Workspace
    private let auth: any AuthRepository
    private let centres: any CentreRepository

    public init(workspace: Workspace, auth: any AuthRepository, centres: any CentreRepository, version: String) {
        self.workspace = workspace
        self.auth = auth
        self.centres = centres
        self.version = version
        displayName = workspace.profile.displayName ?? ""
        centreName = workspace.centre.name
        digits = workspace.centre.whatsappNumber.flatMap(PhoneNumber.init(e164:))?.nationalDigits ?? ""
        email = workspace.user.email ?? "your Apple ID"
    }

    public func commitName() async {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard name != (workspace.profile.displayName ?? "") else { return }
        guard !name.isEmpty else {
            displayName = workspace.profile.displayName ?? ""
            message = "Your name can't be empty."
            return
        }
        await save { [centres] in try await centres.updateProfile(displayName: name) } apply: {
            $0.profile.displayName = name
        }
    }

    public func commitCentre() async {
        let name = centreName.trimmingCharacters(in: .whitespaces)
        guard name != workspace.centre.name else { return }
        guard !name.isEmpty else {
            centreName = workspace.centre.name
            message = "A centre needs a name."
            return
        }
        await saveCentre(name: name, whatsapp: workspace.centre.whatsappNumber)
    }

    public func commitPhone() async {
        var e164: String?
        if !digits.isEmpty {
            guard let number = PhoneNumber(indianDigits: digits) else {
                phoneError = PhoneNumber.invalidMessage
                return
            }
            e164 = number.e164
        }
        guard e164 != workspace.centre.whatsappNumber else { return }
        await saveCentre(name: workspace.centre.name, whatsapp: e164)
    }

    public func signOut() async {
        await auth.signOut()
    }

    private func saveCentre(name: String, whatsapp: String?) async {
        let id = workspace.centre.id
        await save { [centres] in
            try await centres.updateCentre(id: id, name: name, whatsappNumber: whatsapp)
        } apply: {
            $0.centre.name = name
            $0.centre.whatsappNumber = whatsapp
        }
    }

    private func save(_ write: () async throws -> Void, apply: (inout Workspace) -> Void) async {
        saveState = .saving
        do {
            try await write()
            apply(&workspace)
            onWorkspaceChanged(workspace)
            saveState = .saved
        } catch {
            saveState = .idle
            message = "Couldn't save. Check your connection and try again."
        }
    }
}
