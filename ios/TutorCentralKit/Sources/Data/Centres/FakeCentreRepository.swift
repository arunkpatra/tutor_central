import Domain
import Foundation

/// The in-memory centre for tests, previews and `bun shots`: one workspace, a scripted error, a record of every
/// write.
@MainActor public final class FakeCentreRepository: CentreRepository {
    /// The boards' tutor: Meera Nair of Bright Minds Tuition.
    public nonisolated static let meeraWorkspace = Workspace(
        user: FakeAuthRepository.meera,
        centre: Centre(
            id: UUID(uuid: (
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22
            )),
            name: "Bright Minds Tuition",
            whatsappNumber: "+919611299988"
        ),
        profile: Profile(displayName: "Meera Nair")
    )

    public var workspace: Workspace?
    public var nextError: (any Error)?
    /// The first workspace lookup answers after this long: lets a test overlap two lookups, as a real network can.
    public var firstLookupDelay: Duration?
    public private(set) var created: [CentreDraft] = []
    public private(set) var nameUpdates: [String] = []
    public private(set) var whatsAppUpdates: [String?] = []
    public private(set) var profileUpdates: [String] = []

    public init(workspace: Workspace? = nil) {
        self.workspace = workspace
    }

    public func workspace(for _: AuthUser) async throws -> Workspace? {
        if let delay = firstLookupDelay {
            firstLookupDelay = nil
            try? await Task.sleep(for: delay)
        }
        try takeError()
        return workspace
    }

    public func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace {
        try takeError()
        created.append(draft)
        let made = Workspace(
            user: user,
            centre: Centre(id: UUID(), name: draft.centreName, whatsappNumber: draft.whatsappNumber),
            profile: Profile(displayName: draft.displayName)
        )
        workspace = made
        return made
    }

    public func updateCentreName(id _: UUID, name: String) async throws {
        try takeError()
        nameUpdates.append(name)
        workspace?.centre.name = name
    }

    public func updateWhatsAppNumber(id _: UUID, number: String?) async throws {
        try takeError()
        whatsAppUpdates.append(number)
        workspace?.centre.whatsappNumber = number
    }

    public func updateProfile(displayName: String) async throws {
        try takeError()
        profileUpdates.append(displayName)
        workspace?.profile.displayName = displayName
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
