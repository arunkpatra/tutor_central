import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Settings (P7-Settings): the onboarding fields saved as they are committed (return or leaving the field), this
/// iPhone's choices (appearance, haptics) written at once, the reminders' and the queue's summaries, the account and
/// the version.
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
    /// The Teacher reminders row's value.
    public var reminders: ReminderSummary
    /// The Pending changes row's count.
    public var pendingCount: Int
    public var appearance: AppearanceChoice {
        didSet { defaults.set(appearance.rawValue, forKey: AppearanceChoice.storageKey) }
    }

    public var haptics: Bool {
        didSet { defaults.set(haptics, forKey: Haptic.storageKey) }
    }

    public var onWorkspaceChanged: (Workspace) -> Void = { _ in }
    private var workspace: Workspace
    private let centres: any CentreRepository
    private let defaults: UserDefaults

    public init(
        workspace: Workspace, centres: any CentreRepository, version: String, defaults: UserDefaults = .standard,
        reminders: ReminderSummary, pendingCount: Int
    ) {
        self.workspace = workspace
        self.centres = centres
        self.version = version
        self.defaults = defaults
        self.reminders = reminders
        self.pendingCount = pendingCount
        appearance = AppearanceChoice.resolve(
            arguments: [], stored: defaults.string(forKey: AppearanceChoice.storageKey)
        )
        haptics = defaults.object(forKey: Haptic.storageKey) as? Bool ?? true
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
        await save("your name") { [centres] in try await centres.updateProfile(displayName: name) } apply: {
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
        let id = workspace.centre.id
        await save("the centre's name") { [centres] in try await centres.updateCentreName(id: id, name: name) } apply: {
            $0.centre.name = name
        }
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
        let id = workspace.centre.id
        await save("your WhatsApp number") { [centres] in
            try await centres.updateWhatsAppNumber(id: id, number: e164)
        } apply: {
            $0.centre.whatsappNumber = e164
        }
    }

    /// "None" or the count (the Pending changes row).
    public nonisolated static func pendingValue(_ count: Int) -> String {
        count == 0 ? "None" : "\(count)"
    }

    private func save(_ field: String, _ write: () async throws -> Void, apply: (inout Workspace) -> Void) async {
        saveState = .saving
        do {
            try await write()
            apply(&workspace)
            onWorkspaceChanged(workspace)
            saveState = .saved
        } catch {
            saveState = .idle
            message = "Couldn't save \(field). Check your connection and try again."
        }
    }
}

/// Where the tutor's reminders stand, for Settings' row: "Not set up" before the ask, "Not allowed" when iOS refuses,
/// "Off" when every switch is off, else "On".
public struct ReminderSummary: Hashable, Sendable {
    public let permission: NotificationPermission
    public let settings: ReminderSettings

    public init(permission: NotificationPermission, settings: ReminderSettings) {
        self.permission = permission
        self.settings = settings
    }

    public var value: String {
        switch permission {
        case .notAsked: "Not set up"
        case .refused: "Not allowed"
        case .allowed: settings.anyOn ? "On" : "Off"
        }
    }
}
